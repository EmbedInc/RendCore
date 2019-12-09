{   Subroutine REND_SW_VECT_3DW (X,Y,Z)
*
*   Draw a vector in 3D world coordinate space.  The vector will start at the
*   current point and end at the given coordinate.  The vector end point will be
*   the new current point.
}
module rend_sw_vect_3dw;
define rend_sw_vect_3dw;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_vect_3dw_d.ins.pas';

procedure rend_sw_vect_3dw (           {vector to new current point in 3DW space}
  in      x, y, z: real);              {vector end point and new current point}
  val_param;

var
  w: real;                             {perspective mult factor}
  sx, sy, sz: real;                    {3DW space vector start point}
  ex, ey, ez: real;                    {3DW space vector end point}
  s2: vect_2d_t;                       {2DIM space vector start point}
  e2: vect_2d_t;                       {2DIM space vector end point}
  smask: integer32;                    {clip status mask for vector start point}
  emask: integer32;                    {clip status mask for vector end point}
  dx, dy, dz: real;                    {displacement of this vector}
  f: real;                             {fraction used in clipping}
  dzdx, dzdy: real;                    {Z derivatives}

label
  not_easy, no_clip, flat_z, done_z;

begin
  emask := 0;                          {init clip status of vector end point}
  if z > rend_view.zclip_near          {end point clipped at near Z ?}
    then emask := 1;
  if z < rend_view.zclip_far           {end point cliped at far Z ?}
    then emask := 2;
  if rend_view.cpnt_clipped            {not fast and easy case ?}
      or (emask <> 0)
      or rend_zon
    then goto not_easy;
{
*   This vector is the simple and easy case.  That means that neither end point is
*   clipped due to the Z range limits, and that Z buffering is turned off.
}
  rend_view.cpnt.x := x;               {save 3DW space current point}
  rend_view.cpnt.y := y;
  rend_view.cpnt.z := z;
  rend_view.cpnt_clipped := false;     {new current point is not clipped}
  if rend_view.perspec_on              {check for perspective on/off}
    then begin                         {perspective is turned on}
      w :=                             {make perspective mult factor}
        rend_view.eyedis/(rend_view.eyedis-z);
      rend_prim.vect_2d^ (x*w, y*w);   {draw vector in 2D model space}
      end
    else begin                         {perspective is turned off}
      rend_prim.vect_2d^ (x, y);       {draw vector in 2D model space}
      end
    ;
  return;                              {done with the simple and easy case}
{
*   This vector is not a simple or easy case.  That means that one or both of the
*   end points are clipped, or that Z buffering is turned on.
}
not_easy:
  sx := rend_view.cpnt.x;              {init 3DW space vector start point}
  sy := rend_view.cpnt.y;
  sz := rend_view.cpnt.z;
  ex := x;                             {init 3DW space vector end point}
  ey := y;
  ez := z;
  rend_view.cpnt.x := x;               {update 3DW current point to vector end point}
  rend_view.cpnt.y := y;
  rend_view.cpnt.z := z;
  smask := 0;                          {init clip status of vector start point}
  if rend_view.cpnt_clipped then begin {vector start point clipped ?}
    if sz > rend_view.zclip_near       {start point clipped at near Z ?}
      then smask := 1;
    if sz < rend_view.zclip_far        {start point clipped at far Z ?}
      then smask := 2;
    end;
  rend_view.cpnt_clipped := emask <> 0; {set flag for clip state of new curr point}
  if (smask ! emask) = 0 then goto no_clip; {vector is not clipped at all ?}
  if (smask & emask) <> 0 then return; {vector completely clipped off ?}
  dx := ex - sx;                       {make length of this vector}
  dy := ey - sy;
  dz := ez - sz;

  if emask <> 0 then begin             {end point needs clipping ?}
    if emask = 1
      then begin                       {clip end point to near Z}
        f := (rend_view.zclip_near-sz)/dz;
        ex := sx + f*dx;
        ey := sy + f*dy;
        ez := rend_view.zclip_near;
        end
      else begin                       {clip end point to far Z}
        f := (rend_view.zclip_far-sz)/dz;
        ex := sx + f*dx;
        ey := sy + f*dy;
        ez := rend_view.zclip_far;
        end
      ;
    end;

  if smask <> 0 then begin             {start point needs clipping ?}
    if smask = 1
      then begin                       {clip start point to near Z}
        f := (rend_view.zclip_near-sz)/dz;
        sx := sx + f*dx;
        sy := sy + f*dy;
        sz := rend_view.zclip_near;
        end
      else begin                       {clip end point to far Z}
        f := (rend_view.zclip_far-sz)/dz;
        sx := sx + f*dx;
        sy := sy + f*dy;
        sz := rend_view.zclip_far;
        end
      ;
    end;
{
*   The vector is all clipped.  The vector start point is SX,SY,SZ and the vector
*   end point is EX,EY,EZ.
}
no_clip:                               {jump here if vector not clipped}
  if rend_zon                          {check Z buffering enabled flag}

    then begin                         {vector is to be Z buffered}
      if rend_view.perspec_on          {check perspective on flag}
        then begin                     {perspective transformation is on}
          w :=                         {make perspective mult factor for start point}
            rend_view.eyedis/(rend_view.eyedis-sz);
          s2.x :=                      {transform all the way to 2DIM space}
            w*(sx*rend_2d.sp.xb.x + sy*rend_2d.sp.yb.x) + rend_2d.sp.ofs.x;
          s2.y :=
            w*(sx*rend_2d.sp.xb.y + sy*rend_2d.sp.yb.y) + rend_2d.sp.ofs.y;
          sz := w*sz*rend_view.zmult + rend_view.zadd;
          w :=                         {make perspective mult factor for end point}
            rend_view.eyedis/(rend_view.eyedis-ez);
          e2.x :=                      {transform all the way to 2DIM space}
            w*(ex*rend_2d.sp.xb.x + ey*rend_2d.sp.yb.x) + rend_2d.sp.ofs.x;
          e2.y :=
            w*(ex*rend_2d.sp.xb.y + ey*rend_2d.sp.yb.y) + rend_2d.sp.ofs.y;
          ez := w*ez*rend_view.zmult + rend_view.zadd;
          end
        else begin                     {perspective is turned off}
          s2.x :=                      {make 2DIM start point}
            sx*rend_2d.sp.xb.x + sy*rend_2d.sp.yb.x + rend_2d.sp.ofs.x;
          s2.y :=
            sx*rend_2d.sp.xb.y + sy*rend_2d.sp.yb.y + rend_2d.sp.ofs.y;
          sz := sz*rend_view.zmult + rend_view.zadd;
          e2.x :=                      {make 2DIM end point}
            ex*rend_2d.sp.xb.x + ey*rend_2d.sp.yb.x + rend_2d.sp.ofs.x;
          e2.y :=
            ex*rend_2d.sp.xb.y + ey*rend_2d.sp.yb.y + rend_2d.sp.ofs.y;
          ez := ez*rend_view.zmult + rend_view.zadd;
          end
        ;                              {done transforming to 2DIM space}
      dx := e2.x - s2.x;               {X displacement of vector}
      dy := e2.y - s2.y;               {Y displacement of vector}
      f := sqr(dx) + sqr(dy);          {denominator for Z derivatives}
      if f < 1.0E-10 then goto flat_z; {vector too short to make Z derivative ?}
      f := (ez - sz)/f;                {intermediate factor for Z derivatives}
      dzdx := dx*f;                    {Z derivative in X direction}
      if (dzdx > 2.0) or (dzdx < -2.0) then goto flat_z;
      dzdy := dy*f;                    {Z derivative in Y direction}
      if (dzdy > 2.0) or (dzdy < -2.0) then goto flat_z;
      rend_set.iterp_linear^ (         {linearly interpolate Z along vector}
        rend_iterp_z_k,                {interpolant to set}
        s2,                            {anchor point}
        sz,                            {value at anchor point}
        dzdx, dzdy);                   {derivatives}
      goto done_z;                     {done setting Z interpolant}
flat_z:                                {jump here if derivatives out of range}
      rend_set.iterp_flat^ (           {set to flat average Z}
        rend_iterp_z_k,                {interpolant to set}
        (sz + ez)*0.5);                {set Z value to average}
done_z:                                {Z interpolant is now set}
      rend_set.cpnt_2dim^ (s2.x, s2.y); {set current point to start of vector}
      end                              {done handling Z buffering enabled case}

    else begin                         {Z buffering is turned off}
      if rend_view.perspec_on          {check perspective on flag}
        then begin                     {perspective transformation is on}
          if smask <> 0 then begin     {start point got clipped off ?}
            w :=                       {make perspective mult factor for start point}
              rend_view.eyedis/(rend_view.eyedis-sz);
            s2.x :=                    {transform all the way to 2DIM space}
              w*(sx*rend_2d.sp.xb.x + sy*rend_2d.sp.yb.x) + rend_2d.sp.ofs.x;
            s2.y :=
              w*(sx*rend_2d.sp.xb.y + sy*rend_2d.sp.yb.y) + rend_2d.sp.ofs.y;
            rend_set.cpnt_2dim^ (s2.x, s2.y); {reset curr pnt to clipped vect start}
            end;                       {done handling start point clipped}
          w :=                         {make perspective mult factor for end point}
            rend_view.eyedis/(rend_view.eyedis-ez);
          e2.x :=                      {transform all the way to 2DIM space}
            w*(ex*rend_2d.sp.xb.x + ey*rend_2d.sp.yb.x) + rend_2d.sp.ofs.x;
          e2.y :=
            w*(ex*rend_2d.sp.xb.y + ey*rend_2d.sp.yb.y) + rend_2d.sp.ofs.y;
          end
        else begin                     {perspective is turned off}
          if smask <> 0 then begin     {start point got clipped off ?}
            s2.x :=                    {transform all the way to 2DIM space}
              sx*rend_2d.sp.xb.x + sy*rend_2d.sp.yb.x + rend_2d.sp.ofs.x;
            s2.y :=
              sx*rend_2d.sp.xb.y + sy*rend_2d.sp.yb.y + rend_2d.sp.ofs.y;
            rend_set.cpnt_2dim^ (s2.x, s2.y); {reset curr pnt to clipped vect start}
            end;                       {done handling start point clipped}
          e2.x :=                      {make 2DIM end point}
            ex*rend_2d.sp.xb.x + ey*rend_2d.sp.yb.x + rend_2d.sp.ofs.x;
          e2.y :=
            ex*rend_2d.sp.xb.y + ey*rend_2d.sp.yb.y + rend_2d.sp.ofs.y;
          end
        ;                              {done transforming to 2DIM space}
      end                              {done handling Z buffering turned off case}
    ;

  rend_prim.vect_2dimcl^ (e2.x, e2.y); {draw vector}
  if emask <> 0 then begin             {original end point clipped off ?}
    rend_set.cpnt_3dw^ (               {set current point to unaltered vector end}
      rend_view.cpnt.x, rend_view.cpnt.y, rend_view.cpnt.z);
    end;
  end;
