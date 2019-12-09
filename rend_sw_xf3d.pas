{   Collection of routines that deal with the 3D model space to 3D world space
*   transformation.
}
module rend_sw_xf3d;
define rend_sw_xform_3d;
define rend_sw_get_xform_3d;
define rend_sw_get_xfnorm_3d;
define rend_sw_get_xfpnt_3d;
define rend_sw_xform_3d_postmult;
define rend_sw_xform_3d_premult;
%include 'rend_sw2.ins.pas';
{
**********************************************
*
*   Subroutine REND_SW_XFORM_3D (XB, YB, ZB, OFS)
*
*   Set a new current 3D to 3DW transform.
}
procedure rend_sw_xform_3d (           {set new 3D to 3DW space transform}
  in      xb, yb, zb: vect_3d_t;       {X, Y, and Z basis vectors}
  in      ofs: vect_3d_t);             {offset (translation) vector (in 3DW space)}
  val_param;

var
  vol: real;                           {forward transform matrix volume (determinant)}
  mag2x, mag2y, mag2z: real;           {basis vector square magnitudes}
  m: real;                             {scratch mult factor}
  m2: real;

begin
{
*   Save the new matrix in the common block.  The old matrix is overwritten.
}
  rend_xf3d.xb := xb;
  rend_xf3d.yb := yb;
  rend_xf3d.zb := zb;
  rend_xf3d.ofs := ofs;

  rend_xf3d.vrad_ok := false;          {VRAD fields definately now no good anymore}
  rend_xf3d.rot_scale := false;        {init to not just rotation and uniform scale}
{
*   Find the "average" scale factor of the forward matrix.  This value will
*   apply exactly to the whole matrix when ROT_SCALE is TRUE.
}
  rend_xf3d.scale := sqrt(
    ( sqr(xb.x) + sqr(xb.y) + sqr(xb.z) + {sum of the squares of all three vectors}
      sqr(yb.x) + sqr(yb.y) + sqr(yb.z) +
      sqr(zb.x) + sqr(zb.y) + sqr(zb.z))
    / 3.0);                            {make average squared basis vector length}
{
*   Make the normal vector transformation matrix.  Each vector in this matrix is the
*   result of the cross product between the other two.
}
  rend_xf3d.vxb.x := yb.y*zb.z - yb.z*zb.y;
  rend_xf3d.vxb.y := yb.z*zb.x - yb.x*zb.z;
  rend_xf3d.vxb.z := yb.x*zb.y - yb.y*zb.x;

  rend_xf3d.vyb.x := zb.y*xb.z - zb.z*xb.y;
  rend_xf3d.vyb.y := zb.z*xb.x - zb.x*xb.z;
  rend_xf3d.vyb.z := zb.x*xb.y - zb.y*xb.x;

  rend_xf3d.vzb.x := xb.y*yb.z - xb.z*yb.y;
  rend_xf3d.vzb.y := xb.z*yb.x - xb.x*yb.z;
  rend_xf3d.vzb.z := xb.x*yb.y - xb.y*yb.x;
{
*   Make the reverse transformation matrix.  This is the same as the transpose
*   of the normal vector matrix, but is stored separately because the two need
*   to be at different scale factors to try to keep numbers at reasonable
*   magnitudes.
}
  vol :=                               {volume (determinant) of original matrix}
    rend_xf3d.zb.x * rend_xf3d.vzb.x +
    rend_xf3d.zb.y * rend_xf3d.vzb.y +
    rend_xf3d.zb.z * rend_xf3d.vzb.z;

  if abs(vol) < 1.0E-35 then begin     {forward matrix collapsed, no inverse here ?}
    rend_xf3d.rmat_ok := false;        {reverse matrix doesn't exist}
    rend_xf3d.right := true;           {this is really arbitrary}
    return;
    end;

  rend_xf3d.rmat_ok := true;
  rend_xf3d.right := vol > 0.0;        {TRUE if right handed}
  vol := 1.0 / vol;                    {make scale factor for proper inverse matrix}
  rend_xf3d.rxb.x := rend_xf3d.vxb.x * vol; {apply scale factor and transpose}
  rend_xf3d.rxb.y := rend_xf3d.vyb.x * vol;
  rend_xf3d.rxb.z := rend_xf3d.vzb.x * vol;
  rend_xf3d.ryb.x := rend_xf3d.vxb.y * vol;
  rend_xf3d.ryb.y := rend_xf3d.vyb.y * vol;
  rend_xf3d.ryb.z := rend_xf3d.vzb.y * vol;
  rend_xf3d.rzb.x := rend_xf3d.vxb.z * vol;
  rend_xf3d.rzb.y := rend_xf3d.vyb.z * vol;
  rend_xf3d.rzb.z := rend_xf3d.vzb.z * vol;
{
*   Scale the normal vector matrix to roughly preserve vector magnitude.
*   Set ROT_SCALE to TRUE if matrix is only rotation with uniform scaling.
*   In that case, the normal vector matrix will exactly preserve vector
*   magnitude.  Unit shading normals in the 3D space can therefore be
*   transformed into the 3DW space without needing to be re-unitized.
}
  mag2x :=                             {make square magnitudes of basis vectors}
    sqr(rend_xf3d.vxb.x) + sqr(rend_xf3d.vxb.y) + sqr(rend_xf3d.vxb.z);
  mag2y :=
    sqr(rend_xf3d.vyb.x) + sqr(rend_xf3d.vyb.y) + sqr(rend_xf3d.vyb.z);
  mag2z :=
    sqr(rend_xf3d.vzb.x) + sqr(rend_xf3d.vzb.y) + sqr(rend_xf3d.vzb.z);
  m2 := 3.0 / (mag2x + mag2y + mag2z); {sqr of mult factor for adjusting matrix size}
  m := sqrt(m2);                       {mult factor for adjusting matrix size}

  rend_xf3d.vxb.x := rend_xf3d.vxb.x * m; {adjust normal vector matrix size}
  rend_xf3d.vxb.y := rend_xf3d.vxb.y * m;
  rend_xf3d.vxb.z := rend_xf3d.vxb.z * m;
  rend_xf3d.vyb.x := rend_xf3d.vyb.x * m;
  rend_xf3d.vyb.y := rend_xf3d.vyb.y * m;
  rend_xf3d.vyb.z := rend_xf3d.vyb.z * m;
  rend_xf3d.vzb.x := rend_xf3d.vzb.x * m;
  rend_xf3d.vzb.y := rend_xf3d.vzb.y * m;
  rend_xf3d.vzb.z := rend_xf3d.vzb.z * m;
{
*   Check matrix for possibly having non-uniform scaling or non-orthogonal
*   vectors.  If all checks pass, then set ROT_SCALE to TRUE.
}
  if abs(mag2x * m2 - 1.0) > 1.0E-5 then return; {resulting VXB not unit length ?}
  if abs(mag2y * m2 - 1.0) > 1.0E-5 then return; {resulting VYB not unit length ?}

  if abs(                              {VXB and VYB not orthogonal ?}
      rend_xf3d.vxb.x * rend_xf3d.vyb.x +
      rend_xf3d.vxb.y * rend_xf3d.vyb.y +
      rend_xf3d.vxb.z * rend_xf3d.vyb.z)
      > 1.0E-5
    then return;
  if abs(                              {VXB and VZB not orthogonal ?}
      rend_xf3d.vxb.x * rend_xf3d.vzb.x +
      rend_xf3d.vxb.y * rend_xf3d.vzb.y +
      rend_xf3d.vxb.z * rend_xf3d.vzb.z)
      > 1.0E-5
    then return;
  if abs(                              {VYB and VZB not orthogonal ?}
      rend_xf3d.vyb.x * rend_xf3d.vzb.x +
      rend_xf3d.vyb.y * rend_xf3d.vzb.y +
      rend_xf3d.vyb.z * rend_xf3d.vzb.z)
      > 1.0E-5
    then return;

  rend_xf3d.rot_scale := true;         {xform is rotation and uniform scale only}
  end;
{
**********************************************
*
*   Subroutine REND_SW_GET_XFORM_3D (XB, YB, ZB, OFS)
*
*   Return the current 3D transformation matrix.
}
procedure rend_sw_get_xform_3d (       {return the current 3D to 3DW transform}
  out     xb, yb, zb: vect_3d_t;       {X, Y, and Z basis vectors}
  out     ofs: vect_3d_t);             {offset (translation) vector (in 3DW space)}

begin
  xb := rend_xf3d.xb;
  yb := rend_xf3d.yb;
  zb := rend_xf3d.zb;
  ofs := rend_xf3d.ofs;
  end;
{
**********************************************
*
*   Subroutine REND_SW_GET_XFPNT_3D (IPNT, OPNT)
*
*   Transform the 3D coordinate in IPNT from 3D model to 3D world space, and put
*   the result into OPNT.  IPNT and OPNT may be the same variable.
}
procedure rend_sw_get_xfpnt_3d (       {transform point from 3D to 3DW space}
  in      ipnt: vect_3d_t;             {input point in 3D space}
  out     opnt: vect_3d_t);            {3DW space point, may be same as IPNT arg}
  val_param;

var
  x, y: real;

begin
  x :=
    ipnt.x * rend_xf3d.xb.x +
    ipnt.y * rend_xf3d.yb.x +
    ipnt.z * rend_xf3d.zb.x +
    rend_xf3d.ofs.x;
  y :=
    ipnt.x * rend_xf3d.xb.y +
    ipnt.y * rend_xf3d.yb.y +
    ipnt.z * rend_xf3d.zb.y +
    rend_xf3d.ofs.y;
  opnt.z :=
    ipnt.x * rend_xf3d.xb.z +
    ipnt.y * rend_xf3d.yb.z +
    ipnt.z * rend_xf3d.zb.z +
    rend_xf3d.ofs.z;
  opnt.x := x;
  opnt.y := y;
  end;
{
**********************************************
*
*   Subroutine REND_SW_GET_XFNORM_3D (INORM, ONORM)
*
*   Transform the normal vector INORM from 3D model to 3D world space, unitize it,
*   and put it into ONORM.  INORM and ONORM may be the same variable.
}
procedure rend_sw_get_xfnorm_3d (      {transform normal vector from 3D to 3DW space}
  in      inorm: vect_3d_t;            {vector in 3D space, need not be unit length}
  out     onorm: vect_3d_t);           {unit vect in 3DW space, may be same as INORM}
  val_param;

var
  x, y, z: real;                       {intermediated transformed, ununitized vector}
  m: real;                             {mult factor for unitizing}

begin
  x :=
    inorm.x * rend_xf3d.vxb.x +
    inorm.y * rend_xf3d.vyb.x +
    inorm.z * rend_xf3d.vzb.x;
  y :=
    inorm.x * rend_xf3d.vxb.y +
    inorm.y * rend_xf3d.vyb.y +
    inorm.z * rend_xf3d.vzb.y;
  z :=
    inorm.x * rend_xf3d.vxb.z +
    inorm.y * rend_xf3d.vyb.z +
    inorm.z * rend_xf3d.vzb.z;
  m := 1.0 / sqrt(sqr(x) + sqr(y) + sqr(z)); {mult factor to make unit vector}
  onorm.x := x * m;                    {pass back unit vector}
  onorm.y := y * m;
  onorm.z := z * m;
  end;
{
**********************************************
*
*   REND_SW_XFORM_3D_POSTMULT (M)
*
*   Post-multiply matrix M to the current 3D transform.  The result becomes
*   the new current 3D transform.
}
procedure rend_sw_xform_3d_postmult (  {postmult new matrix to old and make current}
  in      m: vect_mat3x4_t);           {new matrix to postmultiply to existing}
  val_param;

var
  m2: vect_mat3x4_t;

begin
  m2.m33.xb.x :=                       {make combined matrix in M2}
    rend_xf3d.xb.x * m.m33.xb.x +
    rend_xf3d.xb.y * m.m33.yb.x +
    rend_xf3d.xb.z * m.m33.zb.x;
  m2.m33.xb.y :=
    rend_xf3d.xb.x * m.m33.xb.y +
    rend_xf3d.xb.y * m.m33.yb.y +
    rend_xf3d.xb.z * m.m33.zb.y;
  m2.m33.xb.z :=
    rend_xf3d.xb.x * m.m33.xb.z +
    rend_xf3d.xb.y * m.m33.yb.z +
    rend_xf3d.xb.z * m.m33.zb.z;

  m2.m33.yb.x :=
    rend_xf3d.yb.x * m.m33.xb.x +
    rend_xf3d.yb.y * m.m33.yb.x +
    rend_xf3d.yb.z * m.m33.zb.x;
  m2.m33.yb.y :=
    rend_xf3d.yb.x * m.m33.xb.y +
    rend_xf3d.yb.y * m.m33.yb.y +
    rend_xf3d.yb.z * m.m33.zb.y;
  m2.m33.yb.z :=
    rend_xf3d.yb.x * m.m33.xb.z +
    rend_xf3d.yb.y * m.m33.yb.z +
    rend_xf3d.yb.z * m.m33.zb.z;

  m2.m33.zb.x :=
    rend_xf3d.zb.x * m.m33.xb.x +
    rend_xf3d.zb.y * m.m33.yb.x +
    rend_xf3d.zb.z * m.m33.zb.x;
  m2.m33.zb.y :=
    rend_xf3d.zb.x * m.m33.xb.y +
    rend_xf3d.zb.y * m.m33.yb.y +
    rend_xf3d.zb.z * m.m33.zb.y;
  m2.m33.zb.z :=
    rend_xf3d.zb.x * m.m33.xb.z +
    rend_xf3d.zb.y * m.m33.yb.z +
    rend_xf3d.zb.z * m.m33.zb.z;

  m2.ofs.x :=
    rend_xf3d.ofs.x * m.m33.xb.x +
    rend_xf3d.ofs.y * m.m33.yb.x +
    rend_xf3d.ofs.z * m.m33.zb.x +
    m.ofs.x;
  m2.ofs.y :=
    rend_xf3d.ofs.x * m.m33.xb.y +
    rend_xf3d.ofs.y * m.m33.yb.y +
    rend_xf3d.ofs.z * m.m33.zb.y +
    m.ofs.y;
  m2.ofs.z :=
    rend_xf3d.ofs.x * m.m33.xb.z +
    rend_xf3d.ofs.y * m.m33.yb.z +
    rend_xf3d.ofs.z * m.m33.zb.z +
    m.ofs.z;

  rend_set.xform_3d^ (                 {make new matrix current}
    m2.m33.xb, m2.m33.yb, m2.m33.zb, m2.ofs);
  end;
{
**********************************************
*
*   REND_SW_XFORM_3D_PREMULT (M)
*
*   Pre-multiply matrix M to the current 3D transform.  The result becomes
*   the new current 3D transform.
}
procedure rend_sw_xform_3d_premult (   {premult new matrix to old and make current}
  in      m: vect_mat3x4_t);           {new matrix to premultiply to existing}
  val_param;

var
  m2: vect_mat3x4_t;

begin
  m2.m33.xb.x :=                       {make combined matrix in M2}
    m.m33.xb.x * rend_xf3d.xb.x +
    m.m33.xb.y * rend_xf3d.yb.x +
    m.m33.xb.z * rend_xf3d.zb.x;
  m2.m33.xb.y :=
    m.m33.xb.x * rend_xf3d.xb.y +
    m.m33.xb.y * rend_xf3d.yb.y +
    m.m33.xb.z * rend_xf3d.zb.y;
  m2.m33.xb.z :=
    m.m33.xb.x * rend_xf3d.xb.z +
    m.m33.xb.y * rend_xf3d.yb.z +
    m.m33.xb.z * rend_xf3d.zb.z;

  m2.m33.yb.x :=
    m.m33.yb.x * rend_xf3d.xb.x +
    m.m33.yb.y * rend_xf3d.yb.x +
    m.m33.yb.z * rend_xf3d.zb.x;
  m2.m33.yb.y :=
    m.m33.yb.x * rend_xf3d.xb.y +
    m.m33.yb.y * rend_xf3d.yb.y +
    m.m33.yb.z * rend_xf3d.zb.y;
  m2.m33.yb.z :=
    m.m33.yb.x * rend_xf3d.xb.z +
    m.m33.yb.y * rend_xf3d.yb.z +
    m.m33.yb.z * rend_xf3d.zb.z;

  m2.m33.zb.x :=
    m.m33.zb.x * rend_xf3d.xb.x +
    m.m33.zb.y * rend_xf3d.yb.x +
    m.m33.zb.z * rend_xf3d.zb.x;
  m2.m33.zb.y :=
    m.m33.zb.x * rend_xf3d.xb.y +
    m.m33.zb.y * rend_xf3d.yb.y +
    m.m33.zb.z * rend_xf3d.zb.y;
  m2.m33.zb.z :=
    m.m33.zb.x * rend_xf3d.xb.z +
    m.m33.zb.y * rend_xf3d.yb.z +
    m.m33.zb.z * rend_xf3d.zb.z;

  m2.ofs.x :=
    m.ofs.x * rend_xf3d.xb.x +
    m.ofs.y * rend_xf3d.yb.x +
    m.ofs.z * rend_xf3d.zb.x +
    rend_xf3d.ofs.x;
  m2.ofs.y :=
    m.ofs.x * rend_xf3d.xb.y +
    m.ofs.y * rend_xf3d.yb.y +
    m.ofs.z * rend_xf3d.zb.y +
    rend_xf3d.ofs.y;
  m2.ofs.z :=
    m.ofs.x * rend_xf3d.xb.z +
    m.ofs.y * rend_xf3d.yb.z +
    m.ofs.z * rend_xf3d.zb.z +
    rend_xf3d.ofs.z;

  rend_set.xform_3d^ (                 {make new matrix current}
    m2.m33.xb, m2.m33.yb, m2.m33.zb, m2.ofs);
  end;
