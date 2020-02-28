{   Subroutine REND_SW_DEL_ALL_LIGHTS
*
*   Deleate all light sources.  All existing light source handles must be
*   considered invalid after this call.
}
module rend_sw_del_all_lights;
define rend_sw_del_all_lights;
%include 'rend_sw2.ins.pas';

procedure rend_sw_del_all_lights;

var
  cm_save: univ_ptr;                   {save area for CHECK_MODES state}
  h: rend_light_handle_t;              {handle for current light source to delete}

begin
  rend_sw_save_cmode (cm_save);        {turn off CHECK_MODES}

  while rend_lights.used_p <> nil do begin {keep looping until all lights gone}
    h := rend_lights.used_p;           {make handle to this light source}
    rend_set.del_light^ (h);           {delete this light source}
    end;

  if rend_lights.n_used <> 0 then begin
    writeln ('All lights deleted, but N_USED counter not zero.');
    end;

  if rend_lights.n_on <> 0 then begin
    writeln ('All lights deleted, but N_ON counter not zero.');
    end;

  rend_sw_restore_cmode (cm_save);     {restore CHECK_MODES and run if needed}
  end;
