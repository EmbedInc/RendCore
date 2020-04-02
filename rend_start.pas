{   Subroutine REND_START
*
*   This MUST be the first call to RENDlib for each application.  It initializes
*   all the RENDlib state that is not associated with particular drivers.
}
module rend_start;
define rend_start;
%include 'rend2.ins.pas';

procedure rend_start;

var
  ii: sys_int_machine_t;               {loop counter and scratch integer}

begin
  util_mem_context_get (               {create RENDlib top memory allocation context}
    util_top_mem_context,              {parent context}
    rend_mem_context_p);               {returned pointing to new context descriptor}

  rend_evglb := [];

  for ii := 1 to rend_max_devices do begin {once for each device descriptor}
    rend_device[ii].open := false;     {indicate this device closed}
    end;

  rend_evqueue_init (rend_evq, rend_mem_context_p^); {init events queue}

  rend_stdin_init (rend_stdin);        {init STDIN management state}

  rend_dev_id := 0;                    {init current device ID to none}
  rend_reset_call_tables;              {init call tables to invalid values}
  end;
