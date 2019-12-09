{   Subroutine REND_SW_GET_XFVECT_TEXT (IN_V,OUT_V)
*
*   Transform a vector from the TEXT space to the TXDRAW space.  IN_V and OUT_V
*   may the same variable.
}
{
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*   ::        CONFIDENTIAL AND PROPRIETARY INFORMATION OF        ::
*   ::                    COGNIVISION, INC.                      ::
*   ::           PROTECTED BY THE COPYRIGHT LAW AS AN            ::
*   ::                    UNPUBLISHED WORK                       ::
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}
module rend_sw_get_xfvect_text;
define rend_sw_get_xfvect_text;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_xfvect_text (    {transform vector from TEXT to TXDRAW space}
  in      in_v: vect_2d_t;             {input vector in TEXT space}
  out     out_v: vect_2d_t);           {output vector in TXDRAW space}

var
  out_x: real;                         {local copy of output X value}

begin
  out_x :=
    in_v.x*rend_text_state.sp.xb.x +
    in_v.y*rend_text_state.sp.yb.x;
  out_v.y :=
    in_v.x*rend_text_state.sp.xb.y +
    in_v.y*rend_text_state.sp.yb.y;
  out_v.x := out_x;
  end;
