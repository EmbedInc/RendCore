{   Subroutine REND_SW_RVECT_3DPL (DX,DY)
*
*   Draw a vector from the current point.  The vector length is given by DX,DY.
*   Coordinates are in the 3DPL space, which is defined by a current plane in the
*   3D model space.
}
module rend_sw_rvect_3dpl;
define rend_sw_rvect_3dpl;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_rvect_3dpl_d.ins.pas';

procedure rend_sw_rvect_3dpl (         {relative vector from current point}
  in      dx, dy: real);               {displacement to end point and new curr pnt}
  val_param;

var
  x, y: real;                          {absolute 3DPL vector end coordinates}

begin
  x := rend_3dpl.sp.cpnt.x + dx;       {make absolute current point}
  y := rend_3dpl.sp.cpnt.y + dy;
  rend_prim.vect_3dpl^ (x, y);         {draw as absolute vector}
  end;
