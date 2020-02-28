{   Subroutine REND_SW_TBPOINT_2D_3D (TP)
*
*   Fill in all the required 3D transformation information in a tube point
*   descriptor, given only the 2D X and Y basis vectors of the end plane.
*   The Z basis vector will be created orthogonal to the X and Y basis vectors,
*   and its magnitude will be adjusted to be "near" that of XB and YB.
*   The full normal vector transform matrix will also be created.
*
*   TP is the tube point descriptor.  The XB and YB fields must already be
*   set.  The ZB, NXB, NYB, and NZB fields will be set by this call.
}
module rend_tbpoint_2d_3d;
define rend_tbpoint_2d_3d;
%include 'rend2.ins.pas';

procedure rend_tbpoint_2d_3d (         {make full 3D xforms from XB,YB in tube point}
  in out  tp: rend_tube_point_t);      {will fill in ZB, NXB, NYB, NZB given XB, YB}

const
  third = 1.0 / 3.0;

var
  mag2: real;                          {square of vector magnitude}
  m: real;                             {mult factor for scaling vector}

begin
  mag2 := 0.5 * (                      {mean square of original vector magnitudes}
    sqr(tp.xb.x) + sqr(tp.xb.y) + sqr(tp.xb.z) +
    sqr(tp.yb.x) + sqr(tp.yb.y) + sqr(tp.yb.z));

  tp.nzb.x := (tp.xb.y * tp.yb.z) - (tp.xb.z * tp.yb.y); {ZB of norm vect transform}
  tp.nzb.y := (tp.xb.z * tp.yb.x) - (tp.xb.x * tp.yb.z);
  tp.nzb.z := (tp.xb.x * tp.yb.y) - (tp.xb.y * tp.yb.x);

  m := sqr(tp.nzb.x) + sqr(tp.nzb.y) + sqr(tp.nzb.z); {square of NZB magnitude}
  if m > 1.0E-30 then begin            {big enough to still have direction ?}
    m := sqrt(mag2/m);                 {make vector mult factor}
    tp.zb.x := tp.nzb.x * m;           {make ZB roughly same size as XB and YB}
    tp.zb.y := tp.nzb.y * m;
    tp.zb.z := tp.nzb.z * m;
    end;

  tp.nxb.x := (tp.yb.y * tp.zb.z) - (tp.yb.z * tp.zb.y); {XB of norm vect transform}
  tp.nxb.y := (tp.yb.z * tp.zb.x) - (tp.yb.x * tp.zb.z);
  tp.nxb.z := (tp.yb.x * tp.zb.y) - (tp.yb.y * tp.zb.x);

  tp.nyb.x := (tp.zb.y * tp.xb.z) - (tp.zb.z * tp.xb.y); {YB of norm vect transform}
  tp.nyb.y := (tp.zb.z * tp.xb.x) - (tp.zb.x * tp.xb.z);
  tp.nyb.z := (tp.zb.x * tp.xb.y) - (tp.zb.y * tp.xb.x);
{
*   Everything is correct.  However, since the overall scaling of the normal vector
*   matrix is irrelevant, we will try to make the vectors roughly of unit length.
*   This prevent drastic changes in scale, which could lead to overflow or
*   underflow, especially if they accumulate.
*
*   The whole normal vector matrix will be scaled so that the RMS of the three
*   vector lengths is 1.
}
  m := third * (                       {mean square of vector lengths}
    sqr(tp.nxb.x) + sqr(tp.nxb.y) + sqr(tp.nxb.z) +
    sqr(tp.nyb.x) + sqr(tp.nyb.y) + sqr(tp.nyb.z) +
    sqr(tp.nzb.x) + sqr(tp.nzb.y) + sqr(tp.nzb.z));
  if m > 1.0E-30 then begin            {vectors big enough to scale ?}
    m := 1.0 / sqrt(m);                {make matrix scale factor}
    tp.nxb.x := tp.nxb.x * m;          {scale whole matrix for roughly unit vectors}
    tp.nxb.y := tp.nxb.y * m;
    tp.nxb.z := tp.nxb.z * m;
    tp.nyb.x := tp.nyb.x * m;
    tp.nyb.y := tp.nyb.y * m;
    tp.nyb.z := tp.nyb.z * m;
    tp.nzb.x := tp.nzb.x * m;
    tp.nzb.y := tp.nzb.y * m;
    tp.nzb.z := tp.nzb.z * m;
    end;
  end;
