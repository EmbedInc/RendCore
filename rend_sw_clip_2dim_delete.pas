{   Subroutine REND_SW_CLIP_2DIM_DELETE (HANDLE)
*
*   Completely deallocate the clip window indicated by HANDLE.  The handle will be
*   set to invalid.
}
module rend_sw_clip_2dim_delete;
define rend_sw_clip_2dim_delete;
%include 'rend_sw2.ins.pas';

procedure rend_sw_clip_2dim_delete (   {deallocate 2D image space clip window}
  in out  handle: rend_clip_2dim_handle_t); {returned as invalid}

begin
  rend_set.clip_2dim_on^ (handle, false); {turn off clipping window}
  rend_clips_2dim.clip[handle].exists := false; {this window no longer exists}
  end;
