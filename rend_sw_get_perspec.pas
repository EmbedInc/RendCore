{   Subroutine REND_SW_GET_PERSPEC (ON,EYEDIS)
*
*   Return the current perspective parameters.
*
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*   ::        CONFIDENTIAL AND PROPRIETARY INFORMATION OF        ::
*   ::                    COGNIVISION, INC.                      ::
*   ::           PROTECTED BY THE COPYRIGHT LAW AS AN            ::
*   ::                    UNPUBLISHED WORK                       ::
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}
module rend_sw_get_perspec;
define rend_sw_get_perspec;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_perspec (        {get current perspective parameters}
  out     on: boolean;                 {TRUE if perspective projection on}
  out     eyedis: real);               {eye distance perspective value, 3.3 = normal}

begin
  on := rend_view.perspec_on;
  eyedis := rend_view.eyedis;
  end;
