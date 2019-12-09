{   Subroutine REND_SW_LIGHT_AMB (H, RED, GRN, BLU)
*
*   Set a light source to be of type ambient, set its values, and turn it ON.
*   H is the handle to the light source.  RED, GRN, and BLU are the color values
*   for this light source.
}
module rend_sw_light_amb;
define rend_sw_light_amb;
%include 'rend_sw2.ins.pas';

procedure rend_sw_light_amb (          {set ambient light source and turn ON}
  in      h: rend_light_handle_t;      {handle to light source}
  in      red, grn, blu: real);        {light source brightness values}
  val_param;

var
  cm_save: univ_ptr;                   {save area for CHECK_MODES state}
  val: rend_light_val_t;               {light source parameters in proper format}

begin
  rend_sw_save_cmode (cm_save);        {turn off CHECK_MODES}

  val.amb_red := red;                  {reformat data for REND_SET.LIGHT_VAL}
  val.amb_grn := grn;
  val.amb_blu := blu;
  rend_set.light_val^ (h, rend_ltype_amb_k, val); {set light source type and values}
  rend_set.light_on^ (h, true);        {turn light source ON}

  rend_sw_restore_cmode (cm_save);     {restore CHECK_MODES and run if needed}
  end;
