{   Private include file for all REND routines.  All the data structures and
*   entry points that are private and deal with the layer above the device
*   drivers are here.
*
*   About RENDlib's top level:
*
*     RENDlib's top level is a layer above any particular device drivers.  The
*     common block defined here always contains valid data after the REND_START
*     call, whether any device has been opened or not.  One important reason
*     that RENDlib needs to know about all graphics connections that have been
*     opened is for proper handling of asynchronous events, such as window
*     shakeups.  An asynchonous event may happen when the RENDlib context for
*     that device is swapped out.  Therefore, a top layer needs to be able to
*     save the current state, identify and swap in the state of the device with
*     the event, call the user, restore the state, and return.  This can only be
*     done if some global state exists for all the devices.  This include file
*     declares the common block and associated information for that global
*     state.
*
*     NOTE: Only the bare minimum device state that really needs to be visible
*     about a swapped out device should be kept here.  Any other per-device
*     state should go either in REND_SW.INS.PAS if it is needed for all devices,
*     or in REND_xxx.ins.pas if it is specific to a particular device.
*
*   About RENDlib memory allocation:
*
*     RENDlib occasionally needs to dynamically allocate memory, either for
*     internal reasons or directly due to a user request.  This memory can be
*     allocated from different scopes: system, RENDlib top level, or a specific
*     RENDlib open device.  See the constants REND_SCOPE_xxx_K in REND.INS.PAS.
*
*     The effective difference between these is when, if ever, RENDlib will
*     automatically deallocate this memory.  System memory is never
*     automatically deallocated by RENDlib.  RENDlib top level memory is assumed
*     to have a scope tied to the current RENDlib invocation, but above any
*     specific device.  An example might be a RENDlib bitmap that is shared
*     between devices.  Such memory is automatically deallocated when REND_END
*     is called.  RENDlib device  memory is assumed to be associated only with a
*     particular device, and is therefore automatically deallocated when
*     REND_SET.CLOSE is called.
}
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'img.ins.pas';
%include 'vect.ins.pas';
%include 'ray.ins.pas';
%include 'ray_type1.ins.pas';
%include 'rend.ins.pas';

const
  rend_max_devices = 8;                {max simultaneously open devices}

type
  rend_evglb_k_t = (                   {IDs for all global RENDlib event requests}
    rend_evglb_stdin_line_k);          {STDIN_LINE events}
  rend_evglb_t =                       {set of all global RENDlib event requests}
    set of rend_evglb_k_t;

  rend_evdev_k_t = (                   {IDs for all device-specific event requests}
    rend_evdev_close_k,                {CLOSE, CLOSE_USER events}
    rend_evdev_resize_k,               {RESIZE events}
    rend_evdev_wiped_resize_k,         {WIPED_RESIZE compressed with WIPED_RECT}
    rend_evdev_wiped_rect_k,           {WIPED_RECT events}
    rend_evdev_key_k,                  {KEY events}
    rend_evdev_pnt_k,                  {PNT_ENTER, PNT_EXIT, PNT_MOVE events}
    rend_evdev_rotate_k,               {3D rotations}
    rend_evdev_translate_k);           {3D translations}
  rend_evdev_t =                       {set of all device-specific event requests}
    set of rend_evdev_k_t;

  rend_device_t = record               {permanent data about each device}
    save_area_p: rend_context_p_t;     {handle to current context when swapped out}
    mem_p: util_mem_context_p_t;       {pnt to memory context for this device}
    keys_enab: sys_int_machine_t;      {number of individual keys enabled for events}
    keys_max: sys_int_machine_t;       {number of allocated key desc in KEYS_P^}
    keys_n: sys_int_machine_t;         {number of actual keys in KEYS_P^}
    keys_p: rend_key_ar_p_t;           {points to array of key descriptors}
    ev_req: rend_evdev_t;              {mask for all the requested event types}
    scale_3drot: real;                 {scale factor for 3D rotation events}
    pnt_x, pnt_y: sys_int_machine_t;   {current 2D pointer coordinates}
    pnt_mode: rend_pntmode_k_t;        {2D pointer motion interpretation}
    open: boolean;                     {TRUE if device is open}
    ev_changed: boolean;               {event config changed, for CHECK_MODES}
    end;

  {   The following structures should be considered opaque except in the module
  *   REND_EVQUEUE.
  }
  rend_evq_ent_p_t = ^rend_evq_ent_t;
  rend_evq_ent_t = record              {one event queue entry}
    next_p: rend_evq_ent_p_t;          {points to next entry in queue}
    event: rend_event_t;               {actual event data}
    end;

  rend_evqueue_t = record              {the global event queue}
    mem_p: util_mem_context_p_t;       {points to context for all queue dyn mem}
    lock: sys_sys_threadlock_t;        {mutex for accessing the queue structures}
    first_p: rend_evq_ent_p_t;         {points to first (next event) queue entry}
    last_p: rend_evq_ent_p_t;          {points to last queue entry}
    free_p: rend_evq_ent_p_t;          {points to chain of unused queue entries}
    newev: sys_sys_event_id_t;         {notified when new event added to queue}
    locked: boolean;                   {LOCK is locked}
    end;

  {   The following structure should be considered opaque except in the module
  *   REND_STDIN.
  }
  rend_stdin_t = record                {state for handling standard input events}
    line: string_var8192_t;            {line read from STDIN}
    evbreak: sys_sys_event_id_t;       {aborts wait of input thread}
    evstopped: sys_sys_event_id_t;     {signalled when thread stops}
    hline: boolean;                    {a STDIN input line is in LINE}
    on: boolean;                       {STDIN events enabled, thread running}
    end;

var (rend2)
  rend_mem_context_p: util_mem_context_p_t; {pnt to top level RENDlib mem context}
  rend_evglb: rend_evglb_t;            {set of all requested global events}
  rend_device:                         {top level data about each device}
    array[1..rend_max_devices] of rend_device_t;
  rend_evq: rend_evqueue_t;            {events queue}
  rend_stdin: rend_stdin_t;            {STDIN handling state}
{
*   Subroutine entry points.  These are private routines used by RENDlib
*   internally.
}
procedure rend_cache_clip_2dim;        {cache 2DIM clip if resolves to one rectangle}
  extern;

procedure rend_config_vert3d;          {set REND_VERT3D_BYTES value from curr state}
  extern;

procedure rend_context_to_state (      {copy context block to current state}
  in      context: rend_context_t);    {context block to copy from}
  extern;

procedure rend_dev_save;               {copy curr device state into save area}
  extern;

function rend_event_pointer_move (     {handle 2D pointer motion}
  in      dev: sys_int_machine_t;      {RENDlib device where pointer moved}
  in      newx, newy: sys_int_machine_t) {new 2D pointer coordinates}
  :boolean;                            {TRUE if an event actually enqueued}
  val_param; extern;

procedure rend_evqueue_add (           {add event to end of queue}
  out     queue: rend_evqueue_t;       {the queue to add event to}
  in      event: rend_event_t);        {event to add}
  val_param; extern;

procedure rend_evqueue_add_unlock (    {add event to queue, release queue lock}
  out     queue: rend_evqueue_t;       {the queue to add event to}
  in      event: rend_event_t);        {event to add}
  val_param; extern;

procedure rend_evqueue_dealloc (       {deallocate resources of event queue}
  in out  queue: rend_evqueue_t);      {the queue, returned unusable}
  val_param; extern;

procedure rend_evqueue_get (           {get next event}
  in out  queue: rend_evqueue_t;       {queue to get event from}
  out     event: rend_event_t;         {returned event}
  in      wait: boolean);              {returns NONE event when FALSE and no event}
  val_param; extern;

procedure rend_evqueue_init (          {initialize a event queue}
  out     queue: rend_evqueue_t;       {the queue to initialize}
  in out  mem: util_mem_context_t);    {parent memory context}
  val_param; extern;

procedure rend_evqueue_last_lock (     {get last event, lock the queue}
  in out  queue: rend_evqueue_t;       {queue to get last event of}
  out     ev_p: rend_event_p_t);       {pointer to last event in queue, NIL = none}
  val_param; extern;

procedure rend_evqueue_push (          {add event to start of queue}
  out     queue: rend_evqueue_t;       {the queue to add event to}
  in      event: rend_event_t);        {event to add}
  val_param; extern;

procedure rend_evqueue_unlock (        {release caller lock on queue}
  in out  queue: rend_evqueue_t);      {queue to release lock on}
  val_param; extern;

procedure rend_get_all_prim_access (   {get worst case access flags for all prims}
  out     sw_read: rend_access_k_t;    {SW read access, use REND_ACCESS_xxx_K}
  out     sw_write: rend_access_k_t);  {SW write access, use REND_ACCESS_xxx_K}
  extern;

procedure rend_get_prim_access (       {resolve inherited primitive access flags}
  in out  prim_data: rend_prim_data_t; {data block for specific primitive}
  out     sw_read: rend_access_k_t;    {SW read access, use REND_ACCESS_xxx_K}
  out     sw_write: rend_access_k_t);  {SW write access, use REND_ACCESS_xxx_K}
  extern;

procedure rend_install_prim (          {install primitive into call table}
  in out  prim_data: rend_prim_data_t; {specific data block for this primitive}
  out     call_p: univ_ptr);           {where to put the entry point address}
  extern;

procedure rend_make_xf3d_vrad;         {update VRAD... fields in REND_XF3D}
  extern;

procedure rend_open_screen (           {open SCREEN RENDlib inherent device}
  in      devname: univ string_var_arg_t; {RENDlib inherent device name}
  in      parms: univ string_var_arg_t; {paramters string}
  out     stat: sys_err_t);            {completion status code}
  extern;

procedure rend_open_window (           {open WINDOW RENDlib inherent device}
  in      devname: univ string_var_arg_t; {RENDlib inherent device name}
  in      parms: univ string_var_arg_t; {paramters string}
  out     stat: sys_err_t);            {completion status code}
  extern;

procedure rend_prim_restore_sw (       {restore call table entry to software version}
  out     call_p: univ_ptr);           {call table entry pointing to subroutine entry}
  extern;

procedure rend_reset_call_tables;      {load all the call tables with illegal values}
  extern;

procedure rend_state_to_context (      {copy current state to context block}
  in out  context: rend_context_t);    {context block to copy into}
  extern;

procedure rend_stdin_close (           {end STDIN reading, deallocate resources}
  in out  stdin: rend_stdin_t);        {state to deallocate resources of}
  val_param; extern;

procedure rend_stdin_get (             {get STDIN line, only valid after event}
  in out  stdin: rend_stdin_t;         {STDIN reading state}
  in out  line: univ string_var_arg_t); {returned STDIN line}
  val_param; extern;

procedure rend_stdin_init (            {init STDIN state}
  out     stdin: rend_stdin_t);        {state to initialize}
  val_param; extern;

procedure rend_stdin_off (             {disable STDIN events}
  in out  stdin: rend_stdin_t);        {STDIN reading state}
  val_param; extern;

procedure rend_stdin_on (              {enable STDIN events}
  in out  stdin: rend_stdin_t);        {STDIN reading state}
  val_param; extern;

procedure rend_vert3d_ind_adr (        {get adr of 3D vertex entry index}
  in      entry_type: rend_vert3d_ent_vals_t; {ID for particular entry type}
  out     ind_p: sys_int_machine_p_t); {pointer to 3D vertex index value}
  extern;
{
*   Initialization routines for the various layered device drivers.
}
procedure rend_x_init (                {device is an X window}
  in      dev_name: univ string_var_arg_t; {RENDlib inherent device name}
  in      parms: univ string_var_arg_t; {parameters passed from application}
  out     stat: sys_err_t);            {error return code}
  extern;

procedure rend_dbuf_init (             {device is a .DBUF file}
  in      dev_name: univ string_var_arg_t; {RENDlib inherent device name}
  in      parms: univ string_var_arg_t; {parameters passed from application}
  out     stat: sys_err_t);            {error return code}
  extern;

procedure rend_tga_init (              {device is Truevision Targa+ board}
  in      dev_name: univ string_var_arg_t; {RENDlib inherent device name}
  in      parms: univ string_var_arg_t; {parameters passed from application}
  out     stat: sys_err_t);            {error return code}
  extern;

procedure rend_fgen_init (             {device is DN10000VS genlock video out}
  in      dev_name: univ string_var_arg_t; {RENDlib inherent device name}
  in      parms: univ string_var_arg_t; {parameters passed from application}
  out     stat: sys_err_t);            {error return code}
  extern;

procedure rend_fang_init (             {device is DN10000VS native hardware}
  in      dev_name: univ string_var_arg_t; {RENDlib inherent device name}
  in      parms: univ string_var_arg_t; {parameters passed from application}
  out     stat: sys_err_t);            {error return code}
  extern;

procedure rend_gpr_init (              {device is Apollo GPR library calls}
  in      dev_name: univ string_var_arg_t; {RENDlib inherent device name}
  in      parms: univ string_var_arg_t; {parameters passed from application}
  out     stat: sys_err_t);            {error return code}
  extern;

procedure rend_gmr_init (              {device is Apollo GMR and GPR library calls}
  in      dev_name: univ string_var_arg_t; {RENDlib inherent device name}
  in      parms: univ string_var_arg_t; {parameters passed from application}
  out     stat: sys_err_t);            {error return code}
  extern;

%include 'rend_sw.ins.pas';
