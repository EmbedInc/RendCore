{   Subroutine REND_SW_RGBZ_QUAD (V1,V2,V3,V4,V5,V6)
*
*   Set a quadratic surface definition for red, green, and blue, and set a linear
*   surface definition for Z.  The verticies V1-V6 each contain 6 floating point
*   numbers in the order XYZRGB.  Verticies V1-V3 are used to compute the linear
*   Z surface.  The remaining verticies (V4-V6) are used together with V1-V3 to
*   compute the quadratic RGB surfaces.  The Z values of V4-V6 are ignored.
}
{
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*   ::        CONFIDENTIAL AND PROPRIETARY INFORMATION OF        ::
*   ::                    COGNIVISION, INC.                      ::
*   ::           PROTECTED BY THE COPYRIGHT LAW AS AN            ::
*   ::                    UNPUBLISHED WORK                       ::
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}
module rend_sw_rgbz_quad;
define rend_sw_rgbz_quad;
%include 'rend_sw2.ins.pas';
%include 'math.ins.pas';

procedure rend_sw_rgbz_quad (          {set quadratic RGB and linear Z values}
  in      v1, v2, v3: rend_color3d_t;  {XYZ,RGB points used to make linear Z}
  in      v4, v5, v6: rend_color3d_t); {extra points used to make quad RGB, Z unused}

type
  equation_type = record               {the stuff for one of the linear equations}
    dx: real;                          {coefficient for X delta from vertex 1}
    dy: real;                          {coefficient for Y delta from vertex 1}
    dxx: real;                         {coef for second X derivative}
    dyy: real;                         {coef for second Y derivative}
    dxy: real;                         {coef for crossover derivative}
    di: real;                          {coef for intensity delta from vertex 1}
    end;

  answer_type = record                 {what comes out of the matrix solver}
    d1x: real;                         {partial derivative of I in X}
    d1y: real;                         {partial derivative of I in Y}
    d2xx: real;                        {second partial in X}
    d2yy: real;                        {second partial in Y}
    d2xy: real;                        {crossover partial}
    end;

var
  mat: array[1..5] of equation_type;   {lin equations to solve for differentials}
  ans: answer_type;                    {answer to matrix solution}
  i: integer32;                        {loop counter}
  valid: boolean;                      {linear equations solve was succesful}
  d: real;                             {determinant used for computing derivatives}
  dx2, dx3, dy2, dy3: real;            {geometric deltas from point V1}
  di2, di3: real;                      {interpolant deltas from point V1}
  c: vect_2d_t;                        {2d coordinates of anchor point}

label
  no_quad, do_z;

begin
  c.x := v1.x;                         {copy 2d anchor point for interpolants}
  c.y := v1.y;
{
*   We now need to solve for the derivatives of the colors.  We will use
*   vertex one as the anchor point.  This leaves five simultaneaous equations
*   to describe the color deltas for each remaining vertex from vertex 1.
*   The simultaneous equations have the form:
*
*   d1x[dx] + d1y[dy] + d2xx[dx**2/2] + d2yy[dy**2/2] + d2xy[dx*dy] = [di]
*
*   The values in the brackets are values we have from the color and coordinate
*   information, and are different for each equation.  The values outside the
*   brackets are the derivatives we are trying to solve for.  We have to do
*   this solution once for each R, G, and B.  First stuff in the values that
*   are dependent on just the geometry and not the colors, and init the non-color
*   part of the surface definition.  We start this by filling in the DX and DY
*   terms in each equation.  We then use a loop to compute the other three terms
*   from the DX and DY.
}
  mat[1].dx := v2.x - v1.x;
  mat[1].dy := v2.y - v1.y;
  mat[2].dx := v3.x - v1.x;
  mat[2].dy := v3.y - v1.y;
  mat[3].dx := v4.x - v1.x;
  mat[3].dy := v4.y - v1.y;
  mat[4].dx := v5.x - v1.x;
  mat[4].dy := v5.y - v1.y;
  mat[5].dx := v6.x - v1.x;
  mat[5].dy := v6.y - v1.y;
  for i := 1 to 5 do begin             {once for each equation}
    mat[i].dxx := 0.5 * mat[i].dx * mat[i].dx;
    mat[i].dyy := 0.5 * mat[i].dy * mat[i].dy;
    mat[i].dxy := mat[i].dx * mat[i].dy;
    end;                               {back and fill in next equation in matrix}
{
*   Done with just the geometric information.  Now process each color.
}
  mat[1].di := v2.red - v1.red;        {load the color deltas into matrix}
  mat[2].di := v3.red - v1.red;
  mat[3].di := v4.red - v1.red;
  mat[4].di := v5.red - v1.red;
  mat[5].di := v6.red - v1.red;
  math_simul (5, mat, ans, valid);     {try solve linear equations}
  if not valid then goto no_quad;      {can't solve quadratic, try linear ?}
  rend_set.iterp_quad^ (               {set this interpolant to quadratic}
    rend_iterp_red_k,                  {identifier for this interpolant}
    c,                                 {anchor point}
    v1.red,                            {value at anchor point}
    ans.d1x, ans.d1y,                  {first partials at anchor point}
    ans.d2xx, ans.d2yy, ans.d2xy);     {second derivatives}

  mat[1].di := v2.grn - v1.grn;        {load the color deltas into matrix}
  mat[2].di := v3.grn - v1.grn;
  mat[3].di := v4.grn - v1.grn;
  mat[4].di := v5.grn - v1.grn;
  mat[5].di := v6.grn - v1.grn;
  math_simul (5, mat, ans, valid);     {try solve linear equations}
  if not valid then goto no_quad;      {can't solve quadratic, try linear ?}
  rend_set.iterp_quad^ (               {set this interpolant to quadratic}
    rend_iterp_grn_k,                  {identifier for this interpolant}
    c,                                 {anchor point}
    v1.grn,                            {value at anchor point}
    ans.d1x, ans.d1y,                  {first partials at anchor point}
    ans.d2xx, ans.d2yy, ans.d2xy);     {second derivatives}

  mat[1].di := v2.blu - v1.blu;        {load the color deltas into matrix}
  mat[2].di := v3.blu - v1.blu;
  mat[3].di := v4.blu - v1.blu;
  mat[4].di := v5.blu - v1.blu;
  mat[5].di := v6.blu - v1.blu;
  math_simul (5, mat, ans, valid);     {try solve linear equations}
  if not valid then goto no_quad;      {can't solve quadratic, try linear ?}
  rend_set.iterp_quad^ (               {set this interpolant to quadratic}
    rend_iterp_blu_k,                  {identifier for this interpolant}
    c,                                 {anchor point}
    v1.blu,                            {value at anchor point}
    ans.d1x, ans.d1y,                  {first partials at anchor point}
    ans.d2xx, ans.d2yy, ans.d2xy);     {second derivatives}
  goto do_z;                           {done with colors, compute Z surface}
{
*   The color second derivatives were too large.  Set to flat shading using the
*   average color.
}
no_quad:
  rend_set.iterp_flat^ (               {set red to flat color}
    rend_iterp_red_k,                  {interpolant ID}
    (v1.red + v2.red + v3.red + v4.red + v5.red + v6.red)*0.166666); {average}
  rend_set.iterp_flat^ (               {set green to flat color}
    rend_iterp_grn_k,                  {interpolant ID}
    (v1.grn + v2.grn + v3.grn + v4.grn + v5.grn + v6.grn)*0.166666); {average}
  rend_set.iterp_flat^ (               {set blue to flat color}
    rend_iterp_blu_k,                  {interpolant ID}
    (v1.blu + v2.blu + v3.blu + v4.blu + v5.blu + v6.blu)*0.166666); {average}
{
*   All done with the RGB color values.  Now compute and set the Z surface.
}
do_z:
  dx2 := v2.x - v1.x;                  {compute geometric deltas from vertex 1}
  dy2 := v2.y - v1.y;
  dx3 := v3.x - v1.x;
  dy3 := v3.y - v1.y;
  d := dx3*dy2 - dx2*dy3;              {twice area of triangle}
  if abs(d) < 1.0E-10 then begin       {not enough area to define linear surface ?}
    rend_set.iterp_flat^ (
      rend_iterp_z_k,                  {ID of interpolant to set to constant value}
      (v1.z+v2.z+v3.z)*0.3333333);     {average value}
    return;
    end;
  d := 1.0/d;                          {mult factor for derivatives}

  di2 := v2.z - v1.z;                  {make interpolant delta from point V1}
  di3 := v3.z - v1.z;
  rend_set.iterp_linear^ (             {set linear surface for this interpolant}
    rend_iterp_z_k,                    {ID for this interpolant}
    c,                                 {XY coordinates of anchor point}
    v1.z,                              {value of interpolant at anchor point}
    (dy2*di3 - dy3*di2)*d,             {partial derivative in X direction}
    (dx3*di2 - dx2*di3)*d);            {partial derivative in Y direction}
  end;
