{   Funtion REND_SW_GET_VIDEO_SYNC_INT
*
*   Returns TRUE if the video sync signal has been interrupted since
*   the interrupt flag had been cleared by rend_sw_video_sync_int_clr.
}
module rend_sw_get_video_sync_int;
define rend_sw_get_video_sync_int;
%include 'rend_sw2.ins.pas';

function rend_sw_get_video_sync_int: boolean; {TRUE if video sync interrupted}

begin
  rend_sw_get_video_sync_int := rend_video_sync_int;
  end;
