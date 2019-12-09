{   Subroutine REND_SW_ALLOC_BITMAP (HANDLE,X_SIZE,Y_SIZE,PIX_SIZE,SCOPE)
*
*   Allocate the pixel memory for this bitmap.  It is assumed that no pixel memory
*   has been previously allocated for this bitmap.  X_SIZE and Y_SIZE are the number
*   of pixels in the bitmap horizontally and vertically.  PIX_SIZE is the number
*   of machine address units to allocate for each pixel.
}
module rend_sw_alloc_bitmap;
define rend_sw_alloc_bitmap;
%include 'rend_sw2.ins.pas';

procedure rend_sw_alloc_bitmap (       {alloc memory for the pixels}
  in      handle: rend_bitmap_handle_t; {handle to bitmap descriptor}
  in      x_size, y_size: sys_int_machine_t; {number of pixels in each dimension}
  in      pix_size: sys_int_adr_t;     {adr units to allocate per pixel}
  in      scope: rend_scope_t);        {what memory context bitmap to belong to}
  val_param;

var
  y: sys_int_machine_t;                {bitmap scan line number}
  b: rend_bitmap_desc_p_t;             {pointer to this bitmap descriptor}
  line_mem: sys_int_adr_t;             {memory needed for each scan line}
  total_mem: sys_int_adr_t;            {total memory needed for bitmap}
  line_p: univ_ptr;                    {pointer to current scan line}

begin
  if y_size > (rend_max_y + 1) then begin
    writeln ('Too many scan lines specified in REND_SW_ALLOCATE_BITMAP.');
    sys_bomb;
    end;

  line_mem := x_size*pix_size;         {number of bytes needed for each scan line}
  line_mem := (line_mem + sizeof(sys_int_machine_t) - 1) div
    sizeof(sys_int_machine_t);         {number of whole convenient address units}
  line_mem := line_mem * sizeof(sys_int_machine_t); {make final size of scan line}
  total_mem := line_mem * y_size;      {total bitmap memory needed}
  rend_mem_alloc (                     {get memory for bitmap}
    total_mem,                         {size of region to allocate}
    scope,
    true,                              {we may need to deallocate this separately}
    line_p);                           {init pointer to first scan line}
  sys_mem_error (line_p, '', '', nil, 0);

  b := handle;                         {make local pointer to bitmap descriptor}
  b^.x_size := x_size;                 {fill in bitmap size in pixels}
  b^.y_size := y_size;
  b^.x_offset := pix_size;             {fill in bytes per pixel horizontally}
  b^.scope_pixels := scope;            {save scope of pixel memory}

  for y := 0 to y_size-1 do begin      {once for each scan line}
    b^.line_p[y] := line_p;            {set start adr for this scan line}
    line_p := univ_ptr(                {advance to point to next scan line}
      sys_int_adr_t(line_p) + line_mem);
    end;                               {back and do next scan line}
  end;
