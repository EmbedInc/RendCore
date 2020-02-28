{   Subroutine REND_SW_GET_CPNT_2D (X,Y)
*
*   Read back 2D model space current point.
}
module rend_sw_get_cpnt_2d;
define rend_sw_get_cpnt_2d;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_cpnt_2d (        {get 2D model space current point}
  out     x, y: real);                 {current point coordinates}

begin
  x := rend_2d.sp.cpnt.x;
  y := rend_2d.sp.cpnt.y;
  end;
