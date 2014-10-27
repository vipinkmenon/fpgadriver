#!/bin/bash

#install driver
cd ../src/sw/driver/
sudo make setup
make 
sudo make install

#install shared sw library
cd ../userlib/
make
sudo make install

#install shared hw library
if [ -d /usr/include/fpga ];
then
    sudo rm -rf /usr/include/fpga
fi
sudo mkdir /usr/include/fpga
sudo cp -r -p ../../hw/fpga/source /usr/include/fpga/source
sudo cp -r -p ../../hw/fpga/ipcore_dir /usr/include/fpga/ipcore_dir

cd ../application/
make 
