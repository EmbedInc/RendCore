{   Subroutine REND_SW_LIGHT_AMB (H, RED, GRN, BLU, R, X, Y, Z)
*
*   Set a light source to be of type POINT with 1/R**2 falloff, set its values,
*   and turn it ON.  H is the handle to the light source.  RED, GRN, and BLU are
*   the light source color value at radius R.  X, Y, and Z are the light source
*   coordinate.  The effect of the color values will be scaled by the reciprocal
*   of the squared distance to the light source.  The color values given here
*   will apply without any scaling at radius R.  They will be brighter at closer
*   distances and dimmer at farther distance.  This is the way real light behaves.
}
module rend_sw_light_pr2;
define rend_sw_light_pr2;
%include 'rend_sw2.ins.pas';

procedure rend_sw_light_pr2 (          {set point light with falloff, turn ON}
  in      h: rend_light_handle_t;      {handle to light source}
  in      red, grn, blu: real;         {light source brightness values at radius}
  in      r: real;                     {radius where given intensities apply}
  in      x, y, z: real);              {light source coordinate}
  val_param;

var
  cm_save: univ_ptr;                   {save area for CHECK_MODES state}
  val: rend_light_val_t;               {light source parameters in proper format}

begin
  rend_sw_save_cmode (cm_save);        {turn off CHECK_MODES}

  val.pr2_red := red;                  {reformat data for REND_SET.LIGHT_VAL}
  val.pr2_grn := grn;
  val.pr2_blu := blu;
  val.pr2_r := r;
  val.pr2_coor.x := x;
  val.pr2_coor.y := y;
  val.pr2_coor.z := z;
  rend_set.light_val^ (h, rend_ltype_pr2_k, val); {set light source type and values}
  rend_set.light_on^ (h, true);        {turn light source ON}

  rend_sw_restore_cmode (cm_save);     {restore CHECK_MODES and run if needed}
  end;
