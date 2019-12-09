{   REND_SW_TZOID
*
*   Draw the pixels of a trapezoid.  All the interpolators and the Bresenham steppers
*   have already been set up.
}
module rend_sw_tzoid;
define rend_sw_tzoid;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_tzoid_d.ins.pas';

procedure rend_sw_tzoid;

var
  xlen: sys_int_machine_t;             {number of pixels to draw on curr scan line}
  i, j: sys_int_machine_t;             {loop counters}
  step: rend_iterp_step_k_t;           {Bresenham step type}

begin
  for i := 1 to min(rend_lead_edge.length, rend_trail_edge.length) do begin
    if rend_dir_flag = rend_dir_right_k {which direction are we scanning}
      then                             {left-to-right}
        xlen := rend_trail_edge.x-rend_lead_edge.x
      else                             {right-to-left}
        xlen := rend_lead_edge.x-rend_trail_edge.x
      ;
    for j := 1 to xlen do begin        {once for each pixel on this scan line}
      rend_prim.wpix^;                 {write this pixel}
      if j < xlen then begin           {not last pixel on this scan line ?}
        rend_sw_interpolate (rend_iterp_step_h_k); {do horizontal interpolation step}
        end;
      end;                             {back and do next pixel on this scan line}
    rend_sw_bres_step (rend_trail_edge, step); {go to next scan line on trailing edge}
    rend_sw_bres_step (rend_lead_edge, step); {next scan line on leading edge}
    rend_sw_interpolate (step);        {set up interpolators for new scan line}
    end;                               {back and do new scan line}
  end;
