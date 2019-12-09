{   Subroutine REND_SW_CLEAR
*
*   Write a full screen rectangle with the current interpolant settings.
}
{
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*   ::        CONFIDENTIAL AND PROPRIETARY INFORMATION OF        ::
*   ::                    COGNIVISION, INC.                      ::
*   ::           PROTECTED BY THE COPYRIGHT LAW AS AN            ::
*   ::                    UNPUBLISHED WORK                       ::
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}
module rend_sw_clear;
define rend_sw_clear;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_clear_d.ins.pas';

procedure rend_sw_clear;

begin
  rend_set.cpnt_2dimi^ (0, 0);         {set current point to top left of image}
  rend_prim.rect_2dimi^ (              {draw full screen rectangle}
    rend_image.x_size,                 {indicate full image width}
    rend_image.y_size);                {indicate full image height}
  end;
