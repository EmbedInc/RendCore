{   Subroutine REND_SW_RVECT_2D (DX,DY)
*
*   Draw vector in 2D image coordinate space.  The vector start point is at the
*   current point, and the vector displacement is specified by DX,DY.  The current
*   point is left at the vector end point.
}
module rend_sw_rvect_2d;
define rend_sw_rvect_2d;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_rvect_2d_d.ins.pas';

procedure rend_sw_rvect_2d (           {relative vector from current point}
  in      dx, dy: real);               {displacement to end point and new curr pnt}
  val_param;

var
  x, y: real;                          {absolute coordinate of vector end point}

begin
  x := rend_2d.sp.cpnt.x+dx;           {make absolute vector end point}
  y := rend_2d.sp.cpnt.y+dy;
  rend_prim.vect_2d^ (x, y);           {draw absolute vector}
  end;
