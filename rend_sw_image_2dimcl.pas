{   Subroutine REND_SW_IMAGE_2DIMCL (IMG,X,Y,TORG,STAT)
*
*   Write an image from an image file to the current bitmap.  IMG is the
*   image stream handle for the source image.  It must already be open.
*   X,Y is the bitmap pixel coordinate for the image anchor point.  TORG
*   defines where the anchor point is with respect to the source image.
*   Use one of the constants of name REND_TORG_xxx_K for the TORG value.
*   Only the first 9 REND_TORG_xxx_K value are legal.  These are
*   upper left thru lower right.  STAT is returned as the completion status
*   code.
}
module rend_sw_image_2dimcl;
define rend_sw_image_2dimcl;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_image_2dimcl_d.ins.pas';

const
  max_msg_parms = 1;                   {max parameters we can pass to a message}

procedure rend_sw_image_2dimcl (       {read image from file to current image bitmap}
  in out  img: img_conn_t;             {handle to previously open image file}
  in      x, y: sys_int_machine_t;     {bitmap anchor coordinate}
  in      torg: rend_torg_k_t;         {how image is anchored to X,Y}
  out     stat: sys_err_t);            {returned completion status code}
  val_param;

var
  ul_x, ul_y: sys_int_machine_t;       {bitmap coordinate of image upper left}
  msg_parm:                            {parameter references for message}
    array[1..max_msg_parms] of sys_parm_msg_t;
  it: rend_iterp_k_t;                  {loop counter for interpolants}
  i: sys_int_machine_t;                {loop counter}
  scan_p: img_scan1_arg_p_t;           {pointer to buffer for one scan line}
  size: sys_int_adr_t;                 {amount of mem needed for one scan line}

begin
  sys_error_none (stat);               {init to no errors}

  case torg of
rend_torg_ul_k: begin
      ul_x := x;
      ul_y := y;
      end;
rend_torg_um_k: begin
      ul_x := x - (img.x_size div 2);
      ul_y := y;
      end;
rend_torg_ur_k: begin
      ul_x := x - img.x_size + 1;
      ul_y := y;
      end;
rend_torg_ml_k: begin
      ul_x := x;
      ul_y := y - (img.y_size div 2);
      end;
rend_torg_mid_k: begin
      ul_x := x - (img.x_size div 2);
      ul_y := y - (img.y_size div 2);
      end;
rend_torg_mr_k: begin
      ul_x := x - img.x_size + 1;
      ul_y := y - (img.y_size div 2);
      end;
rend_torg_ll_k: begin
      ul_x := x;
      ul_y := y - img.y_size + 1;
      end;
rend_torg_lm_k: begin
      ul_x := x - (img.x_size div 2);
      ul_y := y - img.y_size + 1;
      end;
rend_torg_lr_k: begin
      ul_x := x - img.x_size + 1;
      ul_y := y - img.y_size + 1;
      end;
otherwise
    sys_msg_parm_int (msg_parm[1], ord(torg));
    sys_message_bomb ('rend', 'rend_bad_torg', msg_parm, 1);
    end;                               {done handling TORG cases}
{
*   UL_X,UL_Y is the bitmap pixel coordinate of where the top left corner of the
*   image is to go.
}
  if img.next_y <> 0 then begin        {we are not at start of image file ?}
    img_rewind (img, stat);
    if sys_error (stat) then return;
    end;
{
*   Configure the interpolants so that they can receive data thru a format 1
*   span.
}
  for it := firstof(it) to lastof(it) do begin {once for each interpolant}
    rend_set.iterp_span_on^ (it, false); {disable all iterps for SPAN participation}
    end;

  rend_set.iterp_span_on^ (rend_iterp_red_k, true); {enable for SPAN primitive}
  rend_set.iterp_span_on^ (rend_iterp_grn_k, true);
  rend_set.iterp_span_on^ (rend_iterp_blu_k, true);
  rend_set.iterp_span_on^ (rend_iterp_alpha_k, true);

  rend_set.iterp_span_ofs^ (rend_iterp_red_k, 1); {set position in scan line pixel}
  rend_set.iterp_span_ofs^ (rend_iterp_grn_k, 2);
  rend_set.iterp_span_ofs^ (rend_iterp_blu_k, 3);
  rend_set.iterp_span_ofs^ (rend_iterp_alpha_k, 0);

  rend_set.span_config^ (sizeof(img_pixel1_t)); {offset for one pixel further}

  rend_set.cpnt_2dimi^ (ul_x, ul_y);   {set coordinate of top left pixel}
  rend_prim.rect_px_2dimcl^ (img.x_size, img.y_size); {declare draw area}
{
*   Write the image into the bitmap by copying one scan line at a time.
}
  size := img.x_size * sizeof(img_pixel1_t);
  sys_mem_alloc (size, scan_p);        {allocate memory for one scan line}
  sys_mem_error (scan_p, '', '', nil, 0);

  for i := 0 to img.y_size-1 do begin  {once for each scan line in image}
    img_read_scan1 (img, scan_p^, stat); {read scan line from image file}
    if sys_error(stat) then return;    {error reading this scan line}
    rend_prim.span_2dimcl^ (img.x_size, scan_p^); {write scan line to bitmap}
    end;

  sys_mem_dealloc (scan_p);            {deallocate scan line buffer}
  end;
