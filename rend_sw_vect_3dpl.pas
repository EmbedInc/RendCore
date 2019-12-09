{   Subroutine REND_SW_VECT_3DPL (X,Y)
*
*   Draw a vector from the current point to a new absolute point.  The current
*   point will be updated to the end of the vector.  Coordinates are in the
*   3DPL space, which is defined by a current plane in the 3D model coordinate
*   space.
}
module rend_sw_vect_3dpl;
define rend_sw_vect_3dpl;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_vect_3dpl_d.ins.pas';

procedure rend_sw_vect_3dpl (          {vector from curr pnt to new absolute point}
  in      x, y: real);                 {coor of end point and new current point}
  val_param;

var
  x3d, y3d, z3d: real;                 {vector end point in 3D space}

begin
  rend_3dpl.sp.cpnt.x := x;            {new 3DPL current point is vector end}
  rend_3dpl.sp.cpnt.y := y;

  x3d :=                               {do current plane transform}
    (x * rend_3dpl.xb.x) + (y * rend_3dpl.yb.x) + rend_3dpl.org.x;
  y3d :=
    (x * rend_3dpl.xb.y) + (y * rend_3dpl.yb.y) + rend_3dpl.org.y;
  z3d :=
    (x * rend_3dpl.xb.z) + (y * rend_3dpl.yb.z) + rend_3dpl.org.z;
  rend_prim.vect_3d^ (x3d, y3d, z3d);  {draw vector in 3D space}
  end;
