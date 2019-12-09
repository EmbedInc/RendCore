{   Subroutine REND_SW_RECT_2DIM (DX,DY)
*
*   Draw axis aligned rectangle.  The current point is at one corner, and DX,DY is
*   the displacement to the other corner.  Only those pixel centers that are in the
*   rectangle will be drawn.
}
module rend_sw_rect_2dim;
define rend_sw_rect_2dim;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_rect_2dim_d.ins.pas';

procedure rend_sw_rect_2dim (          {axis aligned rectangle at current point}
  in      dx, dy: real);               {displacement from curr pnt to opposite corner}
  val_param;

var
  ix, iy: integer32;                   {pixel coordinate of rectangle start point}
  idx, idy: integer32;                 {integer pixel rectangle size}

begin
  if rend_poly_parms.subpixel          {use subpixel or integer addressing ?}
{
*   Subpixel addressing is ON.
}
    then begin                         {subpixel addressing is ON}
      if dx >= 0.0                     {which way does rect extend from curr pnt ?}
        then begin                     {rectangle extends to the right}
          ix := round(rend_2d.curr_x2dim); {starting X pixel coordinate}
          idx := round(rend_2d.curr_x2dim+dx)-ix; {number of pixels horizontally}
          end
        else begin                     {rectangle extends to the left}
          ix := round(rend_2d.curr_x2dim)-1; {starting X pixel coordinate}
          idx := round(rend_2d.curr_x2dim+dx)-1-ix; {signed pixels in X direction}
          end
        ;
      if idx = 0 then return;          {nothing to draw ?}
      if dy >= 0.0                     {which way does rect extend from curr pnt ?}
        then begin                     {rectangle extends upwards}
          iy := round(rend_2d.curr_y2dim); {starting Y pixel coordinate}
          idy := round(rend_2d.curr_y2dim+dy)-iy; {number of pixels vertically}
          end
        else begin                     {rectangle extends downwards}
          iy := round(rend_2d.curr_y2dim)-1; {starting Y pixel coordinate}
          idy := round(rend_2d.curr_y2dim+dy)-1-iy; {signed pixels in Y direction}
          end
        ;
      if idy = 0 then return;          {nothing to draw ?}
      if (ix <> rend_lead_edge.x) or (iy <> rend_lead_edge.y) then begin {new curr pnt ?}
        rend_set.cpnt_2dimi^ (ix, iy); {set new pixel coordinate current point}
        end;
      rend_prim.rect_2dimi^ (idx, idy); {draw the rectangle}
      end                              {done with subpixel addressing ON}
{
*   Subpixel addressing in OFF.
}
    else begin                         {subpixel addressing is OFF}
      ix := trunc(rend_2d.curr_x2dim);
      iy := trunc(rend_2d.curr_y2dim);
      if dx >= 0.0
        then begin                     {rectangle extends to the right}
          idx := trunc(rend_2d.curr_x2dim + dx) - ix + 1;
          end
        else begin                     {rectangle extends to the left}
          idx := trunc(rend_2d.curr_x2dim + dx) - ix - 1;
          end
        ;
      if dy >= 0.0
        then begin                     {rectangle extends downwards}
          idy := trunc(rend_2d.curr_y2dim + dy) - iy + 1;
          end
        else begin                     {rectangle extends upwards}
          idy := trunc(rend_2d.curr_y2dim + dy) - iy - 1;
          end
        ;
      if                               {rectangle start no longer on current point ?}
          (ix <> rend_lead_edge.x) or (iy <> rend_lead_edge.y)
          then begin
        rend_set.cpnt_2dimi^ (ix, iy); {set new pixel coordinate current point}
        end;                           {done resetting current point}
      rend_prim.rect_2dimi^ (idx, idy); {draw the rectangle}
      end                              {done with subpixel addressing OFF}
    ;                                  {done testing for subpixel addressing ON/OFF}
  end;
