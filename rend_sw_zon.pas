{   Subroutine REND_SW_ZON (ON)
*
*   Turn Z buffering on/off.  To do hidden surface removal by Z buffering, Z buffering
*   must be turned on, the Z interpolant must be on, and a Z function must be set.
}
module rend_sw_zon;
define rend_sw_zon;
%include 'rend_sw2.ins.pas';

procedure rend_sw_zon (
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param;

begin
  if rend_zon = on then return;        {nothing to do ?}
  rend_zon := on;                      {save Z function code in common block}
  rend_internal.check_modes^;          {update routine pointers and device modes}
  end;
