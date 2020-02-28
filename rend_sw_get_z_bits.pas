{   Subroutine REND_SW_GET_Z_BITS (N)
*
*   Return the effective hardware Z buffer resolution in bits.
}
module rend_sw_get_z_bits;
define rend_sw_get_z_bits;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_z_bits (         {return hardware Z buffer resolution}
  out     n: real);                    {effective Z buffer resolution in bits}

begin
  n := rend_iterps.z.width;
  end;
