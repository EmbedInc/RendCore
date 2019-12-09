{   Subroutine REND_SW_TUBESEG_3D (P1,P2,CAP_START,CAP_END)
*
*   Draw a segment of an extruded tube.
*
*   P1, P2 - Descriptors for start and end points of the tube segment.
*     These data structures define the 2D planes at the segment ends, refer to
*     the tube crossection definition, etc.
*
*   CAP_START, CAP_END - Select start and end cap styles.  Implemented cap
*     styles are:
*
*       REND_TBCAP_NONE_K
*       REND_TBCAP_FLAT_K
}
module rend_sw_tubeseg_3d;
define rend_sw_tubeseg_3d;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_tubeseg_3d_d.ins.pas';

procedure rend_sw_tubeseg_3d (         {draw one segment of extruded tube}
  in      p1: rend_tube_point_t;       {point descriptor for start of tube segment}
  in      p2: rend_tube_point_t;       {point descriptor for end of tube segment}
  in      cap_start: rend_tbcap_k_t;   {selects cap style for segment start}
  in      cap_end: rend_tbcap_k_t);    {selects cap style for segment end}
  val_param;

const
  max_msg_parms = 1;                   {max parameters we can pass to a message}

type
  vert_data_t = record                 {stuff we need for our vertex descriptors}
    coor: vect_3d_fp1_t;               {XYZ coordinate}
    norm: vect_3d_fp1_t;               {shading normal vector}
    vcache: rend_vcache_t;             {vertex cache}
    end;

  vert_data_p_t =                      {pointer to our real per-vertex data}
    ^vert_data_t;

var
  xsec1_p, xsec2_p: rend_xsec_p_t;     {crossections for start and end of tubeseg}
  x1a_p, x1b_p: rend_xsec_point_p_t;   {current xsec points for end 1}
  x2a_p, x2b_p: rend_xsec_point_p_t;   {current xsec points for end 2}
  v1a_p, v1b_p: rend_vert3d_p_t;       {point to 3D verticies for end 1}
  v2a_p, v2b_p: rend_vert3d_p_t;       {point to 3D verticies for end 2}
  vmem_p: univ_ptr;                    {points to start of dynamically allocated mem}
  v1a_data, v1b_data, v2a_data, v2b_data: {data referenced by vertex descriptors}
    vert_data_t;
  d1a_p, d1b_p, d2a_p, d2b_p:          {pointers directly to our vertex data}
    vert_data_p_t;
  version_invalid: sys_int_machine_t;  {invalid cache version ID}
  ptr: univ_ptr;                       {scratch for swapping pointers}
  n_sides: sys_int_machine_t;          {number of sides to actually draw}
  i: sys_int_machine_t;                {loop counter}
  v1, v2: vect_3d_t;                   {scratch vector for making gnorm}
  gnorm: vect_3d_t;                    {geometric normal vector for triangle}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;
{
**********************************
*
*   Local subroutine MAKE_VERT_COOR (TP,XP,D)
*
*   Fill in the coordinate information for a vertex.
*
*   TP - Tube point descriptor.
*
*   XP - Crossection point descriptor.
*
*   D - Vertex data to fill in.  Will set COOR field.
}
procedure make_vert_coor (
  in      tp: rend_tube_point_t;       {tube point descriptor}
  in      xp: rend_xsec_point_t;       {crossection point descriptor}
  out     d: vert_data_t);             {vertex data structure, will fill in COOR}

begin
  d.vcache.version := version_invalid; {invalidate cached vertex data}

  d.coor.x := tp.coor_p^.x +           {do the 2D to 3D plane transform}
    (xp.coor.x * tp.xb.x) + (xp.coor.y * tp.yb.x);
  d.coor.y := tp.coor_p^.y +
    (xp.coor.x * tp.xb.y) + (xp.coor.y * tp.yb.y);
  d.coor.z := tp.coor_p^.z +
    (xp.coor.x * tp.xb.z) + (xp.coor.y * tp.yb.z);
  end;
{
**********************************
*
*   Local subroutine MAKE_VERT_SHNORM (TP,XP,BEF,C2,V,D)
*
*   Set the shading normal vector field for a vertex.
*
*   TB - Tube point descriptor.
*
*   XP - Crossection point descriptor.
*
*   BEF - TRUE if this is the "before" shading normal, FALSE for "after".
*
*   C2 - Coordinate of vertex at other end of tube segment at corresponding
*     position in its crossection.
*
*   V - Vertex descriptor for this point.  The SHNORM pointer will either be
*     set to point to the shading normal produced, or NIL if it was not possible
*     to produce a workable shading normal.
*
*   D - Vertex data.  NORM field will be filled in.  The cached vertex data
*     will be invalidated if any vertex data is changed.
}
procedure make_vert_shnorm (
  in      tp: rend_tube_point_t;       {tube point descriptor}
  in      xp: rend_xsec_point_t;       {crossection point descriptor}
  in      bef: boolean;                {TRUE for "before" shnorm, FALSE for "after"}
  in      c2: vect_3d_fp1_t;           {coor of "other" vertex at same xsec position}
  out     v: rend_vert3d_t;            {vertex descriptor}
  out     d: vert_data_t);             {vertex data structure, will fill in COOR}

var
  n_p: vect_2d_p_t;                    {points to untransformed shading normal}
  v1, v2: vect_3d_t;                   {vectors for intermediate calculations}

begin
  if rend_norm_p_ind < 0 then return;  {shading normals not enabled ?}
  d.vcache.version := version_invalid; {invalidate cached vertex data}

  if bef                               {which shading normal to use ?}
    then n_p := addr(xp.norm_bef)      {use "before" shading normal}
    else n_p := addr(xp.norm_aft);     {use "after" shading normal}

  d.norm.x :=                          {init shnorm to be in segment end plane}
    (n_p^.x * tp.nxb.x) + (n_p^.y * tp.nyb.x);
  d.norm.y :=
    (n_p^.x * tp.nxb.y) + (n_p^.y * tp.nyb.y);
  d.norm.z :=
    (n_p^.x * tp.nxb.z) + (n_p^.y * tp.nyb.z);

  case tp.shade of                     {what kind of shnorm rule is selected ?}

rend_tblen_shade_facet_k: begin        {make shnorm orthogonal to segment side}
      v1.x := c2.x - d.coor.x;         {make vector along tube surface}
      v1.y := c2.y - d.coor.y;
      v1.z := c2.z - d.coor.z;

      v2.x := (v1.y * d.norm.z) - (v1.z * d.norm.y); {perp to surface and orig norm}
      v2.y := (v1.z * d.norm.x) - (v1.x * d.norm.z);
      v2.z := (v1.x * d.norm.y) - (v1.y * d.norm.x);

      d.norm.x := (v2.y * v1.z) - (v2.z * v1.y); {cross product for final shnorm}
      d.norm.y := (v2.z * v1.x) - (v2.x * v1.z);
      d.norm.z := (v2.x * v1.y) - (v2.y * v1.x);
      end;

rend_tblen_shade_endplane_k: ;         {shnorm in end plane, already set this way}

otherwise                              {illegal or unimplemented shnorm rule}
    sys_msg_parm_int (msg_parm[1], ord(tp.shade));
    rend_message_bomb ('rend', 'rend_tbpoint_shade_rule_bad', msg_parm, 1);
    end;                               {end of shading normal rule cases}
{
*   Check whether the resulting shading normal is valid, and then either set
*   the vertex pointing to it, or set it to NIL.
}
  if (sqr(d.norm.x)+sqr(d.norm.y)+sqr(d.norm.z)) > 1.0E-30
    then begin                         {shading normal we calculated is useable}
      v[rend_norm_p_ind].norm_p := addr(d.norm);
      end
    else begin                         {calculated shading normal is unuseable}
      v[rend_norm_p_ind].norm_p := nil;
      end
    ;
  end;
{
**********************************
*
*   Local subroutine DRAW_CAP (STYLE,TP,XSEC,FLIP)
*
*   Draw an end cap.
*
*   STYLE - End cap style.  Supported styles are:
*
*     REND_TBCAP_NONE_K
*     REND_TBCAP_FLAT_K
*
*   TP - Tube point descriptor.
*
*   XSEC - Crossection descriptor.
*
*   FLIP - If TRUE, flip the triangle around.  This means ordering the verticies
*     in the other direction and flipping all the normals.
}
procedure draw_cap (
  in      style: rend_tbcap_k_t;       {cap style selector}
  in      tp: rend_tube_point_t;       {tube point descriptor}
  in      xsec: rend_xsec_t;           {crossection descriptor}
  in      flip: boolean);              {flip triangles around if TRUE}

var
  xp_p: rend_xsec_point_p_t;           {points to current crossection point}
  gnorm: vect_3d_t;                    {geometric normal of end plane}
  i: sys_int_machine_t;                {loop counter}

begin
  case style of
rend_tbcap_none_k: return;
{
*   End cap style is FLAT.
*   The cap will be draw by spoking into triangles from the first vertex.
}
rend_tbcap_flat_k: begin
  if rend_norm_p_ind >= 0 then begin   {shading normals enabled ?}
    v1a_p^[rend_norm_p_ind].norm_p := nil; {disable separate shading norms per vert}
    v2a_p^[rend_norm_p_ind].norm_p := nil;
    v2b_p^[rend_norm_p_ind].norm_p := nil;
    end;

  xp_p := xsec.first_p;                {init curr crossection point to first}
  make_vert_coor (tp, xp_p^, d1a_p^);  {set coordinate for spoke vertex}

  xp_p := xp_p^.next_p;                {advance to second point in crossection}
  make_vert_coor (tp, xp_p^, d2a_p^);  {init second vertex in first triangle}

  if flip
    then begin                         {use flipped geometric normal}
      gnorm.x := -tp.nzb.x;
      gnorm.y := -tp.nzb.y;
      gnorm.z := -tp.nzb.z;
      end
    else begin                         {use unflipped geometric normal}
      gnorm := tp.nzb;
      end
    ;

  for i := 3 to xsec.n do begin        {once for each spoked triangle}
    xp_p := xp_p^.next_p;              {to xsec point for third vertex in triangle}
    make_vert_coor (tp, xp_p^, d2b_p^); {make coordinate for third vertex}
    if flip
      then begin                       {triangle is flipped over}
        rend_prim.tri_3d^ (v1a_p^, v2b_p^, v2a_p^, gnorm);
        end
      else begin                       {triangle is not flipped}
        rend_prim.tri_3d^ (v1a_p^, v2a_p^, v2b_p^, gnorm);
        end
      ;

    ptr := v2b_p;                      {swap triangle second and third verticies}
    v2b_p := v2a_p;
    v2a_p := ptr;

    ptr := d2b_p;
    d2b_p := d2a_p;
    d2a_p := ptr;
    end;                               {back and do next spoked triangle}
  end;                                 {end of FLAT endcap style case}
{
*   Illegal or unimplemented end cap style.
}
otherwise
    sys_msg_parm_int (msg_parm[1], ord(style));
    rend_message_bomb ('rend', 'rend_tube_endcap_style_bad', msg_parm, 1);
    end;                               {end of endcap style cases}
  end;
{
**********************************
*
*   Start of main routine.
}
begin
{
*   Create and wire up our own set of 3D vertex descriptors.  It is required
*   that the COOR field be enabled.  We will use the NORM and VCACHE fields
*   if enabled.  The NORM_P fields in the vertex descriptors will not be
*   set here, since they are reset every time a new shading normal is calculated.
}
  version_invalid := rend_cache_version - 1; {cache version ID to indicate invalid}

  d1a_p := addr(v1a_data);             {init pointer to direct vertex data}
  d1b_p := addr(v1b_data);
  d2a_p := addr(v2a_data);
  d2b_p := addr(v2b_data);

  sys_mem_alloc (rend_vert3d_bytes*4, vmem_p); {alloc mem for 3D vert descriptors}
  v1a_p := vmem_p;                     {set pointers to vertex descriptors}
  v1b_p := univ_ptr(
    sys_int_adr_t(v1a_p) + rend_vert3d_bytes);
  v2a_p := univ_ptr(
    sys_int_adr_t(v1b_p) + rend_vert3d_bytes);
  v2b_p := univ_ptr(
    sys_int_adr_t(v2a_p) + rend_vert3d_bytes);

  v1a_p^[rend_coor_p_ind].coor_p := addr(v1a_data.coor); {set coordinate pointers}
  v1b_p^[rend_coor_p_ind].coor_p := addr(v1b_data.coor);
  v2a_p^[rend_coor_p_ind].coor_p := addr(v2a_data.coor);
  v2b_p^[rend_coor_p_ind].coor_p := addr(v2b_data.coor);

  if rend_vcache_p_ind >= 0 then begin {vertex caches enabled ?}
    v1a_p^[rend_vcache_p_ind].vcache_p := addr(v1a_data.vcache); {set pointers}
    v1b_p^[rend_vcache_p_ind].vcache_p := addr(v1b_data.vcache);
    v2a_p^[rend_vcache_p_ind].vcache_p := addr(v2a_data.vcache);
    v2b_p^[rend_vcache_p_ind].vcache_p := addr(v2b_data.vcache);
    end;

  if rend_diff_p_ind >= 0 then begin   {explicit diffuse color enabled ?}
    v1a_p^[rend_diff_p_ind].diff_p := p1.rgba_p;
    v1b_p^[rend_diff_p_ind].diff_p := p1.rgba_p;
    v2a_p^[rend_diff_p_ind].diff_p := p2.rgba_p;
    v2b_p^[rend_diff_p_ind].diff_p := p2.rgba_p;
    end;

  if rend_tmapi_p_ind >= 0 then begin  {texture mapping indicies enabled ?}
    v1a_p^[rend_tmapi_p_ind].tmapi_p := nil;
    v1b_p^[rend_tmapi_p_ind].tmapi_p := nil;
    v2a_p^[rend_tmapi_p_ind].tmapi_p := nil;
    v2b_p^[rend_tmapi_p_ind].tmapi_p := nil;
    end;

  if rend_ncache_p_ind >= 0 then begin {normal vector cache enabled ?}
    v1a_p^[rend_ncache_p_ind].ncache_p := nil;
    v1b_p^[rend_ncache_p_ind].ncache_p := nil;
    v2a_p^[rend_ncache_p_ind].ncache_p := nil;
    v2b_p^[rend_ncache_p_ind].ncache_p := nil;
    end;

  if rend_spokes_p_ind >= 0 then begin {spokes list enabled ?}
    v1a_p^[rend_spokes_p_ind].spokes_p := nil;
    v1b_p^[rend_spokes_p_ind].spokes_p := nil;
    v2a_p^[rend_spokes_p_ind].spokes_p := nil;
    v2b_p^[rend_spokes_p_ind].spokes_p := nil;
    end;
{
*   Vertex descriptors are all set up.
*   Now set up the state for the first point in each crossection.  The current
*   patch to draw spans between end 1 and end 2 of the segment, and point "a"
*   and point "b" of the crossections.  Each time around the loop later, the
*   old crossection B points become the new A points, and then new B points
*   are calculated.  Therefore we will init the starting B points here.
}
  if p1.xsec_p = nil
    then xsec1_p := rend_xsec_curr_p   {default to current crossection for end 1}
    else xsec1_p := p1.xsec_p;         {use explicit crossection for end 1}
  if p2.xsec_p = nil
    then xsec2_p := rend_xsec_curr_p   {default to current crossection for end 2}
    else xsec2_p := p2.xsec_p;         {use explicit crossection for end 2}
  if xsec1_p^.n <> xsec2_p^.n then begin {both crossections not same size ?}
    rend_message_bomb ('rend', 'rend_xsec_npoints_not_match', nil, 0);
    end;

  x1b_p := xsec1_p^.first_p;           {init pointer to current crossection points}
  x2b_p := xsec2_p^.first_p;

  make_vert_coor (p1, x1b_p^, d1b_p^); {fill in coordinate for vertex 1B}
  make_vert_coor (p2, x2b_p^, d2b_p^); {fill in coordinate for vertex 2B}

  if rend_xsecpnt_flag_smooth_k in x1b_p^.flags then begin {will re-use shnorm 1 ?}
    make_vert_shnorm (p1, x1b_p^, true, d2b_p^.coor, v1b_p^, d1b_p^);
    end;
  if rend_xsecpnt_flag_smooth_k in x2b_p^.flags then begin {will re-use shnorm 2 ?}
    make_vert_shnorm (p2, x2b_p^, true, d1b_p^.coor, v2b_p^, d2b_p^);
    end;

  if rend_xsec_flag_conn_k in xsec1_p^.flags
    then begin                         {last point IS connected back to first point}
      n_sides := xsec1_p^.n;
      end
    else begin                         {last point is NOT connected back to first}
      n_sides := xsec1_p^.n - 1;
      end
    ;
{
*   Loop back here for each new point in the crossections.
}
  for i := 1 to n_sides do begin       {once for each face to draw}
    x1a_p := x1b_p;                    {promote pointers to xsec points}
    x2a_p := x2b_p;

    x1b_p := x1a_p^.next_p;            {get new B crossection pointers}
    x2b_p := x2a_p^.next_p;

    ptr := v1a_p;                      {swap end 1 vertex pointers}
    v1a_p := v1b_p;
    v1b_p := ptr;

    ptr := d1a_p;                      {swap pointer to vertex data for end 1}
    d1a_p := d1b_p;
    d1b_p := ptr;

    ptr := v2a_p;                      {swap end 2 vertex pointers}
    v2a_p := v2b_p;
    v2b_p := ptr;

    ptr := d2a_p;                      {swap pointer to vertex data for end 2}
    d2a_p := d2b_p;
    d2b_p := ptr;

    make_vert_coor (p1, x1b_p^, d1b_p^); {fill in coordinate for new vertex 1B}
    make_vert_coor (p2, x2b_p^, d2b_p^); {fill in coordinate for new vertex 2B}

    if not (rend_xsecpnt_flag_smooth_k in x1a_p^.flags) then begin {redo shnorm 1A?}
      make_vert_shnorm (p1, x1a_p^, false, d2a_p^.coor, v1a_p^, d1a_p^);
      end;
    if not (rend_xsecpnt_flag_smooth_k in x1b_p^.flags) then begin {redo shnorm 2A?}
      make_vert_shnorm (p2, x2a_p^, false, d1a_p^.coor, v2a_p^, d2a_p^);
      end;

    make_vert_shnorm (p1, x1b_p^, true, d2b_p^.coor, v1b_p^, d1b_p^); {make shade norms}
    make_vert_shnorm (p2, x2b_p^, true, d1b_p^.coor, v2b_p^, d2b_p^);

    if not p1.rad0 then begin          {end 1 not collapsed to a point ?}
      v1.x := d2a_p^.coor.x - d1a_p^.coor.x; {make triangle edge vectors}
      v1.y := d2a_p^.coor.y - d1a_p^.coor.y;
      v1.z := d2a_p^.coor.z - d1a_p^.coor.z;

      v2.x := d1b_p^.coor.x - d1a_p^.coor.x;
      v2.y := d1b_p^.coor.y - d1a_p^.coor.y;
      v2.z := d1b_p^.coor.z - d1a_p^.coor.z;

      gnorm.x := (v1.y * v2.z) - (v1.z * v2.y); {make geometric normal vector}
      gnorm.y := (v1.z * v2.x) - (v1.x * v2.z);
      gnorm.z := (v1.x * v2.y) - (v1.y * v2.x);

      rend_prim.tri_3d^ (v1a_p^, v2a_p^, v1b_p^, gnorm); {draw first half of face}
      end;

    if not p2.rad0 then begin          {end 2 not collapsed to a point ?}
      v1.x := d1b_p^.coor.x - d2b_p^.coor.x; {make triangle edge vectors}
      v1.y := d1b_p^.coor.y - d2b_p^.coor.y;
      v1.z := d1b_p^.coor.z - d2b_p^.coor.z;

      v2.x := d2a_p^.coor.x - d2b_p^.coor.x;
      v2.y := d2a_p^.coor.y - d2b_p^.coor.y;
      v2.z := d2a_p^.coor.z - d2b_p^.coor.z;

      gnorm.x := (v1.y * v2.z) - (v1.z * v2.y); {make geometric normal vector}
      gnorm.y := (v1.z * v2.x) - (v1.x * v2.z);
      gnorm.z := (v1.x * v2.y) - (v1.y * v2.x);

      rend_prim.tri_3d^ (v2b_p^, v1b_p^, v2a_p^, gnorm); {draw second half of face}
      end;
    end;                               {back and draw next face in this tube segment}
{
*   Done drawing the radial surface of this segment.
*   Now draw the end caps.
}
  draw_cap (cap_start, p1, xsec1_p^, false); {draw cap at end 1}
  draw_cap (cap_end, p2, xsec2_p^, true); {draw cap at end 2}
  sys_mem_dealloc (vmem_p);            {deallocate our dynamic memory}
  end;
