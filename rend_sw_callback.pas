{   Software driver routines related to app callbacks.
}
module rend_sw_callback;
define rend_sw_cpnt_2dim_cb;
%include 'rend_sw2.ins.pas';
{
********************************************************************************
*
*   SET.CPNT_2DIM routine that does app callback.
}
procedure rend_sw_cpnt_2dim_cb (       {SET.CPNT_2DIM that does app callback}
  in      x, y: real);                 {new coordinates of curr pnt in this space}
  val_param;

begin
  rend_callback.cpnt_2dim_call_p^ (    {do the callback}
    rend_callback.cpnt_2dim_state_p,   {app context for this callback}
    x, y);                             {new 2DIM current point}

  rend_2d.curr_x2dim := x;             {save 2DIM floating point current point}
  rend_2d.curr_y2dim := y;
  end;
