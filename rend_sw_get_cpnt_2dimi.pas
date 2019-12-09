{   Subroutine REND_SW_GET_CPNT_2DIMI (X,Y)
*
*   Read back 2D integer image space current point.
}
module rend_sw_get_cpnt_2dimi;
define rend_sw_get_cpnt_2dimi;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_cpnt_2dimi (     {return the current point}
  out     ix, iy: sys_int_machine_t);  {integer pixel address of current point}

begin
  ix := rend_lead_edge.x;
  iy := rend_lead_edge.y;
  end;
