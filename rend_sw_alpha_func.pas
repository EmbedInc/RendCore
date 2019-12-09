{   Subroutine REND_SW_ALPHA_FUNC (AFUNC)
*
*   Set the new current alpha buffer blending function.
}
module rend_sw_alpha_func;
define rend_sw_alpha_func;
%include 'rend_sw2.ins.pas';

procedure rend_sw_alpha_func (         {set alpha buffering (compositing) function}
  in      afunc: rend_afunc_k_t);      {alpha function ID}
  val_param;

begin
  if afunc = rend_afunc then return;   {nothing to do ?}
  rend_afunc := afunc;
  rend_internal.check_modes^;          {update routine pointers and device modes}
  end;
