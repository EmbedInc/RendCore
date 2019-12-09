{   Subroutine REND_SW_ITERP_AA (ITERP,ON)
*
*   Turn anti-aliasing ON/OFF for this interpolant.  TRUE is on, FALSE if off.
*   When anti-aliasing is on, the interpolator output is replaced with the
*   anti-aliased value for each pixel.  All other pixel funtions, etc. remain
*   in effect.  Anti-aliasing is only done when the anti-aliasing primitive is
*   used (REND_PRIM.ANTI_ALIAS).  Other global anti-aliasing state is controlled
*   with REND_SET.AA_SCALE.
}
module rend_sw_iterp_aa;
define rend_sw_iterp_aa;
%include 'rend_sw2.ins.pas';

procedure rend_sw_iterp_aa (           {turn anti-aliasing ON/OFF for this iterp}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      on: boolean);                {anti-aliasing override interpolator value ON}
  val_param;

begin
  with rend_iterps.iterp[iterp]: it do begin {IT is state for this interpolant}
    if it.aa = on then return;         {state already set the way requested}
    it.aa := on;                       {set new ON/OFF state}
    rend_internal.check_modes^;        {re-evaluate new state}
    end;                               {done with IT abbreviation}
  end;
