{   Subroutine REND_SW_UPDATE_MODE (MODE)
*
*   Set a new current display update mode.  This mode sets the strategy for
*   how often, and when, the display is updated to the software bitmap when
*   primitives are drawn using software emulation.
}
module rend_sw_update_mode;
define rend_sw_update_mode;
%include 'rend_sw2.ins.pas';

procedure rend_sw_update_mode (        {select how display is updated when SW emul}
  in      mode: rend_updmode_k_t);     {update mode, use REND_UPDMODE_xxx_K}
  val_param;

begin
  if rend_updmode = mode then return;  {nothing to do ?}

  rend_prim.flush_all^;                {do any pending updates before changing modes}
  rend_updmode := mode;                {set new mode}
  rend_crect_dirty_ok :=               {TRUE if OK to allow whole clip rect dirty}
    rend_clip_normal and
    (rend_updmode = rend_updmode_buffall_k);

  rend_internal.check_modes^;          {adjust to new mode setting}
  end;
