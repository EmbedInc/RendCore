{   Subroutine REND_SW_GET_CPNT_TEXT (X,Y)
*
*   Return the TEXT coordinate space current point.
}
{
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*   ::        CONFIDENTIAL AND PROPRIETARY INFORMATION OF        ::
*   ::                    COGNIVISION, INC.                      ::
*   ::           PROTECTED BY THE COPYRIGHT LAW AS AN            ::
*   ::                    UNPUBLISHED WORK                       ::
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}
module rend_sw_get_cpnt_text;
define rend_sw_get_cpnt_text;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_cpnt_text (      {return the current point}
  out     x, y: real);                 {current point in this space}

begin
  x := rend_text_state.sp.cpnt.x;
  y := rend_text_state.sp.cpnt.y;
  end;
