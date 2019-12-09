{   Subroutine REND_SW_ITERP_QUAD (ITERP,POINT,VAL,DX,DY,DXX,DYY,DXY)
*
*   Set quadratic value for this interpolant.
}
module rend_sw_iterp_quad;
define rend_sw_iterp_quad;
%include 'rend_sw2.ins.pas';

procedure rend_sw_iterp_quad (         {set interpolation to quadratic and init values}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      point: vect_2d_t;            {X,Y coordinates where VAL valid}
  in      val: real;                   {interpolant value at anchor point}
  in      dx, dy: real;                {first partials of val in X and Y at anchor}
  in      dxx, dyy, dxy: real);        {second derivatives for X, Y and crossover}
  val_param;

const
  max_msg_parms = 1;                   {max parameters we can pass to a message}

var
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;

begin
  if not rend_iterps.iterp[iterp].on then begin
    sys_msg_parm_int (msg_parm[1], ord(iterp));
    rend_message_bomb ('rend', 'rend_iterp_off_quad', msg_parm, 1);
    end;

  rend_iterps.iterp[iterp].x := point.x;
  rend_iterps.iterp[iterp].y := point.y;
  rend_iterps.iterp[iterp].aval := val;
  rend_iterps.iterp[iterp].adx := dx;
  rend_iterps.iterp[iterp].ady := dy;
  rend_iterps.iterp[iterp].adxx := dxx;
  rend_iterps.iterp[iterp].adyy := dyy;
  rend_iterps.iterp[iterp].adxy := dxy;

  if  (rend_iterps.iterp[iterp].mode = rend_iterp_mode_quad_k) and
      (rend_iterps.iterp[iterp].int = false)
    then return;                       {no modes being changed ?}
  rend_iterps.iterp[iterp].mode := rend_iterp_mode_quad_k;
  rend_iterps.iterp[iterp].int := false;
  rend_internal.check_modes^;          {update routine pointers and device modes}
  end;
