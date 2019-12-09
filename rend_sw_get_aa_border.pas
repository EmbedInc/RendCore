{   Subroutine REND_SW_GET_AA_BORDER (XP,YP)
*
*   Return the size of the border needed around an image if it is to be anti-aliased
*   later.  XP is the number of extra pixels needed on the left and right, and
*   YP is the number of extra pixels needed at the top and bottom.  These values
*   may change when REND_SET.AA_SCALE is called.
}
module rend_sw_get_aa_border;
define rend_sw_get_aa_border;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_aa_border (      {return border needed for curr AA filter}
  out     xp, yp: sys_int_machine_t);  {pixels border needed for each dimension}

begin
  xp := rend_aa.start_xofs;
  yp := rend_aa.start_yofs;
  end;
