{   Subroutine REND_SW_SPAN_2DIMCL (LEN,PIXELS)
*
*   Write a span of pixels.  A span of pixels is a horizontally consecutive set
*   of pixels.  LEN is the number of pixels in the span.  PIXELS is
*   the array of pixels.  The data format of PIXELS is set with the calls
*   REND_SET.ITERP_SPAN_OFS and REND_SET.SPAN_CONFIG.
*
*   The span of pixels will be written into the next pixel position within the
*   current rectangle defined by the primitive REND_PRIM.RECT_PX_2DIMCL.
*   See the header comments for REND_SW_RECT_PX_2DIMCL for more details on this.
*
*   All ON interpolants will write, but only the ones enabled with
*   REND_SET.ITERP_SPAN_ON will have their interpolator values superceeded by the
*   data in PIXELS.  See header comments of REND_SW_ITERP_SPAN_ON.PAS for details
*   about this.
}
module rend_sw_span_2dimcl;
define rend_sw_span_2dimcl;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_span_2dimcl_d.ins.pas';

procedure rend_sw_span_2dimcl (        {write horizontal span of pixels}
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
        if not iterp.span_run then next; {this interpolant not ON for SPAN}
        val_adr.i :=                   {make adr of our source data in span pixel}
          pix_adr + iterp.span_offset;
        iterp.val.all := 0;            {init unused bits}
        case iterp.width of            {replace interpolator output with source val}
8:        iterp.val.val8 := ord(val_adr.p8^);
16:       iterp.val.val16 := val_adr.p16^;
32:       iterp.val.all := val_adr.p32^;
          end;                         {done with width cases, VAL all set}
        iterp.value := iterp.val;      {init final clamped output value}
        if iterp.iclamp then begin     {need to clip interpolator result ?}
          if iterp.value.all > iterp.iclamp_max.all
            then iterp.value := iterp.iclamp_max;
          if iterp.value.all < iterp.iclamp_min.all
            then iterp.value := iterp.iclamp_min;
          end;                         {done handling interpolator clamping}
        end;                           {done with ITERP abbreviation}
        end;                           {back and process next interpolant}
      rend_prim.wpix^;                 {write this pixel}
      pix_adr :=                       {update pointer to next span pixel}
        pix_adr + rend_span.pxsize;
      rend_rectpx.left_line :=         {one less pixel to do this scan line}
        rend_rectpx.left_line - 1;

      if rend_rectpx.left_line > 0
        then begin                     {this was not last pixel on scan line}
          rend_sw_interpolate (rend_iterp_step_h_k); {step to next pixel accross}
          end
        else begin                     {we just drew last pixel on this scan line}
          rend_sw_bres_step (rend_lead_edge, step); {next scan line on leading edge}
          if rend_lead_edge.length <= 0 then begin {finished whole rectangle ?}
            rend_rectpx.xlen := 0;     {indicate all done with rectangle}
            return;
            end;
          rend_sw_interpolate (step);  {set up interpolators for new scan line}
          rend_rectpx.left_line :=     {init number of pixels to draw next line}
            rend_rectpx.xlen;
          rend_rectpx.skip_curr :=     {set span pixels to skip before new line}
            rend_rectpx.skip_line;
          end
        ;
      end;                             {back and process next pixel on scan line}
      span_left := span_left - n;      {fewer span pixels left to process}
    end;                               {back and process next span pixel}
  end;
