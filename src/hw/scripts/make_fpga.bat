C:\Xilinx\14.7\ISE_DS\ISE\bin\nt64\ngdbuild -intstyle ise -dd _ngo -sd ..\fpga\ipcore_dir -nt timestamp -uc ..\fpga\source\v7_top.ucf -p xc7vx485t-ffg1761-2 top.ngc top.ngd
C:\Xilinx\14.7\ISE_DS\ISE\bin\nt64\map -intstyle ise -p xc7vx485t-ffg1761-2 -w -o top_map.ncd top.ngd top.pcf
C:\Xilinx\14.7\ISE_DS\ISE\bin\nt64\par -w -intstyle ise top_map.ncd top.ncd top.pcf