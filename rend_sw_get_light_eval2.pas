{   Subroutine REND_SW_GET_LIGHT_EVAL2 (VERT, CA, NORM, SP)
*
*   Optimized version to implement REND_GET.LIGHT_EVAL public entry point.
*   This version may only be installed when all of the following conditions
*   are met:
*
*   1)  The front surface property is ON.  SP will therefore never be OFF.
*
*   2)  The diffuse surface property is ON in all enabled suprops blocks.
*
*   3)  All other surface properties are OFF in all enabled suprop blocks.
*
*   4)  Alpha buffering is OFF.
*
*   5)  Vertex descriptor diffuse override colors are disabled.
}
module rend_sw_get_light_eval2;
define rend_sw_get_light_eval2;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_light_eval2 (    {get point color by doing lighting evaluation}
  in      vert: univ rend_vert3d_t;    {vertex descriptor to find colors at}
  in out  ca: rend_vcache_t;           {cache data for this vertex}
  in      norm: vect_3d_t;             {unit normal vector at point}
  in      sp: rend_suprop_t);          {visual surface properties descriptor block}

var
  m: real;                             {mult factor for unitizing vectors}
  s: real;                             {light scale factor}
  lvx, lvy, lvz: real;                 {unit vector to light source}
  diff_red, diff_grn, diff_blu: real;  {diffuse surface color}
  l_p: rend_light_p_t;                 {pointer to current light source}

label
  next_light;

begin
  ca.color.red := 0.0;                 {init color accumulators}
  ca.color.grn := 0.0;
  ca.color.blu := 0.0;

  diff_red := sp.diff.red;             {fetch object diffuse color}
  diff_grn := sp.diff.grn;
  diff_blu := sp.diff.blu;

  l_p := rend_lights.on_p;             {init pointer to first light source}
  while l_p <> nil do begin            {keep looping until end of ON lights list}
    with l_p^: l do begin              {L is abbreviation for this light source}
      case l.ltype of                  {different code for each type of light source}

rend_ltype_amb_k: begin                {ambient light source}
  ca.color.red := ca.color.red + (diff_red * l.amb_red);
  ca.color.grn := ca.color.grn + (diff_grn * l.amb_grn);
  ca.color.blu := ca.color.blu + (diff_blu * l.amb_blu);
  end;

rend_ltype_dir_k: begin                {directional light source}
  m :=                                 {COS of angle between surf normal and light}
    (l.dir.x * norm.x) + (l.dir.y * norm.y) + (l.dir.z * norm.z);
  if m <= 0.0 then goto next_light;    {light source behind, go on to next one}
  ca.color.red := ca.color.red + (diff_red * l.dir_red * m);
  ca.color.grn := ca.color.grn + (diff_grn * l.dir_grn * m);
  ca.color.blu := ca.color.blu + (diff_blu * l.dir_blu * m);
  end;

rend_ltype_pnt_k: begin                {point light source with no falloff}
  lvx := l.pnt.x - ca.x3dw;            {make vector to light source}
  lvy := l.pnt.y - ca.y3dw;
  lvz := l.pnt.z - ca.z3dw;
  m := sqr(lvx) + sqr(lvy) + sqr(lvz); {square of distance to light source}
  if m < 1.0E-20 then goto next_light; {too close, pretend it's on other side}
  m := 1.0 / sqrt(m);                  {mult factor to unitize light vector}
  lvx := lvx * m;                      {make unit vector to light source}
  lvy := lvy * m;
  lvz := lvz * m;
  m :=                                 {COS of angle between surf normal and light}
    (lvx * norm.x) + (lvy * norm.y) + (lvz * norm.z);
  if m <= 0.0 then goto next_light;    {light source behind, go on to next one}
  ca.color.red := ca.color.red + (diff_red * l.pnt_red * m);
  ca.color.grn := ca.color.grn + (diff_grn * l.pnt_grn * m);
  ca.color.blu := ca.color.blu + (diff_blu * l.pnt_blu * m);
  end;

rend_ltype_pr2_k: begin                {point light with 1/R**2 falloff}
  lvx := l.pr2_coor.x - ca.x3dw;       {make vector to light source}
  lvy := l.pr2_coor.y - ca.y3dw;
  lvz := l.pr2_coor.z - ca.z3dw;
  m := sqr(lvx) + sqr(lvy) + sqr(lvz); {square of distance to light source}
  if m < 1.0E-20 then goto next_light; {too close, pretend it's on other side}
  m := 1.0 / m;                        {1/R**2 to light source}
  s := l.pr2_r2 * m;                   {brightness adjust factor due to distance}
  if s < 0.002 then goto next_light;   {too dim, don't bother ?}
  m := s * sqrt(m);                    {factor for scaling light vector}
  lvx := lvx * m;                      {make scaled vector to light source}
  lvy := lvy * m;
  lvz := lvz * m;
  m :=                                 {COS of angle between surf normal and light}
    (lvx * norm.x) + (lvy * norm.y) + (lvz * norm.z);
  if m <= 0.0 then goto next_light;    {light source behind, go on to next one}
  ca.color.red := ca.color.red + (diff_red * l.pr2_red * m);
  ca.color.grn := ca.color.grn + (diff_grn * l.pr2_grn * m);
  ca.color.blu := ca.color.blu + (diff_blu * l.pr2_blu * m);
  end;

        end;                           {done with all the lightsource type cases}
      end;                             {done with the L abbreviation}

next_light:                            {jump here to go on to next light source}
    l_p := l_p^.next_on_p;             {advance to next light source}
    end;                               {back and do this new light source}

  ca.shnorm.x := norm.x;               {save the shading normal in vertex cache}
  ca.shnorm.y := norm.y;
  ca.shnorm.z := norm.z;
  end;
