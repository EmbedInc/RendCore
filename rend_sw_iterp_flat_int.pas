{   Subroutine REND_SW_ITERP_FLAT_INT (ITERP,VAL)
*
*   Set the interpolant identified by ITERP to FLAT interpolation mode, and set
*   its value to the integer VAL.  Bits below the binary point, if any, will be
*   set to zero.  Higher order bits beyond the interpolant's width will be ignored.
}
module rend_sw_iterp_flat_int;
define rend_sw_iterp_flat_int;
%include 'rend_sw2.ins.pas';

procedure rend_sw_iterp_flat_int(      {set interpolation to flat integer value}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      val: sys_int_machine_t);     {new raw interpolant value}
  val_param;

begin
  rend_iterps.iterp[iterp].val.all := val; {set to new integer value}

  if  (rend_iterps.iterp[iterp].mode = rend_iterp_mode_flat_k) and
      (rend_iterps.iterp[iterp].int = true)
    then return;                       {no modes being changed ?}
  rend_iterps.iterp[iterp].mode := rend_iterp_mode_flat_k;
  rend_iterps.iterp[iterp].int := true;
  rend_internal.check_modes^;          {update routine pointers and device modes}
  end;
