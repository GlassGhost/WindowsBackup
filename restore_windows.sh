#!/bin/bash
owd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" #Path to THIS script.

xz -dc $owd/ComputerName_DriveName.boot.xz | sudo dd of=/dev/sda
xz -dc $owd/ComputerName_OSname.ntfsclone.xz | sudo ntfsclone -rO /dev/sda1 -