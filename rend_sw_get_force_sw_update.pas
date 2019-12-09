{   Subroutine REND_SW_GET_FORCE_SW_UPDATE (ON)
*
*   Return the current state of the FORCE_SW_UPDATE flag.  This flag is only set
*   thru the call REND_SET.FORCE_SW_UPDATE.
*
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*   ::        CONFIDENTIAL AND PROPRIETARY INFORMATION OF        ::
*   ::                    COGNIVISION, INC.                      ::
*   ::           PROTECTED BY THE COPYRIGHT LAW AS AN            ::
*   ::                    UNPUBLISHED WORK                       ::
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}
module rend_sw_get_force_sw_update;
define rend_sw_get_force_sw_update;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_force_sw_update ( {return what user last set FORCE_SW_UPDATE to}
  out     on: boolean);                {last user setting of FORCE_SW_UPDATE}

begin
  on := rend_force_sw;
  end;
