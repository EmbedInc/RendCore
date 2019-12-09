{   Subroutine REND_SW_DEV_Z_CURR (CURR)
*
*   Declare whether or not the current device Z buffer is to be considered up to
*   date.
}
module rend_sw_dev_z_curr;
define rend_sw_dev_z_curr;
%include 'rend_sw2.ins.pas';

procedure rend_sw_dev_z_curr (         {indicate whether device Z is current}
  in      curr: boolean);              {TRUE if declare device Z to be current}
  val_param;

begin
  end;
