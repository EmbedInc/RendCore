{   Subroutine REND_SW_MIN_BITS_VIS (N)
*
*   Set the minimum number of effective bits to use per pixel.  This is basically
*   Log2 of the number of effective colors.  The effective colors are counted
*   after dithering is applied, if on.
}
module rend_sw_min_bits_vis;
define rend_sw_min_bits_vis;
%include 'rend_sw2.ins.pas';

procedure rend_sw_min_bits_vis (       {set minimum required effective bits per pixel}
  in      n: real);                    {Log2 of total effective number of colors}
  val_param;

var
  ln: real;                            {local copy of N}

begin
  rend_cmode[rend_cmode_minbits_vis_k] := false; {reset mode to not changed}
  ln := n;                             {init local copy of N}
  if ln < 0.0 then ln := 0.0;          {clip to lowest possible value}
  if abs(rend_min_bits_vis-ln) < 0.001 then return; {nothing to do ?}
  rend_min_bits_vis := ln;             {set value as received}

  if rend_min_bits_vis > 24.01 then begin {needs to be made smaller ?}
    rend_min_bits_vis := 24.0;
    rend_cmode[rend_cmode_minbits_vis_k] := true; {this mode got changed}
    end;

  rend_internal.check_modes^;
  end;
