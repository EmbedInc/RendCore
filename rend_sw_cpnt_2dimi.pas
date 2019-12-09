{   Subroutine REND_SW_CPNT_2DIMI (X, Y)
*
*   Set the 2D pixel coordinate integer current point.
}
module rend_sw_cpnt_2dimi;
define rend_sw_cpnt_2dimi;
%include 'rend_sw2.ins.pas';

procedure rend_sw_cpnt_2dimi (         {set current point with absolute coordinates}
  in      x, y: sys_int_machine_t);    {new integer pixel coor of current point}
  val_param;

var
  iterp_n: sys_int_machine_t;          {current interpolant number}
  dx, dy: real;                        {displacement from iterp anchor point}
  r: double;                           {scratch used just before integer conversion}
  x_arg, y_arg: sys_int_machine_t;     {call args to get around compiler bug}
{
**********************************************************
*
*   Local subroutine TMAP_DERIVATIVES (I, E)
*
*   Update the extra derivates needed for an interpolant that is being used as
*   a texture map index.  I is the interpolant normal state block.  E is the extra
*   derivatives state block for that interpolant.
}
procedure tmap_derivatives (
  in out  i: rend_iterp_pix_t;         {normal interpolant state block}
  in out  e: rend_uvwder_t);           {supplemental derivatives state block}

var
  dx, dy: real;                        {displacements from iterp anchor point}
  r: real;                             {scratch used just before integer conversion}

label
  force_flat;

begin
  case i.mode of                       {what is interpolation mode ?}
{
*   Interpolation mode is linear.
}
rend_iterp_mode_linear_k: begin
      r := 65536.0 * i.adx * i.val_scale; {make raw scaled derivative}
      if (r > 2147480000.0) or (r < -2147480000.0) {out of range for integer ?}
        then goto force_flat;          {punt back to flat interpolation}
      e.dx.all := round(r);            {set final integer derivative}

      r := 65536.0 * i.ady * i.val_scale; {make raw scaled derivative}
      if (r > 2147480000.0) or (r < -2147480000.0) {out of range for integer ?}
        then goto force_flat;          {punt back to flat interpolation}
      e.dy.all := round(r);            {set final integer derivative}
      end;
{
*   Interpolation mode is quadratic.
}
rend_iterp_mode_quad_k: begin
      dx := x_arg + 0.5 - i.x;         {make displacements from anchor point}
      dy := y_arg + 0.5 - i.y;

      r := 65536.0 * i.val_scale *     {make raw scaled derivative}
        (i.adx + (i.adxx * dx) + (i.adxy * dy));
      if (r > 2147480000.0) or (r < -2147480000.0) {out of range for integer ?}
        then goto force_flat;          {punt back to flat interpolation}
      e.dx.all := round(r);            {set final integer derivative}

      r := 65536.0 * i.val_scale *     {make raw scaled derivative}
        (i.ady + (i.adyy * dy) + (i.adxy * dx));
      if (r > 2147480000.0) or (r < -2147480000.0) {out of range for integer ?}
        then goto force_flat;          {punt back to flat interpolation}
      e.dy.all := round(r);            {set final integer derivative}
      end;
{
*   Interpolation mode is other than linear or quadratic.  In this
*   case, just set the derivatives to zero.
}
otherwise
    e.dx.all := 0;                     {indicate derivatives won't change}
    e.dy.all := 0;
    end;                               {end of interpolation mode cases}
  return;
{
*   Jump here to forcebly switch to flat interpolation.  This is done if
*   an overflow is detected.
}
force_flat:
  e.dx.all := 0;                       {incicate derivatives won't change}
  e.dy.all := 0;
  i.mode := rend_iterp_mode_flat_k;    {force interpolation mode to flat}
  end;
{
**********************************************************
*
*   Start of main routine.
}
begin
  rend_lead_edge.x := x;               {set current point coordinates}
  rend_curr_x := x;                    {current X when not at leading edge}
  rend_lead_edge.y := y;
  if (x < -1) or (y < 0)               {new point outside image bounds ?}
      or (x > rend_image.x_size)
      or (y >= rend_image.y_size)
    then return;                       {only recompute colors/adr if inside image}

  for iterp_n := 1 to rend_iterps.n_on do begin {once for each enabled interpolant}
    with rend_iterps.list_on[iterp_n]^:iterp do begin {set up ITERP abbreviation}
{
*   Process this interpolant.  The abbreviation ITERP stands for this interpolant
*   state block.  We must find the byte address of this interpolant at the current
*   pixel.  We must also set the current color at this pixel.
}
  if iterp.bitmap_p <> nil then begin  {there is a bitmap attatched ?}
    iterp.curr_adr.i :=                {find address of interpolant in this pixel}
      sys_int_adr_t(iterp.bitmap_p^.line_p[y]) {start adr of scan line}
      + x*iterp.bitmap_p^.x_offset     {pixel offset into scan line}
      + iterp.iterp_offset;            {byte offset into pixel}
    end;
  case iterp.mode of                   {different code for each interpolation mode}

rend_iterp_mode_flat_k: begin          {flat interpolation}
  if not iterp.int then begin          {not in raw integer mode ?}
    iterp.val.all := round(65536.0*(iterp.val_offset + iterp.val_scale*
      iterp.aval                       {floating point value here}
      ));
    end;
  end;

rend_iterp_mode_linear_k: begin        {linear interpolation}
  dx := x+0.5 - iterp.x;               {make displacement from anchor to curr pnt}
  dy := y+0.5 - iterp.y;
  r := 65536.0*(iterp.val_offset + iterp.val_scale*
    (iterp.aval + dx*iterp.adx + dy*iterp.ady)); {floating point value here}
  r := min(2147480000.0, max(-2147480000.0, r));
  iterp.val.all := round(r);
  end;

rend_iterp_mode_quad_k: begin          {quadratic interpolation}
  dx := x+0.5 - iterp.x;               {make displacement from anchor to curr pnt}
  dy := y+0.5 - iterp.y;
  r := 65536.0*(iterp.val_offset + iterp.val_scale*
    (iterp.aval + dx*(iterp.adx + 0.5*dx*iterp.adxx)
     + dy*(iterp.ady + 0.5*dy*iterp.adyy + dx*iterp.adxy) ));
  r := min(2147480000.0, max(-2147480000.0, r));
  iterp.val.all := round(r);
  end;
  end;                                 {end of interpolation mode cases}

  iterp.eval := iterp.val;             {copy current value into leading edge value}
  iterp.value := iterp.val;            {init final interpolator result value}
  if iterp.iclamp then begin           {clamp result in VALUE ?}
    if iterp.value.all > iterp.iclamp_max.all {over range ?}
      then iterp.value.all := iterp.iclamp_max.all;
    if iterp.value.all < iterp.iclamp_min.all {under range ?}
      then iterp.value.all := iterp.iclamp_min.all;
    end;                               {done handling clamping}
{
*   Done processing this interpolant.  Go back and process the next interpolant that
*   is enabled.
}
      end;                             {done with ITERP abbreviation}
    end;                               {back and do next interpolant}
{
*   All the normal interpolants have been done.  Now update the extra derivatives
*   of U, V, and W if the appropriate texture mapping modes are enabled.
}
  if rend_tmap.on then begin           {texture mapping turned on ?}
    x_arg := x;                        {make call args local copy for compiler bug}
    y_arg := y;
    case rend_tmap.dim of              {which interpolants are tmap indicies ?}
rend_tmapd_u_k: begin
        tmap_derivatives (rend_iterps.u, rend_u);
        end;
rend_tmapd_uv_k: begin
        tmap_derivatives (rend_iterps.u, rend_u);
        tmap_derivatives (rend_iterps.v, rend_v);
        end;
otherwise
      rend_message_bomb ('rend', 'rend_tmap_dim_bad', nil, 0);
      end;                             {done with texture map dimension ID cases}
    end;                               {done handling texture mapping turned on}
  end;
