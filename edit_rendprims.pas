{   Program EDIT_RENDPRIMS
*
*   Scan all .pas files in the current directory, and edit them to convert to
*   the latest build system as appropriate.  The module or file name of each
*   source file examined will be written to one of three list output files.
}
program edit_rendprims;
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';

var
  conn_dir: file_conn_t;               {connection to reading the curr directory}
  fnam:                                {directory entry name}
    %include '(cog)lib/string_leafname.ins.pas';
  finfo: file_info_t;                  {info about directory entry}
  list_prim: string_list_t;            {list of modules that were primitives}
  list_nprim: string_list_t;           {list of modules that were not primitives}
  list_nmod: string_list_t;            {list of files without MODULE statement}
  lines: string_list_t;                {source lines read from the current file}
  tk:                                  {scratch token}
    %include '(cog)lib/string32.ins.pas';
  nedit: sys_int_machine_t;            {number of files edited}
  stat: sys_err_t;                     {completion status}
{
********************************************************************************
*
*   Local subroutine READIN (FNAM, LIST)
*
*   Read the file FNAM into the strings list LIST.  LIST has already been
*   initialized.  The new lines will be added to the end of the list.
}
procedure readin (                     {read file into list}
  in      fnam: string_leafname_t;     {name of file to read}
  in out  list: string_list_t);        {list to add lines to end of}
  val_param; internal;

var
  conn: file_conn_t;                   {connection to the file}
  buf: string_var8192_t;               {one line buffer}
  stat: sys_err_t;                     {completion status}

begin
  buf.max := size_char(buf.str);       {init local var string}

  file_open_read_text (fnam, '', conn, stat); {open the input file}
  sys_error_abort (stat, '', '', nil, 0);

  string_list_pos_last (list);         {go to end of list}
  while true do begin                  {back here each new source line}
    file_read_text (conn, buf, stat);  {read next line from file}
    if file_eof(stat) then exit;       {hit end of file ?}
    sys_error_abort (stat, '', '', nil, 0);
    string_list_str_add (list, buf);   {add this line to end of list}
    end;                               {back to get next source line}

  file_close (conn);
  end;
{
********************************************************************************
*
*   Local function FILE_EDIT (LIST)
*
*   Edit the source lines of the graphics primitive in LIST, as appropriate.
*   The function returns TRUE iff any changes were made to the soruce lines.
*
*   If the source code is a valid module (contains exactly one MODULE
*   statement), then the module is added to either the PRIM_LIST or NPRIM_LIST
*   list, depending on whether it is a graphics primitive or not.
}
function file_edit (                   {edit graphics primitive as appropriate}
  in out  list: string_list_t)         {the source lines to possibly edit}
  :boolean;                            {the source code was changed}
  val_param; internal;

var
  mod: string_var80_t;                 {module name, empty if none found}
  p: string_index_t;                   {current input line parse index}
  tk, tk2: string_var80_t;             {token parsed from input line}
  pick: sys_int_machine_t;             {number of keyword picked from list}
  modline: sys_int_machine_t;          {line number of MODULE statement, 0 = none}
  prim: boolean;                       {this module is a graphics primitive}
  changed: boolean;                    {the source code was changed}
  old: boolean;                        {was old style code}
  modu: boolean;                       {module name contains upper case chars}
  stat: sys_err_t;                     {completion status}

label
  next_line;

begin
  mod.max := size_char(mod.str);       {init local var strings}
  tk.max := size_char(tk.str);
  tk2.max := size_char(tk2.str);

  file_edit := false;                  {init function return value}
  prim := false;                       {init to not a graphics primitive}
  changed := false;                    {init to source code not changed}
  old := false;                        {init to not old style primitive}
  modu := false;                       {init to no upper case chars in module name}

  modline := 0;                        {init to no module name found}
  mod.len := 0;
  string_list_pos_start (list);        {go to before first line}
  while true do begin                  {back here each new source line}
    string_list_pos_rel (list, 1);     {advance to next line}
    if list.str_p = nil then exit;     {hit end of list ?}
    p := 1;                            {init input line parse index}
    string_token (list.str_p^, p, tk, stat);
    if sys_error(stat) then tk.len := 0;
    string_upcase (tk);
    string_tkpick80 (tk,               {pick keyword from list}
      'MODULE %INCLUDE',
      pick);
    case pick of                       {which keyword is this ?}
{
*   MODULE
}
1: begin
  string_token_anyd (                  {parse the module name into TK}
    list.str_p^,                       {input string}
    p,                                 {parse index}
    ';', 1,                            {list of delimiters}
    0,                                 {first N delimiters that may repeat}
    [string_tkopt_padsp_k],            {strip leading/trailing blank padding}
    tk,                                {returned the parsed token}
    pick,                              {number of defining delimiter}
    stat);
  if not sys_error(stat) then begin
    if modline <> 0 then begin
      writeln ('Duplicate MODULE statements found in ', fnam.str:fnam.len, '.');
      writeln ('First module was "', mod.str:mod.len, '".');
      writeln ('Second module was "', tk.str:tk.len, '".');
      sys_bomb;
      end;
    string_copy (tk, mod);             {save module name}
    modline := list.curr;              {save line number of MODULE statement}
    string_downcase (tk);              {make module name all lower case}
    modu := not string_equal(tk, mod); {module name contains upper case chars ?}
    end;
  end;                                 {end of MODULE case}
{
*   %INCLUDE
}
2: begin
  if modline = 0 then goto next_line;  {ignore if no previous MODULE statement}
  string_token_anyd (                  {parse include file name into TK}
    list.str_p^,                       {input string}
    p,                                 {parse index}
    ' ;', 2,                           {list of delimiters}
    1,                                 {first N delimiters that may repeat}
    [string_tkopt_quotea_k],           {may be quoted in apostrophies ('...')}
    tk,                                {returned the parsed token}
    pick,                              {number of defining delimiter}
    stat);
  {
  *   Check for old style private primitive data include.
  }
  string_copy (tk, tk2);               {make corruptable copy of include file name}
  string_upcase (tk2);
  if string_equal (tk2, string_v('$(REND_PRIM_INS)'(0))) then begin
    prim := true;                      {this is a graphics primitive}
    old := true;                       {this is old style private include}
    string_list_line_del (list, false); {delete this line, back to previous}
    string_vstring (tk2, '%include '''(0), -1); {build the replacement line}
    string_append (tk2, mod);
    string_downcase (tk2);             {make sure module name written lower case}
    string_appends (tk2, '_d.ins.pas'';'(0));
    string_list_str_add (list, tk2);   {write the replacement line, make curr}
    changed := true;                   {indicate original source altered}
    goto next_line;                    {done with this source line}
    end;
  {
  *   Check for new style private primitive data include.
  }
  string_copy (mod, tk2);              {build expected include file name}
  string_appends (tk2, '_d.ins.pas'(0));
  if string_equal (tk, tk2) then begin {this is private prim data include ?}
    prim := true;                      {indicate this is a primitive}
    end;
  end;                                 {end of %INCLUDE case}

      end;                             {end of first token cases}
next_line:                             {done with this source line, advance to next}
    end;                               {back to do next list entry}
{
*   Done examining each source line.
}
{
*   Update the MODULE statement if the module name contained upper case
*   characters.  Convert them to lower case.
*
*   The original RENDlib code only used lower case module names, although they
*   were sometimes written as partially upper case due to some automated copy
*   and paste error a long time ago.  While module names with upper case letters
*   are legitimate, we assume this program is being run to convert old RENDlib
*   code to a new system.  After all the old RENDlib code has been converted
*   once, there should be no need to run this program again.
}
  if modu then begin                   {module name contains upper case chars ?}
    string_list_pos_abs (list, modline); {go to MODULE statement line}
    list.str_p^.len := 0;              {clear the original line}
    string_appends (list.str_p^, 'module '(0)); {re-write MODULE statement}
    string_downcase (mod);             {convert module name to all lower case}
    string_append (list.str_p^, mod);  {add the module name}
    string_append1 (list.str_p^, ';'); {finish the line}
    changed := true;                   {indicate the source code was changed}
    end;
{
*   Write this file name or module name to the appropriate list.
}
  if modline = 0
    then begin                         {no MODULE statement}
      string_list_str_add (list_nmod, fnam);
      end
    else begin                         {is a module, MOD set to name}
      if prim
        then begin                     {this is a primitive}
          string_list_str_add (list_prim, mod);
          end
        else begin                     {this is not a primitive}
          string_list_str_add (list_nprim, mod);
          end
        ;
      end
    ;

  file_edit := changed;                {indicate whether source was changed}
  end;
{
********************************************************************************
*
*   Local subroutine WRITE_LIST (LIST, FNAM)
*
*   Write the contents of the strings list LIST to the file FNAM.
}
procedure write_list (                 {write list of lines to a file}
  in out  list: string_list_t;         {list of text lines to write}
  in      fnam: univ string_var_arg_t); {name of file to write to}
  val_param; internal;

var
  conn: file_conn_t;                   {connection to the file}
  stat: sys_err_t;                     {completion status}

begin
  file_open_write_text (fnam, '', conn, stat); {open the output file}
  sys_error_abort (stat, '', '', nil, 0);

  string_list_pos_start (list);        {go to before first line}
  while true do begin                  {back here each new line to write}
    string_list_pos_rel (list, 1);     {advance to next line}
    if list.str_p = nil then exit;     {hit end of list ?}
    file_write_text (list.str_p^, conn, stat); {write this line to the file}
    sys_error_abort (stat, '', '', nil, 0);
    end;                               {back for next line in list}

  file_close (conn);                   {close the output file}
  end;
{
********************************************************************************
*
*   Start of main routine.
}
begin
  file_open_read_dir (                 {open the current directory for reading}
    string_v('.'(0)),                  {directory name}
    conn_dir,                          {returned connection to the directory}
    stat);
  sys_error_abort (stat, '', '', nil, 0);

  string_list_init (list_prim, util_top_mem_context); {init list of prims}
  list_prim.deallocable := false;
  string_list_init (list_nprim, util_top_mem_context); {init list of not-prims}
  list_nprim.deallocable := false;
  string_list_init (list_nmod, util_top_mem_context); {init list of not-modules}
  list_nmod.deallocable := false;
  nedit := 0;                          {inti to no files edited}

  while true do begin                  {back here each new directory entry}
    file_read_dir (                    {read next directory entry}
      conn_dir,                        {connection to the directory}
      [file_iflag_type_k],             {request object type}
      fnam,                            {returned entry name}
      finfo,                           {returned info about the entry}
      stat);
    if file_eof(stat) then exit;       {hit end of directory ?}
    sys_error_abort (stat, '', '', nil, 0);
    {
    *   The directory entry name is in FNAM.
    *
    *   Ignore this entry if it can't be a Pascal source file.
    }
    if finfo.ftype <> file_type_data_k {not a ordinary data file ?}
      then next;
    if fnam.len < 5                    {name not long enough for "x.pas" ?}
      then next;
    if fnam.str[fnam.len-3] <> '.' then next; {doesn't end in ".pas" ?}
    if fnam.str[fnam.len-2] <> 'p' then next;
    if fnam.str[fnam.len-1] <> 'a' then next;
    if fnam.str[fnam.len-0] <> 's' then next;
    if fnam.len >= 9 then begin        {long enough for "x.ins.pas" ?}
      string_substr (fnam, fnam.len-7, fnam.len-4, tk);
      string_downcase (tk);
      if string_equal (tk, string_v('.ins'(0)))
        then next;
      end;
    if fnam.len >= 12 then begin       {long enough for "x.insall.pas" ?}
      string_substr (fnam, fnam.len-10, fnam.len-4, tk);
      string_downcase (tk);
      if string_equal (tk, string_v('.insall'(0)))
        then next;
      end;
    {
    *   The file name checks out.  Process the file.
    }
    string_list_init (lines, util_top_mem_context); {init list for source lines}
    lines.deallocable := true;         {allow individual lines to be deleted}
    readin (fnam, lines);              {read the file into the LINES strings list}

    if file_edit (lines) then begin    {edit the file as necessary}
      writeln ('Editing: ', fnam.str:fnam.len);
      write_list (lines, fnam);        {write modified version back to file}
      nedit := nedit + 1;              {count one more file edited}
      end;

    string_list_kill (lines);          {done with local copy of the source lines}
    end;                               {back to get next directory entry}
  file_close (conn_dir);               {close the directory}
{
*   Done processing all files.
*
*   Write the primitives and not-primitives lists.
}
  string_list_sort (list_prim, [string_comp_num_k]); {write primitives list}
  write_list (list_prim, string_v('prim_list.txt'(0)));

  string_list_sort (list_nprim, [string_comp_num_k]); {write not-primitives list}
  write_list (list_nprim, string_v('nprim_list.txt'(0)));

  string_list_sort (list_nmod, [string_comp_num_k]); {write not-modules list}
  write_list (list_nmod, string_v('nmod_list.txt'(0)));
{
*   Show statistics.
}
  if nedit > 0 then writeln;
  writeln (nedit, ' files edited.');
  writeln (list_prim.n, ' primitives found, in PRIM_LIST.TXT.');
  writeln (list_nprim.n, ' non-primitives found, in NPRIM_LIST.TXT.');
  writeln (list_nmod.n, ' non-module source files found, in NMOD_LIST.TXT.');
  end.
