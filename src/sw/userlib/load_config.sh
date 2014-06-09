#!/bin/bash
cp -p ~/workspace/config /sys/bus/pci/devices/*$(lspci | grep Xilinx | awk '{print $1}')/ 
