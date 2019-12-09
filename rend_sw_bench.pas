{   Module of routines that deal with the benchmark flags.
}
module rend_sw_bench;
define rend_sw_bench_flags;
define rend_sw_bench_init;
define rend_sw_get_bench_flags;
%include 'rend_sw2.ins.pas';

var
  varname_bench: string_var16_t :=     {environment variable name}
    [str := 'RENDLIB_BENCH', len := 13, max := sizeof(varname_bench.str)];
{
***************************************************
*
*   Subroutine REND_BENCH_INIT
*
*   Initialize benchmark flags in REND_BENCH.  These are all disabled
*   unless the appropriate environment variable exists and is set correctly.
}
procedure rend_sw_bench_init;          {init REND_BENCH flags}

const
  max_msg_parms = 1;                   {max parameters we can pass to a message}

var
  vstr: string_var80_t;                {contents of environment variable}
  token: string_var16_t;               {token parsed from environment variable value}
  p: string_index_t;                   {parse index for env var string}
  pick: sys_int_machine_t;             {number of keyword picked from list}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;
  stat: sys_err_t;

label
  next_keyword;

begin
  vstr.max := sizeof(vstr.str);        {init local var strings}
  token.max := sizeof(token.str);

  rend_bench := [];                    {init to all flags disabled}

  sys_envvar_get (varname_bench, vstr, stat); {get environment var value, if there}
  if sys_error(stat) then return;      {ignore if couldn't get environment variable}

  p := 1;                              {init env var string parse index}
next_keyword:                          {back here each new keyword from envvar}
  string_token (vstr, p, token, stat); {get next token from envvar string}
  if string_eos(stat) then return;     {exhausted envvar string ?}
  rend_error_abort (stat, 'rend', 'bench_envvar_parse_err', nil, 0);
  string_upcase (token);               {make upper case for keyword matching}
  string_tkpick80 (token,              {token to match to keyword list}
    'DUMPRIM NOGR DUMGR NO2D',
    pick);                             {number of keyword picked from list}
  case pick of

1:  begin                              {DUMPRIM}
      rend_bench := rend_bench + [rend_bench_dumprim_k];
      end;

2:  begin                              {NOGR}
      rend_bench := rend_bench + [rend_bench_nogr_k];
      end;

3:  begin                              {DUMGR}
      rend_bench := rend_bench + [rend_bench_dumgr_k];
      end;

4:  begin                              {NO2D}
      rend_bench := rend_bench + [rend_bench_no2d_k];
      end;

otherwise                              {unexpected token encountered}
    sys_msg_parm_vstr (msg_parm[1], token);
    rend_message_bomb ('rend', 'bench_envvar_token_bad', msg_parm, 1);
    end;
  goto next_keyword;                   {back to process next keyword from envvar}
  end;
{
***************************************************
*
*   Subroutine REND_SW_BENCH_FLAGS (FLAGS)
*
*   Explicitly set new values for the benchmark flags.
}
procedure rend_sw_bench_flags (        {explicitly set benchmark flags}
  in      flags: rend_bench_t);        {new benchmark flag settings}
  val_param;

begin
  if flags = rend_bench then return;   {nothing to change ?}
  rend_bench := flags;                 {update internal copy of flags}
  rend_internal.check_modes^;          {reconfigure to new flag values}
  end;
{
***************************************************
*
*   Function REND_SW_GET_BENCH_FLAGS
*
*   Returns the current state of the benchmark flags.
}
function rend_sw_get_bench_flags       {return current benchmark flag settings}
  :rend_bench_t;

begin
  rend_sw_get_bench_flags := rend_bench;
  end;
