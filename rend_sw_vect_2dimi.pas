{   Subroutine REND_SW_VECT_2DIMI (IX,IY)
*
*   Draw a vector from the current point to the 2D integer image pixel coordinates
*   X,Y.  X,Y will become the new current point.  The vector will always go from
*   the center of the starting pixel to the center of the ending pixel.  Both end
*   point pixels will always be drawn.  Therefore, if the X,Y is the same coordinate
*   as the existing current point, then the pixel at the current point will be
*   drawn.
}
module rend_sw_vect_2dimi;
define rend_sw_vect_2dimi;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_vect_2dimi_d.ins.pas';

procedure rend_sw_vect_2dimi (         {integer 2D image space vector}
  in      ix, iy: sys_int_machine_t);  {pixel coordinate end point}
  val_param;

var
  sign_x, sign_y: sys_int_machine_t;   {1 or -1 values to indicate DX, DY signs}
  adx, ady: sys_int_machine_t;         {abs value of vector length along axies}
  step: rend_iterp_step_k_t;           {Bresenham step type ID}

label
  loop;

begin
  adx := ix-rend_lead_edge.x;          {signed vector X distance}
  if adx >= 0                          {check sign of vector X distance}
    then sign_x := 1                   {save sign of vector X distance}
    else sign_x := -1;
  adx := abs(adx);                     {make vector X length magnitude}
  ady := iy-rend_lead_edge.y;          {signed vector Y distance}
  if ady >= 0                          {check sign of vector Y distance}
    then sign_y := 1                   {save sign of vector Y distance}
    else sign_y := -1;
  ady := abs(ady);                     {make vector Y length magnitude}
  if adx >= ady                        {check for which is major axis}

    then begin                         {X is the major axis}
      rend_lead_edge.dxa := sign_x;    {X increment for an A step}
      rend_lead_edge.dxb := sign_x;    {X increment for a B step}
      rend_lead_edge.dya := 0;         {Y increment for an A step}
      rend_lead_edge.dyb := sign_y;    {Y increment for a B step}
      rend_lead_edge.err := 2*ady-adx; {initial error accumulator value}
      rend_lead_edge.dea := 2*ady;     {ERR increment for an A step}
      rend_lead_edge.deb := 2*(ady-adx); {ERR increment for a B step}
      rend_lead_edge.length := adx;    {number of steps to take to get to final pix}
      end

    else begin                         {Y is the major axis}
      rend_lead_edge.dxa := 0;
      rend_lead_edge.dxb := sign_x;
      rend_lead_edge.dya := sign_y;
      rend_lead_edge.dyb := sign_y;
      rend_lead_edge.err := 2*adx-ady;
      rend_lead_edge.dea := 2*adx;
      rend_lead_edge.deb := 2*(adx-ady);
      rend_lead_edge.length := ady;
      end
    ;
  rend_dir_flag := rend_dir_vect_k;    {indicate we are drawing a vector}
  rend_internal.setup_iterps^;         {set up interpolators for new A/B steps}

loop:                                  {back here each new pixel to draw}
  rend_prim.wpix^;                     {write this pixel}
  if rend_lead_edge.length <= 0 then return; {no more pixels to write ?}
  rend_sw_bres_step (                  {step the leading edge by one iteration}
    rend_lead_edge,                    {the Bresenham stepper to step}
    step);                             {ID of step that was taken}
  rend_sw_interpolate (step);          {advance the interpolators to the next pixel}
  goto loop;                           {back and draw the next pixel}
  end;
