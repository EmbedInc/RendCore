{   Subroutine REND_SW_CPNT_2DIM (X,Y)
*
*   Set 2D image coordinate space current point using floating point numbers.
}
module rend_sw_cpnt_2dim;
define rend_sw_cpnt_2dim;
%include 'rend_sw2.ins.pas';

procedure rend_sw_cpnt_2dim (          {set current point with absolute coordinates}
  in      x, y: real);                 {new coordinates of curr pnt in this space}
  val_param;

begin
  rend_2d.curr_x2dim := x;             {save 2DIM floating point current point}
  rend_2d.curr_y2dim := y;
  rend_set.cpnt_2dimi^ (trunc(x), trunc(y)); {set integer current point}
  end;
