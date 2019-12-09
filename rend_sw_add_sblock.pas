{   Subroutine REND_SW_ADD_SBLOCK (START_ADR,LEN)
*
*   Add another memory block to the list of blocks that will be saved/restored
*   during a context swap.  The block must start on a 32 bit boundary, which
*   means that START_ADR must be a multiple of 4.  LEN is the length of the block
*   to save in bytes.  The actual saved/restored length will be rounded up to the
*   nearest multiple of 4 bytes.
}
module rend_sw_add_sblock;
define rend_sw_add_sblock;
%include 'rend_sw2.ins.pas';

procedure rend_sw_add_sblock (         {add block to saved/restored block list}
  in      start_adr: univ_ptr;         {starting adr, must be multiple of 4}
  in      len: sys_int_adr_t);         {block length in machine adr units}
  val_param;

const
  align_mask_k = sizeof(sys_int_machine_t) - 1; {used for block alignment}

begin
  if rend_save_blocks >= rend_max_save_blocks then begin
    rend_message_bomb ('rend', 'rend_save_blocks_too_many', nil, 0);
    end;
  if (sys_int_adr_t(start_adr) & align_mask_k) <> 0 then begin
    rend_message_bomb ('rend', 'rend_save_block_not_aligned', nil, 0);
    end;
  rend_save_blocks := rend_save_blocks + 1; {one more block}
  rend_save_block[rend_save_blocks].start_adr :=
    start_adr;                         {set block start address}
  rend_save_block[rend_save_blocks].len :=
    (len + align_mask_k) & (~align_mask_k); {set rounded up block length}
  end;
