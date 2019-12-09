{   Subroutine REND_SW_CHECK_MODES
*
*   Reevaluate all the current modes and switches, and make sure the optimum version
*   of each of the transfer vector routines is installed.  Some modes may allow
*   efficiencies, while other modes require slower more general purpose routines.
}
module rend_sw_check_modes;
define rend_sw_check_modes;
%include 'rend_sw2.ins.pas';

procedure rend_sw_check_modes;

var
  i: sys_int_machine_t;                {loop counter}
  max_mode: sys_int_machine_t;         {max interpolation order for any iterps}
  itrp_on: sys_int_machine_t;          {number of interpolants of interest turned on}
  n_hflat: sys_int_machine_t;          {number of interpolants horizontally flat}
  n_clamp: sys_int_machine_t;          {number of interpolants with iterp clamping on}
  n_clims: sys_int_machine_t;          {num iterps with OK iterp clamping limits}
  l_p: rend_light_p_t;                 {pointer to current light source}
  ok: boolean;                         {scratch flag for necessary conditions met}

label
  normal_tzoid, done_tzoid;

begin
  rend_mode_changed := false;          {no longer any pending mode change}

  rend_ray.visprop_old :=              {TRUE if ray visprop is out of date}
    rend_ray.visprop_old or rend_suprop.changed;
{
*   Update cached light source state if any changes were made that effects
*   the rendering lights environment.
}
  if rend_lights.changed then begin    {renderer-visible lighting state changed ?}
    rend_lights.dir_p := nil;          {init to no directional light source}
    rend_lights.amb_red := 0.0;        {init rend_lights.ambient light accumulators}
    rend_lights.amb_grn := 0.0;
    rend_lights.amb_blu := 0.0;
    rend_lights.n_on := 0;             {init number of ON light sources}
    rend_lights.n_amb := 0;            {init number of ambient light sources}
    rend_lights.n_dir := 0;            {init number of directional light sources}
    l_p := rend_lights.on_p;           {init current light source to first ON light}
    while l_p <> nil do begin          {once for each light source in ON list}
      rend_lights.n_on := rend_lights.n_on + 1; {count one more ON light source}
      case l_p^.ltype of               {what kind of light source is this ?}
rend_ltype_amb_k: begin                {ambient light source}
          rend_lights.amb_red := rend_lights.amb_red + l_p^.amb_red;
          rend_lights.amb_grn := rend_lights.amb_grn + l_p^.amb_grn;
          rend_lights.amb_blu := rend_lights.amb_blu + l_p^.amb_blu;
          rend_lights.n_amb := rend_lights.n_amb + 1; {one more ambient light}
          end;
rend_ltype_dir_k: begin                {directional light source}
          rend_lights.dir_p := l_p;    {save pointer to directional light source}
          rend_lights.n_dir := rend_lights.n_dir + 1; {one more directional light}
          end;
        end;                           {end of light source type cases}
      l_p := l_p^.next_on_p;           {advance to next ON light source in list}
      end;                             {back to process this new light source}
    end;                               {done updating cached light source state}
{
*   Update internal cached state about interpolants.  This may be used here and
*   by CHECK_MODES routines for specific devices.
}
  rend_iterp_data.n_on := 0;           {init cached data}
  rend_iterp_data.n_rgb := 0;
  rend_iterp_data.n_8 := 0;
  rend_iterp_data.n_pixfun_ins := 0;
  rend_iterp_data.n_iclamp := 0;
  rend_iterp_data.n_iclamp_all := 0;
  rend_iterp_data.n_aa := 0;
  rend_iterp_data.n_span := 0;
  rend_iterp_data.n_wmask_all := 0;
  rend_iterp_data.n_hflat := 0;
  rend_iterp_data.n_shmode_none := 0;
  rend_iterp_data.n_shmode_flat := 0;
  rend_iterp_data.n_shmode_linear := 0;
  rend_iterp_data.n_shmode_quad := 0;
  max_mode := rend_iterp_mode_none_k;

  for i := 1 to rend_iterps.n_on do begin {once for each enabled interpolant}
    with rend_iterps.list_on[i]^:iterp do begin {set up ITERP abbreviation}
      rend_iterp_data.n_on := rend_iterp_data.n_on + 1;
      if iterp.pixfun = rend_pixfun_insert_k
        then rend_iterp_data.n_pixfun_ins := rend_iterp_data.n_pixfun_ins + 1;
      if iterp.span_run
        then rend_iterp_data.n_span := rend_iterp_data.n_span + 1;
      if  (iterp.shmode <= rend_iterp_mode_flat_k) or
          ( (iterp.shmode = rend_iterp_mode_linear_k) and
            (iterp.adx < 1.0E-8))
          then begin
        rend_iterp_data.n_hflat := rend_iterp_data.n_hflat + 1;
        end;
      iterp.max_mode := max(iterp.mode, iterp.shmode); {find max possible iterp mode}
      max_mode := max(max_mode, iterp.mode); {accumulate max overall iterp mode}
      case iterp.shmode of
rend_iterp_mode_none_k:
        rend_iterp_data.n_shmode_none := rend_iterp_data.n_shmode_none + 1;
rend_iterp_mode_flat_k:
        rend_iterp_data.n_shmode_flat := rend_iterp_data.n_shmode_flat + 1;
rend_iterp_mode_linear_k:
        rend_iterp_data.n_shmode_linear := rend_iterp_data.n_shmode_linear + 1;
rend_iterp_mode_quad_k:
        rend_iterp_data.n_shmode_quad := rend_iterp_data.n_shmode_quad + 1;
        end;

      case iterp.width of

8:      begin                          {interpolant is 8 bits wide}
          rend_iterp_data.n_8 := rend_iterp_data.n_8 + 1;
          if iterp.aa
            then rend_iterp_data.n_aa := rend_iterp_data.n_aa + 1;
          if (iterp.wmask & 255) = 255
            then rend_iterp_data.n_wmask_all := rend_iterp_data.n_wmask_all + 1;
          if iterp.iclamp
            then begin
              rend_iterp_data.n_iclamp := rend_iterp_data.n_iclamp + 1;
              if  (iterp.iclamp_max.val8 = 255) and
                  (iterp.iclamp_min.val8 = 0)
                then rend_iterp_data.n_iclamp_all := rend_iterp_data.n_iclamp_all + 1;
              end
            else begin
              rend_iterp_data.n_iclamp_all := rend_iterp_data.n_iclamp_all + 1;
              end
            ;
          end;                         {done with 8 bit iterp}

16:     begin                          {interpolant is 16 bits wide}
          if (iterp.wmask & 16#FFFF) = 16#FFFF
            then rend_iterp_data.n_wmask_all := rend_iterp_data.n_wmask_all + 1;
          end;                         {done with 16 bit iterp}

32:     begin                          {interpolant is 32 bits wide}
          if (iterp.wmask & 16#FFFFFFFF) = 16#FFFFFFFF
            then rend_iterp_data.n_wmask_all := rend_iterp_data.n_wmask_all + 1;
          end;                         {done with 16 bit iterp}

        end;                           {end of iterp width cases}
      end;                             {done with the ITERP abbreviation}
    end;                               {back and process next ON interpolant}

  if rend_iterps.red.on
    then rend_iterp_data.n_rgb := rend_iterp_data.n_rgb + 1;
  if rend_iterps.grn.on
    then rend_iterp_data.n_rgb := rend_iterp_data.n_rgb + 1;
  if rend_iterps.blu.on
    then rend_iterp_data.n_rgb := rend_iterp_data.n_rgb + 1;

  case max_mode of
rend_iterp_mode_linear_k: begin        {max interpolation mode is linear}
      rend_max_allowed_run := 65536;
      end;
rend_iterp_mode_quad_k: begin          {max interpolation mode is quadratic}
      rend_max_allowed_run := 256;
      end;
otherwise
    rend_max_allowed_run := rend_image.max_run; {set to no breakup necessary}
    end;
  rend_check_run_size :=               {TRUE if may need to break up polygon}
    rend_image.max_run > rend_max_allowed_run;
{
*   Public cached data is all set.
*
**************************
*
*   Install the appropriate INTERNAL.TZOID primitive.
}
  if rend_alpha_on then goto normal_tzoid; {alpha buffering on ?}
  if rend_tmap.on then goto normal_tzoid; {texture mapping on ?}
  if rend_prim.wpix <> rend_sw_prim.wpix {customized routine called by TZOID ?}
    then goto normal_tzoid;
  itrp_on := 0;                        {init to no RGBZ interpolators on}
  n_hflat := 0;                        {init num of horizontally flat interpolators}
  n_clamp := 0;                        {init num interpolants with iterp clamping on}
  n_clims := 0;                        {init num iterps with OK clamping limits}

  if rend_iterps.red.on then begin     {red interpolant turned on ?}
    if rend_iterps.red.iclamp then begin {interplator clamping turned ON ?}
      n_clamp := n_clamp + 1;          {one more interpolant with clamping ON}
      if  (rend_iterps.red.iclamp_max.val8 = 255) and
          (rend_iterps.red.iclamp_min.val8 = 0)
        then n_clims := n_clims + 1;   {one more OK type of interpolator clamping}
      end;
    case rend_iterps.red.mode of       {check interpolation mode}
rend_iterp_mode_flat_k: begin
        n_hflat := n_hflat + 1;        {definately horizontally linear}
        end;
rend_iterp_mode_linear_k: begin
        if abs(rend_iterps.red.adx) < 1.0E-8
          then n_hflat := n_hflat + 1; {one more horizontally linear}
        end;
otherwise
      goto normal_tzoid;               {other interpolation modes not allowed}
      end;                             {end of interpolation mode cases}
    if rend_iterps.red.pixfun <> rend_pixfun_insert_k
      then goto normal_tzoid;          {not PIXFUN INSERT ?}
    if (rend_iterps.red.wmask & 255) <> 255
      then goto normal_tzoid;          {not simple write mask ?}
    if trunc(rend_iterps.red.val_offset) <> 0
      then goto normal_tzoid;          {not normal offset value ?}
    if trunc(rend_iterps.red.val_offset + rend_iterps.red.val_scale) <> 255
      then goto normal_tzoid;          {not normal scale value ?}
    itrp_on := itrp_on+1;              {one more RGBZ interpolant with proper state}
    end;                               {done checking red interpolant}

  if rend_iterps.grn.on then begin     {green interpolant turned on ?}
    if rend_iterps.grn.iclamp then begin {interplator clamping turned ON ?}
      n_clamp := n_clamp + 1;          {one more interpolant with clamping ON}
      if  (rend_iterps.grn.iclamp_max.val8 = 255) and
          (rend_iterps.grn.iclamp_min.val8 = 0)
        then n_clims := n_clims + 1;   {one more OK type of interpolator clamping}
      end;
    case rend_iterps.grn.mode of       {check interpolation mode}
rend_iterp_mode_flat_k: begin
        n_hflat := n_hflat + 1;        {definately horizontally linear}
        end;
rend_iterp_mode_linear_k: begin
        if abs(rend_iterps.grn.adx) < 1.0E-8
          then n_hflat := n_hflat + 1; {one more horizontally linear}
        end;
otherwise
      goto normal_tzoid;               {other interpolation modes not allowed}
      end;                             {end of interpolation mode cases}
    if rend_iterps.grn.pixfun <> rend_pixfun_insert_k
      then goto normal_tzoid;          {not PIXFUN INSERT ?}
    if (rend_iterps.grn.wmask & 255) <> 255
      then goto normal_tzoid;          {not simple write mask ?}
    if trunc(rend_iterps.grn.val_offset) <> 0
      then goto normal_tzoid;          {not normal offset value ?}
    if trunc(rend_iterps.grn.val_offset + rend_iterps.grn.val_scale) <> 255
      then goto normal_tzoid;          {not normal scale value ?}
    itrp_on := itrp_on+1;              {one more RGBZ interpolant with proper state}
    end;                               {done checking green interpolant}

  if rend_iterps.blu.on then begin     {blue interpolant turned on ?}
    if rend_iterps.blu.iclamp then begin {interplator clamping turned ON ?}
      n_clamp := n_clamp + 1;          {one more interpolant with clamping ON}
      if  (rend_iterps.blu.iclamp_max.val8 = 255) and
          (rend_iterps.blu.iclamp_min.val8 = 0)
        then n_clims := n_clims + 1;   {one more OK type of interpolator clamping}
      end;
    case rend_iterps.blu.mode of       {check interpolation mode}
rend_iterp_mode_flat_k: begin
        n_hflat := n_hflat + 1;        {definately horizontally linear}
        end;
rend_iterp_mode_linear_k: begin
        if abs(rend_iterps.blu.adx) < 1.0E-8
          then n_hflat := n_hflat + 1; {one more horizontally linear}
        end;
otherwise
      goto normal_tzoid;               {other interpolation modes not allowed}
      end;                             {end of interpolation mode cases}
    if rend_iterps.blu.pixfun <> rend_pixfun_insert_k
      then goto normal_tzoid;          {not PIXFUN INSERT ?}
    if (rend_iterps.blu.wmask & 255) <> 255
      then goto normal_tzoid;          {not simple write mask ?}
    if trunc(rend_iterps.blu.val_offset) <> 0
      then goto normal_tzoid;          {not normal offset value ?}
    if trunc(rend_iterps.blu.val_offset + rend_iterps.blu.val_scale) <> 255
      then goto normal_tzoid;          {not normal scale value ?}
    itrp_on := itrp_on+1;              {one more RGBZ interpolant with proper state}
    end;                               {done checking blue interpolant}

  if rend_iterps.z.on then begin       {Z interpolant turned on ?}
    if rend_iterps.z.iclamp
      then n_clamp := n_clamp + 1;     {one more interpolant with clamping ON}
    case rend_iterps.z.mode of         {check interpolation mode}
rend_iterp_mode_flat_k: begin
        n_hflat := n_hflat + 1;        {definately horizontally linear}
        end;
rend_iterp_mode_linear_k: begin
        if abs(rend_iterps.z.adx) < 1.0E-7
          then n_hflat := n_hflat + 1; {one more horizontally linear}
        end;
otherwise
      goto normal_tzoid;               {other interpolation modes not allowed}
      end;                             {end of interpolation mode cases}
    if rend_iterps.z.pixfun <> rend_pixfun_insert_k
      then goto normal_tzoid;          {not PIXFUN INSERT ?}
    if (rend_iterps.z.wmask & 16#FFFF) <> 16#FFFF
      then goto normal_tzoid;          {not simple write mask ?}
    itrp_on := itrp_on+1;              {one more RGBZ interpolant with proper state}
    end;                               {done checking Z interpolant}

  if rend_iterps.n_on <> itrp_on       {something other than R, G, B, and Z on ?}
    then goto normal_tzoid;
  case itrp_on of                      {cases for how many of RGBZ turned ON}
{
*   Three of the four interpolants RGBZ are turned ON.
}
3:  begin
      if rend_iterps.z.on              {Z interpolant ON ?}
        then goto normal_tzoid;
      if n_clamp <> 3                  {not all clamped ?}
        then goto normal_tzoid;
      if n_clims <> n_clamp            {some iterps clamped with not OK limits ?}
        then goto normal_tzoid;
      rend_install_prim (rend_sw_tzoid5_d, rend_sw_internal.tzoid);
      end;
{
*   R, G, B, and Z are all turned on.
}
4:  begin
      if rend_zon                      {check for Z buffering on/off}
        then begin                     {Z buffering is ON}
          if rend_zfunc <> rend_zfunc_gt_k {not correct Z function ?}
            then goto normal_tzoid;
          if n_clims <> n_clamp        {some iterps clamped with not OK limits ?}
            then goto normal_tzoid;
          case n_clamp of
0:          rend_install_prim (rend_sw_tzoid2_d, rend_sw_internal.tzoid);
3:          rend_install_prim (rend_sw_tzoid4_d, rend_sw_internal.tzoid);
otherwise goto normal_tzoid;
            end;                       {end of number of clamping iterps cases}
          end
        else begin                     {Z buffering is OFF}
          if n_hflat <> 4              {not all at least horizontally flat ?}
            then goto normal_tzoid;
          rend_install_prim (rend_sw_tzoid3_d, rend_sw_internal.tzoid);
          end
        ;
      end;                             {done with RGBZ all on case}
    end;                               {end of number of interpolant ON cases}
  goto done_tzoid;                     {TZOID entry has already been installed}

normal_tzoid:                          {jump here if no special optimized cases apply}
  rend_install_prim  (rend_sw_tzoid_d, rend_sw_internal.tzoid);
done_tzoid:                            {REND_SW_INTERNAL.TZOID entry all set}
{
*   Done installing INTERNAL.TZOID primitive.
*
**************************
*
*   Decide which versions of other primitives to install.
*
*   Check for common necessary conditions for PRIM.ANTI_ALIAS,
*   PRIM.SPAN_2DIMCL, and PRIM.SPAN_2DIMI.
}
  ok :=                                {TRUE if common necessary conditions met}
    (not rend_alpha_on) and
    (not rend_tmap.on) and
    (not rend_zon) and
    (rend_iterp_data.n_8 = rend_iterp_data.n_on) and
    (rend_iterp_data.n_pixfun_ins = rend_iterp_data.n_on) and
    (rend_iterp_data.n_iclamp_all = rend_iterp_data.n_on) and
    (rend_iterp_data.n_wmask_all = rend_iterp_data.n_on);
{
*   Install PRIM.ANTI_ALIAS.
}
    if ok and (rend_iterp_data.n_aa = rend_iterp_data.n_on)
      then begin
        rend_install_prim (rend_sw_anti_alias2_d, rend_sw_prim.anti_alias);
        end
      else begin
        rend_install_prim (rend_sw_anti_alias_d, rend_sw_prim.anti_alias);
        end
      ;
{
*   Install PRIM.SPAN_2DIMCL, PRIM.SPAN_2DIMI.
}
    if ok and (rend_iterp_data.n_span = rend_iterp_data.n_on)
      then begin
        rend_install_prim (rend_sw_span2_2dimcl_d, rend_sw_prim.span_2dimcl);
        rend_install_prim (rend_sw_span2_2dimcl_d, rend_sw_prim.span_2dimi);
        end
      else begin
        rend_install_prim (rend_sw_span_2dimcl_d, rend_sw_prim.span_2dimcl);
        rend_install_prim (rend_sw_span_2dimcl_d, rend_sw_prim.span_2dimi);
        end
      ;
{
*   Install INTERNAL.TRI_CACHE_3D.
}
  if
      rend_view.perspec_on and         {perspective ON ?}
      rend_vert3d_always[rend_vert3d_norm_p_k] and {shading normals always given ?}
      (rend_vert3d_bytes <= rend_vert3d_size_simple_k) and {vert desc small enough ?}
      (rend_shade_geom = rend_iterp_mode_linear_k) and {linear geometry ?}
      (not rend_alpha_on) and          {alpha buffering OFF ?}
      (not rend_tmap.on) and           {texture mapping OFF ?}
      (not rend_ray.save_on) and       {ray tracing OFF ?}
      (rend_iterp_data.n_rgb = 3) and  {red, green, and blue all ON ?}
      (rend_iterps.red.shmode = rend_iterp_mode_linear_k) and {RGB SHMODES LINEAR ?}
      (rend_iterps.grn.shmode = rend_iterp_mode_linear_k) and
      (rend_iterps.blu.shmode = rend_iterp_mode_linear_k) and
      rend_iterps.z.on and             {Z interpolant is ON ?}
      (rend_iterps.z.shmode = rend_iterp_mode_linear_k) and {Z SHADE_MODE LINEAR ?}
      (rend_iterp_data.n_shmode_linear = 4) and {4 iterps with SHADE_MODE LINEAR ?}
      (                                {all other iterps have SHADE_MODE NONE?}
        (rend_iterp_data.n_shmode_linear + rend_iterp_data.n_shmode_none)
        = rend_iterp_data.n_on
        )
    then begin
      if
          rend_xf3d.rot_scale and      {NV xform just rotation and uniform scaling ?}
          rend_shnorm_unit             {shading normals unitized by application ?}
        then begin
          rend_install_prim (rend_sw_tri_cache3_3d_d, rend_sw_internal.tri_cache_3d);
          end
        else begin
          rend_install_prim (rend_sw_tri_cache2_3d_d, rend_sw_internal.tri_cache_3d);
          end
        ;
      end
    else begin
      if rend_ray.save_on
        then begin                     {primitives are being saved for ray tracing}
          rend_install_prim (
            rend_sw_tri_cache_ray_3d_d, rend_sw_internal.tri_cache_3d);
          end
        else begin                     {not saving primitives for ray tracing}
          rend_install_prim (
            rend_sw_tri_cache_3d_d, rend_sw_internal.tri_cache_3d);
          end
        ;
      end
    ;
{
*   Install REND_PRIM.SPHERE_3D
}
  if
      rend_ray.save_on and             {primitives being saved for ray tracing ?}
      rend_xf3d.rot_scale              {3D to 3DW transform preserves sphere ?}
    then begin
      rend_install_prim (rend_sw_sphere_ray_3d_d, rend_sw_prim.sphere_3d);
      end
    else begin
      rend_install_prim (rend_sw_sphere_3d_d, rend_sw_prim.sphere_3d);
      end
    ;
{
*   Install REND_GET.LIGHT_EVAL.
}
  ok :=                                {TRUE on minimum requirements}
    rend_face_front.on and             {FRONT surface property enabled ?}
    rend_face_front.diff_on and        {diffuse on ?}
    (not rend_face_front.emis_on) and  {emiffive off ?}
    (not rend_face_front.trans_on) and {transparency off ?}
    (not rend_face_front.spec_on) and  {specular off ?}
    (not rend_alpha_on) and            {alpha buffering off ?}
    (rend_diff_p_ind < 0);             {per vertex diffuse colors disabled ?}
  if ok and rend_face_back.on then begin {need to check out back suprop ?}
    ok :=
      rend_face_back.diff_on and       {diffuse on ?}
      (not rend_face_back.emis_on) and {emiffive off ?}
      (not rend_face_back.trans_on) and {transparency off ?}
      (not rend_face_back.spec_on);    {specular off ?}
    end;
  if ok
    then begin
      if
          (rend_lights.n_dir = 1) and  {exactly one directional light ?}
          (rend_lights.n_amb + rend_lights.n_dir = {all others are ambient ?}
            rend_lights.n_on)
        then begin
          rend_sw_get.light_eval := addr(rend_sw_get_light_eval3);
          end
        else begin
          rend_sw_get.light_eval := addr(rend_sw_get_light_eval2);
          end
        ;
      end
    else begin
      rend_sw_get.light_eval := addr(rend_sw_get_light_eval);
      end
    ;
  rend_get.light_eval := rend_sw_get.light_eval;
{
*   Install all the available dummy primitives if DUMPRIM benchmark flag set.
}
  if rend_bench_dumprim_k in rend_bench then begin {DUMPRIM benchmark flag set ?}
    rend_install_prim (rend_dummy_poly_2d_d, rend_sw_prim.poly_2d);
    rend_install_prim (rend_dummy_quad_3d_d, rend_sw_prim.quad_3d);
    rend_install_prim (rend_dummy_tri_3d_d, rend_sw_prim.tri_3d);
    rend_install_prim (rend_dummy_tstrip_3d_d, rend_sw_prim.tstrip_3d);

    rend_install_prim (rend_dummy_tri_cache_3d_d, rend_sw_internal.tri_cache_3d);
    end;

  if not rend_inhibit_check_modes2 then begin
    rend_internal.check_modes2^;       {clean up after installing routines}
    end;
  rend_inhibit_check_modes2 := false;  {automatically turn off CHECK_MODES2 inhibit}
  end;
