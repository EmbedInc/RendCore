{   Subroutine REND_SW_GET_BITS_VIS (N)
*
*   Return the effective number of visible bits per pixel actually in use.
}
{
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*   ::        CONFIDENTIAL AND PROPRIETARY INFORMATION OF        ::
*   ::                    COGNIVISION, INC.                      ::
*   ::           PROTECTED BY THE COPYRIGHT LAW AS AN            ::
*   ::                    UNPUBLISHED WORK                       ::
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}
module rend_sw_get_bits_vis;
define rend_sw_get_bits_vis;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_bits_vis (       {get effective bits per pixel actually in use}
  out     n: real);                    {effective visible bits per pixel}

begin
  n := rend_bits_vis;
  end;
