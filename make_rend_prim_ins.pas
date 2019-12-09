{   Program MAKE_REND_PRIM_INS <input fnam>
*
*   The input file is assumed to be the Pascal module for a RENDlib graphics
*   primitive.  The output file is the Pascal include file that defines the
*   subroutine that installs this primitive.
*
*   This program is intended to be used in the process of building graphics
*   primitives.
}
program make_rend_prim_ins;
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'img.ins.pas';
%include 'vect.ins.pas';
%include 'rend.ins.pas';

const
  n_exclusions_k = 4;                  {number of ignore exclusion cases}

type
  ignore_t = record                    {describes one kind of ignore exclusion}
    start_chars: string_var4_t;        {character pattern to start exclusion}
    end_chars: string_var4_t;          {character pattern to end exclusion}
    end;

  ignore_list_t =                      {list of all the ignore exclusions}
    array[1..n_exclusions_k] of ignore_t;

var
  in_fnam,                             {input file name}
  out_fnam:                            {output file name}
    %include '(cog)lib/string_treename.ins.pas';
  conn_in, conn_out: file_conn_t;      {input and output file connection handles}
  ignore: ignore_list_t := [           {info list about each exclusion}
    [ start_chars := [str := '{',  len := 1, max := 4],
      end_chars :=   [str := '}',  len := 1, max := 4]],
    [ start_chars := [str := '(*', len := 2, max := 4],
      end_chars :=   [str := '*)', len := 2, max := 4]],
    [ start_chars := [str := '''', len := 1, max := 4],
      end_chars :=   [str := '''', len := 1, max := 4]],
    [ start_chars := [str := '"',  len := 1, max := 4],
      end_chars :=   [str := '"',  len := 1, max := 4]]
    ];
  buf:                                 {input and output line buffer}
    %include '(cog)lib/string8192.ins.pas';
  excl_n: sys_int_machine_t;           {current exclusion number, 0 = none}
  excl_start_col: sys_int_machine_t;   {column number for exclusion start}
  ii, ij: sys_int_machine_t;           {scratch integers and loop counters}
  si, sj: string_index_t;              {scratch index into a string}
  rend_prim_patt: string_var32_t :=
    [str := 'rend_prim.', len := 10, max := sizeof(rend_prim_patt.str)];
  rend_sw_prim_patt: string_var32_t :=
    [str := 'rend_sw_prim.', len := 10, max := sizeof(rend_sw_prim_patt.str)];
  rend_internal_patt: string_var32_t :=
    [str := 'rend_internal.tzoid^', len := 20, max := sizeof(rend_internal_patt.str)];
  rend_sw_internal_patt: string_var32_t :=
    [str := 'rend_sw_internal.tzoid^', len := 20, max := sizeof(rend_sw_internal_patt.str)];
  module_patt: string_var32_t :=
    [str := 'module ', len := 7, max := sizeof(module_patt.str)];
  cmd_patt: string_var32_t :=
    [str := '*   PRIM_DATA ', len := 14, max := sizeof(cmd_patt.str)];
  token:                               {scratch string}
    %include '(cog)lib/string256.ins.pas';
  prim_ref_list:                       {list of text for primitive references}
    array[1..rend_max_called_prims] of string_var256_t;
  prim_data: rend_prim_data_t;         {specific data for this primitive}
  rw_p: ^rend_access_k_t;              {used to point where to put command arg}
  pick: sys_int_machine_t;             {number of token picked from list}
  p: string_index_t;                   {parse index}
  stat: sys_err_t;

label
  next_line, rw_arg, excl_loop, not_prim, not_sw_prim, not_module, eof;
{
********************************************************************************
*
*   Internal subroutine PRIM_REF (NAME)
*
*   Add another primitive reference to the list.  NAME contains the complete
*   name of what the object that should be pointed to by from the CALLED_PRIMS
*   list.  The reference is only added to the list if it is not already there.
}
procedure prim_ref (
  in      name: univ string_var_arg_t); {name to point to from CALLED_PRIMS list}

var
  i: sys_int_machine_t;                {loop counter}

begin
  for i := 1 to prim_data.n_prims do begin {loop thru all previous prim references}
    if string_equal(prim_ref_list[i], name)
      then return;                     {already got this primitive reference ?}
    end;                               {back and check next existing reference}
  if prim_data.n_prims >= rend_max_called_prims then begin {list already full ?}
    writeln ('More than REND_MAX_CALLED_PRIMS primitive references found.');
    sys_bomb;                          {abort with error condition}
    end;
  prim_data.n_prims := prim_data.n_prims + 1; {one more unique primitive reference}
  string_copy (name, prim_ref_list[prim_data.n_prims]); {stuff new name into list}
  end;
{
********************************************************************************
*
*   Internal subroutine APPEND_ACCESS (S, ACCESS)
*
*   Append the name of the enumerated value representing ACCESS to the string S.
}
procedure append_access (
  in out  s: univ string_var_arg_t;    {string to append to}
  in      access: rend_access_k_t);    {access to write value name of}
  val_param;

begin
  case access of
rend_access_inherited_k: begin
      string_appends (s, 'rend_access_inherited_k');
      end;
rend_access_no_k: begin
      string_appends (s, 'rend_access_no_k');
      end;
rend_access_yes_k: begin
      string_appends (s, 'rend_access_yes_k');
      end;
otherwise
    writeln ('Bad access value in MAKE_REND_PRIM_INS.');
    sys_bomb;
    end;
  end;
{
********************************************************************************
*
*   Start of main routine.
}
begin
  string_cmline_init;                  {init for command line processing}
  string_cmline_token (in_fnam, stat); {get input file name from command line}
  string_cmline_req_check (stat);
  string_cmline_end_abort;             {no more arguments allowed on command line}

  file_open_read_text (in_fnam, '', conn_in, stat);
  sys_error_abort (stat, '', '', nil, 0);

  excl_n := 0;                         {start out not in an exclusion}
  for ii := 1 to rend_max_called_prims do begin {init var strings}
    prim_ref_list[ii].max := sizeof(prim_ref_list[ii].str);
    prim_ref_list[ii].len := 0;
    end;
  prim_data.n_prims := 0;              {init number of primitive references in list}
  prim_data.name.max := sizeof(prim_data.name.str);
  prim_data.name.len := 0;
  prim_data.sw_read := rend_access_inherited_k;
  prim_data.sw_write := rend_access_inherited_k;
{
********************
*
*   Read the input file.
}
next_line:                             {back here to read next input file line}
  file_read_text (conn_in, buf, stat); {read next line from input file}
  if file_eof(stat) then goto eof;     {hit end of input file ?}
  sys_error_abort (stat, '', '', nil, 0);
  string_unpad (buf);                  {strip off trailing blanks}
  if buf.len <= 0 then goto next_line; {ignore blank lines}
{
*   Process this line.  The input file line is in BUF.
*
*   Look for a command for us.  These commands must start with '*   PRIM_DATA '
*   in column 1.  Spaces are significant.  Following that, there is a command
*   keyword and optional parameters.
}
  string_find (cmd_patt, buf, si);     {look for command to this program}
  if si = 1 then begin                 {found a command for us ?}
    p := si + cmd_patt.len;            {init token parse pointer}
    string_token (buf, p, token, stat); {get command keyword token}
    string_upcase (token);             {for keyword matching}
    string_tkpick80 (token,            {pick keyword from list}
      'SW_READ SW_WRITE PRIM_CALL PRIM_DATA_P',
      pick);                           {number of token picked from list, 0 = none}
    case pick of
{
*   PRIM_DATA SW_READ <YES, NO, or INHERITED>
}
1: begin                               {SW_READ}
  rw_p := addr(prim_data.sw_read);     {point to where to put result}
rw_arg:                                {from other commands to get access ID arg}
  string_token (buf, p, token, stat);  {get command keyword token}
  string_upcase (token);               {for keyword matching}
  string_tkpick80 (token,              {pick keyword from list}
    'YES NO INHERITED',
    pick);                             {number of token picked from list, 0 = none}
  case pick of
1:  rw_p^ := rend_access_yes_k;
2:  rw_p^ := rend_access_no_k;
3:  rw_p^ := rend_access_inherited_k;
otherwise
    write ('Unrecognized parameter "', token.str:token.len);
    writeln ('" for command SW_READ or SW_WRITE.');
    sys_bomb;
    end;                               {end of access type cases}
  end;                                 {end of SW_READ command}
{
*   PRIM_DATA SW_WRITE <YES, NO, or INHERITED>
}
2: begin
  rw_p := addr(prim_data.sw_write);    {point to where to put result}
  goto rw_arg;                         {to common routine for access argument}
  end;                                 {end of SW_WRITE command}
{
*   PRIM_DATA PRIM_CALL <primitive subroutine entry point>
}
3: begin
  string_token (buf, p, token, stat);
  string_appends (token, '_d.self_p');
  prim_ref (token);
  end;
{
*   PRIM_DATA PRIM_DATA_P <pointer to prim_data of nested primitive>
}
4: begin
  string_token (buf, p, token, stat);
  prim_ref (token);
  end;
{
*   Unrecognized PRIM_DATA command.
}
otherwise
      writeln ('Unrecognized PRIM_DATA command "', token.str:token.len, '".');
      sys_bomb;
      end;                             {end of PRIM_DATA command cases}
    end;                               {done handling PRIM_DATA command on this line}

  excl_start_col := 1;                 {exclusion, if any, start at first char}

excl_loop:                             {back here until got all exclusions on line}
  if excl_n = 0

    then begin                         {not in an exclusion, look for start}
      excl_start_col := buf.len + 1;   {init pos of left-most exclusion so far}
      for ii := 1 to n_exclusions_k do begin {once for each possible exclusion}
        string_find (                  {look for exclusion start in input line}
          ignore[ii].start_chars,      {substring to look for}
          buf,                         {where to look for it}
          sj);                         {char pos of start, = 0 for not found}
        if sj = 0 then next;           {this exclusion not found on this line ?}
        if sj >= excl_start_col then next; {further left than left-most so far ?}
        excl_start_col := sj;          {update start of left-most exclusion}
        excl_n := ii;                  {update number of left-most exclusion}
        end;                           {back and try next exclusion start}
      if excl_n <> 0 then begin        {found an exclusion ?}
        for ii := excl_start_col       {stomp on all the exclusion start characters}
            to excl_start_col + ignore[excl_n].start_chars.len - 1 do begin
          buf.str[ii] := ' ';
          end;
        goto excl_loop;                {back and process this exclusion}
        end;
      end                              {done handling not currently in exclusion}

    else begin                         {currently in an exclusion, look for end}
      string_find (ignore[excl_n].end_chars, buf, si); {look for exclusion end}
      if si = 0
        then begin                     {exclusion does not end on this line}
          si := buf.len + 1;           {first char "after" exclusion}
          end
        else begin                     {exclusion ends on this line}
          si := si + ignore[excl_n].end_chars.len; {first char after exclusion}
          excl_n := 0;                 {no longer in an exclusion}
          end
        ;
      for ij := si to buf.len do begin {once for each char after exclusion}
        buf.str[excl_start_col] := buf.str[ij]; {move chars to remove exclusion}
        excl_start_col := excl_start_col + 1; {advance index where next char goes}
        end;
      buf.len := excl_start_col - 1;   {line now shorter with exclusion removed}
      string_unpad (buf);              {remove any trailing blanks}
      if buf.len <= 0 then goto next_line; {nothing left on this input line ?}
      goto excl_loop;                  {back and look for more exclusions}
      end
    ;                                  {all exclusions have been removed from BUF}
{
*   BUF contains the next input line with all comments and quoted strings
*   stripped out.  Now look for the subroutine name and any references to other
*   primitives.
}
  string_find (rend_prim_patt, buf, si); {look for REND_PRIM reference}
  if si = 0 then goto not_prim;        {not found ?}
  for ij := si + rend_prim_patt.len to buf.len do begin {scan forwards for ^}
    if buf.str[ij] = '^' then begin    {found pointer dereference ?}
      string_substr (buf, si, ij-1, token); {extract reference raw name}
      string_downcase (token);
      string_appends (token, '_data_p'); {make name of pointer to prim_data}
      prim_ref (token);                {record this REND_PRIM reference}
      exit;                            {no need to look farther}
      end;
    end;                               {back and check next char for ^}
not_prim:                              {jump here if definately no REND_PRIM}

  string_find (rend_sw_prim_patt, buf, si); {look for REND_SW_PRIM reference}
  if si = 0 then goto not_sw_prim;     {not found ?}
  for ij := si + rend_sw_prim_patt.len to buf.len do begin {scan forwards for ^}
    if buf.str[ij] = '^' then begin    {found pointer dereference ?}
      string_substr (buf, si, ij-1, token); {extract reference raw name}
      string_downcase (token);
      string_appends (token, '_data_p'); {make name of pointer to prim_data}
      prim_ref (token);                {record this REND_SW_PRIM reference}
      exit;                            {no need to look farther}
      end;
    end;                               {back and check next char for ^}
not_sw_prim:                           {jump here if definately no REND_PRIM}

  string_find (rend_internal_patt, buf, si); {look for proper REND_INTERNAL reference}
  if si <> 0 then begin                {found something ?}
    string_substr (buf, si, si + rend_internal_patt.len - 2, token); {extract ref name}
    string_downcase (token);
    string_appends (token, '_data_p'); {make name of pointer to prim_data}
    prim_ref (token);                  {record this REND_INTERNAL reference}
    end;

  string_find (rend_sw_internal_patt, buf, si); {look for proper REND_SW_INTERNAL reference}
  if si <> 0 then begin                {found something ?}
    string_substr (buf, si, si + rend_sw_internal_patt.len - 2, token); {extract ref name}
    string_downcase (token);
    string_appends (token, '_data_p'); {make name of pointer to prim_data}
    prim_ref (token);                  {record this REND_SW_INTERNAL reference}
    end;
{
*   Check for MODULE statement.
}
  string_find (module_patt, buf, si);  {look for MODULE statement}
  if si <> 1 then goto not_module;     {must start in column 1}
  if prim_data.name.len <> 0 then begin
    writeln ('Multiple MODULE statements encountered.');
    sys_bomb;
    end;
  si := si + module_patt.len;          {point to first char after pattern}
  while buf.str[si] = ' ' do si := si + 1; {skip over blanks}
  for ij := si to buf.len do begin     {scan forwards for ";"}
    if buf.str[ij] = ';' then begin    {found ";" ?}
      string_substr (buf, si, ij-1, prim_data.name); {extract name of this module}
      string_downcase (prim_data.name);
      exit;                            {no need to look any farther}
      end;
    end;                               {back and check next char for ;}
not_module:                            {jump here if definately no MODULE statement}

  goto next_line;                      {back and process next input line}

eof:                                   {end of input file encountered}
  file_close (conn_in);                {close input file}
{
*   Done reading the input file.
*
********************
}
  if prim_data.name.len <= 0 then begin
    writeln ('No MODULE name found.');
    sys_bomb;                          {abort with error}
    end;

  if
      (prim_data.n_prims = 0) and
      ( (prim_data.sw_read = rend_access_inherited_k) or
        (prim_data.sw_write = rend_access_inherited_k)
        )
      then begin
    writeln ('Access flag set to INHERITED with no nested called primitives.');
    sys_bomb;
    end;
{
*   The data extracted from the input file is all set.
*
*   Now write the output file.
}
  string_copy (prim_data.name, out_fnam); {build the output file name}
  string_appends (out_fnam, '_d'(0));
  file_open_write_text (               {open the output file}
    out_fnam, '.ins.pas',              {output fila name and suffix}
    conn_out,                          {returned connection to the file}
    stat);                             {completion status}
  sys_error_abort (stat, '', '', nil, 0);

  file_write_text (string_v('define'(0)),
    conn_out, stat);
  sys_error_abort (stat, '', '', nil, 0);

  buf.len := 0;
  string_appendn (buf, '  ', 2);
  string_append (buf, prim_data.name);
  string_appends (buf, '_d := [');
  file_write_text (buf, conn_out, stat);
  sys_error_abort (stat, '', '', nil, 0);

  buf.len := 0;
  string_appends (buf, '    call_adr := addr(');
  string_append (buf, prim_data.name);
  string_appends (buf, '),');
  file_write_text (buf, conn_out, stat);
  sys_error_abort (stat, '', '', nil, 0);

  file_write_text (string_v('    name := ['(0)),
    conn_out, stat);
  sys_error_abort (stat, '', '', nil, 0);

  buf.len := 0;
  string_appends (buf, '      str := ''');
  string_append (buf, prim_data.name);
  string_appends (buf, ''',');
  file_write_text (buf, conn_out, stat);
  sys_error_abort (stat, '', '', nil, 0);

  buf.len := 0;
  string_appends (buf, '      len :=');
  string_append1 (buf, ' ');
  string_f_int16 (token, prim_data.name.len);
  string_append (buf, token);
  string_append1 (buf, ',');
  file_write_text (buf, conn_out, stat);
  sys_error_abort (stat, '', '', nil, 0);

  buf.len := 0;
  string_appends (buf, '      max := sizeof(');
  string_append (buf, prim_data.name);
  string_appends (buf, '_d.name.str)');
  file_write_text (buf, conn_out, stat);
  sys_error_abort (stat, '', '', nil, 0);

  file_write_text (string_v('      ],'(0)),
    conn_out, stat);
  sys_error_abort (stat, '', '', nil, 0);

  buf.len := 0;
  string_appends (buf, '    self_p := addr(');
  string_append (buf, prim_data.name);
  string_appends (buf, '_d),');
  file_write_text (buf, conn_out, stat);
  sys_error_abort (stat, '', '', nil, 0);

  buf.len := 0;
  string_appends (buf, '    sw_read :=');
  string_append1 (buf, ' ');
  append_access (buf, prim_data.sw_read);
  string_append1 (buf, ',');
  file_write_text (buf, conn_out, stat);
  sys_error_abort (stat, '', '', nil, 0);

  buf.len := 0;
  string_appends (buf, '    sw_write :=');
  string_append1 (buf, ' ');
  append_access (buf, prim_data.sw_write);
  string_append1 (buf, ',');
  file_write_text (buf, conn_out, stat);
  sys_error_abort (stat, '', '', nil, 0);

  buf.len := 0;
  string_appends (buf, '    n_prims :=');
  string_append1 (buf, ' ');
  string_f_int32 (token, prim_data.n_prims);
  string_append (buf, token);
  string_append1 (buf, ',');
  file_write_text (buf, conn_out, stat);
  sys_error_abort (stat, '', '', nil, 0);

  file_write_text (string_v('    called_prims := ['(0)),
    conn_out, stat);
  sys_error_abort (stat, '', '', nil, 0);

  for ii := 1 to rend_max_called_prims do begin
    buf.len := 0;
    if ii <= prim_data.n_prims
      then begin                       {we have a real reference for this slot}
        string_appends (buf, '      addr(');
        string_append (buf, prim_ref_list[ii]);
        string_append1 (buf, ')');
        end
      else begin                       {no reference for this slot}
        string_appends (buf, '      nil');
        end
      ;
    if ii <> rend_max_called_prims then begin {no comma on last entry}
      string_append1 (buf, ',');
      end;
    file_write_text (buf, conn_out, stat);
    sys_error_abort (stat, '', '', nil, 0);
    end;                               {back and fill in next prim reference slot}

  file_write_text (string_v('      ]'(0)),
    conn_out, stat);
  sys_error_abort (stat, '', '', nil, 0);

  file_write_text (string_v('    ];'(0)),
    conn_out, stat);
  sys_error_abort (stat, '', '', nil, 0);

  file_close (conn_out);
  end.
