{   Subroutine REND_SW_DEL_LIGHT (H)
*
*   Delete the light source indicated by the light source handle H.  This handle
*   originally came from REND_SET.CREATE_LIGHT.  When a light source is deleted,
*   it is completely removed from user visibility, although its memory is not
*   deallocated.  The memory is re-used if when a new light source is created.
*   All light sources memory is deallocated when the RENDlib device they belong
*   to is closed.
}
module rend_sw_del_light;
define rend_sw_del_light;
%include 'rend_sw2.ins.pas';

procedure rend_sw_del_light (          {delete a light source}
  in out  h: rend_light_handle_t);     {handle to light source, returned invalid}

begin
  rend_set.light_on^ (h, false);       {ensure that light source is OFF}

  h^.prev_pp^ := h^.next_p;            {remove light source from USED chain}
  if h^.next_p <> nil then begin
    h^.next_p^.prev_pp := h^.prev_pp;
    end;
  h^.used := false;                    {flag light source descriptor as unused}

  h^.next_p := rend_lights.free_p;     {put descriptor onto unused chain}
  if h^.next_p <> nil then begin
    h^.next_p^.prev_pp := addr(h^.next_p);
    end;
  h^.prev_pp := addr(rend_lights.free_p);
  rend_lights.free_p := h;

  rend_lights.n_used := rend_lights.n_used - 1; {one less USED light source}
  h := nil;                            {return user light source handle as invalid}
  end;
