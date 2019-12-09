{   Subroutine REND_OPEN (NAME, DEV_ID, STAT)
*
*   Open a new RENDlib device by name.  NAME is a string giving the device name
*   and optional parameters.  The device name in NAME will be translated as
*   specified in the RENDLIB.DEV environment file.  Any additional tokens in NAME
*   that are not used to decide the RENDlib device type will be passed as parameters
*   to the specific open routines for each RENDlib device.
*
*   DEV_ID is returned as the RENDlib device ID.  This will be how the application
*   identifies this new RENDlib device in all future interactions.
*
*   STAT is the returned completion status code.  It is set to the RENDlib
*   status NO_DEVICE if the specified device does not exist.
}
module rend_open;
define rend_open;
%include 'rend2.ins.pas';

const
  dev_desc_fnam = 'rendlib';           {generic device descriptor file name}
  max_recurse_level = 16;              {max allowed recursion level}
  max_msg_parms = 3;                   {max parameters we can pass to a message}

var                                    {static variables}
  recurse_level: sys_int_machine_t := 0; {current recursion level}
  varname_debug: string_var32_t :=     {variable name to set RENDlib debug level}
    [str := 'RENDLIB_DEBUG', len := 13, max := sizeof(varname_debug.str)];
  debug_level: sys_int_machine_t;      {RENDlib debug level}

procedure rend_open (                  {open RENDlib device by name}
  in      name: univ string_var_arg_t; {RENDlib device name and parameters}
  out     dev_id: rend_dev_id_t;       {returned device ID for this connection}
  out     stat: sys_err_t);            {completion status code}

var
  conn: file_conn_t;                   {environment file connection handle}
  p: string_index_t;                   {string parse index}
  parms: string_var256_t;              {optional parameters extracted from NAME}
  try: string_var80_t;                 {name of current device to try}
  devs: string_list_t;                 {points to list of device strings from file}
  buf: string_var256_t;                {one line input buffer for reading dev files}
  token: string_var80_t;               {for parsing dev file line}
  devname_raw: string_var80_t;         {raw RENDlib device name}
  pick: sys_int_machine_t;             {number of token picked from list}
  old_dev_id: sys_int_machine_t;       {ID of current device when REND_OPEN called}
  stat2: sys_err_t;                    {local error code to not corrupt STAT}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;

label
  next_line, alias_next, alias_done, err, eof, got_try_list,
  got_raw, do_open, got_dev_id, leave;
{
*********************************************************
*
*   Local subroutine INDENT
*
*   Write leading blanks for current indentation level for debug messages.
}
procedure indent;

var
  n: sys_int_machine_t;

begin
  n := (recurse_level - 1) * 2;
  if n <= 0 then return;
  write (' ':n);
  end;
{
*********************************************************
*
*   Local subroutine OPEN_RAW
*
*   This subroutine performs the system-dependent part of the OPEN operation.
*   It is implemented in an include file so that different branches may be
*   created for different operating systems or environments.
}
procedure open_raw;

%include 'rend_open.ins.pas';
{
*********************************************************
*
*   Local subroutine EXTRACT_DEV_NAME (NAME_IN, NAME_OUT)
*
*   Extract the native RENDlib device name from NAME_IN, and return it in NAME_OUT
*   stripped of the special characters that identify it as a native device name.
*   Native device names may not be traslated in the device files.  If NAME_IN
*   does not contain a native device name, then NAME_OUT is set to zero length.
}
procedure extract_dev_name (
  in      name_in: univ string_var_arg_t; {input name with special chars}
  in out  name_out: univ string_var_arg_t); {returned stripped of special chars}

begin
  name_out.len := 0;                   {init to this is not an intrinsic device name}
  if name_in.len < 3 then return;      {too small to hold intrinsic name ?}
  if  (name_in.str[1] <> '*') or       {doesn't start with right character ?}
      (name_in.str[name_in.len] <> '*') {doesn't end with right character ?}
    then return;
  string_substr (name_in, 2, name_in.len-1, name_out); {extract name from NAME_IN}
  end;
{
*********************************************************
*
*   Start of main routine.
}
begin
  recurse_level := recurse_level + 1;  {one level deeper in nested REND_OPEN calls}
  if recurse_level > max_recurse_level then begin {exceeded recursion depth limit ?}
    sys_message_bomb ('rend', 'rend_open_recurse_limit', nil, 0);
    end;

  parms.max := sizeof(parms.str);      {init local var strings}
  try.max := sizeof(try.str);
  buf.max := sizeof(buf.str);
  token.max := sizeof(token.str);
  devname_raw.max := sizeof(devname_raw.str);

  if recurse_level <= 1 then begin     {this is first time ?}
    sys_envvar_get (varname_debug, token, stat); {read RENDlib debug env variable}
    if sys_stat_match (sys_subsys_k, sys_stat_envvar_noexist_k, stat)
      then begin                       {debug environment variable not present}
        debug_level := 0;              {default to all debug info suppressed}
        end
      else begin                       {debug environment variable exists}
        string_t_int (token, debug_level, stat); {try to convert value to integer}
        if sys_error(stat) or (debug_level < 0) then begin
          sys_msg_parm_vstr (msg_parm[1], token);
          sys_msg_parm_vstr (msg_parm[2], varname_debug);
          sys_message_bomb ('rend', 'rend_debug_envvar_badstr', msg_parm, 2);
          end;
        end
      ;                                {debug level all set}
    end;

  if debug_level >= 2 then begin
    indent;
    writeln ('REND_OPEN "', name.str:name.len, '"');
    end;

  string_list_init (devs, rend_mem_context_p^); {init expanded dev strings list}

  p := 1;                              {init NAME parse index}
  string_list_line_add (devs);         {init expanded list to input string}
  string_copy (name, devs.str_p^);
  string_token (name, p, try, stat);   {extract device name token from NAME}
  string_upcase (try);                 {device names are case-insensitive}
  while (p <= name.len) and (name.str[p] = ' ') do begin {go to start of parms}
    p := p + 1;
    end;
  string_substr (name, p, name.len, parms); {extract parameters string from NAME}

  extract_dev_name (try, devname_raw); {extract RENDlib native dev name, if is one}
  if devname_raw.len > 0 then begin    {device is direct RENDlib native device ?}
    goto got_raw;                      {DEVNAME_RAW and PARMS all set}
    end;

  file_open_read_env (                 {open our device descriptor file set}
    string_v(dev_desc_fnam),           {generic device descriptor file set name}
    '.dev',                            {file name suffix}
    true,                              {read in global to local order}
    conn,                              {returned connection handle}
    stat);
  if file_not_found(stat) then goto got_try_list; {no dev file, use raw names ?}
  if sys_error(stat) then goto leave;  {real error opening device descriptor file ?}
{
*   Read the device descriptor files to translate the input device name in TRY
*   to a list of device strings to try in order.  These strings will be put into
*   the strings list DEVS_P^.
}
next_line:                             {back here to read each new dev files line}
  file_read_env (conn, buf, stat);     {read next line from dev files}
  if file_eof(stat) then goto eof;     {hit end of device descriptor files ?}
  if sys_error(stat) then goto leave;
  p := 1;                              {init input line parse index}
  string_token (buf, p, token, stat);  {extract command name from input line}
  sys_error_none (stat);
  string_upcase (token);               {make upper case for name matching}
  string_tkpick80 (token,
    'DEV_ALIAS',
    pick);
  case pick of
{
*   DEV_ALIAS <input dev name> <list of aliases to try in order>
}
1: begin
  string_token (buf, p, token, stat);  {get input dev name for this command}
  if sys_error(stat) then goto err;
  string_upcase (token);               {make upper case for name matching}
  if not string_equal(token, try) then goto alias_done; {not for our device name ?}
  string_list_pos_start (devs);        {reset resulting device strings to empty}
  string_list_trunc (devs);
  if debug_level >= 2 then begin
    indent;
    writeln ('Expanding "', try.str:try.len,
      '" from line ', conn.lnum,
      ' of ', conn.tnam.str:conn.tnam.len, ' to:');
    indent;
    end;

alias_next:                            {back here each new token}
  string_list_line_add (devs);         {create string for this token}
  string_token (buf, p, devs.str_p^, stat); {extract and save string for this dev}
  if string_eos(stat)
    then begin                         {we just hit end of DEV_ALIAS command}
      string_list_line_del (devs, false); {delete last unused string in list}
      goto alias_done;                 {done with DEV_ALIAS command}
      end
    else begin                         {there may be more tokens left on line}
      if sys_error(stat) then goto err;
      if debug_level >= 2 then begin
        indent;
        writeln ('"', devs.str_p^.str:devs.str_p^.len, '"');
        end;
      end
    ;
  goto alias_next;                     {back and handle next name from list}

alias_done:                            {all done with DEV_ALIAS command}
  end;                                 {end of DEV_ALIAS command case}
{
*   Unrecognized command in device descriptor file.
}
otherwise
    rend_end;
    sys_msg_parm_vstr (msg_parm[1], token);
    sys_msg_parm_int (msg_parm[2], conn.lnum);
    sys_msg_parm_vstr (msg_parm[3], conn.tnam);
    sys_message_bomb ('file', 'env_cmd_bad', msg_parm, 3);
    end;                               {end of command name cases}
  goto next_line;                      {back and read next line from dev files}
{
*   Jump here on error processing information from device files.  STAT is
*   set to the error code describing the error.  We will print the file and line
*   number, then bomb.
}
err:
  rend_end;
  sys_msg_parm_int (msg_parm[1], conn.lnum);
  sys_msg_parm_vstr (msg_parm[2], conn.tnam);
  sys_message_bomb ('file', 'env_read', msg_parm, 2);

eof:                                   {jump here on end of device files}
  file_close (conn);                   {close device files}
{
*   Done processing the device descriptor files.  The strings list DEVS
*   contains the expansion of the caller's device in NAME.
}
got_try_list:                          {jump here if DEVS all set}
{
*   Determine whether we need to call ourselves recursively for each entry in
*   the expanded list.  This is the case unless the expanded list is only one
*   entry in size and that entry is identical to the original call argument
*   in NAME.
}
  if devs.n = 1 then begin             {expanded list contains exactly one string ?}
    string_list_pos_abs (devs, 1);     {position to this string}
    if string_equal(name, devs.str_p^) {exansion was identical to input arg ?}
      then goto do_open;               {we will do the open directly}
    end;
{
*   The expanded list was different from the input argument in NAME.  Call this
*   subroutine recursively for each entry in the expanded list.
}
  string_list_pos_start (devs);        {init to before first dev string to try}
  while devs.curr < devs.n do begin    {once for each dev string to try}
    string_list_pos_rel (devs, 1);     {position to string for this dev to try}
    if parms.len > 0 then begin        {additional parameters exist from caller ?}
      string_append1 (devs.str_p^, ' '); {separater before parameters}
      string_append (devs.str_p^, parms); {append caller's parameters}
      end;
    rend_open (devs.str_p^, dev_id, stat); {try to open this device}
    stat2 := stat;                     {make corruptable copy of STAT}
    if not sys_stat_match(rend_subsys_k, rend_stat_no_device_k, stat2)
      then goto leave;                 {either opened or got real error}
    end;                               {this dev not here, try next entry in list}
  goto leave;                          {return with NO_DEVICE err for last dev tried}
{
*   Open the device indicated by the one and only string in DEVS_P^.
}
do_open:                               {jump here if we need to do the actual open}
  p := 1;                              {init device string parse index}
  string_token (devs.str_p^, p, try, stat); {extract device name token}
  string_upcase (try);                 {device names are case-insensitive}
  while (p <= devs.str_p^.len) and (devs.str_p^.str[p] = ' ') do begin
    p := p + 1;                        {go to start of first parameter token}
    end;
  string_substr (devs.str_p^, p, devs.str_p^.len, parms); {extract parms string}
  extract_dev_name (try, devname_raw); {extract native RENDlib device name}
  if devname_raw.len <= 0 then begin   {device is not inherent RENDlib device ?}
    sys_stat_set (rend_subsys_k, rend_stat_no_device_k, stat); {dev doesn't exist}
    sys_stat_parm_vstr (devname_raw, stat); {indicate name of dev that wasn't found}
    sys_stat_parm_vstr (parms, stat);  {save parameters to unavailable device}
    goto leave;
    end;
{
*   The native RENDlib device name to open is in DEVNAME_RAW, and the parameters
*   string to pass to the specific init routines is in PARMS.  The original
*   device name token the raw device name was extracted from is in TRY.
}
got_raw:                               {TRY, DEVNAME_RAW, and PARMS all set}
  for dev_id := 1 to rend_max_devices do begin {once for each device descriptor}
    if not rend_device[dev_id].open then goto got_dev_id; {descriptor available ?}
    end;                               {back and try find available descriptor}
  rend_end;                            {no slots left in devices table}
  sys_message_bomb ('rend', 'rend_dev_table_overflow', nil, 0);

got_dev_id:                            {DEV_ID is now all set}
  old_dev_id := rend_dev_id;           {save ID of current device}
  rend_dev_save;                       {save current device's state if exists}
  rend_dev_id := dev_id;               {set device ID of this device}

  rend_device[dev_id].save_area_p := nil;
  rend_device[dev_id].open := true;
  util_mem_context_get (               {make device's memory context block}
    rend_mem_context_p^,               {parent context}
    rend_device[rend_dev_id].mem_p);   {returned pointer to new context block}

  if debug_level >= 2 then begin
    indent;
    writeln ('OPEN_RAW called with device name "',
      devname_raw.str:devname_raw.len, '", ');
    indent;
    writeln ('  and parameters "', parms.str:parms.len, '".');
    end;

  open_raw;                            {do system-dependent open, sets STAT}

  if debug_level >= 2 then begin
    indent;
    write ('  Returned status: ');
    if sys_error(stat)
      then begin                       {OPEN_RAW returned with error}
        writeln ('Subsys ', stat.subsys, ', Code ', stat.code);
        end
      else begin                       {OPEN_RAW was successful}
        writeln ('OK');
        end
      ;
    end;

  if not sys_error(stat) then goto leave; {no error, device opened ?}
  if sys_stat_match(rend_subsys_k, rend_stat_no_device_k, stat) then begin
    sys_stat_set (rend_subsys_k, rend_stat_no_device_k, stat); {dev doesn't exist}
    sys_stat_parm_vstr (devname_raw, stat); {indicate name of dev that wasn't found}
    sys_stat_parm_vstr (parms, stat);  {save parameters to unavailable device}
    end;
{
*   Opening the new device was not successful.  Restore back to the old device.
}
  util_mem_context_del (rend_device[rend_dev_id].mem_p); {dealloc dev's mem context}
  rend_device[dev_id].open := false;   {flag device descriptor as unused}
  dev_id := 0;                         {pass back illegal device ID}
  rend_dev_id := 0;                    {indicate no device currently swapped in}
  if old_dev_id > 0 then begin         {a device was swapped in ?}
    rend_dev_set (old_dev_id);         {swap back to old device}
    end;
{
*   Common exit point.
}
leave:
  if debug_level >= 2 then begin
    indent;
    writeln ('Return from REND_OPEN');
    end;
  recurse_level := recurse_level - 1;  {one less level deep in recursion}
  string_list_kill (devs);
  end;
