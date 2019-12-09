{   Subroutine REND_SW_SAVE_CMODE (SAVE)
*
*   Return the current CHECK_MODES routine pointer, and install the dummy check
*   modes routine.  The dummy routine only sets the REND_MODE_CHANGED flag if called.
}
module rend_sw_save_cmode;
define rend_sw_save_cmode;
%include 'rend_sw2.ins.pas';

procedure rend_sw_save_cmode (         {save old CHECK_MODES ptr and set to dummy}
  out     save: univ_ptr);             {old CHECK_MODES routine pointer}

begin
  save := rend_internal.check_modes;   {return old CHECK_MODES routine pointer}
  rend_internal.check_modes := addr(rend_sw_dummy_cmode); {install dummy routine}
  end;
