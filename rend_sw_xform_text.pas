{   Subroutine REND_SW_XFORM_TEXT (XB,YB,OFS)
*
*   Set the TEXT --> TXDRAW transform to new values.
}
{
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*   ::        CONFIDENTIAL AND PROPRIETARY INFORMATION OF        ::
*   ::                    COGNIVISION, INC.                      ::
*   ::           PROTECTED BY THE COPYRIGHT LAW AS AN            ::
*   ::                    UNPUBLISHED WORK                       ::
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}
module rend_sw_xform_text;
define rend_sw_xform_text;
%include 'rend_sw2.ins.pas';

procedure rend_sw_xform_text (         {set new TEXT --> TXDRAW transform}
  in      xb: vect_2d_t;               {X basis vector}
  in      yb: vect_2d_t;               {Y basis vector}
  in      ofs: vect_2d_t);             {offset vector}

begin
  rend_text_state.sp.xb.x := xb.x;     {stuff new transform}
  rend_text_state.sp.xb.y := xb.y;
  rend_text_state.sp.yb.x := yb.x;
  rend_text_state.sp.yb.y := yb.y;
  rend_text_state.sp.ofs.x := ofs.x;
  rend_text_state.sp.ofs.y := ofs.y;
  rend_text_state.sp.right :=          {set right/left handedness flag}
    (xb.x*yb.y - xb.y*yb.x) >= 0.0;
  end;
