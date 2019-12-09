{   Subroutine REND_SW_GET_BXFV_3D (IN_V,OUT_V)
*
*   Transform a vector from the 3D world space to the 3D model space.  IN_V is
*   the input vector in 3DW space.  OUT_V is the 3D space result.  IN_V and OUT_V
*   are allowed to resolve to the same storage.
}
module rend_sw_get_bxfv_3d;
define rend_sw_get_bxfv_3d;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_bxfv_3d (        {transform vector from 3DW to 3D space}
  in      in_v: vect_3d_t;             {input vector in 3D world space}
  out     out_v: vect_3d_t);           {result in 3D model space, may be IN_V}
  val_param;

var
  x, y, z: real;                       {scratch values}

begin
  x := in_v.x;                         {make local copy of input vector}
  y := in_v.y;
  z := in_v.z;

  out_v.x :=
    (rend_xf3d.rxb.x * x) + (rend_xf3d.ryb.x * y) + (rend_xf3d.rzb.x * z);
  out_v.y :=
    (rend_xf3d.rxb.y * x) + (rend_xf3d.ryb.y * y) + (rend_xf3d.rzb.y * z);
  out_v.z :=
    (rend_xf3d.rxb.z * x) + (rend_xf3d.ryb.z * y) + (rend_xf3d.rzb.z * z);
  end;
