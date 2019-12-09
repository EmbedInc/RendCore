{   Subroutine REND_SW_GET_READING_SW (READING)
*
*   Return READING as TRUE if the current pixel function modes require at least
*   one primitive to read from software copy of the bitmap.  This may be important
*   to know so that earlier drawing can be forced to write to the software bitmap.
}
module rend_sw_get_reading_sw;
define rend_sw_get_reading_sw;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_reading_sw (     {find out if reading SW bitmap}
  out     reading: boolean);           {TRUE if modes require reading SW bitmap}

var
  sw_read, sw_write: rend_access_k_t;  {SW bitmap access flags}

begin
  rend_get_all_prim_access (sw_read, sw_write);
  reading := (sw_read = rend_access_yes_k);
  end;
