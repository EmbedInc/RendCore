{  Module of routines for determining color values to use in XOR mode.
}
module rend_sw_get_color_xor;
define rend_sw_get_color_xor;
define rend_sw_icolor_xor;
%include 'rend_sw2.ins.pas';
{
************************************************
*
*   Subroutine REND_SW_GET_COLOR_XOR (COLOR1, COLOR2, COLOR_XOR)
*
*   Determine the drawing color value needed to toggle between two given
*   colors when the XOR pixel function is used.  COLOR1 and COLOR2 are
*   the two colors to toggle between.  COLOR_XOR will be returned as XOR
*   mode drawing color value that will cause pixels with color COLOR1 to
*   change to COLOR2, and pixels with color COLOR2 to change to COLOR1.
*
*   It is not possible to guarantee the behaviour of any other pixel colors
*   when COLOR_XOR is applied in XOR mode.
}
procedure rend_sw_get_color_xor (      {get color to XOR between two other colors}
  in      color1, color2: rend_rgb_t;  {two colors to toggle between}
  out     color_xor: rend_rgb_t);      {color value to use with XOR pixel function}
  val_param;

var
  icolor1, icolor2: img_pixel1_t;      {integer color values}
  icolor_xor: img_pixel1_t;            {integer XOR color value}

begin
  icolor1.red :=                       {convert color 1 to integer values}
    rshft(
      round(65536.0 * (rend_iterps.red.val_offset +
        rend_iterps.red.val_scale * color1.red)),
      16);
  icolor1.grn :=
    rshft(
      round(65536.0 * (rend_iterps.grn.val_offset +
        rend_iterps.grn.val_scale * color1.grn)),
      16);
  icolor1.blu :=
    rshft(
      round(65536.0 * (rend_iterps.blu.val_offset +
        rend_iterps.blu.val_scale * color1.blu)),
      16);
  icolor1.alpha := 255;

  icolor2.red :=                       {convert color 2 to integer values}
    rshft(
      round(65536.0 * (rend_iterps.red.val_offset +
        rend_iterps.red.val_scale * color2.red)),
      16);
  icolor2.grn :=
    rshft(
      round(65536.0 * (rend_iterps.grn.val_offset +
        rend_iterps.grn.val_scale * color2.grn)),
      16);
  icolor2.blu :=
    rshft(
      round(65536.0 * (rend_iterps.blu.val_offset +
        rend_iterps.blu.val_scale * color2.blu)),
      16);
  icolor2.alpha := 255;

  icolor_xor.red := 0;                 {set values for fields that may be unused}
  icolor_xor.grn := 0;
  icolor_xor.blu := 0;
  icolor_xor.alpha := 255;

  rend_internal.icolor_xor^ (          {find integer XOR color value}
    icolor1, icolor2,                  {the two colors to toggle between}
    icolor_xor);                       {XOR color value that causes the toggle}

  color_xor.red :=                     {convert integer XOR color to floating point}
    (icolor_xor.red - rend_iterps.red.val_offset) /
    rend_iterps.red.val_scale;
  color_xor.grn :=
    (icolor_xor.grn - rend_iterps.grn.val_offset) /
    rend_iterps.grn.val_scale;
  color_xor.blu :=
    (icolor_xor.blu - rend_iterps.blu.val_offset) /
    rend_iterps.blu.val_scale;
  end;
{
************************************************
*
*   Subroutine REND_SW_ICOLOR_XOR (COLOR1, COLOR2, COLOR_XOR)
*
*   Same as GET_COLOR_XOR, above, except works with integer color values.
*   The ALPHA field in the color descriptor is not used.  This routine
*   is intended for customization by specific drivers, since conversion
*   to/from floating point is a common problem.
}
procedure rend_sw_icolor_xor (         {get integer color to XOR between two others}
  in      color1, color2: img_pixel1_t; {RGB values to toggle between, ALPHA unused}
  out     color_xor: img_pixel1_t);    {color value to write with XOR pixel function}
  val_param;

begin
  color_xor.red := xor(color1.red, color2.red);
  color_xor.grn := xor(color1.grn, color2.grn);
  color_xor.blu := xor(color1.blu, color2.blu);
  end;
