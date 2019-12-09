{   Subroutine REND_SW_TEXT_POS_ORG
*
*   Move the TEXT space origin to the TXDRAW space current point.
}
module rend_sw_text_pos_org;
define rend_sw_text_pos_org;
%include 'rend_sw2.ins.pas';

procedure rend_sw_text_pos_org;        {move TEXT origin to TXDRAW current point}

begin
  rend_get.cpnt_txdraw^ (
    rend_text_state.sp.ofs.x,
    rend_text_state.sp.ofs.y);
  end;
