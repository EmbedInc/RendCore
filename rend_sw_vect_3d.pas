{   Subroutine REND_SW_VECT_3D (X,Y,Z)
*
*   Draw vector in 3D model space from the current point to the given coordinates.
*   The given coordinates will become the new current point.
}
module rend_sw_vect_3d;
define rend_sw_vect_3d;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_vect_3d_d.ins.pas';

procedure rend_sw_vect_3d (            {vector to new current point in 3D space}
  in      x, y, z: real);              {vector end point and new current point}
  val_param;

begin
  rend_xf3d.cpnt.x := x;               {save 3D model space current point}
  rend_xf3d.cpnt.y := y;
  rend_xf3d.cpnt.z := z;
  rend_prim.vect_3dw^ (                {draw vector in 3D world coordinate space}
    x*rend_xf3d.xb.x + y*rend_xf3d.yb.x + z*rend_xf3d.zb.x + rend_xf3d.ofs.x,
    x*rend_xf3d.xb.y + y*rend_xf3d.yb.y + z*rend_xf3d.zb.y + rend_xf3d.ofs.y,
    x*rend_xf3d.xb.z + y*rend_xf3d.yb.z + z*rend_xf3d.zb.z + rend_xf3d.ofs.z);
  end;
