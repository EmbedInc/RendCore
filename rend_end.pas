{   Subroutine REND_END
*
*   Completely end a RENDlib session.  All devices are closed, and all memory
*   that was allocated with RENDlib will be released.
}
module rend_end;
define rend_end;
%include 'rend2.ins.pas';

procedure rend_end;

var
  dev: sys_int_machine_t;              {current device ID}

begin
  for dev := rend_max_devices downto 1 do begin {once for each possible device}
    if not rend_device[dev].open then next; {no device here ?}
    rend_dev_set (dev);                {make this device current}
    rend_set.close^;                   {close this device}
    end;                               {back and process next device}

  rend_stdin_close;                    {release STDIN handling resources}
  rend_evqueue_dealloc;                {release events queue resources}

  if rend_mem_context_p <> nil then begin
    util_mem_context_del (rend_mem_context_p); {release all RENDlib dynamic memory}
    end;
  end;
