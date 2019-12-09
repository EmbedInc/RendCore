{   Subroutine REND_SW_RCPNT_2DIMI (IDX,IDY)
*
*   Set new 2D integer image space current point by specifying displacement from
*   existing current point.
}
module rend_sw_rcpnt_2dimi;
define rend_sw_rcpnt_2dimi;
%include 'rend_sw2.ins.pas';

procedure rend_sw_rcpnt_2dimi (        {set current point with relative coordinates}
  in      idx, idy: sys_int_machine_t); {integer displacement from old current point}
  val_param;

var
  x, y: sys_int_machine_t;             {absolute coordinate of new curr point}

begin
  x := rend_lead_edge.x + idx;         {make new current point}
  y := rend_lead_edge.y + idy;
  rend_set.cpnt_2dimi^ (x, y);         {set new absolute current point}
  end;
