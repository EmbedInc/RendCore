{   Subroutine REND_SW_GET_CMODE_VALS (VALS)
*
*   Return the current state of all the changeable modes into the data structure
*   VALS.  This is intended to be used with the SET.CMODE_VALS call to restore the
*   changeable modes.
}
module rend_sw_get_cmode_vals;
define rend_sw_get_cmode_vals;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_cmode_vals (     {get current state of all changeable modes}
  out     vals: rend_cmode_vals_t);    {data block with all changeable modes values}

begin
  vals.max_buf := rend_max_buf;
  vals.disp_buf := rend_curr_disp_buf;
  vals.draw_buf := rend_curr_draw_buf;
  vals.min_bits_vis := rend_min_bits_vis;
  vals.min_bits_hw := rend_min_bits_hw;
  vals.dith_on := rend_dith.on;
  end;
