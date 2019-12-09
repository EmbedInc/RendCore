{   Subroutine REND_SW_ARRAY_BITMAP (HANDLE,AR,X_SIZE,Y_SIZE,PIX_BYTES,LINE_BYTES)
*
*   Set up a bitmap as pixel data in an array.  HANDLE must be the previously
*   created bitmap handle.  AR is the array that contains the storage for the
*   pixels.  X_SIZE and Y_SIZE are the number of pixels in each dimension of the
*   array.  PIX_BYTES is the number of storage bytes in the array for one pixel to
*   the right within the same scan line.  LINE_BYTES is the number of storage bytes
*   withing the array from the start of one scan line to the start of the next.
}
module rend_sw_array_bitmap;
define rend_sw_array_bitmap;
%include 'rend_sw2.ins.pas';

procedure rend_sw_array_bitmap (       {declare array to use for bitmap data}
  in      handle: rend_bitmap_handle_t; {handle for this bitmap}
  in      ar: univ sys_size1_t;        {the array of pixels}
  in      x_size, y_size: sys_int_machine_t; {number of pixels in each dimension}
  in      size_pix: sys_int_adr_t;     {adr offset for one pixel to the right}
  in      size_line: sys_int_adr_t);   {adr offset for one scan line down}
  val_param;

var
  b: rend_bitmap_desc_p_t;             {pointer to bitmap descritor}
  lnum: sys_int_machine_t;             {scan line number}
  adr: sys_int_adr_t;                  {address of current scan line start}

begin
  if y_size > rend_max_lines then begin
    rend_message_bomb ('rend', 'image_image_too_tall', nil, 0);
    end;
  b := handle;                         {save pointer to bitmap descriptor}
  b^.x_size := x_size;                 {width of bitmap in pixels}
  b^.y_size := y_size;                 {height of bitmap in pixels}
  b^.x_offset := size_pix;             {adr offset for one pixel to the right}
  adr := sys_int_adr_t(addr(ar));      {init to address of first scan line}
  for lnum := 0 to y_size-1 do begin   {once for each scan line in array}
    b^.line_p[lnum] := univ_ptr(adr);  {set start address of this scan line}
    adr := adr + size_line;            {make address of next scan line start}
    end;                               {back and do next array scan line}
  for lnum := y_size to rend_max_y do begin {once for each unused scan line pointer}
    b^.line_p[lnum] := nil;            {set scan line pointer to invalid}
    end;                               {back and do next unused scan line}
  end;
