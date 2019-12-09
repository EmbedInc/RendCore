{   Subroutine REND_SW_ITERP_ICLAMP (ITERP,ON)
*
*   Turn interpolator clamping on/off.
}
module rend_sw_iterp_iclamp;
define rend_sw_iterp_iclamp;
%include 'rend_sw2.ins.pas';

procedure rend_sw_iterp_iclamp (       {turn interpolator output clamping on/off}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param;

begin
  if rend_iterps.iterp[iterp].iclamp = on then return; {nothing to do here ?}
  rend_iterps.iterp[iterp].iclamp := on;
  rend_internal.check_modes^;
  end;
