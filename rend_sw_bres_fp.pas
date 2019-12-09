{   Subroutine REND_SW_BRES_FP (BRES, X1, Y1, X2, Y2, XMAJOR)
*
*   Set up the Bresnham stepper BRES for a line from X1,Y1 to X2,Y2.  If XMAJOR
*   is true, then X is to be the major axis, otherwise Y is the major axis.
}
module rend_sw_bres_fp;
define rend_sw_bres_fp;
%include 'rend_sw2.ins.pas';

procedure rend_sw_bres_fp (            {set up Bresenham with floating point numbers}
  out     bres: rend_bresenham_t;      {the Bresenham stepper data structure}
  in      x1, y1: real;                {starting point of line}
  in      x2, y2: real;                {ending point of line}
  in      xmajor: boolean);            {TRUE for X is major axis, FALSE for Y major}

const
  max_scale = 268419072.0;             {max scale factor for ERR, DEA, and DEB}
  machine_epsilon = 2.3E-7;

var
  imaj1, imaj2: integer32;             {major axis integer end points}
  admaj: real;                         {positive major axis length}
  dmin: real;                          {minor axis displacment}
  frac_slope: real;                    {fraction of abs(D minor / D major)}
  frac_min0: real;                     {fraction of min start point into pixel}
  min0: real;                          {minor axis coordinate at first pixel}
  scale: real;                         {scale factor for ERR, DEA, and DEB}
  slope: real;                         {Dminor/Dmajor, with sign of Dminor}

label
  nothing;

begin
  if xmajor                            {check which is the major axis}

    then begin                         {X is the major axis}
      imaj1 := round(x1);
      imaj2 := round(x2);
      if imaj1 = imaj2 then goto nothing; {nothing to write for this vector ?}
      dmin := y2 - y1;                 {minor axis displacement}
      if imaj1 < imaj2                 {which direction are we going ?}
        then begin                     {from low to high major axis}
          bres.x := imaj1;             {first major axis pixel to be drawn}
          bres.dxa := 1;               {stepping in positive direction}
          bres.dxb := 1;
          bres.length := imaj2 - imaj1; {number of pixels to write in this vector}
          admaj := x2-x1;              {make positive major axis length}
          slope := dmin/admaj;
          min0 := y1 + (bres.x+0.5-x1)*slope; {minor axis at first pixel}
          if min0 < 0.0                {set minor axis starting pixel coordinate}
            then bres.y := trunc(min0) - 1
            else bres.y := trunc(min0);
          end
        else begin                     {from high to low major axis}
          bres.x := imaj1-1;
          bres.dxa := -1;
          bres.dxb := -1;
          bres.length := imaj1 - imaj2;
          admaj := x1-x2;
          slope := dmin/admaj;
          min0 := y1 + (x1-bres.x-0.5)*slope; {minor axis at first pixel}
          if min0 < 0.0                {set minor axis starting pixel coordinate}
            then bres.y := trunc(min0) - 1
            else bres.y := trunc(min0);
          end
        ;                              {done handling ascending/descending X major}
      if dmin >= 0
        then begin                     {minor axis is heading in positive direction}
          bres.dya := trunc(slope-machine_epsilon); {minor axis delta for an A step}
          bres.dyb := bres.dya+1;      {minor axis delta for a B step}
          frac_slope := slope - bres.dya; {just the fraction part of the slope}
          frac_min0 := min0 - bres.y;  {fraction into pixel for min axis start}
          end
        else begin                     {minor axis is heading in negative direction}
          bres.dya := -trunc(-slope-machine_epsilon); {minor axis delta for an A step}
          bres.dyb := bres.dya-1;      {minor axis delta for a B step}
          frac_slope := bres.dya - slope; {the positive fraction part of the slope}
          frac_min0 := 1 - min0 + bres.y; {fraction into pixel for min axis start}
          end
        ;
      end                              {done with X is the major axis}

    else begin                         {Y is the major axis}
      imaj1 := round(y1);
      imaj2 := round(y2);
      if imaj1 = imaj2 then goto nothing;
      dmin := x2 - x1;
      if imaj1 < imaj2
        then begin
          bres.y := imaj1;
          bres.dya := 1;
          bres.dyb := 1;
          bres.length := imaj2 - imaj1;
          admaj := y2-y1;
          slope := dmin/admaj;
          min0 := x1 + (bres.y+0.5-y1)*slope;
          if min0 < 0.0                {set minor axis starting pixel coordinate}
            then bres.x := trunc(min0) - 1
            else bres.x := trunc(min0);
          end
        else begin
          bres.y := imaj1-1;
          bres.dya := -1;
          bres.dyb := -1;
          bres.length := imaj1 - imaj2;
          admaj := y1-y2;
          slope := dmin/admaj;
          min0 := x1 + (y1-bres.y-0.5)*slope;
          if min0 < 0.0                {set minor axis starting pixel coordinate}
            then bres.x := trunc(min0) - 1
            else bres.x := trunc(min0);
          end
        ;
      if dmin >= 0
        then begin
          bres.dxa := trunc(slope-machine_epsilon);
          bres.dxb := bres.dxa+1;
          frac_slope := slope - bres.dxa;
          frac_min0 := min0 - bres.x;
          end
        else begin
          bres.dxa := -trunc(-slope-machine_epsilon);
          bres.dxb := bres.dxa-1;
          frac_slope := bres.dxa - slope;
          frac_min0 := 1 - min0 + bres.x;
          end
        ;
      end                              {done with X is the major axis}
    ;

  if frac_slope > 0.5
    then begin                         {DEA has the biggest magnitude}
      scale := max_scale / frac_slope;
      bres.dea := round(max_scale);
      bres.deb := round((frac_slope-1.0)*scale);
      end
    else begin                         {DEB has the biggest magnitude}
      scale := max_scale / (1.0-frac_slope);
      bres.dea := round(frac_slope*scale);
      bres.deb := round(-max_scale);
      end
    ;
  bres.err := round((frac_min0+frac_slope-1.0)*scale);
  return;                              {new Bresenham values all set}

nothing:                               {jump here if maj axis too short for any pixels}
  bres.length := 0;
  end;
