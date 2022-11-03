# Arduino-FFB-gui

Graphical user interface for controlling and monitoring all aspects of the **[Arduino FFB wheel](https://github.com/ranenbg/Arduino-FFB-wheel)** via RS232 serial port. Wheel control v2.5 supports Arduino HEX firmware from v220 and onward, but it's backward compatible with v210, v200, v190, v180 and v170. You can use a stand alone wheel_control.exe file from the **[latest release](https://github.com/ranenbg/Arduino-FFB-gui/releases/latest)**, it already has all Java stuff embedded. For more details on how to setup and use the program correctly please read **[manual](https://github.com/ranenbg/Arduino-FFB-gui/tree/master/data/manual.txt)**. You can find some screenshots with step-by-step first time run setup process in **[data](https://github.com/ranenbg/Arduino-FFB-gui/tree/master/data)** folder.

### Screenshot of GUI v2.5
![plot](./data/Wheel_control_v2_5.png)

## Download - standalone app
+ ***[Latest Release](https://github.com/ranenbg/Arduino-FFB-gui/releases/latest)***
+ ***[Past Versions](https://github.com/ranenbg/Arduino-FFB-gui/releases)***

## How to compile the source

The GUI is made in Processing 3.5.4 IDE from scratch and requires latest Java 8. In order to compile the source yourself, you will need to install the following Processing libraries:

- game controls plus
- gp4 controls
- sprites
- control P5

Make sure that all pde files are located in the folder named wheel_control. Processing 3.5.4 IDE can be found here: <https://processing.org/download>

## Troubleshooting - first time run

The program will look for all virtual COM port devices plugged into your PC, but it doesn't know to which COM port your Arduino is assigned to. You can either follow the first time run setup process and select your Arduino COM port from there, or if you experience "stuck in black screen issue" you can do it manually. Locate the data folder and create a txt file named COM_cfg.txt (do not put .txt in the file name, it is just the file extension). Open this file and type COMx, where x is the 1 digit number of the COM port where your Arduino is located. You can find it in device manager under ports, example is COM5. Save the file and close it, then try to run wheel control exe again as administrator. If the problem still persits, you may try to install Processing IDE 3.5.4, donwload missing libraries and try to run it as a source code from there.
