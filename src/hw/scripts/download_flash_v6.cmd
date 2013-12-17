setmode -bscan
setCable -p auto
identify
attachflash -position 2 -bpi "XCF128X"
assignfiletoattachedflash -position 2 -file "top_v6.mcs"
Erase -p 2
Program -p 2 -dataWidth 16 -rs1 NONE -rs0 NONE -bpionly -e -v -loadfpga
quit
