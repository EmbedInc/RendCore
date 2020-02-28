{   Subroutine REND_SW_GET_VECT_PARMS (PARMS)
*
*   Return the current values of the modes and switches that directly effect the
*   VECT primitive.
}
module rend_sw_get_vect_parms;
define rend_sw_get_vect_parms;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_vect_parms (
  out     parms: rend_vect_parms_t);   {new values for the modes and switches}

begin
  parms := rend_vect_parms;            {return the whole data structure}
  end;
