{   Subroutine REND_SW_CPNT_TEXT (X,Y)
*
*   Set new current point in TEXT coordinate space.
}
module rend_sw_cpnt_text;
define rend_sw_cpnt_text;
%include 'rend_sw2.ins.pas';

procedure rend_sw_cpnt_text (          {set current point with absolute coordinates}
  in      x, y: real);                 {new coordinates of curr pnt in this space}
  val_param;

var
  xy: vect_2d_t;                       {X,Y transformed to TXDRAW space}

begin
  rend_text_state.sp.cpnt.x := x;      {save current point at TEXT level}
  rend_text_state.sp.cpnt.y := y;
  rend_get.xfpnt_text^ (               {transform point to TXDRAW space}
    rend_text_state.sp.cpnt,           {input point in TEXT space}
    xy);                               {output point in TXDRAW space}
  rend_set.cpnt_txdraw^ (xy.x, xy.y);  {send transformed current point on down pipe}
  end;
