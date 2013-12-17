#!/bin/bash

#uninstall driver
cd ../src/sw/driver/
sudo make uninstall

#uninstall shared sw library
if [ -d /usr/lib/libfpga.so ];
then
    sudo rm /usr/lib/libfpga.so
fi

#uninstall shared hw library
sudo rm -rf /usr/include/fpga


