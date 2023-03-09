{   Subroutine REND_SW_CPNT_2D (X,Y)
*
*   Set the current point by specifying a new 2D model space coordinate.
}
module rend_sw_cpnt_2d;
define rend_sw_cpnt_2d;
%include 'rend_sw2.ins.pas';

procedure rend_sw_cpnt_2d (            {set current point with absolute coordinates}
  in      x, y: real);                 {new coordinates of curr pnt in this space}
  val_param;

begin
  rend_2d.sp.cpnt.x := x;              {save 2D model space current point coor}
  rend_2d.sp.cpnt.y := y;

  rend_set.cpnt_2dim^ (                {set image space current point}
    x*rend_2d.sp.xb.x + y*rend_2d.sp.yb.x + rend_2d.sp.ofs.x,
    x*rend_2d.sp.xb.y + y*rend_2d.sp.yb.y + rend_2d.sp.ofs.y);
  end;
