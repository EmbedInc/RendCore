{   Subroutine REND_SW_IMAGE_SIZE (X_SIZE,Y_SIZE,ASPECT)
*
*   Set the size of the current output image.  The interpolators may each be pointing
*   to different bitmaps, so this is the only way to describe what the whole image
*   size is.  No checking is done to insure that all bitmaps are sufficiently large
*   to accomodate this image size.  The application must guarantee not to read or
*   write any pixels that do not exist in the bitmaps.
}
module rend_sw_image_size;
define rend_sw_image_size;
%include 'rend_sw2.ins.pas';

procedure rend_sw_image_size (         {set size and aspect of current output image}
  in      x_size, y_size: sys_int_machine_t; {number of pixels in each dimension}
  in      aspect: real);               {DX/DY image aspect ratio when displayed}
  val_param;

begin
  if rend_image.size_fixed then return; {not allowed to change size ?}

  rend_image.x_size := x_size;
  rend_image.y_size := y_size;
  rend_image.aspect := aspect;
  rend_sw_update_xf2d;
  rend_cache_clip_2dim;
  end;
