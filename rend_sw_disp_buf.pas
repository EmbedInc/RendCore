{   Subroutine REND_SW_DISP_BUF (N)
*
*   The the number of the buffer to display.  This is used in double buffering.
}
module rend_sw_disp_buf;
define rend_sw_disp_buf;
%include 'rend_sw2.ins.pas';

procedure rend_sw_disp_buf (           {set number of new current display buffer}
  in      n: sys_int_machine_t);       {buffer number, first buffer is 1}
  val_param;

var
  ln: sys_int_machine_t;               {local copy of N}

begin
  rend_cmode[rend_cmode_dispbuf_k] := false; {reset to mode not changed}
  ln := n;                             {init local copy of N}
  if ln < 1 then ln := 1;              {clip at lower limit}
  if ln = rend_curr_disp_buf then return; {nothing to do here ?}
  rend_curr_disp_buf := ln;            {set new value}

  if rend_curr_disp_buf > rend_max_buf then begin {check for buffer number too high}
    rend_curr_disp_buf := rend_max_buf;
    rend_cmode[rend_cmode_dispbuf_k] := true; {indicate mode got changed}
    end;

  rend_internal.check_modes^;
  end;
