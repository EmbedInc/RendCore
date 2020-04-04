{   Module of routines that are global to all RENDlib, and that relate
*   to events.
}
module rend_events;
define rend_event_get;
define rend_event_get_nowait;
define rend_event_enqueue;
define rend_event_push;
define rend_event_req_stdin_line;
define rend_get_stdin_line;
define rend_event_pointer_move;
define rend_event_key_multiple;
%include 'rend2.ins.pas';
{
********************************************************************************
*
*   Local subroutine REND_EVENT_GET2 (EVENT, WAIT)
*
*   Get the next event.  Return immediately, with a NULL event if neccesary,
*   when WAIT is FALSE.  Otherwise wait until a suitable event occurs.
*
*   Callback events are handled transparently in this routine, so are never
*   returned.
}
procedure rend_event_get2 (
  out     event: rend_event_t;         {returned event descriptor}
  in      wait: boolean);              {wait for an event when TRUE}
  val_param; internal;

label
  unqueue_event;

begin
unqueue_event:                         {try again if event processed here}
  rend_evqueue_get (event, wait);      {get next event}

  if rend_debug_level >= 10 then begin {show event info for debugging ?}
    write ('Read RENDlib event ');
    case event.ev_type of              {which event is this ?}
rend_ev_none_k: begin                  {no event occurred}
        writeln ('NONE');
        end;
rend_ev_close_k: begin                 {draw device closed, RENDlib still open}
        writeln ('CLOSE');
        end;
rend_ev_resize_k: begin                {drawing area changed size}
        writeln ('RESIZE, ', rend_image.x_size, ',', rend_image.y_size);
        end;
rend_ev_wiped_rect_k: begin            {rect of pixels wiped out, now redrawable}
        writeln ('WIPED_RECT');
        end;
rend_ev_wiped_resize_k: begin          {all pixels wiped out, now redrawable}
        writeln ('WIPED_RESIZE');
        end;
rend_ev_key_k: begin                   {a user-pressable key changed state}
        writeln ('KEY');
        end;
rend_ev_pnt_enter_k: begin             {pointer entered draw area}
        writeln ('PNT_ENTER');
        end;
rend_ev_pnt_exit_k: begin              {pointer left draw area}
        writeln ('PNT_EXIT');
        end;
rend_ev_pnt_move_k: begin              {pointer location changed}
        writeln ('PNT_MOVE');
        end;
rend_ev_close_user_k: begin            {user requested close of graphics device}
        writeln ('CLOSE_USER');
        end;
rend_ev_stdin_line_k: begin            {text line available from REND_GET_STDIN_LINE}
        writeln ('STDIN_LINE');
        end;
rend_ev_xf3d_k: begin                  {3D transformation event}
        writeln ('XF3D');
        end;
rend_ev_app_k: begin                   {application event}
        writeln ('APP');
        end;
rend_ev_call_k: begin                  {callback event}
        writeln ('CALL');
        end;
      end;                             {end of event type cases}
    end;                               {end of print debug enabled}

  case event.ev_type of                {check for special handling events}
rend_ev_call_k: begin                  {callback event}
      if event.call.call_p <> nil then begin {callback routine pointer set ?}
        event.call.call_p^ (addr(event)); {call the callback routine for this event}
        end;
      goto unqueue_event;              {back to get next event}
      end;
    end;                               {end of event type cases}
  end;                                 {return with event}
{
********************************************************************************
*
*   Subroutine REND_EVENT_GET (EVENT)
*
*   Get the next event.  This routine will wait until a suitable event is
*   available.
}
procedure rend_event_get (             {get next RENDlib event}
  out     event: rend_event_t);        {returned event descriptor}

begin
  rend_event_get2 (event, true);       {get next event, wait if neccessary}
  end;
{
********************************************************************************
*
*   Subroutine REND_EVENT_GET_NOWAIT (EVENT)
*
*   Get the next event, if one is available.  An event with ID REND_EV_NONE_K
*   is returned if none is immediately available.
}
procedure rend_event_get_nowait (      {get next RENDlib event if available now}
  out     event: rend_event_t);        {returned event descriptor}

begin
  rend_event_get2 (event, false);      {get event, return null event if none avail}
  end;
{
********************************************************************************
*
*   Subroutine REND_EVENT_ENQUEUE (EVENT)
*
*   Add the event to the tail of RENDlib's event queue.
*
*   Certain kinds of immediately adjacent events are compressed into one event.
}
procedure rend_event_enqueue (         {add event to end of RENDlib's event queue}
  in      event: rend_event_t);        {this will be the next event returned}

var
  evl_p: rend_event_p_t;               {pointer to last event in the queue}
  xb, yb, zb, ofs: vect_3d_t;          {scratch basis vectors}

label
  no_compress;

begin
  if rend_debug_level >= 10 then begin {show event info for debugging ?}
    write ('Write RENDlib event ');
    case event.ev_type of              {which event is this ?}
rend_ev_none_k: begin                  {no event occurred}
        writeln ('NONE');
        end;
rend_ev_close_k: begin                 {draw device closed, RENDlib still open}
        writeln ('CLOSE');
        end;
rend_ev_resize_k: begin                {drawing area changed size}
        writeln ('RESIZE, ', rend_image.x_size, ',', rend_image.y_size);
        end;
rend_ev_wiped_rect_k: begin            {rect of pixels wiped out, now redrawable}
        writeln ('WIPED_RECT, ul ', event.wiped_rect.x, ',', event.wiped_rect.y,
          ' size ', event.wiped_rect.dx, ',', event.wiped_rect.dy);
        end;
rend_ev_wiped_resize_k: begin          {all pixels wiped out, now redrawable}
        writeln ('WIPED_RESIZE');
        end;
rend_ev_key_k: begin                   {a user-pressable key changed state}
        writeln ('KEY ', event.key.x, ',', event.key.y);
        end;
rend_ev_pnt_enter_k: begin             {pointer entered draw area}
        writeln ('PNT_ENTER');
        end;
rend_ev_pnt_exit_k: begin              {pointer left draw area}
        writeln ('PNT_EXIT');
        end;
rend_ev_pnt_move_k: begin              {pointer location changed}
        writeln ('PNT_MOVE');
        end;
rend_ev_close_user_k: begin            {user requested close of graphics device}
        writeln ('CLOSE_USER');
        end;
rend_ev_stdin_line_k: begin            {text line available from REND_GET_STDIN_LINE}
        writeln ('STDIN_LINE');
        end;
rend_ev_xf3d_k: begin                  {3D transformation event}
        writeln ('XF3D');
        end;
rend_ev_app_k: begin
        writeln ('APP');
        end;
      end;                             {end of event type cases}
    end;                               {end of print debug enabled}

  rend_evqueue_last_lock (evl_p);      {get pointer to last event, lock the queue}
  if evl_p = nil then goto no_compress; {no previous event to compress new with ?}
  if evl_p^.dev <> event.dev           {previous event not from same device ?}
    then goto no_compress;
{
*   A previous event queue entry exists, and is pointed to by EVL_P.  The
*   previous event and the new event are both from the same device.  Now check
*   for whether the new event and the previous event can be compressed into one
*   event.  If compression is not possible, we jump to NO_COMPRESS or fall thru
*   the end of the CASE statement.
}
  case event.ev_type of                {what type is the new event ?}
{
*   New event is RESIZE.
}
rend_ev_resize_k: begin
  case evl_p^.ev_type of               {what type is the old event ?}
rend_ev_resize_k,                      {RESIZE, RESIZE -> RESIZE}
rend_ev_wiped_resize_k: begin          {WIPED_RESIZE, RESIZE -> WIPED_RESIZE}
      rend_evqueue_unlock;             {release lock on the event queue}
      return;
      end;
    end;                               {end of old event type cases}
  end;                                 {end of new event is RESIZE case}
{
*   New event is WIPED_RECT.
}
rend_ev_wiped_rect_k: begin
  case evl_p^.ev_type of               {what type is the old event ?}
rend_ev_wiped_resize_k: begin          {WIPED_RESIZE, WIPED_RECT -> WIPED_RESIZE}
      rend_evqueue_unlock;             {release lock on the event queue}
      return;
      end;
    end;                               {end of old event type cases}
  end;                                 {end of new event is WIPED_RECT case}
{
*   New event is WIPED_RESIZE.
*
*   Note that RESIZE events are not compressed with a following WIPED_RESIZE.
*   When a app enables both of these, then RESIZE is used to adjust to the new
*   window size, and WIPED_RESIZE typically just causes a redraw.
}
rend_ev_wiped_resize_k: begin
  case evl_p^.ev_type of               {what type is the old event ?}
rend_ev_wiped_rect_k: begin            {WIPED_RECT, WIPED_RESIZE -> WIPED_RESIZE}
      evl_p^.ev_type :=                {compress to one WIPED_RESIZE}
        rend_ev_wiped_resize_k;
      rend_evqueue_unlock;             {release lock on the event queue}
      return;
      end;
rend_ev_wiped_resize_k: begin          {multiple WIPED_RESIZE are senseless}
      rend_evqueue_unlock;             {release lock on the event queue}
      return;
      end;
    end;                               {end of old event type cases}
  end;                                 {end of new event is WIPED_RESIZE case}
{
*   Adjacent 3D transform events.  The new transform will be post-mutiplied
*   to the old, and the result will be used to update the event already in the
*   queue.  No new event will be added to the queue.
}
rend_ev_xf3d_k: begin
  case evl_p^.ev_type of               {what type is the old event ?}
rend_ev_xf3d_k: begin                  {XF3D, XF3D -> XF3D}
      if evl_p^.xf3d.dvclass <> event.xf3d.dvclass
        then goto no_compress;         {both events not from same device class ?}
      with
          evl_p^.xf3d.mat: omat,       {OMAT is matrix in old event}
          event.xf3d.mat: nmat         {NMAT is matrix in new event}
          do begin
        if rend_ev3d_rot_k in event.xf3d.comp
          then begin                   {new event contains 3x3 transform}
            xb.x :=                    {create composite matrix in XB, YB, ZB, OFS}
              omat.m33.xb.x * nmat.m33.xb.x +
              omat.m33.xb.y * nmat.m33.yb.x +
              omat.m33.xb.z * nmat.m33.zb.x;
            xb.y :=
              omat.m33.xb.x * nmat.m33.xb.y +
              omat.m33.xb.y * nmat.m33.yb.y +
              omat.m33.xb.z * nmat.m33.zb.y;
            xb.z :=
              omat.m33.xb.x * nmat.m33.xb.z +
              omat.m33.xb.y * nmat.m33.yb.z +
              omat.m33.xb.z * nmat.m33.zb.z;

            yb.x :=
              omat.m33.yb.x * nmat.m33.xb.x +
              omat.m33.yb.y * nmat.m33.yb.x +
              omat.m33.yb.z * nmat.m33.zb.x;
            yb.y :=
              omat.m33.yb.x * nmat.m33.xb.y +
              omat.m33.yb.y * nmat.m33.yb.y +
              omat.m33.yb.z * nmat.m33.zb.y;
            yb.z :=
              omat.m33.yb.x * nmat.m33.xb.z +
              omat.m33.yb.y * nmat.m33.yb.z +
              omat.m33.yb.z * nmat.m33.zb.z;

            zb.x :=
              omat.m33.zb.x * nmat.m33.xb.x +
              omat.m33.zb.y * nmat.m33.yb.x +
              omat.m33.zb.z * nmat.m33.zb.x;
            zb.y :=
              omat.m33.zb.x * nmat.m33.xb.y +
              omat.m33.zb.y * nmat.m33.yb.y +
              omat.m33.zb.z * nmat.m33.zb.y;
            zb.z :=
              omat.m33.zb.x * nmat.m33.xb.z +
              omat.m33.zb.y * nmat.m33.yb.z +
              omat.m33.zb.z * nmat.m33.zb.z;

            ofs.x :=
              omat.ofs.x * nmat.m33.xb.x +
              omat.ofs.y * nmat.m33.yb.x +
              omat.ofs.z * nmat.m33.zb.x +
              nmat.ofs.x;
            ofs.y :=
              omat.ofs.x * nmat.m33.xb.y +
              omat.ofs.y * nmat.m33.yb.y +
              omat.ofs.z * nmat.m33.zb.y +
              nmat.ofs.y;
            ofs.z :=
              omat.ofs.x * nmat.m33.xb.z +
              omat.ofs.y * nmat.m33.yb.z +
              omat.ofs.z * nmat.m33.zb.z +
              nmat.ofs.z;

            omat.m33.xb := xb;         {update transform in old event}
            omat.m33.yb := yb;
            omat.m33.zb := zb;
            omat.ofs := ofs;
            end                        {done handling new event as 3x3 transform}
          else begin                   {new event has no 3x3 transform}
            omat.ofs.x := omat.ofs.x + nmat.ofs.x; {concatenate the translations}
            omat.ofs.y := omat.ofs.y + nmat.ofs.y;
            omat.ofs.z := omat.ofs.z + nmat.ofs.z;
            end
          ;                            {3x4 matrix in old event fully updated}
        evl_p^.xf3d.comp :=            {combine component flags}
          evl_p^.xf3d.comp + event.xf3d.comp;
        end;                           {done with OMAT and NMAT abbreviations}
      rend_evqueue_unlock;             {release lock on the event queue}
      return;                          {all done, nothing to add to the queue}
      end;                             {end of old event is XF3D case}
    end;                               {end of old event type cases}
  end;                                 {end of new event is XF3D case}

    end;                               {end of new event type cases}
{
*   The new event couldn't be compressed with the previous event.  Add new event
*   to end of queue.
}
no_compress:
  rend_evqueue_add_unlock (event);     {add to end of queue, release lock}
  end;
{
********************************************************************************
*
*   Global subroutine REND_EVENT_PUSH (EVENT)
*
*   Push an event to the head of the event queue.  This will be the next event
*   returned.
}
procedure rend_event_push (            {push event onto head of event queue}
  in      event: rend_event_t);        {this will be the next event returned}

begin
  rend_evqueue_push (event);
  end;
{
********************************************************************************
*
*   Global subroutine REND_EVENT_REQ_STDIN_LINE (ON)
*
*   Enable/disable the STDIN_LINE global event.
}
procedure rend_event_req_stdin_line (  {request STDIN_LINE events on/off}
  in      on: boolean);                {TRUE requests these events}
  val_param;

begin
  if on
    then begin                         {enable STDIN events}
      rend_stdin_on;
      end
    else begin                         {disable STDIN events}
      rend_stdin_off;
      end
    ;
  end;
{
********************************************************************************
*
*   Global subroutine REND_GET_STDIN_LINE (S)
*
*   Return the next text line from standard input into the string S.  When the
*   STDIN_LINE event is enabled, this routine should only be called after such
*   an event is received.  Calling at other times may cause loss of data.
*
*   When the STDIN_LINE event is not enabled, this routine will wait until a
*   full text line is read from standard input.
}
procedure rend_get_stdin_line (        {get next line from standard input}
  in out  s: univ string_var_arg_t);   {returned line of text}

begin
  rend_stdin_get (s);
  end;
{
********************************************************************************
*
*   Global subroutine REND_EVENT_POINTER_MOVE (DEV, NEWX, NEWY)
*
*   Handle 2D pointer motion.  The current pointer coordinate is updated in the
*   device descriptor.  The appropriate event is created, if enabled.
}
function rend_event_pointer_move (     {handle 2D pointer motion}
  in      dev: sys_int_machine_t;      {RENDlib device where pointer moved}
  in      newx, newy: sys_int_machine_t) {new 2D pointer coordinates}
  :boolean;                            {TRUE if an event actually enqueued}
  val_param;

const
  scale_dolly_k = 1.0;                 {scale factor for dolly operations}
  scale_rot_k = 1.0;                   {scale factor for rotation operations}
  max_msg_parms = 1;                   {max parameters we can pass to a message}

var
  idx, idy: sys_int_machine_t;         {relative pointer motion in 2DIMI space}
  dx, dy: real;                        {relative pointer motion in 2D space}
  dxs, dys: real;                      {scaled DX and DY}
  m: real;                             {scratch mult factor}
  ev: rend_event_t;
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;

label
  done_set_event;

begin
  if rend_debug_level >= 10 then begin
    writeln ('Pointer moved from ', rend_device[dev].pnt_x, ',',
      rend_device[dev].pnt_y, ' to ', newx, ',', newy);
    end;

  rend_event_pointer_move := false;    {init to no event generated}
  idx := newx - rend_device[dev].pnt_x; {make relative pointer motion}
  idy := newy - rend_device[dev].pnt_y;
  if (idx = 0) and (idy = 0) then return; {pointer didn't really move ?}

  ev.dev := dev;                       {set event device}

  if rend_device[dev].pnt_mode = rend_pntmode_direct_k then begin {simple case ?}
    ev.ev_type := rend_ev_pnt_move_k;  {this is a pointer motion event}
    ev.pnt_move.x := newx;             {stuff new pointer coordinates into event}
    ev.pnt_move.y := newy;
    goto done_set_event;               {all done setting up EV}
    end;
{
*   Do common initialization for the more complicated pointer handling
*   modes.
}
  rend_dev_set (dev);                  {swap in RENDlib device that had the event}

  if not rend_2d.sp.inv_ok then begin  {can't do 2DIM to 2D transform ?}
    goto done_set_event;
    end;

  dx := rend_2d.sp.invm *              {transform displacement from 2DIM to 2D space}
    (idx * rend_2d.sp.yb.y - idy * rend_2d.sp.xb.y);
  dy := rend_2d.sp.invm *
    (-idx * rend_2d.sp.yb.x + idy * rend_2d.sp.xb.x);

  ev.ev_type := rend_ev_xf3d_k;        {init to 3D transform event created}
  ev.xf3d.dvclass := rend_dvclass_rel_k; {this will be a relative transform event}
  ev.xf3d.comp := [];                  {init to no 3D transform components present}

  ev.xf3d.mat.m33.xb.x := 1.0;         {init transform to identity}
  ev.xf3d.mat.m33.xb.y := 0.0;
  ev.xf3d.mat.m33.xb.z := 0.0;
  ev.xf3d.mat.m33.yb.x := 0.0;
  ev.xf3d.mat.m33.yb.y := 1.0;
  ev.xf3d.mat.m33.yb.z := 0.0;
  ev.xf3d.mat.m33.zb.x := 0.0;
  ev.xf3d.mat.m33.zb.y := 0.0;
  ev.xf3d.mat.m33.zb.z := 1.0;
  ev.xf3d.mat.ofs.x := 0.0;
  ev.xf3d.mat.ofs.y := 0.0;
  ev.xf3d.mat.ofs.z := 0.0;

  case rend_device[dev].pnt_mode of    {what supposed to do with pointer motion ?}
{
************************************
*
*   Pointer motion causes change of view direction.  This appears as if the
*   pointer "drags" the Z=0 plane.
}
rend_pntmode_pan_k: begin
  if rend_view.perspec_on
    then begin                         {perspective is ON}
      dxs := dx / rend_view.eyedis;    {scale to unit view space}
      dys := dy / rend_view.eyedis;

      m := 1.0 / sqrt(sqr(dxs) + sqr(dys) + 1); {create unit ZB}
      ev.xf3d.mat.m33.zb.x := -dxs * m;
      ev.xf3d.mat.m33.zb.y := -dys * m;
      ev.xf3d.mat.m33.zb.z := m;

      m := 1.0 / sqrt(1 + sqr(dxs));   {create orthogonal unit XB}
      ev.xf3d.mat.m33.xb.x := m;
      ev.xf3d.mat.m33.xb.z := dxs * m;

      ev.xf3d.mat.m33.yb.x :=          {make YB as ZB x XB}
        ev.xf3d.mat.m33.zb.y * ev.xf3d.mat.m33.xb.z;
      ev.xf3d.mat.m33.yb.y :=
        ev.xf3d.mat.m33.zb.z * ev.xf3d.mat.m33.xb.x -
        ev.xf3d.mat.m33.zb.x * ev.xf3d.mat.m33.xb.z;
      ev.xf3d.mat.m33.yb.z :=
        -ev.xf3d.mat.m33.zb.y * ev.xf3d.mat.m33.xb.x;

      ev.xf3d.mat.ofs.x :=             {transform offset thru new rotation}
        dx * ev.xf3d.mat.m33.xb.x +
        dy * ev.xf3d.mat.m33.yb.x;
      ev.xf3d.mat.ofs.y :=
        dx * ev.xf3d.mat.m33.xb.y +
        dy * ev.xf3d.mat.m33.yb.y;
      ev.xf3d.mat.ofs.z :=
        dx * ev.xf3d.mat.m33.xb.z +
        dy * ev.xf3d.mat.m33.yb.z;

      ev.xf3d.comp := [                {set components in this transform}
        rend_ev3d_rot_k,               {rotation}
        rend_ev3d_translate_k,         {any translation}
        rend_ev3d_tx_k, rend_ev3d_ty_k, rend_ev3d_tz_k];
      end
    else begin                         {perspective is OFF}
      ev.xf3d.mat.ofs.x := dx;
      ev.xf3d.mat.ofs.y := dy;
      ev.xf3d.comp := [                {xform has only X and Y translations}
        rend_ev3d_translate_k, rend_ev3d_tx_k, rend_ev3d_ty_k];
      end
    ;
  end;
{
************************************
*
*   Pointer motion appears to causes in and out translations of the eye point
*   along the view direction.  This actually causes a relative scale factor to
*   the whole transform, since perspective is preserved.  +Y pointer motion
*   (mouse movement away from user) causes dolly in.  X motion is ignored.
}
rend_pntmode_dolly_k: begin
  m := (dy * scale_dolly_k) + 1.0;     {make transform scale factor}

  ev.xf3d.mat.m33.xb.x := m;           {set scaling transform}
  ev.xf3d.mat.m33.yb.y := m;
  ev.xf3d.mat.m33.zb.z := m;

  ev.xf3d.comp := [rend_ev3d_scale_k];
  end;
{
************************************
*
*   Pointer motion causes pure rotations.  Movement in +X direction will cause
*   rotation in +Y.  Movement in +Y direction will cause rotation in -X.  This
*   has the appearance of dragging a point on the front of a large sphere.  The
*   sphere is allowed to rotate about the origin.
}
rend_pntmode_rot_k: begin
  dxs := dx * scale_rot_k;             {apply rotation scale factor}
  dys := dy * scale_rot_k;

  m := 1.0 / sqrt(sqr(dxs) + sqr(dys) + 1); {create unit ZB}
  ev.xf3d.mat.m33.zb.x := dxs * m;
  ev.xf3d.mat.m33.zb.y := dys * m;
  ev.xf3d.mat.m33.zb.z := m;

  m := 1.0 / sqrt(1 + sqr(dxs));       {create orthogonal unit XB}
  ev.xf3d.mat.m33.xb.x := m;
  ev.xf3d.mat.m33.xb.z := -dxs * m;

  ev.xf3d.mat.m33.yb.x :=              {make YB as ZB x XB}
    ev.xf3d.mat.m33.zb.y * ev.xf3d.mat.m33.xb.z;
  ev.xf3d.mat.m33.yb.y :=
    ev.xf3d.mat.m33.zb.z * ev.xf3d.mat.m33.xb.x -
    ev.xf3d.mat.m33.zb.x * ev.xf3d.mat.m33.xb.z;
  ev.xf3d.mat.m33.yb.z :=
    -ev.xf3d.mat.m33.zb.y * ev.xf3d.mat.m33.xb.x;

  ev.xf3d.comp := [rend_ev3d_rot_k];   {this is a pure rotation transform}
  end;
{
************************************
*
*   Unexpected pointer motion strategy ID.
}
otherwise
    sys_msg_parm_int (msg_parm[1], ord(rend_device[dev].pnt_mode));
    rend_message_bomb ('rend', 'rend_event_pntmode_bad', msg_parm, 1);
    end;                               {done with pointer motion strategy cases}

done_set_event:                        {done setting new event in EV}
  rend_event_enqueue (ev);             {put event on end of queue}
  rend_event_pointer_move := true;     {indicate event was generated}

  rend_device[dev].pnt_x := newx;      {update current 2D pointer coordinates}
  rend_device[dev].pnt_y := newy;
  end;
{
********************************************************************************
*
*   Function REND_EVENT_KEY_MULTIPLE (EVENT)
*
*   Returns the total number of consecutive times the key indicated by EVENT was
*   pressed.  This may either be due to a keyboard auto-repeat feature, or
*   because the user has pressed and released the key several times since the
*   program last checked for events.  The function value is the total number of
*   times the key is to be interpreted as having been pressed.  This includes
*   the event in EVENT.  The function value is therefore always at least 1 when
*   EVENT indicates a key press (as apposed to a key release).  All counted
*   events are removed from the event queue.  The first event that does not
*   match EVENT is left in the queue.  The final key release of a string of
*   press/release events is also left in the queue.
*
*   The function returns 0 when EVENT is not a key event, or if it is a key
*   release with no following key presses.
}
function rend_event_key_multiple (     {get number of repeated KEY events}
  in      event: rend_event_t)         {key down event that may be repeated}
  :sys_int_machine_t;                  {total repeated key presses, EVENT}
  val_param;

var
  n: sys_int_machine_t;                {key press counter}
  ev: rend_event_t;                    {last event read from queue}
  up: boolean;                         {TRUE if last event was a matching key up}

label
  loop, leave;

begin
  rend_event_key_multiple := 0;        {init to no events at all}
  if event.ev_type <> rend_ev_key_k then return; {not a key event at all ?}
  if event.key.down
    then n := 1                        {count initial key down event}
    else n := 0;                       {initial event is a key up}
  up := false;                         {init to no matching key up read from queue}

loop:                                  {back here to test each new event}
  rend_event_get_nowait (ev);          {get next event from queue, if any}
  if ev.ev_type = rend_ev_none_k then goto leave; {event queue is empty}
  if ev.dev <> event.dev then goto leave; {device ID's don't match ?}
  if ev.ev_type <> rend_ev_key_k then goto leave; {this isn't a key event ?}
  if ev.key.key_p <> event.key.key_p then goto leave; {different key ?}
  if ev.key.modk <> event.key.modk then goto leave; {different modifiers active ?}
  if ev.key.down
    then begin                         {this is a matching key press event}
      n := n + 1;                      {count one more key press}
      up := false;                     {last event wasn't a key release}
      end
    else begin                         {this is a matching key release event}
      up := true;                      {last event was a matching key release}
      end
    ;
  goto loop;                           {back to check next event in the queue}

leave:                                 {common exit code after reading events}
  if ev.ev_type <> rend_ev_none_k then begin {we read an event not for us to keep ?}
    rend_event_push (ev);              {put the event back onto the event queue}
    end;
  if up then begin                     {last matching event was a key release ?}
    ev := event;                       {make local copy of template event}
    ev.key.down := false;              {make it a key release event}
    rend_event_push (ev);              {put the terminating key up event back}
    end;
  rend_event_key_multiple := n;        {pass back consecutive key presses found}
  end;
