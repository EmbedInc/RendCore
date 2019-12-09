{   Subroutine REND_SW_LIGHT_PNT (H, RED, GRN, BLU, X, Y, Z)
*
*   Set a light source to be of type POINT with no falloff, set its values,
*   and turn it ON.  H is the handle to the light source.  RED, GRN, and BLU
*   are the light source color values.  X, Y, and Z are the coordinate for the
*   light source.
}
module rend_sw_light_pnt;
define rend_sw_light_pnt;
%include 'rend_sw2.ins.pas';

procedure rend_sw_light_pnt (          {set point light with no falloff, turn ON}
  in      h: rend_light_handle_t;      {handle to light source}
  in      red, grn, blu: real;         {light source brightness values}
  in      x, y, z: real);              {light source coordinate}
  val_param;

var
  cm_save: univ_ptr;                   {save area for CHECK_MODES state}
  val: rend_light_val_t;               {light source parameters in proper format}

begin
  rend_sw_save_cmode (cm_save);        {turn off CHECK_MODES}

  val.pnt_red := red;                  {reformat data for REND_SET.LIGHT_VAL}
  val.pnt_grn := grn;
  val.pnt_blu := blu;
  val.pnt_coor.x := x;
  val.pnt_coor.y := y;
  val.pnt_coor.z := z;
  rend_set.light_val^ (h, rend_ltype_pnt_k, val); {set light source type and values}
  rend_set.light_on^ (h, true);        {turn light source ON}

  rend_sw_restore_cmode (cm_save);     {restore CHECK_MODES and run if needed}
  end;
