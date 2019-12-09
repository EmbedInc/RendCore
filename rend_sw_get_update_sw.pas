{   Subroutine REND_SW_GET_UPDATE_SW (ON)
*
*   Return TRUE if at least one primitive will write into the software bitmap under
*   the current conditions.
}
module rend_sw_get_update_sw;
define rend_sw_get_update_sw;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_update_sw (      {return current state of UPDATE_SW flag}
  out     on: boolean);                {TRUE if software updates are on}

var
  sw_read, sw_write: rend_access_k_t;  {SW bitmap access flags}

begin
  rend_get_all_prim_access (sw_read, sw_write);
  on := (sw_write = rend_access_yes_k);
  end;
