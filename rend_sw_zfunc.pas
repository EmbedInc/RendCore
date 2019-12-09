{   Subroutine REND_SW_ZFUNC (ZFUNC)
*
*   Set the new current Z compare function.  The result of this Z compare function
*   determines whether writes to a particular pixel are to be inhibited.  The Z
*   interpolant must be turned on for Z buffering to be possible.
}
module rend_sw_zfunc;
define rend_sw_zfunc;
%include 'rend_sw2.ins.pas';

procedure rend_sw_zfunc (              {set new current Z compare function}
  in      zfunc: rend_zfunc_k_t);      {the Z compare function number}
  val_param;

begin
  if rend_zfunc = zfunc then return;   {nothing to do}
  rend_zfunc := zfunc;                 {save Z function code in common block}
  rend_internal.check_modes^;
  end;
