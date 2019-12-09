{   Subroutine REND_SW_ANTI_ALIAS (SIZE_X,SIZE_Y,SRC_X,SRC_Y)
*
*   Anti-alias by copying one rectangle to another.  SIZE_X, SIZE_Y declare
*   the size of the rectangle to copy into.  The current point is at
*   the top left destination pixel in the destination rectangle.
*   (SRC_X,SRC_Y) is the coordinate of the source pixel that will map to the
*   top left corner of the top left destination pixel.  The current point will
*   be trashed.
*
*   NOTE:  This routine may read source pixels outside the source rectangle.
*     How far outside pixels may be read depends on the anti-alias shrink factor
*     and the filter function radius.  Use call REND_GET.AA_BORDER to find
*     out how many pixels outside the source rectangle are required in the
*     source bitmap.
}
module rend_sw_anti_alias;
define rend_sw_anti_alias;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_anti_alias_d.ins.pas';

procedure rend_sw_anti_alias (         {anti alias src to dest bitmap, curr scale}
  in      size_x, size_y: sys_int_machine_t; {destination rectangle size}
  in      src_x, src_y: sys_int_machine_t); {maps to top left of top left out pixel}
  val_param;

var
  ixdc, iydc: sys_int_machine_t;       {destination pixel loop counters}
  ixsc, iysc: sys_int_machine_t;       {source pixel loop counters}
  iys: sys_int_machine_t;              {Y source pixel coordinate}
  kernel_lx, kernel_ty: sys_int_machine_t; {top left kernel pixel source coordinate}
  i: sys_int_machine_t;                {loop counter for ON interpolants}
  step: rend_iterp_step_k_t;           {Bresenham step type ID}
  lim_xc, lim_yc: sys_int_machine_t;   {limit values for dest coor loop counters}
  acc: rend_iterp_val_t;               {convolution accumulator}
  i_p: sys_int_machine_p_t;            {pointer to current kernel coeficient}
  src_p: ^char;                        {pointer to current source pixel}
  left_ofs: sys_int_adr_t;             {src scan line offset for kernel start}

begin
  rend_lead_edge.dxa := 0;             {set up Bresenham for rectangle left edge}
  rend_lead_edge.dxb := 0;
  rend_lead_edge.dya := 1;
  rend_lead_edge.dyb := 0;
  rend_lead_edge.err := -1;            {insure we always take A steps}
  rend_lead_edge.dea := 0;
  rend_lead_edge.deb := 0;
  rend_lead_edge.length := size_x;     {number of scan lines to draw}
  rend_dir_flag := rend_dir_right_k;   {pixels will be drawn left to right}
  rend_internal.setup_iterps^;         {set up interpolators for new Bresenham}

  lim_xc := size_x - 1;                {set max for dest pixel loop counters}
  lim_yc := size_y - 1;

  for iydc := 0 to lim_yc do begin     {once for each destination scan line}
    for ixdc := 0 to lim_xc do begin   {once for each dest pixel on this scan line}
      kernel_lx :=                     {left kernel column src bitmap X coordinate}
        src_x + (ixdc * rend_aa.shrink_x) - rend_aa.start_xofs;
      kernel_ty :=                     {top kernel row src bitmap Y coordinate}
        src_y + (iydc * rend_aa.shrink_y) - rend_aa.start_yofs;
{
*   All the interpolators are set to the new destination pixel.  KERNEL_LX and
*   KERNEL_TY specify the source bitmap pixel coordinate for the top left subpixel
*   of the convolution kernel for this destination pixel.  Now loop thru each
*   interpolant for which anti-aliasing is enabled and set its VALUE field.
*   This has the effect of replacing the interpolator output value with the
*   result of the anti-aliasing calculation.
}
  for i := 1 to rend_iterps.n_on do begin {once for each ON interpolant}
    with
      rend_iterps.list_on[i]^: iterp,  {ITERP is this interpolant}
      iterp.bitmap_src_p^: bitmap      {BITMAP is source bitmap desc}
      do begin
    if not iterp.aa then next;         {anti-aliasing off for this interpolant ?}
    iys := kernel_ty;                  {init Y source coor to top kernal row}
    acc.all := 0;                      {init convolution accumulator}
    i_p := addr(rend_aa.filt_int_p^[1]); {init pointer to first kernel coeficient}
    left_ofs :=                        {offset for pixel value into source scan line}
      (kernel_lx * bitmap.x_offset) + iterp.src_offset;
    for iysc := 1 to rend_aa.kernel_dy do begin {down the filter kernel rows}
      src_p := univ_ptr(               {adr of first src pixel this kernel row}
        sys_int_adr_t(bitmap.line_p[iys]) + left_ofs);
      for ixsc := 1 to rend_aa.kernel_dx do begin {accross this filter kernel row}
        acc.all := acc.all +           {add in contribution for this src pixel}
          (ord(src_p^) * i_p^);
        src_p := univ_ptr(             {advance to next source pixel}
          sys_int_adr_t(src_p) + bitmap.x_offset);
        i_p := univ_ptr(               {advance to next filter kernel coeficient}
          sys_int_adr_t(i_p) + sizeof(i_p^));
        end;                           {back and do next source pixel accross}
      iys := iys + 1;                  {make Y coor for new filter kernel row}
      end;                             {back for next filter kernel row down}
    iterp.val := acc;                  {stomp on unclipped interpolator value}
    iterp.value := acc;                {init clipped interpolator value}
    if iterp.iclamp then begin         {need to clip interpolator result ?}
      if iterp.value.all > iterp.iclamp_max.all
        then iterp.value := iterp.iclamp_max;
      if iterp.value.all < iterp.iclamp_min.all
        then iterp.value := iterp.iclamp_min;
      end;                             {done handling interpolator clamping}
    end;                               {done with ITERP and BITMAP abbreviations}
    end;                               {back and process next interpolant}
{
*   All the interpolants with anti-aliasing enabled have their VALUE field set
*   to the result of the anti-aliasing calculation for this destination pixel.
}
      rend_prim.wpix^;                 {draw this pixel}
      if ixdc < lim_xc then begin      {not at last pixel on dest scan line ?}
        rend_sw_interpolate (rend_iterp_step_h_k); {step iterps to next pixel accross}
        end;
      end;                             {back and do next dest pixel accross}
    rend_sw_bres_step (rend_lead_edge, step); {walk down left rectangle edge}
    rend_sw_interpolate (step);        {update interpolators for new scan line}
    end;                               {back and process new scan line}
  end;
