{   Subroutine REND_SW_RAY_VISPROP_NEW
*
*   Make sure the ray tracing visual properties block correctly reflects the
*   current RENDlib surface properties.  If REND_RAY.VISPROP_USED is TRUE, then
*   a new visprop block is created.
}
module rend_sw_ray_visprop_new;
define rend_sw_ray_visprop_new;
%include 'rend_sw2.ins.pas';

procedure rend_sw_ray_visprop_new;     {make new current ray tracing visprop block}
{
********************************************************************************
*
*   Local subroutine FILL_VISPROP (S, V)
*
*   Fill in the ray tracer VISPROP block V from the RENDlib surface properties
*   block S.
}
procedure fill_visprop (
  in      s: rend_suprop_t;            {input RENDlib surface properties}
  out     v: type1_visprop_t);         {ray tracer VISPROP block to fill in}
  val_param;

begin
  if s.emis_on
    then begin                         {emissive is ON}
      v.emis_red := s.emis.red;
      v.emis_grn := s.emis.grn;
      v.emis_blu := s.emis.blu;
      end
    else begin                         {emissive is OFF}
      v.emis_red := 0.0;
      v.emis_grn := 0.0;
      v.emis_blu := 0.0;
      end
    ;

  if s.diff_on
    then begin                         {diffuse is ON}
      v.diff_red := s.diff.red;
      v.diff_grn := s.diff.grn;
      v.diff_blu := s.diff.blu;
      end
    else begin                         {diffuse is OFF}
      v.diff_red := 0.0;
      v.diff_grn := 0.0;
      v.diff_blu := 0.0;
      end
    ;
  v.diff_on := s.diff_on;

  if s.spec_on
    then begin                         {specular is ON}
      v.spec_red := s.spcol.red;
      v.spec_grn := s.spcol.grn;
      v.spec_blu := s.spcol.blu;
      v.spec_exp := round(s.spexp);
      end
    else begin                         {specular is OFF}
      v.spec_red := 0.0;
      v.spec_grn := 0.0;
      v.spec_blu := 0.0;
      v.spec_exp := 1;
      end
    ;
  v.spec_on := s.spec_on;

  if s.trans_on and ((s.trans_side < 0.999) or (s.trans_front < 0.999))
    then begin                         {transparency is ON and not fully opaque}
      if abs(s.trans_side - s.trans_front) < 0.001
        then begin                     {front and side opacity are effectively same}
          v.opac_front := s.trans_front;
          v.opac_side := s.trans_front;
          end
        else begin                     {front and side opacity are different}
          v.opac_front := s.trans_front;
          v.opac_side := s.trans_side;
          end
        ;
      v.opac_on := true;               {set ray tracer variable opacity ON}
      end
    else begin                         {transparency is OFF or fully opaque}
      v.opac_front := 1.0;
      v.opac_side := 1.0;
      v.opac_on := false;
      end
    ;
  end;
{
********************************************************************************
*
*   Start of main routine.
}
begin
  if rend_ray.visprop_used then begin  {old visprop was used, need to save it ?}
    rend_ray.visprop_p :=              {allocate memory for new visprop block}
      ray_mem_alloc_perm (sizeof(rend_ray.visprop_p^));
    rend_ray.visprop_back_p := nil;    {init to back side block not allocated yet}
    end;

  if rend_face_back.on and (rend_ray.visprop_back_p = nil) then begin {need back ?}
    rend_ray.visprop_back_p :=         {allocate memory for back face visprop}
      ray_mem_alloc_perm (sizeof(rend_ray.visprop_back_p^));
    end;
{
*   REND_RAY.VISPROP_P is pointing to the ray tracer visual properties block
*   we need to fill in.
}
  fill_visprop (rend_face_front, rend_ray.visprop_p^); {fill in front face data}
  if rend_face_back.on
    then begin                         {separate properties enabled for back side}
      fill_visprop (rend_face_back, rend_ray.visprop_back_p^); {fill back face data}
      rend_ray.visprop_p^.back_p := rend_ray.visprop_back_p; {set pnt to back vals}
      end
    else begin                         {same properties in use for front/back}
      rend_ray.visprop_p^.back_p := nil; {indicate no separate back properties}
      end
    ;

  rend_ray.visprop_old := false;       {visprop block is now up to date}
  rend_ray.visprop_used := false;      {new visprop block has not been used yet}
  end;
