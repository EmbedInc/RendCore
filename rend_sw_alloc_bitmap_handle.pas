{   Subroutine REND_SW_ALLOC_BITMAP_HANDLE (SCOPE,HANDLE)
*
*   Create a new bitmap handle.  This causes storage to be allocated for an internal
*   bitmap descriptor.
}
module rend_sw_alloc_bitmap_handle;
define rend_sw_alloc_bitmap_handle;
%include 'rend_sw2.ins.pas';

procedure rend_sw_alloc_bitmap_handle ( {create a new empty bitmap handle}
  in      scope: rend_scope_t;         {memory context, use REND_SCOPE_xxx_K}
  out     handle: rend_bitmap_handle_t); {returned valid bitmap handle}
  val_param;

var
  p: rend_bitmap_desc_p_t;             {pointer to bitmap descriptor}

begin
  rend_mem_alloc (sizeof(p^), scope, true, p); {allocate memory for handle}
  sys_mem_error (p, '', '', nil, 0);   {bomb if not got requested memory}

  p^.x_size := 0;                      {init to values that would cause errors}
  p^.y_size := 0;
  p^.x_offset := 0;
  p^.scope_handle := scope;            {save memory scope of handle itself}

  handle := p;                         {pass back bitmap handle}
  end;
