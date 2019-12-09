{   Subroutine REND_SW_RECT_PX_2DIMI (DX,DY)
*
*   Declare the rectangular region subsequent RUNPX and SPAN primitives will draw
*   into.  One corner of the rectangle will be at the current point.  DX and DY
*   are the signed rectangle width and height in pixels.  The rectangle will
*   extend to the right from the current point for positive values for DX, and
*   down from the current point for positive values of DY.
*
*   The rectangle is filled completely on one scan line before stepping to the
*   next scan line.  The first pixel filled is always the current point.
*   Therefore, the fill directions depend on the sign of DX and DY.
*
*   WARNING:  This is a special primitive that does not stand alone.
*     No other RENDlib calls are allowed between this call, and the last RUNPX or
*     SPAN primitive used to fill the rectangle.  It IS permissible to abort the
*     rectangle early by simply making other calls before is it completely filled.
*     However, if this is done, no RUNPX or SPAN primitives are allowed until
*     another RECT_PX is established.
*
*     The behavior is undefined if more pixels are supplied than the size of
*     the rectangle.
*
*   PRIM_DATA sw_write no
*   PRIM_DATA sw_read no
}
{
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*   ::        CONFIDENTIAL AND PROPRIETARY INFORMATION OF        ::
*   ::                    COGNIVISION, INC.                      ::
*   ::           PROTECTED BY THE COPYRIGHT LAW AS AN            ::
*   ::                    UNPUBLISHED WORK                       ::
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}
module rend_sw_rect_px_2dimi;
define rend_sw_rect_px_2dimi;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_rect_px_2dimi_d.ins.pas';

procedure rend_sw_rect_px_2dimi (      {declare rectangle for RUNs or SPANs}
  in      dx, dy: sys_int_machine_t);  {size from curr pixel to opposite corner}

begin
  if (dx = 0) or (dy = 0) then return; {no pixels to write ?}

  if dx > 0
    then begin                         {rect extends right from current point}
      rend_dir_flag := rend_dir_right_k;
      rend_rectpx.xlen := dx;
      end
    else begin                         {rect extends left from current point}
      rend_dir_flag := rend_dir_left_k;
      rend_rectpx.xlen := -dx;
      end
    ;

  if dy > 0
    then begin                         {rectangle extends down from current point}
      rend_lead_edge.dya := 1;
      rend_lead_edge.length := dy;
      end
    else begin                         {rectangle extends up from current point}
      rend_lead_edge.dya := -1;
      rend_lead_edge.length := -dy;
      end
    ;

  rend_lead_edge.dxa := 0;
  rend_lead_edge.dxb := 0;
  rend_lead_edge.dyb := 0;
  rend_lead_edge.err := -1;            {insure we always take A steps}
  rend_lead_edge.dea := 0;
  rend_lead_edge.deb := 0;

  rend_internal.setup_iterps^;         {set up interpolators for new Bresenham}

  rend_rectpx.left_line := rend_rectpx.xlen;
  rend_rectpx.skip_line := 0;
  rend_rectpx.skip_curr := 0;
  end;
