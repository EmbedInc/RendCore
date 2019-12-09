{   Subroutine REND_SW_RCPNT_2DIM (DX, DY)
*
*   Set new 2D image coordinate space current point by specifying displacement from
*   existing current point.
}
module rend_sw_rcpnt_2dim;
define rend_sw_rcpnt_2dim;
%include 'rend_sw2.ins.pas';

procedure rend_sw_rcpnt_2dim (         {set current point with relative coordinates}
  in      dx, dy: real);               {displacement from old current point}
  val_param;

var
  x, y: real;                          {absolute coordinate of new curr point}

begin
  x := rend_2d.curr_x2dim+dx;          {make new current point}
  y := rend_2d.curr_y2dim+dy;
  rend_set.cpnt_2dim^ (x, y);          {set new absolute current point}
  end;
