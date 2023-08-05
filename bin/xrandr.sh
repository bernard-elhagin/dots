#!/bin/bash

# Home computer
if [[ hostname == "magrathea" ]]
then
    xrandr --newmode "2560x1440" 241.50 2560 2608 2640 2720 1440 1443 1448 1481 +hsync -vsync
    xrandr --addmode VGA-1 "2560x1440"
    xrandr --output VGA-1 --mode 2560x1440
else [[ hostname == "bertold-virtualbox" ]]
    xrandr --newmode "1920x1080" 241.50 2560 2608 2640 2720 1440 1443 1448 1481 +hsync -vsync
    xrandr --addmode Virtual1 "1920x1080"
    xrandr --output Virtual1 --mode 1920x1080
fi
