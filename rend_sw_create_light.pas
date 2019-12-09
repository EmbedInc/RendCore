{   Subroutine REND_SW_CREATE_LIGHT (H)
*
*   Create a new light source.  H is returned as the user handle to the new light
*   source.  H must be used in all future interactions with RENDlib when referring
*   to this light source.  Dynamic memory is allocated, if necessary, for the new
*   light source.  The memory for deleted light sources is not deallocated until
*   the RENDlib device is closed, but is re-used by new light sources.
}
module rend_sw_create_light;
define rend_sw_create_light;
%include 'rend_sw2.ins.pas';

procedure rend_sw_create_light (       {create new light source and return handle}
  out     h: rend_light_handle_t);     {handle to newly created light source}

begin
  if rend_lights.free_p = nil
{
*   No previously deleted light source is available for re-use.  We need to
*   grab some more dynamic memory.
}
    then begin
      rend_mem_alloc (                 {get new memory for this light source}
        sizeof(h^),                    {amount of memory needed}
        rend_scope_dev_k,              {memory belong to device}
        false,                         {we don't need to individually deallocate this}
        h);                            {returned address of new light source}
      if h = nil then begin
        writeln ('Unable to allocate dynamic memory in REND_SW_CREATE_LIGHT.');
        writeln ('The disk is probably full.');
        sys_bomb;
        end;
      rend_lights.n_alloc := rend_lights.n_alloc + 1; {one more light allocated}
      end
{
*   We will re-use a previously deleted light source for the new light source.
}
    else begin
      h := rend_lights.free_p;         {save pointer to reclaimed light descriptor}
      rend_lights.free_p := h^.next_p; {unchain light source from unused list}
      if h^.next_p <> nil then begin
        h^.next_p^.prev_pp := h^.prev_pp;
        end;
      end
    ;
{
*   H has been set to the light source handle, and is pointing to the light source
*   descriptor to use for the new light source.
}
  h^.next_p := rend_lights.used_p;     {add new light source to USED list}
  if h^.next_p <> nil then begin
    h^.next_p^.prev_pp := addr(h^.next_p);
    end;
  h^.prev_pp := addr(rend_lights.used_p);
  rend_lights.used_p := h;

  h^.next_on_p := nil;                 {init this light source to OFF}
  h^.prev_on_pp := nil;
  h^.on := false;
  h^.used := true;                     {flag this light source as existing}
  h^.ltype := rend_ltype_amb_k;        {init to harmless light source type}
  h^.amb_red := 0.0;
  h^.amb_grn := 0.0;
  h^.amb_blu := 0.0;
  rend_lights.n_used := rend_lights.n_used + 1; {one more light source in use}
  end;
