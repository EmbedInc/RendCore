{   Subroutine REND_SW_SPHERE_3D (X, Y, Z, R)
*
*   Draw the sphere at point X,Y,Z with radius R.
*
*   This version of the SPHERE_3D primitives creates triangles and passes them
*   on to the internal TRI_CACHE_3D primitive.  This particular implementation
*   isn't very efficient in how the sphere is tesselated.
*
*   PRIM_DATA PRIM_DATA_P rend_internal.tri_cache_3d_data_p
}
module rend_sw_sphere_3d;
define rend_sw_sphere_3d;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_sphere_3d_d.ins.pas';

procedure rend_sw_sphere_3d (          {draw a sphere}
  in      x, y, z: real;               {sphere center point}
  in      r: real);                    {radius}
  val_param;

var
  rgba: rend_rgba_t;                   {color and opacity in case DIFF enabled}
  ll, lr, ur, ul: vect_3d_t;           {coordinates of current original face corners}
  duv: real;                           {U and V increment for traversing face}
  duv2: real;                          {half of DUV}
  nface: sys_int_machine_t;            {number of segments in a face}
  vcache_ind: sys_int_machine_t;       {VERT3D index we use for VCACHE pointer}
  vert3d_bytes: sys_int_adr_t;         {size of VERT3D with our VCACHE pointer}
  ll_p, lr_p, ur_p, ul_p: rend_vert3d_p_t; {pointers to vert descriptors}
{
************************************************************************
*
*   Local function ROUNDUP (A, R)
*
*   Round the address value A up to the nearest multiple of R.
}
function roundup (                     {make value of A rounded up to mult of R}
  in      a: sys_int_adr_t;            {value to round}
  in      r: sys_int_machine_t)        {multiple to round up to}
  :sys_int_adr_t;                      {resulting value}
  val_param;

begin
  roundup := ((a + r - 1) div r) * r;
  end;
{
************************************************************************
*
*   Local subroutine NEW_VERT (V_P)
*
*   Create a new RENDlib 3D vertex descriptor and initialize as much as possible.
*   The descriptor must later be deallocated with a call to SYS_MEM_DEALLOC.
*   This routine also allocates the memory for the COOR, NORM, VCACHE values.
}
procedure new_vert (                   {create and init new 3D vertex descriptor}
  out     v_p: rend_vert3d_p_t);       {returned pointer to new descriptor}

var
  sz: sys_int_adr_t;                   {memory size}
  ofs_coor: sys_int_adr_t;             {offset for COOR value}
  ofs_norm: sys_int_adr_t;             {offset for NORM value}
  ofs_vcache: sys_int_adr_t;           {offset for VCACHE value}

begin
  sz := vert3d_bytes;                  {init size to raw VERT3D descriptor}

  sz := roundup(sz, sizeof(single));   {align properly for COOR value}
  ofs_coor := sz;                      {save offset to COOR value}
  sz := sz + sizeof(vect_3d_fp1_t);    {leave room for the COOR value}

  sz := roundup(sz, sizeof(single));   {align properly for NORM value}
  ofs_norm := sz;                      {save offset to NORM value}
  sz := sz + sizeof(vect_3d_fp1_t);    {leave room for the NORM value}

  sz := roundup(sz,                    {align properly for VCACHE value}
    max(sizeof(sys_int_machine_t), sizeof(single)));
  ofs_vcache := sz;                    {save offset for VCACHE value}
  sz := sz + sizeof(rend_vcache_t);    {leave room for VCACHE}

  sys_mem_alloc (sz, v_p);             {allocate memory for descriptor}
  sys_mem_error (v_p, '', '', nil, 0); {barf on didn't get the memory}

  v_p^[rend_coor_p_ind].coor_p := univ_ptr( {set pointer to COOR value}
    sys_int_adr_t(v_p) + ofs_coor);

  if rend_norm_p_ind >= 0 then begin   {NORM value enabled ?}
    v_p^[rend_norm_p_ind].norm_p := univ_ptr( {set pointer to NORM value}
      sys_int_adr_t(v_p) + ofs_norm);
    end;

  if rend_diff_p_ind >= 0 then begin   {DIFF value enabled ?}
    if rend_vert3d_always[rend_vert3d_diff_p_k]
      then begin                       {must not be NIL pointer}
        v_p^[rend_diff_p_ind].diff_p := addr(rgba);
        end
      else begin                       {NIL pointer is allowed}
        v_p^[rend_diff_p_ind].diff_p := nil;
        end
      ;
    end;

  v_p^[vcache_ind].vcache_p := univ_ptr( {we always have a pointer to a vertex cache}
    sys_int_adr_t(v_p) + ofs_vcache);
  end;
{
************************************************************************
*
*   Local subroutine FILL_VERT (VERT, U, V)
*
*   Fill in the COOR and NORM values in the vertex descriptor VERT.  U,V
*   are the relative coordinates within the current original face, as defined
*   by LL, LR, UR, UL.
}
procedure fill_vert (                  {fill in COOR and NORM value in vertex VERT}
  in out  vert: rend_vert3d_t;         {vertex descriptor}
  in      u, v: real);                 {horizontal, vertical indices into orig face}
  val_param;

var
  wll, wlr, wur, wul: real;            {weighting factors for each of the corners}
  dx, dy, dz: real;                    {vector from sphere center}
  m: real;                             {mult factor for unitizing vector}

begin
  wll := 1.0 - u;                      {init left edge based on U}
  wul := wll;
  wlr := u;                            {init right edge based on U}
  wur := u;
  wll := wll * (1.0 - v);              {factor in V weighting of lower edge}
  wlr := wlr * (1.0 - v);
  wul := wul * v;                      {factor in V weighting of upper edge}
  wur := wur * v;

  dx := (ll.x * wll) + (lr.x * wlr) + (ur.x * wur) + (ul.x * wul); {interpoate coor}
  dy := (ll.y * wll) + (lr.y * wlr) + (ur.y * wur) + (ul.y * wul);
  dz := (ll.z * wll) + (lr.z * wlr) + (ur.z * wur) + (ul.z * wul);

  m := 1.0 / sqrt(sqr(dx) + sqr(dy) + sqr(dz)); {mult factor for unitizing vect}
  dx := dx * m;                        {make unit vector from sphere center}
  dy := dy * m;
  dz := dz * m;

  if rend_norm_p_ind >= 0 then begin   {need to set the shading normal vector ?}
    vert[rend_norm_p_ind].norm_p^.x := dx; {set the shading normal vector}
    vert[rend_norm_p_ind].norm_p^.y := dy;
    vert[rend_norm_p_ind].norm_p^.z := dz;
    end;

  vert[rend_coor_p_ind].coor_p^.x := x + dx * r; {fill in the actual coordinate}
  vert[rend_coor_p_ind].coor_p^.y := y + dy * r;
  vert[rend_coor_p_ind].coor_p^.z := z + dz * r;

  vert[vcache_ind].vcache_p^.version := {any cached data is now invalid}
    rend_cache_version_invalid;
  end;
{
************************************************************************
*
*   Local subroutine DRAW_TRI (V1, V2, V3)
*
*   Draw the triangle between the three vertices.  When viewed from the front
*   face, the vertices V1,V2,V3 will appear in counter-clockwise order.
}
procedure draw_tri (                   {draw triangle from three vertex descriptors}
  in      v1, v2, v3: univ rend_vert3d_t); {vertex descriptors}

var
  e1: vect_3d_t;                       {edge 1 vector}
  e2: vect_3d_t;                       {edge 2 vector}
  gnorm: vect_3d_t;                    {geometric normal vector}

begin
  e1.x := v2[rend_coor_p_ind].coor_p^.x - v1[rend_coor_p_ind].coor_p^.x; {edge V1-V2}
  e1.y := v2[rend_coor_p_ind].coor_p^.y - v1[rend_coor_p_ind].coor_p^.y;
  e1.z := v2[rend_coor_p_ind].coor_p^.z - v1[rend_coor_p_ind].coor_p^.z;
  e2.x := v3[rend_coor_p_ind].coor_p^.x - v1[rend_coor_p_ind].coor_p^.x; {edge V1-V3}
  e2.y := v3[rend_coor_p_ind].coor_p^.y - v1[rend_coor_p_ind].coor_p^.y;
  e2.z := v3[rend_coor_p_ind].coor_p^.z - v1[rend_coor_p_ind].coor_p^.z;

  gnorm.x := (e1.y * e2.z) - (e1.z * e2.y); {make geometric normal}
  gnorm.y := (e1.z * e2.x) - (e1.x * e2.z);
  gnorm.z := (e1.x * e2.y) - (e1.y * e2.x);

  rend_internal.tri_cache_3d^ (        {draw the triangle}
    v1, v2, v3,                        {vertex descriptors}
    v1[vcache_ind].vcache_p^,          {vertex caches}
    v2[vcache_ind].vcache_p^,
    v3[vcache_ind].vcache_p^,
    gnorm);                            {geometric normal vector}
  end;
{
************************************************************************
*
*   Local subroutine DRAW_FACE
*
*   Draw the current original face.
}
procedure draw_face;

var
  iu, iv: sys_int_machine_t;           {current U, V increment number}
  u, v: real;                          {current U, V value}
  p: univ_ptr;                         {scratch for swapping pointers}
  llur: boolean;                       {TRUE if cut along LL to UR diagonal}

begin
  v := 0.0;                            {start at bottom of face}
  for iv := 1 to nface do begin        {up the rows of quads}
    u := 0.0;                          {start at left edge of face}
    fill_vert (ll_p^, u, v);           {init lower left corner of first quad}
    fill_vert (ul_p^, u, v + duv);     {init upper left corner of first quad}

    for iu := 1 to nface do begin      {across this row of quads}
      u := u + duv;                    {step one segment to the right}
      fill_vert (lr_p^, u, v);         {make lower right corner of this quad}
      fill_vert (ur_p^, u, v + duv);   {make upper right corner of this quad}
      if (u - duv2) < 0.5
        then llur := (v + duv2) < 0.5
        else llur := (v + duv2) >= 5.0;
      if llur                          {draw two triangles for this quad}
        then begin                     {cut quad along LL to UR diagnonal}
          draw_tri (ur_p^, ul_p^, ll_p^); {top left tri}
          draw_tri (ur_p^, ll_p^, lr_p^); {bottom right tri}
          end
        else begin                     {cut quad along UL to LR diagonal}
          draw_tri (ul_p^, lr_p^, ur_p^); {top right tri}
          draw_tri (ul_p^, ll_p^, lr_p^); {bottom left tri}
          end
        ;
      p := ll_p;                       {old leading edge is new trailing edge}
      ll_p := lr_p;
      lr_p := p;
      p := ul_p;
      ul_p := ur_p;
      ur_p := p;
      end;                             {back to do next quad in this row}

    v := v + duv;                      {advance to next row up}
    end;                               {back to do next row of quads up}
  end;
{
************************************************************************
*
*   Srart of main routine.
}
begin
  if rend_vcache_p_ind >= 0
    then begin                         {VCACHE already enabled}
      vcache_ind := rend_vcache_p_ind; {we will use the same index for VCACHE_P}
      vert3d_bytes := rend_vert3d_bytes; {no change in vertex descriptor size needed}
      end
    else begin                         {VCACHE feature disabled}
      vcache_ind :=                    {make index for next entry after VERT3D end}
        rend_vert3d_bytes div sizeof(ll_p^[0]);
      vert3d_bytes :=                  {grow descriptor to include VCACHE_P}
        rend_vert3d_bytes + sizeof(ll_p^[0]);
      end;
    ;                                  {VCACHE_IND and VERT3D_BYTES all set}

  nface := (rend_cirres[1] + 3) div 4; {number of segments along one face}
  duv := 1.0 / nface;                  {increment per sample along a face}
  duv2 := 0.5 * duv;                   {half increment}
  if                                   {a valid RGBA pointer is required ?}
      (rend_diff_p_ind >= 0) and       {DIFF vertex value enabled ?}
      rend_vert3d_always[rend_vert3d_diff_p_k] {DIFF_P must not be NIL ?}
      then begin
    rgba.red := rend_face_front.diff.red; {fill in static RGBA descriptor to pnt to}
    rgba.grn := rend_face_front.diff.grn;
    rgba.blu := rend_face_front.diff.blu;
    rgba.alpha := 0.5 * (rend_face_front.trans_front + rend_face_front.trans_side);
    end;

  new_vert (ll_p);                     {allocate temporary vertex descriptors}
  new_vert (lr_p);
  new_vert (ur_p);
  new_vert (ul_p);

  ll.x :=  0.0;   ll.y := -1.0;   ll.z :=  1.0;
  lr.x :=  1.0;   lr.y := -1.0;   lr.z :=  0.0;
  ur.x :=  1.0;   ur.y :=  1.0;   ur.z :=  0.0;
  ul.x :=  0.0;   ul.y :=  1.0;   ul.z :=  1.0;
  draw_face;

  ll.x :=  1.0;   ll.y := -1.0;   ll.z :=  0.0;
  lr.x :=  0.0;   lr.y := -1.0;   lr.z := -1.0;
  ur.x :=  0.0;   ur.y :=  1.0;   ur.z := -1.0;
  ul.x :=  1.0;   ul.y :=  1.0;   ul.z :=  0.0;
  draw_face;

  ll.x :=  0.0;   ll.y := -1.0;   ll.z := -1.0;
  lr.x := -1.0;   lr.y := -1.0;   lr.z :=  0.0;
  ur.x := -1.0;   ur.y :=  1.0;   ur.z :=  0.0;
  ul.x :=  0.0;   ul.y :=  1.0;   ul.z := -1.0;
  draw_face;

  ll.x := -1.0;   ll.y := -1.0;   ll.z :=  0.0;
  lr.x :=  0.0;   lr.y := -1.0;   lr.z :=  1.0;
  ur.x :=  0.0;   ur.y :=  1.0;   ur.z :=  1.0;
  ul.x := -1.0;   ul.y :=  1.0;   ul.z :=  0.0;
  draw_face;

  ll.x :=  1.0;   ll.y :=  1.0;   ll.z :=  0.0;
  lr.x :=  0.0;   lr.y :=  1.0;   lr.z := -1.0;
  ur.x := -1.0;   ur.y :=  1.0;   ur.z :=  0.0;
  ul.x :=  0.0;   ul.y :=  1.0;   ul.z :=  1.0;
  draw_face;

  ll.x :=  1.0;   ll.y := -1.0;   ll.z :=  0.0;
  lr.x :=  0.0;   lr.y := -1.0;   lr.z :=  1.0;
  ur.x := -1.0;   ur.y := -1.0;   ur.z :=  0.0;
  ul.x :=  0.0;   ul.y := -1.0;   ul.z := -1.0;
  draw_face;

  sys_mem_dealloc (ll_p);              {release temporary vertex descriptors}
  sys_mem_dealloc (lr_p);
  sys_mem_dealloc (ur_p);
  sys_mem_dealloc (ul_p);
  end;
