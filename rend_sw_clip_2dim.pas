{   Subroutine REND_SW_CLIP_2DIM (HANDLE, X1, X2, Y1, Y2, DRAW_INSIDE)
*
*   Set a clip window coordinates and turn it on.  HANDLE must be a previously
*   created handle to a clip window.  INSIDE is TRUE if drawing is allowed inside
*   the clip window, and inhibited outside.  X1 and X2 are the right and left
*   clipping rectangle boundaries.  They may be in any order.  The clipping rectangle
*   is between them.  Y1 and Y2 work the same way.
}
module rend_sw_clip_2dim;
define rend_sw_clip_2dim;
%include 'rend_sw2.ins.pas';

procedure rend_sw_clip_2dim (          {set 2D image clip window and turn it on}
  in      handle: rend_clip_2dim_handle_t; {handle to this clip window}
  in      x1, x2: real;                {X coordinate limits}
  in      y1, y2: real;                {y coordinate limits}
  in      draw_inside: boolean);       {TRUE for draw in, FALSE for exclude inside}
  val_param;

var
  xmin, xmax: real;                    {sorted X limits}
  ymin, ymax: real;                    {sorted Y limits}

begin
  with rend_clips_2dim.clip[handle]: r do begin {R is abbrev for this clip rectangle}
    if not r.exists then begin
      writeln ('Bad clip window handle in REND_SW_CLIP_2DIM.');
      sys_bomb;
      end;
    if (x1 < x2)                       {sort the X limits}
      then begin
        xmin := x1;
        xmax := x2;
        end
      else begin
        xmin := x2;
        xmax := x1;
        end
      ;
    if (y1 < y2)                       {sort the Y limits}
      then begin
        ymin := y1;
        ymax := y2;
        end
      else begin
        ymin := y2;
        ymax := y1;
        end
      ;
    r.xmin := max(0.001, min(rend_image.x_size - 0.001, xmin));
    r.xmax := max(0.001, min(rend_image.x_size - 0.001, xmax));
    r.ymin := max(0.001, min(rend_image.y_size - 0.001, ymin));
    r.ymax := max(0.001, min(rend_image.y_size - 0.001, ymax));
    r.draw_inside := draw_inside;
{
*   Calculate integer pixel bounds from floating point limits.  The integer values
*   reflect the edge coordinates that are just inside the region.  A pixel is
*   considered to be inside the region if its center is in the region.
}
    r.ixmin := trunc(r.xmin + 0.5);
    r.ixmax := trunc(r.xmax - 0.5);
    r.iymin := trunc(r.ymin + 0.5);
    r.iymax := trunc(r.ymax - 0.5);
    end;                               {done with R abbreviation}

  rend_set.clip_2dim_on^ (handle, true); {turn this clip window on}
  end;
