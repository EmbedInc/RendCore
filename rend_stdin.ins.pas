{   Include file used only by the REND_STDIN module, and the various
*   system-dependent REDN_STDIN_SYS modules.
}
type
  rend_stdin_t = record                {state for handling standard input events}
    line: string_var8192_t;            {line read from STDIN}
    evbreak: sys_sys_event_id_t;       {aborts wait of input thread}
    evstopped: sys_sys_event_id_t;     {signalled when thread stops}
    hline: boolean;                    {a STDIN input line is in LINE}
    on: boolean;                       {STDIN events enabled, thread running}
    end;

procedure rend_stdin_sys_close (       {deallocate system-dependent STDIN resources}
  in out  stdin: rend_stdin_t);        {STDIN reading state}
  val_param; extern;

procedure rend_stdin_sys_init (        {initialize the system-dependent part}
  in out  stdin: rend_stdin_t);        {STDIN reading state}
  val_param; extern;
