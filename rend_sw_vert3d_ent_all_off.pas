{   Subroutine REND_SW_VERT3D_ENT_ALL_OFF
*
*   Turn off all 3D vertex descriptor entries.
*
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*   ::        CONFIDENTIAL AND PROPRIETARY INFORMATION OF        ::
*   ::                    COGNIVISION, INC.                      ::
*   ::           PROTECTED BY THE COPYRIGHT LAW AS AN            ::
*   ::                    UNPUBLISHED WORK                       ::
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}
module rend_sw_vert3d_ent_all_off;
define rend_sw_vert3d_ent_all_off;
%include 'rend_sw2.ins.pas';

procedure rend_sw_vert3d_ent_all_off;

var
  ent_type: rend_vert3d_ent_vals_t;    {ID for one 3D vertex entry type}
  save: univ_ptr;                      {save area}

begin
  rend_sw_save_cmode (save);           {turn off CHECK_MODES}
  for ent_type := firstof(rend_vert3d_ent_vals_t) to lastof(rend_vert3d_ent_vals_t)
      do begin
    rend_set.vert3d_ent_off^ (ent_type);
    end;
  rend_sw_restore_cmode (save);        {restore CHECK_MODES and run if necessary}
  end;
