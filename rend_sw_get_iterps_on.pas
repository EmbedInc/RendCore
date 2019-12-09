module rend_sw_get_iterps_on;
define rend_sw_get_iterps_on_list;
define rend_sw_get_iterps_on_set;
%include 'rend_sw2.ins.pas';
{
**********************************************
*
*   Subroutine REND_SW_GET_ITERPS_ON (N, LIST)
*
*   Return the list of all the currently ON interpolants.  N is the number of
*   ON interpolants.  The first N entries in LIST will contain the IDs for each
*   on interpolant.
}
procedure rend_sw_get_iterps_on_list ( {get list of all the curr ON interpolants}
  out     n: sys_int_machine_t;        {number of interpolants currently ON}
  out     list: rend_iterps_list_t);   {N interpolant IDs}

var
  it: rend_iterp_k_t;                  {loop counter}

begin
  n := 0;                              {init number of ON interpolants}
  for it := firstof(it) to lastof(it)  do begin {once for each interpolant}
    if not rend_iterps.iterp[it].on then next; {this interpolant is OFF ?}
    n := n + 1;                        {one more ON interpolant}
    list[n] := it;                     {add interpolant ID to list}
    end;
  end;
{
**********************************************
*
*   Function REND_SW_GET_ITERPS_ON_SET
*
*   Return a SET containing one member for each ON interpolant.
}
function rend_sw_get_iterps_on_set     {get SET indicating the ON interpolants}
  :rend_iterps_t;

begin
  rend_sw_get_iterps_on_set := rend_iterps.mask_on;
  end;
