{   Module REND_SW_SURF
*
*   Collection of routines that deal with object visual surface properties.
}
module rend_sw_surf;
define rend_sw_surf_face_curr;
define rend_sw_surf_face_on;
define rend_sw_suprop_on;
define rend_sw_suprop_val;
%include 'rend_sw2.ins.pas';
{
***************************************
*
*   Subroutine REND_SW_SURF_FACE_CURR (FACE)
*
*   Select for which polygon face future changes to surface properties will effect.
*   There are currently separate surface property definitions for the front and
*   back face of a polygon.  All routines to make changes to any visual surface
*   properties change the definition for the current face.  The front face of a
*   polygon is the one with the geometric normal vector pointing out from it.
*   Also, it *MUST* be true that when viewing the front face, the verticies are
*   traversed in a counter-clockwise order from first to last.
*
*   Use the constant REND_FACE_FRONT_K or REND_FACE_BACK_K for values of FACE.
}
procedure rend_sw_surf_face_curr (     {set which suprop to use for future set/get(s)}
  in      face: rend_face_k_t);        {polygon face select, use REND_FACE_xx_K}
  val_param;

begin
  rend_curr_face := face;
  end;
{
***************************************
*
*   Subroutine REND_SW_SURF_FACE_ON (ON)
*
*   Turn the visual surface properties for the current face on/off.  This is
*   really only useful for the back face.  If the back face visual surface
*   properties block is turned off when the back face is displayed, then the
*   visual surface properties for the front face will be used.
}
procedure rend_sw_surf_face_on (       {enable surface properties for current face}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param;

var
  p: rend_suprop_p_t;                  {pointer to current surface properties block}

begin
  case rend_curr_face of               {make pointer to curr suprop block}
rend_face_front_k: p := addr(rend_face_front);
rend_face_back_k: p := addr(rend_face_back);
otherwise return;
    end;
  if p^.on = on then return;           {nothing is getting changed ?}
  p^.on := on;                         {make the change}

  rend_suprop.changed := true;         {indicate surface properties changed}
  rend_internal.check_modes^;          {notify system of the change}
  end;
{
***************************************
*
*   Subroutine REND_SW_SUPROP_ON (SUPROP,ON)
*
*   Turn a particular surface property on/off for the current face.
*   SUPROP is the ID for the selected surface property.  Use the constants of the
*   form REND_SUPROP_xx_K for values of SUPROP.
}
procedure rend_sw_suprop_on (          {turn particular surface property on/off}
  in      suprop: rend_suprop_k_t;     {surf prop ID, use REND_SUPROP_xx_K constants}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param;

var
  p: rend_suprop_p_t;                  {pointer to current surface properties block}

begin
  case rend_curr_face of               {make pointer to curr suprop block}
rend_face_front_k: p := addr(rend_face_front);
rend_face_back_k: p := addr(rend_face_back);
otherwise return;
    end;

  case suprop of                       {different code for each surface property}
rend_suprop_emis_k: begin
      if p^.emis_on = on then return;
      p^.emis_on := on;
      end;
rend_suprop_diff_k: begin
      if p^.diff_on = on then return;
      p^.diff_on := on;
      end;
rend_suprop_spec_k: begin
      if p^.spec_on = on then return;
      p^.spec_on := on;
      end;
rend_suprop_trans_k: begin
      if p^.trans_on = on then return;
      p^.trans_on := on;
      end;
    end;                               {end of surface property type cases}

  rend_suprop.changed := true;         {indicate surface properties changed}
  rend_internal.check_modes^;          {notify system of the change}
  end;
{
***************************************
*
*   Subroutine REND_SW_SUPROP_VAL (SUPROP,VAL)
*
*   Set the value of a particular visual surface property for the current face.
*   VAL is defined differently for each specific surface property.
}
procedure rend_sw_suprop_val (         {set value for particular surface property}
  in      suprop: rend_suprop_k_t;     {surf prop ID, use REND_SUPROP_xx_K constants}
  in      val: rend_suprop_val_t);     {SUPROP dependent data values}
  val_param;

var
  p: rend_suprop_p_t;                  {pointer to current surface properties block}

begin
  case rend_curr_face of               {make pointer to curr suprop block}
rend_face_front_k: p := addr(rend_face_front);
rend_face_back_k: p := addr(rend_face_back);
otherwise return;
    end;

  case suprop of                       {different code for each surface property}
rend_suprop_emis_k: begin
      p^.emis.red := val.emis_red;
      p^.emis.grn := val.emis_grn;
      p^.emis.blu := val.emis_blu;
      end;
rend_suprop_diff_k: begin
      p^.diff.red := val.diff_red;
      p^.diff.grn := val.diff_grn;
      p^.diff.blu := val.diff_blu;
      end;
rend_suprop_spec_k: begin
      p^.spcol.red := val.spec_red;
      p^.spcol.grn := val.spec_grn;
      p^.spcol.blu := val.spec_blu;
      p^.spexp := val.spec_exp;
      p^.iexp := round(val.spec_exp);
      end;
rend_suprop_trans_k: begin
      p^.trans_front := val.trans_front;
      p^.trans_side := val.trans_side;
      end;
    end;                               {end of surface property type cases}

  rend_suprop.changed := true;         {indicate surface properties changed}
  rend_internal.check_modes^;          {notify system of the change}
  end;
