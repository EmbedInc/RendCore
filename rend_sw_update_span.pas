{   Subroutine REND_SW_UPDATE_SPAN (X,Y,LEN)
*
*   This primitive is used internally to indicate that a span of pixels got
*   altered, and that the device may want to take some action, such as write them
*   to the screen.
*
*   NOTE:  The SW bitmap driver version of this primitive does nothing.
*
*   PRIM_DATA sw_read no
*   PRIM_DATA sw_write no
}
module rend_sw_update_span;
define rend_sw_update_span;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_update_span_d.ins.pas';

procedure rend_sw_update_span (        {update device span from SW bitmap}
  in      x: sys_int_machine_t;        {starting X pixel address of span}
  in      y: sys_int_machine_t;        {scan line coordinate span is on}
  in      len: sys_int_machine_t);     {number of pixels in span}
  val_param;

begin
  end;
