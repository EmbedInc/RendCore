{   Subroutine REND_SW_QUAD_VALS (ITERP,V1,V2,V3,V4,V5,V6)
*
*   Declare interpolant values at the geom points set earlier.  This information
*   is used to set the interpolant to quadratic interpolation, such that the
*   the values given here are achieved at the geom points set earlier.
}
module rend_sw_quad_vals;
define rend_sw_quad_vals;
%include 'rend_sw2.ins.pas';
%include 'math.ins.pas';

procedure rend_sw_quad_vals (          {set quad interp by giving vals at 6 points}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      v1, v2, v3, v4, v5, v6: real); {values at previously given coordinates}
  val_param;

type
  answer_type = record                 {what comes out of the matrix solver}
    d1x: real;                         {partial derivative of I in X}
    d1y: real;                         {partial derivative of I in Y}
    d2xx: real;                        {second partial in X}
    d2yy: real;                        {second partial in Y}
    d2xy: real;                        {crossover partial}
    end;

var
  ans: answer_type;                    {answer to matrix solution}
  valid: boolean;                      {quadratic equations solve was succesful}
  dx, dy: real;                        {partial derivative in X and Y direction}

label
  linear, flat;

begin
  if not rend_geom.valid then goto flat; {punt to flat shading ?}
  rend_geom.mat[1].di := v2 - v1;      {load the color deltas into rend_geom.matrix}
  rend_geom.mat[2].di := v3 - v1;
  rend_geom.mat[3].di := v4 - v1;
  rend_geom.mat[4].di := v5 - v1;
  rend_geom.mat[5].di := v6 - v1;
  math_simul (                         {try to solve matrix to get derivatives}
    5,                                 {number of simultaneous equations}
    rend_geom.mat,                     {matrix with equation coeficients}
    ans,                               {returned variable values}
    valid);                            {returned TRUE if unique solution exists}
  if not valid then goto linear;       {can't solve quadratic, revert to linear}

  if ans.d1x > 2.0 then goto linear;
  if ans.d1x < -2.0 then goto linear;
  if ans.d1y > 2.0 then goto linear;
  if ans.d1y < -2.0 then goto linear;
  if ans.d2xx > 2.0 then goto linear;
  if ans.d2xx < -2.0 then goto linear;
  if ans.d2yy > 2.0 then goto linear;
  if ans.d2yy < -2.0 then goto linear;
  if ans.d2xy > 2.0 then goto linear;
  if ans.d2xy < -2.0 then goto linear;

  rend_set.iterp_quad^ (               {set this interpolant to quadratic}
    iterp,                             {identifier for this interpolant}
    rend_geom.p1.coor,                 {anchor point}
    v1,                                {value at anchor point}
    ans.d1x, ans.d1y,                  {first partials at anchor point}
    ans.d2xx, ans.d2yy, ans.d2xy);     {second derivatives}
  return;                              {quadratic set successfully, all done}
{
*   The geometry was flagged as valid, but a quadratic solution was either not
*   possible, or the resulting values were out of range.  Try a linear solution.
}
linear:
  dx := rend_geom.p2.dy*rend_geom.mat[2].di - {X partial derivative}
    rend_geom.p3.dy*rend_geom.mat[1].di;
  if (dx > 2.0) or (dx < -2.0) then goto flat;
  dy := rend_geom.p3.dx*rend_geom.mat[1].di - {Y partial derivative}
    rend_geom.p2.dx*rend_geom.mat[2].di;
  if (dy > 2.0) or (dy < -2.0) then goto flat;
  rend_set.iterp_linear^ (             {set linear surface for this interpolant}
    iterp,                             {interpolant ID}
    rend_geom.p1.coor,                 {XY coordinate of anchor point}
    v1,                                {value of interpolant at anchor point}
    dx,                                {interpolant derivative in X direction}
    dy);                               {interpolant derivative in Y direction}
  return;
{
*   Jump to here if quadratic is not possible.  The 6 color values will be averaged
*   and the interpolant will be set to flat interpolation.
}
flat:
  rend_set.iterp_flat^ (               {set to flat color}
    iterp,                             {interpolant ID}
    (v1 + v2 + v3 + v4 + v5 + v6)*0.166666); {average}
  end;
