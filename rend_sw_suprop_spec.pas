{   Subroutine REND_SW_SUPROP_SPEC (R, G, B, E)
*
*   Set the specular surface property for the current face and turn it ON.
*   R, G, and B are the specular color.  E is the specular exponent.
}
module rend_sw_suprop_spec;
define rend_sw_suprop_spec;
%include 'rend_sw2.ins.pas';

procedure rend_sw_suprop_spec (        {set specular property and turn it ON}
  in      r, g, b: real;               {specular color}
  in      e: real);                    {specular exponent}
  val_param;

var
  save: univ_ptr;                      {saved copy of CHECK_MODES pointer}
  suprop: rend_suprop_val_t;           {value for surface property being set}

begin
  rend_sw_save_cmode (save);           {turn off CHECK_MODES}
  rend_set.suprop_on^ (rend_suprop_spec_k, true); {turn surface property ON}
  suprop.spec_red := r;
  suprop.spec_grn := g;
  suprop.spec_blu := b;
  suprop.spec_exp := e;
  rend_set.suprop_val^ (rend_suprop_spec_k, suprop); {set surface property value}
  rend_sw_restore_cmode (save);        {restore CHECK_MODES and run it if necessary}
  end;
