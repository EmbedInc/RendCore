{   Subroutine REND_SW_DEALLOC_BITMAP_HANDLE (HANDLE)
*
*   Delete the bitmap handle HANDLE.  This does not deallocate any of the pixel
*   memory.
}
module rend_sw_dealloc_bitmap_handle;
define rend_sw_dealloc_bitmap_handle;
%include 'rend_sw2.ins.pas';

procedure rend_sw_dealloc_bitmap_handle ( {deallocate memory behind a bitmap handle}
  in out  handle: rend_bitmap_handle_t); {returned invalid}

var
  b: rend_bitmap_desc_p_t;             {pointer to bitmap}

begin
  b := handle;                         {make pointer to bitmap}
  rend_mem_dealloc (b, b^.scope_handle); {release memory for bitmap handle}
  handle := nil;                       {return invalid handle}
  end;
