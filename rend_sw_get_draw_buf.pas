{   Subroutine REND_SW_GET_DRAW_BUF (N)
*
*   Return the number of the current drawing buffer.
}
module rend_sw_get_draw_buf;
define rend_sw_get_draw_buf;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_draw_buf (       {return number of current drawing buffer}
  out     n: sys_int_machine_t);       {current drawing buffer number}

begin
  n := rend_curr_draw_buf;
  end;
