{   Subroutine REND_MEM_ALLOC (SIZE, SCOPE, IND, ADR)
*
*   Allocate virtual memory.  SIZE is the amount of memory needed in machine address
*   units.  SCOPE indicates whether the memory is to be tied to the top level
*   RENDlib layer or the current device.  The former is automatically deallocated
*   when REND_END is called, the latter when REND_SET.CLOSE^ is called.
*   If IND is set to TRUE, then this new memory block can be individually deallocated.
*   Otherwise, it can only be deallocated as described above.  ADR is returned as
*   the starting address of the block.
}
module rend_mem_alloc;
define rend_mem_alloc;
%include 'rend2.ins.pas';

procedure rend_mem_alloc (             {get memory under specific memory context}
  in      size: sys_int_adr_t;         {size of region to allocate}
  in      scope: rend_scope_t;         {scope of new region, use REND_SCOPE_xxx_K}
  in      ind: boolean;                {TRUE if need to individually deallocate mem}
  out     adr: univ_ptr);              {start adr of region, NIL for unavailable}
  val_param;

var
  mem_context_p: util_mem_context_p_t; {points to memory context to use}

begin
  case scope of
rend_scope_sys_k: begin                {scope is above RENDlib, just grab sys mem}
      sys_mem_alloc (size, adr);
      return;
      end;
rend_scope_rend_k: begin               {scope is at RENDlib level above devices}
      mem_context_p := rend_mem_context_p;
      end;
rend_scope_dev_k: begin                {scope is at current RENDlib device}
      if rend_dev_id <= 0 then begin
        writeln ('No current RENDlib device, and REND_MEM_ALLOC called with DEV scope.');
        sys_bomb;
        end;
      mem_context_p := rend_device[rend_dev_id].mem_p;
      end;
otherwise
    writeln ('Illegal SCOPE value in REND_MEM_ALLOC.');
    sys_bomb;
    end;                               {MEM_CONTEXT_P now all set}
{
*   End up here if the scope belongs to RENDlib in some way.
}
  util_mem_grab (size, mem_context_p^, ind, adr); {allocate the memory}
  end;
