{   Subroutine REND_SW_DEALLOCATE_BITMAP (HANDLE)
*
*   Deallocate the pixel memory of the given bitmap.  The pixel memory MUST have been
*   allocated using subroutine REND_SW_ALLOC_BITMAP.  The bitmap handle is returned
*   valid, but there will no longer be any pixels associated with the bitmap.
}
module rend_sw_dealloc_bitmap;
define rend_sw_dealloc_bitmap;
%include 'rend_sw2.ins.pas';

procedure rend_sw_dealloc_bitmap (     {release memory allocated with ALLOC_BITMAP}
  in      h: rend_bitmap_handle_t);    {handle to bitmap, still valid but no pixels}
  val_param;

var
  b: rend_bitmap_desc_p_t;             {pointer to this bitmap descriptor}

begin
  b := h;                              {make local pointer to bitmap descriptor}
  b^.x_size := 0;                      {indicate bitmap has no pixels}
  b^.y_size := 0;
  b^.x_offset := 0;
  if b^.line_p[0] = nil then return;   {no memory allocated here ?}
  rend_mem_dealloc (b^.line_p[0], b^.scope_pixels); {release pixel memory}
  end;
