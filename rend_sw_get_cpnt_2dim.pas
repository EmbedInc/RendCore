{   Subroutine REND_SW_GET_CPNT_2DIM (X,Y)
*
*   Read back 2D floating point image space current point.
}
{
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*   ::        CONFIDENTIAL AND PROPRIETARY INFORMATION OF        ::
*   ::                    COGNIVISION, INC.                      ::
*   ::           PROTECTED BY THE COPYRIGHT LAW AS AN            ::
*   ::                    UNPUBLISHED WORK                       ::
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}
module rend_sw_get_cpnt_2dim;
define rend_sw_get_cpnt_2dim;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_cpnt_2dim (      {get 2D float point image space current point}
  out     x, y: real);                 {current point coordinates}

begin
  x := rend_2d.curr_x2dim;
  y := rend_2d.curr_y2dim;
  end;
