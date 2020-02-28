{   Subroutine REND_SW_GET_MIN_BITS_HW (N)
*
*   Return current value of the MIN_BITS_HW parameters.
}
module rend_sw_get_min_bits_hw;
define rend_sw_get_min_bits_hw;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_min_bits_hw (    {return current HW_MIN_BITS setting}
  out     n: real);                    {actual number of hardware bits per pixel used}

begin
  n := rend_min_bits_hw;
  end;
