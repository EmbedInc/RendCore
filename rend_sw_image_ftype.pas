{   Subroutine REND_SW_IMAGE_FTYPE (FTYPE)
*
*   Set the image output file type.  This is the name of the image driver that
*   will be used to write an image file, which is also the same as the image
*   file name suffix.  Examples are IMG and TGA.  FTYPE is case insensitive.
*   See the IMAGE_TYPES help file for a discussion of the various supported
*   image file types.
}
module rend_sw_image_ftype;
define rend_sw_image_ftype;
%include 'rend_sw2.ins.pas';

procedure rend_sw_image_ftype (        {set the image output file type}
  in      ftype: univ string_var_arg_t); {image file type name (IMG, TGA, etc.)}

begin
  string_copy (ftype, rend_image.ftype);
  string_downcase (rend_image.ftype);
  string_fill (rend_image.ftype);      {fill to max length with blanks}
  end;
