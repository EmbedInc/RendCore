{   Subroutine REND_SW_VECT_INT_2DIM (X,Y)
*
*   Draw a vector in the 2D image coordinate space using integer pixel addressing.
}
module rend_sw_vect_int_2dim;
define rend_sw_vect_int_2dim;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_vect_int_2dim_d.ins.pas';

procedure rend_sw_vect_int_2dim (      {2D image space vector using integer adr}
  in      x, y: real);                 {coor of end point and new current point}
  val_param;

begin
  rend_2d.curr_x2dim := x;             {update new 2DI current point}
  rend_2d.curr_y2dim := y;
  rend_prim.vect_2dimi^ (trunc(x), trunc(y));
  end;
