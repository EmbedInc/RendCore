{   Subroutine REND_SW_GET_XFPNT_2D (IN_XY,OUT_XY)
*
*   Transform a point from the 2D model space to the 2D image coordinate space.
*   Both the input and output arguments are allowed to be the same (a point may be
*   transformed in place.
}
module rend_sw_get_xfpnt_2d;
define rend_sw_get_xfpnt_2d;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_xfpnt_2d (       {transform point from 2D to 2DIM space}
  in      in_xy: vect_2d_t;            {input point in 2D space}
  out     out_xy: vect_2d_t);          {output point in 2DIM space}

var
  out_x: real;                         {temp save so args can be the same}

begin
  out_x :=                             {make local copy of output X value}
    in_xy.x*rend_2d.sp.xb.x +
    in_xy.y*rend_2d.sp.yb.x +
    rend_2d.sp.ofs.x;
  out_xy.y :=                          {make output Y and possibly corrupt input Y}
    in_xy.x*rend_2d.sp.xb.y +
    in_xy.y*rend_2d.sp.yb.y +
    rend_2d.sp.ofs.y;
  out_xy.x := out_x;                   {pass back output X and possibly corrupt in X}
  end;
