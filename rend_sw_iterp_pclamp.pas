{   Subroutine REND_SW_ITERP_PCLAMP (ITERP,ON)
*
*   Turn pixel function clamping on/off.
}
module rend_sw_iterp_pclamp;
define rend_sw_iterp_pclamp;
%include 'rend_sw2.ins.pas';

procedure rend_sw_iterp_pclamp (       {turn pixel function output clamping on/off}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param;

begin
  if rend_iterps.iterp[iterp].pclamp = on then return; {nothing to do ?}
  rend_iterps.iterp[iterp].pclamp := on;
  rend_internal.check_modes^;          {update routine pointers and device modes}
  end;
