{   Flat RGBA color settings.
}
module rend_sw_rgba;
define rend_sw_set_rgba;
define rend_sw_get_rgba;
%include 'rend_sw2.ins.pas';
{
********************************************************************************
*
*   Subroutine REND_SW_SET_RGBA (RED, GRN, BLU, ALP)
*
*   Set the current red, green, blue and alpha color as given.  The
*   interpolation mode for red, green, blue and alpha will be set to flat.  The
*   color values are in the range 0.0 to 1.0.
}
procedure rend_sw_set_rgba (           {set flat RGBA color}
  in      red, grn, blu: real;         {0.0 to 1.0 red, green, blue color values}
  in      alp: real);                  {0.0 to 1.0 opacity fraction}
  val_param;

var
  save: univ_ptr;                      {saved copy of CHECK_MODES pointer}

begin
  rend_sw_save_cmode (save);           {turn off CHECK_MODES}

  rend_set.iterp_flat^ (rend_iterp_red_k, red);
  rend_set.iterp_flat^ (rend_iterp_grn_k, grn);
  rend_set.iterp_flat^ (rend_iterp_blu_k, blu);
  if rend_iterps.alpha.on then begin   {alpha is enabled ?}
    rend_set.iterp_flat^ (rend_iterp_alpha_k, alp);
    end;

  rend_sw_restore_cmode (save);        {restore CHECK_MODES and run it if necessary}
  end;
{
********************************************************************************
*
*   Subroutine REND_SW_GET_RGBA (RED, GRN, BLU, ALP)
*
*   Get the current flat red, green, blu, and alpha settings.  Results are
*   undefined if the interpolants are not set to flat.  The returned values are
*   in the 0.0 to 1.0 scale.  If a color is disabled, it will be returned as
*   0 (black).  If alpha is disabled, it will be returned as 1 (fully opaque).
}
procedure rend_sw_get_rgba (           {get flat RGBA color setting}
  out     red, grn, blu: real;         {0.0 to 1.0 color, 0 for off}
  out     alp: real);                  {0.0 to 1.0 opacity, 1 for off}
  val_param;

begin
  if rend_iterps.red.on
    then red := rend_iterps.red.aval
    else red := 0.0;
  if rend_iterps.grn.on
    then grn := rend_iterps.grn.aval
    else grn := 0.0;
  if rend_iterps.blu.on
    then blu := rend_iterps.blu.aval
    else blu := 0.0;
  if rend_iterps.alpha.on
    then alp := rend_iterps.alpha.aval
    else alp := 1.0;
  end;
