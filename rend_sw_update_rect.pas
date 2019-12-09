{   Subroutine REND_SW_UPDATE_RECT (X, Y, DX, DY)
*
*   Cause a rectangle of pixels to be updated on the display from the copy
*   in the software bitmap.
*
*   PRIM_DATA prim_data_p rend_internal.update_span_data_p
}
module rend_sw_update_rect;
define rend_sw_update_rect;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_update_rect_d.ins.pas';

procedure rend_sw_update_rect (        {update device rectangle from SW bitmap}
  in      x, y: sys_int_machine_t;     {upper left pixel in rectangle}
  in      dx, dy: sys_int_machine_t);  {dimensions of rectangle in pixels}
  val_param;

var
  span_y: sys_int_machine_t;           {current span Y coordinate}

begin
  for span_y := y to y + dy - 1 do begin {once for each scan line in rectangle}
    rend_internal.update_span^ (x, span_y, dx);
    end;
  end;
