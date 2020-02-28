{   Subroutine REND_SW_GET_MIN_BITS_VIS (N)
*
*   Return current value of the MIN_BITS_VIS parameters.
}
module rend_sw_get_min_bits_vis;
define rend_sw_get_min_bits_vis;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_min_bits_vis (   {return current VIS_MIN_BITS setting}
  out     n: real);                    {Log2 of total effective number of colors}

begin
  n := rend_min_bits_vis;
  end;
