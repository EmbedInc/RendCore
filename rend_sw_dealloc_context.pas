{   Subroutine REND_SW_DEALLOC_CONTEXT (HANDLE)
*
*   Deallocate the dynamic memory allocated for the context block indicated by
*   HANDLE.  This must be the same handle originally created by
*   REND_SET.ALLOC_CONTEXT.
}
module rend_sw_dealloc_context;
define rend_sw_dealloc_context;
%include 'rend_sw2.ins.pas';

procedure rend_sw_dealloc_context (    {release memory for context block}
  in out  handle: rend_context_handle_t); {returned invalid}

begin
  util_mem_ungrab (                    {release memory for save area}
    handle,                            {starting address of area to release}
    rend_device[handle^.dev].mem_p^);  {parent memory context descriptor}
  end;
