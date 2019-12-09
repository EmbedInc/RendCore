{   Subroutine REND_SW_RVECT_TEXT (DX,DY)
}
module rend_sw_rvect_text;
define rend_sw_rvect_text;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_rvect_text_d.ins.pas';

procedure rend_sw_rvect_text (         {relative vector from current point}
  in      dx, dy: real);               {displacement to end point and new curr pnt}
  val_param;

var
  x, y: real;                          {absolute coordinate of vector end point}

begin
  x := rend_text_state.sp.cpnt.x+dx;   {make absolute vector end point}
  y := rend_text_state.sp.cpnt.y+dy;
  rend_prim.vect_text^ (x, y);         {draw absolute vector}
  end;
