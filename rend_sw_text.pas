{   Subroutine REND_SW_TEXT (S, LEN)
*
*   Write a text string to the screen.  S is the string, and LEN is the number of
*   characters in the string.  The current text parameter setting will be used to
*   set up the VECT_TEXT primitive as necessary.  the TEXT_RAW primitive will then
*   be used to draw the actual text.
}
module rend_sw_text;
define rend_sw_text;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_text_d.ins.pas';

procedure rend_sw_text (               {text string, use current text parms}
  in      s: univ string;              {string of bytes}
  in      len: string_index_t);        {number of characters in string}
  val_param;

const
  cap_sides = 6;                       {number of sides to a vector end cap}

var
  old_vparms: rend_vect_parms_t;       {vector control parameters before text}
  vparms: rend_vect_parms_t;           {vector control parameters used for text}

begin
  if rend_text_parms.poly then begin   {draw text vectors as polygons ?}
    rend_get.vect_parms^ (old_vparms); {get current vector parameters}
    vparms := old_vparms;              {init to what is already there}
    vparms.poly_level := rend_space_txdraw_k; {convert to polygons in TXDRAW space}
    vparms.width :=                    {width of vectors when polygons}
      rend_text_parms.vect_width * rend_text_parms.size;
    vparms.start_style.style := rend_end_style_circ_k; {circular start cap}
    vparms.start_style.nsides := cap_sides; {number of sides to start cap}
    vparms.end_style.style := rend_end_style_circ_k; {circular end cap}
    vparms.end_style.nsides := cap_sides; {number of sides to end cap}
    rend_set.vect_parms^ (vparms);     {set new current vector parameters}
    end;                               {done setting up for drawing polygons}

  rend_prim.text_raw^ (s, len);        {draw the text}

  if rend_text_parms.poly then begin   {drawing text as polygons ?}
    rend_set.vect_parms^ (old_vparms); {restore old vector parameters}
    end;
  end;
