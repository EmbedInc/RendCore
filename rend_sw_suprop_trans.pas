{   Subroutine REND_SW_SUPROP_TRANS (FRONT, SIDE)
*
*   Set the transparency surface property for the current face and turn it ON.
*   FRONT is the opaqueness fraction for when the surface is facing directly at the
*   viewer.  SIDE is the opaquen fraction for when the surface is facing sideways
*   to the viewer.
}
module rend_sw_suprop_trans;
define rend_sw_suprop_trans;
%include 'rend_sw2.ins.pas';

procedure rend_sw_suprop_trans (       {set transparency property and turn it ON}
  in      front: real;                 {opaqueness when facing head on}
  in      side: real);                 {opaqueness when facing sideways}
  val_param;

var
  save: univ_ptr;                      {saved copy of CHECK_MODES pointer}
  suprop: rend_suprop_val_t;           {value for surface property being set}

begin
  rend_sw_save_cmode (save);           {turn off CHECK_MODES}
  rend_set.suprop_on^ (rend_suprop_trans_k, true); {turn surface property ON}
  suprop.trans_front := front;
  suprop.trans_side := side;
  rend_set.suprop_val^ (rend_suprop_trans_k, suprop); {set surface property value}
  rend_sw_restore_cmode (save);        {restore CHECK_MODES and run it if necessary}
  end;
