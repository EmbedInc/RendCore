{   Subroutine REND_SW_SHNORM_BREAK_COS (C)
*
*   Set the threshold value for deciding whether a particular V should be included
*   in the shading normal calculation.  C is the cosine of the maximum allowed angle
*   between the cross product of two Vs for both Vs to be considered in the shading
*   normal calculation.
}
module rend_sw_shnorm_break_cos;
define rend_sw_shnorm_break_cos;
%include 'rend_sw2.ins.pas';

procedure rend_sw_shnorm_break_cos (   {set threshold for making break in spokes list}
  in      c: real);                    {COS of max allowed deviation angle}
  val_param;

begin
  rend_break_cos := c;
  end;
