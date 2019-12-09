{   Subroutine REND_SW_GET_CPNT_3D (X,Y,Z)
*
*   Return the 3D world space current point.
}
module rend_sw_get_cpnt_3d;
define rend_sw_get_cpnt_3d;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_cpnt_3d (        {return 3D model space current point}
  out     x, y, z: real);

begin
  x := rend_xf3d.cpnt.x;
  y := rend_xf3d.cpnt.y;
  z := rend_xf3d.cpnt.z;
  end;
