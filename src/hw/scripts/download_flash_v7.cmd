setmode -bscan
setCable -p auto
identify
attachflash -position 1 -bpi "XCF128X"
assignfiletoattachedflash -position 1 -file "top_v7.mcs"
Erase -p 1
Program -p 1 -dataWidth 16 -rs1 NONE -rs0 NONE -bpionly -e -v -loadfpga
quit