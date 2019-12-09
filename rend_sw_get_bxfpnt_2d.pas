{   Subroutine REND_SW_GET_BXFPNT_2D (IN_XY,OUT_XY)
*
*   Transform a point backwards thru the 2D model space transform.  This means
*   converting it from the 2D image (2DIM) space to the 2D model (2D) space.
}
module rend_sw_get_bxfpnt_2d;
define rend_sw_get_bxfpnt_2d;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_bxfpnt_2d (      {transform point backwards thru 2D xform}
  in      in_xy: vect_2d_t;            {input 2DIM space point}
  out     out_xy: vect_2d_t);          {output 2D space point}

var
  x, y: real;                          {temp scratch coordinate}

begin
  if not rend_2d.sp.inv_ok then begin  {can't do inverse transform with this matrix ?}
    writeln ('Inverse transform not possible in routine REND_SW_GET_BXFPNT_2D.');
    sys_bomb;                          {save traceback and bomb out}
    end;

  x := in_xy.x - rend_2d.sp.ofs.x;     {remove offset vector}
  y := in_xy.y - rend_2d.sp.ofs.y;
  out_xy.x := rend_2d.sp.invm * (      {do inverse transform}
     x * rend_2d.sp.yb.y - y * rend_2d.sp.yb.x);
  out_xy.y := rend_2d.sp.invm * (
    -x * rend_2d.sp.xb.y + y * rend_2d.sp.xb.x);
  end;
