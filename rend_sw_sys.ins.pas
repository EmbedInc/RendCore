{   System dependent part of REND_SW.INS.PAS.  True OS dependencies should be
*   handled by other mechanisms.  This file is used mostly to declare data types
*   that depend on machine byte order.
*
*   This is the default version, which assumes FORWARDS byte order (MSB stored
*   first).
}
type
  rend_iterp_val_t = packed record case integer of {interpolation value}
    1:(
      val16: integer16;                {16 bit interpolant value above binary point}
      frac: 0..65535);                 {interpolant value below binary point}
    2:(
      ovfl: -128..127;                 {8 overflow bits above interpolant value}
      val8: 0..255);                   {8 bit interpolant value above binary point}
    3:(
      unused: -128..127;
      val8s: -128..127);               {signed 8 bit interpolant value}
    4:(
      val32: integer32);
    5:(
      all: integer32);                 {all the bits together}
    end;
