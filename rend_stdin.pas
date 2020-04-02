{   Routines related to standard input events.
}
module rend_stdin;
define rend_stdin_init;
define rend_stdin_close;
define rend_stdin_on;
define rend_stdin_off;
define rend_stdin_get;
%include 'rend2.ins.pas';
{
********************************************************************************
*
*   Subroutine REND_STDIN_INIT (STDIN)
*
*   Initialize the STDIN reading state, STDIN.
}
procedure rend_stdin_init (            {init STDIN state}
  out     stdin: rend_stdin_t);        {state to initialize}
  val_param;

begin
  stdin.line.max := size_char(stdin.line.str);
  stdin.line.len := 0;
  sys_event_create_bool (stdin.evbreak);
  sys_event_create_bool (stdin.evstopped);
  stdin.hline := false;
  stdin.on := false;
  end;
{
********************************************************************************
*
*   Subroutine REND_STDIN_CLOSE (STDIN)
*
*   End the use of the STDIN reading state and deallocate all associated
*   resources.
}
procedure rend_stdin_close (           {end STDIN reading, deallocate resources}
  in out  stdin: rend_stdin_t);        {state to deallocate resources of}
  val_param;

begin
  if stdin.on then begin               {the thread is running ?}
    rend_stdin_off (stdin);            {stop it}
    end;

  sys_event_del_bool (stdin.evbreak);  {delete the events}
  sys_event_del_bool (stdin.evstopped);
  end;
{
********************************************************************************
*
*   Subroutine REND_STDIN_ON (STDIN)
*
*   Make sure that STDIN events are enabled.
}
procedure rend_stdin_on (              {enable STDIN events}
  in out  stdin: rend_stdin_t);        {STDIN reading state}
  val_param;

begin
  if stdin.on then return;             {already on, nothing to do ?}


{***  FILL IN CODE HERE TO LAUNCH THE THREAD. ***}


  end;
{
********************************************************************************
*
*   Subroutine REND_STDIN_OFF (STDIN)
*
*   Make sure that STDIN events are disabled.
}
procedure rend_stdin_off (             {disable STDIN events}
  in out  stdin: rend_stdin_t);        {STDIN reading state}
  val_param;

var
  stat: sys_err_t;

begin
  if not stdin.on then return;         {already off, nothing more to do ?}

  stdin.on := false;                   {tell thread to exit}
  sys_event_notify_bool (stdin.evbreak); {cause thread to wake up}
  sys_event_wait (stdin.evstopped, stat); {wait for thread to stop}
  sys_error_abort (stat, '', '', nil, 0);
  end;
{
********************************************************************************
*
*   Subroutine REND_STDIN_GET (STDIN, LINE)
*
*   Get the last STDIN line.  This call is only valid after a STDIN_LINE event
*   was received.  Otherwise, LINE is set to the empty string.
}
procedure rend_stdin_get (             {get STDIN line, only valid after event}
  in out  stdin: rend_stdin_t;         {STDIN reading state}
  in out  line: univ string_var_arg_t); {returned STDIN line}
  val_param;

begin
  string_copy (stdin.line, line);      {return the current saved line}
  stdin.line.len := 0;                 {reset the line to empty}
  stdin.hline := false;                {there is no saved STDIN line}
  sys_event_notify_bool (stdin.evbreak); {wake up thread to see the state change}
  end;
