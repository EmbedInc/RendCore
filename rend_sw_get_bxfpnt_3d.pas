{   Subroutine REND_SW_GET_BXFPNT_3D (IN_XYZ,OUT_XYZ)
*
*   Transform the 3D world space point IN_XYZ to its corresponding 3D model space
*   coordinate OUT_XYZ.  It is permissible to pass the same variable for both
*   call arguments.  In this case the value will be transformed in place.
}
module rend_sw_get_bxfpnt_3d;
define rend_sw_get_bxfpnt_3d;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_bxfpnt_3d (      {transform point from 3DW to 3D space}
  in      in_xyz: vect_3d_t;           {3DW space input coordinate}
  out     out_xyz: vect_3d_t);         {3D space output coordinate, may be IN_XYZ}
  val_param;

var
  x, y, z: real;                       {scratch values}

begin
  x := in_xyz.x - rend_xf3d.ofs.x;     {remove 3DW space offset vector}
  y := in_xyz.y - rend_xf3d.ofs.y;
  z := in_xyz.z - rend_xf3d.ofs.z;

  out_xyz.x :=
    (rend_xf3d.rxb.x * x) + (rend_xf3d.ryb.x * y) + (rend_xf3d.rzb.x * z);
  out_xyz.y :=
    (rend_xf3d.rxb.y * x) + (rend_xf3d.ryb.y * y) + (rend_xf3d.rzb.y * z);
  out_xyz.z :=
    (rend_xf3d.rxb.z * x) + (rend_xf3d.ryb.z * y) + (rend_xf3d.rzb.z * z);
  end;
