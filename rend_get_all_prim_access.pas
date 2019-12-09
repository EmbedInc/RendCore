{   Subroutine REND_GET_ALL_PRIM_ACCESS (SW_READ,SW_WRITE)
*
*   Find the combined software bitmap access state of all primitives together.
*   SW_READ will be returned as TRUE if at least one primitive will read from the
*   software bitmap under the current conditions.  SW_WRITE will be returned as
*   TRUE if at least one primitive will write to the software bitmap under the
*   current conditions.
}
module rend_get_all_prim_access;
define rend_get_all_prim_access;
%include 'rend2.ins.pas';

const
  rend_prim_entry_size =               {adr offset for next entry in REND_PRIM}
    2 * sizeof(univ_ptr);

procedure rend_get_all_prim_access (   {get worst case access flags for all prims}
  out     sw_read: rend_access_k_t;    {SW read access, use REND_ACCESS_xxx_K}
  out     sw_write: rend_access_k_t);  {SW write access, use REND_ACCESS_xxx_K}

var
  swr, sww: rend_access_k_t;           {SW bitmap access flags}
  n_prims: sys_int_machine_t;          {number of primitives in REND_PRIM call table}
  prim_data_pp: rend_prim_data_pp_t;   {adr of prim data pointer in call table}
  i: sys_int_machine_t;                {loop counter}

begin
  prim_data_pp := univ_ptr(            {make address of first prim data pointer}
    sys_int_adr_t(addr(rend_prim)) + sizeof(univ_ptr));
  n_prims := sizeof(rend_prim) div rend_prim_entry_size; {number of REND_PRIM entries}
  sw_read := rend_access_inherited_k;  {init accumulated access flags}
  sw_write := rend_access_inherited_k;

  for i := 1 to n_prims do begin       {once for each primitive in REND_PRIM}
    rend_get_prim_access (prim_data_pp^^, swr, sww); {get access flags for this prim}
    if ord(swr) > ord(sw_read)         {update accumulated access info}
      then sw_read := swr;
    if ord(sww) > ord(sw_write)
      then sw_write := sww;
    prim_data_pp := univ_ptr(          {point to data pointer for next primitive}
      sys_int_adr_t(prim_data_pp) + rend_prim_entry_size);
    end;                               {back and get flags for next primitive}
  end;
