{   Subroutine REND_SW_TEXT_RAW (S, LEN)
*
*   Write a text string to the screen.  S is the string, and LEN is the number of
*   characters in the string.  The text is drawn directly to the VECT_TEXT primitive.
*   It is assumed that this primitive is already set up in the way desired for the
*   text operation.
}
module rend_sw_text_raw;
define rend_sw_text_raw;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_text_raw_d.ins.pas';

procedure rend_sw_text_raw (           {text string, assume VECT_TEXT all set up}
  in      s: univ string;              {string of bytes}
  in      len: string_index_t);        {number of characters in string}
  val_param;

var
  xc, yc: real;                        {current point in text coordinates}
  xstart, ystart: real;                {TEXT space start coor of string lower left}
  draw: boolean;                       {draw vectors if TRUE, always update XC,YC}
  width: real;                         {width of text string in text coordinates}
  i: sys_int_machine_t;                {loop counter}
  m: real;                             {UP vect mult factor for next line of text}
{
**************************************************
*
*   Internal subroutine DRAW_CHAR (C)
*
*   Draw the character C if DRAW is TRUE, and update the text coordinates current point
*   XC,YC.  If DRAW is set to FALSE, then just update XC,YC.  This may be done to
*   find out how long the character string is before drawing so support TORG values
*   of other than the left edge.
}
procedure draw_char (
  in      c: char);                    {the character to draw}

var
  x, y: rend_font_ar_entry_t;          {XY coordinate from font array}
  xs, ys: real;                        {TEXT space start coordinates of vector}
  ind: sys_int_machine_t;              {index into font array}
  move: boolean;                       {move/draw flag for this font array coordinate}

label
  vect_loop, done_char;

begin
  ind := ord(c) & 127;                 {make character code of this character}
  ind := rend_text_state.font[ind].i;  {get start index for this character descriptor}
  if ind <= 0 then return;             {no character here ?}
  xs := xc;                            {make initial point in draw space}
  ys := yc;

vect_loop:                             {back here for each new move/draw in character}
  x := rend_text_state.font[ind];      {fetch next X coordinate from font array}
  if x.i = -1 then goto done_char;     {hit end of this character definition ?}
  move := (x.i & 1) = 0;               {set move/draw flag for this font array coor}
  x.i := x.i & ~1;                     {mask off low move/draw bit}
  ind := ind+1;                        {advance font array index to next entry}
  y := rend_text_state.font[ind];      {fetch Y value of this point}
  ind := ind+1;                        {advance font array index to next entry}
  x.f := x.f+xc;                       {make character string coor of this point}
  y.f := y.f+yc;
  if draw then begin                   {we are actually supposed to draw the char ?}
    if move                            {check for MOVE or DRAW command}
      then begin                       {this is a MOVE command}
        rend_set.cpnt_text^ (x.f, y.f); {set current point to this coordinate}
        end
      else begin                       {this a DRAW command}
(*
        rend_set.exit_rend^;
        writeln ('Draw to', x.f:8:3, ',', y.f:8:3);
        rend_set.enter_rend^;
*)
        rend_prim.vect_text^ (x.f, y.f); {draw vector to this coordinate}
        end
      ;
    end;                               {done with drawing enabled}
  xs := x.f;                           {update current point within this char}
  ys := y.f;
  goto vect_loop;                      {back for next coordinate in this character}

done_char:                             {done with all coordinates in this character}
  xc := xs;                            {update char space curr point after this char}
  yc := ys;
  end;
{
**************************************************
*
*   Internal subroutine FIND_WIDTH (N_CHAR, CHARS, W)
*
*   Set the WIDTH variable to the width of the text string in text coordinates.
*   This is used if the start text origin is other than at the left edge.
}
procedure find_width (
  in      n_char: string_index_t;      {number of characters in string}
  in      chars: univ string;          {string to find width for}
  out     w: real);                    {returned string width}

var
  j: sys_int_machine_t;                {loop counter}

begin
  xc := 0.0;                           {init text coordinate current point}
  yc := 0.0;
  for j := 1 to n_char do begin        {once for each character in string}
    draw_char (chars[j]);              {draw this character}
    end;                               {back for next character in string}
  w := xc;                             {width is baseline offset of string}
  end;
{
**************************************************
*
*   Code for main routine.
}
begin
  draw := false;                       {init to do not draw anything yet}
  case rend_text_parms.start_org of    {where to anchor text string to current point}
rend_torg_ul_k: begin                  {upper left}
      xc := 0.0;
      yc := -1.0;
      end;
rend_torg_um_k: begin                  {upper middle}
      find_width (len, s, width);
      xc := -0.5*width;
      yc := -1.0;
      end;
rend_torg_ur_k: begin                  {upper right}
      find_width (len, s, width);
      xc := -width;
      yc := -1.0;
      end;
rend_torg_ml_k: begin                  {middle left}
      xc := 0.0;
      yc := -0.5;
      end;
rend_torg_mid_k: begin                 {middle}
      find_width (len, s, width);
      xc := -0.5*width;
      yc := -0.5;
      end;
rend_torg_mr_k: begin                  {middle right}
      find_width (len, s, width);
      xc := -width;
      yc := -0.5;
      end;
rend_torg_ll_k: begin                  {lower left}
      xc := 0.0;
      yc := 0.0;
      end;
rend_torg_lm_k: begin                  {lower middle}
      find_width (len, s, width);
      xc := -0.5*width;
      yc := 0.0;
      end;
rend_torg_lr_k: begin                  {lower right}
      find_width (len, s, width);
      xc := -width;
      yc := 0.0;
      end;
otherwise
    writeln ('Bad value of text parameter START_ORG found.');
    sys_bomb;
    end;                               {done with START_ORG cases}

  draw := true;                        {now draw the text string for real}
  xstart := xc;                        {save text space starting point}
  ystart := yc;
  rend_get.cpnt_txdraw^ (              {set TEXT space origin to TXDRAW curr point}
    rend_text_state.sp.ofs.x,
    rend_text_state.sp.ofs.y);
{
*   Actually draw the characters.
}
  for i := 1 to len do begin           {once for each character in text string}
    draw_char (s[i]);                  {draw this character}
    end;                               {back and do next character}
{
*   Done drawing the characters.
}
  width := xc-xstart;                  {make width in case not done earlier}

  case rend_text_parms.end_org of      {where to leave current point after string}
rend_torg_ul_k:                        {upper left}
    rend_set.cpnt_text^ (xstart, ystart+1.0);
rend_torg_um_k:                        {upper middle}
    rend_set.cpnt_text^ (xstart+0.5*width, ystart+1.0);
rend_torg_ur_k:                        {upper right}
    rend_set.cpnt_text^ (xstart+width, ystart+1.0);
rend_torg_ml_k:                        {middle left}
    rend_set.cpnt_text^ (xstart, ystart+0.5);
rend_torg_mid_k:                       {middle}
    rend_set.cpnt_text^ (xstart+0.5*width, ystart+0.5);
rend_torg_mr_k:                        {middle right}
    rend_set.cpnt_text^ (xstart+width, ystart+0.5);
rend_torg_ll_k:                        {lower left}
    rend_set.cpnt_text^ (xstart, ystart);
rend_torg_lm_k:                        {lower middle}
    rend_set.cpnt_text^ (xstart+0.5*width, ystart);
rend_torg_lr_k:                        {lower right}
    rend_set.cpnt_text^ (xstart+width, ystart);
rend_torg_down_k: begin                {down char height + lspace from start point}
      m := -1.0-rend_text_parms.lspace; {make mult factor for UP vector}
      rend_set.cpnt_txdraw^ (          {move directly to new curr pnt in TXDRAW space}
        rend_text_state.sp.ofs.x + m*rend_text_state.up.x,
        rend_text_state.sp.ofs.y + m*rend_text_state.up.y);
      end;
rend_torg_up_k: begin                  {up char height + lspace from start point}
      m := 1.0+rend_text_parms.lspace; {make mult factor for UP vector}
      rend_set.cpnt_txdraw^ (          {move directly to new curr pnt in TXDRAW space}
        rend_text_state.sp.ofs.x + m*rend_text_state.up.x,
        rend_text_state.sp.ofs.y + m*rend_text_state.up.y);
      end;
otherwise
    writeln ('Bad value of text parameter END_ORG found.');
    sys_bomb;
    end;                               {done with END_ORG cases}
  end;
