{   Subroutine REND_SW_SHADE_GEOM (GEOM_MODE)
*
*   Set what level of interpolation geometry should be set up for when interpolants
*   are implicitly defined.  For example, is GEOM_MODE indidates linear interpolation,
*   then 3 points on the geometry will be computed with full interpolant (color)
*   information.  These three points will be used to set up linear color surfaces
*   (if the interpolants envolved are enabled for linear interpolation).  If
*   GEOM_MODE indicates quadratic interpolation, then 6 points are computed with
*   full interpolant values.  Note that the SHADE_MODE value for each individual
*   interpolant controlls what interpolation is actually performed.
}
module rend_sw_shade_geom;
define rend_sw_shade_geom;
%include 'rend_sw2.ins.pas';

procedure rend_sw_shade_geom (         {set geometry mode for implicit color gen}
  in      geom_mode: rend_iterp_mode_k_t); {flat, linear, etc}
  val_param;

begin
  if geom_mode = rend_shade_geom then return; {no state change ?}
  rend_shade_geom := geom_mode;        {set state to new value}
  rend_internal.check_modes^;          {set modes for this new state}
  end;
