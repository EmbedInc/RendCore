{   Subroutine REND_SW_LIN_VALS (ITERP,V1,V2,V3)
*
*   Specify the values of an interpolant at the previously specified geom points.
*   This information will be used to set the interpolant to linear interpolation
*   such that the given values will be obtained at the specified geom coordinates.
}
module rend_sw_lin_vals;
define rend_sw_lin_vals;
%include 'rend_sw2.ins.pas';

procedure rend_sw_lin_vals (           {set linear interp by giving corner values}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      v1, v2, v3: real);           {values at previously given coordinates}
  val_param;

var
  di2, di3: real;                      {interpolant deltas from point V1}
  dx, dy: real;                        {partial derivative in X and Y direction}

label
  flat_shading;

begin
  if not rend_geom.valid then goto flat_shading; {gemoetry definition no good ?}
  di2 := v2 - v1;                      {make interpolant delta from anchor point}
  di3 := v3 - v1;
  dx := (rend_geom.p2.dy*di3 - rend_geom.p3.dy*di2); {X partial derivative}
  if (dx > 2.0) or (dx < -2.0) then goto flat_shading;
  dy := (rend_geom.p3.dx*di2 - rend_geom.p2.dx*di3); {Y partial derivative}
  if (dy > 2.0) or (dy < -2.0) then goto flat_shading;
  rend_set.iterp_linear^ (             {set linear surface for this interpolant}
    iterp,                             {interpolant ID}
    rend_geom.p1.coor,                 {XY coordinate of anchor point}
    v1,                                {value of interpolant at anchor point}
    dx,                                {interpolant derivative in X direction}
    dy);                               {interpolant derivative in Y direction}
  return;

flat_shading:
  rend_set.iterp_flat^ (               {set interpolant to flat surface}
    iterp,                             {interpolant ID}
    (v1+v2+v3)*0.333333);              {average value}
  end;
