{   This is a template for programs to test Windows graphics.
}
program "gui" test_win;
%include 'base.ins.pas';
%include 'sys_sys2.ins.pas';
%include 'win.ins.pas';
%include 'win_keys.ins.pas';

const
  cmd_close_k = 0;                     {command ID to close window}
  n_accel_k = 1;                       {number of accelerator keys defined}

var
  window_class_name: string := 'TEST_WIN_CLASS'(0);
  wind_h: win_handle_t;                {handle to our drawing window}
  dc: win_handle_t;                    {handle to our drawing device context}
  dirty_x, dirty_y: sys_int_machine_t; {upper left corner of dirty rectangle}
  dirty_dx, dirty_dy: sys_int_machine_t; {size of dirty rectangle}
  wind_dx, wind_dy: sys_int_machine_t; {dimensions of drawing area in pixels}
  dirty: boolean;                      {TRUE if a dirty region exists}
  ready: boolean;                      {TRUE after first PAINT message received}

  s: string_var80_t;                   {scratch string}
  tk: string_var80_t;                  {scratch token}
  i: sys_int_machine_t;                {scratch integer}
  byte_p: ^int8u_t;                    {pointer to arbitrary memory byte}
  wclass: window_class_t;              {descriptor for our window class}
  atom_class: win_atom_t;              {atom ID for our window class name}
  getflag: win_bool_t;                 {flag from GetMessage}
  accel: array[1..n_accel_k] of win_accel_t; {our table of shortcut keys}
  accel_h: win_handle_t;               {handle to our installed accelerator table}
  msg: win_msg_t;                      {message descriptor}

  verts: array[1..4] of win_point_t;   {array of vertices for polygon, etc}

label
  loop_msg, done_msg;
{
********************************************************************************
*
*   Subroutine ERROR (MSG)
*
*   Write error message and abort program with error.  MSG will be printed to
*   its full length, or to the first NULL character, whichever occurrs first.
}
procedure error (                      {write error message and bomb}
  in      msg: string);                {error message to write}
  val_param;

var
  s: string_var80_t;                   {scratch var string}

begin
  s.max := size_char(s.str);           {init local var string}

  string_vstring (s, msg, size_char(msg)); {write caller's message}
  string_write (s);
  writeln ('*** Program aborted on error. ***');
  sys_exit_error;                      {bomb the program with error status}
  end;
{
********************************************************************************
*
*   Subroutine ERROR_SYS (MSG, ERR)
*
*   Like subroutine ERROR, except first shows the system error condition ERR.
}
procedure error_sys (                  {abort due to system error}
  in      msg: string;                 {error message to show after system err info}
  in      err: sys_sys_err_t);         {system error code}
  val_param;

var
  stat: sys_err_t;

begin
  sys_error_none (stat);               {init STAT to indicate no error}
  stat.sys := err;                     {set STAT to the system error from caller}
  sys_error_print (stat, '', '', nil, 0); {show info about the system error}
  error (msg);                         {write caller's error message and bomb}
  end;
{
********************************************************************************
*
*   Subroutine ERROR_ABORT (OK, MSG, ERR)
*
*   Like ERROR_SYS if OK = WIN_BOOL_FALSE_K.  Otherwise does nothing.
}
procedure error_abort (                {abort on error with messages}
  in      ok: win_bool_t;              {common Windows success/fail value}
  in      msg: string;                 {message to show after system err info}
  in      err: sys_sys_err_t);         {system error code}
  val_param;

begin
  if ok <> win_bool_false_k then return; {no error ?}
  error_sys (msg, err);
  end;
{
********************************************************************************
*
*   Subroutine SHOW_MESSAGE (MSG, WPARAM, LPARAM)
*
*   Write the message name and its parameters to standard output.
}
procedure show_message (               {show a message and parameters to STDOUT}
  in      msg: winmsg_k_t;             {message ID}
  in      wparam: win_wparam_t;        {unsigned 32 bit integer message parameter}
  in      lparam: win_lparam_t);       {signed 32 bit integer message parameter}
  val_param;

var
  s: string_var80_t;                   {scratch string}
  mname: string_var32_t;               {message name}
  tk: string_var32_t;                  {scratch token}

begin
  s.max := size_char(s.str);           {init local var strings}
  mname.max := size_char(mname.str);
  tk.max := size_char(tk.str);

  case msg of                          {set MNAME to message name}
winmsg_null_k: string_vstring (mname, 'NULL'(0), -1);
winmsg_create_k: string_vstring (mname, 'CREATE'(0), -1);
winmsg_destroy_k: string_vstring (mname, 'DESTROY'(0), -1);
winmsg_move_k: string_vstring (mname, 'MOVE'(0), -1);
winmsg_size_k: string_vstring (mname, 'SIZE'(0), -1);
winmsg_activate_k: string_vstring (mname, 'ACTIVATE'(0), -1);
winmsg_setfocus_k: string_vstring (mname, 'SETFOCUS'(0), -1);
winmsg_killfocus_k: string_vstring (mname, 'KILLFOCUS'(0), -1);
winmsg_enable_k: string_vstring (mname, 'ENABLE'(0), -1);
winmsg_setredraw_k: string_vstring (mname, 'SETREDRAW'(0), -1);
winmsg_settext_k: string_vstring (mname, 'SETTEXT'(0), -1);
winmsg_gettext_k: string_vstring (mname, 'GETTEXT'(0), -1);
winmsg_gettextlength_k: string_vstring (mname, 'GETTEXTLENGTH'(0), -1);
winmsg_paint_k: string_vstring (mname, 'PAINT'(0), -1);
winmsg_close_k: string_vstring (mname, 'CLOSE'(0), -1);
winmsg_queryendsession_k: string_vstring (mname, 'QUERYENDSESSION'(0), -1);
winmsg_quit_k: string_vstring (mname, 'QUIT'(0), -1);
winmsg_queryopen_k: string_vstring (mname, 'QUERYOPEN'(0), -1);
winmsg_erasebkgnd_k: string_vstring (mname, 'ERASEBKGND'(0), -1);
winmsg_syscolorchange_k: string_vstring (mname, 'SYSCOLORCHANGE'(0), -1);
winmsg_endsession_k: string_vstring (mname, 'ENDSESSION'(0), -1);
winmsg_showwindow_k: string_vstring (mname, 'SHOWWINDOW'(0), -1);
winmsg_wininichange_k: string_vstring (mname, 'WININICHANGE'(0), -1);
winmsg_devmodechange_k: string_vstring (mname, 'DEVMODECHANGE'(0), -1);
winmsg_activateapp_k: string_vstring (mname, 'ACTIVATEAPP'(0), -1);
winmsg_fontchange_k: string_vstring (mname, 'FONTCHANGE'(0), -1);
winmsg_timechange_k: string_vstring (mname, 'TIMECHANGE'(0), -1);
winmsg_cancelmode_k: string_vstring (mname, 'CANCELMODE'(0), -1);
winmsg_setcursor_k: string_vstring (mname, 'SETCURSOR'(0), -1);
winmsg_mouseactivate_k: string_vstring (mname, 'MOUSEACTIVATE'(0), -1);
winmsg_childactivate_k: string_vstring (mname, 'CHILDACTIVATE'(0), -1);
winmsg_queuesync_k: string_vstring (mname, 'QUEUESYNC'(0), -1);
winmsg_getminmaxinfo_k: string_vstring (mname, 'GETMINMAXINFO'(0), -1);
winmsg_painticon_k: string_vstring (mname, 'PAINTICON'(0), -1);
winmsg_iconerasebkgnd_k: string_vstring (mname, 'ICONERASEBKGND'(0), -1);
winmsg_nextdlgctl_k: string_vstring (mname, 'NEXTDLGCTL'(0), -1);
winmsg_spoolerstatus_k: string_vstring (mname, 'SPOOLERSTATUS'(0), -1);
winmsg_drawitem_k: string_vstring (mname, 'DRAWITEM'(0), -1);
winmsg_measureitem_k: string_vstring (mname, 'MEASUREITEM'(0), -1);
winmsg_deleteitem_k: string_vstring (mname, 'DELETEITEM'(0), -1);
winmsg_vkeytoitem_k: string_vstring (mname, 'VKEYTOITEM'(0), -1);
winmsg_chartoitem_k: string_vstring (mname, 'CHARTOITEM'(0), -1);
winmsg_setfont_k: string_vstring (mname, 'SETFONT'(0), -1);
winmsg_getfont_k: string_vstring (mname, 'GETFONT'(0), -1);
winmsg_sethotkey_k: string_vstring (mname, 'SETHOTKEY'(0), -1);
winmsg_gethotkey_k: string_vstring (mname, 'GETHOTKEY'(0), -1);
winmsg_querydragicon_k: string_vstring (mname, 'QUERYDRAGICON'(0), -1);
winmsg_compareitem_k: string_vstring (mname, 'COMPAREITEM'(0), -1);
winmsg_compacting_k: string_vstring (mname, 'COMPACTING'(0), -1);
winmsg_windowposchanging_k: string_vstring (mname, 'WINDOWPOSCHANGING'(0), -1);
winmsg_windowposchanged_k: string_vstring (mname, 'WINDOWPOSCHANGED'(0), -1);
winmsg_power_k: string_vstring (mname, 'POWER'(0), -1);
winmsg_copydata_k: string_vstring (mname, 'COPYDATA'(0), -1);
winmsg_canceljournal_k: string_vstring (mname, 'CANCELJOURNAL'(0), -1);
winmsg_notify_k: string_vstring (mname, 'NOTIFY'(0), -1);
winmsg_inputlangchangerequest_k: string_vstring (mname, 'INPUTLANGCHANGEREQUEST'(0), -1);
winmsg_inputlangchange_k: string_vstring (mname, 'INPUTLANGCHANGE'(0), -1);
winmsg_tcard_k: string_vstring (mname, 'TCARD'(0), -1);
winmsg_help_k: string_vstring (mname, 'HELP'(0), -1);
winmsg_userchanged_k: string_vstring (mname, 'USERCHANGED'(0), -1);
winmsg_notifyformat_k: string_vstring (mname, 'NOTIFYFORMAT'(0), -1);
winmsg_contextmenu_k: string_vstring (mname, 'CONTEXTMENU'(0), -1);
winmsg_stylechanging_k: string_vstring (mname, 'STYLECHANGING'(0), -1);
winmsg_stylechanged_k: string_vstring (mname, 'STYLECHANGED'(0), -1);
winmsg_displaychange_k: string_vstring (mname, 'DISPLAYCHANGE'(0), -1);
winmsg_geticon_k: string_vstring (mname, 'GETICON'(0), -1);
winmsg_seticon_k: string_vstring (mname, 'SETICON'(0), -1);
winmsg_nccreate_k: string_vstring (mname, 'NCCREATE'(0), -1);
winmsg_ncdestroy_k: string_vstring (mname, 'NCDESTROY'(0), -1);
winmsg_nccalcsize_k: string_vstring (mname, 'NCCALCSIZE'(0), -1);
winmsg_nchittest_k: string_vstring (mname, 'NCHITTEST'(0), -1);
winmsg_ncpaint_k: string_vstring (mname, 'NCPAINT'(0), -1);
winmsg_ncactivate_k: string_vstring (mname, 'NCACTIVATE'(0), -1);
winmsg_getdlgcode_k: string_vstring (mname, 'GETDLGCODE'(0), -1);
winmsg_ncmousemove_k: string_vstring (mname, 'NCMOUSEMOVE'(0), -1);
winmsg_nclbuttondown_k: string_vstring (mname, 'NCLBUTTONDOWN'(0), -1);
winmsg_nclbuttonup_k: string_vstring (mname, 'NCLBUTTONUP'(0), -1);
winmsg_nclbuttondblclk_k: string_vstring (mname, 'NCLBUTTONDBLCLK'(0), -1);
winmsg_ncrbuttondown_k: string_vstring (mname, 'NCRBUTTONDOWN'(0), -1);
winmsg_ncrbuttonup_k: string_vstring (mname, 'NCRBUTTONUP'(0), -1);
winmsg_ncrbuttondblclk_k: string_vstring (mname, 'NCRBUTTONDBLCLK'(0), -1);
winmsg_ncmbuttondown_k: string_vstring (mname, 'NCMBUTTONDOWN'(0), -1);
winmsg_ncmbuttonup_k: string_vstring (mname, 'NCMBUTTONUP'(0), -1);
winmsg_ncmbuttondblclk_k: string_vstring (mname, 'NCMBUTTONDBLCLK'(0), -1);
winmsg_keydown_k: string_vstring (mname, 'KEYDOWN'(0), -1);
winmsg_keyup_k: string_vstring (mname, 'KEYUP'(0), -1);
winmsg_char_k: string_vstring (mname, 'CHAR'(0), -1);
winmsg_deadchar_k: string_vstring (mname, 'DEADCHAR'(0), -1);
winmsg_syskeydown_k: string_vstring (mname, 'SYSKEYDOWN'(0), -1);
winmsg_syskeyup_k: string_vstring (mname, 'SYSKEYUP'(0), -1);
winmsg_syschar_k: string_vstring (mname, 'SYSCHAR'(0), -1);
winmsg_sysdeadchar_k: string_vstring (mname, 'SYSDEADCHAR'(0), -1);
winmsg_keylast_k: string_vstring (mname, 'KEYLAST'(0), -1);
winmsg_initdialog_k: string_vstring (mname, 'INITDIALOG'(0), -1);
winmsg_command_k: string_vstring (mname, 'COMMAND'(0), -1);
winmsg_syscommand_k: string_vstring (mname, 'SYSCOMMAND'(0), -1);
winmsg_timer_k: string_vstring (mname, 'TIMER'(0), -1);
winmsg_hscroll_k: string_vstring (mname, 'HSCROLL'(0), -1);
winmsg_vscroll_k: string_vstring (mname, 'VSCROLL'(0), -1);
winmsg_initmenu_k: string_vstring (mname, 'INITMENU'(0), -1);
winmsg_initmenupopup_k: string_vstring (mname, 'INITMENUPOPUP'(0), -1);
winmsg_menuselect_k: string_vstring (mname, 'MENUSELECT'(0), -1);
winmsg_menuchar_k: string_vstring (mname, 'MENUCHAR'(0), -1);
winmsg_enteridle_k: string_vstring (mname, 'ENTERIDLE'(0), -1);
winmsg_ctlcolormsgbox_k: string_vstring (mname, 'CTLCOLORMSGBOX'(0), -1);
winmsg_ctlcoloredit_k: string_vstring (mname, 'CTLCOLOREDIT'(0), -1);
winmsg_ctlcolorlistbox_k: string_vstring (mname, 'CTLCOLORLISTBOX'(0), -1);
winmsg_ctlcolorbtn_k: string_vstring (mname, 'CTLCOLORBTN'(0), -1);
winmsg_ctlcolordlg_k: string_vstring (mname, 'CTLCOLORDLG'(0), -1);
winmsg_ctlcolorscrollbar_k: string_vstring (mname, 'CTLCOLORSCROLLBAR'(0), -1);
winmsg_ctlcolorstatic_k: string_vstring (mname, 'CTLCOLORSTATIC'(0), -1);
winmsg_mousemove_k: string_vstring (mname, 'MOUSEMOVE'(0), -1);
winmsg_lbuttondown_k: string_vstring (mname, 'LBUTTONDOWN'(0), -1);
winmsg_lbuttonup_k: string_vstring (mname, 'LBUTTONUP'(0), -1);
winmsg_lbuttondblclk_k: string_vstring (mname, 'LBUTTONDBLCLK'(0), -1);
winmsg_rbuttondown_k: string_vstring (mname, 'RBUTTONDOWN'(0), -1);
winmsg_rbuttonup_k: string_vstring (mname, 'RBUTTONUP'(0), -1);
winmsg_rbuttondblclk_k: string_vstring (mname, 'RBUTTONDBLCLK'(0), -1);
winmsg_mbuttondown_k: string_vstring (mname, 'MBUTTONDOWN'(0), -1);
winmsg_mbuttonup_k: string_vstring (mname, 'MBUTTONUP'(0), -1);
winmsg_mbuttondblclk_k: string_vstring (mname, 'MBUTTONDBLCLK'(0), -1);
winmsg_parentnotify_k: string_vstring (mname, 'PARENTNOTIFY'(0), -1);
winmsg_entermenuloop_k: string_vstring (mname, 'ENTERMENULOOP'(0), -1);
winmsg_exitmenuloop_k: string_vstring (mname, 'EXITMENULOOP'(0), -1);
winmsg_nextmenu_k: string_vstring (mname, 'NEXTMENU'(0), -1);
winmsg_sizing_k: string_vstring (mname, 'SIZING'(0), -1);
winmsg_capturechanged_k: string_vstring (mname, 'CAPTURECHANGED'(0), -1);
winmsg_moving_k: string_vstring (mname, 'MOVING'(0), -1);
winmsg_powerbroadcast_k: string_vstring (mname, 'POWERBROADCAST'(0), -1);
winmsg_devicechange_k: string_vstring (mname, 'DEVICECHANGE'(0), -1);
winmsg_mdicreate_k: string_vstring (mname, 'MDICREATE'(0), -1);
winmsg_mdidestroy_k: string_vstring (mname, 'MDIDESTROY'(0), -1);
winmsg_mdiactivate_k: string_vstring (mname, 'MDIACTIVATE'(0), -1);
winmsg_mdirestore_k: string_vstring (mname, 'MDIRESTORE'(0), -1);
winmsg_mdinext_k: string_vstring (mname, 'MDINEXT'(0), -1);
winmsg_mdimaximize_k: string_vstring (mname, 'MDIMAXIMIZE'(0), -1);
winmsg_mditile_k: string_vstring (mname, 'MDITILE'(0), -1);
winmsg_mdicascade_k: string_vstring (mname, 'MDICASCADE'(0), -1);
winmsg_mdiiconarrange_k: string_vstring (mname, 'MDIICONARRANGE'(0), -1);
winmsg_mdigetactive_k: string_vstring (mname, 'MDIGETACTIVE'(0), -1);
winmsg_mdisetmenu_k: string_vstring (mname, 'MDISETMENU'(0), -1);
winmsg_entersizemove_k: string_vstring (mname, 'ENTERSIZEMOVE'(0), -1);
winmsg_exitsizemove_k: string_vstring (mname, 'EXITSIZEMOVE'(0), -1);
winmsg_dropfiles_k: string_vstring (mname, 'DROPFILES'(0), -1);
winmsg_mdirefreshmenu_k: string_vstring (mname, 'MDIREFRESHMENU'(0), -1);
winmsg_cut_k: string_vstring (mname, 'CUT'(0), -1);
winmsg_copy_k: string_vstring (mname, 'COPY'(0), -1);
winmsg_paste_k: string_vstring (mname, 'PASTE'(0), -1);
winmsg_clear_k: string_vstring (mname, 'CLEAR'(0), -1);
winmsg_undo_k: string_vstring (mname, 'UNDO'(0), -1);
winmsg_renderformat_k: string_vstring (mname, 'RENDERFORMAT'(0), -1);
winmsg_renderallformats_k: string_vstring (mname, 'RENDERALLFORMATS'(0), -1);
winmsg_destroyclipboard_k: string_vstring (mname, 'DESTROYCLIPBOARD'(0), -1);
winmsg_drawclipboard_k: string_vstring (mname, 'DRAWCLIPBOARD'(0), -1);
winmsg_paintclipboard_k: string_vstring (mname, 'PAINTCLIPBOARD'(0), -1);
winmsg_vscrollclipboard_k: string_vstring (mname, 'VSCROLLCLIPBOARD'(0), -1);
winmsg_sizeclipboard_k: string_vstring (mname, 'SIZECLIPBOARD'(0), -1);
winmsg_askcbformatname_k: string_vstring (mname, 'ASKCBFORMATNAME'(0), -1);
winmsg_changecbchain_k: string_vstring (mname, 'CHANGECBCHAIN'(0), -1);
winmsg_hscrollclipboard_k: string_vstring (mname, 'HSCROLLCLIPBOARD'(0), -1);
winmsg_querynewpalette_k: string_vstring (mname, 'QUERYNEWPALETTE'(0), -1);
winmsg_paletteischanging_k: string_vstring (mname, 'PALETTEISCHANGING'(0), -1);
winmsg_palettechanged_k: string_vstring (mname, 'PALETTECHANGED'(0), -1);
winmsg_hotkey_k: string_vstring (mname, 'HOTKEY'(0), -1);
winmsg_print_k: string_vstring (mname, 'PRINT'(0), -1);
winmsg_printclient_k: string_vstring (mname, 'PRINTCLIENT'(0), -1);
winmsg_handheldfirst_k: string_vstring (mname, 'HANDHELDFIRST'(0), -1);
winmsg_handheldlast_k: string_vstring (mname, 'HANDHELDLAST'(0), -1);
winmsg_afxfirst_k: string_vstring (mname, 'AFXFIRST'(0), -1);
winmsg_afxlast_k: string_vstring (mname, 'AFXLAST'(0), -1);
winmsg_penwinfirst_k: string_vstring (mname, 'PENWINFIRST'(0), -1);
winmsg_penwinlast_k: string_vstring (mname, 'PENWINLAST'(0), -1);
winmsg_user_k: string_vstring (mname, 'USER'(0), -1);
winmsg_app_k: string_vstring (mname, 'APP'(0), -1);
otherwise                              {not a message we explicitly know about}
    string_f_int32h (mname, ord(msg)); {message name is message number in hex}
    end;                               {end of message ID cases, MNAME all set}

  string_vstring (s, 'Message '(0), -1);
  string_append (s, mname);
  string_appends (s, ', wparam '(0));
  string_f_int32h (tk, wparam);
  string_append (s, tk);
  string_appends (s, ', lparam '(0));
  string_f_int32h (tk, lparam);
  string_append (s, tk);
  string_write (s);
  end;
{
********************************************************************************
*
*   Function WINDOW_PROC (WIN_H, MSG, WPARAM, LPARAM)
*
*   This is the window procedure for our window class.  It is called by the
*   system when messages are explicitly dispatched to our window, and when
*   certain asynchronous event happen.
}
function window_proc (                 {our official Win32 window procedure}
  in      win_h: win_handle_t;         {handle to window this message is for}
  in      msgid: winmsg_k_t;           {ID of this message}
  in      wparam: win_wparam_t;        {unsigned 32 bit integer message parameter}
  in      lparam: win_lparam_t)        {signed 32 bit integer message parameter}
  :win_lresult_t;                      {unsigned 32 bit integer return value}
  val_param;

var
  ok: win_bool_t;                      {not WIN_BOOL_FALSE_K on sys call success}
  paint: winpaint_t;                   {paint info from BeginPaint}
  x, y: sys_int_machine_t;             {scratch integer coordinates}
  id: sys_int_machine_t;               {scratch for command ID, etc}
  result_set: boolean;                 {TRUE if function result already set}

label
  default_action;

begin
  show_message (msgid, wparam, lparam); {write messages name and parms to STDOUT}

  result_set := false;                 {indicate WINDOW_PROC function value not set}
  case msgid of                        {which message is it ?}
{
**********
*
*   SIZE  -  Specifies new window size in pixels.
}
winmsg_size_k: begin
  x := lparam & 16#FFFF;               {extract new window width}
  y := rshft(lparam, 16) & 16#FFFF;    {extract new window height}
  if (x <> wind_dx) or (y <> wind_dy) then begin {window size actually changed ?}
    if ready then begin                {resized after initial paint request ?}
      dirty_x := 0;                    {flag whole window as dirty}
      dirty_y := 0;
      dirty_dx := x;
      dirty_dy := y;
      dirty := true;
      end;
    wind_dx := x;                      {update our saved window size values}
    wind_dy := y;
    writeln ('Window size changed to ', wind_dx, ' x ', wind_dy);
    end;
  end;
{
**********
*
*   KEYDOWN - A key was pressed without ALT being down.
}
winmsg_keydown_k: begin
  case wparam of                       {which virtual key is it ?}

ord(winkey_end_k): begin               {END key}
  ok := DestroyWindow (wind_h);
  error_abort (ok, 'On call to DestroyWindow.', GetLastError);
  end;

otherwise                              {all the key codes we don't explicitly handle}
    goto default_action;               {handle message in the default way}
    end;                               {end of cases for specific key codes}
  end;
{
**********
*
*   COMMAND
}
winmsg_command_k: begin
  id := wparam & 16#FFFF;              {extract the command ID}
  case id of                           {which command is this ?}

cmd_close_k: begin                     {close the window}
  ok := DestroyWindow (wind_h);
  error_abort (ok, 'On call to DestroyWindow.', GetLastError);
  end;

otherwise                              {all the key codes we don't explicitly handle}
    goto default_action;               {handle message in the default way}
    end;                               {end of cases for specific key codes}
  end;
{
**********
*
*   PAINT - Windows wants us to update a dirty region.
}
winmsg_paint_k: begin
  discard( BeginPaint (                {get info about region, reset to not dirty}
    wind_h,                            {handle to our window}
    paint) );                          {returned info about how to repaint}

  if dirty
    then begin                         {a previous dirty region exists}
      dirty_x := min(dirty_x, paint.dirty.lft);
      dirty_y := min(dirty_y, paint.dirty.rit);
      x := max(dirty_x + dirty_dx, paint.dirty.rit);
      y := max(dirty_y + dirty_dy, paint.dirty.bot);
      dirty_dx := x - dirty_x;
      dirty_dy := y - dirty_y;
      end
    else begin                         {no previous dirty region exists}
      dirty_x := paint.dirty.lft;
      dirty_y := paint.dirty.top;
      dirty_dx := paint.dirty.rit - dirty_x;
      dirty_dy := paint.dirty.bot - dirty_y;
      dirty := true;
      end
    ;

  discard( EndPaint (wind_h, paint) ); {tell windows we are done repainting}
  ready := true;                       {window is now ready for drawing}
  end;
{
**********
*
*   CLOSE - Someone wants us to close the window.
}
winmsg_close_k: begin
  ok := DestroyWindow (wind_h);
  error_abort (ok, 'On call to DestroyWindow.', GetLastError);
  end;
{
**********
*
*   DESTROY - Window is being destroyed, child windows still exist.
}
winmsg_destroy_k: begin
  PostQuitMessage (0);                 {indicate we want to exit application}
  end;
{
**********
*
*   All remaining messages that weren't explicitly trapped above.  These
*   messages are passed to the system for processing in the default way.
}
otherwise
    goto default_action;               {let the system take the default action}
    end;
  if not result_set then begin         {WINDOW_PROC function value not yet set ?}
    window_proc := 0;
    end;
  return;                              {message handled, WINDOW_PROC already set}

default_action:                        {jump here to handle message in default way}
  window_proc := DefWindowProcA (      {let system handle message in default way}
    win_h, msgid, wparam, lparam);     {pass our call arguments exactly}
  end;
{
********************************************************************************
*
*   Start of main routine.
}
begin
  tk.max := size_char(tk.str);         {init local var strings}
  s.max := size_char(s.str);
{
*   Create a new window class for our window.
}
  byte_p := univ_ptr(addr(wclass));    {init class descriptor to all zeros}
  for i := 1 to size_min(wclass) do begin
    byte_p^ := 0;
    byte_p := succ(byte_p);
    end;

  wclass.size := size_min(wclass);     {indicate size of data structure}
  wclass.style := [                    {set window class style}
    clstyle_dblclks_k,                 {convert and send double click messages}
    clstyle_own_dc_k];                 {each window gets a private dc}
  wclass.msg_proc := addr(window_proc); {set pointer to window procedure}
  wclass.instance_h := instance_h;     {identify who we are}
  wclass.cursor_h := LoadCursorA (     {indicate which cursor to use}
    handle_none_k,                     {we will use one of the predifined cursors}
    cursor_arrow_k);                   {ID of predefined cursor}
  if wclass.cursor_h = handle_none_k then begin {error getting cursor handle ?}
    error_sys ('On get handle to predefined system cursor.', GetLastError);
    end;
  wclass.name_p := univ_ptr(addr(window_class_name));

  atom_class := RegisterClassExA (wclass); {try to create our new window class}
  if atom_class = 0 then begin         {failed to create new window class ?}
    error_sys ('On try to create new window class.', GetLastError);
    end;

  dirty := false;                      {init to no portion of window needs updating}
  ready := false;                      {init to window not ready for drawing}
  wind_dx := 0;                        {init draw area size to invalid}
  wind_dy := 0;
{
*   Create a window with our window class and display it.
}
  wind_h := CreateWindowExA (          {try to create our drawing window}
    [],                                {extended window style flags}
    univ_ptr(addr(window_class_name)), {pointer to window class name string}
    'TEST_WIN Private Window'(0),      {window name for title bar}
    [ wstyle_max_box_k,                {make maximize box on title bar}
      wstyle_min_box_k,                {make minimize box on title bar}
      wstyle_edge_size_k,              {make user sizing border}
      wstyle_sysmenu_k,                {put standard system menu on title bar}
      wstyle_edge_thin_k,              {thin edge, needed for title bar}
      wstyle_clip_child_k,             {our drawing will be clipped to child windows}
      wstyle_clip_sib_k,               {our drawing will be clipped to sib windows}
      wstyle_visible_k],               {make initially visible}
    win_default_coor_k, 0,             {use default placement}
    512, 410,                          {window size in pixels}
    handle_none_k,                     {no parent window specified}
    handle_none_k,                     {no application menu specified}
    instance_h,                        {handle to our invocation instance}
    16#123456789);                     {data passed to CREATE window message}
  if wind_h = handle_none_k then begin {window wasn't created ?}
    error_sys ('CreateWindowExA Failed.', GetLastError);
    end;
  writeln ('Window handle = ', wind_h);
{
*   Initialize state before entering message loop.
}
  dc := GetDC (wind_h);                {get handle to our drawing device context}
  if dc = handle_none_k then begin
    error ('Failed to get device context from GetDC.');
    end;

  accel[1].flags := [
    accelflag_virtkey_k,               {use virtual key codes, not char values}
    accelflag_control_k];              {control key must be down}
  accel[1].key := ord(winkey_return_k); {selected key}
  accel[1].cmd := cmd_close_k;         {command ID to close window}

  accel_h := CreateAcceleratorTableA ( {tell system about our accelerators}
    accel,                             {array of keyboard accelerator descriptors}
    n_accel_k);                        {number of entries in the list}
  if accel_h = handle_none_k then begin {failed to create internal accel table ?}
    error_sys ('Error on create internal keyboard accelerator table.',
      GetLastError);
    end;

  discard( ShowWindow (                {make our window visible}
    wind_h,                            {handle to our window}
    winshow_normal_k));                {new window show state}
{
*   Fetch messages and dispatch them to our window procedure.
}
loop_msg:                              {back here each new thread message}
  getflag := GetMessageA (             {get the next message from thread msg queue}
    msg,                               {returned message descriptor}
    handle_none_k,                     {get any message for this thread}
    firstof(winmsg_k_t), lastof(winmsg_k_t)); {message range we care about}
  if ord(getflag) < 0 then begin       {error getting message ?}
    error_sys ('On get next thread message.', GetLastError);
    end;
  if ord(getflag) = 0 then goto done_msg; {got the QUIT message ?}
  i := TranslateAcceleratorA (         {check for accelerator key stroke}
    wind_h,                            {handle to window to receive translated msg}
    accel_h,                           {handle to our accelerator table}
    msg);                              {message to try to translate}
  if i <> 0 then goto loop_msg;        {message was translated and dealt with ?}

(*
  writeln ('Calling DispatchMessageA');
  writeln ('  wind_h ', msg.wind_h);
  writeln ('  msg ', ord(msg.msg));
  writeln ('  wparam ', msg.wparam);
  writeln ('  lparam ', msg.lparam);
  writeln ('  time ', msg.time);
  writeln ('  coor.x ', msg.coor.x);
  writeln ('  coor.y ', msg.coor.y);
*)

  i := DispatchMessageA (msg);         {have our window procedure process the msg}
{
*   Draw our stuff if any region needs updating.
}
  if dirty then begin                  {some region of window needs updating ?}
    writeln ('Dirty rect at ', dirty_x, ',', dirty_y,
      ' size ', dirty_dx, ',', dirty_dy);
    dirty := false;                    {reset to no dirty region exists}

    verts[1].x := 0;         verts[1].y := 0;
    verts[2].x := 0;         verts[2].y := wind_dy-1;
    verts[3].x := wind_dx-1; verts[3].y := wind_dy-1;
    verts[4].x := wind_dx-1; verts[4].y := 0;
    discard( Polygon (                 {clear background}
      dc,                              {handle to our drawing device context}
      verts,                           {list of polygon vertices}
      4));                             {number of vertices in list}

    discard( MoveToEx (dc, wind_dx div 2, 0, nil) );
    discard( LineTo (dc, 0, wind_dy div 2) );
    discard( LineTo (dc, wind_dx div 2, wind_dy-1) );
    discard( LineTo (dc, wind_dx-1, wind_dy div 2) );
    discard( LineTo (dc, wind_dx div 2, 0) );
    end;
{
*   Done refreshing our picture.
}
  goto loop_msg;                       {back for next thread message}

done_msg:                              {all done handling thread messages}
  discard( DestroyAcceleratorTable(accel_h) ); {try to deallocate accel resources}
  end.
