{   Subroutine REND_SW_VERT3D_ENT_ON (ENT_TYPE, OFFSET)
*
*   Turn on an entry type for all subsequently used 3D vertex descriptors.
*   ENT_TYPE is the entry type ID, and must be one of the constants of name
*   REND_VERT3D_xxx_K.  OFFSET is the address offset from the start of each
*   3D vertex descriptor (data type REND_VERT3D_T) to this entry type.  This
*   must be a multiple of the system address size.
}
module rend_sw_vert3d_ent_on;
define rend_sw_vert3d_ent_on;
%include 'rend_sw2.ins.pas';

procedure rend_sw_vert3d_ent_on (      {turn on an entry type in vertex descriptor}
  in      ent_type: rend_vert3d_ent_vals_t; {ID of entry type to turn ON}
  in      offset: sys_int_adr_t);      {adr offset for this ent from vert desc start}
  val_param;

const
  max_offset_k = 4096 - sizeof(univ_ptr); {max allowed OFFSET}
  max_msg_parms = 1;                   {max parameters we can pass to a message}
  align_mult = sizeof(univ_ptr);
  align_mask = align_mult - 1;

var
  ind: sys_int_machine_t;              {array index for OFFSET}
  ind_p: sys_int_machine_p_t;          {address of this entry type array index}
  was_on: boolean;                     {TRUE if entry was already ON}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;

begin
  if
      ((offset & align_mask) <> 0) or  {BYTE_OFFSET not properly aligned ?}
      (offset > max_offset_k)          {offset too large to be valid ?}
      then begin
    sys_msg_parm_int (msg_parm[1], offset);
    rend_message_bomb ('rend', 'rend_vert_ent_offset_mod_bad', msg_parm, 1);
    end;
{
*   BYTE_OFFSET has been validated.
}
  ind := offset div align_mult;        {make array index for this entry type}
  rend_vert3d_ind_adr (ent_type, ind_p); {get pointer to this entry type array index}
  if ind_p^ = ind then return;         {already set this way, nothing to do ?}
  was_on := ind_p^ >= 0;               {TRUE if this entry type already ON}
  ind_p^ := ind;                       {set to new value}
  rend_config_vert3d;                  {find new size of 3D vertex descriptor}
  if not was_on then begin             {entry type was just now switched ON ?}
    rend_internal.check_modes^;        {update to new vertex configuration}
    end;
  end;
