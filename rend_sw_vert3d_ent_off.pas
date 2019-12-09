{   Subroutine REND_SW_VERT3D_ENT_OFF (ENT_TYPE)
*
*   Turn off an entry type for 3D vertex descriptors.  The entry type IDs have
*   names of the form REND_VERT3D_xxx_K.  When an entry type is turned off, it
*   does not exist, and needs to have no space allocated for it in the vertex
*   descriptor.  This is also used to tell RENDlib globally that the associated
*   feature is not used.  These features can still be disabled selectively be
*   setting the pointer values to NIL.
}
module rend_sw_vert3d_ent_off;
define rend_sw_vert3d_ent_off;
%include 'rend_sw2.ins.pas';

procedure rend_sw_vert3d_ent_off (     {turn off an entry type in vertex descriptor}
  in      ent_type: rend_vert3d_ent_vals_t); {ID of entry type to turn OFF}
  val_param;

var
  ind_p: sys_int_machine_p_t;          {address of this entry type array index}

begin
  rend_vert3d_always[ent_type] := false; {disable the ALWAYS ON flag}

  rend_vert3d_ind_adr (ent_type, ind_p); {get address of this entry type array index}
  if ind_p^ < 0 then return;           {already off, nothing to do ?}
  ind_p^ := -1;                        {turn off this entry type}
  rend_config_vert3d;                  {re-compute total 3D vertex size}
  rend_internal.check_modes^;          {we now have a new configuration}
  end;
