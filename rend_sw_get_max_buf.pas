{   Subroutine REND_SW_GET_MAX_BUF (N)
*
*   Return the maximum number of buffers supported by the current device.  This
*   is useful, for example, to determine whether the device is capable of double
*   buffering.  The returned N value is therefore the maximum usefule value for
*   calls such as SET.DISP_BUF (N).
}
module rend_sw_get_max_buf;
define rend_sw_get_max_buf;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_max_buf (        {return max buffers available on device}
  out     n: sys_int_machine_t);       {number of highest buffer, first buffer is 1}

begin
  n := rend_max_buf;
  end;
