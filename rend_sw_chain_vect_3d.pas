{   Subroutine REND_SW_CHAIN_VECT_3D (N_VERTS,VERT_P_LIST)
*
*   Draw a set of vectors that are chained end to end.  VERT_P_LIST is an array of
*   pointers to 3D vertex descriptors.  The first vector starts at the first vertex
*   and the last vector ends at the last vertex.  N_VERTS is the number of verticies
*   in pointed to by VERT_P_LIST.  N_VERTS must be at least 2.  This primitive
*   trashes the current point.
}
module rend_sw_chain_vect_3d;
define rend_sw_chain_vect_3d;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_chain_vect_3d_d.ins.pas';

procedure rend_sw_chain_vect_3d (      {end-to-end chained vectors}
  in      n_verts: sys_int_machine_t;  {number of verticies pointed to by VERT_P_LIST}
  in      vert_p_list: univ rend_vert3d_p_list_t); {vertex descriptor pointer list}
  val_param;

var
  i: sys_int_machine_t;                {scratch integer and loop counter}

begin
  if rend_coor_p_ind < 0 then begin
    writeln (
      'COOR_P entry of 3D vertex descriptor required in REND_SW_CHAIN_VECT_3D.');
    sys_bomb;
    end;

  if n_verts < 2 then return;          {not enough verticies in list ?}
  rend_set.cpnt_3d^ (                  {move to start of first vector}
    vert_p_list[1]^[rend_coor_p_ind].coor_p^.x,
    vert_p_list[1]^[rend_coor_p_ind].coor_p^.y,
    vert_p_list[1]^[rend_coor_p_ind].coor_p^.z);
  for i := 2 to n_verts do begin       {once for each vector in chain}
    rend_prim.vect_3d^ (               {draw to endpoint of this vector}
      vert_p_list[i]^[rend_coor_p_ind].coor_p^.x,
      vert_p_list[i]^[rend_coor_p_ind].coor_p^.y,
      vert_p_list[i]^[rend_coor_p_ind].coor_p^.z);
    end;                               {back and draw next vector in chain}
  end;
