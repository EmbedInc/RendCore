{   Subroutine REND_CACHE_CLIP_2DIM
*
*   Cache the result of the current 2DIM clip conditions if the resulting draw
*   region is a rectangle.
}
module rend_cache_clip_2dim;
define rend_cache_clip_2dim;
%include 'rend2.ins.pas';

procedure rend_cache_clip_2dim;

var
  clip_new: rend_clip_2dim_t;          {new cached clip state}

begin
{
*   Calculate new cached clip state.
}
  case rend_clips_2dim.n_on of         {different handling of 0, 1, and many}
0:  begin                              {no rectangles on, use window limits}
      clip_new.xmin := 0.0;
      clip_new.xmax := rend_image.x_size;
      clip_new.ymin := 0.0;
      clip_new.ymax := rend_image.y_size;
      clip_new.ixmin := 0;
      clip_new.ixmax := rend_image.x_size - 1;
      clip_new.iymin := 0;
      clip_new.iymax := rend_image.y_size - 1;
      clip_new.on := true;
      clip_new.draw_inside := true;
      clip_new.exists := true;
      end;
1:  begin                              {one rectangle on, copy it directly}
      clip_new := rend_clips_2dim.clip[rend_clips_2dim.list_on[1]];
      end;
otherwise                              {more than one rectangle, can't cache result}
    clip_new.exists := false;
    end;                               {done with number of rectangles cases}
{
*   Compare the new cached clip state to the old.  We can avoid doing some
*   bookeeping if nothing really changed.
}
  if
      clip_new.exists and              {result can be cached as one rectangle ?}
      rend_clip_2dim.exists and        {old state was one rectangle too ?}
      clip_new.draw_inside and         {result is draw inside, clip outside ?}
      rend_clip_2dim.draw_inside and   {old was same ?}
      (clip_new.ixmin = rend_clip_2dim.ixmin) and {new coordinates match old ?}
      (clip_new.ixmax = rend_clip_2dim.ixmax) and
      (clip_new.iymin = rend_clip_2dim.iymin) and
      (clip_new.iymax = rend_clip_2dim.iymax)
    then return;                       {nothing more to do, state not really changed}
{
*   The final resulting clip state did change.
}
  rend_prim.flush_all^;                {flush pending updates before clip change}

  rend_clip_2dim := clip_new;          {update new cached clip state}
  rend_clip_normal :=                  {TRUE on single draw inside clip rectangle}
    rend_clip_2dim.exists and
    rend_clip_2dim.draw_inside;
  rend_crect_dirty_ok :=               {TRUE if OK to allow whole clip rect dirty}
    rend_clip_normal and
    (rend_updmode = rend_updmode_buffall_k);

  rend_internal.check_modes^;          {re-evaluate modes now that clip changed}
  end;
