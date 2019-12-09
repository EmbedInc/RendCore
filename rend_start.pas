{   Subroutine REND_START
*
*   This MUST be the first call to RENDlib for each application.  It initializes
*   all the RENDlib state that is not associated with particular drivers.
}
module rend_start;
define rend_start;
%include 'rend2.ins.pas';

const
  retry_wait_default_k = 0.050;        {seconds wait before look for event again}

procedure rend_start;

var
  i: sys_int_machine_t;                {loop counter and scratch integer}
  stat: sys_err_t;

begin
  rend_event_retry_wait := retry_wait_default_k;
  rend_n_evcheck := 0;
  rend_evglb := [];
  sys_thread_lock_create (rend_qlock, stat); {make interlock for event queue}
  sys_error_abort (stat, 'rend', 'rend_qlock_create', nil, 0);

  for i := 1 to rend_max_devices do begin {once for each device descriptor}
    rend_device[i].open := false;      {indicate this device closed}
    end;

  util_mem_context_get (               {create RENDlib top memory allocation context}
    util_top_mem_context,              {parent context}
    rend_mem_context_p);               {returned pointing to new context descriptor}

  rend_evqueue_first_p := nil;         {init event queue to completely empty}
  rend_evqueue_last_p := nil;
  rend_evqueue_free_p := nil;

  rend_stdin_done := false;            {indicate no current STDIN line waiting}
  rend_stdin_line.max := sizeof(rend_stdin_line.str); {init STDIN line var string}
  rend_stdin_line.len := 0;            {init to no chars read from STDIN yet}

  rend_dev_id := 0;                    {init current device ID to none}
  rend_reset_call_tables;              {init call tables to invalid values}
  end;
