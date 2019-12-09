{   Subroutine REND_SW_SPAN_CONFIG (PXSIZE)
*
*   Configure the format for future span data.  PXSIZE is the machine address
*   offset from the start of one pixel to the start of the next.
}
module rend_sw_span_config;
define rend_sw_span_config;
%include 'rend_sw2.ins.pas';

procedure rend_sw_span_config (        {configure SPAN primitives data format}
  in      pxsize: sys_int_adr_t);      {machine adr offset from one pixel to next}
  val_param;

begin
  if rend_span.pxsize = pxsize         {no state is getting changed ?}
    then return;

  rend_span.pxsize := pxsize;          {save pixel size}
  rend_internal.check_modes^;
  end;
