{   Subroutine REND_SW_MIPMAP_TABLE_INIT (N, TABLE)
*
*   Fill in a mipmap blending table.  This table is used to determine the
*   coeficients for blending between the two mip maps of the closest sizes
*   to the ideal size.
*
*   The table is an array of integers with 16 bits below the binary point.
*   Each table entry gives the 0.0 to 1.0 weighting fraction for the larger
*   (less filtered) of the two maps.  The table index is a number from 0
*   to 255.  The index comes from the 8 bits immediately below the most
*   significant 1 bit of the derivative value.  We can think of the derivative
*   value as already having been scaled (by selection of the appropiate maps)
*   to a value from 256 to 511.  A value of 256 would exactly specify the
*   larger map, while a value of 512 would exactly specify the smaller map.
*   Note that map values are not blended linearly with the 256-511 value,
*   but rather logarithmically.  The table index is the low 8 bits of the
*   256-511 scaled derivative value.
*
*   The N call parameter indicates the number of discrete quantization levels
*   to allow in the 0-255 table index.  In normal operation, N should be
*   set to 256, meaning all 8 table index bits are meaningful.  Other values
*   may be useful to deliberately simulate specific hardware or other
*   algorithms.  If so, the user must write separate code to call this
*   routine with a different value of N.  RENDlib only uses a value of
*   256.  See REND_SW_INIT.PAS.
}
module rend_sw_mipmap_table_init;
define rend_sw_mipmap_table_init;
%include 'rend_sw2.ins.pas';
%include 'math.ins.pas';

procedure rend_sw_mipmap_table_init (  {init mip-map adjacent map blending table}
  in      n: sys_int_machine_t;        {number of discrete blending levels}
  out     table: rend_mipmap_blend_t); {resulting blending table}
  val_param;

var
  ind: 0..255;                         {current table entry index}
  lev: 0..511;                         {current quantized level}
  m: real;                             {0.0 to 1.0 mult factor for larger map}

begin
  for ind := 0 to 255 do begin         {once for each table entry to fill in}
    lev := trunc(n * ind/256 + 0.0001); {find 0 to N-1 level for this index}
    m := lev / n;                      {derivative fraction towards smaller map}
    m := math_log2(m + 1.0);           {0.0 to 1.0 weighting for smaller map}
    m := 1.0 - m;                      {make 0.0 to 1.0 weighting for larger map}
    table[ind] := trunc(m * 65536.0);  {fill in final fixed point table entry value}
    end;                               {back to do next table entry}
  end;
