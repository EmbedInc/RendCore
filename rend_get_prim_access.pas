{   Subroutine REND_GET_PRIM_ACCESS (PRIM_DATA,SW_READ,SW_WRITE)
*
*   Resolve the final software bitmap access state for a particular primitive.
*   PRIM_DATA is the data block for the primitive.  SW_READ and SW_WRITE are returned
*   to indicate whether this primitive eventually causes reads or writes to/from
*   the software bitmap.  These flags will have values of with names
*   REND_ACCESS_xxx_K.  This subroutine will follow the chain of nested primitive
*   calls to resolve actual state when it is set to INHERITED in PRIM_DATA.
*   This routine will never return either flag with a value of REND_ACCESS_IHERITED_K.
}
module rend_get_prim_access;
define rend_get_prim_access;
%include 'rend2.ins.pas';

procedure rend_get_prim_access (       {resolve inherited primitive access flags}
  in out  prim_data: rend_prim_data_t; {data block for specific primitive}
  out     sw_read: rend_access_k_t;    {SW read access, use REND_ACCESS_xxx_K}
  out     sw_write: rend_access_k_t);  {SW write access, use REND_ACCESS_xxx_K}

var
  i: sys_int_machine_t;                {loop counter}
  swr, sww: rend_access_k_t;           {scratch read/write access flags}

begin
  if prim_data.res_version = rend_prim_data_res_version then begin {cache valid ?}
    sw_read := prim_data.sw_read_res;  {pass back resolved access flags from cache}
    sw_write := prim_data.sw_write_res;
    return;
    end;

  sw_read := prim_data.sw_read;        {init to direct values from data block}
  sw_write := prim_data.sw_write;
  prim_data.sw_read_res := prim_data.sw_read; {init resolved flags}
  prim_data.sw_write_res := prim_data.sw_write;
  prim_data.res_version :=             {set cache version to valid}
    rend_prim_data_res_version;

  for i := 1 to prim_data.n_prims do begin {once for each subordinate primitive}
    rend_get_prim_access (             {recursive call to resolve subordinate prim}
      prim_data.called_prims[i]^^,     {PRIM_DATA for subordinate primitive}
      swr, sww);                       {returned access flags}
    if ord(swr) > ord(sw_read)         {update accumulated access info}
      then sw_read := swr;
    if ord(sww) > ord(sw_write)
      then sw_write := sww;
    end;                               {back and process next nested primitive}

  prim_data.sw_read_res := sw_read;    {saved resolved access flags in cache}
  prim_data.sw_write_res := sw_write;
  end;
