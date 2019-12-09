{   Funtion REND_SW_GET_CLOSE_CORRUPT
*
*   Returns TRUE if the display will be corrupted on close of the
*   of the current graphics device.
}
{
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*   ::        CONFIDENTIAL AND PROPRIETARY INFORMATION OF        ::
*   ::                    COGNIVISION, INC.                      ::
*   ::           PROTECTED BY THE COPYRIGHT LAW AS AN            ::
*   ::                    UNPUBLISHED WORK                       ::
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}
module rend_sw_get_close_corrupt;
define rend_sw_get_close_corrupt;
%include 'rend_sw2.ins.pas';

function rend_sw_get_close_corrupt: boolean; {true if display will be corrupted}

begin
  rend_sw_get_close_corrupt := rend_close_corrupt;
  end;
