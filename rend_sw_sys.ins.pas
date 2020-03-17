{   System dependent part of REND_SW.INS.PAS.  True OS dependencies should be
*   handled by other mechanisms.  This file is used mostly to declare data types
*   that depend on machine byte order.
*
*   This file is a hack for now.  Uncomment the appropriate section for the
*   particular target machine.  A better mechanism is needed to automatically
*   select sections of include file code depending on the native machine byte
*   ordering, but that is for a later time.
}

{
********************************************************************************
*
*   Forwards byte ordering (multi-byte data is stored in most to least
*   significant byte order).
}
(*
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
*)
{
********************************************************************************
*
*   Backwards byte ordering (multi-byte data is stored in least to most
*   significant byte order).
}
type
  rend_iterp_val_t = packed record case integer of {interpolation value}
    1:(
      frac: 0..65535;                  {interpolant value below binary point}
      val16: integer16);               {16 bit interpolant value above binary point}
    2:(
     unused1: 0..65535;
      val8: 0..255;                    {8 bit interpolant value above binary point}
      ovfl: -128..127);                {8 overflow bits above interpolant value}
    3:(
      unused2: 0..65535;
      val8s: -128..127;                {signed 8 bit interpolant value}
      unused3: 0..255;
    4:(
      val32: integer32);               {full 32 bit integer}
    5:(
      all: integer32);                 {all the bits together}
    end;
