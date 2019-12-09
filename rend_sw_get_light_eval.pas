{   Subroutine REND_SW_GET_LIGHT_EVAL (VERT,CA,NORM,SP)
*
*   Evaluate the color/alpha for the vertex VERT.  NORM is the unit normal vector
*   at the vertex.  SP is the surface properties block to use.  CA is the cache
*   to use for this vertex, regardless of whether there is a valid cache pointer
*   in VERT.
}
module rend_sw_get_light_eval;
define rend_sw_get_light_eval;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_light_eval (     {get point color by doing lighting evaluation}
  in      vert: univ rend_vert3d_t;    {vertex descriptor to find colors at}
  in out  ca: rend_vcache_t;           {cache data for this vertex}
  in      norm: vect_3d_t;             {unit normal vector at point}
  in      sp: rend_suprop_t);          {visual surface properties descriptor block}

var
  ex, ey, ez: real;                    {unit vector to eye point}
  m: real;                             {mult factor for unitizing vectors}
  s: real;                             {COS of angle scale factor}
  spec_on: boolean;                    {TRUE if able to do specular}
  spx: real;                           {mult factor for specular reflection}
  bits: sys_int_machine_t;             {for doing specular exponentiation}
  lvx, lvy, lvz: real;                 {unit vector to light source}
  diff_red, diff_grn, diff_blu: real;  {diffuse surface color to use}
  lred, lgrn, lblu: real;              {effective light source colors here}
  l_p: rend_light_p_t;                 {pointer to current light source}

label
  next_light;

begin
  if not sp.on then begin              {this suprop block not enabled ?}
    ca.color.red := 0.25;              {pass back arbitrary color}
    ca.color.grn := 0.25;
    ca.color.blu := 0.25;
    if rend_alpha_on then ca.color.alpha := 1.0;
    return;
    end;

  if sp.emis_on                        {emissive color on/off ?}
    then begin                         {emissive on, init RGB with emissive color}
      ca.color.red := sp.emis.red;
      ca.color.grn := sp.emis.grn;
      ca.color.blu := sp.emis.blu;
      end
    else begin                         {emissive off, init RGB accumulators to black}
      ca.color.red := 0.0;
      ca.color.grn := 0.0;
      ca.color.blu := 0.0;
      end
    ;

  if sp.spec_on or rend_alpha_on then begin {will need eye vector later ?}
    ez := rend_view.eyedis - ca.z3dw;  {Z distance to eye point}
    m := 1.0/sqrt(                     {make mult factor for unit vector}
      sqr(ca.x3dw) + sqr(ca.y3dw) + sqr(ez));
    ex := -m*ca.x3dw;                  {make unit vector to eye point}
    ey := -m*ca.y3dw;
    ez := m*ez;
    end;

  if rend_iterps.alpha.on then begin   {need an alpha value here ?}
    if sp.trans_on                     {transparency turned on/off ?}
      then begin                       {transparency is turned on}
        if (rend_diff_p_ind >= 0) and then (vert[rend_diff_p_ind].diff_p <> nil)
          then begin                   {explicit RGBA values exist}
            ca.color.alpha :=          {grab alpha from explicit values in vertex}
              vert[rend_diff_p_ind].diff_p^.alpha;
            end
          else begin                   {no explicit RGBA, get from suprop block}
            s :=                       {COS between normal and eye vectors}
              abs(ex*norm.x + ey*norm.y + ez*norm.z);
            ca.color.alpha :=          {blended opaqueness between front and side}
              s*sp.trans_front + (1.0-s)*sp.trans_side;
            end
          ;
        end                            {done with transparency surf prop ON}
      else ca.color.alpha := 1.0;      {transparency off, assume fully opaque}
    end;                               {done with alpha component}

  if sp.spec_on                        {check for specular surface property on/off}
    then begin                         {specular is turned on}
      spec_on :=                       {allow specular only if surface facing eye}
        (ex*norm.x + ey*norm.y + ez*norm.z) > 0.0;
      end
    else begin                         {specular is turned off in suprop block}
      spec_on := false;                {indicate no specular}
      end
    ;

  if sp.diff_on then begin             {diffuse reflections turned on ?}
    if (rend_diff_p_ind < 0) or else (vert[rend_diff_p_ind].diff_p = nil)
      then begin                       {diffuse color comes from suprop block}
        diff_red := sp.diff.red;
        diff_grn := sp.diff.grn;
        diff_blu := sp.diff.blu;
        end
      else begin                       {diffuse color comes from vertex descriptor}
        diff_red := vert[rend_diff_p_ind].diff_p^.red;
        diff_grn := vert[rend_diff_p_ind].diff_p^.grn;
        diff_blu := vert[rend_diff_p_ind].diff_p^.blu;
        end
      ;
    end;

  l_p := rend_lights.on_p;             {init pointer to first light source}
  while l_p <> nil do begin            {keep looping until end of ON lights list}
    with l_p^:l do begin               {set up L abbreviation for the light source}
      case l.ltype of                  {different code for each type of light source}

rend_ltype_amb_k: begin                {ambient light source}
  if sp.diff_on then begin             {diffuse reflections turned on ?}
    ca.color.red := ca.color.red + (diff_red * l.amb_red);
    ca.color.grn := ca.color.grn + (diff_grn * l.amb_grn);
    ca.color.blu := ca.color.blu + (diff_blu * l.amb_blu);
    end;                               {done with diffuse color}
  goto next_light;                     {all done with this light source}
  end;

rend_ltype_dir_k: begin                {directional light source}
  lvx := l.dir.x;                      {unit vector to light source}
  lvy := l.dir.y;
  lvz := l.dir.z;
  lred := l.dir_red;                   {light source colors here}
  lgrn := l.dir_grn;
  lblu := l.dir_blu;
  end;

rend_ltype_pnt_k: begin                {point light source with no falloff}
  lvx := l.pnt.x - ca.x3dw;            {make vector to light source}
  lvy := l.pnt.y - ca.y3dw;
  lvz := l.pnt.z - ca.z3dw;
  m := sqr(lvx) + sqr(lvy) + sqr(lvz); {square of distance to light source}
  if m < 1.0E-20 then goto next_light; {too close, pretend it's on other side}
  m := 1.0 / sqrt(m);                  {mult factor to unitize light vector}
  lvx := lvx * m;                      {make unit vector to light source}
  lvy := lvy * m;
  lvz := lvz * m;
  lred := l.pnt_red;                   {light source colors here}
  lgrn := l.pnt_grn;
  lblu := l.pnt_blu;
  end;

rend_ltype_pr2_k: begin                {point light with 1/R**2 falloff}
  lvx := l.pr2_coor.x - ca.x3dw;       {make vector to light source}
  lvy := l.pr2_coor.y - ca.y3dw;
  lvz := l.pr2_coor.z - ca.z3dw;
  m := sqr(lvx) + sqr(lvy) + sqr(lvz); {square of distance to light source}
  if m < 1.0E-20 then goto next_light; {too close, pretend it's on other side}
  m := 1.0 / m;                        {1/R**2 to light source}
  s := l.pr2_r2 * m;                   {brightness adjust factor due to distance}
  if s < 0.002 then goto next_light;   {too dim, don't bother ?}
  m := sqrt(m);                        {mult factor to unitize light vector}
  lvx := lvx * m;                      {make unit vector to light source}
  lvy := lvy * m;
  lvz := lvz * m;
  lred := l.pr2_red * s;               {light source colors, adjusted for distance}
  lgrn := l.pr2_grn * s;
  lblu := l.pr2_blu * s;
  end;

        end;                           {done with all the lightsource type cases}
      end;                             {done with the L abbreviation}
{
*   The unit vector to the light source is LVX, LVY, LVZ, and the effective light
*   source colors at this point are LRED, LGRN, LBLU.  Now calculate diffuse
*   and specular reflections.
}
    m :=                               {COS of angle between surf normal and light}
      (lvx * norm.x) + (lvy * norm.y) + (lvz * norm.z);
    if m <= 0.0 then goto next_light;  {light source behind, go on to next one}

    if sp.diff_on then begin           {diffuse reflections turned on ?}
      ca.color.red := ca.color.red + (diff_red * lred * m);
      ca.color.grn := ca.color.grn + (diff_grn * lgrn * m);
      ca.color.blu := ca.color.blu + (diff_blu * lblu * m);
      end;                             {done with diffuse reflections}

    if spec_on then begin              {specular reflections turned on ?}
      m := m*2.0;                      {make multiplier for normal vector}
      s :=                             {COS between reflection and normal vectors}
        ex*(m*norm.x - lvx) +
        ey*(m*norm.y - lvy) +
        ez*(m*norm.z - lvz);
      if s > 0.0 then begin            {reflection not heading away from eye ?}
        spx := 1.0;                    {init S**IEXP multiplicative accumulator}
        m := s;                        {init multiplier to first power of S}
        bits := sp.iexp;               {make local copy of exponent}
        if (bits & 1) <> 0             {the bit for this power is on ?}
          then spx := spx*m;           {multiply in this S**(power of 2)}
        bits := rshft(bits, 1);        {shift next bit into position}
        while bits <> 0 do begin       {again until all 1 bits used up}
          m := sqr(m);                 {make S raised to next power of 2}
          if (bits & 1) <> 0           {the bit for this power is on ?}
            then spx := spx*m;         {multiply in this S**(power of 2)}
          bits := rshft(bits, 1);      {shift next bit into position}
          end;                         {back and do next 2**n power of S}
{
*   SPX is the final specular coupling factor from light source to pixel colors.
}
        ca.color.red := ca.color.red + (sp.spcol.red * spx * lred);
        ca.color.grn := ca.color.grn + (sp.spcol.grn * spx * lgrn);
        ca.color.blu := ca.color.blu + (sp.spcol.blu * spx * lblu);
        end;                           {done with reflection is towards eye point}
      end;                             {done with specular reflections}

next_light:                            {jump here to go on to next light source}
    l_p := l_p^.next_on_p;             {advance to next light source}
    end;                               {back and do this new light source}

  ca.shnorm.x := norm.x;               {save the shading normal in vertex cache}
  ca.shnorm.y := norm.y;
  ca.shnorm.z := norm.z;
  end;
