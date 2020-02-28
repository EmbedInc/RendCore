{   Subroutine REND_SW_GET_XFPNT_TEXT (IN_XY,OUT_XY)
*
*   Transform a point from the TEXT coordinate space to the TXDRAW coordinate space.
}
module rend_sw_get_xfpnt_text;
define rend_sw_get_xfpnt_text;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_xfpnt_text (     {transform point from TEXT to TXDRAW space}
  in      in_xy: vect_2d_t;            {input point in TEXT space}
  out     out_xy: vect_2d_t);          {output point in TXDRAW space}

var
  out_x: real;                         {local copy of output X value}

begin
  out_x :=
    in_xy.x*rend_text_state.sp.xb.x +
    in_xy.y*rend_text_state.sp.yb.x +
    rend_text_state.sp.ofs.x;
  out_xy.y :=
    in_xy.x*rend_text_state.sp.xb.y +
    in_xy.y*rend_text_state.sp.yb.y +
    rend_text_state.sp.ofs.y;
  out_xy.x := out_x;
  end;
