{   Subroutine REND_SW_CIRCLE_2DIM (RADIUS)
*
*   Draw circle about the current point.
*
*   PRIM_DATA sw_read no
*   PRIM_DATA sw_write no
}
module rend_sw_circle_2dim;
define rend_sw_circle_2dim;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_circle_2dim_d.ins.pas';

procedure rend_sw_circle_2dim (        {unfilled circle}
  in      radius: real);
  val_param;

begin
  end;                                 {not implemented yet}
