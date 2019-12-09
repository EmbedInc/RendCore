{   Subroutine REND_SW_RECT_2DIMI (IDX,IDY)
*
*   Draw a relative rectangle from the current point.  IDX and IDY are the signed
*   width and height.  The signs of IDX and IDY indicate the direction the rectangle
*   is to extend from the current point.  A size of 0,0 draws nothing, and a size
*   of 1,1 (or -1,-1) draws the current point.
}
module rend_sw_rect_2dimi;
define rend_sw_rect_2dimi;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_rect_2dimi_d.ins.pas';

procedure rend_sw_rect_2dimi (         {integer image space axis aligned rectangle}
  in      idx, idy: sys_int_machine_t); {pixel displacement to opposite corner}
  val_param;

var
  ady: sys_int_machine_t;              {absolute value of DY}
  sign_dy: sys_int_machine_t;          {+1 or -1 sign of DY}
  cdx, cdy: sys_int_machine_t;         {clip rectangle size}
  match_clip: boolean;                 {TRUE if rectangle matches clip rectangle}

begin
  if (idx=0) or (idy=0) then return;   {no pixels to write ?}

  cdx := rend_clip_2dim.ixmax - rend_clip_2dim.ixmin + 1;
  cdy := rend_clip_2dim.iymax - rend_clip_2dim.iymin + 1;
  if idx > 0
    then begin
      match_clip :=
        (rend_lead_edge.x = rend_clip_2dim.ixmin) and
        (idx = cdx);
      end
    else begin
      match_clip :=
        (rend_lead_edge.x = rend_clip_2dim.ixmax) and
        (idx = -cdx);
      end
    ;
  if idy > 0
    then begin
      match_clip := match_clip and
        (rend_lead_edge.y = rend_clip_2dim.iymin) and
        (idy = cdy);
      sign_dy := 1;
      ady := idy;
      end
    else begin
      match_clip := match_clip and
        (rend_lead_edge.y = rend_clip_2dim.iymax) and
        (idy = -cdy);
      sign_dy := -1;
      ady := -idy;
      end
    ;
  rend_dirty_crect := rend_dirty_crect or
    (rend_crect_dirty_ok and match_clip);

  rend_lead_edge.dxa := 0;
  rend_lead_edge.dxb := 0;
  rend_lead_edge.dya := sign_dy;
  rend_lead_edge.dyb := 0;
  rend_lead_edge.err := -1;            {insure we always take A steps}
  rend_lead_edge.dea := 0;
  rend_lead_edge.deb := 0;
  rend_lead_edge.length := ady;        {number of scan lines to draw}

  rend_trail_edge.x := rend_lead_edge.x + idx;
  rend_trail_edge.y := rend_lead_edge.y;
  rend_trail_edge.dxa := 0;
  rend_trail_edge.dxb := 0;
  rend_trail_edge.dya := sign_dy;
  rend_trail_edge.dyb := 0;
  rend_trail_edge.err := -1;           {insure we always take A steps}
  rend_trail_edge.dea := 0;
  rend_trail_edge.deb := 0;
  rend_trail_edge.length := ady;       {number of scan lines to draw}

  if idx >= 0
    then rend_dir_flag := rend_dir_right_k
    else rend_dir_flag := rend_dir_left_k;
  rend_internal.setup_iterps^;         {set up interpolators for new Bresenham}
  rend_internal.tzoid^;                {draw the rectangle}
  end;
