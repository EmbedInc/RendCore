{   Events queue structure handling.  The event queue is private to this module.
*   The rest of the system interfaces with the event via the routines exported
*   here.
}
module rend_evqueue;
define rend_evqueue_init;
define rend_evqueue_dealloc;
define rend_evqueue_add;
define rend_evqueue_push;
define rend_evqueue_get;
define rend_evqueue_last_lock;
define rend_evqueue_add_unlock;
define rend_evqueue_unlock;
%include 'rend2.ins.pas';

type
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

var
  queue: rend_evqueue_t;               {events queue}
{
********************************************************************************
*
*   Local function ENTRY_GET
*
*   Returns a pointer to a available queue entry.  The entry will not be
*   enqueued, nor will it be on the free list.
*
*   If a free entry is available, it will be returned.  Otherwise, a new entry
*   is allocated.
}
function entry_get                     {get pointer to available queue entry}
  :rend_evq_ent_p_t;                   {pointer to new available queue entry}
  val_param; internal;

var
  ent_p: rend_evq_ent_p_t;             {pointer to the new queue entry}

begin
  sys_thread_lock_enter (queue.lock);  {acquire lock on queue structures}
  if queue.free_p = nil
    then begin                         {no available free entry}
      sys_thread_lock_leave (queue.lock); {done with queue structures}
      util_mem_grab (                  {allocate new queue entry}
        sizeof(ent_p^), queue.mem_p^, false, ent_p);
      end
    else begin                         {a free entry is available}
      ent_p := queue.free_p;           {get pointer to first free entry}
      queue.free_p := ent_p^.next_p;   {update start of free list pointer}
      sys_thread_lock_leave (queue.lock); {done with queue structures}
      end
    ;
  entry_get := ent_p;                  {return pointer to the new entry}
  end;
{
********************************************************************************
*
*   Local subroutine ENTRY_FREE (ENT)
*
*   Release the queue entry ENT.  The entry will be placed on the free entries
*   list, and must not be used anymore by the caller.
}
procedure entry_free (                 {release queue entry onto free list}
  in out  ent: rend_evq_ent_t);        {the entry to release}
  val_param; internal;

begin
  sys_thread_lock_enter (queue.lock);  {acquire lock on queue structures}
  ent.next_p := queue.free_p;          {link entry to rest of free list}
  queue.free_p := addr(ent);           {update start of free list pointer}
  sys_thread_lock_leave (queue.lock);  {done with queue structures}
  end;
{
********************************************************************************
*
*   Subroutine REND_EVQUEUE_INIT (MEM)
*
*   Initialize the event queue.  MEM is the parent memory context.  A
*   subordinate context will be created for the queue.
}
procedure rend_evqueue_init (          {initialize a event queue}
  in out  mem: util_mem_context_t);    {parent memory context}
  val_param;

var
  stat: sys_err_t;

begin
  util_mem_context_get (mem, queue.mem_p); {create mem context for the queue}
  sys_thread_lock_create (queue.lock, stat); {create mutex for accessing queue}
  sys_error_abort (stat, '', '', nil, 0);
  queue.first_p := nil;
  queue.last_p := nil;
  queue.free_p := nil;
  sys_event_create_bool (queue.newev);
  end;
{
********************************************************************************
*
*   Subroutine REND_EVQUEUE_DEALLOC
*
*   Deallocate system resources associated with the events queue QUEUE.  The
*   queue will not be usable until it is re-initialized.
}
procedure rend_evqueue_dealloc;        {deallocate resources of event queue}
  val_param;

var
  stat: sys_err_t;

begin
  util_mem_context_del (queue.mem_p);  {deallocate all dynamic memory}
  sys_thread_lock_delete (queue.lock, stat); {delete queue structures mutex}
  sys_error_abort (stat, '', '', nil, 0);
  sys_event_del_bool (queue.newev);    {delete the system event}
  end;
{
********************************************************************************
*
*   Subroutine REND_EVQUEUE_ADD (EVENT)
*
*   Add the event EVENT to the end of the queue QUEUE.
}
procedure rend_evqueue_add (           {add event to end of queue}
  in      event: rend_event_t);        {event to add}
  val_param;

var
  ent_p: rend_evq_ent_p_t;             {pointer to new queue entry}

begin
  ent_p := entry_get;                  {get pointer to new queue entry}
  ent_p^.event := event;               {copy the event data into the queue entry}
  ent_p^.next_p := nil;                {this entry will be at end of list}

  sys_thread_lock_enter (queue.lock);  {acquire lock on queue structures}
  if queue.last_p = nil
    then begin                         {no previous queue entry}
      queue.first_p := ent_p;
      end
    else begin                         {link new entry after previous}
      queue.last_p^.next_p := ent_p;
      end
    ;
  queue.last_p := ent_p;               {update pointer to last queue entry}
  sys_event_notify_bool (queue.newev); {now definitely event in the queue}
  sys_thread_lock_leave (queue.lock);  {done with queue structures}
  end;
{
********************************************************************************
*
*   Subroutine REND_EVQUEUE_PUSH (EVENT)
*
*   Add the event EVENT to the start of the queue QUEUE.
}
procedure rend_evqueue_push (          {add event to start of queue}
  in      event: rend_event_t);        {event to add}
  val_param;

var
  ent_p: rend_evq_ent_p_t;             {pointer to new queue entry}

begin
  ent_p := entry_get;                  {get pointer to new queue entry}
  ent_p^.event := event;               {copy the event data into the queue entry}

  sys_thread_lock_enter (queue.lock);  {acquire lock on queue structures}
  ent_p^.next_p := queue.first_p;      {link to next queue entry}
  queue.first_p := ent_p;              {update pointer to first entry in queue}
  if queue.last_p = nil then begin     {pointer to last entry not set ?}
    queue.last_p := ent_p;             {set it}
    end;
  sys_event_notify_bool (queue.newev); {now definitely event in the queue}
  sys_thread_lock_leave (queue.lock);  {done with queue structures}
  end;
{
********************************************************************************
*
*   Subroutine REND_EVQUEUE_GET (EVENT, WAIT)
*
*   Get the next event from the queue.
*
*   When WAIT is TRUE, this routine will wait indefinitely for an event to be
*   available, then return that event.
*
*   When WAIT is FALSE, this routine always returns immediately.  If no event
*   is immediately available, then EVENT is returned indicating event type NONE.
}
procedure rend_evqueue_get (           {get next event}
  out     event: rend_event_t;         {returned event}
  in      wait: boolean);              {returns NONE event when FALSE and no event}
  val_param;

var
  ent_p: rend_evq_ent_p_t;             {pointer to queue entry}
  stat: sys_err_t;

label
  retry;

begin
retry:                                 {back here on notified after waiting}
{
*   Return the first queue entry, if it exists.
}
  sys_thread_lock_enter (queue.lock);  {acquire lock on queue structures}

  if queue.first_p <> nil then begin   {a entry is immediately available ?}
    ent_p := queue.first_p;            {get pointer to the entry}
    queue.first_p := ent_p^.next_p;    {unlink this entry from the queue}
    if queue.first_p = nil then begin  {just removed last entry from queue ?}
      queue.last_p := nil;
      end;
    sys_thread_lock_leave (queue.lock); {done with queue structures}

    event := ent_p^.event;             {return the event from this entry}
    entry_free (ent_p^);               {this entry is now free}
    return;
    end;

  sys_thread_lock_leave (queue.lock);  {done with queue structures}
{
*   The queue is empty.
}
  if not wait then begin               {return immediately ?}
    event.dev := rend_dev_none_k;      {set the event to NONE}
    event.ev_type := rend_ev_none_k;
    return;
    end;
{
*   Wait for something to be added to the queue.
}
  sys_event_wait (queue.newev, stat);  {wait for entry added to queue}
  sys_error_abort (stat, '', '', nil, 0);
  goto retry;                          {back to check for event in queue again}
  end;
{
********************************************************************************
*
*   Subroutine REND_EVQUEUE_LAST_LOCK (EV_P)
*
*   Return a pointer to the last event in the queue and lock the queue.  EV_P is
*   returned pointing to the last event when there is one, NIL otherwise.
*
*   The queue is locked in either case.  This prevents events from being
*   asynchronously added to or removed from the queue.  The caller must release
*   the lock "quickly" by calling one of the following routines:
*
*     REND_EVQUEUE_UNLOCK  -  Explicitly releases the lock on the queue.  It is
*       permissible for the caller to modify the event pointed to by EV_P while
*       the lock is held.
*
*     REND_EVQUEUE_ADD_UNLOCK  -  Add a new event at the end of the queue, then
*       release the lock.  This guarantees that the new event will immediately
*       follow the event pointed to by EV_P.
}
procedure rend_evqueue_last_lock (     {get last event, lock the queue}
  out     ev_p: rend_event_p_t);       {pointer to last event in queue, NIL = none}
  val_param;

begin
  sys_thread_lock_enter (queue.lock);  {acquire lock on queue structures}
  queue.locked := true;                {indicate now locked by caller}
  if queue.last_p = nil
    then begin                         {the queue is empty}
      ev_p := nil;
      end
    else begin                         {there is at least one event}
      ev_p := addr(queue.last_p^.event); {return pointer to the last event}
      end
    ;
  end;
{
********************************************************************************
*
*   Subroutine REND_EVQUEUE_ADD_UNLOCK (EVENT)
*
*   Add a new event to the end of the queue, and release the lock acquired with
*   REND_EVQUEUE_LAST_LOCK.
}
procedure rend_evqueue_add_unlock (    {add event to queue, release queue lock}
  in      event: rend_event_t);        {event to add}
  val_param;

var
  ent_p: rend_evq_ent_p_t;             {pointer to new queue entry}

begin
  if not queue.locked then return;     {ignore if queue not locked by caller}

  if queue.free_p = nil
    then begin                         {no available free entry}
      util_mem_grab (                  {allocate new queue entry}
        sizeof(ent_p^), queue.mem_p^, false, ent_p);
      end
    else begin                         {a free entry is available}
      ent_p := queue.free_p;           {get pointer to first free entry}
      queue.free_p := ent_p^.next_p;   {update start of free list pointer}
      end
    ;
  ent_p^.next_p := nil;                {this entry will be at end of queue}
  ent_p^.event := event;               {save the event in the new queue entry}

  if queue.last_p = nil
    then begin                         {no previous queue entry}
      queue.first_p := ent_p;
      end
    else begin                         {link new entry after previous}
      queue.last_p^.next_p := ent_p;
      end
    ;
  queue.last_p := ent_p;               {update pointer to last queue entry}
  sys_event_notify_bool (queue.newev); {now definitely event in the queue}
  queue.locked := false;               {caller will no longer hold the lock}
  sys_thread_lock_leave (queue.lock);  {release the lock}
  end;
{
********************************************************************************
*
*   Subroutine REND_EVQUEUE_UNLOCK
*
*   Release the lock on the queue acquired with REND_EVQUEUE_LAST_LOCK.
}
procedure rend_evqueue_unlock;         {release caller lock on queue}
  val_param;

begin
  if not queue.locked then return;     {queue not locked by caller ?}

  queue.locked := false;               {caller will no longer hold the lock}
  sys_thread_lock_leave (queue.lock);  {release the lock}
  end;
