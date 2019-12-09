{   Subroutine REND_SW_VECT_TEXT (X,Y)
*
*   Draw vector in TEXT coordinate space.
}
module rend_sw_vect_text;
define rend_sw_vect_text;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_vect_text_d.ins.pas';

procedure rend_sw_vect_text (          {vector from curr pnt to new absolute point}
  in      x, y: real);                 {coor of end point and new current point}
  val_param;

var
  xy2: vect_2d_t;                      {transformed vector end point}

begin
  rend_text_state.sp.cpnt.x := x;      {update text space current point}
  rend_text_state.sp.cpnt.y := y;
  rend_get.xfpnt_text^ (               {transform vector end point to TXDRAW space}
    rend_text_state.sp.cpnt,           {input point in TEXT space}
    xy2);                              {output point in TXDRAW space}
  rend_prim.vect_txdraw^ (xy2.x, xy2.y); {send vector on to rest of pipe}
  end;
