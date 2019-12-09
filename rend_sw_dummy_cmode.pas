{   Subroutine REND_SW_DUMMY_CMODE
*
*   Dummy CHECK_MODES routine.  This routine assumes that it is only called when
*   a mode actually got changed, and that therefore the real CHECK_MODES routine
*   eventually needs to be called.  The flag REND_MODE_CHANGED is set to TRUE to
*   remember that some mode changed.  The real CHECK_MODES routine should eventually
*   get called if this flag is found TRUE.
}
module rend_sw_dummy_cmode;
define rend_sw_dummy_cmode;
%include 'rend_sw2.ins.pas';

procedure rend_sw_dummy_cmode;         {used when calls to CHECK_MODES are deferred}

begin
  rend_mode_changed := true;
  end;
