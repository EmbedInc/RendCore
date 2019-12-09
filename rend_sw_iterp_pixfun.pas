{   Subroutine REND_SW_ITERP_PIXFUN (ITERP,PIXFUN)
*
*   Set the pixel write function for this interpolant.
}
module rend_sw_iterp_pixfun;
define rend_sw_iterp_pixfun;
%include 'rend_sw2.ins.pas';

procedure rend_sw_iterp_pixfun (       {set pixel write function}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      pixfun: rend_pixfun_k_t);    {pixel function identifier}
  val_param;

begin
  if rend_iterps.iterp[iterp].pixfun = pixfun then return; {nothing to do ?}
  rend_iterps.iterp[iterp].pixfun := pixfun;
  rend_internal.check_modes^;          {update routine pointers and device modes}
  end;
