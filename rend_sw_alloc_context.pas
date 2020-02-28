{   Subroutine REND_SW_ALLOC_CONTEXT (HANDLE)
*
*   Allocate and initialize a user handle to a complete save area for the current
*   device.  This save area can then be used to save/restore the current device
*   state.  The memory for this save area will be automatically released when the
*   device is closed.
}
module rend_sw_alloc_context;
define rend_sw_alloc_context;
%include 'rend_sw2.ins.pas';

procedure rend_sw_alloc_context (      {allocate mem for context and return handle}
  out     handle: rend_context_handle_t); {handle to this new context block}

var
  total_size: sys_int_adr_t;           {total bytes in context save area}
  i: sys_int_machine_t;                {loop counter}
  info_p: rend_context_p_t;            {pointer to newly allocated save area}

begin
  total_size :=                        {init to size of header area}
    sizeof(rend_context_t) +           {size of static header + one block descriptor}
    (rend_save_blocks - 1) * sizeof(rend_context_block_t); {remaining block desc}
  for i := 1 to rend_save_blocks do begin {once for each block to save}
    total_size := total_size +         {add size of this block in 4 byte multiples}
      sizeof(sys_int_machine_t)*((rend_save_block[i].len+sizeof(sys_int_machine_t)-1)
      div sizeof(sys_int_machine_t));
    end;

  rend_mem_alloc (                     {allocate memory for save area}
    total_size,                        {size of block to get}
    rend_scope_dev_k,                  {memory belongs to this device}
    true,                              {need to be able to individually release mem}
    info_p);                           {returned start address of new save area}
  if info_p = nil then begin
    writeln ('Unable to allocate dynamic memory in routine REND_SW_ALLOC_CONTEXT.');
    writeln ('Probably insufficient disk space.');
    sys_bomb;
    end;

  info_p^.dev := rend_dev_id;          {save which device this belongs to}
  info_p^.n_blocks := rend_save_blocks; {copy static data into save area}
  for i := 1 to rend_save_blocks do begin {copy data for each save block}
    info_p^.block[i].start_adr := rend_save_block[i].start_adr;
    info_p^.block[i].len := (rend_save_block[i].len + sizeof(sys_int_machine_t)-1)
      div sizeof(sys_int_machine_t);   {make number of whole 32 bit words}
    end;
  handle := info_p;                    {pass back user handle to new save area}
  end;
