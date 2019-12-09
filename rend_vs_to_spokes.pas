{   Subroutine REND_VS_TO_SPOKES (V_LIST, N_V, VERT, SPOKES_P)
*
*   Create the spokes list from the Vs list in V_LIST.  N_V is the number of Vs in
*   the Vs list.  VERT is the vertex descriptor for the "center" vertex for all the
*   Vs.  The memory for the spokes list will be dynamically allocated, and
*   SPOKES_P will be returned pointing to the start of the dynamically allocated
*   region.
}
module rend_vs_to_spokes;
define rend_vs_to_spokes;
%include 'rend2.ins.pas';

procedure rend_vs_to_spokes (          {compute vert spokes list from list of Vs}
  in      v_list: univ rend_v_list_t;  {list of Vs in any order}
  in      n_v: sys_int_machine_t;      {number of Vs in V list}
  in      vert: univ rend_vert3d_t;    {center vertex for all the Vs}
  out     spokes_sets_p: rend_spokes_lists_p_t); {spokes sets list is dyn allocated}
  val_param;

type
  v_p_t =                              {pointer to internal V descriptor}
    ^v_t;

  v_t = record                         {local data about each V}
    v1_p, v2_p: rend_vert3d_p_t;       {vertex spoke pointers after flipping}
    norm: vect_3d_t;                   {unit normal vector}
    last_p: v_p_t;                     {point to previous V in shading chain}
    next_p: v_p_t;                     {point to next V in shading chain}
    flip: boolean;                     {TRUE if spokes order was flipped}
    flip_set: boolean;                 {TRUE if flip sense has be alread determined}
    null_vect: boolean;                {TRUE if cross product was null vector}
    next_set: boolean;                 {TRUE if NEXT_P field set}
    end;

  v_ar_t =                             {local array of data for each V}
    array[1..1] of v_t;

  v_ar_p_t =                           {pointer to local array of data for each V}
    ^v_ar_t;

var
  v_ar_p: v_ar_p_t;                    {point to dynamically allocated local data}
  i, j: sys_int_machine_t;             {scratch integers and loop counters}
  mask: sys_int_machine_t;             {mask for selecting flip array bit}
  coor: vect_3d_t;                     {local copy of center coordinate for each V}
  vect1, vect2: vect_3d_t;             {first and second vectors used for cross prod}
  m: real;                             {scratch mult factor}
  ss_p: rend_spokes_p_t;               {points to start of max size spokes lists}
  spokes_p: rend_spokes_p_t;           {points to temp current spokes list}
  spokes2_p: rend_spokes_p_t;          {points to final current spokes list}
  flip_ar_p: rend_spokes_flip_ar_p_t;  {points to current spokes flip array}
  n_spokes_lists: sys_int_machine_t;   {number of spokes lists formed}
  n_spokes: sys_int_machine_t;         {number of spokes in current list}
  n_vs: sys_int_machine_t;             {number of Vs in current spokes list}
  start_v_p: v_p_t;                    {pointer to starting vertex in chain}
  v_p: v_p_t;                          {pointer to current V}
  spokes_bytes: sys_int_machine_t;     {bytes needed for all spokes lists}
  spoke: sys_int_machine_t;            {value of internal spoke "pointer"}
  nv: sys_int_machine_t;               {local copy of N_V to work around compiler bug}
{
********************************************************************************
*
*   Local subroutine FIND_NEXT (V)
*
*   Find the next V array entries in the chain starting a V entry V.  The entire
*   chain will be followed.  Each entry in the chain will have its NEXT_P, NEXT_SET,
*   and FLIP_SET fields set.
}
procedure find_next (
  in out  v: v_t);                     {starting V descriptor}

var
  i: sys_int_machine_t;                {loop counter}
  v_p: rend_vert3d_p_t;                {scratch V pointer for flipping V2}
  dot: real;                           {dot product of unit normal vectors}
  flip: boolean;                       {TRUE if would need to flip other V}
  flip_succ: boolean;                  {TRUE if need to flip current successor V}

begin
  if v.next_set then return;           {this chain already done ?}
  if v.null_vect then return;          {can't chain anything to a null vector}
  v.next_set := true;                  {NEXT_P will be set before routine exit}
  v.flip_set := true;                  {our flip state now frozen if not already}
  for i := 1 to nv do begin            {once for all other Vs in list}
    with v_ar_p^[i]: v2 do begin       {V2 is abbrev for "second" V descriptor}
    if addr(v2) = addr(v) then next;   {can't follow self}
    if v2.last_p <> nil then next;     {already has a predecessor ?}
    if v2.null_vect then next;         {don't add null vector to chain}
    if v2.flip_set
      then begin                       {second V can't be flipped any more}
        if v.v2_p <> v2.v1_p then next; {V2 not follow V ?}
        flip := false;
        end
      else begin                       {second V could still be flipped}
        if v.v2_p = v2.v1_p
          then begin                   {V2 might follow, unflipped}
            flip := false;
            end
          else if v.v2_p = v2.v2_p then begin {V2 might follow, flipped}
            flip := true;
            end
          else next                    {V2 does not follow V}
          ;
        end                            {done with V2 could still be flipped}
      ;                                {V2 is connected and FLIP is determined}
    dot :=                             {make cosine between the two normal vectors}
      v.norm.x * v2.norm.x +
      v.norm.y * v2.norm.y +
      v.norm.z * v2.norm.z;
    if flip then dot := -dot;          {correct for flipped normal}
    if dot < rend_break_cos then next; {angle too great, V2 not connected ?}
{
*   V2 definately follows V.  FLIP indicates whether V2 needs to be flipped around
*   before being added to the chain.
}
    if v.next_p <> nil then begin      {a previous vert looked like next in chain ?}
      v.next_p := nil;                 {too ambiguous, stop chain here}
      return;
      end;
    flip_succ := flip;                 {remeber flip state for this successor}
    v.next_p := addr(v2);              {link V2 onto chain as successor}
    end;                               {done with V2 abbreviation}
    end;                               {back to test new successor V}
  if v.next_p <> nil then begin        {we did find a successor ?}
    with v.next_p^: sv do begin        {SV is successor vertex}
      if flip_succ then begin          {flip successor V around ?}
        v_p := sv.v1_p;                {flip the first and second spoke pointers}
        sv.v1_p := sv.v2_p;
        sv.v2_p := v_p;
        sv.norm.x := -sv.norm.x;       {flip unit normal vector}
        sv.norm.y := -sv.norm.y;
        sv.norm.z := -sv.norm.z;
        end;
      sv.flip := flip_succ;            {indicate this V's flipped state}
      sv.flip_set := true;             {freeze successor's flip state}
      sv.last_p := addr(v);            {set successor's previous chain link pointer}
      find_next (sv);                  {set chain for successor V}
      end;                             {done with SV abbreviation}
    end;                               {done handling that a successor was found}
  end;
{
*******************************************************************************
*
*   Start main routine.
}
begin
{
*   Work around compiler bug.  Local subroutines can't see the proper values for the
*   call arguments of the main routine.
}
  nv := n_v;                           {make copy for local subroutines}

  if rend_coor_p_ind < 0 then begin
    writeln ('3D vertex COOR_P feature not enabled in REND_VS_TO_SPOKES.');
    sys_bomb;
    end;
  if vert[rend_coor_p_ind].coor_p = nil then begin
    writeln ('NIL 3D coordinate pointer in VERT argument (REND_VS_TO_SPOKES).');
    sys_bomb;
    end;
  coor.x := vert[rend_coor_p_ind].coor_p^.x; {make local copy of center coordinate}
  coor.y := vert[rend_coor_p_ind].coor_p^.y;
  coor.z := vert[rend_coor_p_ind].coor_p^.z;

  sys_mem_alloc (n_v*sizeof(v_t), v_ar_p); {get mem for local data about each V}
  if v_ar_p = nil then begin
    writeln ('Unable to allocate dynamic memory in REND_VS_TO_SPOKES.');
    writeln ('The disk is probably full.');
    sys_bomb;
    end;
{
*   An array has been allocated with an entry for each V in the input list.
*   Each array entry holds much more data than is available directly from the input
*   list.  Now initialize as many fields as possible in the local array entries
*   without knowing the topological connections.
}
  for i := 1 to n_v do begin           {once for each V}
    with v_ar_p^[i]: v do begin        {V stands for this local V array entry}
      v.v1_p := v_list[i].v1_p;        {copy pointers to spoke vertex descriptors}
      v.v2_p := v_list[i].v2_p;
      vect1.x := v.v2_p^[rend_coor_p_ind].coor_p^.x - coor.x; {first cross prod vect}
      vect1.y := v.v2_p^[rend_coor_p_ind].coor_p^.y - coor.y;
      vect1.z := v.v2_p^[rend_coor_p_ind].coor_p^.z - coor.z;
      vect2.x := v.v1_p^[rend_coor_p_ind].coor_p^.x - coor.x; {second cross prod vect}
      vect2.y := v.v1_p^[rend_coor_p_ind].coor_p^.y - coor.y;
      vect2.z := v.v1_p^[rend_coor_p_ind].coor_p^.z - coor.z;
      v.norm.x := vect1.y*vect2.z - vect1.z*vect2.y; {make cross product}
      v.norm.y := vect1.z*vect2.x - vect1.x*vect2.z;
      v.norm.z := vect1.x*vect2.y - vect1.y*vect2.x;
      m :=                             {square of cross product magnitude}
        sqr(v.norm.x) + sqr(v.norm.y) + sqr(v.norm.z);
      if m < 1.0E-30                   {check size of cross product vector}
        then begin                     {cross product too small, no normal exists}
          v.null_vect := true;         {indicate unit normal is not valid}
          end
        else begin                     {cross prod big enough, normal exists here}
          m := 1.0 / sqrt(m);          {mult factor to make unit normal vector}
          v.norm.x := v.norm.x * m;    {make unit normal vector}
          v.norm.y := v.norm.y * m;
          v.norm.z := v.norm.z * m;
          v.null_vect := false;        {indicate unit normal vector is valid}
          end
        ;
      v.last_p := nil;                 {init to this is first of smooth V set}
      v.next_p := nil;                 {init to this is end of smooth V set}
      v.flip := false;                 {init to this V not have normal flipped}
      v.flip_set := false;             {init to flip sense not determined yet}
      v.next_set := false;             {init to NEXT_P not set}
      end;                             {done with V abbreviation}
    end;                               {back and init next V in array}
{
*   The unit normal vectors have been found for each V.  Now loop thru each V and
*   determine which other V, if any, follows it in a set of Vs used to compute the
*   shading normals.  If it appears that more than one V follows, then declare a
*   hard break, since this should not happen topologically.
}
  for i := 1 to n_v do begin           {once for each V to set NEXT_P field in}
    find_next (v_ar_p^[i]);            {set NEXT_P and FLIP fields in V entry}
    end;                               {back and do next V in array}

  sys_mem_alloc (                      {grab memory for worst case spokes lists}
    n_v*(sizeof(rend_spokes_t)+sizeof(rend_spokes_ent_t)), {bytes to grab}
    ss_p);                             {points to start of temp spokes lists}
  if ss_p = nil then begin
    writeln ('Unable to allocate dynamic memory in REND_VS_TO_SPOKES.');
    writeln ('The disk is probably full.');
    sys_bomb;
    end;
  spokes_p := ss_p;                    {init pointer to current spokes list}
  n_spokes_lists := 0;                 {init number of spokes lists found so far}
  spokes_bytes := 0;                   {init number of bytes needed for all lists}

  for i := 1 to n_v do begin           {once for each potential chain}
    start_v_p := addr(v_ar_p^[i]);     {init start of current chain}
    if not start_v_p^.next_set         {already got here from a previous chain ?}
      then next;
    if start_v_p^.null_vect            {ignore Vs with no normal vectors}
      then next;
    while start_v_p^.last_p <> nil do begin {keep looping to look for start of chain}
      if start_v_p^.last_p = addr(v_ar_p^[i]) {got all the way back to start ?}
        then exit;
      start_v_p := start_v_p^.last_p;  {point to previous V entry}
      end;                             {back to keep looking for start of chain}
    n_spokes := 0;                     {init number of spokes in current list}
    spokes_p^.loop := true;            {init to spokes list is a loop of Vs}
    n_vs := 0;                         {init number of Vs in this spokes list}
    v_p := start_v_p;                  {init current V to start of this chain}
    repeat                             {once for each V in this chain}
      j := sys_int_adr_t(v_p^.v1_p);   {init raw spoke address value}
      if v_p^.flip                     {add in flip flag}
        then j := j ! 1;               {1 means this V was flipped}
      spokes_p^.vert_p_ar[n_spokes].spoke_p := {spoke pnt with flip flag in low bit}
        univ_ptr(j);
      n_spokes := n_spokes + 1;        {one more spoke in this list}
      n_vs := n_vs + 1;                {we processed one more V to make spokes list}
      v_p^.next_set := false;          {prevent from using this V twice}
      if v_p^.next_p = nil then begin  {hit end of chain with hard break ?}
        spokes_p^.vert_p_ar[n_spokes].spoke_p := {set pointer to last spoke}
          v_p^.v2_p;                   {no flip bit exists here}
        n_spokes := n_spokes + 1;      {count this last spoke}
        spokes_p^.loop := false;       {this spokes list is not a loop}
        exit;                          {done following this chain}
        end;
      v_p := v_p^.next_p;              {advance to next V in this chain}
      until v_p = start_v_p;           {stop when got all the way back to start V}
    spokes_p^.max_ind := n_spokes - 1; {set max VERT_P_AR array index for this list}
    n_spokes_lists := n_spokes_lists + 1; {one more spokes lists}
    spokes_bytes := spokes_bytes +     {add in bytes needed for this spokes list}
      sizeof(rend_spokes_t) +          {spokes list header plus one spoke pointer}
      (n_spokes-1)*sizeof(rend_spokes_ent_t) + {bytes for remaining spokes pointers}
      sizeof(rend_spokes_flip_bits_word_t)*((n_vs+31) div 32); {bytes for flip flags}
    spokes_p := univ_ptr(              {start new spokes list right after this one}
      addr(spokes_p^.vert_p_ar[n_spokes]));
    end;                               {back and test next V for unused chain}

  spokes_bytes := spokes_bytes +       {add in header for whole spokes lists}
    sizeof(rend_spokes_lists_t) - sizeof(rend_spokes_t);
{
*   The spokes list in the temporary buffer are all set.  We now know that the
*   final spokes list will take SPOKES_BYTES number of bytes.  Now allocate the
*   final spokes list and copy into it from the temporary one.  The temporary list
*   has the flip bits stored in the low bit of each pointer.  In the final list,
*   they will be stored in their own array of one bit pointers.
}
  sys_mem_dealloc (v_ar_p);            {no longer need temporary V array}
  sys_mem_alloc (spokes_bytes, spokes_sets_p); {allocate final spokes lists memory}
  if spokes_sets_p = nil then begin
    writeln ('Unable to allocate dynamic memory in REND_VS_TO_SPOKES.');
    writeln ('The disk is probably full.');
    sys_bomb;
    end;
  spokes_sets_p^.n := n_spokes_lists;  {set number of individual spokes lists}
  spokes_p := ss_p;                    {init curr source pointer to start of lists}
  spokes2_p := addr(spokes_sets_p^.first_set); {init current destination spokes list}

  for i := 1 to n_spokes_lists do begin {once for each separate spokes list}
    if spokes_p^.loop                  {set how many flip bits used here}
      then n_vs := spokes_p^.max_ind + 1
      else n_vs := spokes_p^.max_ind;
    flip_ar_p := univ_ptr(             {make adr of start of flip bits array}
      addr(spokes2_p^.vert_p_ar[spokes_p^.max_ind+1]));
    spokes2_p^ := spokes_p^;           {copy all the header stuff for this list}
    for j := 0 to rshft(n_vs-1, 5) do begin {once for each flip bits word}
      flip_ar_p^[j] := 0;              {init this word of flip bits to zero}
      end;
    for j := 0 to spokes_p^.max_ind do begin {once for each spoke in list}
      spoke := sys_int_adr_t(spokes_p^.vert_p_ar[j].spoke_p); {get "pointer" value}
      spokes2_p^.vert_p_ar[j].spoke_p := univ_ptr( {set spoke pointer in final list}
        spoke & 16#FFFFFFFC);          {mask off flip bit value}
      spokes2_p^.vert_p_ar[j].cent_p := nil; {init to center vert not set yet}
      if (j <> spokes_p^.max_ind) or (spokes_p^.loop) then begin {flip bit exists ?}
        mask := lshft(1, j & 31);      {make mask for this flip array bit}
        if (spoke & 1) = 0
          then begin                   {flip bit is 0}
            flip_ar_p^[rshft(j, 5)] := {disable this flip bit}
              flip_ar_p^[rshft(j, 5)] & (~mask);
            end
          else begin                   {flip bit is 1}
            flip_ar_p^[rshft(j, 5)] := {enable this flip bit}
              flip_ar_p^[rshft(j, 5)] ! mask;
            end
          ;
        end;
      end;                             {back and process next spoke pointer}
    spokes_p := univ_ptr(              {point to start of next source spoke list}
      addr(spokes_p^.vert_p_ar[spokes_p^.max_ind+1]));
    spokes2_p := univ_ptr(             {point to start of next dest spokes list}
      addr(flip_ar_p^[rshft(n_vs+31, 5)]));
    end;                               {back and do next whole spokes list}

  sys_mem_dealloc (ss_p);              {deallocate temp spokes lists buffer}
  end;
