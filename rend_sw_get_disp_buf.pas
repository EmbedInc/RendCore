{   Subroutine REND_SW_GET_DISP_BUF (N)
*
*   Return the number of the current display buffer.
}
module rend_sw_get_disp_buf;
define rend_sw_get_disp_buf;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_disp_buf (       {return number of current display buffer}
  out     n: sys_int_machine_t);       {current display buffer number}

begin
  n := rend_curr_disp_buf;
  end;
