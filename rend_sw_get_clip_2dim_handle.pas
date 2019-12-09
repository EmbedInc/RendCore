{   Subroutine REND_SW_GET_CLIP_2DIM_HANDLE (HANDLE)
*
*   Create a handle for a new clipping window.  The clipping window will not have
*   coordinates set or be turned on.
}
module rend_sw_get_clip_2dim_handle;
define rend_sw_get_clip_2dim_handle;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_clip_2dim_handle ( {make new  handle for 2D image space clip wind}
  out     handle: rend_clip_2dim_handle_t); {return a valid clip window handle}

var
  i: integer32;                        {loop counter}

begin
  for i := 1 to rend_max_clip_2dim do begin {once for each possible clip window}
    if not rend_clips_2dim.clip[i].exists then begin {found unused clip window slot ?}
      rend_clips_2dim.clip[i].exists := true; {this window now used}
      rend_clips_2dim.clip[i].on := false; {init to window turned off}
      rend_clips_2dim.clip[i].xmin := 0.0; {init coordinates to image bounds}
      rend_clips_2dim.clip[i].xmax := rend_image.x_size;
      rend_clips_2dim.clip[i].ymin := 0.0;
      rend_clips_2dim.clip[i].ymax := rend_image.y_size;
      rend_clips_2dim.clip[i].draw_inside := true; {init to drawing allowed within}
      handle := i;                     {return handle to this window}
      return;                          {done setting up new clip window}
      end;
    end;                               {back and check next clip window for unused}
  writeln (
    'No more clip windows available in subroutine REND_SW_GET_CLIP_2DIM_HANDLE.');
  sys_bomb;
  end;
