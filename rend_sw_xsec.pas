{   Module REND_SW_XSEC
*
*   This module contains the routines that manipulate tube crossection definitions.
}
module rend_sw_xsec;
define rend_sw_xsec_circle;
define rend_sw_xsec_close;
define rend_sw_xsec_create;
define rend_sw_xsec_curr;
define rend_sw_xsec_delete;
define rend_sw_xsec_pnt_add;
%include 'rend_sw2.ins.pas';
{
*******************************
*
*   Subroutine REND_SW_XSEC_CIRCLE (NSEG, SMOOTH, SCOPE, XSEC_P)
*
*   Create a new crossection and fill it in as a unit circle.
*
*   NSEG - The number of line segments to use in approximating a circle.
*
*   SMOOTH - TRUE means should be smooth shaded around circle.
*
*   SCOPE - Indicates what scope the new crossection will belong to.  Values may be:
*     REND_SCOPE_SYS_K
*     REND_SCOPE_REND_K
*     REND_SCOPE_DEV_K
*
*   XSEC_P - Returned handle to newly created crossection.  Crossection will be
*     ready for use.
}
procedure rend_sw_xsec_circle (        {create new unit-circle crossection}
  in      nseg: sys_int_machine_t;     {number of line segments in the circle}
  in      smooth: boolean;             {TRUE if should smooth shade around circle}
  in      scope: rend_scope_t;         {what scope new crossection will belong to}
  out     xsec_p: rend_xsec_p_t);      {returned handle to new crossection}
  val_param;

var
  a: real;                             {current angle}
  da: real;                            {angle increment}
  i: sys_int_machine_t;                {loop counter}
  coor_curr: vect_2d_t;                {current circle point coordinate}
  coor_prev: vect_2d_t;                {coordinate for previous circle point}
  coor_next: vect_2d_t;                {coordinate for next circle point}
  norm_bef, norm_aft: vect_2d_t;       {shading normals at the current circle point}

begin
  rend_set.xsec_create^ (scope, xsec_p); {create new crossection}
  da := rend_pi2 / nseg;               {angle between points}
  a := 0.0;                            {init current angle}
  coor_curr.x := cos(-da);             {init coors expected to exist in the loop}
  coor_curr.y := sin(-da);
  coor_next.x := 1.0;
  coor_next.y := 0.0;

  for i := 1 to nseg do begin          {once for each circle point}
    a := a + da;                       {advance to angle for new "next" point}
    coor_prev := coor_curr;            {update the next/curr/prev coordinates}
    coor_curr := coor_next;
    coor_next.x := cos(a);
    coor_next.y := sin(a);
    if smooth
      then begin                       {smooth shading ON}
        rend_set.xsec_pnt_add^ (       {add this point to crossection}
          xsec_p^,                     {crossection handle}
          coor_curr,                   {point coordinate}
          coor_curr,                   {"before" shading normal}
          coor_curr,                   {"after" shading normal}
          smooth);
        end
      else begin                       {smooth shading is OFF}
        norm_bef.x := 0.5 * (coor_curr.x + coor_prev.x); {"before" shading normal}
        norm_bef.y := 0.5 * (coor_curr.y + coor_prev.y);
        norm_aft.x := 0.5 * (coor_curr.x + coor_next.x); {"after" shading normal}
        norm_aft.y := 0.5 * (coor_curr.y + coor_next.y);
        rend_set.xsec_pnt_add^ (       {add this point to crossection}
          xsec_p^,                     {crossection handle}
          coor_curr,                   {point coordinate}
          norm_bef,                    {"before" shading normal}
          norm_aft,                    {"after" shading normal}
          smooth);
        end
      ;
    end;                               {back and do next circle point}

  rend_set.xsec_close^ (xsec_p^, true); {close xsec and connect last point to first}
  end;
{
*******************************
*
*   Subroutine REND_SW_XSEC_CLOSE (XSEC, CONNECT)
*
*   Close a crossection definition.  This must be done before it can be used.
*   This also freezes the definition.  The crossection may not be edited after
*   it is closed.
*
*   XSEC - The crossection to close.
*
*   CONNECT - If TRUE, indicates that the last point is connected to the first
*     point to form a closed path.  Otherwise, the points are not connected, and
*     it is assumed that the crossection is an open path.
}
procedure rend_sw_xsec_close (         {done adding points, freeze xsec definition}
  in out  xsec: rend_xsec_t;           {crossection to close}
  in      connect: boolean);           {TRUE if connect last point to first point}
  val_param;

begin
  if rend_xsec_flag_closed_k in xsec.flags then begin {xsec already closed ?}
    rend_message_bomb ('rend', 'rend_xsec_closed', nil, 0);
    end;
  xsec.flags :=                        {flag crossection as closed}
    xsec.flags + [rend_xsec_flag_closed_k];
  if connect then begin                {end/start points connected ?}
    xsec.flags :=                      {flag that end/start points are connected}
      xsec.flags + [rend_xsec_flag_conn_k];
    xsec.last_p^.next_p := xsec.first_p; {close points chain to make loop}
    xsec.first_p^.prev_p := xsec.last_p;
    end;
  end;
{
*******************************
*
*   Subroutine REND_SW_XSEC_CREATE (SCOPE, XSEC_P)
*
*   Create a new crossection descriptor.  This has no effect on any existing state,
*   including the current crossection.
*
*   SCOPE - Indicates what scope the new crossection will belong to.  Values may be:
*     REND_SCOPE_SYS_K
*     REND_SCOPE_REND_K
*     REND_SCOPE_DEV_K
*
*   XSEC_P - Returned handle to newly created crossection descriptor.  The
*     crossection will be initialized to contain no points.  Points must be
*     added to it, and it must be closed before use.
}
procedure rend_sw_xsec_create (        {create new crossection descriptor}
  in      scope: rend_scope_t;         {what scope new crossection will belong to}
  out     xsec_p: rend_xsec_p_t);      {returned user handle to new crossection}
  val_param;

const
  max_msg_parm = 1;                    {max parameters we can pass to a message}

var
  parent_mem_p: util_mem_context_p_t;  {points to parent mem context}
  mem_p: util_mem_context_p_t;         {points to memory context for this xsec}
  msg_parm:                            {message parameter references}
    array[1..max_msg_parm] of sys_parm_msg_t;

begin
  case scope of                        {what scope does memory belong to ?}
rend_scope_sys_k: begin                {memory does not belong to RENDlib at all}
      parent_mem_p := addr(util_top_mem_context);
      end;
rend_scope_rend_k: begin               {memory belongs to all RENDlib, above devices}
      parent_mem_p := rend_mem_context_p;
      end;
rend_scope_dev_k: begin                {memory belongs just to the current device}
      if rend_dev_id <= 0 then begin
        rend_message_bomb ('rend', 'rend_dev_curr_none', nil, 0);
        end;
      parent_mem_p := rend_device[rend_dev_id].mem_p;
      end;
otherwise
    sys_msg_parm_int (msg_parm[1], ord(scope));
    rend_message_bomb ('rend', 'rend_mem_scope_bad', msg_parm, 1);
    end;                               {end of memory scope cases}

  util_mem_context_get (parent_mem_p^, mem_p); {create new mem context for this xsec}
  mem_p^.pool_size :=                  {set amount of mem to allocate at one time}
    sizeof(rend_xsec_point_t) * 64;    {room for 64 crossection points at a time}
  mem_p^.max_pool_chunk :=             {set max chunk allowed to take from pool}
    sizeof(rend_xsec_point_t) + 8;     {make sure xsec point can come from pool}

  util_mem_grab (                      {allocate mem for base xsec descriptor}
    sizeof(xsec_p^), mem_p^, false, xsec_p);

  xsec_p^.n := 0;                      {init new crossection descriptor}
  xsec_p^.first_p := nil;
  xsec_p^.last_p := nil;
  xsec_p^.mem_p := mem_p;
  xsec_p^.flags := [];
  end;
{
*******************************
*
*   Subroutine REND_SW_XSEC_CURR (XSEC)
*
*   Declare new current crossection.  This crossection will be used by default
*   wherever no crossection is explicitly specified.  The RENDlib default current
*   crossection is a circle.
}
procedure rend_sw_xsec_curr (          {declare current crossection for future use}
  in      xsec: rend_xsec_t);          {crossection to make current}
  val_param;

begin
  rend_xsec_curr_p := addr(xsec);      {set new crossection as current}
  end;
{
*******************************
*
*   Subroutine REND_SW_XSEC_DELETE (XSEC_P)
*
*   Delete a crossection descriptor and deallocate its system resources.
*   XSEC_P is returned invalid.  If this was also the current crossection, then
*   the current crossection will be restored to the RENDlib default crossection.
}
procedure rend_sw_xsec_delete (        {delete crossection, deallocate resources}
  in out  xsec_p: rend_xsec_p_t);      {crossection handle, will be set to invalid}

var
  mem_p: util_mem_context_p_t;         {points to memory context for this xsec}

begin
  if xsec_p = rend_xsec_curr_p then begin {deleting the current crossection ?}
    rend_xsec_curr_p := rend_xsec_def_p; {make default crossection current}
    end;

  mem_p := xsec_p^.mem_p;              {make local copy of memory context pointer}
  util_mem_context_del (mem_p);        {deallocate all memory for this crossection}
  xsec_p := nil;                       {return crossection handle as invalid}
  end;
{
*******************************
*
*   Subroutine REND_SW_XSEC_PNT_ADD (XSEC, COOR, NORM_BEF, NORM_AFT, SMOOTH)
*
*   Add a point to the current end of a crossection path.  The crossection must
*   be open.  This call accesses the full features available in describing a
*   crossection point.  In other words, this is the "unlayered" call.
*
*   XSEC - The crossection to add a point to.
*
*   COOR - X,Y coordinate of this crossection point.  By convention, crossections
*     go around the origin with a "radius" of 1.0.  Separate scaling factors
*     are available when the crossection is used.  Right handed crossections go
*     around the origin counter-clockwise when viewed so that X is to the right
*     and Y is up.
*
*   NORM_BEF - Shading normal vector in the crossection plane at, or just before
*     this point.  This is also the shading normal for the whole point when
*     SMOOTH is TRUE (below).
*
*   NORM_AFT - Shading normal vector in the crossection plane just after this
*     point.  When SMOOTH is TRUE, then only one shading normal exists at this
*     point.  In that case NORM_BEF becomes this vector, and NORM_AFT becomes
*     irrelevant.
*
*   SMOOTH - When TRUE, indicates that smooth shading should be done at this
*     point around the crossection.  In that case NORM_BEF is the shading normal
*     for both sides of this point.  When SMOOTH is FALSE, NORM_BEF and NORM_AFT
*     are the shading normals to use on either side of this point.
}
procedure rend_sw_xsec_pnt_add (       {add point to end of xsec, full features}
  in out  xsec: rend_xsec_t;           {crossection to add point to}
  in      coor: vect_2d_t;             {coordinate, intended to be near unit circle}
  in      norm_bef: vect_2d_t;         {2D shading normal at or just before here}
  in      norm_aft: vect_2d_t;         {2D shading normal just after here}
  in      smooth: boolean);            {TRUE if NORM_BEF to apply to whole point}
  val_param;

var
  p: rend_xsec_point_p_t;              {points to new xsec point descriptor}

begin
  if rend_xsec_flag_closed_k in xsec.flags then begin {xsec already closed ?}
    rend_message_bomb ('rend', 'rend_xsec_closed', nil, 0);
    end;
  util_mem_grab (sizeof(p^), xsec.mem_p^, false, p); {alloc memory for new point}

  p^.next_p := nil;                    {fill in descriptor for new crossection point}
  p^.prev_p := xsec.last_p;
  p^.coor := coor;
  p^.norm_bef := norm_bef;
  p^.norm_aft := norm_aft;
  p^.flags := [];
  if smooth then begin                 {smooth shade accross this point ?}
    p^.flags := p^.flags + [rend_xsecpnt_flag_smooth_k];
    end;
  p^.flags := p^.flags + [rend_xsecpnt_flag_nrmset_k]; {not fully implemented yet}

  if xsec.first_p = nil
    then begin                         {this is first point in crossection}
      xsec.first_p := p;
      end
    else begin                         {there is a previous point}
      xsec.last_p^.next_p := p;
      end
    ;
  xsec.last_p := p;                    {update pointer to new last point in list}

  if xsec.first_p = nil                {this is first point in crossection ?}
    then xsec.first_p := p;
  xsec.n := xsec.n + 1;                {log one more point in this crossection}
  end;
