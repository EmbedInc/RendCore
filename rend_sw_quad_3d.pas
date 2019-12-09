{   Subroutine REND_SW_QUAD_3D (V1, V2, V3, V4)
*
*   Draw a quadrillateral.  The "front" suface of the quadrillateral is showing
*   when the verticies go around the polygon in counter-clockwise order.
*
*   This version of the QUAD primitive routine draws the quad as two separate
*   triangles.  The shorter of the two diagonals is used to break the quad.
}
module rend_sw_quad_3d;
define rend_sw_quad_3d;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_quad_3d_d.ins.pas';

procedure rend_sw_quad_3d (            {draw 3D model space quadrilateral}
  in      v1, v2, v3, v4: univ rend_vert3d_t); {pointer info for each vertex}
  val_param;

var
  d1: vect_3d_t;                       {V1 to V3 diagonal vector}
  d2: vect_3d_t;                       {V2 to V4 diagonal vector}
  gnorm: vect_3d_t;                    {geometric unit normal vector for each tri}
  v: vect_3d_t;                        {scratch vector}
  m: real;                             {scratch mult factor}

begin
  d1.x := v3[rend_coor_p_ind].coor_p^.x - v1[rend_coor_p_ind].coor_p^.x;
  d1.y := v3[rend_coor_p_ind].coor_p^.y - v1[rend_coor_p_ind].coor_p^.y;
  d1.z := v3[rend_coor_p_ind].coor_p^.z - v1[rend_coor_p_ind].coor_p^.z;

  d2.x := v4[rend_coor_p_ind].coor_p^.x - v2[rend_coor_p_ind].coor_p^.x;
  d2.y := v4[rend_coor_p_ind].coor_p^.y - v2[rend_coor_p_ind].coor_p^.y;
  d2.z := v4[rend_coor_p_ind].coor_p^.z - v2[rend_coor_p_ind].coor_p^.z;

  if
      (sqr(d1.x) + sqr(d1.y) + sqr(d1.z)) <=
      (sqr(d2.x) + sqr(d2.y) + sqr(d2.z))
    then begin                         {diagonal V1-V3 is shorter than V2-V4}
      v.x := v2[rend_coor_p_ind].coor_p^.x - v1[rend_coor_p_ind].coor_p^.x;
      v.y := v2[rend_coor_p_ind].coor_p^.y - v1[rend_coor_p_ind].coor_p^.y;
      v.z := v2[rend_coor_p_ind].coor_p^.z - v1[rend_coor_p_ind].coor_p^.z;

      gnorm.x := (v.y * d1.z) - (v.z * d1.y);
      gnorm.y := (v.z * d1.x) - (v.x * d1.z);
      gnorm.z := (v.x * d1.y) - (v.y * d1.x);

      if rend_shnorm_unit then begin   {need to unitize the geometric normal ?}
        m := 1.0 / sqrt(
          sqr(gnorm.x) + sqr(gnorm.y) + sqr(gnorm.z));
        gnorm.x := gnorm.x * m;
        gnorm.y := gnorm.y * m;
        gnorm.z := gnorm.z * m;
        end;

      rend_prim.tri_3d^ (v1, v2, v3, gnorm); {draw first triangle}

      v.x := v4[rend_coor_p_ind].coor_p^.x - v1[rend_coor_p_ind].coor_p^.x;
      v.y := v4[rend_coor_p_ind].coor_p^.y - v1[rend_coor_p_ind].coor_p^.y;
      v.z := v4[rend_coor_p_ind].coor_p^.z - v1[rend_coor_p_ind].coor_p^.z;

      gnorm.x := (d1.y * v.z) - (d1.z * v.y);
      gnorm.y := (d1.z * v.x) - (d1.x * v.z);
      gnorm.z := (d1.x * v.y) - (d1.y * v.x);

      if rend_shnorm_unit then begin   {need to unitize the geometric normal ?}
        m := 1.0 / sqrt(
          sqr(gnorm.x) + sqr(gnorm.y) + sqr(gnorm.z));
        gnorm.x := gnorm.x * m;
        gnorm.y := gnorm.y * m;
        gnorm.z := gnorm.z * m;
        end;

      rend_prim.tri_3d^ (v1, v3, v4, gnorm); {draw second triangle}
      end

    else begin                         {diagonal V2-V4 is smaller than V1-V3}
      v.x := v1[rend_coor_p_ind].coor_p^.x - v2[rend_coor_p_ind].coor_p^.x;
      v.y := v1[rend_coor_p_ind].coor_p^.y - v2[rend_coor_p_ind].coor_p^.y;
      v.z := v1[rend_coor_p_ind].coor_p^.z - v2[rend_coor_p_ind].coor_p^.z;

      gnorm.x := (d2.y * v.z) - (d2.z * v.y);
      gnorm.y := (d2.z * v.x) - (d2.x * v.z);
      gnorm.z := (d2.x * v.y) - (d2.y * v.x);

      if rend_shnorm_unit then begin   {need to unitize the geometric normal ?}
        m := 1.0 / sqrt(
          sqr(gnorm.x) + sqr(gnorm.y) + sqr(gnorm.z));
        gnorm.x := gnorm.x * m;
        gnorm.y := gnorm.y * m;
        gnorm.z := gnorm.z * m;
        end;

      rend_prim.tri_3d^ (v1, v2, v4, gnorm); {draw first triangle}

      v.x := v3[rend_coor_p_ind].coor_p^.x - v2[rend_coor_p_ind].coor_p^.x;
      v.y := v3[rend_coor_p_ind].coor_p^.y - v2[rend_coor_p_ind].coor_p^.y;
      v.z := v3[rend_coor_p_ind].coor_p^.z - v2[rend_coor_p_ind].coor_p^.z;

      gnorm.x := (v.y * d2.z) - (v.z * d2.y);
      gnorm.y := (v.z * d2.x) - (v.x * d2.z);
      gnorm.z := (v.x * d2.y) - (v.y * d2.x);

      if rend_shnorm_unit then begin   {need to unitize the geometric normal ?}
        m := 1.0 / sqrt(
          sqr(gnorm.x) + sqr(gnorm.y) + sqr(gnorm.z));
        gnorm.x := gnorm.x * m;
        gnorm.y := gnorm.y * m;
        gnorm.z := gnorm.z * m;
        end;

      rend_prim.tri_3d^ (v2, v3, v4, gnorm); {draw second triangle}
      end
    ;
  end;
