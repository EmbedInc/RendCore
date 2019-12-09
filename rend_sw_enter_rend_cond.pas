{   Subroutine REND_SW_ENTER_REND_COND (ENTERED)
*
*   Perform and ENTER_REND operation only if it can be done immediately.  If so,
*   return ENTERED as TRUE.  If the ENTER_REND can not be done immediately, no
*   ENTER_REND is performed, and ENTERED is returned as FALSE.  This can be the
*   case, for example, when the window is occluded.
*
*   The SW device always performs the ENTER_REND.
}
module rend_sw_enter_rend_cond;
define rend_sw_enter_rend_cond;
%include 'rend_sw2.ins.pas';

procedure rend_sw_enter_rend_cond (    {ENTER_REND only if possible immediately}
  out     entered: boolean);           {TRUE if did ENTER_REND}

begin
  entered := true;                     {SW device can always ENTER_REND}
  rend_enter_cnt := rend_enter_cnt + 1; {count one ENTER_REND call}
  rend_enter_level := rend_enter_level + 1; {one more level into graphics mode}
  if rend_enter_level > 1 then return; {already in graphics mode ?}

  sys_fpmode_get (rend_old_fpp_traps); {save existing FP handling modes}
  sys_fpmode_traps_none;               {disable all FP exception traps}
  end;
