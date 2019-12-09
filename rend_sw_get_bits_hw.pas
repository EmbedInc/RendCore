{   Subroutine REND_SW_GET_BITS_HW (N)
*
*   Return the actual number of physical bits used for the displayable part of each
*   pixel.
}
{
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*   ::        CONFIDENTIAL AND PROPRIETARY INFORMATION OF        ::
*   ::                    COGNIVISION, INC.                      ::
*   ::           PROTECTED BY THE COPYRIGHT LAW AS AN            ::
*   ::                    UNPUBLISHED WORK                       ::
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}
module rend_sw_get_bits_hw;
define rend_sw_get_bits_hw;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_bits_hw (        {get physical bits per pixel actually in use}
  out     n: real);                    {physical bits per pixel}

begin
  n := rend_bits_hw;
  end;
