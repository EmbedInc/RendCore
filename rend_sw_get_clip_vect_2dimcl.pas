{   Subroutine REND_SW_GET_CLIP_VECT_2DIMCL (STATE, IN_VECT, OUT_VECT)
*
*   Clip the 2D input vector to produce the 2D output vector.
*   IN_VECT and OUT_VECT each contain the explicit start point and
*   end point. The clipping region may be concave or disjoint, so
*   it is possible that there is more than one output vector. The
*   variable STATE should be set to REND_CLIP_STATE_START for the
*   first call. Subsequent calls will return additional output
*   vectors. When STATE is returned as REND_CLIP_STATE_LAST then
*   an output vector is returned, but there are no more. When
*   STATE is returned as REND_CLIP_STATE_END, then no output vector
*   is returned, and there are none left. STATE is guaranteed to
*   eventually be returned as REND_CLIP_STATE_END, but may not
*   always be set to REND_CLIP_STATE_LAST on the last output
*   vector.
}
module rend_sw_get_clip_vect_2dimcl;
define rend_sw_get_clip_vect_2dimcl;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_clip_vect_2dimcl ( {run vector thru 2DIMCL clipping}
  in out  state: rend_clip_state_k_t;  {for remembering multiple output vectors}
  in      in_vect: rend_2dvect_t;      {original unclipped input vector}
  out     out_vect: rend_2dvect_t);    {this fragment of clipped output vector}

var
  dx, dy: real;                        {displacement of unclipped vector}
  clip1, clip2: sys_int_machine_t;     {clip check mask for first and second points}
  clip: sys_int_machine_t;             {composite of CLIP1 and CLIP2}
  xs, ys: real;                        {start point of clipped vector}
  xe, ye: real;                        {end point of clipped vector}
  frac: real;                          {fraction into vector for intersect point}
  clip_minx: real;                     {coordinates of clip rectangle}
  clip_maxx: real;
  clip_miny: real;
  clip_maxy: real;

label
  reject;

begin
  if (not rend_clip_2dim.exists) or (not rend_clip_2dim.draw_inside) then begin
    rend_message_bomb ('rend', 'rend_clip_complicated_cvect', nil, 0);
    end;

  if state <> rend_clip_state_start_k then begin {no more vectors left ?}
    state := rend_clip_state_end_k;
    return;
    end;

  clip_minx := rend_clip_2dim.xmin + 0.001; {make local copy of clip rectangle}
  clip_maxx := rend_clip_2dim.xmax - 0.001;
  clip_miny := rend_clip_2dim.ymin + 0.001;
  clip_maxy := rend_clip_2dim.ymax - 0.001;

  clip1 := 0;                          {init clip check result masks}
  clip2 := 0;
  if in_vect.p1.y < clip_miny          {set clip mask for start point}
    then clip1 := clip1 + 1;
  if in_vect.p1.y > clip_maxy
    then clip1 := clip1 + 2;
  if in_vect.p1.x < clip_minx
    then clip1 := clip1 + 4;
  if in_vect.p1.x > clip_maxx
    then clip1 := clip1 + 8;

  if in_vect.p2.y < clip_miny          {set clip mask for end point}
    then clip2 := clip2 + 1;
  if in_vect.p2.y > clip_maxy
    then clip2 := clip2 + 2;
  if in_vect.p2.x < clip_minx
    then clip2 := clip2 + 4;
  if in_vect.p2.x > clip_maxx
    then clip2 := clip2 + 8;

  if (clip1 ! clip2) = 0 then begin    {trivial accept case ?}
    out_vect := in_vect;               {copy input vector to output vector}
    state := rend_clip_state_last_k;   {this is the last output vector}
    return;
    end;                               {done with the trivial accept case}

  if (clip1 & clip2) <> 0 then goto reject; {trivial reject case ?}

  clip := clip1 ! clip2;               {make list of which limits to clip against}
  xs := in_vect.p1.x;                  {init clipped vector start point}
  ys := in_vect.p1.y;
  xe := in_vect.p2.x;                  {init clipped vector end point}
  ye := in_vect.p2.y;
  dx := in_vect.p2.x-in_vect.p1.x;     {make displacement of unclipped vector}
  dy := in_vect.p2.y-in_vect.p1.y;

  if (clip & 1) <> 0 then begin        {clip against the top Y limit ?}
    frac := (clip_miny-in_vect.p1.y)/dy; {fraction into vect for clip point}
    if (clip1 & 1) <> 0                {which point is clipped out ?}
      then begin                       {start point is clipped off by this limit}
        xs := in_vect.p1.x + frac*dx;  {make new start point}
        ys := clip_miny;
        end                            {done handling start point is clipped off}
      else begin                       {end point is clipped off by this limit}
        xe := in_vect.p1.x + frac*dx;  {make new end point}
        ye := clip_miny;
        end                            {done handling end point is clipped off}
      ;
    end;

  if (clip & 2) <> 0 then begin        {clip against the bottom Y limit ?}
    frac := (clip_maxy-in_vect.p1.y)/dy; {fraction into vect for clip point}
    if (clip1 & 2) <> 0                {which point is clipped out ?}
      then begin                       {start point is clipped off by this limit}
        xs := in_vect.p1.x + frac*dx;  {make new start point}
        ys := clip_maxy;
        end                            {done handling start point is clipped off}
      else begin                       {end point is clipped off by this limit}
        xe := in_vect.p1.x + frac*dx;  {make new end point}
        ye := clip_maxy;
        end                            {done handling end point is clipped off}
      ;
    end;

  if (clip & 4) <> 0 then begin        {clip against the left X limit ?}
    frac := (clip_minx-in_vect.p1.x)/dx; {fraction into vect for clip point}
    if (clip1 & 4) <> 0                {which point is clipped out ?}
      then begin                       {start point is clipped off by this limit}
        if xe < clip_minx              {vector completely clipped off ?}
          then goto reject;
        if xs < clip_minx then begin   {start point still outside ?}
          xs := clip_minx;             {make new start point}
          ys := in_vect.p1.y + frac*dy;
          end;
        end                            {done handling start point is clipped off}
      else begin                       {end point is clipped off by this limit}
        if xs < clip_minx              {vector completely clipped off ?}
          then goto reject;
        if xe < clip_minx then begin   {end point still outside ?}
          xe := clip_minx;             {make new end point}
          ye := in_vect.p1.y + frac*dy;
          end;
        end                            {done handling end point is clipped off}
      ;
    end;

  if (clip & 8) <> 0 then begin        {clip against the right X limit ?}
    frac := (clip_maxx-in_vect.p1.x)/dx; {fraction into vect for clip point}
    if (clip1 & 8) <> 0                {which point is clipped out ?}
      then begin                       {start point is clipped off by this limit}
        if xe > clip_maxx              {vector completely clipped off ?}
          then goto reject;
        if xs > clip_maxx then begin   {start point still outside ?}
          xs := clip_maxx;             {make new start point}
          ys := in_vect.p1.y + frac*dy;
          end;
        end                            {done handling start point is clipped off}
      else begin                       {end point is clipped off by this limit}
        if xs > clip_maxx              {vector completely clipped off ?}
          then goto reject;
        if xe > clip_maxx then begin   {end point still outside ?}
          xe := clip_maxx;             {make new end point}
          ye := in_vect.p1.y + frac*dy;
          end;
        end                            {done handling end point is clipped off}
      ;
    end;
{
*   The vector has been clipped to the 2D image space clipping window, and there
*   is actually something left to draw.  The vector extends from (xs,ys) to (xe,ye).
}
  out_vect.p1.x := xs;                 {return the clipped vector}
  out_vect.p1.y := ys;
  out_vect.p2.x := xe;
  out_vect.p2.y := ye;
  state := rend_clip_state_last_k;     {this is the last fragment from this vector}
  return;                              {return with a clipped vector}

reject:                                {jump here if nothing left after clipping}
  state := rend_clip_state_end_k;      {indicate there is nothing to return}
  end;
