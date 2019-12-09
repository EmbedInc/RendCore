{   This file contains the system-dependent parts of REND_EVENTS.PAS.
*
*   This version is for the Microsoft Win32 API.
}
%include 'sys_sys2.ins.pas';

var
  readin_h: win_handle_t               {handle to thread trying to read next in line}
    := handle_none_k;                  {init to no thread active}
  readin_err: boolean := false;        {can't seem to launch STDIN read thread}
{
**********************************************************
*
*   Function REND_WIN_THREAD_STDIN (DUMMY)
*
*   This function is the main routine for the thread that tries to read the next
*   line from standard input.  The call argument and the function return
*   value are not used.
}
function rend_win_thread_stdin (
  in      dummy: sys_int_adr_t)
  :sys_int_adr_t;
  val_param;

begin
  rend_win_thread_stdin := 0;          {set function return value, unused}
  string_readin (rend_stdin_line);     {read in the next standard input line}
  rend_stdin_done := true;             {indicate we have a new input line}
  readin_h := handle_none_k;           {indicate no longer looking for STDIN line}
  end;                                 {terminate the thread}
{
**********************************************************
*
*   Subroutine CHECK_STDIN
*
*   This subroutine is called from REND_EVENT_GET2 when standard input line
*   events are enabled.  If a standard input line event is available, then
*   the input line is placed into REND_STDIN_LINE, and REND_STDIN_DONE is
*   set to TRUE.
}
procedure check_stdin;                 {check for text line available from STDIN}

var
  thread_id: win_dword_t;              {ID of new thread, unused}
  stat: sys_err_t;

begin
  if readin_h <> handle_none_k then return; {already reading next stdin line ?}

  if readin_err then begin             {we can't start thread for some reason}
    rend_evglb :=                      {disable standard input line event}
      rend_evglb - [rend_evglb_stdin_line_k];
    return;
    end;

  readin_h := CreateThread (           {create thread to read next STDIN line}
    nil,                               {no security information supplied}
    0,                                 {use default stack size}
    addr(rend_win_thread_stdin),       {pointer to main thread routine}
    nil,                               {argument passed to thread routine}
    [],                                {additional thread creation flags}
    thread_id);                        {returned ID of new thread}
  if readin_h = handle_none_k then begin {failed to launch thread ?}
    readin_err := true;                {prevent trying over and over again}
    if rend_debug_level >= 1 then begin
      sys_error_none (stat);
      stat.sys := GetLastError;
      sys_error_print (stat, 'rend_win', 'thrad_start_stdin', nil, 0);
      end;
    return;
    end;

  discard( CloseHandle(readin_h) );    {release handle to the thread}
  end;
