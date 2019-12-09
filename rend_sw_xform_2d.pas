{   Subroutine REND_SW_XFORM_2D (XB,YB,OFS)
*
*   Set the user-view 2D transformation matrix.  This transform converts from 2D
*   model coordinate space to the +-1.0 image coordinate space.
}
module rend_sw_xform_2d;
define rend_sw_xform_2d;
%include 'rend_sw2.ins.pas';

procedure rend_sw_xform_2d (           {set new absolute 2D transform}
  in      xb: vect_2d_t;               {X basis vector}
  in      yb: vect_2d_t;               {Y basis vector}
  in      ofs: vect_2d_t);             {offset vector}

begin
  rend_2d.uxb.x := xb.x;
  rend_2d.uxb.y := xb.y;
  rend_2d.uyb.x := yb.x;
  rend_2d.uyb.y := yb.y;
  rend_2d.uofs.x := ofs.x;
  rend_2d.uofs.y := ofs.y;
  rend_sw_update_xf2d;                 {update internal 2D transform}
  end;
