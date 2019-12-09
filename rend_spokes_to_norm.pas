{   Subroutine REND_SPOKES_TO_NORM (VERT, UNITIZE, SHADE_NORM)
*
*   Process the spokes list for the vertex VERT, and return the resulting shading
*   normal vector SHADE_NORM.  SHADE_NORM and the normal vectors written into the
*   caches may not be of unit length unless UNITIZE is TRUE.  It will be assumed
*   that the COOR_P and SPOKES_P fields in the vertex descriptor are turned
*   on and have been set to valid values.  No checks will be made for NIL pointer
*   values, etc.  The resulting shading normal vector will be saved in the normal
*   vector caches of all verticies on this spokes list if the NCACHE_P feature
*   is turned on, and that have valid NCACHE_P pointers.
}
module rend_spokes_to_norm;
define rend_spokes_to_norm;
%include 'rend2.ins.pas';

procedure rend_spokes_to_norm (        {compute shading normal from vert spokes list}
  in      vert: univ rend_vert3d_t;    {vertex descriptor where want shading normal}
  in      unitize: boolean;            {resulting normals will be unitized if TRUE}
  out     shade_norm: vect_3d_t);      {returned non-unit shading normal vector}
  val_param;

const
  max_num_vs = 100;                    {maximum number of Vs allowed in spoke list}

  max_v_ind = max_num_vs - 1;          {max V array index}

type
  v_ent_p_t =                          {pointer to a V descriptor}
    ^v_ent_t;

  v_ent_t = record                     {descriptor for a V}
    valid: boolean;                    {TRUE if valid unit normal found here}
    break_after: boolean;              {TRUE if break right after this V}
    flip: boolean;                     {TURE if flip normal before passing back}
    next_p: v_ent_p_t;                 {points to next V in list}
    vert_p: rend_vert3d_p_t;           {pointer to parent vertex for this V}
    case integer of
      1:(                              {active fields before unit normal computed}
        coor2_p: vect_3d_fp1_p_t);     {points to coordinate on second spoke of V}
      2:(
        norm: vect_3d_t);              {unit normal vector}
    end;

var
  n_vs: sys_int_machine_t;             {number of Vs indicated by spokes list}
  max_v: sys_int_machine_t;            {largest used V array index}
  i: sys_int_machine_t;                {loop counter}
  vect1: vect_3d_t;                    {vector to first spoke of V}
  vect2: vect_3d_t;                    {vector to second spoke of V}
  m: real;                             {scratch real number}
  first_group_start_p: v_ent_p_t;      {pointer to start of first V entries group}
  group_start_p: v_ent_p_t;            {pointer to start of curr V entries group}
  group_end_p: v_ent_p_t;              {pointer to end of curr V entries group}
  norm_acc: vect_3d_t;                 {average normal vector accumulator}
  neg_norm: vect_3d_t;                 {negative of final shading normal}
  flip_ar_p: rend_spokes_flip_ar_p_t;  {array of 1 bit flip flags}
  ncache_flags: rend_ncache_flags_t;   {combined flag fields of normal vect caches}
  found_break: boolean;                {TRUE if at least one break in spokes list}
  prev_break: boolean;                 {previous V had break after it}
  v:                                   {local per-V data}
    array[0..max_v_ind] of v_ent_t;

label
  no_break, break, group_loop, v_loop, stuff_loop, done_groups;

begin
  ncache_flags.all := 0;               {clear any unused bits in flags word}
  if unitize
    then ncache_flags.unitized := 1
    else ncache_flags.unitized := 0;
  ncache_flags.version := rend_ncache_flags.version;

  with                                 {set up abbreviations}
    vert[rend_spokes_p_ind].spokes_p^: spokes,
    vert[rend_spokes_p_ind].spokes_p^.vert_p_ar: v_p_ar,
    vert[rend_coor_p_ind].coor_p^: coor
    do begin
{
*   The following abbreviations are in effect:
*
*   SPOKES
*     The whole spokes data structure pointed to directly from the vertex
*     descriptor, VERT.
*
*   V_P_AR
*     The spokes array.  Each array entry points to two vertex descriptors, called
*     SPOKE_P and CENT_P.  The vertex descriptor at SPOKE_P points to the vertex
*     at the other end of that spoke.  CENT_P points to the vertex that is the center
*     of the V between this spoke and the next one.  The spokes are in adjacent
*     order along the array.
*
*   COOR
*     XYZ coordinate of this vertex.
}
  flip_ar_p :=                         {make adr of flip flags array}
    univ_ptr(addr(v_p_ar[spokes.max_ind+1]));
  if spokes.loop                       {find how many Vs are indicated by spokes list}
    then n_vs := spokes.max_ind + 1
    else n_vs := spokes.max_ind;
  max_v := n_vs - 1;                   {make max used NORM array index}
  if max_v > max_v_ind then begin
    writeln ('Too many Vs encountered in REND_SPOKES_TO_NORM.');
    sys_bomb;
    end;
{
*   Fill in the COOR2_P field in each V descriptor.  COOR2_P points to a coordinate
*   along the second spoke forming the V.  The COOR2_P fields are all filled in first
*   before the normal vectors are computed.  This is done in two passes because
*   figuring out which Vs live where is a bit more tricky and requires some redundant
*   code.  Therefore this is only performed on the much simpler operation of storing
*   the pointers.  The control for the loop to calculate the cross products then
*   becomes very simple, not requiring any redundant code.
}
  for i := 0 to spokes.max_ind-1 do begin {all Vs except last-to-first}
    v[i].coor2_p :=                    {pointer to coordinate on second spoke of V}
      v_p_ar[i+1].spoke_p^[rend_coor_p_ind].coor_p;
    v[i].next_p := addr(v[i+1]);       {pointer to next V in sequence}
    v[i].vert_p := v_p_ar[i].cent_p;   {pointer to main vertex for this V}
    v[i].flip :=
      (flip_ar_p^[rshft(i, 5)] & lshft(1, i & 31)) <> 0;
    end;
  if spokes.loop                       {first and last Vs connected ?}
    then begin                         {first V directly follows last V}
      v[max_v].coor2_p :=
        v_p_ar[0].spoke_p^[rend_coor_p_ind].coor_p;
      v[max_v].next_p := addr(v[0]);
      v[max_v].vert_p := v_p_ar[max_v].cent_p;
      v[max_v].flip :=
        (flip_ar_p^[rshft(max_v, 5)] & lshft(1, max_v & 31)) <> 0;
      end
    else begin                         {first and last Vs are not connected}
      v[max_v].next_p := nil;
      end
    ;
{
*   Calculate the unit normal vector for each V.
}
  vect2.x := v_p_ar[0].spoke_p^[rend_coor_p_ind].coor_p^.x - coor.x;
  vect2.y := v_p_ar[0].spoke_p^[rend_coor_p_ind].coor_p^.y - coor.y;
  vect2.z := v_p_ar[0].spoke_p^[rend_coor_p_ind].coor_p^.z - coor.z;
  for i := 0 to max_v do begin         {once for each V}
    with v[i].norm: norm do begin      {NORM is abbrev for normal vector in V entry}
      vect1 := vect2;                  {old second spoke becomes new first spoke}
      vect2.x := v[i].coor2_p^.x - coor.x; {make second spoke vector for this V}
      vect2.y := v[i].coor2_p^.y - coor.y;
      vect2.z := v[i].coor2_p^.z - coor.z;
      norm.x := vect2.y*vect1.z - vect2.z*vect1.y; {raw cross product}
      norm.y := vect2.z*vect1.x - vect2.x*vect1.z;
      norm.z := vect2.x*vect1.y - vect2.y*vect1.x;
      m :=                             {squared magnitude of cross product}
        sqr(norm.x) + sqr(norm.y) + sqr(norm.z);
      if m < 1.0E-30
        then begin                     {vector magnitude is too small to unitize}
          v[i].valid := false;         {indicate there is no normal vector here}
          end
        else begin                     {vector magnitude OK, make unit normal}
          m := 1.0 / sqrt(m);          {make mult factor for unitizing vector length}
          norm.x := norm.x * m;        {make unit normal vector for this V entry}
          norm.y := norm.y * m;
          norm.z := norm.z * m;
          v[i].valid := true;          {indicate that a valid normal exists here}
          end
        ;
      end;                             {done with NORM abbreviation}
    end;                               {back and process next V}
{
*   The V array entries are all set.  For each V, if the VALID field is TRUE,
*   the unit normal vector is in the NORM field.  If the VALID field is false,
*   then no unit normal exists for that V, meaning that the V had no area.
*
*   Now loop thru the V list and look for breaks.  Breaks occur when the unit
*   normal vectors for adjacent Vs have too great an angle between them.  This
*   is measured by comparing their dot product to the preset threshold value in
*   REND_BREAK_COS.
}
  first_group_start_p := addr(v[0]);   {init start of first continuous group}
  found_break := false;                {init to no breaks found}
  prev_break := false;                 {init to previous V had no break after it}
  for i := 0 to max_v do begin         {once for each V}
    if prev_break then begin           {previous V had break directly after it ?}
      first_group_start_p := addr(v[i]); {this must be start of a new group}
      end;
    if v[i].next_p = nil               {not connected to any next V ?}
      then goto break;
    if not v[i].valid                  {no normal vector exists here ?}
      then goto no_break;
    m :=                               {dot product between this and next V normal}
      (v[i].norm.x * v[i].next_p^.norm.x) +
      (v[i].norm.y * v[i].next_p^.norm.y) +
      (v[i].norm.z * v[i].next_p^.norm.z);
    if m < rend_break_cos then goto break; {angles too far apart ?}
no_break:                              {jump here if no break after this V}
    v[i].break_after := false;         {set flags to indicate no break here}
    prev_break := false;               {remember no break following for next V}
    next;                              {back and process next V}
break:                                 {jump here if definately break after this V}
    v[i].break_after := true;          {set flags to indicate break here}
    prev_break := true;                {remember break follows here for next V}
    found_break := true;               {flag that at least one break found}
    end;                               {back and process next V}
  v[max_v].next_p := addr(v[0]);       {fix pointers now that break flags all set}
  if not found_break then begin        {no breaks in whole spokes V list}
    v[max_v].break_after := true;      {create artificial break after last V entry}
    end;
{
*   All the breaks have been found and flagged in the V array.  FIRST_GROUP_START_P
*   points to a V array entry that is the start of a group of V entries with no
*   breaks.
*
*   Now loop thru each of these groups, calculate the average normal vector, and
*   write it into all the caches of each vertex in the group.
}
  group_end_p := nil;                  {indicate this will be first time thru loop}
{
*   Loop back here once for each new continuous group of Vs without any breaks
*   in between.  The loop terminates when the end of the next group would start
*   at the start of the first group.
}
group_loop:
  if group_end_p = nil
    then begin                         {this is the first time thru the loop}
      group_start_p := first_group_start_p; {init where to start first group}
      end
    else begin                         {this is not the first group}
      if group_end_p^.next_p = first_group_start_p {back to start of first group ?}
        then goto done_groups;         {all done with all the groups}
      group_start_p := group_end_p^.next_p; {start this group right after last group}
      end
    ;
  group_end_p := group_start_p;        {init end of this new group}
  norm_acc.x := 0.0;                   {init normal vector accumulator value}
  norm_acc.y := 0.0;
  norm_acc.z := 0.0;
  n_vs := 0;                           {init number of Vs used to make shading norm}

v_loop:                                {back here each new V in this group}
  if group_end_p^.valid then begin     {normal vector valid for this V ?}
    norm_acc.x := norm_acc.x + group_end_p^.norm.x;
    norm_acc.y := norm_acc.y + group_end_p^.norm.y;
    norm_acc.z := norm_acc.z + group_end_p^.norm.z;
    n_vs := n_vs + 1;                  {one more V used to make this normal}
    end;
  if not group_end_p^.break_after then begin {not last V in this group ?}
    group_end_p := group_end_p^.next_p; {advance to next V in list}
    goto v_loop;                       {back and process new V in current group}
    end;
  if n_vs <= 0 then begin              {no normal exists for the whole group ?}
    norm_acc.x := 0.0;                 {pick an arbitrary normal vector}
    norm_acc.y := 0.0;
    norm_acc.z := 1.0;
    end;
  if unitize and (n_vs > 1) then begin {need to unitize normal vector ?}
    m := 1.0 / sqrt(                   {make scale factor for unitizing vector}
      sqr(norm_acc.x) + sqr(norm_acc.y) + sqr(norm_acc.z));
    norm_acc.x := norm_acc.x * m;
    norm_acc.y := norm_acc.y * m;
    norm_acc.z := norm_acc.z * m;
    end;
  neg_norm.x := -norm_acc.x;           {make flipped shading normal in case needed}
  neg_norm.y := -norm_acc.y;
  neg_norm.z := -norm_acc.z;
{
*   A complete group was found.  GROUP_START_P and GROUP_END_P point to the first
*   and last V array entries of the group.  NORM_ACC contains the average normal
*   to use for this group.
*
*   Now loop thru the group again and fill in all the normal vector caches with
*   this average normal vector.
}
stuff_loop:                            {back here to stuff normal vector to this vert}
  if group_start_p^.vert_p = addr(vert) then begin {this is caller's vertex ?}
    if group_start_p^.flip             {flip normal vector to make shading norm ?}
      then shade_norm := neg_norm
      else shade_norm := norm_acc;
    end;
  if group_start_p^.vert_p <> nil then begin {vertex exists to stuff norm into ?}
    with group_start_p^.vert_p^: vvert {VVERT is vertex at center of current V}
        do begin
      if  (rend_ncache_p_ind >= 0) and then
          (vvert[rend_ncache_p_ind].ncache_p <> nil) and then
          (vvert[rend_ncache_p_ind].ncache_p^.flags.all <> ncache_flags.all)
          then begin                   {we must update the norm cache for this vert}
        if group_start_p^.flip         {need to use flipped norm for shading norm ?}
          then begin
            vvert[rend_ncache_p_ind].ncache_p^.norm.x := neg_norm.x;
            vvert[rend_ncache_p_ind].ncache_p^.norm.y := neg_norm.y;
            vvert[rend_ncache_p_ind].ncache_p^.norm.z := neg_norm.z;
            end
          else begin
            vvert[rend_ncache_p_ind].ncache_p^.norm.x := norm_acc.x;
            vvert[rend_ncache_p_ind].ncache_p^.norm.y := norm_acc.y;
            vvert[rend_ncache_p_ind].ncache_p^.norm.z := norm_acc.z;
            end
          ;
        vvert[rend_ncache_p_ind].ncache_p^.flags.all := ncache_flags.all;
        end;                           {done stuffing normal vect into cache}
      end;                             {done with VVERT abbreviation}
    end;                               {done with target vertex exists}
  if group_start_p <> group_end_p then begin {not at last V in this group ?}
    group_start_p := group_start_p^.next_p; {advance to next V in this group}
    goto stuff_loop;                   {back and stuff normal for this new V}
    end;
  goto group_loop;                     {back and process next group without breaks}
done_groups:                           {jump here when done with last group}
  end;                                 {done with SPOKES, V_P_AR, and COOR abbrev}
  end;
