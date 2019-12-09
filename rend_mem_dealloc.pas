{   Subroutine REND_MEM_DEALLOC (ADR, SCOPE)
*
*   Deallocate a block of virtual memory that was previously allocated using
*   subroutine REND_MEM_ALLOC.  ADR must be the first address of the block.  It
*   will be returned NIL.  SCOPE indicates how globally or locally the memory was
*   allocated.  This must be set the same as when REND_MEM_ALLOC was called.
*   If scope is set to DEV, indicating that the memory belongs to the current
*   device, then the same device MUST be current as when REND_MEM_ALLOC was called.
}
module rend_mem_dealloc;
define rend_mem_dealloc;
%include 'rend2.ins.pas';

procedure rend_mem_dealloc (           {release memory allocated with REND_MEM_ALLOC}
  in out  adr: univ_ptr;               {starting adr of memory, returned NIL}
  in      scope: rend_scope_t);        {scope that memory was allocated under}
  val_param;

var
  mem_context_p: util_mem_context_p_t; {points to memory context to use}

begin
  case scope of
rend_scope_sys_k: begin                {scope is above RENDlib, just system memory}
      sys_mem_dealloc (adr);
      return;
      end;
rend_scope_rend_k: begin               {scope is at RENDlib level above devices}
      mem_context_p := rend_mem_context_p;
      end;
rend_scope_dev_k: begin                {scope is at current RENDlib device}
      if rend_dev_id <= 0 then begin
        writeln ('No current RENDlib device, and REND_MEM_DEALLOC called with DEV scope.');
        sys_bomb;
        end;
      mem_context_p := rend_device[rend_dev_id].mem_p;
      end;
otherwise
    writeln ('Illegal SCOPE value in REND_MEM_DEALLOC.');
    sys_bomb;
    end;                               {MEM_CONTEXT_P now all set}
{
*   End up here if the scope belongs to RENDlib in some way.
}
  util_mem_ungrab (adr, mem_context_p^); {release memory}
  end;
