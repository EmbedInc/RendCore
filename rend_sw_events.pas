{   Module of event-related routines for the SW driver.
}
module rend_sw_events;
define rend_sw_event_req_close;
define rend_sw_event_req_resize;
define rend_sw_event_req_wiped_resize;
define rend_sw_event_req_wiped_rect;
define rend_sw_event_req_key_on;
define rend_sw_event_req_key_off;
define rend_sw_event_req_pnt;
define rend_sw_event_req_rotate_off;
define rend_sw_event_req_rotate_on;
define rend_sw_event_req_translate;
define rend_sw_events_req_off;
define rend_sw_pointer;
define rend_sw_pointer_abs;
define rend_sw_get_keys;
define rend_sw_get_key_sp;
define rend_sw_get_key_sp_def;
define rend_sw_get_pointer;
define rend_sw_get_pointer_abs;
define rend_sw_get_event_possible;
define rend_sw_get_ev_possible;
define rend_sw_event_mode_pnt;
%include 'rend_sw2.ins.pas';
{
*********************************************************
}
procedure rend_sw_event_req_close (    {request CLOSE events on/off}
  in      on: boolean);                {TRUE requests these events}
  val_param;

const
  ev = rend_evdev_close_k;             {ID for this event class}

begin
  with rend_device[rend_dev_id]: dev do begin {DEV is our device descriptor}
    if on
      then begin                       {these events are being enabled}
        if ev in dev.ev_req then return; {already enabled ?}
        dev.ev_req := dev.ev_req + [ev]; {enable these events}
        end
      else begin                       {these events are being disabled}
        if not (ev in dev.ev_req) then return; {already disabled ?}
        dev.ev_req := dev.ev_req - [ev]; {disable these events}
        end
      ;
    dev.ev_changed := true;            {event configuration changed for this dev}
    end;                               {done with DEV abbreviation}

  rend_internal.check_modes^;
  end;
{
*********************************************************
}
procedure rend_sw_event_req_resize (   {request RESIZE events on/off}
  in      on: boolean);                {TRUE requests these events}
  val_param;

const
  ev = rend_evdev_resize_k;            {ID for this event class}

begin
  with rend_device[rend_dev_id]: dev do begin {DEV is our device descriptor}
    if on
      then begin                       {these events are being enabled}
        if ev in dev.ev_req then return; {already enabled ?}
        dev.ev_req := dev.ev_req + [ev]; {enable these events}
        end
      else begin                       {these events are being disabled}
        if not (ev in dev.ev_req) then return; {already disabled ?}
        dev.ev_req := dev.ev_req - [ev]; {disable these events}
        end
      ;
    dev.ev_changed := true;            {event configuration changed for this dev}
    end;                               {done with DEV abbreviation}

  rend_internal.check_modes^;
  end;
{
*********************************************************
}
procedure rend_sw_event_req_wiped_resize ( {request WIPED_RESIZE events on/off}
  in      on: boolean);                {TRUE requests these events}
  val_param;

const
  ev = rend_evdev_wiped_resize_k;      {ID for this event class}

begin
  with rend_device[rend_dev_id]: dev do begin {DEV is our device descriptor}
    if on
      then begin                       {these events are being enabled}
        if ev in dev.ev_req then return; {already enabled ?}
        dev.ev_req := dev.ev_req + [ev]; {enable these events}
        end
      else begin                       {these events are being disabled}
        if not (ev in dev.ev_req) then return; {already disabled ?}
        dev.ev_req := dev.ev_req - [ev]; {disable these events}
        end
      ;
    dev.ev_changed := true;            {event configuration changed for this dev}
    end;                               {done with DEV abbreviation}

  rend_internal.check_modes^;
  end;
{
*********************************************************
}
procedure rend_sw_event_req_wiped_rect ( {request WIPED_RECT events on/off}
  in      on: boolean);                {TRUE requests these events}
  val_param;

const
  ev = rend_evdev_wiped_rect_k;        {ID for this event class}

begin
  with rend_device[rend_dev_id]: dev do begin {DEV is our device descriptor}
    if on
      then begin                       {these events are being enabled}
        if ev in dev.ev_req then return; {already enabled ?}
        dev.ev_req := dev.ev_req + [ev]; {enable these events}
        end
      else begin                       {these events are being disabled}
        if not (ev in dev.ev_req) then return; {already disabled ?}
        dev.ev_req := dev.ev_req - [ev]; {disable these events}
        end
      ;
    dev.ev_changed := true;            {event configuration changed for this dev}
    end;                               {done with DEV abbreviation}

  rend_internal.check_modes^;
  end;
{
*********************************************************
}
procedure rend_sw_event_req_key_on (   {request events for a particular key}
  in      id: rend_key_id_t;           {RENDlib ID of key requesting events for}
  in      id_user: sys_int_machine_t); {ID returned to user with event data}
  val_param;

const
  max_msg_parms = 2;                   {max parameters we can pass to a message}

var
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;

begin
  if id = rend_key_none_k then return; {nothing to do ?}

  with rend_device[rend_dev_id]: dev do begin {DEV is descriptor for our device}
    if (id <= 0) or (id > dev.keys_n) then begin {key ID out of range ?}
      sys_msg_parm_int (msg_parm[1], id);
      sys_msg_parm_int (msg_parm[2], dev.keys_n);
      rend_message_bomb ('rend', 'rend_key_id_bad', msg_parm, 2);
      end;

    dev.keys_p^[id].id_user := id_user; {set user ID for this key}

    if
        dev.keys_p^[id].req and        {this key already enabled ?}
        (rend_evdev_key_k in dev.ev_req) {key events already enabled ?}
      then return;                     {nothing more to do}

    if not dev.keys_p^[id].req then begin {events not already enabled for this key ?}
      dev.keys_p^[id].req := true;     {events now requested for this key}
      dev.keys_enab := dev.keys_enab + 1; {count one more key with events anabled}
      end;
    dev.ev_req := dev.ev_req + [rend_evdev_key_k]; {enable key events for this device}
    dev.ev_changed := true;            {event configuration changed for this device}

    rend_internal.check_modes^;
    end;                               {done with DEV abbreviation}
  end;
{
*********************************************************
}
procedure rend_sw_event_req_key_off (  {request no events for a particular key}
  in      id: rend_key_id_t);          {RENDlib ID of key requesting no events for}
  val_param;

const
  max_msg_parms = 2;                   {max parameters we can pass to a message}

var
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;

begin
  if id = rend_key_none_k then return; {nothing to do ?}

  with rend_device[rend_dev_id]: dev do begin {DEV is descriptor for our device}
    if (id <= 0) or (id > dev.keys_n) then begin {key ID out of range ?}
      sys_msg_parm_int (msg_parm[1], id);
      sys_msg_parm_int (msg_parm[2], dev.keys_n);
      rend_message_bomb ('rend', 'rend_key_id_bad', msg_parm, 2);
      end;

    if not dev.keys_p^[id].req         {this key already disabled ?}
      then return;                     {nothing more to do}

    dev.keys_p^[id].req := false;      {events now disabled for this key}
    dev.keys_enab := max(0, dev.keys_enab-1); {count one less key with events anabled}
    if dev.keys_enab <= 0 then begin   {no keys have events enabled anymore ?}
      dev.ev_req := dev.ev_req - [rend_evdev_key_k]; {all key events off for this dev}
      end;
    dev.ev_changed := true;            {event configuration changed for this device}

    rend_internal.check_modes^;
    end;                               {done with DEV abbreviation}
  end;
{
*********************************************************
}
procedure rend_sw_event_req_pnt (      {request pnt ENTER, EXIT, MOVE events on/off}
  in      on: boolean);                {TRUE requests these events}
  val_param;

const
  ev = rend_evdev_pnt_k;               {ID for this event class}

begin
  with rend_device[rend_dev_id]: dev do begin {DEV is our device descriptor}
    if on
      then begin                       {these events are being enabled}
        if ev in dev.ev_req then return; {already enabled ?}
        dev.ev_req := dev.ev_req + [ev]; {enable these events}
        end
      else begin                       {these events are being disabled}
        if not (ev in dev.ev_req) then return; {already disabled ?}
        dev.ev_req := dev.ev_req - [ev]; {disable these events}
        end
      ;
    dev.ev_changed := true;            {event configuration changed for this dev}
    end;                               {done with DEV abbreviation}

  rend_internal.check_modes^;
  end;
{
*********************************************************
}
procedure rend_sw_event_req_rotate_off; {disable relative 3D rotation events}

const
  ev = rend_evdev_rotate_k;            {ID for this event class}

begin
  with rend_device[rend_dev_id]: dev do begin {DEV is our device descriptor}
    if not (ev in dev.ev_req) then return; {already disabled ?}
    dev.ev_req := dev.ev_req - [ev];   {disable these events}
    dev.ev_changed := true;            {event configuration changed for this dev}
    end;                               {done with DEV abbreviation}

  rend_internal.check_modes^;
  end;
{
*********************************************************
}
procedure rend_sw_event_req_rotate_on ( {enable relative 3D rotation events}
  in      scale: real);                {scale factor, 1.0 = "normal"}
  val_param;

const
  ev = rend_evdev_rotate_k;            {ID for this event class}

begin
  with rend_device[rend_dev_id]: dev do begin {DEV is descriptor for our device}
    dev.scale_3drot := scale;          {update 3D rotations scale factor}
    if ev in dev.ev_req then return;   {events already enabled}
    dev.ev_req := dev.ev_req + [ev];   {enable these events for current device}
    dev.ev_changed := true;            {event configuration changed for this device}
    rend_internal.check_modes^;
    end;                               {done with DEV abbreviation}
  end;
{
*********************************************************
}
procedure rend_sw_event_req_translate ( {enable/disable 3D translation events}
  in      on: boolean);                {TRUE enables these events}
  val_param;

const
  ev = rend_evdev_translate_k;         {ID for this event class}

begin
  with rend_device[rend_dev_id]: dev do begin {DEV is our device descriptor}
    if on
      then begin                       {these events are being enabled}
        if ev in dev.ev_req then return; {already enabled ?}
        dev.ev_req := dev.ev_req + [ev]; {enable these events}
        end
      else begin                       {these events are being disabled}
        if not (ev in dev.ev_req) then return; {already disabled ?}
        dev.ev_req := dev.ev_req - [ev]; {disable these events}
        end
      ;
    dev.ev_changed := true;            {event configuration changed for this dev}
    end;                               {done with DEV abbreviation}

  rend_internal.check_modes^;
  end;
{
*********************************************************
}
function rend_sw_get_event_possible (  {find whether event might ever occurr}
  event_id: rend_ev_k_t)               {event type inquiring about}
  :boolean;                            {TRUE when event is possible and enabled}
  val_param;

const
  max_msg_parms = 1;                   {max parameters we can pass to a message}

var
  ev: rend_evdev_k_t;                  {internal device-specific event ID}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;

begin
  case event_id of                     {what is user event ID ?}
rend_ev_none_k: begin
      rend_sw_get_event_possible := false;
      return;
      end;
rend_ev_close_k: begin
      ev := rend_evdev_close_k;
      end;
rend_ev_resize_k: begin
      ev := rend_evdev_resize_k;
      end;
rend_ev_wiped_rect_k: begin
      ev := rend_evdev_wiped_rect_k;
      end;
rend_ev_wiped_resize_k: begin
      ev := rend_evdev_wiped_resize_k;
      end;
rend_ev_key_k: begin
      ev := rend_evdev_key_k;
      end;
rend_ev_pnt_enter_k: begin
      ev := rend_evdev_pnt_k;
      end;
rend_ev_pnt_exit_k: begin
      ev := rend_evdev_pnt_k;
      end;
rend_ev_pnt_move_k: begin
      ev := rend_evdev_pnt_k;
      end;
rend_ev_close_user_k: begin
      ev := rend_evdev_close_k;
      end;
rend_ev_stdin_line_k: begin
      rend_sw_get_event_possible :=
        rend_evglb_stdin_line_k in rend_evglb;
      return;
      end;
rend_ev_xf3d_k: begin
      rend_sw_get_event_possible := false; {init to events are off}
      if rend_evdev_rotate_k in rend_device[rend_dev_id].ev_req then begin
        if rend_internal.ev_possible^ (rend_evdev_rotate_k) then begin
          rend_sw_get_event_possible := true;
          return;
          end;
        end;
      if rend_evdev_translate_k in rend_device[rend_dev_id].ev_req then begin
        if rend_internal.ev_possible^ (rend_evdev_translate_k) then begin
          rend_sw_get_event_possible := true;
          return;
          end;
        end;
      if
          (rend_evdev_pnt_k in rend_device[rend_dev_id].ev_req) and
          (rend_device[rend_dev_id].pnt_mode <> rend_pntmode_direct_k)
          then begin
        if rend_internal.ev_possible^ (rend_evdev_pnt_k) then begin
          rend_sw_get_event_possible := true;
          end;
        end;
      return;
      end;
otherwise
    sys_msg_parm_int (msg_parm[1], ord(event_id));
    rend_message_bomb ('rend', 'rend_event_id_bad', msg_parm, 1);
    end;
{
*   EV is the internal device-dependent ID for this event type.
}
  if ev in rend_device[rend_dev_id].ev_req
    then begin                         {this event type is enabled}
      rend_sw_get_event_possible :=    {call device routine to get the answer}
        rend_internal.ev_possible^ (ev);
      end
    else begin                         {this event type is disabled}
      rend_sw_get_event_possible := false; {can't possibly be on}
      end
    ;
  end;
{
*********************************************************
*
*   This is the SW driver version of this routine.
}
function rend_sw_get_ev_possible (     {internal find whether event might ever occurr}
  event_id: rend_evdev_k_t)            {event type inquiring about}
  :boolean;                            {TRUE when event is possible and enabled}
  val_param;

begin
  rend_sw_get_ev_possible := false;    {SW driver has no events}
  end;
{
*********************************************************
}
procedure rend_sw_events_req_off;      {request to disable all events}

var
  k: sys_int_machine_t;                {key ID loop counter}

begin
  with rend_device[rend_dev_id]: dev do begin {DEV is the descriptor for this device}
    dev.ev_req := [];                  {disable all events for this device}
    for k := 1 to dev.keys_n do begin  {once for each key of this device}
      dev.keys_p^[k].req := false;     {disable this key for events}
      end;                             {back and do next key in this device}
    dev.keys_enab := 0;                {no keys are now enabled for events}
    dev.ev_changed := true;            {flag that device events changed}
    end;                               {done with DEV abbreviation}

  rend_internal.check_modes^;
  end;
{
*********************************************************
}
procedure rend_sw_pointer (            {set pointer to location within draw area}
  in      x, y: sys_int_machine_t);    {new location relative to draw area origin}
  val_param;

begin
  rend_pointer.x := x;
  rend_pointer.y := y;
  rend_pointer.inside :=
    (rend_pointer.x >= 0) and
    (rend_pointer.x < rend_image.x_size) and
    (rend_pointer.y >= 0) and
    (rend_pointer.y < rend_image.y_size);
  end;
{
*********************************************************
}
procedure rend_sw_pointer_abs (        {set pointer to location within "root" device}
  in      x, y: sys_int_machine_t);    {new location in absolute "root" coordinates}
  val_param;

begin
  rend_pointer.root_x := x;
  rend_pointer.root_y := y;
  rend_pointer.root_inside := true;
  rend_set.pointer^ (x, y);            {set to same coordinates in current device}
  end;
{
*********************************************************
}
procedure rend_sw_get_keys (           {get info about all available keys}
  out     keys_p: univ rend_key_ar_p_t; {pointer to array of all the key descriptors}
  out     n: sys_int_machine_t);       {number of valid entries in KEYS}

begin
  with rend_device[rend_dev_id]: dev do begin {DEV is our device descriptor}
    keys_p := dev.keys_p;              {return pointer to list of key descriptors}
    n := dev.keys_n;                   {return number of keys in list}
    end;                               {done with DEV abbreviation}
  end;
{
*********************************************************
}
function rend_sw_get_key_sp (          {get ID of a special pre-defined key}
  in      id: rend_key_sp_k_t;         {ID for this special key}
  in      detail: sys_int_machine_t)   {detail info for this key}
  :rend_key_id_t;                      {key ID or REND_KEY_NONE_K}
  val_param;

var
  key: sys_int_machine_t;              {key ID loop counter}

begin
  rend_sw_get_key_sp := rend_key_none_k; {init to requested key doesn't exist}
  if id = rend_key_sp_none_k then return; {not requesting a real special key ?}

  with rend_device[rend_dev_id]: dev do begin {DEV is our device descriptor}
    for key := 1 to dev.keys_n do begin {once for each existing key}
      with dev.keys_p^[key]: k do begin {K is this key descriptor}
        if k.id = rend_key_none_k then next; {this key descriptor is empty ?}
        if                             {key matches requested special key info ?}
            (k.spkey.key = id) and
            (k.spkey.detail = detail)
            then begin                 {we found the requested key}
          rend_sw_get_key_sp := k.id;  {pass back ID of this key}
          return;
          end;
        end;                           {done with K abbreviation}
      end;                             {back and check out next key descriptor}
    end;                               {done with DEV abbreviation}
  end;
{
*********************************************************
}
procedure rend_sw_get_key_sp_def (     {get "default" or "empty" special key data}
  out     key_sp_data: rend_key_sp_data_t); {returned special key data block}

begin
  key_sp_data.key := rend_key_sp_none_k;
  key_sp_data.detail := 0;
  end;
{
*********************************************************
}
function rend_sw_get_pointer (         {get current pointer location}
  out     x, y: sys_int_machine_t)     {pointer coordinates within this device}
  :boolean;                            {TRUE if pointer is within this device area}

begin
  x := rend_pointer.x;
  y := rend_pointer.y;
  rend_sw_get_pointer := rend_pointer.inside;
  end;
{
*********************************************************
}
function rend_sw_get_pointer_abs (     {get current absolute pointer location}
  out     x, y: sys_int_machine_t)     {pointer coordinates on "root" device}
  :boolean;                            {TRUE if pointer is within root device area}

begin
  x := rend_pointer.root_x;
  y := rend_pointer.root_y;
  rend_sw_get_pointer_abs := rend_pointer.root_inside;
  end;
{
*********************************************************
}
procedure rend_sw_event_mode_pnt (     {indicate how to handle pointer motion}
  in      mode: rend_pntmode_k_t);     {interpretation mode, use REND_PNTMOVE_xxx_K}
  val_param;

begin
  rend_device[rend_dev_id].pnt_mode := mode; {set new pointer handling mode}
  if mode <> rend_pntmode_direct_k then begin {old XY value must be updated ?}
    discard( rend_get.pointer^ (       {init old pointer coordinate to current}
      rend_device[rend_dev_id].pnt_x,
      rend_device[rend_dev_id].pnt_y));
    end;
  end;
