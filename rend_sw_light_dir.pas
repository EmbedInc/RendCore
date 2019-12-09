{   Subroutine REND_SW_LIGHT_DIR (H, RED, GRN, BLU, VX, VY, VZ)
*
*   Set a light source to be of type DIRECTIONAL, set its values, and turn it ON.
*   H is the handle to the light source.  RED, GRN, and BLU are the light source
*   color values.  VX, VY, and VZ are the direction vector to the light source.
*   This vector will be unitized before being used to set the light source direction.
}
module rend_sw_light_dir;
define rend_sw_light_dir;
%include 'rend_sw2.ins.pas';

procedure rend_sw_light_dir (          {set directional light source and turn ON}
  in      h: rend_light_handle_t;      {handle to light source}
  in      red, grn, blu: real;         {light source brightness values}
  in      vx, vy, vz: real);           {direction vector, need not be unitized}
  val_param;

var
  cm_save: univ_ptr;                   {save area for CHECK_MODES state}
  val: rend_light_val_t;               {light source parameters in proper format}
  m: real;                             {scale factor for unitizing vector}

begin
  rend_sw_save_cmode (cm_save);        {turn off CHECK_MODES}

  val.dir_red := red;                  {reformat data for REND_SET.LIGHT_VAL}
  val.dir_grn := grn;
  val.dir_blu := blu;
  m :=                                 {scale factor for unitizing direction vector}
    1.0 / sqrt( sqr(vx) + sqr(vy) + sqr(vz) );
  val.dir_unorm.x := vx * m;           {make unit direction vector}
  val.dir_unorm.y := vy * m;
  val.dir_unorm.z := vz * m;
  rend_set.light_val^ (h, rend_ltype_dir_k, val); {set light source type and values}
  rend_set.light_on^ (h, true);        {turn light source ON}

  rend_sw_restore_cmode (cm_save);     {restore CHECK_MODES and run if needed}
  end;
