{   Subroutine REND_SW_LIN_VALS_RGBA (V1, V2, V3)
*
*   Define the red, green, blue, and alpha values at the coordinates previously
*   specified with routine LIN_GEOM_2DIM.  Since alpha and the colors are all being
*   interpolated, it is assumed that an alpha function will be used, and therefore
*   the colors will be premultiplied by alpha.  Since the colors and alpha are
*   linear functions, the resulting color values will be quadratic functions.
*   This routine will set up red, green, and blue for quadratic interpolation, and
*   alpha for linear interpolation.
}
module rend_sw_lin_vals_rgba;
define rend_sw_lin_vals_rgba;
%include 'rend_sw2.ins.pas';

procedure rend_sw_lin_vals_rgba (      {premult RGB by A, set quad RGB, linear A}
  in      v1, v2, v3: rend_rgba_t);    {RGBA at each previously given coordinate}
  val_param;

var
  di2, di3: real;                      {interpolant deltas from point V1}
  dadx, dady: real;                    {alpha derivatives}
  didx, didy: real;                    {derivatives for color before alpha mult}
  check_modes: univ_ptr;               {saved copy of check_modes procedure pointer}
  val: real;                           {final color value at anchor point}
  dx, dy: real;                        {final color first derivatives}
  dxx, dyy, dxy: real;                 {final color second derivatives}

label
  flat_interp, done;

begin
  rend_sw_save_cmode (check_modes);    {save old CHECK_MODES and set dummy}
  if not rend_geom.valid then goto flat_interp; {punt to flat interpolation}
{
*   Set alpha as normal linear interpolation.
}
  di2 := v2.alpha - v1.alpha;          {make interpolant delta from anchor point}
  di3 := v3.alpha - v1.alpha;
  dadx :=                              {derivative in X direction}
    (rend_geom.p2.dy*di3 - rend_geom.p3.dy*di2);
  if (dadx > 2.0) or (dadx < -2.0) then goto flat_interp;
  dady :=                              {derivative in Y direction}
    (rend_geom.p3.dx*di2 - rend_geom.p2.dx*di3);
  if (dady > 2.0) or (dady < -2.0) then goto flat_interp;
  rend_set.iterp_linear^ (             {set linear interpolation coeficients}
    rend_iterp_alpha_k,                {ID of interpolant to set to linear}
    rend_geom.p1.coor,                 {XY coordinates of anchor point}
    v1.alpha,                          {interpolant value at anchor point}
    dadx,                              {partial derivative in X direction}
    dady);                             {partial derivative in Y direction}
{
*   Set red to quadratic function after multiply by alpha value.
}
  di2 := v2.red - v1.red;              {make interpolant delta from anchor point}
  di3 := v3.red - v1.red;
  didx :=                              {derivative in X direction}
    (rend_geom.p2.dy*di3 - rend_geom.p3.dy*di2);
  didy :=                              {derivative in Y direction}
    (rend_geom.p3.dx*di2 - rend_geom.p2.dx*di3);
  val := v1.red*v1.alpha;              {value at anchor point}
  dx := v1.red*dadx + v1.alpha*didx;   {X first derivative at anchor point}
  if (dx > 2.0) or (dx < -2.0) then goto flat_interp;
  dy := v1.red*dady + v1.alpha*didy;   {Y first derivative at anchor point}
  if (dy > 2.0) or (dy < -2.0) then goto flat_interp;
  dxx := 2.0*didx*dadx;                {second derivative in X direction}
  if (dxx > 2.0) or (dxx < -2.0) then goto flat_interp;
  dyy := 2.0*didy*dady;                {second derivative in Y direction}
  if (dyy > 2.0) or (dyy < -2.0) then goto flat_interp;
  dxy := didx*dady + didy*dadx;        {crossover second derivative}
  if (dxy > 2.0) or (dxy < -2.0) then goto flat_interp;
  rend_set.iterp_quad^ (               {set linear interpolation coeficients}
    rend_iterp_red_k,                  {ID of interpolant to set to linear}
    rend_geom.p1.coor,                 {XY coordinates of anchor point}
    val,                               {interpolant value at anchor point}
    dx, dy,                            {first derivatives}
    dxx, dyy, dxy);                    {second derivatives}
{
*   Set green to quadratic function after multiply by alpha value.
}
  di2 := v2.grn - v1.grn;              {make interpolant delta from anchor point}
  di3 := v3.grn - v1.grn;
  didx :=                              {derivative in X direction}
    (rend_geom.p2.dy*di3 - rend_geom.p3.dy*di2);
  didy :=                              {derivative in Y direction}
    (rend_geom.p3.dx*di2 - rend_geom.p2.dx*di3);
  val := v1.grn*v1.alpha;              {value at anchor point}
  dx := v1.grn*dadx + v1.alpha*didx;   {X first derivative at anchor point}
  if (dx > 2.0) or (dx < -2.0) then goto flat_interp;
  dy := v1.grn*dady + v1.alpha*didy;   {Y first derivative at anchor point}
  if (dy > 2.0) or (dy < -2.0) then goto flat_interp;
  dxx := 2.0*didx*dadx;                {second derivative in X direction}
  if (dxx > 2.0) or (dxx < -2.0) then goto flat_interp;
  dyy := 2.0*didy*dady;                {second derivative in Y direction}
  if (dyy > 2.0) or (dyy < -2.0) then goto flat_interp;
  dxy := didx*dady + didy*dadx;        {crossover second derivative}
  if (dxy > 2.0) or (dxy < -2.0) then goto flat_interp;
  rend_set.iterp_quad^ (               {set linear interpolation coeficients}
    rend_iterp_grn_k,                  {ID of interpolant to set to linear}
    rend_geom.p1.coor,                 {XY coordinates of anchor point}
    val,                               {interpolant value at anchor point}
    dx, dy,                            {first derivatives}
    dxx, dyy, dxy);                    {second derivatives}
{
*   Set blue to quadratic function after multiply by alpha value.
}
  di2 := v2.blu - v1.blu;              {make interpolant delta from anchor point}
  di3 := v3.blu - v1.blu;
  didx :=                              {derivative in X direction}
    (rend_geom.p2.dy*di3 - rend_geom.p3.dy*di2);
  didy :=                              {derivative in Y direction}
    (rend_geom.p3.dx*di2 - rend_geom.p2.dx*di3);
  val := v1.blu*v1.alpha;              {value at anchor point}
  dx := v1.blu*dadx + v1.alpha*didx;   {X first derivative at anchor point}
  if (dx > 2.0) or (dx < -2.0) then goto flat_interp;
  dy := v1.blu*dady + v1.alpha*didy;   {Y first derivative at anchor point}
  if (dy > 2.0) or (dy < -2.0) then goto flat_interp;
  dxx := 2.0*didx*dadx;                {second derivative in X direction}
  if (dxx > 2.0) or (dxx < -2.0) then goto flat_interp;
  dyy := 2.0*didy*dady;                {second derivative in Y direction}
  if (dyy > 2.0) or (dyy < -2.0) then goto flat_interp;
  dxy := didx*dady + didy*dadx;        {crossover second derivative}
  if (dxy > 2.0) or (dxy < -2.0) then goto flat_interp;
  rend_set.iterp_quad^ (               {set linear interpolation coeficients}
    rend_iterp_blu_k,                  {ID of interpolant to set to linear}
    rend_geom.p1.coor,                 {XY coordinates of anchor point}
    val,                               {interpolant value at anchor point}
    dx, dy,                            {first derivatives}
    dxx, dyy, dxy);                    {second derivatives}
  goto done;                           {done setting all interpolant values}
{
*   Linear coeficients can't be computed.  Revert to flat shading.  Each interpolant
*   will be set to its average value (after alpha multiply for colors).
}
flat_interp:
  rend_set.iterp_flat^ (rend_iterp_alpha_k,
    (v1.alpha + v2.alpha + v3.alpha)*0.333333);
  rend_set.iterp_flat^ (rend_iterp_red_k,
    (v1.red*v1.alpha + v2.red*v2.alpha + v3.red*v3.alpha)*0.333333);
  rend_set.iterp_flat^ (rend_iterp_grn_k,
    (v1.grn*v1.alpha + v2.grn*v2.alpha + v3.grn*v3.alpha)*0.333333);
  rend_set.iterp_flat^ (rend_iterp_blu_k,
    (v1.blu*v1.alpha + v2.blu*v2.alpha + v3.blu*v3.alpha)*0.333333);
{
*   Come thru here after done setting all interpolant coeficients.  Run CHECK_MODES,
*   since this was disabled earlier, and therefore not run by the individual
*   routines that may have altered the modes.
}
done:
  rend_sw_restore_cmode (check_modes); {restore CHECK_MODES and run if needed}
  end;
