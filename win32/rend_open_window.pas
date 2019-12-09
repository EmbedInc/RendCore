{   Subroutine REND_OPEN_WINDOW (DEVNAME, PARMS, STAT)
*
*   Open the WINDOW RENDlib inherent device.  The call arguments are the
*   standard set passed to drivers to do an open.  DEVNAME is the name
*   of the RENDlib device, in this case "WINDOW".  PARMS is an optional
*   string of parameters.  STAT is the completion status code.
*
*   PARMS may contain a window specifier string as described in module
*   STRING_WINDOW.
*
*   This routine is system-dependent.  This version is for Windows.
}
module rend_open_window;
define rend_open_window;
%include 'rend2.ins.pas';

procedure rend_win_init (              {device is a window in Microsoft Windows}
  in      dev_name: univ string_var_arg_t; {RENDlib inherent device name}
  in      parms: univ string_var_arg_t; {parameters passed from application}
  out     stat: sys_err_t);            {error return code}
  extern;

procedure rend_open_window (           {open WINDOW RENDlib inherent device}
  in      devname: univ string_var_arg_t; {RENDlib inherent device name}
  in      parms: univ string_var_arg_t; {paramters string}
  out     stat: sys_err_t);            {completion status code}

begin
  rend_win_init (devname, parms, stat);
  end;
