{   Subroutine REND_SW_BRES_STEP (BRES,STEP)
*
*   Step a Bresenham stepper by one iteration.  BRES is the Bresenham stepper state
*   block.  STEP is returned as the type of step taken to get to the new coordinate.
*   The step type is always A or B.
}
module rend_sw_bres_step;
define rend_sw_bres_step;
%include 'rend_sw2.ins.pas';

procedure rend_sw_bres_step (          {step a Bresenham vector gen by one iteration}
  in out  bres: rend_bresenham_t;      {the Bresenham stepper data structure}
  out     step: rend_iterp_step_k_t);  {type of step taken to get to new coordinate}

begin
  if bres.err >= 0                     {check for an A or B step}
    then begin                         {this is a B step}
      step := rend_iterp_step_b_k;
      bres.x := bres.x + bres.dxb;
      bres.y := bres.y + bres.dyb;
      bres.err := bres.err + bres.deb;
      end
    else begin                         {this is an A step}
      step := rend_iterp_step_a_k;
      bres.x := bres.x + bres.dxa;
      bres.y := bres.y + bres.dya;
      bres.err := bres.err + bres.dea;
      end
    ;
  bres.length := bres.length-1;        {one less step to get to last pixel}
  end;
