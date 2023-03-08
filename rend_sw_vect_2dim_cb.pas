{   Subroutine REND_SW_VECT_2DIM_CB (X,Y)
*
*   PRIM.VECT_2DIM routine that does an app callback instead of drawing
*   anything.
*
*   PRIM_DATA SW_READ NO
*   PRIM_DATA SW_WRITE NO
}
module rend_sw_vect_2dim_cb;
define rend_sw_vect_2dim_cb;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_vect_2dim_cb_d.ins.pas';

procedure rend_sw_vect_2dim_cb (       {PRIM.VECT_2DIM that does app callback}
  in      x, y: real);                 {coor of end point and new current point}
  val_param;

begin
  rend_callback.vect_2dim_call_p^ (    {do the callback}
    rend_callback.vect_2dim_state_p,   {to app private state}
    x, y);                             {vector end point and new current point}

  rend_2d.curr_x2dim := x;             {update 2DIM floating point current point}
  rend_2d.curr_y2dim := y;
  end;
