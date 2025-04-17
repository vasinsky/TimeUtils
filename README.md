# TimeUtils
TimeUtils for MUOS on Love2D

The program is written for MUOS and is installed via the ARCHIVE manager

The testing cases are as follows (for exit: press select + start)

1) checking the control buttons: dpad and the left stick are responsible for moving between hours-minutes-seconds and setting values, start or A - for starting/pausing the timer, select - for switching to the timer value setting mode

2) if there is more than 10 seconds left - it is possible to set a pause and continue running the timer, if there is less than 10 seconds left - a pause and switching to the setting is impossible

3) if the value remaining is 10 seconds on the timer - an audible notification occurs (short peaks with an interval of 1 second), at the end of the time a 2-second sound signal

I am interested in tests on various devices, with different diagonals and processors

I tested on H700 640x480 RG35xx H

```
Menu
----------------------------------------------------------------------------
start/a - launch the utility you are interested in

Countdown timer
-----------------------------------------------------------------------------
d-pad - switch between hours, minutes, seconds and set the desired timer time
start/a - start/pause
x - exit to the menu

Stopwatch
-----------------------------------------------------------------------------
start/a - start/pause
x - exit to the menu

Themes and fonts
----------------------------------------------------------------------------
L1 R1 - change color scheme
L2 R2 - change font
```
