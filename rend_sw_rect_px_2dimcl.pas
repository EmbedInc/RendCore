{   Subroutine REND_SW_RECT_PX_2DIMCL (DX,DY)
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
module rend_sw_rect_px_2dimcl;
define rend_sw_rect_px_2dimcl;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_rect_px_2dimcl_d.ins.pas';

procedure rend_sw_rect_px_2dimcl (     {declare rectangle for RUNs or SPANs}
  in      dx, dy: sys_int_machine_t);  {size from curr pixel to opposite corner}
  val_param;

var
  xsz, ysz: sys_int_machine_t;         {size of clipped rectangle}
  startx, starty: sys_int_machine_t;   {rectangle start pixel after clip}
  endx, endy: sys_int_machine_t;       {rectangle end pixel after clip}
  adx: sys_int_machine_t;              {number of pixels accross unclipped rect}

begin
  if (dx = 0) or (dy = 0) then return; {no pixels to write ?}
  if not (rend_clip_2dim.exists and rend_clip_2dim.draw_inside) then begin
    writeln ('Complicated clip environments not supported in RECT_PX_2DIMCL.');
    sys_bomb;
    end;

  if dx > 0
    then begin                         {rect extends right from current point}
      rend_dir_flag := rend_dir_right_k;
      startx := max(rend_lead_edge.x, rend_clip_2dim.ixmin); {clipped start X}
      endx := min(rend_lead_edge.x + dx - 1, rend_clip_2dim.ixmax);
      xsz := max(endx - startx + 1, 0); {clipped rectangle width}
      rend_rectpx.skip_line := dx - xsz; {pixels to skip between scan lines}
      rend_rectpx.skip_curr :=         {pixels to skip before first scan line}
        startx - rend_lead_edge.x;
      adx := dx;                       {number of pixels accross unclipped rect}
      end
    else begin                         {rect extends left from current point}
      rend_dir_flag := rend_dir_left_k;
      startx := min(rend_lead_edge.x, rend_clip_2dim.ixmax); {clipped start X}
      endx := max(rend_lead_edge.x + dx + 1, rend_clip_2dim.ixmin);
      xsz := max(endx - startx + 1, 0); {clipped rectangle width}
      rend_rectpx.skip_line := -dx - xsz; {pixels to skip between scan lines}
      rend_rectpx.skip_curr :=         {pixels to skip before first scan line}
        rend_lead_edge.x -startx;
      adx := -dx;                      {number of pixels accross unclipped rect}
      end
    ;

  if dy > 0
    then begin                         {rectangle extends down from current point}
      starty := max(rend_lead_edge.y, rend_clip_2dim.iymin); {clipped start Y}
      endy := min(rend_lead_edge.y + dy - 1, rend_clip_2dim.iymax);
      ysz := max(endy - starty + 1, 0); {clipped rectangle height}
      rend_lead_edge.dya := 1;
      end
    else begin                         {rectangle extends up from current point}
      starty := min(rend_lead_edge.y, rend_clip_2dim.iymax); {clipped start Y}
      endy := max(rend_lead_edge.y + dy + 1, rend_clip_2dim.iymin);
      ysz := max(endy - starty + 1, 0); {clipped rectangle height}
      rend_lead_edge.dya := -1;
      end
    ;

  if (xsz <= 0) or (ysz <= 0) then begin {rectangle completely clipped away ?}
    rend_rectpx.xlen := 0;             {indicate all clipped to draw routines}
    return;                            {no need to go further}
    end;

  rend_rectpx.skip_curr :=             {pixels for skipping starting scan lines}
    rend_rectpx.skip_curr +
    ((starty - rend_lead_edge.y) * adx);
  rend_rectpx.xlen := xsz;             {line width of rectangle to draw}
  rend_rectpx.left_line := xsz;        {init pixels left to draw on first line}

  if (startx <> rend_lead_edge.x) or (starty <> rend_lead_edge.y) then begin
    rend_set.cpnt_2dimi^ (startx, starty); {reset curr pnt to clipped start}
    end;

  rend_lead_edge.dxa := 0;
  rend_lead_edge.dxb := 0;
  rend_lead_edge.dyb := 0;
  rend_lead_edge.err := -1;            {insure we always take A steps}
  rend_lead_edge.dea := 0;
  rend_lead_edge.deb := 0;
  rend_lead_edge.length := ysz;        {number of scan lines to draw}

  rend_internal.setup_iterps^;         {set up interpolators for new Bresenham}
  end;
