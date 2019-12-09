{   Collection of non-primitive routines that deal with the 3DPL coordinate
*   space.  This is the 2D space defined by a current plane in the 3D model
*   space.
}
module rend_sw_3dpl;
define rend_sw_cpnt_3dpl;
define rend_sw_rcpnt_3dpl;
define rend_sw_xform_3dpl_2d;
define rend_sw_xform_3dpl_plane;
define rend_sw_get_bxfpnt_3dpl;
define rend_sw_get_cpnt_3dpl;
define rend_sw_get_xform_3dpl_2d;
define rend_sw_get_xform_3dpl_plane;
define rend_sw_get_xfpnt_3dpl;
%include 'rend_sw2.ins.pas';
{
**************************************
*
*   Local subroutine UPDATE_TRANSFORM
*
*   At least one component of the overall transform from the 3DPL to the 3D
*   space has changed.  Recompute the combined transform that is actually used
*   at run time.
*
*   The mapping from the 3DPL to the 3D space is actually defined by two
*   separate user-accessible parts.  A current plane is defined in the 3D
*   space, and an additional 2D transform is defined in that plane.  Although
*   this is conceptually what happens, both these transforms are merged for
*   use at run time.  This routine does the merging.  The merged transform
*   is a current plane.
}
procedure update_transform;
  options (internal);

var
  fwd, bak: vect_mat3x3_t;             {forwards and backwards 3x3 transforms}
  vol: real;                           {volume of FWD transform (not used)}

begin
  rend_3dpl.org.x :=                   {combined plane origin point}
    (rend_3dpl.sp.ofs.x * rend_3dpl.u_xb.x) +
    (rend_3dpl.sp.ofs.y * rend_3dpl.u_yb.x) +
    rend_3dpl.u_org.x;
  rend_3dpl.org.y :=
    (rend_3dpl.sp.ofs.x * rend_3dpl.u_xb.y) +
    (rend_3dpl.sp.ofs.y * rend_3dpl.u_yb.y) +
    rend_3dpl.u_org.y;
  rend_3dpl.org.z :=
    (rend_3dpl.sp.ofs.x * rend_3dpl.u_xb.z) +
    (rend_3dpl.sp.ofs.y * rend_3dpl.u_yb.z) +
    rend_3dpl.u_org.z;

  rend_3dpl.xb.x :=                    {combined plane X basis vector}
    (rend_3dpl.sp.xb.x * rend_3dpl.u_xb.x) +
    (rend_3dpl.sp.xb.y * rend_3dpl.u_yb.x);
  rend_3dpl.xb.y :=
    (rend_3dpl.sp.xb.x * rend_3dpl.u_xb.y) +
    (rend_3dpl.sp.xb.y * rend_3dpl.u_yb.y);
  rend_3dpl.xb.z :=
    (rend_3dpl.sp.xb.x * rend_3dpl.u_xb.z) +
    (rend_3dpl.sp.xb.y * rend_3dpl.u_yb.z);

  rend_3dpl.yb.x :=                    {combined plane Y basis vector}
    (rend_3dpl.sp.yb.x * rend_3dpl.u_xb.x) +
    (rend_3dpl.sp.yb.y * rend_3dpl.u_yb.x);
  rend_3dpl.yb.y :=
    (rend_3dpl.sp.yb.x * rend_3dpl.u_xb.y) +
    (rend_3dpl.sp.yb.y * rend_3dpl.u_yb.y);
  rend_3dpl.yb.z :=
    (rend_3dpl.sp.yb.x * rend_3dpl.u_xb.z) +
    (rend_3dpl.sp.yb.y * rend_3dpl.u_yb.z);

  fwd.xb := rend_3dpl.xb;              {make complete 3DPL to 3D 3x3 transform}
  fwd.yb := rend_3dpl.yb;
  fwd.zb := rend_3dpl.front;

  vect_3x3_invert (                    {make 3D to 3DPL 3x3 transform}
    fwd,                               {input matrix to invert}
    vol,                               {volume of input matrix}
    rend_3dpl.inverse,                 {TRUE if 3D to 3DPL transform exists}
    bak);                              {returned inverted matrix}

  rend_3dpl.xb_inv.x := bak.xb.x;      {save necessary part of inverse transform}
  rend_3dpl.xb_inv.y := bak.xb.y;
  rend_3dpl.yb_inv.x := bak.yb.x;
  rend_3dpl.yb_inv.y := bak.yb.y;
  rend_3dpl.zb_inv.x := bak.zb.x;
  rend_3dpl.zb_inv.y := bak.zb.y;
  end;
{
**************************************
*
*   Subroutine REND_SW_CPNT_3DPL (X, Y)
*
*   Set 3DPL space current point to X,Y.
}
procedure rend_sw_cpnt_3dpl (          {set current point with absolute coordinates}
  in      x, y: real);                 {new coordinates of curr pnt in this space}
  val_param;

var
  x3d, y3d, z3d: real;                 {current point in 3D coordinate space}

begin
  rend_3dpl.sp.cpnt.x := x;            {set 3DPL current point}
  rend_3dpl.sp.cpnt.y := y;

  x3d :=                               {do current plane transform}
    (x * rend_3dpl.xb.x) + (y * rend_3dpl.yb.x) + rend_3dpl.org.x;
  y3d :=
    (x * rend_3dpl.xb.y) + (y * rend_3dpl.yb.y) + rend_3dpl.org.y;
  z3d :=
    (x * rend_3dpl.xb.z) + (y * rend_3dpl.yb.z) + rend_3dpl.org.z;

  rend_set.cpnt_3d^ (x3d, y3d, z3d);   {set 3D space current point}
  end;
{
**************************************
*
*   Subroutine REND_SW_RCPNT_3DPL (DX, DY)
*
*   Set the 3DPL space current point relative to its current position.
*   This effects the 2D transform in the current plane, and not the current
*   plane definition.
}
procedure rend_sw_rcpnt_3dpl (         {set current point with relative coordinates}
  in      dx, dy: real);               {displacement from old current point}
  val_param;

var
  x, y: real;                          {absolute 3DPL current point coordinates}

begin
  x := rend_3dpl.sp.cpnt.x + dx;       {make absolute current point}
  y := rend_3dpl.sp.cpnt.y + dy;
  rend_set.cpnt_3dpl^ (x, y);          {set new 3DPL space current point}
  end;
{
**************************************
*
*   Subroutine REND_SW_XFORM_3DPL_2D (XB, YB, OFS)
*
*   Set new current 2D transform for the 3DPL coordinate space.  This 2D transform
*   maps from the 3DPL coordinate space to the current plane defined in the 3D
*   model space.  In practise, this is all treated as one combined transform,
*   which must also be updated here.
}
procedure rend_sw_xform_3dpl_2d (      {set new 2D transform in 3DPL space}
  in      xb: vect_2d_t;               {X basis vector}
  in      yb: vect_2d_t;               {Y basis vector}
  in      ofs: vect_2d_t);             {offset vector}

var
  m: real;                             {scratch number}

begin
  rend_3dpl.sp.xb := xb;               {save user's 2D transform}
  rend_3dpl.sp.yb := yb;
  rend_3dpl.sp.ofs := ofs;

  m :=                                 {Z of XB cross YB}
    (rend_3dpl.sp.xb.x * rend_3dpl.sp.yb.y) -
    (rend_3dpl.sp.xb.y * rend_3dpl.sp.yb.x);

  rend_3dpl.sp.right := m >= 0.0;      {TRUE if this 2D transform is right handed}
  if abs(m) > 1.0E-20
    then begin                         {the matrix is invertable}
      rend_3dpl.sp.invm := 1.0 / m;    {mult factor when using matrix as inverse}
      rend_3dpl.sp.inv_ok := true;     {inverse of this matrix is possible}
      end
    else begin                         {the matrix is not invertable}
      rend_3dpl.sp.inv_ok := false;    {set flag to indicate matrix has no inverse}
      end
    ;

  update_transform;                    {update merged transform used at run time}
  end;
{
**************************************
*
*   Subroutine REND_SW_XFORM_3DPL_PLANE (ORG, XB, YB)
*
*   Set the new current plane in the 3D world space.  ORG will be the origin point
*   of the plane.  XB is the unit X vector in the plane, and YB is the unit Y
*   vector in the plane.
}
procedure rend_sw_xform_3dpl_plane (   {set new current plane for 3DPL space}
  in      org: vect_3d_t;              {origin for 2D space}
  in      xb: vect_3d_t;               {X basis vector}
  in      yb: vect_3d_t);              {Y basis vector}

var
  m: real;                             {mult factor for unitizing vector}

begin
  rend_3dpl.u_org := org;              {save user parameters}
  rend_3dpl.u_xb := xb;
  rend_3dpl.u_yb := yb;

  rend_3dpl.front.x := (xb.y * yb.z) - (xb.z * yb.y); {raw plane normal vector}
  rend_3dpl.front.y := (xb.z * yb.x) - (xb.x * yb.z);
  rend_3dpl.front.z := (xb.x * yb.y) - (xb.y * yb.x);

  m := sqrt(
    sqr(rend_3dpl.front.x) + sqr(rend_3dpl.front.y) + sqr(rend_3dpl.front.z));
  if m < 1.0E-20
    then begin                         {plane collapsed, no normal exists}
      rend_3dpl.front.x := 0.0;        {arbitrary normal, won't matter anyway}
      rend_3dpl.front.y := 0.0;
      rend_3dpl.front.z := 1.0;
      end
    else begin                         {clear normal vector exists}
      m := 1.0 / m;                    {make mult factor for unitizing normal}
      rend_3dpl.front.x := rend_3dpl.front.x * m;
      rend_3dpl.front.y := rend_3dpl.front.y * m;
      rend_3dpl.front.z := rend_3dpl.front.z * m;
      end
    ;                                  {FRONT vector all set}

  update_transform;                    {update merged transform used at run time}
  end;
{
**************************************
*
*   Subroutine REND_SW_GET_BXFPNT_3DPL (IPNT, OPNT)
*
*   Transform a point from the 3D space to the 3DPL space.  0,0 will be
*   returned if no inverse to the 3DPL-->3D transform exists.
*
*   If the input point is not already on the current plane, then it will be
*   projected to the point on the current plane such that its image position
*   is maintained.  This means the point on the plane is used where the
*   plane intersects the eye vector to the original input point.
}
procedure rend_sw_get_bxfpnt_3dpl (    {transform point from 3D to 3DPL space}
  in      ipnt: vect_3d_t;             {input point in 3D space}
  out     opnt: vect_2d_t);            {output point in 3DPL space}
  val_param;

var
  eye: vect_3d_t;                      {unit eye vector for IPNT}
  m: real;                             {scratch mult factor}
  d: real;                             {displacement from IPNT to plane}
  p: vect_3d_t;                        {input point projected onto plane}

label
  no_inverse;

begin
  if not rend_3dpl.inverse             {combined plane transform not invertable ?}
    then goto no_inverse;
{
*   Set EYE to the unit vector from the input point towards the eye.
}
  if rend_view.perspec_on
    then begin                         {perspective is ON}
      eye.x := -ipnt.x;
      eye.y := -ipnt.y;
      eye.z := rend_view.eyedis - ipnt.z;
      m := sqr(eye.x) + sqr(eye.y) + sqr(eye.z); {square of raw eye vector magnitude}
      if m < 1.0E-30 then goto no_inverse; {raw eye vector too small to unitize ?}
      m := 1.0 / sqrt(m);              {make mult factor for unitizing eye vector}
      eye.x := m * eye.x;              {unitize eye vector}
      eye.y := m * eye.y;
      eye.z := m * eye.z;
      end
    else begin                         {perspective is OFF}
      eye.x := 0.0;
      eye.y := 0.0;
      eye.z := 1.0;
      end
    ;
{
*   EYE is set to the unit eye vector.
}
  d :=                                 {displacement from IPNT to plane}
    (rend_3dpl.org.x - ipnt.x) * rend_3dpl.front.x +
    (rend_3dpl.org.y - ipnt.y) * rend_3dpl.front.y +
    (rend_3dpl.org.z - ipnt.z) * rend_3dpl.front.z;
  m :=                                 {cosine between eye vector and plane normal}
    (eye.x * rend_3dpl.front.x) +
    (eye.y * rend_3dpl.front.y) +
    (eye.z * rend_3dpl.front.z);
  if abs(m) < 1.0E-20
    then begin                         {plane is too edge-on to viewer}
      p.x := ipnt.x + d * rend_3dpl.front.x; {project to nearest point on plane}
      p.y := ipnt.y + d * rend_3dpl.front.y;
      p.z := ipnt.z + d * rend_3dpl.front.z;
      end
    else begin                         {eye vector does intersect plane}
      d := d / m;                      {make distance from IPNT to plane along EYE}
      p.x := ipnt.x + d * eye.x;       {project along eye vector onto plane}
      p.y := ipnt.y + d * eye.y;
      p.z := ipnt.z + d * eye.z;
      end
    ;
{
*   P is the input point projected onto the plane.
}
  p.x := p.x - rend_3dpl.org.x;        {make point relative to plane origin}
  p.y := p.y - rend_3dpl.org.y;
  p.z := p.z - rend_3dpl.org.z;

  opnt.x :=                            {make final 2D point in 3DPL space}
    p.x * rend_3dpl.xb_inv.x +
    p.y * rend_3dpl.yb_inv.x +
    p.z * rend_3dpl.zb_inv.x;
  opnt.y :=
    p.x * rend_3dpl.xb_inv.y +
    p.y * rend_3dpl.yb_inv.y +
    p.z * rend_3dpl.zb_inv.y;
  return;
{
*   Jump here if the 3D to 3DPL transform does not exist.
}
no_inverse:
  opnt.x := 0.0;
  opnt.y := 0.0;
  end;
{
**************************************
*
*   Subroutine REND_SW_GET_CPNT_3DPL (X, Y)
*
*   Return the 3DPL space current point.
}
procedure rend_sw_get_cpnt_3dpl (      {return the current point}
  out     x, y: real);                 {current point in this space}

begin
  x := rend_3dpl.sp.cpnt.x;
  y := rend_3dpl.sp.cpnt.y;
  end;
{
**************************************
*
*   Subroutine REND_SW_GET_XFORM_3DPL_2D (XB, YB, OFS)
*
*   Returns the 2D transform within the 3DPL space.  This transform is
*   concatenated with the current plane definition to create the total
*   3DPL space to 3D space transform.
}
procedure rend_sw_get_xform_3dpl_2d (  {get 2D transform in 3D current plane}
  out     xb: vect_2d_t;               {X basis vector}
  out     yb: vect_2d_t;               {Y basis vector}
  out     ofs: vect_2d_t);             {offset vector}

begin
  xb := rend_3dpl.sp.xb;
  yb := rend_3dpl.sp.yb;
  ofs := rend_3dpl.sp.ofs;
  end;
{
**************************************
*
*   Subroutine REND_SW_GET_XFORM_3DPL_PLANE (ORG, XB, YB)
*
*   Returns the current plane part of the 3DPL transform.  The total 3DPL
*   space to 3D space transform is the concatenation of a 2D (3x2)
*   transform with the current plane definition.
}
procedure rend_sw_get_xform_3dpl_plane ( {get definition of current plane in 3D space}
  out     org: vect_3d_t;              {origin for 2D space}
  out     xb: vect_3d_t;               {X basis vector}
  out     yb: vect_3d_t);              {Y basis vector}

begin
  org := rend_3dpl.u_org;
  xb := rend_3dpl.u_xb;
  yb := rend_3dpl.u_yb;
  end;
{
**************************************
*
*   Subroutine REND_SW_GET_XFPNT_3DPL (IPNT, OPNT)
*
*   Transforms the 2D point IPNT from the 3DPL space to the 3D space.
*   The resulting 3D point is returned in OPNT.
}
procedure rend_sw_get_xfpnt_3dpl (     {transform point from 3DPL to 3D space}
  in      ipnt: vect_2d_t;             {input point in 3DPL space}
  out     opnt: vect_3d_t);            {output point in 3D space}
  val_param;

begin
  opnt.x :=
    (ipnt.x * rend_3dpl.xb.x) +
    (ipnt.y * rend_3dpl.yb.x) +
    rend_3dpl.org.x;
  opnt.y :=
    (ipnt.x * rend_3dpl.xb.y) +
    (ipnt.y * rend_3dpl.yb.y) +
    rend_3dpl.org.y;
  end;
