{   Subroutine REND_SW_ITERP_FLAT (ITERP,VAL)
*
*   Set flat value for this interpolant.
}
module rend_sw_iterp_flat;
define rend_sw_iterp_flat;
%include 'rend_sw2.ins.pas';

procedure rend_sw_iterp_flat (         {set interpolation to flat and init values}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      val: real);                  {0.0 to 1.0 interpolant value}
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
      rend_message_bomb ('rend', 'rend_iterp_off_flat', msg_parm, 1);
      end;

    it.x := 0.0;
    it.y := 0.0;
    it.aval := val;                    {set flat color value}
    it.adx := 0.0;
    it.ady := 0.0;
    it.adxx := 0.0;
    it.adyy := 0.0;
    it.adxy := 0.0;

    if                                 {no modes are changing ?}
        (it.mode = rend_iterp_mode_flat_k) and
        (not it.int)
      then return;

    it.mode := rend_iterp_mode_flat_k;
    it.int := false;

    rend_internal.check_modes^;        {update routine pointers and device modes}
    end;                               {done with IT abbreviation}
  end;
