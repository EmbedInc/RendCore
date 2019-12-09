{   Subroutine REND_SW_SPAN2_2DIMCL (LEN,PIXELS)
*
*   Write span of pixels into current open SPAN/RUN rectangle.  See
*   REND_SW_SPAN_2DIMCL.PAS for details.
*
*   This is an optimized routine.  The following assumptions are made:
*
*   1) All ON interpolants are 8 bits wide.
*
*   2) Alpha buffering, texture mapping and Z buffering are all OFF.
*
*   3) All pixel functions are set to INSERT.
*
*   4) Interpolator clamping is either OFF, or limits set to 0 - 255.
*
*   5) All ON interpolants are enabled for SPAN/RUN.
*
*   6) All write mask bits are enabled.
*
*   PRIM_DATA sw_write yes
*   PRIM_DATA sw_read no
}
module rend_sw_span2_2dimcl;
define rend_sw_span2_2dimcl;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_span2_2dimcl_d.ins.pas';

procedure rend_sw_span2_2dimcl (       {write horizontal span of pixels into RECT_PX}
  in      len: sys_int_machine_t;      {number of pixels in span}
  in      pixels: univ char);          {span formatted as currently configured}
  val_param;

var
  pix_adr: sys_int_adr_t;              {address of current source pixel}
  span_left: sys_int_machine_t;        {number of pixels left in span}
  n: sys_int_machine_t;                {number of pixels being processes}
  i: sys_int_machine_t;                {loop counter}
  iterp: sys_int_machine_t;            {current interpolant ID}
  val_adr: rend_iterp_data_pnt_t;      {adr of span data for current interpolant}
  step: rend_iterp_step_k_t;           {Bresenham step type}

begin
  if rend_rectpx.xlen <= 0 then return; {all done or all clipped ?}
  pix_adr := sys_int_adr_t(addr(pixels)); {init address of first pixel in span}
  span_left := len;                    {init number of pixels to process}
  while span_left > 0 do begin         {keep looping until exhausted span}

    if rend_rectpx.skip_curr > 0 then begin {we need to skip over some pixels ?}
      n := min(span_left, rend_rectpx.skip_curr); {pixels to actually skip}
      rend_rectpx.skip_curr :=         {fewer pixels left to skip}
        rend_rectpx.skip_curr - n;
      span_left := span_left - n;      {fewer pixels left to process}
      pix_adr := pix_adr +             {update pointer to new span pixel}
        (rend_span.pxsize * n);
      next;                            {process what's left of this span}
      end;                             {done skipping over pixels}

    n := min(span_left, rend_rectpx.left_line); {scan line pixels to process now}
    for i := 1 to n do begin           {once for each pixel to process}
      for iterp := 1 to rend_iterps.n_on do begin {once for each ON interpolant}
        with
          rend_iterps.list_on[iterp]^: iterp {ITERP is this interpolant}
          do begin
        val_adr.i :=                   {make adr of our source data in span pixel}
          pix_adr + iterp.span_offset;
        iterp.curr_adr.p8^ := val_adr.p8^; {copy from span into bitmap}
        if rend_dir_flag = rend_dir_right_k
          then begin                   {scanning left to right}
            iterp.curr_adr.i :=
              iterp.curr_adr.i + iterp.bitmap_p^.x_offset
            end
          else begin                   {scanning right to left}
            iterp.curr_adr.i :=
              iterp.curr_adr.i - iterp.bitmap_p^.x_offset
            end
          ;
        end;                           {done with ITERP abbreviation}
        end;                           {back and process next interpolant}
      if rend_dir_flag = rend_dir_right_k
        then begin                     {scanning left to right}
          rend_curr_x := rend_curr_x + 1; {update X coordinate}
          end
        else begin                     {scanning right to left}
          rend_curr_x := rend_curr_x - 1; {update X coordinate}
          end
        ;
      pix_adr :=                       {update pointer to next span pixel}
        pix_adr + rend_span.pxsize;
      rend_rectpx.left_line :=         {one less pixel to do this scan line}
        rend_rectpx.left_line - 1;

      if rend_rectpx.left_line <= 0 then begin {last pixel on this scan line ?}
        if not rend_dirty_crect then begin
          if rend_dir_flag = rend_dir_right_k
            then begin                 {scanning left to right}
              rend_internal.update_span^ (
                rend_lead_edge.x,      {span left end coordinate}
                rend_lead_edge.y,
                rend_curr_x - rend_lead_edge.x); {span length}
              end
            else begin                 {scanning right to left}
              rend_internal.update_span^ (
                rend_curr_x + 1,       {span left end coordinate}
                rend_lead_edge.y,
                rend_lead_edge.x - rend_curr_x); {span length}
              end
            ;
          end;
        rend_sw_bres_step (rend_lead_edge, step); {next scan line on leading edge}
        if rend_lead_edge.length <= 0 then begin {finished whole rectangle ?}
          rend_rectpx.xlen := 0;       {indicate all done with rectangle}
          return;
          end;
        rend_sw_interpolate (step);    {set up interpolators for new scan line}
        rend_rectpx.left_line :=       {init number of pixels to draw next line}
          rend_rectpx.xlen;
        rend_rectpx.skip_curr :=       {set span pixels to skip before new line}
          rend_rectpx.skip_line;
        end;                           {done handling last pixel on scan line}

      end;                             {back and process next pixel on scan line}
      span_left := span_left - n;      {fewer span pixels left to process}
    end;                               {back and process next span pixel}
  end;
