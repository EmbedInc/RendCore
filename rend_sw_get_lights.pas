{   Subroutine REND_SW_GET_LIGHTS (MAX_N, START_N, LLIST, RET_N, TOTAL_N)
*
*   Return a list of light source handles in LLIST.  MAX_N is the maximum number
*   of light source handles allowed to be returned, and RET_N is the number of
*   handles actually returned.  TOTAL_N is set to the total number of light
*   sources that currently exist.  START_N is the number of the first light
*   source for which to return a handle.  These light source numbers reflect
*   only the ordering of the light sources in an arbitrary internal sequence.  They
*   have nothing to do with order of creation, etc., and may be changed by any
*   other light source calls.  The first light source in the list is numbered 1.
*
*   START_N is provided for the sole purpose of allowing the caller to eventually
*   get all the light source handles without having to assume a maximum
*   allowable number of light sources.  In normal operation, START_N is set to 1
*   on the first call.  Additional calls are made as long as
*   (START_N + RET_N - 1) < TOTAL_N.  For each new call, START_N is updated:
*   START_N <-- START_N + RET_N - 1.
*
*   In order to determine only how many light sources exist, set MAX_N to zero.
*   TOTAL_N will be the number of light sources, START_N will be irrelevant,
*   LLIST will be left untouched, and RET_N will be set to zero.
}
module rend_sw_get_lights;
define rend_sw_get_lights;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_lights (         {get handles to all light sources}
  in      max_n: sys_int_machine_t;    {max number of light handles to return}
  in      start_n: sys_int_machine_t;  {starting light num, first is 1}
  out     llist: univ rend_light_handle_ar_t; {returned array of light handles}
  out     ret_n: sys_int_machine_t;    {number of light handles returned}
  out     total_n: sys_int_machine_t); {number of lights currently in existance}
  val_param;

var
  h: rend_light_handle_t;              {handle to current light source}
  i: sys_int_machine_t;                {loop counter}

begin
  total_n := rend_lights.n_used;       {return total number of lights in existance}
  ret_n := 0;                          {init number of light handles returned}
  if max_n <= 0 then return;           {nothing more to do ?}
  h := rend_lights.used_p;             {init handle to first light source}

  for i := 1 to (start_n-1) do begin   {once for each light source to skip}
    if h = nil then return;            {hit end of light sources list ?}
    h := h^.next_p;                    {make handle for next light source in list}
    end;

  for i := 1 to max_n do begin         {once for each available slot in LLIST}
    if h = nil then return;            {hit end of light sources list ?}
    llist[i] := h;                     {pass back handle to this light source}
    ret_n := ret_n + 1;                {one more light handle passed back}
    h := h^.next_p;                    {make handle for next light source}
    end;
  end;
