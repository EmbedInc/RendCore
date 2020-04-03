{   System dependent part of STDIN handling.
*
*   This version is for the Win32 API.
}
module rend_stdin_sys;
define rend_stdin_sys_init;
define rend_stdin_sys_close;
%include 'rend2.ins.pas';
%include 'rend_stdin.ins.pas';
{
********************************************************************************
*
*   Subroutine REND_STDIN_SYS_INIT (STDIN)
*
*   Initialize any system-specific state related to reading STDIN.
}
procedure rend_stdin_sys_init (        {initialize the system-dependent part}
  in out  stdin: rend_stdin_t);        {STDIN reading state}
  val_param;

begin
	end;
{
********************************************************************************
*
*   Subroutine REND_STDIN_SYS_CLOSE (STDIN)
*
*   Deallocate any system-dependent resources associated with reading STDIN.
}
procedure rend_stdin_sys_close (       {deallocate system-dependent STDIN resources}
  in out  stdin: rend_stdin_t);        {STDIN reading state}
  val_param;

begin
	end;
