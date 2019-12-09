{   Subroutine REND_SW_ITERP_SRC_BITMAP (ITERP,BITMAP_HANDLE,ITERP_OFFSET)
*
*   Declare the source bitmap for this interpolant, and the address offset of where
*   the data for this interpolant lives within each pixel in that bitmap.
*   The source bitmap is used, for example, when anti-aliasing.
}
module rend_sw_iterp_src_bitmap;
define rend_sw_iterp_src_bitmap;
%include 'rend_sw2.ins.pas';

procedure rend_sw_iterp_src_bitmap (   {declare source mode BITMAP and set bitmap}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      bitmap_handle: rend_bitmap_handle_t; {handle for source bitmap}
  in      iterp_offset: sys_int_adr_t); {adr offset into pixel for this interpolant}
  val_param;

begin
  rend_iterps.iterp[iterp].bitmap_src_p := bitmap_handle;
  rend_iterps.iterp[iterp].src_offset := iterp_offset;
  end;
