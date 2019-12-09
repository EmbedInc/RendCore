{   Subroutine REND_SW_ITERP_LINEAR (ITERP,POINT,VAL,DX,DY)
*
*   Set linear value for this interpolant.
}
module rend_sw_iterp_linear;
define rend_sw_iterp_linear;
%include 'rend_sw2.ins.pas';

procedure rend_sw_iterp_linear (       {set interpolation to linear and init values}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      point: vect_2d_t;            {X,Y coordinates where VAL valid}
  in      val: real;                   {interpolant value at anchor point}
  in      dx, dy: real);               {first partials of val in X and Y direction}
  val_param;

const
  max_msg_parms = 1;                   {max parameters we can pass to a message}

var
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;

begin
  with rend_iterps.iterp[iterp]: it do begin {IT is abbrev for this interpolant}
    if not it.on then begin            {interpolant is OFF ?}
      sys_msg_parm_int (msg_parm[1], ord(iterp));
      rend_message_bomb ('rend', 'rend_iterp_off_linear', msg_parm, 1);
      end;

    it.x := point.x;
    it.y := point.y;
    it.aval := val;
    it.adx := dx;
    it.ady := dy;
    it.adxx := 0.0;
    it.adyy := 0.0;
    it.adxy := 0.0;

    if  (it.mode = rend_iterp_mode_linear_k) and
        (not it.int)
      then return;                     {no modes being changed ?}

    it.mode := rend_iterp_mode_linear_k;
    it.int := false;

    rend_internal.check_modes^;        {update routine pointers and device modes}
    end;                               {done with IT abbreviation}
  end;
