{   Private include file for all REND routines.  All the data structures and
*   entry points that are private and deal with the layer above the device drivers
*   are here.
*
*   About RENDlib's top level:
*
*     RENDlib's top level is a layer above any particular device drivers.  The
*     common block defined here always contains valid data after the REND_START
*     call, whether any device has been opened or not.  One important reason that
*     RENDlib needs to know about all graphics connections that have been opened
*     is for proper handling of asynchronous events, such as window shakeups.
*     An asynchonous event may happen when the RENDlib context for that device
*     is swapped out.  Therefore, a top layer needs to be able to save the current
*     state, identify and swap in the state of the device with the event, call
*     the user, restore the state, and return.  This can only be done if some
*     global state exists for all the devices.  This include file declares the
*     common block and associated information for that global state.
*     NOTE:  Only the bare minimum device state that really needs to be visible
*     about a swapped out device should be kept here.  Any other per-device
*     state should go either in REND_SW.INS.PAS if it is needed for all devices,
*     or in REND_xxx.ins.pas if it is specific to a particular device.
*
*   About RENDlib memory allocation:
*
*     RENDlib occasionally needs to dynamically allocate memory, either for internal
*     reasons or directly due to a user request.  This memory can be allocated
*     from different scopes: system, RENDlib top level, or a specific RENDlib
*     open device.  See the constants REND_SCOPE_xxx_K in REND.INS.PAS.
*     The effective difference between these is when, if ever, RENDlib will
*     automatically deallocate this memory.  System memory is never automatically
*     deallocated by RENDlib.  RENDlib top level memory is assumed to have a scope
*     tied to the current RENDlib invocation, but above any specific device.
*     An example might be a RENDlib bitmap that is shared between devices.  Such
*     memory is automatically deallocated when REND_END is called.  RENDlib device
*     memory is assumed to be associated only with a particular device, and is
*     therefore automatically deallocated when REND_SET.CLOSE is called.
}
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'img.ins.pas';
%include 'vect.ins.pas';
%include 'ray_kernel.ins.pas';
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

  rend_event_check_p_t = ^function (   {device routine used to check for events}
    in    wait: boolean)               {wait for event when TRUE}
    :boolean;                          {TRUE if event returned}
    val_param;

  rend_device_t = record               {permanent data about each device}
    save_area_p: rend_context_p_t;     {handle to current context when swapped out}
    mem_p: util_mem_context_p_t;       {pnt to memory context for this device}
    ev_check: rend_event_check_p_t;    {points to event check routine, may be NIL}
    keys_enab: sys_int_machine_t;      {number of individual keys enabled for events}
    keys_max: sys_int_machine_t;       {number of allocated key desc in KEYS_P^}
    keys_n: sys_int_machine_t;         {number of actual keys in KEYS_P^}
    keys_p: rend_key_ar_p_t;           {points to array of key descriptors}
    ev_req: rend_evdev_t;              {mask for all the requested event types}
    scale_3drot: real;                 {scale factor for 3D rotation events}
    pnt_x, pnt_y: sys_int_machine_t;   {current 2D pointer coordinates}
    pnt_mode: rend_pntmode_k_t;        {2D pointer motion interpretation}
    ev_wiped_resize: boolean;          {TRUE if WIPED_RESIZE event pending to user}
    ev_changed: boolean;               {event configuration state changed}
    open: boolean;                     {TRUE if device is open}
    end;

  rend_evqueue_entry_p_t =             {pointer to an event queue entry}
    ^rend_evqueue_entry_t;

  rend_evqueue_entry_t = record        {template for one event queue entry}
    next_p: rend_evqueue_entry_p_t;    {points to next entry in queue}
    event: rend_event_t;               {actual event data}
    end;

var (rend2)
  rend_event_retry_wait: real;         {seconds to wait before look for event again}
  rend_n_evcheck: sys_int_machine_t;   {number of active event check routines}
  rend_evcheck:                        {list of the active event check routines}
    array[1..rend_max_devices] of rend_event_check_p_t;
  rend_evglb: rend_evglb_t;            {set of all requested global events}
  rend_device:                         {top level data about each device}
    array[1..rend_max_devices] of rend_device_t;
  rend_mem_context_p: util_mem_context_p_t; {pnt to top level RENDlib mem context}
  rend_evqueue_first_p: rend_evqueue_entry_p_t; {pnt to first entry in event queue}
  rend_evqueue_last_p: rend_evqueue_entry_p_t; {pnt to last entry in event queue}
  rend_evqueue_free_p: rend_evqueue_entry_p_t; {pnt to chain of unused queue entries}
  rend_stdin_done: boolean;            {a complete line is in REND_STDIN_LINE}
  rend_stdin_line: string_var8192_t;   {current input line from standard input}
  rend_qlock: sys_sys_threadlock_t;    {single thread interlock for event queue}
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

procedure rend_dev_evcheck_set (       {set event check routine for current device}
  in      proc: rend_event_check_p_t); {pointer to event check routine, may be NIL}
  val_param; extern;

procedure rend_dev_save;               {copy curr device state into save area}
  extern;

procedure rend_dummy0;                 {dummy routine that takes no call args}
  extern;

function rend_event_pointer_move (     {handle 2D pointer motion}
  in      dev: sys_int_machine_t;      {RENDlib device where pointer moved}
  in      newx, newy: sys_int_machine_t) {new 2D pointer coordinates}
  :boolean;                            {TRUE if an event actually enqueued}
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
