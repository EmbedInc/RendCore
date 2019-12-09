{   Subroutine REND_SW_ENTER_REND
*
*   Enter graphics mode.  This routine will wait, if necessary, until the
*   appropriate system resources have been acquired.
}
module rend_sw_enter_rend;
define rend_sw_enter_rend;
%include 'rend_sw2.ins.pas';

const
  retry_wait = 0.50;                   {seconds to wait for retry ENTER_REND_COND}

procedure rend_sw_enter_rend;

var
  entered: boolean;                    {TRUE if ENTER_REND_COND successful}

label
  retry;

begin
retry:                                 {back here to retry ENTER_REND}
  rend_set.enter_rend_cond^ (entered);
  if entered then return;              {successfully performed ENTER_REND}
  sys_wait (retry_wait);               {wait a little time}
  goto retry;                          {back and try again}
  end;
