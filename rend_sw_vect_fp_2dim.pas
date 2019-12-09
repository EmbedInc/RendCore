{   Subroutine REND_SW_VECT_FP_2DIM (X,Y)
*
*   Draw a vector in the 2D image coordinate space using floating point (sub pixel)
*   addressing.
}
module rend_sw_vect_fp_2dim;
define rend_sw_vect_fp_2dim;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_vect_fp_2dim_d.ins.pas';

procedure rend_sw_vect_fp_2dim (       {2D image space vector using subpixel adr}
  in      x, y: real);                 {coor of end point and new current point}
  val_param;

var
  xmajor: boolean;                     {TRUE if X is the major axis}
  step: rend_iterp_step_k_t;           {what kind of step the Bresenham just took}

label
  loop, done_draw;

begin
  xmajor :=                            {set major axis select flag}
    abs(x-rend_2d.curr_x2dim) >= abs(y-rend_2d.curr_y2dim);
  rend_dir_flag := rend_dir_vect_k;    {indicate we are drawing a vector}
  rend_sw_bres_fp (                    {set up the Bresenham stepper}
    rend_lead_edge,                    {Bresenham stepper data block}
    rend_2d.curr_x2dim, rend_2d.curr_y2dim, {starting point coordinate}
    x, y,                              {ending point coordinate}
    xmajor);                           {major axis select flag}
  if rend_lead_edge.length <= 0 then goto done_draw; {no pixels to write ?}
  rend_set.cpnt_2dimi^ (               {set start pixel as current point}
    rend_lead_edge.x, rend_lead_edge.y);
  rend_internal.setup_iterps^;         {set up interpolators for new A/B steps}
  rend_lead_edge.length := rend_lead_edge.length-1; {make number of interpolates to do}

loop:                                  {back here each new pixel to draw}
  rend_prim.wpix^;                     {write this pixel}
  if rend_lead_edge.length <= 0 then goto done_draw; {no more pixels to write ?}
  rend_sw_bres_step (                  {step the leading edge by one iteration}
    rend_lead_edge,                    {tell the Bresenham stepper to step}
    step);                             {ID of step that was taken}
  rend_sw_interpolate (step);          {advance the interpolators to the next pixel}
  goto loop;                           {back and draw the next pixel}

done_draw:                             {everyone comes here after all pixels drawn}
  rend_set.cpnt_2dim^ (x, y);          {update current point to end of vector}
  end;
