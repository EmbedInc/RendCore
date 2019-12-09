{   Subroutine REND_SW_RESTORE_CMODE (SAVE)
*
*   Restore the CHECK_MODES routine pointer and run the new CHECK_MODES routine if
*   any pending mode change exists.  This routine is intended to be used with
*   REND_SW_SAVE_CMODE.
}
module rend_sw_restore_cmode;
define rend_sw_restore_cmode;
%include 'rend_sw2.ins.pas';

procedure rend_sw_restore_cmode (      {restore CHECK_MODES ptr and run CHECK_MODES}
  in      save: univ_ptr);             {old CHECK_MODES routine pointer saved earlier}
  val_param;

begin
  rend_internal.check_modes := save;   {restore old CHECK_MODES routine pointer}
  if rend_mode_changed                 {some mode did change ?}
    then rend_internal.check_modes^;
  end;
