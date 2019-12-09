{   Subroutine REND_SW_GET_CMODES (MAXN, N, LIST)
*
*   Return a list of all the automatically changeable modes that actually got
*   changed.  MAXN is the maximum number of modes to return.  N is the actual number
*   of modes to return, and is never greater than MAXN, even if additional modes
*   got changed.  To insure that all the modes get returned, set MAXN to
*   REND_N_CMODES_K.  LIST is the returned array of mode identifiers.  These
*   are the constants REND_CMODE_xxx_K.
}
module rend_sw_get_cmodes;
define rend_sw_get_cmodes;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_cmodes (         {get list of automatically changed modes}
  in      maxn: sys_int_machine_t;     {max size list to pass back}
  out     n: sys_int_machine_t;        {actual number of modes passed back in list}
  out     list: univ rend_cmodes_list_t); {buffer filled with N mode IDs}
  val_param;

var
  cmode: rend_cmode_k_t;               {current mode ID}

begin
  n := 0;                              {init to nothing passed back}
  for cmode := firstof(cmode) to lastof(cmode) do begin {once for each changeable mode}
    if n >= maxn then return;          {no room for another mode in output list ?}
    if not rend_cmode[cmode] then next; {this mode didn't get changed ?}
    n := n + 1;                        {one more mode ID passed back}
    list[n] := cmode;                  {pass back this mode identifier}
    end;
  end;
