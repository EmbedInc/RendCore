{   Subroutine REND_INSTALL_PRIM (PRIM_DATA,CALL_P)
*
*   Install a graphics primitive into the call table.  PRIM_DATA is the specific
*   data block for this primitive.  CALL_P is the call table entry which will
*   point to the primitive's subroutine entry point.
}
module rend_install_prim;
define rend_install_prim;
%include 'rend2.ins.pas';

procedure rend_install_prim (          {install primitive into call table}
  in out  prim_data: rend_prim_data_t; {specific data block for this primitive}
  out     call_p: univ_ptr);           {where to put the entry point address}

var
  prim_data_pp: rend_prim_data_pp_t;   {adr of pointer to primitive data block}
  offset: sys_int_adr_t;               {offset into particular call table}
  call_pp: ^univ_ptr;                  {adr of entry point pointer in other call tab}

begin
  if call_p = prim_data.call_adr then return; {nothing to to here ?}
{
*   If this primitive is being installed into the REND_SW_PRIM or REND_SW_INTERNAL
*   call tables, then it should also be installed into the the regular call
*   table if it is set to the same routine.
*
*   Check for REND_SW_PRIM call table.
}
  offset := sys_int_adr_t(addr(call_p)) - sys_int_adr_t(addr(rend_sw_prim));
  if (offset < sizeof(rend_sw_prim)) then begin {in SW prim table ?}
    call_pp := univ_ptr(               {make adr of entry pointer in master call tab}
      integer32(addr(rend_prim)) + offset);
    if call_pp^ = call_p then begin    {master table has same routine installed ?}
      call_pp^ := prim_data.call_adr;  {install entry point in master table}
      prim_data_pp := univ_ptr(        {make data pointer adr in master table}
        sys_int_adr_t(call_pp) + sizeof(call_pp^));
      prim_data_pp^ := addr(prim_data); {install data block pointer in master table}
      end;
    end;                               {done handling installing to SW_PRIM table}
{
*   Check for REND_SW_INTERNAL call table.
}
  offset := sys_int_adr_t(addr(call_p)) - sys_int_adr_t(addr(rend_sw_internal));
  if (offset < sizeof(rend_sw_internal)) then begin
    call_pp := univ_ptr(               {make adr of entry pointer in master call tab}
      sys_int_adr_t(addr(rend_internal)) + offset);
    if call_pp^ = call_p then begin    {master table has same routine installed ?}
      call_pp^ := prim_data.call_adr;  {install entry point in master table}
      prim_data_pp := univ_ptr(        {make data pointer adr in master table}
        sys_int_adr_t(call_pp) + sizeof(call_pp^));
      prim_data_pp^ := addr(prim_data); {install data block pointer in master table}
      end;
    end;                               {done handling installing to SW_PRIM table}
{
*   Install into the call table specified by the caller.
}
  call_p := prim_data.call_adr;        {install entry point in call table}
  prim_data_pp := univ_ptr(            {make adr of data block pointer in call table}
    sys_int_adr_t(addr(call_p)) + sizeof(call_pp^));
  prim_data_pp^ := addr(prim_data);    {install data block pointer in call table}

  prim_data.res_version :=             {set to cache version about to become invalid}
    rend_prim_data_res_version;
  rend_prim_data_res_version :=        {make all the cached access flags invalid}
    rend_prim_data_res_version + 1;
  end;
