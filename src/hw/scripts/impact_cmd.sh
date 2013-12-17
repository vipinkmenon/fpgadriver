#!/bin/bash
# Call this script with at least 2 parameters
# impact_cmd device target
# device options - v6/v7
# target options - fpga/flash

if [ $# -ne 2 ]; then
    echo "Invalid number of parameters"
elif [ "$1" == "v6" ]; then
        if [ "$2" == "fpga" ]; then 
            impact -batch download_fpga_v6.cmd
        elif [ "$2" == "FPGA" ]; then 
            impact -batch download_fpga_v6.cmd
        elif [ "$2" == "flash" ]; then 
            impact -batch download_flash_v6.cmd
        elif [ "$2" == "FLASH" ]; then 
            impact -batch download_flash_v6.cmd
        else 
            echo "Invalid Target for v6 Board - Options fpga/flash"
        fi
elif [ "$1" == "v7" ]; then
        if [ "$2" == "fpga" ]; then 
            impact -batch download_fpga_v7.cmd
        elif [ "$2" == "FPGA" ]; then 
            impact -batch download_fpga_v7.cmd
        elif [ "$2" == "flash" ]; then 
            impact -batch download_flash_v7.cmd
        elif [ "$2" == "FLASH" ]; then 
            impact -batch download_flash_v7.cmd
        else 
            echo "Invalid Target for v7 Board - Options fpga/flash"
	fi
else
        echo "Invalid Device - Options v6/v7"
fi
