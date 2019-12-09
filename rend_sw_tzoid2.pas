{   Subroutine REND_SW_TZOID2
*
*   Draw the pixels of a trapezoid.  All the interpolators and the Bresenham steppers
*   have already been set up.
*
*   NOTE:  This a special optimized routine.  The restriction are:
*
*     1)  The enabled interpolants must be exactly red, green, blue, and Z.
*
*     2)  RGBZ PIXFUN = INSERT.
*
*     3)  Z buffering on, ZFUNC = GT.
*
*     4)  Interpolation mode either flat or linear for red, green, blue, and Z.
*
*     5)  RGBZ all write mask bits 1.
*
*     6)  Alpha buffering off, texture mapping off.
*
*     7)  RGBZ pixel clamping OFF.
*
*   PRIM_DATA sw_read yes
*   PRIM_DATA sw_write yes
}
module rend_sw_tzoid2;
define rend_sw_tzoid2;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_tzoid2_d.ins.pas';

procedure rend_sw_tzoid2;              {trapezoid, linear RGBZ}

var
  xlen: sys_int_machine_t;             {number of pixels to draw on curr scan line}
  i, j: sys_int_machine_t;             {loop counters}

  red, grn, blu, z: rend_iterp_val_t;  {current interpolator values}
  red_inc, grn_inc, blu_inc, z_inc:    {horizontal step interpolator increments}
    sys_int_machine_t;
  red_p, grn_p, blu_p: ^char;          {pointers to color pixel data}
  z_p: ^integer16;                     {pointer to Z pixel data}
  red_p_inc, grn_p_inc, blu_p_inc, z_p_inc: {horizontal offset for pixel data pntrs}
    sys_int_adr_t;

begin
{
*   Later when stepping to the next scan line, we will assume that the RGBZ
*   interpolants are set to linear.  Therefore, check for interpolants that are
*   actually set to flat, and set the derivatives used later to zero.
}
  if rend_iterps.red.mode = rend_iterp_mode_flat_k then begin {check red interpolant}
    rend_iterps.red.edh.all := 0;
    rend_iterps.red.eda.all := 0;
    rend_iterps.red.edb.all := 0;
    end;
  if rend_iterps.grn.mode = rend_iterp_mode_flat_k then begin {check green interpolant}
    rend_iterps.grn.edh.all := 0;
    rend_iterps.grn.eda.all := 0;
    rend_iterps.grn.edb.all := 0;
    end;
  if rend_iterps.blu.mode = rend_iterp_mode_flat_k then begin {check blue interpolant}
    rend_iterps.blu.edh.all := 0;
    rend_iterps.blu.eda.all := 0;
    rend_iterps.blu.edb.all := 0;
    end;
  if rend_iterps.z.mode = rend_iterp_mode_flat_k then begin {check Z interpolant}
    rend_iterps.z.edh.all := 0;
    rend_iterps.z.eda.all := 0;
    rend_iterps.z.edb.all := 0;
    end;

  if rend_dir_flag = rend_dir_right_k  {which direction are we scanning}
    then begin                         {left-to-right}
      red_p_inc := rend_iterps.red.bitmap_p^.x_offset;
      grn_p_inc := rend_iterps.grn.bitmap_p^.x_offset;
      blu_p_inc := rend_iterps.blu.bitmap_p^.x_offset;
      z_p_inc := rend_iterps.z.bitmap_p^.x_offset;
      end
    else begin                         {right-to-left}
      red_p_inc := -rend_iterps.red.bitmap_p^.x_offset;
      grn_p_inc := -rend_iterps.grn.bitmap_p^.x_offset;
      blu_p_inc := -rend_iterps.blu.bitmap_p^.x_offset;
      z_p_inc := -rend_iterps.z.bitmap_p^.x_offset;
      end
    ;
  red_inc := rend_iterps.red.edh.all;
  grn_inc := rend_iterps.grn.edh.all;
  blu_inc := rend_iterps.blu.edh.all;
  z_inc := rend_iterps.z.edh.all;

  for i := 1 to min(rend_lead_edge.length, rend_trail_edge.length) do begin
    if rend_dir_flag = rend_dir_right_k {which direction are we scanning}
      then begin                       {left-to-right}
        xlen := rend_trail_edge.x-rend_lead_edge.x;
        end
      else begin                       {right-to-left}
        xlen := rend_lead_edge.x-rend_trail_edge.x;
        end
      ;
    red := rend_iterps.red.eval;       {get starting interpolant evals}
    grn := rend_iterps.grn.eval;
    blu := rend_iterps.blu.eval;
    z := rend_iterps.z.eval;
    red_p := univ_ptr(rend_iterps.red.curr_adr.p8); {get starting pixel data addresses}
    grn_p := univ_ptr(rend_iterps.grn.curr_adr.p8);
    blu_p := univ_ptr(rend_iterps.blu.curr_adr.p8);
    z_p := univ_ptr(rend_iterps.z.curr_adr.p16);

    for j := 1 to xlen do begin        {once for each pixel on this scan line}
      if z.val16 > z_p^ then begin     {this pixel not Z inhibited ?}
        red_p^ := chr(red.val8);       {write into this pixel}
        grn_p^ := chr(grn.val8);
        blu_p^ := chr(blu.val8);
        z_p^ := z.val16;
        end;
      red.all := red.all + red_inc;    {make values for next pixel}
      grn.all := grn.all + grn_inc;
      blu.all := blu.all + blu_inc;
      z.all := z.all + z_inc;
      red_p := univ_ptr(sys_int_adr_t(red_p) + red_p_inc); {point to next pixel}
      grn_p := univ_ptr(sys_int_adr_t(grn_p) + grn_p_inc);
      blu_p := univ_ptr(sys_int_adr_t(blu_p) + blu_p_inc);
      z_p := univ_ptr(sys_int_adr_t(z_p) + z_p_inc);
      end;                             {back and do next pixel on this scan line}

    if not rend_dirty_crect then begin
      if rend_dir_flag = rend_dir_right_k {check which end of span curr pnt is on}
        then begin                     {current point started on left end of span}
          rend_internal.update_span^ ( {notify device we touched region on scan line}
            rend_lead_edge.x,          {left pixel coordinate of span}
            rend_lead_edge.y,
            xlen);                     {number of pixels in span}
          end
        else begin                     {current point started on right end of span}
          rend_internal.update_span^ ( {notify device we touched region on scan line}
            rend_trail_edge.x + 1,     {left pixel coordinate of span}
            rend_lead_edge.y,
            xlen);                     {number of pixels in span}
          end
        ;                              {done checking scan direction}
      end;

    if rend_trail_edge.err >= 0        {check for an A or B step}
      then begin                       {this is a B step}
        rend_trail_edge.x := rend_trail_edge.x + rend_trail_edge.dxb;
        rend_trail_edge.y := rend_trail_edge.y + rend_trail_edge.dyb;
        rend_trail_edge.err := rend_trail_edge.err + rend_trail_edge.deb;
        end
      else begin                       {this is an A step}
        rend_trail_edge.x := rend_trail_edge.x + rend_trail_edge.dxa;
        rend_trail_edge.y := rend_trail_edge.y + rend_trail_edge.dya;
        rend_trail_edge.err := rend_trail_edge.err + rend_trail_edge.dea;
        end
      ;
    rend_trail_edge.length := rend_trail_edge.length-1; {one less step to get to last pixel}

    if rend_lead_edge.err >= 0         {check for an A or B step}
      then begin                       {this is a B step}
        rend_lead_edge.x := rend_lead_edge.x + rend_lead_edge.dxb;
        rend_lead_edge.y := rend_lead_edge.y + rend_lead_edge.dyb;
        rend_lead_edge.err := rend_lead_edge.err + rend_lead_edge.deb;
        rend_iterps.red.eval.all := rend_iterps.red.eval.all + rend_iterps.red.edb.all;
        rend_iterps.grn.eval.all := rend_iterps.grn.eval.all + rend_iterps.grn.edb.all;
        rend_iterps.blu.eval.all := rend_iterps.blu.eval.all + rend_iterps.blu.edb.all;
        rend_iterps.z.eval.all := rend_iterps.z.eval.all + rend_iterps.z.edb.all;
        end
      else begin                       {this is an A step}
        rend_lead_edge.x := rend_lead_edge.x + rend_lead_edge.dxa;
        rend_lead_edge.y := rend_lead_edge.y + rend_lead_edge.dya;
        rend_lead_edge.err := rend_lead_edge.err + rend_lead_edge.dea;
        rend_iterps.red.eval.all := rend_iterps.red.eval.all + rend_iterps.red.eda.all;
        rend_iterps.grn.eval.all := rend_iterps.grn.eval.all + rend_iterps.grn.eda.all;
        rend_iterps.blu.eval.all := rend_iterps.blu.eval.all + rend_iterps.blu.eda.all;
        rend_iterps.z.eval.all := rend_iterps.z.eval.all + rend_iterps.z.eda.all;
        end
      ;
    rend_lead_edge.length := rend_lead_edge.length-1; {one less step to get to last pixel}

    rend_iterps.red.curr_adr.i :=      {make new red pixel data address}
      sys_int_adr_t(rend_iterps.red.bitmap_p^.line_p[rend_lead_edge.y]) {start adr of scan line}
      + rend_lead_edge.x*rend_iterps.red.bitmap_p^.x_offset {pixel offset into scan line}
      + rend_iterps.red.iterp_offset;  {byte offset into pixel}
    rend_iterps.grn.curr_adr.i :=      {make new green pixel data address}
      sys_int_adr_t(rend_iterps.grn.bitmap_p^.line_p[rend_lead_edge.y]) {start adr of scan line}
      + rend_lead_edge.x*rend_iterps.grn.bitmap_p^.x_offset {pixel offset into scan line}
      + rend_iterps.grn.iterp_offset;  {byte offset into pixel}
    rend_iterps.blu.curr_adr.i :=      {make new blue pixel data address}
      sys_int_adr_t(rend_iterps.blu.bitmap_p^.line_p[rend_lead_edge.y]) {start adr of scan line}
      + rend_lead_edge.x*rend_iterps.blu.bitmap_p^.x_offset {pixel offset into scan line}
      + rend_iterps.blu.iterp_offset;  {byte offset into pixel}
    rend_iterps.z.curr_adr.i :=        {make new Z pixel data address}
      sys_int_adr_t(rend_iterps.z.bitmap_p^.line_p[rend_lead_edge.y]) {start adr of scan line}
      + rend_lead_edge.x*rend_iterps.z.bitmap_p^.x_offset {pixel offset into scan line}
      + rend_iterps.z.iterp_offset;    {byte offset into pixel}
    end;                               {back and do new scan line}
{
*   Fix interpolants since short cuts were taken in this optimized routine.  This
*   section will leave them in the same state as the normal routine does.
}
  rend_iterps.red.val.all := rend_iterps.red.eval.all;
  rend_iterps.red.value.all := rend_iterps.red.eval.all;
  rend_iterps.grn.val.all := rend_iterps.grn.eval.all;
  rend_iterps.grn.value.all := rend_iterps.grn.eval.all;
  rend_iterps.blu.val.all := rend_iterps.blu.eval.all;
  rend_iterps.blu.value.all := rend_iterps.blu.eval.all;
  rend_iterps.z.val.all := rend_iterps.z.eval.all;
  rend_iterps.z.value.all := rend_iterps.z.eval.all;
  end;
