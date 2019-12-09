{   Subroutine REND_SW_GET_RAY_BOUNDS_3DW (
*     XMIN, XMAX, YMIN, YMAX, ZMIN, ZMAX, STAT)
*
*   Return the 3D world space axis-aligned minimal bounding box around
*   all the primitives currently saved for ray tracing.  The values should
*   be considered garbage when STAT is set to other than normal completion.
}
module rend_sw_get_ray_bounds_3dw;
define rend_sw_get_ray_bounds_3dw;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_ray_bounds_3dw ( {get current bounds of saved ray primitives}
  out     xmin, xmax: real;            {3D world space axis-aligned bounding box}
  out     ymin, ymax: real;
  out     zmin, zmax: real;
  out     stat: sys_err_t);            {completion status code}

begin
  if
      (not rend_ray.init) or           {ray tracing state not initialized yet ?}
      (rend_ray.xmin > rend_ray.xmax)  {bounds not set yet ?}
      then begin
    sys_stat_set (rend_subsys_k, rend_stat_ray_no_bounds_k, stat);
    return;
    end;

  sys_error_none (stat);               {init to no error}

  xmin := rend_ray.xmin;               {return the bounds}
  xmax := rend_ray.xmax;
  ymin := rend_ray.ymin;
  ymax := rend_ray.ymax;
  zmin := rend_ray.zmin;
  zmax := rend_ray.zmax;
  end;
