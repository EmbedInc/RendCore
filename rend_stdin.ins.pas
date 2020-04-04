{   Include file used only by the REND_STDIN module, and the various
*   system-dependent REDN_STDIN_SYS modules.
}
type
  rend_stdin_p_t = ^rend_stdin_t;
  rend_stdin_t = record                {state for handling standard input events}
    line: string_var8192_t;            {line read from STDIN}
    hline: boolean;                    {a STDIN input line is in LINE}
    on: boolean;                       {STDIN events enabled, thread running}
    end;

procedure rend_stdin_sys_close (       {deallocate system-dependent STDIN resources}
  in out  stdin: rend_stdin_t);        {STDIN reading state}
  val_param; extern;

procedure rend_stdin_sys_gotline (     {notify that the STDIN line was read}
  in out  stdin: rend_stdin_t);        {STDIN reading state}
  val_param; extern;

procedure rend_stdin_sys_init (        {initialize the system-dependent part}
  in out  stdin: rend_stdin_t);        {STDIN reading state}
  val_param; extern;

procedure rend_stdin_sys_off (         {stop STDIN reading}
  in out  stdin: rend_stdin_t);        {STDIN reading state}
  val_param; extern;

procedure rend_stdin_sys_on (          {start STDIN reading}
  in out  stdin: rend_stdin_t);        {STDIN reading state}
  val_param; extern;
