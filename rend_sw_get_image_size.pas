{   Subroutine REND_SW_GET_IMAGE_SIZE (X_SIZE,Y_SIZE,ASPECT)
*
*   Get the current size and aspect ratio of the output image.
}
module rend_sw_get_image_size;
define rend_sw_get_image_size;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_image_size (     {return dimension and aspect ratio of image}
  out     x_size, y_size: sys_int_machine_t; {image width and height in pixels}
  out     aspect: real);               {DX/DY aspect ratio when displayed}

begin
  x_size := rend_image.x_size;
  y_size := rend_image.y_size;
  aspect := rend_image.aspect;
  end;
