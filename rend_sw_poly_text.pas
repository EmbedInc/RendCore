{   Subroutine REND_SW_POLY_TEXT (N,VERTS)
*
*   Draw a polygon in the TEXT coordinate space.  The polygon is assumed to be
*   convex and counter-clockwise.
}
module rend_sw_poly_text;
define rend_sw_poly_text;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_poly_text_d.ins.pas';

procedure rend_sw_poly_text (          {convex polygon}
  in      n: sys_int_machine_t;        {number of verticies in VERTS}
  in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
  val_param;

var
  v2: rend_2dverts_t;                  {transformed verticies}
  i: sys_int_machine_t;                {loop counter}
  j: sys_int_machine_t;                {output vertex counter}

begin
  if rend_text_state.sp.right          {check handedness of TEXT transform}
    then begin                         {TEXT transform is right handed}
      for i := 1 to n do begin         {traverse the verticies forward}
        v2[i].x :=                     {transform this vertex from text to draw space}
          verts[i].x*rend_text_state.sp.xb.x +
          verts[i].y*rend_text_state.sp.yb.x +
          rend_text_state.sp.ofs.x;
        v2[i].y :=
          verts[i].x*rend_text_state.sp.xb.y +
          verts[i].y*rend_text_state.sp.yb.y +
          rend_text_state.sp.ofs.y;
        end;                           {back for next vertex}
      end
    else begin                         {TEXT transform is left handed}
      j := 0;                          {init number of output verticies}
      for i := n downto 1 do begin     {traverse the verticies backward}
        j := j+1;                      {make index for this output vertex}
        v2[j].x :=                     {transform this vertex from text to draw space}
          verts[i].x*rend_text_state.sp.xb.x +
          verts[i].y*rend_text_state.sp.yb.x +
          rend_text_state.sp.ofs.x;
        v2[j].y :=
          verts[i].x*rend_text_state.sp.xb.y +
          verts[i].y*rend_text_state.sp.yb.y +
          rend_text_state.sp.ofs.y;
        end;                           {back for next vertex}
      end
    ;
  rend_prim.poly_txdraw^ (n, v2);      {pass transformed polygon on to next space}
  end;
