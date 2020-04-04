{   Routines related to standard input events.
}
module rend_stdin;
define rend_stdin_init;
define rend_stdin_close;
define rend_stdin_on;
define rend_stdin_off;
define rend_stdin_get;
%include 'rend2.ins.pas';
%include 'rend_stdin.ins.pas';

var
  stdin: rend_stdin_t;                 {STDIN handling state}
{
********************************************************************************
*
*   Subroutine REND_STDIN_INIT
*
*   Initialize the STDIN reading state, STDIN.
}
procedure rend_stdin_init;             {init STDIN state}
  val_param;

begin
  stdin.line.max := size_char(stdin.line.str);
  stdin.line.len := 0;
  stdin.hline := false;
  stdin.on := false;

  rend_stdin_sys_init (stdin);         {initialize system-dependent routines}
  end;
{
********************************************************************************
*
*   Subroutine REND_STDIN_CLOSE
*
*   End the use of the STDIN reading state and deallocate all associated
*   resources.
}
procedure rend_stdin_close;            {end STDIN reading, deallocate resources}
  val_param;

begin
  if stdin.on then begin               {the thread is running ?}
    rend_stdin_off;                    {stop it}
    end;

  rend_stdin_sys_close (stdin);        {deallocate system-dependent resources}
  end;
{
********************************************************************************
*
*   Subroutine REND_STDIN_ON
*
*   Make sure that STDIN events are enabled.
}
procedure rend_stdin_on;               {enable STDIN events}
  val_param;

begin
  if stdin.on then return;             {already on, nothing to do ?}

  rend_stdin_sys_on (stdin);           {start STDIN reading}
  end;
{
********************************************************************************
*
*   Subroutine REND_STDIN_OFF
*
*   Make sure that STDIN events are disabled.
}
procedure rend_stdin_off;              {disable STDIN events}
  val_param;

begin
  if not stdin.on then return;         {already off, nothing more to do ?}

  rend_stdin_sys_off (stdin);          {stop STDIN reading}
  end;
{
********************************************************************************
*
*   Subroutine REND_STDIN_GET (LINE)
*
*   Get the last STDIN line.  This call is only valid after a STDIN_LINE event
*   was received.  Otherwise, LINE is set to the empty string.
}
procedure rend_stdin_get (             {get STDIN line, only valid after event}
  in out  line: univ string_var_arg_t); {returned STDIN line}
  val_param;

begin
  string_copy (stdin.line, line);      {return the current saved line}
  stdin.hline := false;                {there is no saved STDIN line}
  rend_stdin_sys_gotline (stdin);      {notify now done with LINE}
  end;
