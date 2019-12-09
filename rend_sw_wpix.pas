{   Subroutine REND_SW_WPIX
*
*   Draw the current values at the current color.  This subroutine takes care of
*   the low level pixel operations once the interpolant value and address have been
*   computed for each interpolant.
*
*   PRIM_DATA sw_read yes
*   PRIM_DATA sw_write yes
}
module rend_sw_wpix;
define rend_sw_wpix;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_wpix_d.ins.pas';

procedure rend_sw_wpix;

const
  max_msg_parms = 1;                   {max parameters we can pass to a message}

var
  z_enab: boolean;                     {TRUE if no Z, or Z compare allowed write}
  old_z: integer32;                    {old Z buffer value from the pixel}
  new_z: integer32;                    {new Z buffer value from the Z interpolator}
  iterp_n: sys_int_machine_t;          {current interpolant number}
  iterp_val: rend_iterp_val_t;         {final value from interpolant}
  old_val: rend_iterp_val_t;           {old pixel value before write}
  new_pval: rend_iterp_val_t;          {new pixel value after write}
  old_afact, new_afact:                {16.16 mult factors for alpha buffering}
    integer32;
  old_alpha, new_alpha:                {old and new 16.16 alpha values}
    integer32;
  maxd: sys_int_conv32_t;              {max texture map index derivative}
  u1, v1, u2, v2: sys_int_conv16_t;    {source texture map indicies}
  u1r, v1d, u2r, v2d: sys_int_conv16_t; {right or down tmap indicies for blend}
  lev1, lev2: sys_int_conv8_t;         {0 to Log2(size) texture map sizes}
  tm1, tm2: sys_int_conv32_t;          {16.16 blend factors for the two texture maps}
  tm1r, tm1d, tm1rd: sys_int_conv32_t; {horizontal blend factors for LEV1 map}
  tm2r, tm2d, tm2rd: sys_int_conv32_t; {horizontal blend factors for LEV2 map}
  ml1, ml2: sys_int_conv32_t;          {tmap LEVn factors when horiz blending}
  m: sys_int_conv32_t;                 {scratch integer mult factor}
  mask: sys_int_conv32_t;              {scratch bit mask}
  ofs, ofs2: sys_int_adr_t;            {scratch address offset}
  adr: rend_iterp_data_pnt_t;          {source texture pixel value address}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;

label
  got_tmap_levels, done_tmap, new_span;

begin
{
*****************************
*
*   Return if this pixel is inhibited due to a Z compare.
}
  if                                   {Z buffering on, and Z bitmap exists ?}
      rend_zon and (rend_iterps.z.bitmap_p <> nil)
      then begin
    case rend_iterps.z.width of        {different code for each possible width of Z}
8:    begin
        old_z := ord(rend_iterps.z.curr_adr.p8^);
        new_z := rend_iterps.z.value.val8;
        end;
16:   begin
        old_z := rend_iterps.z.curr_adr.p16^;
        new_z := rend_iterps.z.value.val16;
        end;
32:   begin
        old_z := rend_iterps.z.curr_adr.p32^;
        new_z := rend_iterps.z.value.all;
        end;
      end;                             {done with the data width cases}
    case rend_zfunc of                 {different code for each possible Z function}
rend_zfunc_never_k: z_enab := false;
rend_zfunc_gt_k: z_enab := new_z > old_z;
rend_zfunc_ge_k: z_enab := new_z >= old_z;
rend_zfunc_eq_k: z_enab := new_z = old_z;
rend_zfunc_ne_k: z_enab := new_z <> old_z;
rend_zfunc_le_k: z_enab := new_z <= old_z;
rend_zfunc_lt_k: z_enab := new_z < old_z;
rend_zfunc_always_k: z_enab := true;
      end;                             {done with all the Z function cases}
    if not z_enab then return;         {all writes inhibited by the Z buffer ?}
    end;                               {done handling Z compares enabled}
{
*****************************
*
*   Compute the alpha buffer multiply factors if alpha buffering is turned on.
}
  if rend_alpha_on then begin          {alpha buffering is enabled}
    if rend_iterps.alpha.bitmap_p = nil {check for alpha bitmap existance}
      then begin                       {alpha bitmap does not exist}
        old_alpha := 65536;            {default to 1.0 (opaque)}
        end
      else begin                       {alpha bitmap does exist}
        old_alpha :=                   {fetch 8 bit alpha pixel value}
          ord(rend_iterps.alpha.curr_adr.p8^);
        old_alpha :=                   {make best 16.16 fixed point approximation}
          lshft(old_alpha, 8) + old_alpha + rshft(old_alpha, 1);
        end
      ;                                {done handling alpha bitmap existance cases}
    new_alpha := rend_iterps.alpha.value.all div 256; {16.16 interpolated alpha value}
    case rend_afunc of                 {different code for each alpha function}
rend_afunc_clear_k: begin              {val = NEW(0) + OLD(0)}
        new_afact := 0;
        old_afact := 0;
        end;
rend_afunc_a_k: begin                  {val = NEW(1) + OLD(0)}
        new_afact := 65536;
        old_afact := 0;
        end;
rend_afunc_b_k: begin                  {val = NEW(0) + OLD(1)}
        new_afact := 0;
        old_afact := 65536;
        end;
rend_afunc_over_k: begin               {val = NEW(1) + OLD(1-Anew)}
        new_afact := 65536;
        old_afact := 65536 - new_alpha;
        end;
rend_afunc_rover_k: begin              {val = NEW(1-Aold) + OLD(1)}
        new_afact := 65536 - old_alpha;
        old_afact := 65536;
        end;
rend_afunc_in_k: begin                 {val = NEW(Aold) + OLD(0)}
        new_afact := old_alpha;
        old_afact := 0;
        end;
rend_afunc_rin_k: begin                {val = NEW(0) + OLD(Anew)}
        new_afact := 0;
        old_afact := new_alpha;
        end;
rend_afunc_out_k: begin                {val = NEW(1-Aold) + OLD(0)}
        new_afact := 65536 - old_alpha;
        old_afact := 0;
        end;
rend_afunc_rout_k: begin               {val = NEW(0) + OLD(1-Anew)}
        new_afact := 0;
        old_afact := 65536 - new_alpha;
        end;
rend_afunc_atop_k: begin               {val = NEW(Aold) + OLD(1-Anew)}
        new_afact := old_alpha;
        old_afact := 65536 - new_alpha;
        end;
rend_afunc_ratop_k: begin              {val = NEW(1-Aold) + OLD(Anew)}
        new_afact := 65536 - old_alpha;
        old_afact := new_alpha;
        end;
rend_afunc_xor_k: begin                {val = NEW(1-Aold) + OLD(1-Anew)}
        new_afact := 65536 - old_alpha;
        old_afact := 65536 - new_alpha;
        end;
otherwise
      sys_msg_parm_int (msg_parm[1], ord(rend_afunc));
      rend_message_bomb ('rend', 'rend_alpha_func_bad', msg_parm, 1);
      end;                             {end of alpha function ID cases}
    end;                               {done handling alpha buffering turned on}
{
*****************************
*
*   Set the texture map index coordinates and mult factors for the values from
*   those coordinates.  This logic determines which two texture map sizes should
*   be blended to arrive at the final texture source value for the pixel.
*
*   The values U1, V1, LEV1, and TM1 will describe one map, and U2, V2, LEV2,
*   TM2 the other.  U,V will be the X and Y pixel offsets from the origin of
*   the map at level LEV.  TM will be the mult factor for the value from the
*   associated map.  The TM values will have 16 bits below the binary point.
*
*   Note that the texture map index interpolants are 0 to 1 values simulated
*   with 3.29 integers.
}
  if rend_tmap.on then begin           {texture mapping turned on ?}
    case rend_tmap.dim of              {find code for different tmap source iterps}
rend_tmapd_u_k: begin                  {just U is index}
        maxd := abs(rend_u.dx.all);    {find max of all relevant derivatives}
        maxd := max(maxd, rend_u.dy.all);
        u1 := rshft(
          rend_iterps.u.value.all & 16#1FFFFFFF, {mask in 0-1 fraction part}
          29 - rend_max_iterp_tmap);   {leave max possible useable bits}
        v1 := 0;
        end;
rend_tmapd_uv_k: begin                 {U and V are texture map indicies}
        maxd := abs(rend_u.dx.all);    {find max of all relevant derivatives}
        maxd := max(maxd, rend_u.dy.all);
        maxd := max(maxd, rend_v.dx.all);
        maxd := max(maxd, rend_v.dy.all);
        u1 := rshft(
          rend_iterps.u.value.all & 16#1FFFFFFF, {mask in 0-1 fraction part}
          29 - rend_tmap.mip.max_map); {leave max necessary useable bits}
        v1 := rshft(
          rend_iterps.v.value.all & 16#1FFFFFFF, {mask in 0-1 fraction part}
          29 - rend_tmap.mip.max_map); {leave max necessary useable bits}
        end;
otherwise
      rend_message_bomb ('rend', 'rend_tmap_dim_bad', nil, 0);
      end;                             {done with texture map dimension cases}
    maxd := rshft(maxd, 29-rend_tmap.mip.max_map-8); {init for min filt level}
{
*   MAXD is the maximum texture map index stride for one image pixel step
*   up, down, left or right.  It is scaled such that there are MAX_MAP+8
*   bits below the binary point.  The extra 8 bits are used to blend between
*   the first chosen map and the next smaller map.
*
*   U1 and V1 are the integer texture map X and Y source offsets.  They are
*   scaled to be the offset into the largest enabled map.  They therefore
*   have values in the range zero to 2**MAX_MAP - 1.
}
    if maxd < 256 then begin           {really wants larger map than available ?}
      lev1 := rend_tmap.mip.max_map;   {select largest map}
      lev2 := lev1;                    {don't blend between maps}
      goto got_tmap_levels;            {LEV1, LEV2 all set}
      end;

    for                                {from largest to smallest available maps}
        lev1 := rend_tmap.mip.max_map downto rend_tmap.mip.min_map+1
        do begin
      if maxd <= 511 then begin        {deriv small enough for this level ?}
        if rend_tmapfilt_maps_k in rend_tmap.filt
          then begin                   {blending between maps is enabled}
            lev2 := lev1 - 1;          {indicate next lower level to blend with}
            end
          else begin                   {blending between maps is explicitly disabled}
            lev1 := lev1 - 1;          {pick most conservative map}
            lev2 := lev1;
            end
          ;
        goto got_tmap_levels;          {LEV1, LEV2 all set}
        end;
      maxd := rshft(maxd, 1);          {position derivative for next level}
      end;                             {back and check next level}

    lev1 := rend_tmap.mip.min_map;     {use smallest available map without blending}
    lev2 := lev1;
got_tmap_levels:                       {LEV1 and LEV2 are all set}
{
*   LEV1 and LEV2 are all set.  If there were no other restrictions, then
*   LEV1 indicates the map where the maximum pixel stride is from 1 up to
*   2 texils.  LEV2 indicates the map where the pixel stride is from 1/2 to 1
*   texil.  LEV1 and LEV2 are clipped to the range of available maps.  LEV2
*   is also set to the LEV1 value if blending between maps is disabled.
}
    u1 := rshft(u1, rend_tmap.mip.max_map - lev1); {scale U and V for level 1 index}
    v1 := rshft(v1, rend_tmap.mip.max_map - lev1);

    if lev2 = lev1
      then begin                       {using just one map, no blending}
        u2 := u1;                      {indexing into same map}
        v2 := v1;
        tm1 := 65536;                  {100% weighting to map 1}
        tm2 := 0;
        end
      else begin                       {blending between two maps}
        u2 := rshft(u1, 1);            {make index into smaller map}
        v2 := rshft(v1, 1);
        maxd := maxd & 255;            {mask in blending fraction bits}
        tm1 := rend_tmap.mip.blend[maxd];
        tm2 := 65536 - tm1;            {mult fractions always add to 1}
        end
      ;
{
*   Handle blending between adjacent textils within maps, if enabled.
*   This will result in eight weighting factors being set, one for each
*   of the possible eight source texils that are blended to comprise the
*   final texture map value at this pixel.  The weighting factors will all
*   be in fixed point format with 16 bits below the point.
}
    if rend_tmapfilt_pix_k in rend_tmap.filt then begin {blend within maps enabled ?}
      mask := ~lshft(~0, lev1);        {make texil address mask for this level}
      ml1 := tm1;                      {save old .16 weight for whole level}
      tm1 := rshft(tm1, 8);            {adjust map weight from fixed pnt .16 to .8}

      m :=                             {24.8 address from left texil center}
        rshft(rend_iterps.u.value.all, 21 - lev1) - 128;
      u1 := rshft(m, 8) & mask;        {texil address for left of blend pair}
      u1r := (u1 + 1) & mask;          {texil address for right of blend pair}
      tm1r := m & 255;                 {24.8 weight for right blend pair}

      m :=                             {24.8 address from top texil center}
        rshft(rend_iterps.v.value.all, 21 - lev1) - 128;
      v1 := rshft(m, 8) & mask;        {texil address for top of blend pair}
      v1d := (v1 + 1) & mask;          {texil address for bottom of blend pair}
      m := m & 255;                    {24.8 weight for lower blend pair}

      tm1rd :=                         {16.16 weight for lower right texil this map}
        rshft(tm1 * tm1r * m, 8);
      tm1d :=                          {16.16 weight for lower left texil this map}
        rshft(tm1 * (256 - tm1r) * m, 8);
      tm1r :=                          {16.16 weight for upper right texil this map}
        rshft(tm1 * tm1r * (256 - m), 8);
      tm1 :=                           {16.16 weight for upper left texil this map}
        65536 - tm2 - tm1r - tm1rd - tm1d; {all remaining weight for this map}

      ml2 := tm2;                      {save old .16 weight for whole level}
      if tm2 <> 0 then begin           {we are blending between two maps ?}
        mask := rshft(mask, 1);        {make texil address mask for this level}
        tm2 := rshft(tm2, 8);          {adjust map weight from fixed pnt .16 to .8}

        m :=                           {24.8 address from left texil center}
          rshft(rend_iterps.u.value.all, 21 - lev2) - 128;
        u2 := rshft(m, 8) & mask;      {texil address for left of blend pair}
        u2r := (u2 + 1) & mask;        {texil address for right of blend pair}
        tm2r := m & 255;               {24.8 weight for right blend pair}

        m :=                           {24.8 address from top texil center}
          rshft(rend_iterps.v.value.all, 21 - lev2) - 128;
        v2 := rshft(m, 8) & mask;      {texil address for top of blend pair}
        v2d := (v2 + 1) & mask;        {texil address for bottom of blend pair}
        m := m & 255;                  {24.8 weight for lower blend pair}

        tm2rd :=                       {16.16 weight for lower right texil this map}
          rshft(tm2 * tm2r * m, 8);
        tm2d :=                        {16.16 weight for lower left texil this map}
          rshft(tm2 * (256 - tm2r) * m, 8);
        tm2r :=                        {16.16 weight for upper right texil this map}
          rshft(tm2 * tm2r * (256 - m), 8);
        tm2 :=                         {16.16 weight for upper left texil this map}
          65536 - ml1 - tm2r - tm2rd - tm2d; {all remaining weight for this map}
        end;
      end;                             {done handling blending within maps}
    end;                               {done handling texture mapping turned on}
{
*****************************
*
*   Loop thru each enabled interpolant and write to its bitmap.
}
  for iterp_n := 1 to rend_iterps.n_on do begin {once for each enabled interpolant}
    with rend_iterps.list_on[iterp_n]^:iterp do begin {set up ITERP abbreviation}
{
*   The following abbreviations are in effect:
*     ITERP - The current interpolant data block.
}
  if (iterp.pixfun = rend_pixfun_insert_k) {check for the common and easy case}
      and (iterp.bitmap_p <> nil)
      and (iterp.wmask = -1)
      and (not rend_alpha_on)
      and (not rend_tmap.on)
      then begin
    case iterp.width of                {different write code for each width}
8:    iterp.curr_adr.p8^ := chr(iterp.value.val8);
16:   iterp.curr_adr.p16^ := iterp.value.val16;
32:   iterp.curr_adr.p32^ := iterp.value.val32;
      end;                             {end of different width cases}
    next;                              {nothing more to do for this interpolant}
    end;                               {done with simple and easy case}

  if iterp.wmask = 0 then next;        {skip this interpolant if write mask all zero}
  if iterp.bitmap_p = nil then next;   {skip this interpolant if no bitmap exists}

  case iterp.width of                  {fetch pixel differently for each width}
8: begin                               {interpolant is 8 bits wide}
      old_val.all := 0;
      old_val.val16 := ord(iterp.curr_adr.p8^); {fetch old pixel value}
      iterp_val.all := 0;
      iterp_val.val8 := iterp.value.val8; {fetch integer part of interpolant value}
{
*   Handle texture mapping, if enabled.
}
      if rend_tmap.on then begin       {texture mapping turned on ?}
        if iterp.tmap[lev1].bitmap = nil then goto done_tmap; {tmaps not here ?}
        if iterp.tmap[lev2].bitmap = nil then goto done_tmap;
        with
            iterp.tmap[lev1].bitmap^: b1, {B1 is LEV1 tmap source bitmap}
            iterp.tmap[lev2].bitmap^: b2 {B2 is LEV2 tmap source bitmap}
            do begin
          if rend_tmapfilt_pix_k in rend_tmap.filt
            then begin                 {blend between nearest pixels within maps}
{
*   Fetch and accumulate values from LEV1 texture map.
}
  ofs :=                               {offset into scan line for left texils}
    (u1 + iterp.tmap[lev1].x_orig) * b1.x_offset + {pixels into scan line}
    iterp.tmap[lev1].iterp_offset;     {bytes into pixel}
  adr.i :=                             {make adr of top left texil from first map}
    sys_int_adr_t(b1.line_p[v1 + iterp.tmap[lev1].y_orig]) + {scan start adr}
    ofs;                               {offset into scan line}
  iterp_val.all := ord(adr.p8^) * tm1; {init val with weighted top left pixel}

  ofs2 := (u1r - u1) * b1.x_offset;    {adr delta from left to right texils}
  adr.i := adr.i + ofs2;               {make address of top right pixel}
  iterp_val.all :=                     {add in contribution from this texil}
    iterp_val.all + ord(adr.p8^) * tm1r;

  adr.i :=                             {make adr of top left texil from first map}
    sys_int_adr_t(b1.line_p[v1d + iterp.tmap[lev1].y_orig]) + {scan start adr}
    ofs;                               {offset into scan line}
  iterp_val.all :=                     {add in contribution from this texil}
    iterp_val.all + ord(adr.p8^) * tm1d;

  adr.i := adr.i + ofs2;               {make address of top right pixel}
  iterp_val.all :=                     {add in contribution from this texil}
    iterp_val.all + ord(adr.p8^) * tm1rd;
{
*   Fetch and accumulate values from LEV2 texture map, if weight isn't zero.
}
  if ml2 <> 0 then begin               {LEV2 map has non-zero weight ?}
    ofs :=                             {offset into scan line for left texils}
      (u2 + iterp.tmap[lev2].x_orig) * b2.x_offset + {pixels into scan line}
      iterp.tmap[lev2].iterp_offset;   {bytes into pixel}
    adr.i :=                           {make adr of top left texil from first map}
      sys_int_adr_t(b2.line_p[v2 + iterp.tmap[lev2].y_orig]) + {scan start adr}
      ofs;                             {offset into scan line}
    iterp_val.all :=                   {add in contribution from top left texil}
      iterp_val.all + ord(adr.p8^) * tm2;

    ofs2 := (u2r - u2) * b2.x_offset;  {adr delta from left to right texils}
    adr.i := adr.i + ofs2;             {make address of top right pixel}
    iterp_val.all :=                   {add in contribution from this texil}
      iterp_val.all + ord(adr.p8^) * tm2r;

    adr.i :=                           {make adr of top left texil from first map}
      sys_int_adr_t(b2.line_p[v2d + iterp.tmap[lev2].y_orig]) + {scan start adr}
      ofs;                             {offset into scan line}
    iterp_val.all :=                   {add in contribution from this texil}
      iterp_val.all + ord(adr.p8^) * tm2d;

    adr.i := adr.i + ofs2;             {make address of top right pixel}
    iterp_val.all :=                   {add in contribution from this texil}
      iterp_val.all + ord(adr.p8^) * tm2rd;
    end;                               {done adding contribution from LEV2 map}

              end                      {end of horizontal blending enabled case}
            else begin                 {blend only between maps}
              adr.i :=                 {make address of texture value from map 1}
                sys_int_adr_t(b1.line_p[v1 + iterp.tmap[lev1].y_orig]) + {scan start adr}
                (u1 + iterp.tmap[lev1].x_orig) * b1.x_offset + {pixels into scan line}
                iterp.tmap[lev1].iterp_offset; {bytes into pixel}
              iterp_val.all :=         {init to value from LEV1 map}
                ord(adr.p8^) * tm1;
              if tm2 <> 0 then begin   {second level has non-zero weight ?}
                adr.i :=               {make address of texture value from map 2}
                  sys_int_adr_t(b2.line_p[v2 + iterp.tmap[lev2].y_orig]) + {scan start adr}
                  (u2 + iterp.tmap[lev2].x_orig) * b2.x_offset + {pixels into scan line}
                  iterp.tmap[lev2].iterp_offset; {bytes into pixel}
                iterp_val.all :=       {add in contribution from second map}
                  iterp_val.all + ord(adr.p8^) * tm2;
                end;                   {done handling value from second map}
              end                      {end of no horizontal blending case}
            ;
          end;                         {done with the B abbreviation}
        case rend_tmap.func of         {the different texture mapping functions}
rend_tmapf_insert_k: ;                 {value = texture map value}
rend_tmapf_ill_k: begin                {value = map_value * interpolated_value}
            iterp_val.all :=
              iterp_val.val8 *         {0-255 blended texture value}
              rshft(iterp.value.all & 16#00FFFFFF, 8); {16.16 illumination fraction}
            end;
          end;                         {done with texture mapping function cases}
done_tmap:                             {jump here if done handling texture mapping}
        end;                           {done handling texture mapping}
{
*   Handle alpha buffering, if enabled.
}
      if rend_alpha_on then begin      {alpha buffer blending enabled ?}
        iterp_val.all := 32768 +       {make correct blended value in high 16 bits}
          old_val.val16*old_afact + iterp_val.val16*new_afact;
        end;                           {done handling alpha buffering turned on}
      end;                             {done handling interpolant is 8 bits wide}

16: begin                              {interpolant is 16 bits wide}
      old_val.all := 0;
      old_val.val16 := iterp.curr_adr.p16^; {fetch old pixel value}
      iterp_val.all := 0;
      iterp_val.val16 := iterp.value.val16; {fetch integer part of interpolant value}
      end;

32: begin                              {interpolant is 32 bits wide}
      old_val.val32 := iterp.curr_adr.p32^; {fetch old pixel value}
      iterp_val.val32 := iterp.value.val32; {fetch integer part of interpolant value}
      end;
    end;                               {done with data width cases}

  case iterp.pixfun of                 {do the different pixel functions}
rend_pixfun_insert_k: new_pval.all := iterp_val.all;
rend_pixfun_add_k: new_pval.all := old_val.all + iterp_val.all;
rend_pixfun_sub_k: new_pval.all := old_val.all - iterp_val.all;
rend_pixfun_subi_k: new_pval.all := iterp_val.all - old_val.all;
rend_pixfun_and_k: new_pval.all := old_val.all & iterp_val.all;
rend_pixfun_or_k: new_pval.all := old_val.all ! iterp_val.all;
rend_pixfun_xor_k: new_pval.all := xor(old_val.all, iterp_val.all);
rend_pixfun_not_k: new_pval.all := ~iterp_val.all;
    end;                               {end of pixfun cases}

  if iterp.pclamp then begin           {pixel function clamping turned on ?}
    case iterp.width of                {different pixfun clamp code for each width}
8:    begin
        new_pval.val16 := max(0, min(255, new_pval.val16));
        end;
      end;                             {done with width cases that clamp}
    end;                               {done handling pixel function clamping}

  new_pval.all :=                      {merge old and new according to write mask}
    (new_pval.all & iterp.wmask)
    ! (old_val.all & (~iterp.wmask));

  case iterp.width of                  {write final pixel value to the bitmap}
8:  iterp.curr_adr.p8^ := chr(new_pval.val8);
16: iterp.curr_adr.p16^ := new_pval.val16;
32: iterp.curr_adr.p32^ := new_pval.val32;
    end;                               {done with writing different width data}

  end;                                 {done with the ITERP abbreviation}
  end;                                 {back and process next interpolant}
{
*   All done writing to the pixel.  Now handle the current span.
}
  if rend_dirty_crect then return;     {whole clip rect already flagged as dirty ?}
  if rend_curr_span.dirty
    then begin                         {there is a previous span}
      if                               {can't add new pixel to old span ?}
          (rend_curr_span.y <> rend_lead_edge.y) or {not on same scan line ?}
          (rend_curr_x > (rend_curr_span.right_x + 1)) or {would leave gap on right ?}
          (rend_curr_x < (rend_curr_span.left_x - 1)) {would leave gap on left ?}
          then begin
        rend_internal.update_span^ (   {write out old span}
          rend_curr_span.left_x,       {left span pixel coordinate}
          rend_curr_span.y,
          rend_curr_span.right_x - rend_curr_span.left_x + 1); {number of pixels}
        goto new_span;                 {go start a new span}
        end;
      rend_curr_span.left_x :=         {update span horizontal limits}
        min(rend_curr_span.left_x, rend_curr_x);
      rend_curr_span.right_x :=
        max(rend_curr_span.right_x, rend_curr_x);
      end
    else begin                         {there is no previous span}
      rend_curr_span.dirty := true;
new_span:                              {jump here to start a new span}
      rend_curr_span.left_x := rend_curr_x;
      rend_curr_span.right_x := rend_curr_x;
      rend_curr_span.y := rend_lead_edge.y;
      end
    ;
  end;
