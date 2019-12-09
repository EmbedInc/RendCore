{   Subroutine REND_CONFIG_VERT3D
*
*   Calculate the REND_VERT3D_BYTES value.  This value indicates how many bytes
*   need to be allocated to hold a user's vertex descriptor from the start to
*   the end of the last used field.
*
*   Keep REND_VERT3D_ON_LIST array up to date.  Array entries from 0 to
*   REND_VERT3D_LAST_LIST_ENT contain the index value for each currently enabled
*   field in a 3D vertex descriptor.
*
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*   ::        CONFIDENTIAL AND PROPRIETARY INFORMATION OF        ::
*   ::                    COGNIVISION, INC.                      ::
*   ::           PROTECTED BY THE COPYRIGHT LAW AS AN            ::
*   ::                    UNPUBLISHED WORK                       ::
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}
module rend_config_vert3d;
define rend_config_vert3d;
%include 'rend2.ins.pas';

procedure rend_config_vert3d;

var
  max_ind: sys_int_machine_t;          {max entry type index value found}
  entry_type: rend_vert3d_ent_vals_t;  {ID for current 3D vertex entry type}
  ind_p: sys_int_machine_p_t;          {pointer to entry type index value}

begin
  rend_vert3d_last_list_ent := -1;     {init to no VERT3D fields enabled}
  max_ind := -1;                       {init to value that would cause 0 bytes}

  for entry_type := firstof(rend_vert3d_ent_vals_t) to lastof(rend_vert3d_ent_vals_t)
      do begin
    rend_vert3d_ind_adr (entry_type, ind_p); {get pointer to this entry type index}
    if ind_p^ >= 0 then begin          {this vert3d field enabled ?}
      max_ind := max(max_ind, ind_p^); {accumulate max index value}
      rend_vert3d_last_list_ent :=     {one more enabled field}
        rend_vert3d_last_list_ent + 1;
      rend_vert3d_on_list[rend_vert3d_last_list_ent] := ind_p^; {save index}
      end;                             {done handling enabled vert3d field}
    end;                               {back and do next index value}

  rend_vert3d_bytes :=                 {set bytes needed for 3D vertex descriptor}
    (max_ind + 1) * sizeof(rend_vert3d_t);
  end;
