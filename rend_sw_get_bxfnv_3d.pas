{   Subroutine REND_SW_GET_BXFNV_3D (IN_V,OUT_V)
*
*   Transform a normal vector from the 3D world space to the 3D model space.
*   IN_V is the input vector in 3DW space.  OUT_V is the 3D space result.
*   IN_V and OUT_V are allowed to resolve to the same storage.
*
*   NOTE:  Only the direction of OUT_V is valid.  The length is arbitrary.
}
module rend_sw_get_bxfnv_3d;
define rend_sw_get_bxfnv_3d;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_bxfnv_3d (       {transform normal vector from 3DW to 3D space}
  in      in_v: vect_3d_t;             {input normal vector in 3D world space}
  out     out_v: vect_3d_t);           {result in 3D model space, may be IN_V}
  val_param;

var
  x, y, z: real;                       {scratch values}

begin
{
*   The input vector will be transformed by the transpose of the regular forward
*   3D --> 3DW space transformation matrix.
}
  x := in_v.x;                         {make local copy of input vector}
  y := in_v.y;
  z := in_v.z;

  out_v.x :=
    (rend_xf3d.xb.x * x) + (rend_xf3d.xb.y * y) + (rend_xf3d.xb.z * z);
  out_v.y :=
    (rend_xf3d.yb.x * x) + (rend_xf3d.yb.y * y) + (rend_xf3d.yb.z * z);
  out_v.z :=
    (rend_xf3d.zb.x * x) + (rend_xf3d.zb.y * y) + (rend_xf3d.zb.z * z);
  end;
