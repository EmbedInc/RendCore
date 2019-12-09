{   Subroutine REND_SW_RAY_DELETE
*
*   Delete all primitives saved for ray tracing and deallocate any resources
*   tied up by the ray tracer.  The RENDlib ray tracing state will be reset.
}
module rend_sw_ray_delete;
define rend_sw_ray_delete;
%include 'rend_sw2.ins.pas';

procedure rend_sw_ray_delete;          {delete all primitives saved for ray tracing}

begin
  if not rend_ray.init then return;    {nothing to delete ?}

  ray_close;                           {close ray library, release resources}

  rend_ray.callback := nil;            {reset to no application callback set}
  rend_ray.init := false;              {ray state will now be uninitialized}
  rend_ray.save_on := false;           {not saving primitives for later ray tracing}
  end;
