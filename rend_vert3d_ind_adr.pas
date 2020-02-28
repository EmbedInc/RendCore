{   Subroutine REND_VERT3D_IND_ADR (ENTRY_TYPE,IND_P)
*
*   Return a pointer to the 3D vertex index value of a particular entry type.
*   The pointer will point to one of the common block variables of name
*   REND_xxx_IND.
}
module rend_vert3d_ind_adr;
define rend_vert3d_ind_adr;
%include 'rend2.ins.pas';

procedure rend_vert3d_ind_adr (        {get adr of 3D vertex entry index}
  in      entry_type: rend_vert3d_ent_vals_t; {ID for particular entry type}
  out     ind_p: sys_int_machine_p_t); {pointer to 3D vertex index value}

begin
  case entry_type of
rend_vert3d_coor_p_k: ind_p := addr(rend_coor_p_ind);
rend_vert3d_norm_p_k: ind_p := addr(rend_norm_p_ind);
rend_vert3d_diff_p_k: ind_p := addr(rend_diff_p_ind);
rend_vert3d_tmapi_p_k: ind_p := addr(rend_tmapi_p_ind);
rend_vert3d_vcache_p_k: ind_p := addr(rend_vcache_p_ind);
rend_vert3d_ncache_p_k: ind_p := addr(rend_ncache_p_ind);
rend_vert3d_spokes_p_k: ind_p := addr(rend_spokes_p_ind);
otherwise
    writeln ('Bad ENTRY_TYPE value in REND_VERT3D_IND_ADR.');
    sys_bomb;
    end;
  end;
