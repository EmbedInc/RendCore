{   Subroutine REND_STATE_TO_CONTEXT (CONTEXT)
*
*   Copy the current state to the context block CONTEXT.  No other operations are
*   performed other than a pure copy.
}
module rend_state_to_context;
define rend_state_to_context;
%include 'rend2.ins.pas';

procedure rend_state_to_context (      {copy current state to context block}
  in out  context: rend_context_t);    {context block to copy into}

var
  c_p: sys_int_machine_p_t;            {pointer to next word in context block}
  i: sys_int_machine_t;                {loop counter}
{
**************************************************************************************
*
*   Local subroutine SAVE_CONTEXT (START_P, LEN)
*
*   Save the block of memory starting at address START_P and extending for LEN
*   32 bit words into the current location in the context block.  The current location
*   is pointed to by C_P, which is updated.
}
procedure save_context (
  in      start_p: univ_ptr;           {start address of area to save}
  in      len: sys_int_adr_t);         {number of 32 bit words to save}

var
  i: sys_int_machine_t;                {loop counter}
  p: sys_int_machine_p_t;              {current read pointer}

begin
  p := start_p;                        {init read pointer}
  for i := 1 to len do begin           {once for each 32 bit word to save}
    c_p^ := p^;                        {copy this one 32 bit word}
    p := univ_ptr(sys_int_adr_t(p) + sizeof(p^)); {advance read pointer}
    c_p := univ_ptr(sys_int_adr_t(c_p) + sizeof(c_p^)); {advance write pointer}
    end;
  end;
{
**************************************************************************************
*
*   Body of main routine.
}
begin
  c_p := univ_ptr(                     {make adr of first data word in context block}
    sys_int_adr_t(addr(context.block[1])) +
    (context.n_blocks * sizeof(context.block[1])));
  for i := 1 to context.n_blocks do begin {once for each mem block to save}
    save_context (context.block[i].start_adr, context.block[i].len);
    end;
  end;
