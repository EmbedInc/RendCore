{   System dependent part of REND_SW.INS.PAS.  True OS dependencies should be
*   handled by other mechanisms.  This file is used mostly to declare data types
*   that depend on machine byte order.
*
*   This version is for systems with backwards byte ordering (LSB stored first).
}
type
  rend_iterp_val_t = packed record case integer of {interpolation value}
    1:(
      frac: 0..65535;                  {interpolant value below binary point}
      val16: integer16);               {16 bit interpolant value above binary point}
    2:(
      unused1: integer16;
      val8: 0..255;                    {8 bit interpolant value above binary point}
      ovfl: -128..127);                {8 overflow bits above interpolant value}
    3:(
      unused2: integer16;
      val8s: -128..127);               {signed 8 bit interpolant value}
    4:(
      val32: integer32);
    5:(
      all: integer32);                 {all the bits together}
    end;
