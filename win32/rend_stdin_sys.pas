{   System  dependent part of STDIN handling.
*
*   This version is for the Win32 API.
}
module rend_stdin_sys;
define rend_stdin_sys_init;
define rend_stdin_sys_close;
define rend_stdin_sys_on;
define rend_stdin_sys_gotline;
define rend_stdin_sys_off;
%include 'rend2.ins.pas';
%include 'rend_stdin.ins.pas';
%include 'sys_sys2.ins.pas';

const
  cr_k = 13;                           {carriage return character code}
  lf_k = 10;                           {line feed character code}

  nwait = 2;                           {number of events to wait on}
  maxwait = nwait - 1;                 {max WAITLIST array index}

  waitid_io = 0;                       {waitlist entry for I/O complete}
  waitid_wake = 1;                     {waitlist entry for thread wakeup}

var
  ovl: overlap_t;                      {overlapped I/O state}
  ibuf: string_var80_t;                {STDIN input buffer}
  ibufr: sys_int_machine_t;            {IBUF index of next byte to retur}
  stdin_h: win_handle_t;               {handle to STDIN stream}
  waitlist:                            {list of events to wait on for I/O complete}
    array [0..maxwait] of win_handle_t;
  evbreak: sys_sys_event_id_t;         {aborts wait of input thread}
  evstopped: sys_sys_event_id_t;       {signalled when thread stops}
{
********************************************************************************
*
*   Function STDINBYTE (STDIN, B)
*
*   Read the next byte from STDIN.  This routine waits indefinitely until there
*   is a STDIN byte, or the thread has been told to stop.  The function is TRUE
*   when returning with a byte, and FALSE if the thread is supposed to stop.
}
function stdinbyte (                   {get next STDIN byte}
  in out  stdin: rend_stdin_t;         {STDIN reading state}
  out     b: sys_int_machine_t)        {0-255 byte value}
  :boolean;                            {returning with byte, not thread stop}
  val_param; internal;

var
  ok: win_bool_t;                      {completion status of some Windows functions}
  nread: win_dword_t;                  {number of bytes actually read}
  err: sys_sys_err_t;                  {error code}
  donewait: donewait_k_t;              {reason wait completed}

label
  rewait;

begin
  stdinbyte := false;                  {init to not returning with a byte}
  if not stdin.on then return;         {thread told to shut down ?}

  while ibufr > ibuf.len do begin      {keep reading until something to return}
    ok := ReadFile (                   {start read next chunk from STDIN}
      stdin_h,                         {handle to the stream}
      ibuf.str,                        {buffer to receive the data}
      ibuf.max,                        {max number of bytes to read}
      nread,                           {number of bytes actually read}
      addr(ovl));                      {pointer to overlapped I/O state}
    if not stdin.on then return;       {thread told to shut down ?}
    if ok = win_bool_false_k then begin {didn't just complete normally ?}
      err := GetLastError;             {get the reason why}
      if err <> err_io_pending_k       {hard error ?}
        then return;
rewait:
      writeln ('WaitForMultiplObjects');
      donewait := WaitForMultipleObjects ( {sleep until something to do}
        nwait,                         {number of events to wait on}
        waitlist,                      {list of events to wait on}
        win_bool_false_k,              {wait for any, not all}
        timeout_infinite_k);           {no timeout, wait as long as it takes}
      if not stdin.on then return;     {thread told to shut down ?}
      if ord(donewait) = waitid_wake   {deliberate wakeup with nothing do to ?}
        then goto rewait;
      if ord(donewait) <> waitid_io then return; {other than I/O completed ?}
      ok := GetOverlappedResult (      {get result of STDIN read}
        stdin_h,                       {handle read in progress on}
        ovl,                           {overlapped I/O state}
        nread,                         {number of bytes actually read}
        win_bool_true_k);              {wait for I/O complete (should already be)}
      if ok = win_bool_false_k then return; {hard error ?}
      end;                             {I/O has now completed}

    if nread = 0 then return;          {STDIN doesn't exist ?}
    ibuf.len := nread;                 {indicate number of bytes now in buffer}
    ibufr := 1;                        {reset read index to start of buffer}
    end;

  b := ord(ibuf.str[ibufr]);           {return the next byte}
  ibufr := ibufr + 1;                  {update the read index for next time}
  stdinbyte := true;                   {returning with a byte}
  end;
{
********************************************************************************
*
*   Function STDIN_THREAD (STDIN_P)
*
*   This function is run in a separate thread. It reads from STDIN and creates
*   STDIN events as appropriate.
}
function stdin_thread (                {STDIN reading thread routine}
  in   stdin_p: rend_stdin_p_t)        {pointer to STDIN reading state}
  :integer32;                          {return value, not used}
  val_param; internal;

var
  newb: sys_int_machine_t;             {character code of new byte}
  lastcr: boolean;                     {last character was CR}
  ev: rend_event_t;                    {STDIN line event}

label
  nextline, leave;

begin
  stdin_thread := 0;                   {set function value to keep compiler happy}
  ev.dev := rend_dev_none_k;           {fill in event for STDIN line}
  ev.ev_type := rend_ev_stdin_line_k;

nextline:                              {back here for each new STDIN line}
{
*   Wait until the previous STDIN line is used by the application.
}
  while stdin_p^.hline do begin        {wait until previous line is used}
    discard( WaitForSingleObject (evbreak, timeout_infinite_k) );
    if not stdin_p^.on then goto leave;
    end;

  stdin_p^.line.len := 0;              {reset the line to empty}
{
*   Read STDIN bytes into LINE until a end of line indication is encountered.
}
  lastcr := false;                     {init to previous char was not CR}
  while true do begin                  {back here each new character}
    if not stdinbyte (stdin_p^, newb) then goto leave; {get new byte into NEWB}
    if lastcr and (newb = lf_k)        {CR-LF ?}
      then exit;
    if lastcr then begin               {last char CR, but not followed by LF ?}
      string_append1 (stdin_p^.line, chr(cr_k));
      end;
    if newb = cr_k
      then begin                       {this char is CR}
        lastcr := true;
        end
      else begin                       {this char is not CR or CR-LF sequence}
        lastcr := false;               {last not CR for next time}
        string_append1 (stdin_p^.line, chr(newb)); {add this char to end of string}
        end
      ;
    end;                               {back to get next character}

  string_unpad (stdin_p^.line);        {remove trailing blanks from the STDIN line}
  stdin_p^.hline := true;              {indicate a STDIN line is available}
  rend_event_enqueue (ev);             {generate the STDIN line event}
  goto nextline;                       {back for next STDIN line}

leave:
  discard( SetEvent (evstopped) );     {signal that the thread has exited}
  end;
{
********************************************************************************
*
*   Subroutine REND_STDIN_SYS_INIT (STDIN)
*
*   Initialize any system-specific state related to reading STDIN.
}
procedure rend_stdin_sys_init (        {initialize the system-dependent part}
  in out  stdin: rend_stdin_t);        {STDIN reading state}
  val_param;

begin
  ovl.internal := 0;
  ovl.internal_high := 0;
  ovl.offset := 0;
  ovl.offset_high := 0;

  ovl.event_h := CreateEventA (
    nil,                               {pointer to security attributes, unused}
    win_bool_true_k,                   {manual, not auto, reset}
    win_bool_false_k,                  {initial state is not signalled}
    nil);                              {pointet to name, unused}

  ibuf.max := size_char(ibuf.str);     {init the input buffer state}
  ibuf.len := 0;
  ibufr := 1;

  stdin_h := GetStdHandle (stdstream_in_k); {get and save handle to STDIN stream}

  waitlist[waitid_io] := ovl.event_h;  {make list of events to wait for I/O complete}
  waitlist[waitid_wake] := evbreak;

  evbreak := CreateEventA (            {create event for waking up thread}
    nil,                               {pointer to security attributes, unused}
    win_bool_false_k,                  {auto reset}
    win_bool_false_k,                  {initial state is not signalled}
    nil);                              {pointet to name, unused}

  evbreak := CreateEventA (            {create event to indicate thread stopped}
    nil,                               {pointer to security attributes, unused}
    win_bool_false_k,                  {auto reset}
    win_bool_false_k,                  {initial state is not signalled}
    nil);                              {pointet to name, unused}
  end;
{
********************************************************************************
*
*   Subroutine REND_STDIN_SYS_CLOSE (STDIN)
*
*   Deallocate any system-dependent resources associated with reading STDIN.
*   This routine must only be called when the thread is not running.
}
procedure rend_stdin_sys_close (       {deallocate system-dependent STDIN resources}
  in out  stdin: rend_stdin_t);        {STDIN reading state}
  val_param;

begin
  discard( CloseHandle (ovl.event_h) ); {deallocate our private events}
  discard( CloseHandle (evbreak) );
  discard( CloseHandle (evstopped) );
  end;
{
********************************************************************************
*
*   Subroutine REND_STDIN_SYS_ON (STDIN)
*
*   Start STDIN reading.  This routine must only be called when reading is off.
}
procedure rend_stdin_sys_on (          {start STDIN reading}
  in out  stdin: rend_stdin_t);        {STDIN reading state}
  val_param;

var
  thread_h: win_handle_t;              {handle to the thread}
  thread_id: win_dword_t;              {ID of the new thread}

begin
  stdin.on := true;                    {STDIN will now be read}

  thread_h := CreateThread (           {start the STDIN reading thread}
    nil,                               {security info, not used}
    0,                                 {use default stack size}
    addr(stdin_thread),                {pointer to root thread routine}
    addr(stdin),                       {argument to thread routine}
    [],                                {option flags}
    thread_id);                        {returned thread ID}

  discard( CloseHandle (thread_h) );   {no future use for the thread handle}
  end;
{
********************************************************************************
*
*   Subroutine REND_STDIN_SYS_GOTLINE (STDIN)
*
*   This routine is called to inform the system-dependent STDIN module that the
*   current line in STDIN.LINE has been read by the application and marked as
*   no longer valid.  It is now permissible to get the next STDIN line into
*   STDIN.LINE.
}
procedure rend_stdin_sys_gotline (     {notify that the STDIN line was read}
  in out  stdin: rend_stdin_t);        {STDIN reading state}
  val_param;

begin
  discard( SetEvent (evbreak) );       {wake thread to see LINE is now unused}
  end;
{
********************************************************************************
*
*   Subroutine REND_STDIN_SYS_OFF (STDIN)
*
*   Stop STDIN reading.  This routine must only be called when reading is on.
}
procedure rend_stdin_sys_off (         {stop STDIN reading}
  in out  stdin: rend_stdin_t);        {STDIN reading state}
  val_param;

begin
  stdin.on := false;                   {tell thread to exit}

(* *******
*
*   To guarantee the thread will exist the blocking ReadFile call, the I/O
*   operation must be cancelled.  However, the CancelIoEx routine required to do
*   that is not supported in WinXP.  For now, to allow binaries to run on WinXP,
*   CancelIoEx will not be called.
*
  discard( CancelIoEx (stdin_h, addr(ovl)) ); {stop I/O so thread sees exit request}
*)

  discard( SetEvent (evbreak) );       {wake thread for it to see exit request}
  discard( SetEvent (ovl.event_h) );
  discard( SetEvent (stdin_h) );

  discard( WaitForSingleObject (       {wait for thread to actually exit}
    evstopped,                         {event to wait on}
    200) );                            {leave reasonable time, then give up}
  end;
