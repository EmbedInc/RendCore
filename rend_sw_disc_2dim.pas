{   Subroutine REND_SW_DISC_2DIM (RADIUS)
*
*   Draw a circular disc centered at the current point.
*
*   PRIM_DATA sw_read no
*   PRIM_DATA sw_write no
}
module rend_sw_disc_2dim;
define rend_sw_disc_2dim;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_disc_2dim_d.ins.pas';

procedure rend_sw_disc_2dim (          {filled circle}
  in      radius: real);
  val_param;

begin
  end;                                 {not implemented yet}
