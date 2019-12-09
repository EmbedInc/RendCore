{   Subroutine REND_SW_VECT_PARMS (PARMS)
*
*   Set a new current set of modes and switches that control how vectors are rendered.
}
module rend_sw_vect_parms;
define rend_sw_vect_parms;
%include 'rend_sw2.ins.pas';

procedure rend_sw_vect_parms (         {set parameters and switches for VECT call}
  in      parms: rend_vect_parms_t);   {new values for the modes and switches}

const
  max_msg_parms = 2;

var
  thick_below_3d: boolean;             {TRUE if vectors thickened below 3D space}
  msg_parm:                            {message parameter references}
    array[1..max_msg_parms] of sys_parm_msg_t;
{
******************************************
*
*   Internal subroutine END_CAP (UPARMS,STATE,MULT)
*
*   Set up the internal state in STATE for the vector end cap described by user
*   parameters UPARMS.  MULT is either positive or negative, and must be applied to all
*   coordinates stored in the end cap vertex list.  A positive value will result in
*   proper coordinates for the end of the vector, and a negative value selects the
*   beginning of the vector.  A magnitude of 1.0 will scale the end caps to the proper
*   coordinates when multiplied by the WIDTH parameter.
}
procedure end_cap (
  in      uparms: rend_end_style_t;    {user parameters that describe end cap}
  out     state: rend_vectcap_t;       {internal state block for this end cap}
  in      mult: real);                 {mult factor for all vertex coordinates}

const
  pi = 3.141593;                       {what it sounds like}

var
  i: integer32;                        {loop counter}
  a: real;                             {current angle}
  da: real;                            {angle increment}

begin
  case uparms.style of                 {different code for each possible end style}

rend_end_style_rect_k: begin           {rectangular cutoff}
  state.n := 2;                        {set number of verticies in cap}
  state.vert[1].x := 1.0*mult;         {fill in the verticies}
  state.vert[1].y := -1.0*mult;
  state.vert[2].x := 1.0*mult;
  state.vert[2].y := 1.0*mult;
  end;                                 {done with rectangular end caps}

rend_end_style_circ_k: begin           {semi-circular end caps}
  if uparms.nsides > rend_max_end_nsides then begin
    rend_end;
    sys_msg_parm_int (msg_parm[1], uparms.nsides);
    sys_msg_parm_int (msg_parm[2], rend_max_end_nsides);
    sys_message_bomb ('rend', 'rend_cap_too_many_sides', msg_parm, 2);
    end;
  a := -pi/2.0;                        {starting angle}
  da := pi/uparms.nsides;              {angle increment}
  state.vert[1].x := 0.0;              {starting vertex}
  state.vert[1].y := -1.0*mult;
  state.n := 2;                        {init number of next vertex to stuff into list}
  for i := 1 to uparms.nsides-1 do begin {once for each non-end point to compute}
    a := a+da;                         {make angle of this vertex}
    state.vert[state.n].x := cos(a)*mult; {fill in this vertex}
    state.vert[state.n].y := sin(a)*mult;
    state.n := state.n+1;              {advance number of next vertex to stuff}
    end;                               {back and calculate next interior point}
  state.vert[state.n].x := 0.0;        {stuff ending vertex into list}
  state.vert[state.n].y := 1.0*mult;
  end;                                 {done with semi-circular end caps}

otherwise
  rend_end;
  sys_message_bomb ('rend', 'rend_vect_end_style_bad', nil, 0);
  end;                                 {done with vector end style cases}
  end;
{
******************************************
*
*   Code for main routine.
}
begin
{
*   Check to see if one of the VECT primitive entry point addresses in the
*   rendering pipe has been replaced by the entry point address of REND_SW_VECT_POLY.
*   This is done when it is desired to turn vectors into polygons at that stage in
*   the pipe.  If so, the old REND_PRIM entry was saved in
*   REND_VECT_STATE.OLD_VECT_PROC_PNT, and REND_VECT_STATE.OLD_VECT_PROC_PNT_P was
*   set to the address of the REND_PRIM entry that was altered.  This latter pointer
*   is set to NIL to indicate that the REND_PRIM entry was not replaced.
}
  if rend_vect_state.replaced_prim_entry_p <> nil then begin {replaced something ?}
    rend_install_prim (                {restore REND_PRIM entry}
      rend_vect_state.replaced_prim_data_p^, {data block for primitive to install}
      rend_vect_state.replaced_prim_entry_p^); {where to install the primitive}
    end;
{
*   Set the VECT_2DIM primitive address.  This is used to switch between integer and
*   floating point (subpixel) addressed vectors.
}
  if parms.subpixel                    {check integer/subpixel flag}
    then begin                         {generic vectors will be subpixel addressed}
      rend_install_prim (
        rend_sw_prim.vect_fp_2dim_data_p^,
        rend_sw_prim.vect_2dim);
      rend_install_prim (
        rend_prim.vect_fp_2dim_data_p^,
        rend_prim.vect_2dim);
      end
    else begin                         {generic vectors will be integer addressed}
      rend_install_prim (
        rend_sw_prim.vect_int_2dim_data_p^,
        rend_sw_prim.vect_2dim);
      rend_install_prim (
        rend_prim.vect_int_2dim_data_p^,
        rend_prim.vect_2dim);
      end
    ;
{
*   Set the coordinate space level, if any, where vectors will be turned into polygons.
}
  thick_below_3d := false;             {init to no wide vectors below 3D space}
  case parms.poly_level of             {different code for each possible level}

rend_space_none_k: begin               {vectors never turned into polygons}
      rend_vect_state.replaced_prim_entry_p := nil;
      end;

rend_space_2dim_k: begin
      thick_below_3d := true;          {vector thickening will effect 3D vectors}
      rend_vect_state.replaced_prim_entry_p := univ_ptr(
        addr(rend_prim.vect_2dim));
      rend_vect_state.replaced_prim_data_p :=
        rend_prim.vect_2dim_data_p;
      rend_install_prim (rend_sw_vect_poly_d, rend_prim.vect_2dim);
      rend_vect_state.poly_proc_p :=
        addr(rend_prim.poly_2dim);
      rend_vect_state.poly_proc_data_p :=
        rend_prim.poly_2dim_data_p;
      rend_vect_state.cpnt_p :=        {set pointer to output space current point}
        univ_ptr(addr(rend_2d.curr_x2dim));
      rend_vect_state.cpnt_proc_p :=   {set poiner to SET_CPNT routine pointer}
        addr(rend_set.cpnt_2dim);
      end;

rend_space_2dimcl_k: begin
      thick_below_3d := true;          {vector thickening will effect 3D vectors}
      rend_vect_state.replaced_prim_entry_p := univ_ptr(
        addr(rend_prim.vect_2dimcl));
      rend_vect_state.replaced_prim_data_p :=
        rend_prim.vect_2dimcl_data_p;
      rend_install_prim (rend_sw_vect_poly_d, rend_prim.vect_2dimcl);
      rend_vect_state.poly_proc_p :=
        addr(rend_prim.poly_2dimcl);
      rend_vect_state.poly_proc_data_p :=
        rend_prim.poly_2dimcl_data_p;
      rend_vect_state.cpnt_p :=        {set pointer to output space current point}
        univ_ptr(addr(rend_2d.curr_x2dim));
      rend_vect_state.cpnt_proc_p :=   {set poiner to SET_CPNT routine pointer}
        addr(rend_set.cpnt_2dim);
      end;

rend_space_2d_k: begin
      thick_below_3d := true;          {vector thickening will effect 3D vectors}
      rend_vect_state.replaced_prim_entry_p := univ_ptr(
        addr(rend_prim.vect_2d));
      rend_vect_state.replaced_prim_data_p :=
        rend_prim.vect_2d_data_p;
      rend_install_prim (rend_sw_vect_poly_d, rend_prim.vect_2d);
      rend_vect_state.poly_proc_p :=
        addr(rend_prim.poly_2d);
      rend_vect_state.poly_proc_data_p :=
        rend_prim.poly_2d_data_p;
      rend_vect_state.cpnt_p :=        {set pointer to output space current point}
        univ_ptr(addr(rend_2d.sp.cpnt));
      rend_vect_state.cpnt_proc_p :=   {set poiner to SET_CPNT routine pointer}
        addr(rend_set.cpnt_2d);
      end;

rend_space_3dpl_k: begin
      rend_vect_state.replaced_prim_entry_p := univ_ptr(
        addr(rend_prim.vect_3dpl));
      rend_vect_state.replaced_prim_data_p :=
        rend_prim.vect_3dpl_data_p;
      rend_install_prim (rend_sw_vect_poly_d, rend_prim.vect_3dpl);
      rend_vect_state.poly_proc_p :=
        addr(rend_prim.poly_3dpl);
      rend_vect_state.poly_proc_data_p :=
        rend_prim.poly_3dpl_data_p;
      rend_vect_state.cpnt_p :=        {set pointer to output space current point}
        univ_ptr(addr(rend_3dpl.sp.cpnt));
      rend_vect_state.cpnt_proc_p :=   {set poiner to SET_CPNT routine pointer}
        addr(rend_set.cpnt_3dpl);
      end;

rend_space_text_k: begin
      rend_vect_state.replaced_prim_entry_p := univ_ptr(
        addr(rend_prim.vect_text));
      rend_vect_state.replaced_prim_data_p :=
        rend_prim.vect_text_data_p;
      rend_install_prim (rend_sw_vect_poly_d, rend_prim.vect_text);
      rend_vect_state.poly_proc_p :=
        addr(rend_prim.poly_text);
      rend_vect_state.poly_proc_data_p :=
        rend_prim.poly_text_data_p;
      rend_vect_state.cpnt_p :=        {set pointer to output space current point}
        univ_ptr(addr(rend_text_state.sp.cpnt));
      rend_vect_state.cpnt_proc_p :=   {set poiner to SET_CPNT routine pointer}
        addr(rend_set.cpnt_text);
      end;

rend_space_txdraw_k: begin
      rend_vect_state.replaced_prim_entry_p := univ_ptr(
        addr(rend_prim.vect_txdraw));
      rend_vect_state.replaced_prim_data_p :=
        rend_prim.vect_txdraw_data_p;
      rend_install_prim (rend_sw_vect_poly_d, rend_prim.vect_txdraw);
      rend_vect_state.poly_proc_p :=
        addr(rend_prim.poly_txdraw);
      rend_vect_state.poly_proc_data_p :=
        rend_prim.poly_txdraw_data_p;
      rend_vect_state.cpnt_proc_p :=   {set poiner to SET_CPNT routine pointer}
        addr(rend_set.cpnt_txdraw);
      case rend_text_parms.coor_level of
rend_space_2dim_k: begin               {TXDRAW is 2D image coordinate space}
          rend_vect_state.cpnt_p :=
            univ_ptr(addr(rend_2d.curr_x2dim));
          end;
rend_space_2dimcl_k: begin             {TXDRAW is 2D image coordinate space pre-clip}
          rend_vect_state.cpnt_p :=
            univ_ptr(addr(rend_2d.curr_x2dim));
          end;
rend_space_2d_k: begin                 {TXDRAW is 2D model coordinate space}
          rend_vect_state.cpnt_p :=
            univ_ptr(addr(rend_2d.sp.cpnt));
          end;
rend_space_3dpl_k: begin               {TXDRAW is current plane in 3D model space}
          rend_vect_state.cpnt_p :=
            univ_ptr(addr(rend_3dpl.sp.cpnt));
          end;
otherwise
        rend_end;
        sys_message_bomb ('rend', 'rend_txdraw_bad_space', nil, 0);
        end;                           {end of TXDRAW coordinate space cases}
      end;

otherwise
    rend_end;
    sys_message_bomb ('rend', 'rend_vect_to_poly_space_bad', nil, 0);
    end;                               {done with polygon conversion level cases}
{
*   Update the internal vector end cap descriptors if polygon conversion is turned on
*   and if the parameters changed from last time.
}
  if                                   {different vector start style parameters ?}
      (parms.start_style.style <> rend_vect_parms.start_style.style) or
      (parms.start_style.nsides <> rend_vect_parms.start_style.nsides)
      then begin
    end_cap (                          {recompute internal state for end cap}
      parms.start_style,               {user parameters that define end cap}
      rend_vect_state.start_cap,       {internal state to update}
      -1.0);                           {flip about origin from end cap}
    end;                               {done updating vector start cap state}
  if                                   {different vector end style parameters ?}
      (parms.end_style.style <> rend_vect_parms.end_style.style) or
      (parms.end_style.nsides <> rend_vect_parms.end_style.nsides)
      then begin
    end_cap (                          {recompute internal state for end cap}
      parms.end_style,                 {user parameters that define end cap}
      rend_vect_state.end_cap,         {internal state to update}
      1.0);                            {produce end cap instead of start cap}
    end;                               {done updating vector end cap state}
{
*   Install different LINE_3D primitive depending on whether vector thickening
*   effects this primitive.
}
  if thick_below_3d
    then begin                         {vector thickening DOES effect LINE_3D}
      rend_install_prim (rend_sw_line2_3d_d, rend_sw_prim.line_3d);
      end
    else begin                         {vector thickening does NOT effect LINE_3D}
      rend_install_prim (rend_sw_line_3d_d, rend_sw_prim.line_3d);
      end
    ;
  rend_vect_parms := parms;            {save new user parameters in common block}
  rend_xf3d.vrad_ok := false;          {3D space vector widths are now invalid}
  end;
