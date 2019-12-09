{   Defines all the common blocks in this library.
}
module rend_sw_comblock;
%include 'rend_sw2.ins.pas';
{
*   Define all the common blocks visible to any part of base RENDlib and
*   the SW driver.
}
define rend;                           {user-visible common block}
define rend2;                          {holds state above all the drivers}
define rend_sw;                        {SW driver state, visible to all drivers}
