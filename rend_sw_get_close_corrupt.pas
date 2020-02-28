{   Funtion REND_SW_GET_CLOSE_CORRUPT
*
*   Returns TRUE if the display will be corrupted on close of the
*   of the current graphics device.
}
module rend_sw_get_close_corrupt;
define rend_sw_get_close_corrupt;
%include 'rend_sw2.ins.pas';

function rend_sw_get_close_corrupt: boolean; {true if display will be corrupted}

begin
  rend_sw_get_close_corrupt := rend_close_corrupt;
  end;
