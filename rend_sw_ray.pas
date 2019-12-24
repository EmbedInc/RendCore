module rend_sw_ray;
define rend_sw_ray_callback;
define rend_sw_get_ray_callback;
define rend_sw_ray_save;
%include 'rend_sw2.ins.pas';
{
*********************************************************
*
*   Subroutine REND_SW_RAY_CALLBACK (P)
*
*   Set an application routine to call to resolve a ray.  This application
*   routine will be called after the ray has already been resolved for all
*   known primitives.  Set to NIL to prevent calling any external routine
*   while ray tracing.
}
procedure rend_sw_ray_callback (       {set application routine that resolves rays}
  in      p: rend_raytrace_p_t);       {routine pointer or NIL to disable}
  val_param;

begin
  rend_ray.callback := p;              {save pointer to application routine}
  end;
{
*********************************************************
*
*   Function REND_SW_GET_RAY_CALLBACK
*
*   Returns a pointer to the application routine that will be called to
*   resolve rays.  NIL indicates that no such routine is set.
}
function rend_sw_get_ray_callback      {return current ray callback entry point}
  :rend_raytrace_p_t;                  {routine pointer or NIL for none}

begin
  rend_sw_get_ray_callback := rend_ray.callback;
  end;
{
*********************************************************
*
*   Subroutine REND_SW_RAY_SAVE (ON)
*
*   Turn ON/OFF primitive saving for later ray tracing.  The 3DW ray bounds must
*   already be set correctly.
}
procedure rend_sw_ray_save (           {turn primitive saving for ray tracing ON/OFF}
  in      on: boolean);                {TRUE will cause primitives to be saved}
  val_param;

var
 crea_oct: type1_octree_crea_data_t;   {octree creation data}
  stat: sys_err_t;                     {error status}

begin
  if rend_ray.save_on = on then return; {mode already set this way ?}
  rend_ray.save_on := on;              {set ON/OFF switch to new setting}

  if not rend_ray.init then begin      {ray state never initialized ?}
    rend_ray.init := true;             {now it will be initialized}

    rend_ray.xmin := 1.0E35;           {set bounds to invalid}
    rend_ray.xmax := -1.0E35;
    rend_ray.ymin := 1.0E35;
    rend_ray.ymax := -1.0E35;
    rend_ray.zmin := 1.0E35;
    rend_ray.zmax := -1.0E35;

    rend_ray.traced := false;          {no pixels generated with this setup yet}
    rend_ray.visprop_old := true;      {need to make new visprop block next use}
    rend_ray.visprop_used := true;     {need to allocate new visprop block next use}
    rend_ray.visprop_p := nil;         {cause error if try to use without fixing}
    ray_init (                         {initialize ray tracer library}
      rend_device[rend_dev_id].mem_p^); {handle to parent memory context}
    type1_octree_routines_make (       {fill in pointers to OCTREE object routines}
      rend_ray.routines_oct);
    type1_tri_routines_make (          {fill in pointers to TRI object routines}
      rend_ray.routines_tri);
    type1_sphere_routines_make (       {fill in pointers to SPHERE object routines}
      rend_ray.routines_sph);
{
*   Set up our top level object.
}
    crea_oct.shader := nil;            {data for OCTREE object}
    crea_oct.liparm_p := nil;
    crea_oct.visprop_p := nil;
    crea_oct.min_gen := 0;
    crea_oct.max_gen := 8;
    crea_oct.min_miss := 2;
    crea_oct.origin.x := -1.0;         {set temp bounds, will be reset later}
    crea_oct.origin.y := -1.0;
    crea_oct.origin.z := -1.0;
    crea_oct.size.x := 2.0;
    crea_oct.size.y := 2.0;
    crea_oct.size.z := 2.0;
    rend_ray.top_obj.routines_p :=
      addr(rend_ray.routines_oct);
    rend_ray.routines_oct.create^ (    {create top level aggregate object}
      rend_ray.top_obj,                {object to create}
      crea_oct,                        {creation data for this object}
      stat);
    sys_error_abort (stat, 'ray', 'object_create', nil, 0);
{
*   Set up root runtime parameters.
}
    rend_ray.top_parms.shader :=
      ray_shader_t(addr(type1_shader_phong));
    rend_ray.top_parms.liparm_p := nil; {this will be allocated when used}
    rend_ray.top_parms.visprop_p := nil; {cause error if try to use without setting}
{
*   Set up parameters for background shader.
}
    rend_ray.backg_parms.col.red := 0.0;
    rend_ray.backg_parms.col.grn := 0.0;
    rend_ray.backg_parms.col.blu := 0.0;
    rend_ray.backg_parms.col.alpha := 0.0;
    rend_ray.backg_parms.liparm_p :=
      rend_ray.top_parms.liparm_p;
{
*   Set up root context for each ray.
}
    rend_ray.context.top_level_obj_p := {set address of top level object}
      addr(rend_ray.top_obj);
    rend_ray.context.object_parms_p := {set address of root run time parameters}
      ray_object_parms_p_t(addr(rend_ray.top_parms));
    rend_ray.context.backg_shader :=   {point to shader that gets background color}
      ray_shader_t(addr(type1_shader_fixed));
    rend_ray.context.backg_hit_info.object_p := nil;
    rend_ray.context.backg_hit_info.distance := 1.0E35;
    rend_ray.context.backg_hit_info.shader_parms_p :=
      ray_shader_parms_p_t(addr(rend_ray.backg_parms));
    rend_ray.context.backg_hit_info.enter := true;
    end;                               {done initializing ray tracing state}

  rend_internal.check_modes^;          {some state got changed}
  end;
