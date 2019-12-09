{   Subroutine REND_SW_ALPHA_ON (ON)
*
*   Turn alpha buffer blending on/off.
}
module rend_sw_alpha_on;
define rend_sw_alpha_on;
%include 'rend_sw2.ins.pas';

procedure rend_sw_alpha_on (           {turn alpha compositing on/off}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param;

begin
  if rend_alpha_on = on then return;   {nothing to do ?}
  rend_alpha_on := on;
  rend_internal.check_modes^;          {update routine pointers and device modes}
  end;
