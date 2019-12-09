{   Subroutine REND_SW_SUPROP_DIFF (R, G, B)
*
*   Set the diffuse surface property for the current face and turn it ON.
}
module rend_sw_suprop_diff;
define rend_sw_suprop_diff;
%include 'rend_sw2.ins.pas';

procedure rend_sw_suprop_diff (        {set diffuse property and turn it ON}
  in      r, g, b: real);              {diffuse color}
  val_param;

var
  save: univ_ptr;                      {saved copy of CHECK_MODES pointer}
  suprop: rend_suprop_val_t;           {value for surface property being set}

begin
  rend_sw_save_cmode (save);           {turn off CHECK_MODES}
  rend_set.suprop_on^ (rend_suprop_diff_k, true); {turn surface property ON}
  suprop.diff_red := r;
  suprop.diff_grn := g;
  suprop.diff_blu := b;
  rend_set.suprop_val^ (rend_suprop_diff_k, suprop); {set surface property value}
  rend_sw_restore_cmode (save);        {restore CHECK_MODES and run it if necessary}
  end;
