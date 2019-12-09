{   Subroutine REND_SW_RVECT_2DIM (DX,DY)
*
*   Draw vector in 2D image coordinate space.  The vector start point is at the
*   current point, and the vector displacement is specified by DX,DY.  The current
*   point is left at the vector end point.
}
module rend_sw_rvect_2dim;
define rend_sw_rvect_2dim;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_rvect_2dim_d.ins.pas';

procedure rend_sw_rvect_2dim (         {relative vector from current point}
  in      dx, dy: real);               {displacement to end point and new curr pnt}
  val_param;

var
  x, y: real;                          {absolute coordinate of vector end point}

begin
  x := rend_2d.curr_x2dim+dx;          {make absolute vector end point}
  y := rend_2d.curr_y2dim+dy;
  rend_prim.vect_2dim^ (x, y);         {draw absolute vector}
  end;
