{   Subroutine REND_SW_AA_SCALE (X_SCALE,Y_SCALE)
*
*   Set the image size scale factors for anti-aliasing.  The two scale factors are
*   (output image size / input image size) for each dimension.  Currently these
*   are restricted to result in an integer size reduction in each dimension.
*   The image must be shrunk by at least a factor of 2 in each dimension.
}
module rend_sw_aa_scale;
define rend_sw_aa_scale;
%include 'rend_sw2.ins.pas';

procedure rend_sw_aa_scale (           {set scale factors for ANTI_ALIAS primitive}
  in      x_scale: real;               {output size / input size horizontal scale}
  in      y_scale: real);              {output size / input size vertical scale}
  val_param;

var
  kernel_ncoef: sys_int_machine_t;     {total number of coeficients in filter kernel}
  size: sys_int_adr_t;                 {amount of memory needed}
  filt_mag: real;                      {magnitude of unnormalized filter kernel}
  lx, ty: real;                        {left X and top Y of filter kernel}
  x, y: real;                          {XY at top left of current kernel subpixel}
  ix, iy: sys_int_machine_t;           {horizontal and vertical loop counters}
  i: sys_int_machine_t;                {scratch integer and loop counter}
  dx, dy: real;                        {size of a filter subpixel}
  r_p: ^real;                          {points to current real coeficient}
  i_p: ^sys_int_machine_t;             {points to current integer coeficient}
{
*******************************************************************
*
*   Internal function FILT_FUNC(R)
*
*   Pass back the filter function at the radius R.  R is in units of output
*   pixel sizes.
}
function filt_func (
  in      r: real)                     {radius to evaluate filter function at}
  :real;                               {filter function value at radius R}

const
  pi = 3.141593;

begin
  if r > rend_aa.kernel_rad
    then filt_func := 0.0
    else filt_func := cos(pi * r / rend_aa.kernel_rad) + 1.0;
  end;
{
*******************************************************************
*
*   Internal function FILT_COEF(X,Y)
*
*   Return the unnormalized filter coeficient for the subpixel whos top left
*   corner is at X,Y.
}
function filt_coef (
  in      x, y: real)                  {top left corner of this subpixel}
  :real;                               {unnormalized coeficient value}

const
  x_samples = 6;                       {size of sample grid for numerical integral}
  y_samples = 6;

var
  r: real;                             {radius from filter kernel center}
  sy: real;                            {Y coordinate of this sample point}
  lx: real;                            {X at left edge samples}
  sx: real;                            {X coordinate of this sample point}
  xn, yn: real;                        {spacing between sample points}
  i, j: sys_int_machine_t;             {loop counters}
  acc: real;                           {sample integral accumulator}

begin
  xn := dx / x_samples;                {X distance between sample points}
  yn := dy / y_samples;                {Y distance between sample points}
  lx := x + (0.5 * xn);                {X coor of left column of samples}
  sy := y - (0.5 * yn);                {Y coor of top row of samples}
  acc := 0.0;                          {init sample accumulator}

  for i := 1 to y_samples do begin     {down the sample rows}
    sx := lx;                          {next sample will be at left edge}
    for j := 1 to x_samples do begin   {accross this row of samples}
      r := sqrt(sqr(sx) + sqr(sy));    {radius from kernel center}
      acc := acc + filt_func(r);       {accumulate this sample here}
      sx := sx + xn;                   {accross one sample column}
      end;                             {back and process next sample point accross}
    sy := sy - yn;                     {down one sample row}
    end;                               {back and process next row of samples down}

  filt_coef := acc / (x_samples * y_samples); {pass back integral over this subpixel}
  end;
{
*******************************************************************
*
*   Start of main routine.
}
begin
  if (x_scale = rend_aa.scale_x) and (y_scale = rend_aa.scale_y)
    then return;                       {already set to these values ?}

  rend_aa.scale_x := x_scale;          {save image size scaling factors}
  rend_aa.scale_y := y_scale;
  rend_aa.shrink_x := round(1.0/x_scale); {assume integer shrink factor}
  rend_aa.shrink_y := round(1.0/y_scale);

  if                                   {check for bad shrink factors}
      (rend_aa.shrink_x < 2) or
      (rend_aa.shrink_y < 2) or
      (abs((rend_aa.shrink_x * x_scale) - 1.0) > 1.0E-5) or
      (abs((rend_aa.shrink_y * y_scale) - 1.0) > 1.0E-5)
      then begin
    rend_set.enter_level^ (0);
    writeln ('Shrink factors too small or not integer in REND_SET.AA_SCALE.');
    sys_bomb;
    end;
{
*   SHRINK_X and SHRINK_Y are all set and within range.  Now compute a new
*   filter kernel.
}
  rend_aa.start_xofs :=                {subpixels outside output pixel in X}
    trunc((rend_aa.kernel_rad - 0.5) * rend_aa.shrink_x + 0.999);
  rend_aa.start_yofs :=                {subpixels outside output pixel in Y}
    trunc((rend_aa.kernel_rad - 0.5) * rend_aa.shrink_y + 0.999);

  rend_aa.kernel_dx :=                 {number of horizontal subpixels in kernel}
    (2 * rend_aa.start_xofs) + rend_aa.shrink_x;
  rend_aa.kernel_dy :=                 {number of vertical subpixels in kernel}
    (2 * rend_aa.start_yofs) + rend_aa.shrink_y;
  kernel_ncoef :=                      {total number of subpixels in kernel}
    rend_aa.kernel_dx * rend_aa.kernel_dy;
{
*   Allocate memory for real and integer filter kernel.  Any existing filter kernel
*   memory must be deallocated first.
}
  if rend_aa.filt_int_p <> nil then begin {deallocate old integer coeficients ?}
    rend_mem_dealloc (rend_aa.filt_int_p, rend_scope_dev_k); {deallocate old integers}
    end;
  size := sizeof(rend_aa.filt_int_p^[1]) * kernel_ncoef; {amount of mem for integers}
  rend_mem_alloc (                     {allocate memory for integer coeficients}
    size,                              {amount of memory needed}
    rend_scope_dev_k,                  {memory belongs to this device}
    true,                              {WILL need to individually deallocate this}
    rend_aa.filt_int_p);               {pointer to new memory}

  if rend_aa.filt_fp_p <> nil then begin {deallocate old float coeficients ?}
    rend_mem_dealloc (rend_aa.filt_fp_p, rend_scope_dev_k); {deallocate old floats}
    end;
  size := sizeof(rend_aa.filt_fp_p^[1]) * kernel_ncoef; {mem size for FP coeficients}
  rend_mem_alloc (                     {allocate memory for FP coeficients}
    size,                              {amount of memory needed}
    rend_scope_dev_k,                  {memory belongs to this device}
    true,                              {WILL need to individually deallocate this}
    rend_aa.filt_fp_p);                {pointer to new memory}
{
*   The memory has been allocated for both the integer and floating point
*   coeficient lists.  We will first calculate the raw, unnormalized, floating
*   point coeficients.  The overall kernel magnitude will be computed in FILT_MAG.
*   This will then be used to normalize the floating point coeficients to a
*   filter magnitude of 1.0, and to create the integer coeficients in the same
*   pass.
}
  dx := 1.0 / rend_aa.shrink_x;        {make size of a kernel subpixel}
  dy := 1.0 / rend_aa.shrink_y;
  lx := -0.5 * rend_aa.kernel_dx * dx; {make top left coordinate of kernel}
  ty := 0.5 * rend_aa.kernel_dy * dy;
  r_p := addr(rend_aa.filt_fp_p^[1]);  {point to first filter kernel coeficient}
  filt_mag := 0.0;                     {init unnormalized filter magnitude}

  y := ty;                             {init Y coord for top of first row}
  for iy := 1 to rend_aa.kernel_dy do begin {down the rows in the filter kernel}
    x := lx;                           {init X to left edge of this row}
    for ix := 1 to rend_aa.kernel_dx do begin {accross this row in filter kernel}
      r_p^ := filt_coef (x, y);        {get unnormalized value for this coeficient}
      filt_mag := filt_mag + r_p^;     {accumulate total filter magnitude}
      x := x + dx;                     {advance X to next subpixel accross}
      r_p := univ_ptr(                 {advance to next filter coeficient}
        sys_int_adr_t(r_p) + sizeof(r_p^));
      end;                             {back and process next pixel accross}
    y := y - dy;                       {make Y coordinate of next row down}
    end;                               {back and process next row down}

  filt_mag := 0.99999 / filt_mag;      {make filter magnitude adjust factor}
  r_p := addr(rend_aa.filt_fp_p^[1]);  {point to first filter kernel coeficient}
  i_p := addr(rend_aa.filt_int_p^[1]);

  for i := 1 to kernel_ncoef do begin  {once for each kernel coeficient}
    r_p^ := r_p^ * filt_mag;           {make normalized floating point coeficient}
    i_p^ := trunc(r_p^ * 65536.0);     {make normalized integer coeficient}
    r_p := univ_ptr(                   {advance to next FP filter coeficient}
      sys_int_adr_t(r_p) + sizeof(r_p^));
    i_p := univ_ptr(                   {advance to next INT filter coeficient}
      sys_int_adr_t(i_p) + sizeof(i_p^));
    end;                               {back to process next kernel coeficient}

  rend_internal.check_modes^;          {new filter configuration may change modes}
  end;
