{   Subroutine REND_SW_GET_LIGHT_EVAL3 (VERT, CA, NORM, SP)
*
*   Optimized version to implement REND_GET.LIGHT_EVAL public entry point.
*   This version may only be installed when all of the following conditions
*   are met:
*
*   1)  The front surface property is ON.  SP will therefore never be OFF.
*
*   2)  The diffuse surface property is ON in all enabled suprops blocks.
*
*   3)  All other surface properties are OFF in all enabled suprop blocks.
*
*   4)  Alpha buffering is OFF.
*
*   5)  Vertex descriptor diffuse override colors are disabled.
*
*   6)  There is only one non-ambient light source.  This light source
*       must be directional.
}
module rend_sw_get_light_eval3;
define rend_sw_get_light_eval3;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_light_eval3 (    {get point color by doing lighting evaluation}
  in      vert: univ rend_vert3d_t;    {vertex descriptor to find colors at}
  in out  ca: rend_vcache_t;           {cache data for this vertex}
  in      norm: vect_3d_t;             {unit normal vector at point}
  in      sp: rend_suprop_t);          {visual surface properties descriptor block}

var
  m: real;                             {mult factor for unitizing vectors}

begin
  m := max(0.0,                        {directional light coupling factor}
    (rend_lights.dir_p^.dir.x * norm.x) +
    (rend_lights.dir_p^.dir.y * norm.y) +
    (rend_lights.dir_p^.dir.z * norm.z));

  ca.color.red := sp.diff.red *        {calculate visible colors}
    (rend_lights.amb_red + m * rend_lights.dir_p^.dir_red);
  ca.color.grn := sp.diff.grn *
    (rend_lights.amb_grn + m * rend_lights.dir_p^.dir_grn);
  ca.color.blu := sp.diff.blu *
    (rend_lights.amb_blu + m * rend_lights.dir_p^.dir_blu);

  ca.shnorm.x := norm.x;               {save the shading normal in vertex cache}
  ca.shnorm.y := norm.y;
  ca.shnorm.z := norm.z;
  end;
