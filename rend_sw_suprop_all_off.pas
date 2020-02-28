{   Subroutine REND_SW_SUPROP_ALL_OFF
*
*   Turn off all surface properties that exist.
}
module rend_sw_suprop_all_off;
define rend_sw_suprop_all_off;
%include 'rend_sw2.ins.pas';

procedure rend_sw_suprop_all_off;

var
  save: univ_ptr;                      {saved copy of CHECK_MODES pointer}

begin
  rend_sw_save_cmode (save);           {turn off CHECK_MODES}
  rend_set.suprop_on^ (rend_suprop_emis_k, false);
  rend_set.suprop_on^ (rend_suprop_diff_k, false);
  rend_set.suprop_on^ (rend_suprop_spec_k, false);
  rend_set.suprop_on^ (rend_suprop_trans_k, false);
  rend_sw_restore_cmode (save);        {restore CHECK_MODES and run it if necessary}
  end;
