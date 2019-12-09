{   Collection of routines that help handling messages and errors when
*   using RENDlib.
}
module rend_message;
define rend_error_abort;
define rend_message_bomb;
%include 'rend2.ins.pas';
{
************************************
*
*   Subroutine REND_ERROR_ABORT (STAT,SUBSYS_NAME,MSG_NAME,PARMS,N_PARMS)
*
*   Just line SYS_ERROR_ABORT, except that RENDlib is closed first if STAT does
*   indicate an error condition.
}
procedure rend_error_abort (           {close RENDlib, print msg and bomb if error}
  in      stat: sys_err_t;             {error code}
  in      subsys_name: string;         {subsystem name of caller's message}
  in      msg_name: string;            {name of caller's message within subsystem}
  in      parms: univ sys_parm_msg_ar_t; {array of parameter descriptors}
  in      n_parms: sys_int_machine_t); {number of parameters in PARMS}
  val_param;

begin
  if not sys_error(stat) then return;  {no error condition ?}
  rend_end;                            {close RENDlib and deallocate resources}
  sys_error_abort (stat, subsys_name, msg_name, parms, n_parms);
  end;
{
************************************
*
*   Subroutine REND_MESSAGE_BOMB (SUBSYS,MSG,PARMS,N_PARMS)
*
*   Just like SYS_MESSAGE_BOMB, except that RENDlib is closed first.
}
procedure rend_message_bomb (          {close RENDlib, print message, then bomb}
  in      subsys: string;              {name of subsystem, used to find message file}
  in      msg: string;                 {message name withing subsystem file}
  in      parms: univ sys_parm_msg_ar_t; {array of parameter descriptors}
  in      n_parms: sys_int_machine_t); {number of parameters in PARMS}
  options (val_param, noreturn);

begin
  rend_end;                            {close RENDlib}
  sys_message_bomb (subsys, msg, parms, n_parms);
  end;
