{   Subroutine REND_SW_GET_POLY_PARMS (PARMS)
*
*   Return the current polygon drawing control parameters.
}
{
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*   ::        CONFIDENTIAL AND PROPRIETARY INFORMATION OF        ::
*   ::                    COGNIVISION, INC.                      ::
*   ::           PROTECTED BY THE COPYRIGHT LAW AS AN            ::
*   ::                    UNPUBLISHED WORK                       ::
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}
module rend_sw_get_poly_parms;
define rend_sw_get_poly_parms;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_poly_parms (     {get the current polygon drawing control parms}
  out     parms: rend_poly_parms_t);   {current polygon drawing parameters}

begin
  parms := rend_poly_parms;
  end;
