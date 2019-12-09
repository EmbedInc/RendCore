{   Subroutine REND_SW_CPNT_3D (X,Y,Z)
*
*   Set the current point from the 3D model coordinate space.
}
module rend_sw_cpnt_3d;
define rend_sw_cpnt_3d;
%include 'rend_sw2.ins.pas';

procedure rend_sw_cpnt_3d (            {set new current point from 3D model space}
  in      x, y, z: real);              {coordinates of new current point}
  val_param;

begin
  rend_xf3d.cpnt.x := x;               {save 3D model space current point}
  rend_xf3d.cpnt.y := y;
  rend_xf3d.cpnt.z := z;
  rend_set.cpnt_3dw^ (                 {set current point in 3D world space}
    x*rend_xf3d.xb.x + y*rend_xf3d.yb.x + z*rend_xf3d.zb.x + rend_xf3d.ofs.x,
    x*rend_xf3d.xb.y + y*rend_xf3d.yb.y + z*rend_xf3d.zb.y + rend_xf3d.ofs.y,
    x*rend_xf3d.xb.z + y*rend_xf3d.yb.z + z*rend_xf3d.zb.z + rend_xf3d.ofs.z);
  end;
