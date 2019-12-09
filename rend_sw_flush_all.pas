{   Subroutine REND_SW_FLUSH_ALL
*
*   Flush all remaining data from the pipe.  This guarantees that all primitives
*   called up to now actually make it to the image.
*
*   PRIM_DATA sw_write no
*   PRIM_DATA sw_read no
}
module rend_sw_flush_all;
define rend_sw_flush_all;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_flush_all_d.ins.pas';

procedure rend_sw_flush_all;

begin
  if rend_dirty_crect then begin       {whole clip rectangle needs to be updated ?}
    rend_internal.update_rect^ (       {update rectangle to display}
      rend_clip_2dim.ixmin, rend_clip_2dim.iymin, {top left corner of rectangle}
      rend_clip_2dim.ixmax - rend_clip_2dim.ixmin + 1, {width of rectangle}
      rend_clip_2dim.iymax - rend_clip_2dim.iymin + 1); {height of rectangle}
    rend_dirty_crect := false;         {whole clip rectangle is no longer dirty}
    rend_curr_span.dirty := false;     {no pending span exists}
    return;
    end;

  if not rend_curr_span.dirty then return; {no pending span to write out ?}
  rend_internal.update_span^ (
    rend_curr_span.left_x,             {left span pixel coordinate}
    rend_curr_span.y,
    rend_curr_span.right_x - rend_curr_span.left_x + 1); {number of pixels}
  rend_curr_span.dirty := false;       {no longer any span waiting to be written}
  end;
