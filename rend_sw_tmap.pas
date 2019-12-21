{   Collection for SW device routines that deal with texture mapping.
}
module rend_sw_tmap;
define rend_sw_tmap_accur;
define rend_sw_tmap_changed;
define rend_sw_tmap_dimension;
define rend_sw_tmap_filt;
define rend_sw_tmap_flims;
define rend_sw_tmap_func;
define rend_sw_tmap_method;
define rend_sw_tmap_on;
define rend_sw_tmap_src;
%include 'rend_sw2.ins.pas';
%include 'math.ins.pas';
{
********************************************************************************
*
*   Subroutine REND_SW_TMAP_ACCUR (ACCUR)
*
*   Set the new texture mapping accuracy requirements level.  This may be used
*   to allow use of hardware acceleration even though the hardware algorithm
*   doesn't exactly match the RENDlib specification.  Use one of the constants
*   REND_TMAPACCU_xxx_K.
}
procedure rend_sw_tmap_accur (         {set texture mapping accuracy level}
  in      accur: rend_tmapaccu_k_t);   {new accuracy mode, use REND_TMAPACCU_xxx_K}
  val_param;

begin
  if rend_tmap.accur = accur then return; {nothing to change ?}
  rend_tmap.accur := accur;            {set new texture mapping accuracy mode}

  if rend_tmap.on then begin           {texture mapping enabled ?}
    rend_internal.check_modes^;        {reconfigure with new mode}
    end;
  end;
{
********************************************************************************
*
*   Subroutine REND_SW_TMAP_CHANGED
*
*   Notify RENDlib that one or more of the pixel values of the texture map may
*   have gotten altered.  This call *MUST* be used after any texture map pixels
*   are changed, and before the next texture mapping drawing operation is
*   performed.  The results are unpredictable when this is not done.
}
procedure rend_sw_tmap_changed;        {indicate that texture map data got changed}

begin
  end;
{
********************************************************************************
*
*   Subroutine REND_SW_TMAP_DIMENSION (LEVEL)
*
*   Indicate the dimension level of the texture map.  Legal values come from
*   constants named REND_TMAPD_xx_K in file rend.ins.pas.
}
procedure rend_sw_tmap_dimension (     {set texture mapping dimensionality level}
  in      level: rend_tmapd_k_t);      {texture map dimension level ID number}
  val_param;

begin
  if rend_tmap.dim = level then return; {nothing to do ?}
  rend_tmap.dim := level;              {save dimension level in common block}

  if rend_tmap.on then begin           {texture mapping enabled ?}
    rend_internal.check_modes^;        {reconfigure with new mode}
    end;
  end;
{
********************************************************************************
*
*   Subroutine REND_SW_TMAP_FLIMS (MIN_SIZE, MAX_SIZE)
*
*   Set the minimum and maximum allowable texture maps to select.  The two call
*   parameters are floating point and refer to the width of the texture maps in
*   pixels.  When the texture mapping method is mip mapping, then all texture
*   maps must be power of 2 sizes.  The max(abs()) of all the texture index
*   interpolant first derivatives (dU/dX, dU/dY, dV/dX, . . .) is used to select
*   the appropriate texture source map to achieve the correct level of
*   filtering.  This subroutine sets the constraints on that selection.  It can
*   be used, for example, to always force the selection of only one texture map,
*   regardless of the first derivatives.
}
procedure rend_sw_tmap_flims (         {set limits on texture mapping filtering}
  in      min_size: real;              {min size map to use, in pixels accross}
  in      max_size: real);             {max size map to use, in pixels accross}
  val_param;

var
  iminsz, imaxsz: sys_int_machine_t;   {mip map size index number}

begin
  case rend_tmap.method of             {what overall method are we using}

rend_tmapm_mip_k: begin                {overal method is mip-mapping}
      iminsz :=                        {make mip map texture map size numbers}
        round(math_log2(min_size));
      imaxsz :=
        round(math_log2(max_size));
      if                               {nothing getting changed ?}
          (iminsz = rend_tmap.mip.min_map) and
          (imaxsz = rend_tmap.mip.max_map)
        then return;
      rend_tmap.mip.min_map :=         {set minumum size map index number}
        iminsz;
      rend_tmap.mip.max_map :=         {set maximum size map index number}
        imaxsz;
      rend_internal.check_modes^;
      end;                             {done handling mip-map texture mapping method}

    end;                               {end of overall texture mapping method cases}
  end;
{
********************************************************************************
*
*   Subroutine REND_SW_TMAP_FILT (FILT)
*
*   Set new texture mapping filtering requirements.  Note that these may be
*   ignored on some devices depending on the accuracy mode.
}
procedure rend_sw_tmap_filt (          {set texture mapping filtering methods}
  in      filt: rend_tmapfilt_t);      {set of texture mapping filtering flags}
  val_param;

begin
  if rend_tmap.filt = filt then return; {no change, nothing to do ?}
  rend_tmap.filt := filt;              {set new filtering flags values}

  if rend_tmap.on then begin           {texture mapping enabled ?}
    rend_internal.check_modes^;        {reconfigure with new mode}
    end;
  end;
{
********************************************************************************
*
*   Subroutine REND_SW_TMAP_FUNC (FUNC)
*
*   Select a new current texture mapping function.  FUNC is the function ID
*   number.  These are defined by constants of the name REND_TMAPF_xx_K in the
*   include file rend.ins.pas.
}
procedure rend_sw_tmap_func (          {set texture mapping function}
  in      func: rend_tmapf_k_t);       {ID number for new texture mapping function}
  val_param;

begin
  if rend_tmap.func = func then return; {nothing to do ?}
  rend_tmap.func := func;              {save function ID number in common block}

  if rend_tmap.on then begin           {texture mapping enabled ?}
    rend_internal.check_modes^;        {reconfigure with new mode}
    end;
  end;
{
********************************************************************************
*
*   Subroutine REND_SW_TMAP_METHOD (METHOD)
*
*   Set the global texture mapping method.
}
procedure rend_sw_tmap_method (        {set texture mapping method}
  in      method: rend_tmapm_k_t);     {texture mapping method ID number}
  val_param;

begin
  if rend_tmap.method = method then return; {nothing to do ?}
  rend_tmap.method := method;          {save flag in common block}

  if rend_tmap.on then begin           {texture mapping enabled ?}
    rend_internal.check_modes^;        {reconfigure with new mode}
    end;
  end;
{
********************************************************************************
*
*   Subroutine REND_SW_TMAP_ON (ON)
*
*   Turn texture mapping on/off.  TRUE = on.
}
procedure rend_sw_tmap_on (            {turn texture mapping on/off}
  in      on: boolean);                {TRUE to turn texture mapping on}
  val_param;

begin
  if rend_tmap.on = on then return;    {no change in on/off status ?}
  rend_tmap.on := on;                  {save new value in common block}
  rend_internal.check_modes^;          {may need to load in different routines}
  end;
{
********************************************************************************
*
*   Subroutine REND_SW_TMAP_SRC (
*     ITERP, BITMAP, OFFSET, X_SIZE, Y_SIZE, X_ORIG, Y_ORIG)
*
*   Define the source of a texture map for this interpolant.  ITERP identifies
*   the interpolant.  BITMAP is the handle to the bitmap containing the texture
*   map.  OFFSET is the byte offset for this interpolant into each pixel of the
*   bitmap.  X_SIZE and Y_SIZE is the size of the texture map in pixels.  X_ORIG
*   and Y_ORIG is the origin of the texture map within the bitmap.  Therefore,
*   X_ORIG and Y_ORIG are 0,0 if the texture map is justified in the top left
*   corner of the bitmap.
*
*   To disable the texture map of this size for this interpolant, specify nil
*   for BITMAP.
*
*   If the global texture mapping method is mip-mapping, then the texture map
*   must be square (X_SIZE = Y_SIZE), and its size must be a power of 2 pixels
*   in each dimension.
}
procedure rend_sw_tmap_src (           {set texture map source for this interpolant}
  in      iterp: rend_iterp_k_t;       {ID of interpolant to set texmap source for}
  in      bitmap: rend_bitmap_handle_t; {handle to bitmap containing source pixels}
  in      offset: sys_int_adr_t;       {adr offset within pixel for this interpolant}
  in      x_size, y_size: sys_int_machine_t; {dimensions of texture map within bitmap}
  in      x_orig, y_orig: sys_int_machine_t); {origin of texture map within bitmap}
  val_param;

const
  max_msg_parms = 2;                   {max parameters we can pass to a message}

var
  sz: sys_int_machine_t;               {scratch size parameter}
  log_size: sys_int_machine_t;         {LOG2 of texture map size}
  mask: sys_int_machine_t;             {bit mask for finding LOG_SIZE}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;

label
  out_range, log_loop, done_log;

begin
  if (x_size <= 0) or (y_size <= 0) then begin
out_range:                             {jump here if texture map size out of range}
    sys_msg_parm_int (msg_parm[1], x_size);
    sys_msg_parm_int (msg_parm[2], y_size);
    rend_message_bomb ('rend', 'rend_tmap_size_orange', msg_parm, 2);
    end;

  case rend_tmap.dim of                {different code for possible map dimensions}

rend_tmapd_u_k: begin                  {one dimensional, indexed horizontally by U}
      if y_size <> 1 then begin
        sys_msg_parm_int (msg_parm[1], y_size);
        rend_message_bomb ('rend', 'rend_tmap_u_height_bad', msg_parm, 1);
        end;
      sz := x_size;                    {save size to use later}
      end;

rend_tmapd_uv_k: begin                 {two dimensional, indexed by U,V}
      if x_size <> y_size then begin
        sys_msg_parm_int (msg_parm[1], x_size);
        sys_msg_parm_int (msg_parm[2], y_size);
        rend_message_bomb ('rend', 'rend_tmap_mip_nsquare', msg_parm, 2);
        end;
      sz := x_size;                    {save size to use later}
      end;

otherwise
    writeln ('Illegal or unimplemented texture mapping dimension level found');
    writeln ('in subroutine REND_SW_TMAP_SRC.');
    sys_bomb;
    end;                               {done with texture mapping dimension cases}
{
*   SZ is the integer size in pixels of the texture map size in the appropriate
*   dimension(s).
}
  log_size := 0;                       {init LOG2 of SZ}
  mask := 1;
log_loop:                              {back here to check next possible log2 value}
  if (mask & sz) <> 0 then begin       {found a 1 bit in SZ at this position ?}
    if sz <> mask then begin           {some other bit turned on too ?}
      sys_msg_parm_int (msg_parm[1], x_size);
      sys_msg_parm_int (msg_parm[2], y_size);
      rend_message_bomb ('rend', 'rend_tmap_nlog2', msg_parm, 2);
      end;
    goto done_log;                     {found LOG2 of texture map size}
    end;
  mask := lshft(mask, 1);              {make next power of two}
  log_size := log_size+1;              {make next LOG2 value}
  goto log_loop;                       {back and try this new LOG2 value}
{
*   The texture map size is an exact power of two.  LOG2 of the texture map size
*   is sitting in LOG_SIZE.
}
done_log:
  if log_size > rend_max_iterp_tmap then goto out_range; {size out of range ?}
  with rend_iterps.iterp[iterp].tmap[log_size]: tmap do begin {TMAP abbreviation}
{
*   TMAP now stands for the texture map descriptor of the appropriate size for
*   this interpolant.
}
    tmap.bitmap := bitmap;             {stuff values into texture map descriptor}
    tmap.iterp_offset := offset;
    tmap.x_orig := x_orig;
    tmap.y_orig := y_orig;
    tmap.x_size := x_size;
    tmap.y_size := y_size;
    end;                               {done with TMAP abbreviation}
  end;
