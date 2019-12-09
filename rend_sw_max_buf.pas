{   Subroutine REND_SW_MAX_BUF (N)
*
*   Set the maximum buffer number for the display and drawing buffers.  This is used
*   to turn the double buffering capability on/off.  The software device is only
*   single buffered.
}
module rend_sw_max_buf;
define rend_sw_max_buf;
%include 'rend_sw2.ins.pas';

procedure rend_sw_max_buf (            {set max number of desired display/draw bufs}
  in      n: sys_int_machine_t);       {max desired buf num, first buffer is 1}
  val_param;

var
  ln: sys_int_machine_t;               {local copy of N}

begin
  rend_cmode[rend_cmode_maxbuf_k] := false; {reset mode to not changed}
  ln := n;                             {init local copy of N}
  if ln < 1 then ln := 1;              {clip at lower limit}
  if rend_max_buf = ln then return;    {nothing to do ?}
  rend_max_buf := ln;                  {set new max buffers limit}
{
*   SW device only supports one buffer.
}
  if rend_max_buf > 1 then begin       {needs to be changed ?}
    rend_max_buf := 1;                 {change the mode}
    rend_cmode[rend_cmode_maxbuf_k] := true; {indicate mode got changed}
    end;

  rend_internal.check_modes^;
  end;
