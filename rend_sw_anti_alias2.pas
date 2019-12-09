{   Subroutine REND_SW_ANTI_ALIAS2 (SIZE_X,SIZE_Y,SRC_X,SRC_Y)
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
*
*   This is a special case version of the ANTI_ALIAS primitive.  This routine
*   makes the following assumptions:
*
*   1)  Only 8 bit interpolants are on, and all of them are enabled for
*       anti-aliasing.
*
*   2)  Pixel function INSERT.
*
*   3)  Interpolator clamping off, or limits set to 0-255.
*
*   4)  All write mask bits enabled.
*
*   5)  Integer anti-aliasing shrink factors.
*
*   PRIM_DATA sw_write yes
*   PRIM_DATA sw_read no
}
module rend_sw_anti_alias2;
define rend_sw_anti_alias2;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_anti_alias2_d.ins.pas';

procedure rend_sw_anti_alias2 (        {anti alias src to dest bitmap, curr scale}
  in      size_x, size_y: sys_int_machine_t; {destination rectangle size}
  in      src_x, src_y: sys_int_machine_t); {maps to top left of top left out pixel}
  val_param;

var
  ixdc, iydc: sys_int_machine_t;       {destination pixel loop counters}
  ixsc, iysc: sys_int_machine_t;       {source pixel loop counters}
  iys: sys_int_machine_t;              {Y source pixel coordinate}
  kernel_lx, kernel_ty: sys_int_machine_t; {top left kernel pixel source coordinate}
  i: sys_int_machine_t;                {loop counter for ON interpolants}
  lim_xc, lim_yc: sys_int_machine_t;   {limit values for dest coor loop counters}
  acc: rend_iterp_val_t;               {convolution accumulator}
  i_p: sys_int_machine_p_t;            {pointer to current kernel coeficient}
  src_p: ^char;                        {pointer to current source pixel}
  left_ofs: sys_int_adr_t;             {src scan line offset for kernel start}

begin
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
*   interpolant for which anti-aliasing is enabled, calculate the final pixel
*   value, and write it directly to the destination bitmap.  Advance the
*   interpolant destination pixel to the next pixel to the right.
}
      for i := 1 to rend_iterps.n_on do begin {once for each ON interpolant}
        with
          rend_iterps.list_on[i]^: iterp, {ITERP is this interpolant}
          iterp.bitmap_src_p^: bitmap  {BITMAP is source bitmap desc}
          do begin
        iys := kernel_ty;              {init Y source coor to top kernal row}
        acc.all := 0;                  {init convolution accumulator}
        i_p := addr(rend_aa.filt_int_p^[1]); {init pointer to first kernel coeficient}
        left_ofs :=                    {offset for pixel value into source scan line}
          (kernel_lx * bitmap.x_offset) + iterp.src_offset;
        for iysc := 1 to rend_aa.kernel_dy do begin {down the filter kernel rows}
          src_p := univ_ptr(           {adr of first src pixel this kernel row}
            sys_int_adr_t(bitmap.line_p[iys]) + left_ofs);
          for ixsc := 1 to rend_aa.kernel_dx do begin {accross this filter kernel row}
            acc.all := acc.all +       {add in contribution for this src pixel}
              (ord(src_p^) * i_p^);
            src_p := univ_ptr(         {advance to next source pixel}
              sys_int_adr_t(src_p) + bitmap.x_offset);
            i_p := univ_ptr(           {advance to next filter kernel coeficient}
              sys_int_adr_t(i_p) + sizeof(i_p^));
            end;                       {back and do next source pixel accross}
          iys := iys + 1;              {make Y coor for new filter kernel row}
          end;                         {back for next filter kernel row down}
        iterp.curr_adr.p8^ := chr(acc.val8); {stuff result value into dest bitmap}
        iterp.curr_adr.i :=            {point to next pixel to the right}
          iterp.curr_adr.i + iterp.bitmap_p^.x_offset;
        end;                           {done with ITERP and BITMAP abbreviations}
        end;                           {back and process next interpolant}
      end;                             {back and do next dest pixel accross}
{
*   We just finished writing to the bitmap for a destination scan line.
*   Now update the state to get ready for the next scan line.
}
    if not rend_dirty_crect then begin
      rend_internal.update_span^ (     {tell device we touched some pixels}
        rend_lead_edge.x,              {left span pixel coordinate}
        rend_lead_edge.y,
        size_x);                       {number of pixels in span}
      end;
    rend_lead_edge.y := rend_lead_edge.y + 1; {make Y coordinate for new scan line}
    for i := 1 to rend_iterps.n_on do begin {once for each ON interpolant}
      with
        rend_iterps.list_on[i]^: iterp, {ITERP is this interpolant}
        iterp.bitmap_p^: bitmap        {BITMAP is destination bitmap desc}
        do begin
      iterp.curr_adr.i :=              {make adr of first pixel on new scan line}
        sys_int_adr_t(bitmap.line_p[rend_lead_edge.y]) + {scan line start address}
        (bitmap.x_offset * rend_lead_edge.x) + {to pixel in scan line}
        iterp.iterp_offset;            {to our data in pixel}
      end;                             {done with ITERP and BITMAP abbreviations}
      end;                             {back and process next interpolant}
    end;                               {back and process new scan line}
  end;
