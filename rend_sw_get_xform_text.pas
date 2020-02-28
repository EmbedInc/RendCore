{   Subroutine REND_SW_GET_XFORM_TEXT (XB,YB,OFS)
*
*   Read back the current TEXT --> TXDRAW transform.
}
module rend_sw_get_xform_text;
define rend_sw_get_xform_text;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_xform_text (     {get TEXT --> TXDRAW current transform}
  out     xb: vect_2d_t;               {X basis vector}
  out     yb: vect_2d_t;               {Y basis vector}
  out     ofs: vect_2d_t);             {offset vector}

begin
  xb.x := rend_text_state.sp.xb.x;
  xb.y := rend_text_state.sp.xb.y;
  yb.x := rend_text_state.sp.yb.x;
  yb.y := rend_text_state.sp.yb.y;
  ofs.x := rend_text_state.sp.ofs.x;
  ofs.y := rend_text_state.sp.ofs.y;
  end;
