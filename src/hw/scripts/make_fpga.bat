ngdbuild -intstyle ise -dd _ngo -sd ..\fpga\ipcore_dir -nt timestamp -uc ..\fpga\source\v7_top.ucf -p xc7vx485t-ffg1761-2 top.ngc top.ngd
map -intstyle ise -p xc7vx485t-ffg1761-2 -w -o top_map.ncd top.ngd top.pcf
par -w -intstyle ise top_map.ncd top.ncd top.pcf