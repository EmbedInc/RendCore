{   Subroutine REND_SW_RESET_REFRESH
*
*   Reset the device after a window shakeup.  This routine is called from the
*   window shakeup handler after the device with the shakeup is swapped in.
*   This routine is installed in the REND_INTERNAL call table.
}
module rend_sw_reset_refresh;
define rend_sw_reset_refresh;
%include 'rend_sw2.ins.pas';

procedure rend_sw_reset_refresh;

begin
  rend_set.dev_reconfig^;              {SW device needs to do nothing special}
  end;
