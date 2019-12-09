{   Module REND_SW_VIEW
*
*   Collection of routines that deal with 3D world to 2D model space transformations.
}
module rend_sw_view;
define rend_sw_backface;
define rend_sw_eyedis;
define rend_sw_new_view;
define rend_sw_perspec_on;
define rend_sw_z_clip;
define rend_sw_z_range;
%include 'rend_sw2.ins.pas';
{
************************************************
*
*   Subroutine REND_SW_BACKFACE (FLAG)
*
*   Set the new current backfacing operation.  The current backfacing operation
*   should be considered undefined until a call to SET.NEW_VIEW.
}
procedure rend_sw_backface (           {set new current backfacing operation}
  in      flag: rend_bface_k_t);       {from constants REND_BFACE_xx_K}
  val_param;

begin
  rend_view.backface := flag;
  end;
{
************************************************
*
*   Subroutine REND_SW_EYEDIS (E)
*
*   Set the new perspective value by giving the eye distance.  The eye point is
*   assumed to be on the Z axis looking towards the origin.  Objects on the plane
*   Z=0 are never altered in size by perspective.  Objects between the eye point
*   and Z=0 are made bigger, and objects past Z=0 from the eyepoint are made smaller.
*   E is the Z coordinate of that eyepoint.  for a +-1.0 viewing volume at the
*   origin, E is roughly 1/15 times the focal length of the "lens", assuming a
*   35mm camera.  Therefore a value of E=3.3 is about "normal" perspective, while
*   smaller values produce more extreme perspective, and larger values less.
*   Turning perspective off is mathematically (but not computationally)
*   equivalent to setting E to infinity.
*
*   Note that E is a pure perspective number; it does not control the view angle
*   as a true zoom would.  Only the RELATIVE sizes of objects in front and behind
*   the Z=0 plane are effected.
*
*   The eye distance should always be greater than the near Z range limit at the
*   time that SET.NEW_VIEW is called.
*   The current eye distance setting should be considered undefined until the next
*   call to SET.NEW_VIEW.
}
procedure rend_sw_eyedis (             {set perspective value using eye distance}
  in      e: real);                    {new value as eye distance dimensionless value}
  val_param;

begin
  rend_view.eyedis := e;
  end;
{
************************************************
*
*   Subroutine REND_SW_PERSPEC_ON (ON)
*
*   Turn perspective on/off.  When perspective is off, then the eye distance
*   parameter is irrelevant.  The current on/off setting should be considered
*   undefined until the next call to SET.NEW_VIEW.
}
procedure rend_sw_perspec_on (         {turn perspective on/off}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param;

begin
  rend_view.perspec_on := on;
  end;
{
************************************************
*
*   Subroutine REND_SW_Z_CLIP (NEAR,FAR)
*
*   Set the near and far Z clip limits.  These should be set at or inside the
*   Z range limits at the time SET.NEW_VIEW is called.  The current Z clip limits
*   should be considered undefined until the next call to SET.NEW_VIEW.
}
procedure rend_sw_z_clip (             {set 3DW space Z clip limits}
  in      near: real;                  {objects get clipped when Z > this value}
  in      far: real);                  {objects get clipped when Z < this value}
  val_param;

begin
  rend_view.zclip_near := near;
  rend_view.zclip_far := far;
  end;
{
************************************************
*
*   Subroutine REND_SW_Z_RANGE (NEAR,FAR)
*
*   Set the 3D world space near and far limits that the -1.0 to 1.0 Z buffer range
*   will map to.  The near Z range limit should be less than the eye distance value
*   (if perspective is turned on) at the time SET.NEW_VIEW is called.  The current
*   Z range limits should be considered undefined until the next call to
*   SET.NEW_VIEW.
}
procedure rend_sw_z_range (            {set 3DW space to full Z buffer range mapping}
  in      near: real;                  {3DW Z coordinate of Z buffer 1.0 value}
  in      far: real);                  {3DW Z coordinate of Z buffer -1.0 value}
  val_param;

begin
  rend_view.zrange_near := near;
  rend_view.zrange_far := far;
  end;
{
************************************************
*
*   Subroutine REND_SW_NEW_VIEW
*
*   This subroutine must be called after any change to the viewing geometry for it
*   to take effect properly.  Currently, the following calls effect the viewing
*   geometry:
*
*     SET.BACKFACE
*     SET.EYEDIS
*     SET.PERSPEC_ON
*     SET.XFORM_3D
*     SET.Z_CLIP
*     SET.Z_RANGE
*
*   Any number of these calls can be made together without calls to NEW_VIEW in
*   between, as long as NEW_VIEW is called at the end.  Intermediate conditions may
*   also be illegal, as long all conditions are legal when NEW_VIEW is called.
*   For example, if both the eye distance and the Z range are to be changed, the
*   eye distance may be temporarily set to less than the near Z range limit between
*   the two calls.  This is perfectly legal, as long as the condition no longer
*   exists when NEW_VIEW is finally called.
}
procedure rend_sw_new_view;

var
  zn: real;                            {near Z limit after raw perspective}
  zf: real;                            {far Z limit after raw perspective}

begin
  if rend_view.perspec_on
    then begin                         {perspective is turned ON}
      zn := (rend_view.zrange_near*rend_view.eyedis) {make warped Z range}
        / (rend_view.eyedis - rend_view.zrange_near);
      zf := (rend_view.zrange_far*rend_view.eyedis)
        / (rend_view.eyedis - rend_view.zrange_far);
      end
    else begin                         {perspective is turned OFF}
      zn := rend_view.zrange_near;     {copy Z range directly}
      zf := rend_view.zrange_far;
      end
    ;
  rend_view.zmult := 2.0/(zn-zf);      {mult factor for Z adjustment}
  rend_view.zadd :=                    {add constant for Z adjustment}
    -1.0 - zf*rend_view.zmult;
  rend_xf3d.vrad_ok := false;          {VRAD fields no longer valid}
  end;
