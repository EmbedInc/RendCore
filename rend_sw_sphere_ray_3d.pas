{   Subroutine REND_SW_SPHERE_RAY_3D (X, Y, Z, R)
*
*   Draw the sphere at point X,Y,Z with radius R.
*
*   This version of the SPHERE_3D primitive adds the sphere to the list of
*   objects being collected for later ray tracing.
*
*   This routine must only be installed under the following circumstances.
*
*     1 - Primitives are currently being saved for ray tracing.  This means
*         REND_RAY.SAVE_ON must be TRUE.
*
*     2 - The current 3D to 3DW transform must represent only a rotation and
*         uniform scaling.  This means REND_XF3D.ROT_SCALE must be TRUE.
*
*   PRIM_DATA prim_call rend_sw_ray_trace_2dimi
}
module rend_sw_sphere_ray_3d;
define rend_sw_sphere_ray_3d;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_sphere_ray_3d_d.ins.pas';

procedure rend_sw_sphere_ray_3d (      {draw a sphere, saves prim for ray tracing}
  in      x, y, z: real;               {sphere center point}
  in      r: real);                    {radius}
  val_param;

var
  sph: type1_sphere_crea_data_t;       {data for creating a SPHERE ray tracer object}
  obj_p: ray_object_p_t;               {pointer to object we will create}
  stat: sys_err_t;

begin
  if rend_ray.traced then begin        {traced some pixels with this octree ?}
    rend_message_bomb ('rend', 'rend_ray_already_traced', nil, 0);
    end;
{
*   Make sure the current visual properties block is up to date.
}
  if rend_ray.visprop_old then begin   {current visprop block is out of date}
    rend_sw_ray_visprop_new;           {create an up to date visprop block}
    end;
  rend_ray.visprop_used := true;       {we will be using this visprop block}
{
*   Fill in data for creating this sphere.
}
  sph.visprop_p := rend_ray.visprop_p; {pointer to current visual properties}

  sph.center.x :=                      {transform center point to 3DW space}
    x*rend_xf3d.xb.x + y*rend_xf3d.yb.x + z*rend_xf3d.zb.x + rend_xf3d.ofs.x;
  sph.center.y :=
    x*rend_xf3d.xb.y + y*rend_xf3d.yb.y + z*rend_xf3d.zb.y + rend_xf3d.ofs.y;
  sph.center.z :=
    x*rend_xf3d.xb.z + y*rend_xf3d.yb.z + z*rend_xf3d.zb.z + rend_xf3d.ofs.z;

  sph.radius := r * rend_xf3d.scale;   {adjust radius for 3D to 3DW space}
{
*   Create the ray tracer object.
}
  obj_p :=                             {allocate memory for the base object}
    ray_mem_alloc_perm (sizeof(obj_p^));
  obj_p^.class_p := addr(rend_ray.class_sph); {set pointer to obj routines}

  rend_ray.class_sph.create^ (         {create sphere object}
    obj_p^,                            {object to create}
    addr(sph),                         {user data about the object to create}
    stat);
  sys_error_abort (stat, 'ray', 'object_create', nil, 0);
  if obj_p^.data_p = nil then return;  {object got punted by create routine ?}

  rend_ray.top_obj.class_p^.add_child^ ( {add new sphere as child to top object}
    rend_ray.top_obj,                  {aggregate object to add sphere to}
    obj_p^);                           {object to be added}
{
*   The sphere has been successfully added to the top ray tracer aggregate
*   object.
*
*   Update the ray tracing saved primitives bounding box to include this sphere.
}
  rend_ray.xmin := min(rend_ray.xmin, sph.center.x - sph.radius);
  rend_ray.xmax := max(rend_ray.xmax, sph.center.x + sph.radius);
  rend_ray.ymin := min(rend_ray.ymin, sph.center.y - sph.radius);
  rend_ray.ymax := max(rend_ray.ymax, sph.center.y + sph.radius);
  rend_ray.zmin := min(rend_ray.zmin, sph.center.z - sph.radius);
  rend_ray.zmax := max(rend_ray.zmax, sph.center.z + sph.radius);
  end;
