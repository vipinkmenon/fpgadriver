setmode -bscan
setCable -p auto
identify
assignfile -p 1 -file ../ISE/v7_top.bit
program -p 1
quit
