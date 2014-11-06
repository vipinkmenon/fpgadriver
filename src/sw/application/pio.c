#include <stdio.h>
#include "fpga.h"

main()
{
 int rtn;
 rtn = fpga_reg_rd(0x0);
 printf("Version Number : %0d",rtn);
 printf("Writing scratch pad register with 0x1234abcd\n");
 fpga_reg_wr(0x4,0x1234abcd);
 printf("Reading from scrat pad register\n");
 rtn = fpga_reg_rd(0x4);
 printf("Scratch pad register : %0x",rtn);
 return 0;
}
