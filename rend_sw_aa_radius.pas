{   Subroutine REND_SW_AA_RADIUS (R)
*
*   Set the anti-aliasing filter kernal size to a new value.  R is the radius of
*   the filter kernel in output image pixel sizes.  The normal value is 1.25.
*   Values greater than that cause increased blurring, and lower values will
*   cause more aliasing artifacts to show.
}
module rend_sw_aa_radius;
define rend_sw_aa_radius;
%include 'rend_sw2.ins.pas';

procedure rend_sw_aa_radius (          {set anti-aliasing filter kernal radius}
  in      r: real);                    {radius in output pixels, normal = 1.25}
  val_param;

var
  scale_x, scale_y: real;              {saved X and Y AA filter scale factors}

begin
  if abs(r - rend_aa.kernel_rad) < 1.0E-4 then return; {nothing to change ?}

  scale_x := rend_aa.scale_x;          {save existing shrink scale factors}
  scale_y := rend_aa.scale_y;
  rend_aa.scale_x := scale_x - 1.0;    {force filter kernel re-evaluation}
  rend_aa.scale_y := scale_y - 1.0;
  rend_aa.kernel_rad := r;             {set new filter kernel radius}
  rend_set.aa_scale^ (scale_x, scale_y); {re-compute anti-aliasing filter kernel}
  end;
