{   Subroutine REND_SW_VERT3D_ENT_ON_ALWAYS (ENT_TYPE)
*
*   Indicate that the vertex entry ENT_TYPE will always be used.  This means
*   it will never be set to a NIL pointer.  This particular vertex entry
*   must already be enabled.
}
module rend_sw_vert3d_ent_on_always;
define rend_sw_vert3d_ent_on_always;
%include 'rend_sw2.ins.pas';

procedure rend_sw_vert3d_ent_on_always ( {promise vertex entry will always be used}
  in      ent_type: rend_vert3d_ent_vals_t); {ID of entry that will always be used}
  val_param;

const
  max_msg_parms = 1;                   {max parameters we can pass to a message}

var
  ind_p: sys_int_machine_p_t;          {address of this entry type array index}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;

begin
  rend_vert3d_ind_adr (ent_type, ind_p); {get pointer to array index for this ent}
  if ind_p^ < 0 then begin             {this entry is OFF ?}
    sys_msg_parm_int (msg_parm[1], ord(ent_type));
    rend_message_bomb ('rend', 'rend_ent_off_always', msg_parm, 1);
    end;

  if rend_vert3d_always[ent_type] then return; {nothing to do ?}
  rend_vert3d_always[ent_type] := true;
  rend_internal.check_modes^;
  end;
