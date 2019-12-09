{   Subroutine REND_RESET_CALL_TABLES
*
*   Load all the routine pointers in the call tables to illegal values.
*   This should be done whenever there is definately no current device,
*   such immediately following REND_START, or REND_SET.CLOSE^.  An
*   application that tries to use such a call table entry will immediately
*   get some sort illegal memory reference error.
}
module rend_reset_call_tables;
define rend_reset_call_tables;
%include 'rend2.ins.pas';

procedure rend_reset_call_tables;

type
  table_t = array[1..1] of univ_ptr;   {generic table of pointers}
{
***************************************************
*
*   Local subroutine INIT_TABLE (TABLE, N)
*
*   Writes N consecutive NIL pointers starting at TABLE.
}
procedure init_table (
  out     table: univ table_t;         {table to initialize}
  in      n: sys_int_machine_t);       {number of entries in table}
  val_param;

var
  i: sys_int_machine_t;                {loop counter}

begin
  for i := 1 to n do begin             {once for each table entry}
    table[i] := nil;
    end;
  end;
{
***************************************************
*
*   Start of main routine.
}
begin
  init_table (rend_prim,        sizeof(rend_prim)        div sizeof(univ_ptr));
  init_table (rend_sw_prim,     sizeof(rend_sw_prim)     div sizeof(univ_ptr));
  init_table (rend_set,         sizeof(rend_set)         div sizeof(univ_ptr));
  init_table (rend_sw_set,      sizeof(rend_sw_set)      div sizeof(univ_ptr));
  init_table (rend_get,         sizeof(rend_get)         div sizeof(univ_ptr));
  init_table (rend_sw_get,      sizeof(rend_sw_get)      div sizeof(univ_ptr));
  init_table (rend_internal,    sizeof(rend_internal)    div sizeof(univ_ptr));
  init_table (rend_sw_internal, sizeof(rend_sw_internal) div sizeof(univ_ptr));
  end;
