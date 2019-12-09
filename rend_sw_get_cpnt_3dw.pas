{   Subroutine REND_SW_GET_CPNT_3DW (X,Y,Z)
*
*   Return the 3D world space current point.
}
module rend_sw_get_cpnt_3dw;
define rend_sw_get_cpnt_3dw;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_cpnt_3dw (       {return 3D world space current point}
  out     x, y, z: real);

begin
  x := rend_view.cpnt.x;
  y := rend_view.cpnt.y;
  z := rend_view.cpnt.z;
  end;
