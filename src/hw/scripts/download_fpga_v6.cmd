setmode -bscan
setCable -p auto
identify
assignfile -p 2 -file ../ISE/top_v6.bit
program -p 2
quit
