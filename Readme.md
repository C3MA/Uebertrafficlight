# Ueber Traffic Light
## Setup
Generate a wlancfg.lua for your wifi based on the given example wlancfg.lua.example

Copy the required files to the microcontroller:
sudo ./programESP.sh serial wlancfg.lua.lua wlancfg.lua
sudo ./programESP.sh serial init.lua init.lua

## Internal Setup
There is an Mosfet on each of the following GPIOs.
* GPIO16
* GPIO14
* GPIO12

Each MOSFET contorls each lamp, like this:
<pre>
    24V -----(x)-----[]---- GND
                     |
               GPIO of ESP
</pre>
