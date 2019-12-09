{   Subroutine REND_SW_RCPNT_TEXT (DX, DY)
*
*   Set new TEXT coordinate space current point by specifying displacement from
*   existing current point.
}
module rend_sw_rcpnt_text;
define rend_sw_rcpnt_text;
%include 'rend_sw2.ins.pas';

procedure rend_sw_rcpnt_text (         {set current point with relative coordinates}
  in      dx, dy: real);               {displacement from old current point}
  val_param;

var
  x, y: real;                          {absolute coordinate of new curr point}

begin
  x := rend_text_state.sp.cpnt.x + dx; {make new current point}
  y := rend_text_state.sp.cpnt.y + dy;
  rend_set.cpnt_text^ (x, y);          {set new absolute current point}
  end;
