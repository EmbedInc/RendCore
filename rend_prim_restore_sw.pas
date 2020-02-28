{   Subroutine REND_PRIM_RESTORE_SW (CALL_P)
*
*   Restore the indicated call table entry to point to the current software device
*   routine for that entry.  CALL_P is the call table entry that points to the
*   routine entry point.
}
module rend_prim_restore_sw;
define rend_prim_restore_sw;
%include 'rend2.ins.pas';

procedure rend_prim_restore_sw (       {restore call table entry to software version}
  out     call_p: univ_ptr);           {call table entry pointing to subroutine entry}

var
  prim_data_pp: rend_prim_data_pp_t;   {adr of pointer to primitive data block}
  prim_sw_data_pp: rend_prim_data_pp_t; {adr of prim data block pointer in SW table}
  offset: integer32;                   {offset into particular call table}
  call_sw_pp: ^univ_ptr;               {adr of entry point pointer in SW call tab}
  sw_table_adr: integer32;             {start address of SW call table}

label
  found_table;

begin
{
*   Check for REND_PRIM call table.
}
  offset := integer32(addr(call_p)) - integer32(addr(rend_prim));
  if (offset >= 0) and (offset < sizeof(rend_prim)) then begin {in REND_PRIM table ?}
    sw_table_adr := integer32(addr(rend_sw_prim)); {set pointer to SW table start}
    goto found_table;
    end;
{
*   Check for REND_INTERNAL call table.
}
  offset := integer32(addr(call_p)) - integer32(addr(rend_internal));
  if (offset >= 0) and (offset < sizeof(rend_internal)) then begin {REND_INTERNAL ?}
    sw_table_adr := integer32(addr(rend_sw_internal)); {set pointer to SW table start}
    goto found_table;
    end;

  writeln ('REND_PRIM_RESTORE_SW called out of range of call tables.');
  sys_bomb;
{
*   CALL_P is within one of the legal call tables.  OFFSET is the byte offset of
*   CALL_P from the start of the table, and SW_TABLE_ADR is the address of the
*   start of the appropriate SW call table.
}
found_table:
  prim_data_pp := univ_ptr(            {adr of data block pointer in target table}
    sys_int_adr_t(addr(call_p)) + sizeof(call_p));
  call_sw_pp := univ_ptr(sw_table_adr + offset); {adr of call entry in SW table}
  prim_sw_data_pp := univ_ptr(         {adr of data block pointer in SW table}
    sys_int_adr_t(call_sw_pp) + sizeof(call_sw_pp^));
  call_p := call_sw_pp^;               {install routine entry pointer}
  prim_data_pp^ := prim_sw_data_pp^;   {install data block pointer}
  end;
