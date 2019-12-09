{   Subroutine REND_SW_MIN_BITS_HW (N)
*
*   Set the minimum number of actual data bits to use per pixel.
}
module rend_sw_min_bits_hw;
define rend_sw_min_bits_hw;
%include 'rend_sw2.ins.pas';

procedure rend_sw_min_bits_hw (        {set minimum required hardware bits per pixel}
  in      n: real);                    {actual number of hardware bits per pixel used}
  val_param;

var
  ln: real;                            {local copy of N}

begin
  rend_cmode[rend_cmode_minbits_hw_k] := false; {reset mode to not changed}
  ln := n;                             {init local copy of N}
  if ln < 0.0 then ln := 0.0;          {clip to lowest possible value}
  if abs(rend_min_bits_hw-ln) < 0.001 then return; {nothing to do ?}
  rend_min_bits_hw := ln;              {set value as received}

  if rend_min_bits_hw > 24.0 then begin {needs to be made smaller ?}
    rend_min_bits_hw := 24.0;
    rend_cmode[rend_cmode_minbits_hw_k] := true; {this mode got changed}
    end;

  rend_internal.check_modes^;
  end;
