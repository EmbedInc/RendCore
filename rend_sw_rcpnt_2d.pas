{   Subroutine REND_SW_RCPNT_2D (DX, DY)
*
*   Set new 2D model coordinate space current point by specifying displacement from
*   existing current point.
}
module rend_sw_rcpnt_2d;
define rend_sw_rcpnt_2d;
%include 'rend_sw2.ins.pas';

procedure rend_sw_rcpnt_2d (           {set current point with relative coordinates}
  in      dx, dy: real);               {displacement from old current point}
  val_param;

var
  x, y: real;                          {absolute coordinate of new curr point}

begin
  x := rend_2d.sp.cpnt.x+dx;           {make new current point}
  y := rend_2d.sp.cpnt.y+dy;
  rend_set.cpnt_2d^ (x, y);            {set new absolute current point}
  end;
