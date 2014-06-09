#!/bin/bash
sudo chown $(whoami):$(whoami) /sys/bus/pci/devices/*$(lspci | grep Xilinx | awk '{print $1}')/config
sudo cp -p /sys/bus/pci/devices/*$(lspci | grep Xilinx | awk '{print $1}')/config ~/workspace/
