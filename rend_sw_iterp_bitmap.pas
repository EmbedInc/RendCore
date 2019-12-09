{   Subroutine REND_SW_ITERP_BITMAP (ITERP,BITMAP_HANDLE,ITERP_OFFSET)
*
*   Connect an interpolant to a particular collection of bytes in a bitmap.
}
module rend_sw_iterp_bitmap;
define rend_sw_iterp_bitmap;
%include 'rend_sw2.ins.pas';

procedure rend_sw_iterp_bitmap (       {declare where this interpolant gets written}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      bitmap_handle: rend_bitmap_handle_t; {handle for bitmap to write to}
  in      iterp_offset: sys_int_adr_t); {adr offset into pixel for this interpolant}
  val_param;

var
  p: rend_bitmap_desc_p_t;             {pointer to bitmap descriptor}

begin
  p := bitmap_handle;                  {make pointer to bitmap descriptor}
  rend_iterps.iterp[iterp].bitmap_p := p; {save bitmap pointer}
  rend_iterps.iterp[iterp].iterp_offset := iterp_offset; {save offset into pixel}
  end;
