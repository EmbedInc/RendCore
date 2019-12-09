{   Subroutine REND_SW_FORCE_SW_UPDATE (ON)
*
*   ON = TRUE forces the software copy of the bitmap to be kept up to date,
*   regardless of whether the device could have performed the drawing locally.
*   When ON = FALSE, RENDlib only writes to the software bitmap as necessary to
*   emulate features not available in the hardware.
}
module rend_sw_force_sw_update;
define rend_sw_force_sw_update;
%include 'rend_sw2.ins.pas';

procedure rend_sw_force_sw_update (    {force SW bitmap update ON/OFF}
  in      on: boolean);                {TRUE means force keep SW bitmap up to date}
  val_param;

begin
  if rend_force_sw = on then return;
  rend_force_sw := on;
  rend_internal.check_modes^;
  end;
