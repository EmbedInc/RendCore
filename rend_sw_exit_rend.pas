{   Subroutine REND_SW_EXIT_REND
*
*   Leave graphics mode.
}
module rend_sw_exit_rend;
define rend_sw_exit_rend;
%include 'rend_sw2.ins.pas';

procedure rend_sw_exit_rend;

begin
  if rend_enter_level <= 0 then begin
    writeln ('EXIT_REND called while not in graphics mode.');
    sys_bomb;
    end;
  rend_enter_level := rend_enter_level - 1; {one less level into graphics mode}
  if rend_enter_level > 0 then return; {still in graphics mode ?}

  rend_prim.flush_all^;
  sys_fpmode_set (rend_old_fpp_traps); {restore old FP exception handling modes}
  end;
