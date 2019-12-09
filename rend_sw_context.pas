{   Subroutine REND_SW_CONTEXT (HANDLE)
*
*   Set the current RENDlib state to that in context save area indicated by HANDLE.
*   The context must have been previously saved in the the save area by a call to
*   REND_GET.CONTEXT^.
}
module rend_sw_context;
define rend_sw_context;
%include 'rend_sw2.ins.pas';

procedure rend_sw_context (            {restore context from context block}
  in      handle: rend_context_handle_t); {handle of context block to read from}
  val_param;

var
  old_enter_level: sys_int_machine_t;  {ENTER_LEVEL before restore context}
  c_p: rend_context_p_t;               {pointer to context save area}

begin
  rend_get.enter_level^ (old_enter_level); {find existing ENTER_REND level}

  c_p := handle;                       {get pointer to save area}
  if c_p^.dev <> rend_dev_id then begin {swapping to a different device ?}
    rend_dev_save;                     {save away state for current device}
    end;
  rend_set.enter_level^ (0);           {definately get out of graphics mode}
  rend_context_to_state (c_p^);        {swap in new state}
  rend_set.dev_restore^;               {restore device state from new RENDlib state}

  rend_set.enter_level^ (old_enter_level); {back to original ENTER_REND level}
  end;
