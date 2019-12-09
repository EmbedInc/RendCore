{   Subroutine REND_SW_GET_READING_SW_PRIM (PRIM_P,SW_READ)
*
*   Find whether a specific primtive will read from the software bitmap under the
*   current conditions.  PRIM_P is the call table entry pointing to the primtive
*   subroutine.  SW_READ is returned TRUE if this primitive will read from the
*   software bitmap.
}
module rend_sw_get_reading_sw_prim;
define rend_sw_get_reading_sw_prim;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_reading_sw_prim ( {find of specific primitive reads from SW}
  in      prim_p: univ_ptr;            {call table entry for primitive to ask about}
  out     sw_read: boolean);           {TRUE if prim will read from SW bitmap}

var
  prim_data_pp: rend_prim_data_pp_t;   {address of pointer to prim data block}
  swr, sww: rend_access_k_t;           {read/write access flags for this primitive}

begin
  prim_data_pp := univ_ptr(            {make adr of data block pointer in call table}
    sys_int_adr_t(addr(prim_p)) + sizeof(prim_p));
  rend_get_prim_access (prim_data_pp^^, swr, sww); {get access flags for this prim}
  sw_read := (swr = rend_access_yes_k);
  end;
