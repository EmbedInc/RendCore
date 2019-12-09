{   Subroutine REND_SW_RUN_CONFIG (PXSIZE, RUNLEN_OFS)
*
*   Configure the format for future run length data.  PXSIZE is the machine address
*   offset from the start of one run to the start of the next.  RUNLEN_OFS is
*   the offset of the run length byte within the run descriptor.  Run length bytes
*   hold the number of pixels in the run - 1.  Therefore, a value of 0 indicates
*   one pixel, and a value of 255 indicates 256 pixels.
}
module rend_sw_run_config;
define rend_sw_run_config;
%include 'rend_sw2.ins.pas';

procedure rend_sw_run_config (         {configure run length pixel data format}
  in      pxsize: sys_int_adr_t;       {machine adr offset from one run to next}
  in      runlen_ofs: sys_int_adr_t);  {machine address into pixel start for runlen}
  val_param;

begin
  if                                   {no state is getting changed ?}
      (rend_run.pxsize = pxsize) and
      (rend_run.len_ofs = runlen_ofs)
    then return;

  rend_run.pxsize := pxsize;           {save "pixel" size}
  rend_run.len_ofs := runlen_ofs;      {save offset for finding length byte}
  rend_internal.check_modes^;
  end;
