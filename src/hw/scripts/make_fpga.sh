#!/bin/bash


#check the target fpga platform and if nothing is specified, raise an error
if [ $# -ne 1 ]; then
    echo "Target FPGA should be specified as ml605 or vc707"
elif [ "$1" == "ml605" ]; then
    xtclsh ml605_cmd.tcl rebuild_project
    cp top.bit ml605.bit
elif [ "$1" == "vc707" ]; then
    xtclsh vc707_cmd.tcl rebuild_project
    cp top.bit vc707.bit
fi
