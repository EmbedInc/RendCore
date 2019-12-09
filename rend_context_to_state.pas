{   Subroutine REND_CONTEXT_TO_STATE (CONTEXT)
*
*   Copy all the state from the context block CONTEXT into the current state area.
*   No other operations are performed other than the copy.
}
module rend_context_to_state;
define rend_context_to_state;
%include 'rend2.ins.pas';

procedure rend_context_to_state (      {copy context block to current state}
  in      context: rend_context_t);    {context block to copy from}

var
  c_p: sys_int_machine_p_t;            {pointer to next word in context block}
  i: sys_int_machine_t;                {loop counter}
{
**************************************************************************************
*
*   Local subroutine REST_CONTEXT (START_P, LEN)
*
*   Restore the block of memory starting at address START_P and extending for LEN
*   32 bit words from the current location in the context block.  The current location
*   is pointed to by C_P, which is updated.
}
procedure rest_context (
  in      start_p: univ_ptr;           {start address of area to restore}
  in      len: sys_int_adr_t);         {number of words to restore}

var
  i: sys_int_machine_t;                {loop counter}
  p: sys_int_machine_p_t;              {current write pointer}

begin
  p := start_p;                        {init write pointer}
  for i := 1 to len do begin           {once for each 32 bit word to save}
    p^ := c_p^;                        {copy this one 32 bit word}
    p := univ_ptr(sys_int_adr_t(p) + sizeof(p^)); {advance write pointer}
    c_p := univ_ptr(sys_int_adr_t(c_p) + sizeof(c_p^)); {advance read pointer}
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
  for i := 1 to context.n_blocks do begin {once for each mem block in context}
    rest_context (context.block[i].start_adr, context.block[i].len);
    end;
  end;
