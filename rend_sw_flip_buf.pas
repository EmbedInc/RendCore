{   Subroutine REND_SW_FLIP_BUF
*
*   Flip the buffers if double buffering is appropriately enabled.  A
*   CLEAR_CWIND is performed on the new drawing buffer.  This routine will
*   have the net effect of only the clear if single buffering.
}
module rend_sw_flip_buf;
define rend_sw_flip_buf;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_flip_buf_d.ins.pas';

procedure rend_sw_flip_buf;

var
  i: sys_int_machine_t;                {scratch buffer number}

begin
  i := rend_curr_draw_buf;
  rend_set.disp_buf^ (i);              {old drawing buffer becomes new display buf}
  if rend_curr_disp_buf = 1            {chose new drawing buffer}
    then i := 2
    else i := 1;
  rend_set.draw_buf^ (i);              {try to set new drawing buffer}
  rend_prim.clear_cwind^;              {clear new drawing buffer to background}
  end;
