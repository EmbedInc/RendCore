{   Subroutine REND_SW_LIGHT_VAL (H, LTYPE, VAL)
*
*   Set the data values for a light source.  H is the handle to the light source.
*   LTYPE indicates what type of light source this light source is to become.
*   Use the constants with names REND_LTYPE_xxx_K for values of LTYPE.
*   VAL is the data values for the light source.  The format of VAL depends on the
*   light source type.
}
module rend_sw_light_val;
define rend_sw_light_val;
%include 'rend_sw2.ins.pas';

procedure rend_sw_light_val (          {set value for a light source}
  in      h: rend_light_handle_t;      {handle to this light source}
  in      ltype: rend_ltype_k_t;       {type of light source}
  in      val: rend_light_val_t);      {LTYPE dependent data values for this light}
  val_param;

begin
  h^.ltype := ltype;                   {set type of this light source}
  case ltype of                        {different code for each light type}

rend_ltype_amb_k: begin                {ambient light source}
      h^.amb_red := val.amb_red;
      h^.amb_grn := val.amb_grn;
      h^.amb_blu := val.amb_blu;
      end;

rend_ltype_dir_k: begin                {directional light source}
      h^.dir_red := val.dir_red;
      h^.dir_grn := val.dir_grn;
      h^.dir_blu := val.dir_blu;
      h^.dir := val.dir_unorm;
      end;

rend_ltype_pnt_k: begin                {point light source with no falloff}
      h^.pnt_red := val.pnt_red;
      h^.pnt_grn := val.pnt_grn;
      h^.pnt_blu := val.pnt_blu;
      h^.pnt := val.pnt_coor;
      end;

rend_ltype_pr2_k: begin                {point light source with 1/R**2 falloff}
      h^.pr2_red := val.pr2_red;
      h^.pr2_grn := val.pr2_grn;
      h^.pr2_blu := val.pr2_blu;
      h^.pr2_coor := val.pr2_coor;
      h^.pr2_r2 := sqr(val.pr2_r);     {save square of anchor radius}
      end;
    end;                               {end of light source type cases}

  if h^.on then begin                  {light source change effects lighting state ?}
    rend_lights.changed := true;       {indicate lighting environment changed}
    rend_internal.check_modes^;        {notify driver of change}
    end;
  end;
