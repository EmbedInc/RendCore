{   Subroutine REND_SW_SUPROP_EMIS (R, G, B)
*
*   Set the emissive surface property for the current face and turn it ON.
}
module rend_sw_suprop_emis;
define rend_sw_suprop_emis;
%include 'rend_sw2.ins.pas';

procedure rend_sw_suprop_emis (        {set emissive property and turn it ON}
  in      r, g, b: real);              {emissive color}
  val_param;

var
  save: univ_ptr;                      {saved copy of CHECK_MODES pointer}
  suprop: rend_suprop_val_t;           {value for surface property being set}

begin
  rend_sw_save_cmode (save);           {turn off CHECK_MODES}
  rend_set.suprop_on^ (rend_suprop_emis_k, true); {turn surface property ON}
  suprop.emis_red := r;
  suprop.emis_grn := g;
  suprop.emis_blu := b;
  rend_set.suprop_val^ (rend_suprop_emis_k, suprop); {set surface property value}
  rend_sw_restore_cmode (save);        {restore CHECK_MODES and run it if necessary}
  end;
