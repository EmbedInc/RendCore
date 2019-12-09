{   Subroutine REND_SW_GET_DITH_ON (ON)
*
*   Return TRUE if dithering is turned on.
}
{
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*   ::        CONFIDENTIAL AND PROPRIETARY INFORMATION OF        ::
*   ::                    COGNIVISION, INC.                      ::
*   ::           PROTECTED BY THE COPYRIGHT LAW AS AN            ::
*   ::                    UNPUBLISHED WORK                       ::
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}
module rend_sw_get_dith_on;
define rend_sw_get_dith_on;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_dith_on (        {get current state of dithering on/off flag}
  out     on: boolean);                {TRUE if dithering turned on}

begin
  on := rend_dith.on;
  end;
