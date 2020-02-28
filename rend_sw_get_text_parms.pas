{   Subroutine REND_SW_GET_TEXT_PARMS (PARMS)
*
*   Return the current values of the modes and switches that directly effect the
*   TEXT primitive.
}
module rend_sw_get_text_parms;
define rend_sw_get_text_parms;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_text_parms (
  out     parms: rend_text_parms_t);   {new values for the modes and switches}

begin
  parms := rend_text_parms;            {return the whole data structure}
  end;
