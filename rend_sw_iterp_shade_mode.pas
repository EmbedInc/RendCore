{   Subroutine REND_SW_ITERP_SHADE_MODE (ITERP,SHMODE)
*
*   Set the interpolation mode to be used for implicitly defined colors.
*   Color values are implicitly defined when a geometric primitive also contains
*   information defining the colors, such as the TRI_3D primitive, for example.
*   This routine actually can be used for any interpolant and is not really
*   limited to the RGB colors.
}
module rend_sw_iterp_shade_mode;
define rend_sw_iterp_shade_mode;
%include 'rend_sw2.ins.pas';

procedure rend_sw_iterp_shade_mode (   {set interpolation mode for implicit colors}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      shmode: sys_int_machine_t);  {one of the REND_ITERP_MODE_xx_K values}
  val_param;

begin
  if rend_iterps.iterp[iterp].shmode = shmode then return; {no change in state ?}
  rend_iterps.iterp[iterp].shmode := shmode; {set new SHMODE for this interpolant}
  rend_internal.check_modes^;          {reevaluate state now that mode got changed}
  end;
