{   Subroutine REND_SW_VECT_2D (X,Y)
*
*   Draw a vector in the 2D model coordinate space.
}
module rend_sw_vect_2d;
define rend_sw_vect_2d;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_vect_2d_d.ins.pas';

procedure rend_sw_vect_2d (            {vector from curr pnt to new absolute point}
  in      x, y: real);                 {coor of end point and new current point}
  val_param;

var
  x2, y2: real;                        {transformed vector end point}

begin
  x2 :=                                {transform X,Y to make vector end point}
    x*rend_2d.sp.xb.x + y*rend_2d.sp.yb.x + rend_2d.sp.ofs.x;
  y2 :=
    x*rend_2d.sp.xb.y + y*rend_2d.sp.yb.y + rend_2d.sp.ofs.y;
  rend_prim.vect_2dimcl^ (x2, y2);     {send tranformed vector on down the pipe}
  rend_2d.sp.cpnt.x := x;              {update 2D space current point}
  rend_2d.sp.cpnt.y := y;
  end;
