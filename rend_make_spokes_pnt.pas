{   Subroutine REND_MAKE_SPOKES_PNT (VERT,VERT1,VERT2,SPOKES_LISTS)
*
*   Fill in the SPOKES_P field in the vertex descriptor VERT.  The SPOKES_P feature
*   must be enabled.  SPOKES_LISTS is the data structure holding all the spokes
*   lists generated from one original V list.  SPOKES_LISTS is typically produced
*   by subroutine REND_VS_TO_SPOKES.  The SPOKES_P field will be set to point to the
*   particular spokes list within SPOKES_LISTS that applies to the given vertex.
*   If the proper list can not be found, then the NIL pointer is installed.
*   VERT1 and VERT2 are the two verticies that form a V at VERT.  These are not
*   altered, but are used to identify the correct spokes list.
}
module rend_make_spokes_pnt;
define rend_make_spokes_pnt;
%include 'rend2.ins.pas';

procedure rend_make_spokes_pnt (       {set SPOKES_P field in vertex descriptor}
  in out  vert: univ rend_vert3d_t;    {vertex descriptor in which to set SPOKES_P}
  in      vert1, vert2: univ rend_vert3d_t; {adjacent verticies to VERT}
  in      spokes_lists: univ rend_spokes_lists_t); {all the spokes lists at this coor}

var
  spokes_p: rend_spokes_p_t;           {pointer to current spokes list}
  flip_ar_p: rend_spokes_flip_ar_p_t;  {pointer to current flip flags array}
  i: sys_int_machine_t;                {loop counter}
  max_spoke: sys_int_machine_t;        {max VERT_P_AR index for current spokes list}
  n_vs: sys_int_machine_t;             {number of Vs in current spokes list}
  s1, s2: sys_int_machine_t;           {VERT_P_AR indicies for spokes of curr V}

begin
  if rend_spokes_p_ind < 0 then begin
    writeln ('SPOKES_P feature not enabled in REND_MAKE_SPOKES_PNT.');
    sys_bomb;
    end;
  spokes_p := addr(spokes_lists.first_set); {init pointer to current spokes list}

  for i := 1 to spokes_lists.n do begin {once for each spokes list}
    max_spoke := spokes_p^.max_ind;    {get array index for last spoke in list}
    flip_ar_p := univ_ptr(             {make adr for start of flip flags array}
      addr(spokes_p^.vert_p_ar[max_spoke+1]));
    if spokes_p^.loop                  {make number of Vs represented here}
      then n_vs := max_spoke + 1
      else n_vs := max_spoke;
    for s1 := 0 to n_vs-1 do begin     {once for each V in spokes list}
      s2 := s1 + 1;                    {init index for second spoke of this V}
      if s2 > max_spoke then s2 := 0;  {wrap back to first spoke in list ?}
      if
          (spokes_p^.vert_p_ar[s1].cent_p = nil) and
          ( ( (spokes_p^.vert_p_ar[s1].spoke_p = addr(vert1)) and
              (spokes_p^.vert_p_ar[s2].spoke_p = addr(vert2)))
            or
            ( (spokes_p^.vert_p_ar[s1].spoke_p = addr(vert2)) and
              (spokes_p^.vert_p_ar[s2].spoke_p = addr(vert1)))
            )
          then begin
        vert[rend_spokes_p_ind].spokes_p := spokes_p; {set spokes list pointer}
        spokes_p^.vert_p_ar[s1].cent_p := {point this V back to its center vertex}
          addr(vert);
        return;
        end;
      end;                             {back and try next V in this spokes list}
{
*   No V matched in this spokes list.  Advance to next spokes list.
}
    spokes_p := univ_ptr(              {make pointer to start of next spokes list}
      addr(flip_ar_p^[rshft(n_vs+31, 5)]));
    end;                               {back and try new spokes list}
{
*   None of the spokes list contained a suitable V.  Set the SPOKES_P field to the
*   NIL pointer.
}
  vert[rend_spokes_p_ind].spokes_p := nil;
  end;
