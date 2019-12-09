{   Subroutine REND_SW_GET_AA_RADIUS (R)
*
*   Return the current anti-aliasing filter kernal radius setting.  This value
*   is set to "normal" when RENDlib is initialized.
}
module rend_sw_get_aa_radius;
define rend_sw_get_aa_radius;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_aa_radius (      {return current anti-aliasing filter radius}
  out     r: real);                    {filter kernal radius in output image pixels}

begin
  r := rend_aa.kernel_rad;
  end;
