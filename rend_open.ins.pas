{   This include file implements the system-dependent part the user-visible
*   routine REND_OPEN.
*
*   This is the "generic" version that only knows about the standard set
*   of drivers that are available on all systems.
*
*   Local subroutine OPEN_RAW
*
*   This subroutine takes no formal call arguments, but accesses the following
*   symbols from the parent routine REND_OPEN:
*
*     STAT  -  Set to indicate completion status of OPEN_RAW.
*
*     DEVNAME_RAW  -  Name of inherent RENDlib device to open.
*
*     PARMS  -  String of optional parameter information for the specific
*       device driver.
}
const
  max_msg_parms = 1;                   {max parameters we can pass to a message}

var
  pick: sys_int_machine_t;             {number of token picked from list}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;

begin
  sys_error_none (stat);               {init to no error occurred}
  string_tkpick80 (devname_raw,
    'NONE SW WINDOW SCREEN',
    pick);
  case pick of
{
*   NONE
}
1: begin
  sys_stat_set (rend_subsys_k, rend_stat_no_device_k, stat); {dev doesn't exist}
  end;
{
*   SW
}
2: begin
  rend_sw_init (devname_raw, parms, stat);
  end;
{
*   WINDOW
}
3: begin
  rend_open_window (devname_raw, parms, stat);
  end;
{
*   SCREEN
}
4: begin
  rend_open_screen (devname_raw, parms, stat);
  end;

(*
{
*   DBUF
}
5: begin
  rend_dbuf_init (devname_raw, parms, stat);
  end;
*)

{
*   Unrecognized RENDlib native device name.
}
otherwise
    sys_msg_parm_vstr (msg_parm[1], devname_raw);
    sys_message_bomb ('rend', 'rend_dev_name_bad', msg_parm, 1);
    end;                               {end of native device type cases}
  end;
