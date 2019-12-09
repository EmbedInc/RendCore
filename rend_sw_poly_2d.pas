{   Subroutine REND_SW_POLY_2D (N,VERTS)
*
*   Draw one 2D model space polygon.  N is the number of vertices in
*   the polygon.  VERTS is an array containing one XY pair for each
*   vertex.  The vertices must be in counter clockwise order when viewed
*   in the final image, and the polygon must be convex.
}
module rend_sw_poly_2d;
define rend_sw_poly_2d;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_poly_2d_d.ins.pas';

procedure rend_sw_poly_2d (            {convex polygon}
  in      n: sys_int_machine_t;        {number of verticies in VERTS}
  in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
  val_param;

var
  poly: rend_2dverts_t;                {verticies of transformed polygon}
  i: sys_int_machine_t;                {loop counter}
  v: sys_int_machine_t;                {vertex number}
  dv: sys_int_machine_t;               {vertex number incement}

begin
  if n < 3 then return;                {at least 3 verticies needed for a polygon}
  if n > rend_max_verts then begin
    writeln ('Too many verticies in REND_SW_POLY_2D.');
    sys_bomb;
    end;
  if rend_2d.sp.right                  {check for right or left handed transform}
    then begin                         {transform is right handed}
      v := n;                          {fill in POLY starting at last vertex}
      dv := -1;                        {increment towards first vertex}
      end
    else begin                         {transform is left handed}
      v := 1;                          {fill in POLY starting at first vertex}
      dv := 1;                         {increment towards last vertex}
      end
    ;
  for i := 1 to n do begin             {loop thru each 2D space polygon vertex}
    poly[v].x :=                       {transform this vertex into POLY array}
      verts[i].x*rend_2d.sp.xb.x +
      verts[i].y*rend_2d.sp.yb.x +
      rend_2d.sp.ofs.x;
    poly[v].y :=
      verts[i].x*rend_2d.sp.xb.y +
      verts[i].y*rend_2d.sp.yb.y +
      rend_2d.sp.ofs.y;
    v := v+dv;                         {advance to next POLY array vertex number}
    end;
{
*   The polygon has been transformed to 2D image space and is sitting in POLY.
}
  rend_prim.poly_2dimcl^ (n, poly);    {send polygon on down the pipe}
  end;
