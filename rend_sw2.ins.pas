{   Private include file for the all-software device.  This file is
*   included in all the modules used to implement the SW device.
}
%include 'rend2.ins.pas';

procedure rend_sw_bench_init;          {init REND_BENCH flags}
  extern;

procedure rend_sw_bench_flags (        {explicitly set benchmark flags}
  in      flags: rend_bench_t);        {new benchmark flag settings}
  val_param; extern;

procedure rend_sw_text_pos_org;        {move TEXT origin to TXDRAW current point}
  extern;

function rend_sw_get_bench_flags       {return current benchmark flag settings}
  :rend_bench_t;
  extern;

procedure rend_sw_get_bxfpnt_3dpl (    {transform point from 3D to 3DPL space}
  in      ipnt: vect_3d_t;             {input point in 3D space}
  out     opnt: vect_2d_t);            {output point in 3DPL space}
  val_param; extern;

procedure rend_sw_get_xform_3dpl_2d (  {get 2D transform in 3D current plane}
  out     xb: vect_2d_t;               {X basis vector}
  out     yb: vect_2d_t;               {Y basis vector}
  out     ofs: vect_2d_t);             {offset vector}
  extern;

procedure rend_sw_get_xform_3dpl_plane ( {get definition of current plane in 3D space}
  out     org: vect_3d_t;              {origin for 2D space}
  out     xb: vect_3d_t;               {X basis vector}
  out     yb: vect_3d_t);              {Y basis vector}
  extern;

procedure rend_sw_get_xfpnt_3dpl (     {transform point from 3DPL to 3D space}
  in      ipnt: vect_2d_t;             {input point in 3DPL space}
  out     opnt: vect_3d_t);            {output point in 3D space}
  val_param; extern;

procedure rend_sw_get_light_eval (     {get point color by doing lighting evaluation}
  in      vert: univ rend_vert3d_t;    {vertex descriptor to find colors at}
  in out  ca: rend_vcache_t;           {cache data for this vertex}
  in      norm: vect_3d_t;             {unit normal vector at point}
  in      sp: rend_suprop_t);          {visual surface properties descriptor block}
  extern;

procedure rend_sw_get_light_eval2 (    {optimized version for REND_GET.LIGHT_EVAL}
  in      vert: univ rend_vert3d_t;    {vertex descriptor to find colors at}
  in out  ca: rend_vcache_t;           {cache data for this vertex}
  in      norm: vect_3d_t;             {unit normal vector at point}
  in      sp: rend_suprop_t);          {visual surface properties descriptor block}
  extern;

procedure rend_sw_get_light_eval3 (    {optimized version for REND_GET.LIGHT_EVAL}
  in      vert: univ rend_vert3d_t;    {vertex descriptor to find colors at}
  in out  ca: rend_vcache_t;           {cache data for this vertex}
  in      norm: vect_3d_t;             {unit normal vector at point}
  in      sp: rend_suprop_t);          {visual surface properties descriptor block}
  extern;
