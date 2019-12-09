{   Subroutine REND_SW_GET_CONTEXT (HANDLE)
*
*   Save the current context of all the rendering library state in the storage area
*   indicated by HANDLE.  This MUST be the same handle originally created by
*   SET.ALLOCATE_CONTEXT^.  The same device must be current as when
*   SET.ALLOCATE_CONTEXT^ was called.
}
module rend_sw_get_context;
define rend_sw_get_context;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_context (        {save current context into context block}
  in      handle: rend_context_handle_t); {handle of context block to write to}
  val_param;

var
  old_enter_level: integer32;          {user's ENTER_REND level}
  c_p: rend_context_p_t;               {pointer to save area}

begin
  c_p := handle;                       {get pointer to save area}
  if c_p^.dev <> rend_dev_id then begin
    writeln ('Context handle not for this device.  (REND_SW_GET_CONTEXT).');
    sys_bomb;
    end;
  rend_get.enter_level^ (old_enter_level); {save user's ENTER_REND level}
  rend_set.enter_level^ (0);           {make sure we leave graphics mode}
  rend_state_to_context (c_p^);        {save curr state in user save area}
  rend_set.enter_level^ (old_enter_level); {restore to user's ENTER_REND level}
  end;
