{   Subroutine REND_SW_LIGHT_ON (H, ON)
*
*   Turn a light source on/off.  H is the handle to the light source.  This will
*   not effect the lights source settings, only whether the light source will
*   be taken into account when colors are computed from the lighting and surface
*   properties states.
}
module rend_sw_light_on;
define rend_sw_light_on;
%include 'rend_sw2.ins.pas';

procedure rend_sw_light_on (           {turn light source on/off}
  in      h: rend_light_handle_t;      {handle to light source}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param;

var
  l_p: rend_light_p_t;                 {scratch light source pointer}

label
  light_exists;

begin
  if (h = nil) or else (h^.used = false) then begin
    rend_message_bomb ('rend', 'rend_light_handle_bad', nil, 0);
    end;

  l_p := rend_lights.used_p;           {init to first existing light source}
  while l_p <> nil do begin            {loop thru all the light sources}
    if h = l_p then goto light_exists; {yup, this is a real light source handle}
    l_p := l_p^.next_p;                {advance to next light source}
    end;                               {back to do next existing light source}
  rend_message_bomb ('rend', 'rend_light_not_exist', nil, 0);
light_exists:                          {this light exists for this device}

  if h^.on = on then return;           {nothing to do here ?}
  h^.on := on;                         {set light source new ON/OFF state}

  case h^.on of
{
*   Light source is being turned ON.
}
true: begin
      h^.prev_on_pp := addr(rend_lights.on_p); {add this light source to ON chain}
      h^.next_on_p := rend_lights.on_p;
      if h^.next_on_p <> nil then begin
        h^.next_on_p^.prev_on_pp := addr(h^.next_on_p);
        end;
      rend_lights.on_p := h;
      rend_lights.n_on := rend_lights.n_on + 1; {one more ON light source}
      end;
{
*   Light source is being turned OFF.
}
false: begin                           {light source is being turned OFF}
      h^.prev_on_pp^ := h^.next_on_p;
      if h^.next_on_p <> nil then begin
        h^.next_on_p^.prev_on_pp := h^.prev_on_pp;
        end;
      rend_lights.n_on := rend_lights.n_on - 1; {one less ON light source}
      end;
    end;                               {done with turning light ON/OFF cases}

  rend_lights.changed := true;         {indicate lighting state changed}
  rend_internal.check_modes^;          {notify driver of lighting environment change}
  end;
