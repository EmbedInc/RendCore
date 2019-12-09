{   Subroutine REND_SW_INTERPOLATE (STEP)
*
*   Step all the currently enabled interpolators by one step.  STEP defines what kind
*   of step to take.
}
module rend_sw_interpolate;
define rend_sw_interpolate;
%include 'rend_sw2.ins.pas';

procedure rend_sw_interpolate (        {advance all interpolants by one step}
  in      step: rend_iterp_step_k_t);  {interpolation step ID}
  val_param;

var
  iterp_n: sys_int_machine_t;          {current interpolant number}
  new_y: boolean;                      {TRUE if interpolating to a new scan line}
  dx: sys_int_machine_t;               {X distance from old pixel to new pixel}
  step_arg: rend_iterp_step_k_t;       {local copy of call arg for compiler bug}
{
**********************************************************
*
*   Local subroutine TMAP_DERIVATIVES (I, E)
*
*   Update the extra derivates needed for an interpolant that is being used as
*   a texture map index.  I is the interpolant normal state block.  E is the extra
*   derivatives state block for that interpolant.
}
procedure tmap_derivatives (
  in      i: rend_iterp_pix_t;         {normal interpolant state block}
  in out  e: rend_uvwder_t);           {supplemental derivatives state block}

begin
  if i.mode < rend_iterp_mode_quad_k then return; {first derivatives constant ?}
  case step_arg of                     {different code for each step direction}

rend_iterp_step_a_k: begin             {leading edge A step}
      e.edx.all := e.edx.all + e.dax.all; {update leading edge values}
      e.edy.all := e.edy.all + e.day.all;
      e.dx := e.edx;                   {copy current value from leading edge value}
      e.dy := e.edy;
      end;

rend_iterp_step_b_k: begin             {leading edge B step}
      e.edx.all := e.edx.all + e.dbx.all; {update leading edge values}
      e.edy.all := e.edy.all + e.dby.all;
      e.dx := e.edx;                   {make current value from leading edge value}
      e.dy := e.edy;
      end;

rend_iterp_step_h_k: begin             {horizontal step within a span}
      e.dx.all := e.dx.all + e.dhx.all;
      e.dy.all := e.dy.all + e.dhy.all;
      end;
    end;                               {done with interpolation step cases}
  end;
{
**********************************************************
*
*   Start of main routine.
}
begin
  case step of                         {different code for each step type}
rend_iterp_step_a_k: begin             {leading edge A step}
    new_y := rend_lead_edge.dya <> 0;
    dx := rend_lead_edge.dxa;
    rend_curr_x := rend_lead_edge.x;   {reset current X coordinate}
    end;
rend_iterp_step_b_k: begin             {leading edge B step}
    new_y := rend_lead_edge.dyb <> 0;
    dx := rend_lead_edge.dxb;
    rend_curr_x := rend_lead_edge.x;   {reset current X coordinate}
    end;
rend_iterp_step_h_k: begin             {horizontal step within a span}
    new_y := false;
    if rend_dir_flag = rend_dir_right_k
      then dx := 1
      else dx := -1;
    rend_curr_x := rend_curr_x + dx;   {update X coor of where interps are set to}
    end;
    end;                               {end of step type cases}

  for iterp_n := 1 to rend_iterps.n_on do begin {once for each enabled interpolant}
    with rend_iterps.list_on[iterp_n]^:iterp do begin {set up ITERP abbreviation}
{
*   Process this interpolant.  The abbreviation ITERP stands for this interpolant
*   state block.
}
  if iterp.bitmap_p <> nil then begin  {this interpolant has bitmap attatched ?}
    if new_y                           {check for new scan line}
      then begin                       {on new scan line}
        iterp.curr_adr.i :=            {find address of interpolant in this pixel}
          integer32(iterp.bitmap_p^.line_p[rend_lead_edge.y]) {start adr of scan line}
          + rend_lead_edge.x*iterp.bitmap_p^.x_offset {pixel offset into scan line}
          + iterp.iterp_offset;        {byte offset into pixel}
        end
      else begin                       {on same scan line}
        iterp.curr_adr.i := iterp.curr_adr.i {adr of interpolant at new pixel}
          + dx*iterp.bitmap_p^.x_offset;
        end
      ;
    end;
  if iterp.mode <= rend_iterp_mode_flat_k then next; {nothing to interpolate here ?}
  case step of                         {different code for each kind of step}

rend_iterp_step_a_k: begin             {this is a leading edge A step}
  iterp.eval.all := iterp.eval.all + iterp.eda.all; {make new leading edge value}
  iterp.val.all := iterp.eval.all;     {copy into new raw current value}
  if iterp.mode > rend_iterp_mode_linear_k then begin {more than linear ?}
    iterp.eda.all := iterp.eda.all + iterp.edaa.all; {update second derivatives}
    iterp.edb.all := iterp.edb.all + iterp.edab.all;
    iterp.edh.all := iterp.edh.all + iterp.edah.all;
    iterp.dh := iterp.edh;             {update derivative for horizontal step}
    end;
  end;

rend_iterp_step_b_k: begin             {this is a leading edge B step}
  iterp.eval.all := iterp.eval.all + iterp.edb.all; {make new leading edge value}
  iterp.val.all := iterp.eval.all;     {copy into new raw current value}
  if iterp.mode > rend_iterp_mode_linear_k then begin {more than linear ?}
    iterp.eda.all := iterp.eda.all + iterp.edab.all; {update second derivatives}
    iterp.edb.all := iterp.edb.all + iterp.edbb.all;
    iterp.edh.all := iterp.edh.all + iterp.edbh.all;
    iterp.dh := iterp.edh;             {update derivative for horizontal step}
    end;
  end;

rend_iterp_step_h_k: begin             {horizontal step during span of a trapezoid}
  iterp.val.all := iterp.val.all + iterp.dh.all; {make new raw current value}
  if iterp.mode > rend_iterp_mode_linear_k then begin {more than linear ?}
    iterp.dh.all := iterp.dh.all + iterp.edhh.all; {update second derivative}
    end;
  end;
  end;                                 {done with all the interpolation mode cases}

  iterp.value := iterp.val;            {init final interpolator result value}
  if iterp.iclamp then begin           {clamp result in VALUE ?}
    if iterp.value.all > iterp.iclamp_max.all {over range ?}
      then iterp.value.all := iterp.iclamp_max.all;
    if iterp.value.all < iterp.iclamp_min.all {under range ?}
      then iterp.value.all := iterp.iclamp_min.all;
    end;                               {done handling clamping}
{
*   Done processing this interpolant.  Go back and process the next interpolant that
*   is enabled.
}
      end;                             {done with ITERP abbreviation}
    end;                               {back and do next interpolant}
{
*   All the normal interpolants have been done.  Now update the extra derivatives
*   of U, V, and W if the appropriate texture mapping modes are enabled.
}
  if rend_tmap.on then begin           {texture mapping turned on ?}
    step_arg := step;                  {make local copy of arg for compiler bug}
    case rend_tmap.dim of              {which interpolants are tmap indicies ?}
rend_tmapd_u_k: begin
        tmap_derivatives (rend_iterps.u, rend_u);
        end;
rend_tmapd_uv_k: begin
        tmap_derivatives (rend_iterps.u, rend_u);
        tmap_derivatives (rend_iterps.v, rend_v);
        end;
otherwise
      rend_message_bomb ('rend', 'rend_tmap_dim_bad', nil, 0);
      end;                             {done with texture map dimension ID cases}
    end;                               {done handling texture mapping turned on}
  end;
