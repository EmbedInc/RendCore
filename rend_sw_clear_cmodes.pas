{   Subroutine REND_SW_CLEAR_CMODES
*
*   Clear the changed flag for each automatially changeable mode.  The change flags
*   otherwise just accumulate.
}
module rend_sw_clear_cmodes;
define rend_sw_clear_cmodes;
%include 'rend_sw2.ins.pas';

procedure rend_sw_clear_cmodes;

var
  cmode: rend_cmode_k_t;               {loop counter}

begin
  for cmode := firstof(cmode) to lastof(cmode) do begin {once for each changeable mode}
    rend_cmode[cmode] := false;        {reset to this mode not changed}
    end;
  end;
