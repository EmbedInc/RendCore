{   Subroutine REND_SW_GET_WAIT_EXIT
*
*   Wait for the user to indicate he wants to exit the program.  The exact
*   action may be system-dependent.
*
*   If there is no common customary way for a user to indicate a graphics
*   program should exit (and thereby probably corrupt or delete what it
*   displayed), then we recommend that this routine wait for the RETURN
*   key to be pressed.
*
*   This is the default version of this routine, and gets used whenever
*   a suitable branch is not present.
}
module rend_sw_get_wait_exit;
define rend_sw_get_wait_exit;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_wait_exit (      {wait for user to request program exit}
  in      flags: rend_waitex_t);       {set of flags REND_WAITEX_xxx_K}
  val_param;

var
  fnam: string_var80_t;                {generic name of message file}
  msg: string_var80_t;                 {name of message within file}
  conn: file_conn_t;                   {connection handle to the message}
  event: rend_event_t;                 {RENDlib event descriptor}
  stat: sys_err_t;

label
  done_msg, event_wait;

begin
  fnam.max := sizeof(fnam.str);        {init local var strings}
  msg.max := sizeof(msg.str);

  if rend_waitex_msg_k in flags then begin {print message before waiting ?}
    string_vstring (fnam, 'rend', 4);
    string_vstring (msg, 'rend_wait_exit_return'(0), -1);
    file_open_read_msg (fnam, msg, nil, 0, conn, stat);
    if sys_error(stat) then goto done_msg;
    file_read_msg (conn, msg.max, msg, stat); {read first line of message only}
    if sys_error(stat) then goto done_msg;
    file_close (conn);                 {close this message}
    string_append1 (msg, ' ');         {add separator after message}
    string_prompt (msg);               {write the message}
    end;
done_msg:                              {all done writing the message}

  rend_set.events_req_off^;            {disable all events}
  rend_set.event_req_close^ (true);    {enable the events we want}
  rend_event_req_stdin_line (true);

event_wait:
  rend_event_get (event);              {get the next event}
  case event.ev_type of                {what kind of event is it ?}

rend_ev_close_k,                       {drawing device was closed externally}
rend_ev_close_user_k: begin            {user asked us to close use of draw device}
      if rend_waitex_msg_k in flags then begin {we wrote a prompt earlier ?}
        writeln;                       {don't leave hanging unterminated prompt}
        end;
      return;
      end;

rend_ev_stdin_line_k: begin            {a new line of text is available from STDIN}
      return;
      end;

    end;                               {end of event type cases}
  goto event_wait;                     {back and wait for next event}
  end;
