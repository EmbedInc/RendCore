{   Subroutine REND_SW_SETUP_ITERPS
*
*   Set up the interpolators to the new leading edge Bresenham stepper values.
*   It is assumed that the following state has been previously set up:
*
*     REND_LEAD_EDGE                   (leading edge Bresenham stepper)
*     REND_DIR_FLAG                    (trapezoid span direction flag)
*     The canonical color description for each enabled interpolant.
*     The color at the current point for each enabled interpolant.
}
module rend_sw_setup_iterps;
define rend_sw_setup_iterps;
%include 'rend_sw2.ins.pas';

procedure rend_sw_setup_iterps;        {set up interpolants after leading edge setup}

var
  iterp_n: sys_int_machine_t;          {current interpolant number}
  dx, dy: real;                        {displacement from iterp anchor point}
  cdx, cdy: real;                      {X and Y first derivatives at curr point}
  edaa, edbb: real;                    {second derivatives for each direction}
  r: real;                             {integer value before float --> int convert}
{
**********************************************************
*
*   Local subroutine TMAP_DERIVATIVES (I, E)
*
*   Init the extra derivates needed for an interpolant that is being used as
*   a texture map index.  I is the interpolant normal state block.  E is the extra
*   derivatives state block for that interpolant.  It is assumed that
*   the DX and DY values in E have already been set for the current point.
}
procedure tmap_derivatives (
  in out  i: rend_iterp_pix_t;         {normal interpolant state block}
  in out  e: rend_uvwder_t);           {supplemental derivatives state block}

var
  r: real;                             {scratch floating point number}

label
  punt_flat;

begin
  if                                   {must do quadratic calculations ?}
      (i.mode >= rend_iterp_mode_quad_k) and {quadratic interpolation mode set ?}
      i.on                             {interpolant is enabled ?}
{
*   Set derivatives the hard way, using the quadratic interpolation rules.
}
    then begin
      r := 65536.0 * i.val_scale * (
        rend_lead_edge.dxa*i.adxx +
        rend_lead_edge.dya*i.adxy
        );
      if (r > 2147480000.0) or (r < -2147480000.0) then begin {past range for int ?}
        i.mode := rend_iterp_mode_flat_k; {punt back to flat interpolation}
        goto punt_flat;                {set derivatives for flat interpolation}
        end;
      e.dax.all := round(r);

      r := 65536.0 * i.val_scale * (
        rend_lead_edge.dya*i.adyy +
        rend_lead_edge.dxa*i.adxy
        );
      if (r > 2147480000.0) or (r < -2147480000.0) then begin {past range for int ?}
        i.mode := rend_iterp_mode_flat_k; {punt back to flat interpolation}
        goto punt_flat;                {set derivatives for flat interpolation}
        end;
      e.day.all := round(r);

      r := 65536.0 * i.val_scale * (
        rend_lead_edge.dxb*i.adxx +
        rend_lead_edge.dyb*i.adxy
        );
      if (r > 2147480000.0) or (r < -2147480000.0) then begin {past range for int ?}
        i.mode := rend_iterp_mode_flat_k; {punt back to flat interpolation}
        goto punt_flat;                {set derivatives for flat interpolation}
        end;
      e.dbx.all := round(r);

      r := 65536.0 * i.val_scale * (
        rend_lead_edge.dyb*i.adyy +
        rend_lead_edge.dxb*i.adxy
        );
      if (r > 2147480000.0) or (r < -2147480000.0) then begin {past range for int ?}
        i.mode := rend_iterp_mode_flat_k; {punt back to flat interpolation}
        goto punt_flat;                {set derivatives for flat interpolation}
        end;
      e.dby.all := round(r);

      if rend_dir_flag = rend_dir_right_k
        then begin                     {H direction is +X}
          r := 65536.0 * i.val_scale * (
            i.adxx
            );
          if (r > 2147480000.0) or (r < -2147480000.0) then begin {past int range ?}
            i.mode := rend_iterp_mode_flat_k; {punt back to flat interpolation}
            goto punt_flat;            {set derivatives for flat interpolation}
            end;
          e.dhx.all := round(r);

          r := 65536.0 * i.val_scale * (
            i.adxy
            );
          if (r > 2147480000.0) or (r < -2147480000.0) then begin {past int range ?}
            i.mode := rend_iterp_mode_flat_k; {punt back to flat interpolation}
            goto punt_flat;            {set derivatives for flat interpolation}
            end;
          e.dhy.all := round(r);
          end

        else begin                     {H direction is -X}
          r := 65536.0 * i.val_scale * (
            -i.adxx
            );
          if (r > 2147480000.0) or (r < -2147480000.0) then begin {past int range ?}
            i.mode := rend_iterp_mode_flat_k; {punt back to flat interpolation}
            goto punt_flat;            {set derivatives for flat interpolation}
            end;
          e.dhx.all := round(r);

          r := 65536.0 * i.val_scale * (
            -i.adxy
            );
          if (r > 2147480000.0) or (r < -2147480000.0) then begin {past int range ?}
            i.mode := rend_iterp_mode_flat_k; {punt back to flat interpolation}
            goto punt_flat;            {set derivatives for flat interpolation}
            end;
          e.dhy.all := round(r);
          end
        ;
      end                              {done setting derivatives using quadratic}
{
*   Set second derivatives to zero.  This assumes the first derivatives
*   won't change across the trapezoid.
}
    else begin                         {assume first derivatives are constant}
punt_flat:                             {jump here to punt to flat interpolation}
      e.dax.all := 0;
      e.day.all := 0;
      e.dbx.all := 0;
      e.dby.all := 0;
      e.dhx.all := 0;
      e.dhy.all := 0;
      e.edx.all := 0;
      e.edy.all := 0;
      end
    ;

  e.edx := e.dx;                       {copy lead edge derivatives from curr point}
  e.edy := e.dy;
  end;
{
**********************************************************
*
*   Start of main routine.
}
begin
  for iterp_n := 1 to rend_iterps.n_on do begin {once for each enabled interpolant}
    with rend_iterps.list_on[iterp_n]^:iterp do begin {set up ITERP abbreviation}
{
*   Process this interpolant.  The abbreviation ITERP stands for this interpolant
*   state block.
}
  case iterp.mode of                   {different code for each interpolation mode}

rend_iterp_mode_linear_k: begin        {linear interpolation}
  r := 65536.0 * iterp.val_scale *     {value for 32 bit integer}
    (iterp.adx*rend_lead_edge.dxa + iterp.ady*rend_lead_edge.dya);
  if (r > 2147480000.0) or (r < -2147480000.0) then begin {out of range for integer ?}
    iterp.mode := rend_iterp_mode_flat_k; {set to flat shading}
    next;                              {nothing to set up for flat interpolation}
    end;
  iterp.eda.all := round(r);           {stuff value into integer}
  r := 65536.0 * iterp.val_scale *
    (iterp.adx*rend_lead_edge.dxb + iterp.ady*rend_lead_edge.dyb);
  if (r > 2147480000.0) or (r < -2147480000.0) then begin {out of range for integer ?}
    iterp.mode := rend_iterp_mode_flat_k; {set to flat shading}
    next;                              {nothing to set up for flat interpolation}
    end;
  iterp.edb.all := round(r);           {stuff value into integer}
  case rend_dir_flag of
rend_dir_right_k: begin                {H direction is +X}
    r := 65536.0 * iterp.val_scale * iterp.adx; {value for 32 bit integer}
    if (r > 2147480000.0) or (r < -2147480000.0) then begin {out of range for integer ?}
      iterp.mode := rend_iterp_mode_flat_k; {set to flat shading}
      next;                            {nothing to set up for flat interpolation}
      end;
    iterp.edh.all := round(r);         {stuff value into integer}
    end;
rend_dir_left_k: begin                 {H direction is -X}
    r := 65536.0 * iterp.val_scale * (-iterp.adx); {value for 32 bit integer}
    if (r > 2147480000.0) or (r < -2147480000.0) then begin {out of range for integer ?}
      iterp.mode := rend_iterp_mode_flat_k; {set to flat shading}
      next;                            {nothing to set up for flat interpolation}
      end;
    iterp.edh.all := round(r);         {stuff value into integer}
    end;
    end;                               {done with direction flag cases}
  iterp.dh := iterp.edh;               {init DH for current pixel}
  end;                                 {done with linear interpolation case}

rend_iterp_mode_quad_k: begin          {quadratic interpolation}
  edaa :=                              {delta DA for A direction}
    sqr(rend_lead_edge.dxa)*iterp.adxx
    + sqr(rend_lead_edge.dya)*iterp.adyy
    + 2.0*rend_lead_edge.dxa*rend_lead_edge.dya*iterp.adxy;
  edbb :=                              {delta DB for B direction}
    sqr(rend_lead_edge.dxb)*iterp.adxx
    + sqr(rend_lead_edge.dyb)*iterp.adyy
    + 2.0*rend_lead_edge.dxb*rend_lead_edge.dyb*iterp.adxy;

  r := 65536.0 * iterp.val_scale * edaa;
  if (r > 2147480000.0) or (r < -2147480000.0) then begin {out of range for integer ?}
    iterp.mode := rend_iterp_mode_flat_k; {set to flat shading}
    next;                              {nothing to set up for flat interpolation}
    end;
  iterp.edaa.all := round(r);

  r := 65536.0 * iterp.val_scale * edbb;
  if (r > 2147480000.0) or (r < -2147480000.0) then begin {out of range for integer ?}
    iterp.mode := rend_iterp_mode_flat_k; {set to flat shading}
    next;                              {nothing to set up for flat interpolation}
    end;
  iterp.edbb.all := round(r);

  r := 65536.0 * iterp.val_scale * (
    rend_lead_edge.dxa*rend_lead_edge.dxb*iterp.adxx +
    rend_lead_edge.dya*rend_lead_edge.dyb*iterp.adyy +
    (rend_lead_edge.dxa*rend_lead_edge.dyb + rend_lead_edge.dxb*rend_lead_edge.dya)*iterp.adxy
    );
  if (r > 2147480000.0) or (r < -2147480000.0) then begin {out of range for integer ?}
    iterp.mode := rend_iterp_mode_flat_k; {set to flat shading}
    next;                              {nothing to set up for flat interpolation}
    end;
  iterp.edab.all := round(r);

  dx := rend_lead_edge.x+0.5 - iterp.x; {make displacement from anchor to curr pnt}
  dy := rend_lead_edge.y+0.5 - iterp.y;
  cdx := iterp.adx                     {X first derivative at current point}
    + dx*iterp.adxx + dy*iterp.adxy;
  cdy := iterp.ady                     {Y first derivative at current point}
    + dx*iterp.adxy + dy*iterp.adyy;

  r := 65536.0 * iterp.val_scale * (
    rend_lead_edge.dxa*cdx +
    rend_lead_edge.dya*cdy +
    0.5*edaa);
  if (r > 2147480000.0) or (r < -2147480000.0) then begin {out of range for integer ?}
    iterp.mode := rend_iterp_mode_flat_k; {set to flat shading}
    next;                              {nothing to set up for flat interpolation}
    end;
  iterp.eda.all := round(r);

  r := 65536.0 * iterp.val_scale * (
    rend_lead_edge.dxb*cdx +
    rend_lead_edge.dyb*cdy +
    0.5*edbb);
  if (r > 2147480000.0) or (r < -2147480000.0) then begin {out of range for integer ?}
    iterp.mode := rend_iterp_mode_flat_k; {set to flat shading}
    next;                              {nothing to set up for flat interpolation}
    end;
  iterp.edb.all := round(r);

  case rend_dir_flag of
rend_dir_right_k: begin                {H direction is +X}
    r := 65536.0 * iterp.val_scale * iterp.adxx;
    if (r > 2147480000.0) or (r < -2147480000.0) then begin {out of range for integer ?}
      iterp.mode := rend_iterp_mode_flat_k; {set to flat shading}
      next;                            {nothing to set up for flat interpolation}
      end;
    iterp.edhh.all := round(r);

    r := 65536.0 * iterp.val_scale * (
      rend_lead_edge.dxa*iterp.adxx +
      rend_lead_edge.dya*iterp.adxy);
    if (r > 2147480000.0) or (r < -2147480000.0) then begin {out of range for integer ?}
      iterp.mode := rend_iterp_mode_flat_k; {set to flat shading}
      next;                            {nothing to set up for flat interpolation}
      end;
    iterp.edah.all := round(r);

    r := 65536.0 * iterp.val_scale * (
      rend_lead_edge.dxb*iterp.adxx +
      rend_lead_edge.dyb*iterp.adxy);
    if (r > 2147480000.0) or (r < -2147480000.0) then begin {out of range for integer ?}
      iterp.mode := rend_iterp_mode_flat_k; {set to flat shading}
      next;                            {nothing to set up for flat interpolation}
      end;
    iterp.edbh.all := round(r);

    r := 65536.0 * iterp.val_scale * cdx;
    if (r > 2147480000.0) or (r < -2147480000.0) then begin {out of range for integer ?}
      iterp.mode := rend_iterp_mode_flat_k; {set to flat shading}
      next;                            {nothing to set up for flat interpolation}
      end;
    iterp.edh.all := round(r);

    end;
rend_dir_left_k: begin                 {H direction is -X}
    r := 65536.0 * iterp.val_scale * iterp.adxx;
    if (r > 2147480000.0) or (r < -2147480000.0) then begin {out of range for integer ?}
      iterp.mode := rend_iterp_mode_flat_k; {set to flat shading}
      next;                            {nothing to set up for flat interpolation}
      end;
    iterp.edhh.all := round(r);

    r := 65536.0 * iterp.val_scale * (
      (-rend_lead_edge.dxa*iterp.adxx) +
      (-rend_lead_edge.dya*iterp.adxy));
    if (r > 2147480000.0) or (r < -2147480000.0) then begin {out of range for integer ?}
      iterp.mode := rend_iterp_mode_flat_k; {set to flat shading}
      next;                            {nothing to set up for flat interpolation}
      end;
    iterp.edah.all := round(r);

    r := 65536.0 * iterp.val_scale * (
      (-rend_lead_edge.dxb*iterp.adxx) +
      (-rend_lead_edge.dyb*iterp.adxy));
    if (r > 2147480000.0) or (r < -2147480000.0) then begin {out of range for integer ?}
      iterp.mode := rend_iterp_mode_flat_k; {set to flat shading}
      next;                            {nothing to set up for flat interpolation}
      end;
    iterp.edbh.all := round(r);

    r := 65536.0 * iterp.val_scale * (-cdx);
    if (r > 2147480000.0) or (r < -2147480000.0) then begin {out of range for integer ?}
      iterp.mode := rend_iterp_mode_flat_k; {set to flat shading}
      next;                            {nothing to set up for flat interpolation}
      end;
    iterp.edh.all := round(r);

    end;                               {done with right-to-left direction case}
    end;                               {done with direction flag cases}
  iterp.dh := iterp.edh;               {init DH for current pixel}
  end;                                 {done with quadratic interpolation case}
  end;                                 {done with interpolation mode cases}
{
*   Done processing this interpolant.  Go back and process the next interpolant that
*   is enabled.
}
      end;                             {done with ITERP abbreviation}
    end;                               {back and do next interpolant}
{
*   All the normal interpolants have been done.  Now init the extra derivatives
*   of U, V, and W if the appropriate texture mapping modes are enabled.
}
  if rend_tmap.on then begin           {texture mapping turned on ?}
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
