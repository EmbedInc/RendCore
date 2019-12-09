{   Subroutine REND_OPEN_SCREEN (DEVNAME, PARMS, STAT)
*
*   Open the SCREEN RENDlib inherent device.  The call arguments are the
*   standard set passed to drivers to do an open.  DEVNAME is the name
*   of the RENDlib device, in this case "SCREEN".  PARMS is an optional
*   string of parameters.  STAT is the completion status code.
*
*   PARMS may contain a screen specifier string as described in module
*   STRING_SCREEN.
*
*   This routine is system-dependent.  This version is for Windows.
}
module rend_OPEN_SCREEN;
define rend_open_screen;
%include 'rend2.ins.pas';

procedure rend_win_init (              {device is a window in Microsoft Windows}
  in      dev_name: univ string_var_arg_t; {RENDlib inherent device name}
  in      parms: univ string_var_arg_t; {parameters passed from application}
  out     stat: sys_err_t);            {error return code}
  extern;

procedure rend_open_screen (           {open SCREEN RENDlib inherent device}
  in      devname: univ string_var_arg_t; {RENDlib inherent device name}
  in      parms: univ string_var_arg_t; {paramters string}
  out     stat: sys_err_t);            {completion status code}

begin
  rend_win_init (devname, parms, stat);
  end;
