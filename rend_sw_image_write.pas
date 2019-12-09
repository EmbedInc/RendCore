{   Subroutine REND_SW_IMAGE_WRITE (FNAM, X_ORIG, Y_ORIG, X_SIZE, Y_SIZE, STAT)
*
*   Write a rectangle from the current bitmap to an image file. FNAM is the generic
*   name of the image output file.  X_ORIG,Y_ORIG is the bitmap coordinate from where
*   the top left image pixel will be written.  X_SIZE and Y_SIZE, specify
*   the number of pixels in each dimension to write to the image file.
}
module rend_sw_image_write;
define rend_sw_image_write;
%include 'rend_sw2.ins.pas';

var
  default_red: char := chr(0);         {default values when interpolants unreadable}
  default_grn: char := chr(0);
  default_blu: char := chr(0);
  default_alpha: char := chr(255);

procedure rend_sw_image_write (        {write rectangle from bitmap to image file}
  in      fnam: univ string_var_arg_t; {generic image output file name}
  in      x_orig: sys_int_machine_t;   {coor where top left image pixel comes from}
  in      y_orig: sys_int_machine_t;
  in      x_size: sys_int_machine_t;   {image size in pixels}
  in      y_size: sys_int_machine_t;
  out     stat: sys_err_t);            {completion status code}
  val_param;

var
  aspect: real;                        {width/height aspect ratio of new image}
  img_fmt: string_var132_t;            {image file format string}
  x, y: sys_int_machine_t;             {current image pixel coordinate}
  img: img_conn_t;                     {handle to open image output file}
  x_origin: sys_int_machine_t;         {make local copy to get around compiler bug}
  red_p: ^char;                        {pointer to current pixel values}
  grn_p: ^char;
  blu_p: ^char;
  alpha_p: ^char;
  red_inc: sys_int_adr_t;              {increment for pixel value pointers}
  grn_inc: sys_int_adr_t;
  blu_inc: sys_int_adr_t;
  alpha_inc: sys_int_adr_t;
  scan_p: img_scan1_arg_p_t;           {pointer to one scan line of pixels}
  size: sys_int_adr_t;                 {size of one scan line}
{
**************************************************************************************
*
*   Internal subroutine START_SCAN_LINE (ITERP, N, P, INC, DEF)
*
*   Initialize our local data structure for reading a new scan line.  ITERP is the
*   interpolant data block.  N is the new scan line number.  P is returned as a
*   pointer to the first data byte for this interpolant at the pixel coordinate
*   (X_ORIGIN,N).  INC is returned as the amount that P should be incremented to
*   read the next pixel to the right.  DEF is where the default value for this
*   interpolant was previously stored.  In case the interpolant can not be read,
*   P is pointed to DEF, and INC is set to zero, so that the default value is always
*   read for this interpolant.
}
procedure start_scan_line (
  in out  iterp: rend_iterp_pix_t;     {interpolant state block}
  in      n: sys_int_machine_t;        {scan line number to set interpolant to}
  out     p: univ_ptr;                 {will point to iterp data at (X_ORIGIN,N)}
  out     inc: sys_int_adr_t;          {amount to increment P by for next pixel}
  in      def: univ char);             {where to point P to for iterp default value}
  val_param;

begin
  if iterp.on and (iterp.bitmap_p <> nil)
    then begin                         {this interpolant can be read}
      inc := iterp.bitmap_p^.x_offset; {amount to inc pointer to next pixel right}
      p := univ_ptr(                   {address of first iterp byte at curr pixel}
        sys_int_adr_t(iterp.bitmap_p^.line_p[n]) + {start of scan line}
        (x_origin * inc) +             {starting pixel into scan line}
        iterp.iterp_offset);           {pixels offset for this interpolant}
      end
    else begin                         {this interpolant can not be read, use default}
      p := addr(def);                  {point to default value}
      inc := 0;                        {keep pointing to default value}
      end
    ;
  end;
{
**************************************************************************************
*
*   Code for main routine.
}
begin
  img_fmt.max := sizeof(img_fmt.str);  {init var string}
  x_origin := x_orig;                  {make local copy due to compiler bug}
  rend_prim.flush_all^;                {make sure image is up to date}
{
*   Open image output file.  IMG will be the image stream handle to the new file.
}
  aspect := (rend_image.aspect*x_size*rend_image.y_size)
    / (y_size*rend_image.x_size);
  img_fmt.len := 0;                    {init image file format string}

  if  rend_iterps.alpha.on and         {alpha values are available ?}
      (rend_iterps.alpha.bitmap_p <> nil)
      then begin
    string_appends (img_fmt, 'ALPHA 8'); {request alpha resolution in bits}
    end;

  img_open_write_img (                 {open image file for write}
    fnam,                              {generic image file name}
    aspect,                            {image width/height aspect ratio}
    x_size, y_size,                    {size of image in pixels}
    rend_image.ftype.str,              {image file type name}
    img_fmt,                           {image file format string}
    rend_image.comm,                   {handle to list of comment lines}
    img,                               {returned handle to image file connection}
    stat);
  if sys_error(stat) then return;
{
*   The image output file is open.
}
  size := x_size * sizeof(img_pixel1_t);
  sys_mem_alloc (size, scan_p);        {allocate memory for one scan line}
  sys_mem_error (scan_p, '', '', nil, 0);

  for y := y_orig to y_orig+y_size-1 do begin {once for each scan line in image}
    start_scan_line (rend_iterps.red, y, red_p, red_inc, default_red);
    start_scan_line (rend_iterps.grn, y, grn_p, grn_inc, default_grn);
    start_scan_line (rend_iterps.blu, y, blu_p, blu_inc, default_blu);
    start_scan_line (rend_iterps.alpha, y, alpha_p, alpha_inc, default_alpha);

    for x := 0 to x_size-1 do begin    {once for each pixel on scan line}
      scan_p^[x].alpha := ord(alpha_p^);
      scan_p^[x].red := ord(red_p^);
      scan_p^[x].grn := ord(grn_p^);
      scan_p^[x].blu := ord(blu_p^);
      alpha_p := univ_ptr(sys_int_adr_t(alpha_p) + alpha_inc);
      red_p := univ_ptr(sys_int_adr_t(red_p) + red_inc);
      grn_p := univ_ptr(sys_int_adr_t(grn_p) + grn_inc);
      blu_p := univ_ptr(sys_int_adr_t(blu_p) + blu_inc);
      end;                             {back for next pixel accross the scan line}

    img_write_scan1 (img, scan_p^, stat); {write this scan line to image file}
    end;                               {back for next scan line down}
  sys_mem_dealloc (scan_p);
  if sys_error(stat) then return;

  img_close (img, stat);               {close image output file}
  end;
