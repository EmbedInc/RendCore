{   Subroutine REND_SW_RGB (R, G, B)
*
*   Set the current red, green, and blue color as given.  The interpolation mode
*   for red, green, and blue will be set to flat.  The color values are in the
*   range 0.0 to 1.0.
}
module rend_sw_rgb;
define rend_sw_rgb;
%include 'rend_sw2.ins.pas';

procedure rend_sw_rgb (                {set flat RGB color}
  in      r, g, b: real);              {0.0-1.0 red, green, blue color values}
  val_param;

var
  save: univ_ptr;                      {saved copy of CHECK_MODES pointer}

begin
  rend_sw_save_cmode (save);           {turn off CHECK_MODES}
  rend_set.iterp_flat^ (rend_iterp_red_k, r);
  rend_set.iterp_flat^ (rend_iterp_grn_k, g);
  rend_set.iterp_flat^ (rend_iterp_blu_k, b);
  rend_sw_restore_cmode (save);        {restore CHECK_MODES and run it if necessary}
  end;
