{   Subroutine REND_SW_CLEAR_CWIND
*
*   Clear the current clip region with the current modes.
}
module rend_sw_clear_cwind;
define rend_sw_clear_cwind;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_clear_cwind_d.ins.pas';

procedure rend_sw_clear_cwind;

begin
  if not rend_clip_normal then begin
    rend_message_bomb ('rend', 'rend_clip_complicated_ccwind', nil, 0);
    end;

  rend_set.cpnt_2dimi^ (               {set current point to top left corner}
    rend_clip_2dim.ixmin, rend_clip_2dim.iymin);
  rend_prim.rect_2dimi^ (              {draw rectangle over whole clip window}
    rend_clip_2dim.ixmax - rend_clip_2dim.ixmin + 1, {rectangle width}
    rend_clip_2dim.iymax - rend_clip_2dim.iymin + 1); {rectangle height}
  end;
