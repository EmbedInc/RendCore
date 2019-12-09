{   Subroutine REND_SW_RECT_2D (DX,DY)
*
*   Draw axis aligned rectangle.  The current point is at one corner, and DX,DY is
*   the displacement to the other corner.  Only those pixel centers that are in the
*   rectangle will be drawn.
}
module rend_sw_rect_2d;
define rend_sw_rect_2d;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_rect_2d_d.ins.pas';

procedure rend_sw_rect_2d (            {axis aligned rectangle at current point}
  in      dx, dy: real);               {displacement from curr pnt to opposite corner}
  val_param;

var
  verts:                               {verticies of the polygon}
    array[1..4] of vect_2d_t;

label
  stays_rect;

begin
  if (rend_2d.sp.xb.y = 0.0) and (rend_2d.sp.yb.x = 0.0)
    then goto stays_rect;              {still screen aligned rectangle after xform ?}
{
*   The rectangle does not stay an axis aligned rectangle after the 2D transform.
*   Handle it as an arbitrary polygon.
}
  if dx >= 0.0                         {check horizontal rectangle direction}
    then begin                         {rectangle extends to the right}
      verts[2].x := rend_2d.sp.cpnt.x;
      verts[3].x := rend_2d.sp.cpnt.x;
      verts[1].x := rend_2d.sp.cpnt.x + dx;
      verts[4].x := verts[1].x;
      end
    else begin                         {rectangle extends to the left}
      verts[1].x := rend_2d.sp.cpnt.x;
      verts[4].x := rend_2d.sp.cpnt.x;
      verts[2].x := rend_2d.sp.cpnt.x + dx;
      verts[3].x := verts[2].x;
      end
    ;
  if dy >= 0.0                         {check vertical rectangle direction}
    then begin                         {rectangle extends upwards}
      verts[3].y := rend_2d.sp.cpnt.y;
      verts[4].y := rend_2d.sp.cpnt.y;
      verts[1].y := rend_2d.sp.cpnt.y+dy;
      verts[2].y := verts[1].y;
      end
    else begin                         {rectangle extends downwards}
      verts[1].y := rend_2d.sp.cpnt.y;
      verts[2].y := rend_2d.sp.cpnt.y;
      verts[3].y := rend_2d.sp.cpnt.y+dy;
      verts[4].y := verts[3].y;
      end
    ;
  rend_prim.poly_2d^ (4, verts);       {pass rectangle on as polygon}
  return;
{
*   The rectangle remains an axis aligned rectangle after the 2D transform.  Pass
*   it on as a rectangle.
}
stays_rect:
  rend_prim.rect_2dimcl^ (             {rectangle immediatly after 2D transform}
    dx*rend_2d.sp.xb.x,                {X length in 2DIM space}
    dy*rend_2d.sp.yb.y);               {Y length in 2DIM space}
  end;
