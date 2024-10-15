/*Arduino Force Feedback Wheel User Interface
 
 Copyright 2018-2024  Milos Rankovic (ranenbg [at] gmail [dot] com)
 
 Permission to use, copy, modify, distribute, and sell this
 software and its documentation for any purpose is hereby granted
 without fee, provided that the above copyright notice appear in
 all copies and that both that the copyright notice and this
 permission notice and warranty disclaimer appear in supporting
 documentation, and that the name of the author not be used in
 advertising or publicity pertaining to distribution of the
 software without specific, written prior permission.
 
 The author disclaim all warranties with regard to this
 software, including all implied warranties of merchantability
 and fitness.  In no event shall the author be liable for any
 special, indirect or consequential damages or any damages
 whatsoever resulting from loss of use, data or profits, whether
 in an action of contract, negligence or other tortious action,
 arising out of or in connection with the use or performance of
 this software.
 */

import org.gamecontrolplus.gui.*;
import org.gamecontrolplus.*;
import net.java.games.input.*;
import g4p_controls.*;
import processing.serial.*;
import sprites.*;
import sprites.maths.*;
import sprites.utils.*;
import controlP5.*;
import java.util.*;
import static javax.swing.JOptionPane.*;

String cpVer="v2.6.1"; // control panel version

Serial myPort;  // Create object from Serial class
String rb;     // Data received from the serial port
String wb;     // Data to send to the serial port
final boolean debug = true;

Sprite[] sprite = new Sprite[1];
Domain domain;

ControlP5 cp5; // Editable Numberbox for ControlP5
Numberbox num1; // create instance of numberbox class

int num_sldr = 12; //number of FFB sliders
int num_btn = 24;  //number of wheel buttons
int ctrl_btn = 18; //number of control buttons
int ctrl_sh_btn = 5; //number of control buttons for XY shifter
int ctrl_axis_btn = 8; //number of control buttons for gamepad axis
int key_btn = 12;  //number of keyboard function buttons
int gbuffer = 500; //number of points to show in ffb graph
int gskip = 8; //ffb monitor graph vertical divider
int num_profiles = 11; //number of FFB setting profiles (including default profile)
int num_prfset = 16; //number of FFB settings inside a profile
int cur_profile; // currently loaded FFB settings profile
String[] command = new String[num_sldr]; // commands for wheel FFB parameters set
float[] wParmFFB = new float[num_sldr]; // current wheel FFB parameters
float[] wParmFFBprev = new float[num_sldr]; // previous wheel FFB parameters
float[] defParmFFB = new float[num_sldr]; // deafault wheel FFB parameters
GCustomSlider[] sdr = new GCustomSlider [num_sldr];
String[] sliderlabel = new String[num_sldr];
float[] slider_value = new float[num_sldr];
boolean parmChanged = false; // keep track if any FFB parm was changed
boolean wheelMoved = false; // keep track if wheel axis is centered
float prevaxis = 0.0; // previous steer axis value 
int[] col = new int[3]; // colors for control buttons, hsb mode
int thue; // color for text of control button, gray axisScale mode
boolean[] buttonpressed = new boolean[ctrl_btn]; // true if button is pressed
String[] description = new String[key_btn]; // keyboard button function description
String[] keys = new String[key_btn]; // keyboard buttons
boolean enableinfo = true;
boolean dActByp = true; // if true, it will bypass wheel buttons' ability to be inactivated (gray)
byte effstate, effstateprev, effstatedef; // current, previous and default desktop effect state in binary form
byte pwmstate, pwmstateprev, pwmstatedef; // current, previous and default pwm settings in binary form
boolean typepwm; // keeps track of PWM type settings
int freqpwm, modepwm; // keeps track of PWM frequency index selection and pwm mode settings
int minTorque, maxTorque, maxTorquedef; // min, max ffb value or PWM steps
int curCPR, lastCPR, CPRdef;
int maxCPR = 99999; // maximum acceptable CPR by firmware
float deg_min = 30.0; // minimal allowed angle by firmware
float deg_max = 1800.0; // maximal allowed angle by firmware
int maxCPR_turns = maxCPR*int(deg_max/360.0); // maximum acceptable CPRxturns by firmware
float minPWM_max = 20.0; // maximum allowed value for minPWM
float brake_min = 1.0; // minimal brake pressure
float brake_max = 255.0; // max brake pressure
boolean fbmnstp = false; // keeps track if we deactivated ffb monitor
String fbmnstring; // string from ffb monitor readout
String COMport[]; // string for serial port on which Arduino Leonardo is reported
boolean BBenabled = false; // keeps track if button box is supported (3 digit fw's ending with 1)
boolean BMenabled = false; // keeps track if button matrix is supported (option "t") 
boolean LCenabled = false; // keeps track if load cell is supported (3 digit fw's ending with 2)
boolean DACenabled = false; // keeps track if FFB DAC output is supported in firmware (3 digit fw's ending with 3)
boolean checkFwVer = true; // when enabled update fwVersion will take place
boolean enabledac, modedac; // keeps track of DAC output settings
boolean profileActuated = false; // keeps track if we pressed the profile selection
boolean CPRlimit = false; // true if we input more than max allowed CPR
boolean pwm0_50_100enabled = false; // true if firmware supports pwm0.50.100 mode
boolean pwm0_50_100selected = false; // keeps track if pwm0.50.100 mode is selected
boolean RCMenabled = false; // true if firmware supports RCM pwm mode
boolean RCMselected = false; // keeps track if RCM pwm mode is selected
boolean AFFBenabled = false; // keeps track if analog FFB axis is available
int rbt_ms = 0; // read buffer response time in milliseconds
String FullfwVerStr; // Arduino firmware version including the options
String fwVerStr; // Arduino firmware version not including the options
int fwVerNum; // Arduino firmware version digits only
byte fwOpt; // Arduino firmware options 1st byte, if present bit is HIGH (b0-a, b1-z, b2-h, b3-s, b4-i, b5-m, b6-t, b7-f)
byte fwOpt2; // Arduino firmware options 2nd byte, if present bit is HIGH (b0-e, b1-x, b2-w, b3-c, b4-r, b5-, b6-, b7-)
boolean clutchenabled = true; // true if firmware supports clutch analog axis (not the case only for fw option "e")
boolean hbrakeenabled = true; // true if firmware supports handbrake analog axis (not the case only for fw option "e")
int Xoffset = -44; // X-axis offset for buttons
boolean XYshifterEnabled = false; // keeps track if XY analog shifter is supported by firmware
int shifterLastConfig[] = new int[6]; // last XY shifter calibration and configuration settings
String[] shCommand = new String[ctrl_sh_btn+3]; // commands for XY shifter settings
int[] xysParmDef = new int [6]; // XY shifter defaults
String[] pdlCommand = new String[9]; // commands for pedal calibration
float[] pdlMinParm = new float [4]; // curent pedal minimum cal values
float[] pdlMaxParm = new float [4]; // curent pedal maximum cal values
float[] pdlParmDef = new float [8]; // default pedal cal values
// pwm frequency selection possibilities - depends on firmware version and RCM mode
List a = Arrays.asList("40.0 kHz", "20.0 kHz", "16.0kHz", "8.0 kHz", "4.0 kHz", "3.2 kHz", "1.6 kHz", "976 Hz", "800 Hz", "488 Hz"); // for fw-v200 or lower
List a1 = Arrays.asList("40.0 kHz", "20.0 kHz", "16.0kHz", "8.0 kHz", "4.0 kHz", "3.2 kHz", "1.6 kHz", "976 Hz", "800 Hz", "488 Hz", "533 Hz", "400 Hz", "244 Hz"); // wider pwm freq selection (fw-v210+), no RCM selected
List a2_rcm = Arrays.asList("na", "na", "na", "na", "500 Hz", "400 Hz", "200 Hz", "122 Hz", "100 Hz", "61 Hz", "67 Hz", "50 Hz", "30 Hz"); // alternate pwm freq selection if RCM selected
int allowedRCMfreqID = 4; // first allowed pwm freq ID for RCM mode from the above list (anything after and including 500Hz is allowed)
int FFBAxisIndex; // index of axis that is tied to the FFB axis (bits 5-7 from effstate byte)
int setupTextLines = 20; // number of available lines for text in configuration window
String[] setupTextBuffer = new String[setupTextLines]; // array that holds all text for configuration window
int setupTextTimeout_ms = 5000; // show setup text only during this timeout in [ms]
int setupTextTimer; // keeps track of ms passed since starting to display GUI (configuration and fw readout already done)

GImageToggleButton[] btnToggle = new GImageToggleButton[2];

ControlIO control;
Configuration config;
ControlDevice gpad; 

// gamepad axis array
float[] Axis = new float[5];
float axisValue;
float axisScaledValue;
// gamepad button array
boolean[] Button = new boolean [num_btn];
boolean buttonValue = false;
// gamepad D-pad
int[] Dpad = new int[8];
int hatvalue;
// control buttons
boolean[] controlb = new boolean[ctrl_btn+ctrl_sh_btn+ctrl_axis_btn]; // true as long as mouse is howered over

PFont font;
int font_size = 12;

int axisScale = 250; // length of axis ruler axisScale
int Nbits = 16; // wheel's X-axis number of bits (resolution)
int real_wheelTurn = 900; // physical range of wheels rotation in degrees (lock to lock) - what you set in wheel driver
int lfs_wheelTurn = 900; // software range of wheels rotation in degrees (lock to lock) - what you set in lfs as wheelturn
int lfs_car_wheelTurn = 450; // software range of car's wheel rotation in degrees (lock to lock) - specific to each lfs car
float lfs_compensation = 1.0; // lfs compensation factor
int xAxis_log_max;
float level, posY;

float coef1; // linear coef
float coef2; // quadratic coef
float coef3; // cubic coef

int slider_width = 400;
int slider_height = 110;
int sldXoff = 100;
float slider_max = 2.0;
int num_axis = 5; // number of axis to display
color[] axis_color = new color [num_axis];

Wheel[] wheels = new Wheel [1];
Slajder[] slajderi = new Slajder[num_axis];
Dugme[] dugmici = new Dugme[num_btn];
HatSW[] hatsw = new HatSW[1];
//Graph[] graphs = new Graph [1];
Dialog[] dialogs = new Dialog [1];
Button[] buttons = new Button[ctrl_btn];
Info[] infos = new Info[key_btn];
FFBgraph[] ffbgraphs = new FFBgraph[1];
Profile[] profiles = new Profile[num_profiles];
XYshifter[] shifters = new XYshifter[1];
InfoButton[] infobuttons = new InfoButton [1];

void setup() {
  size(1440, 800, JAVA2D);
  colorMode (HSB);
  frameRate(100);
  //noSmooth();
  smooth(2);
  background(51);
  //PImage icon = loadImage("/data/rane_wheel_rim_O-shape.png");
  //surface.setIcon(icon);
  println("=======================================================\n  Arduino Leonardo FFB user interface\t\n  wheel control "+cpVer +" created by Milos Rankovic");
  clearSetupText();
  showSetupText("Configuring wheel control");
  File f = new File(dataPath("COM_cfg.txt"));
  //https://docs.oracle.com/javase/tutorial/uiswing/components/dialog.html
  if (!f.exists()) showMessageDialog(frame, "COM_cfg.txt was not found in your PC, but do not worry.\nYou either run the app for the 1st time, or you have\ndeleted the configuration file for a fresh start.\n\t\nPress OK to continue with the automatic setup process.", "Arduino FFB Wheel " + cpVer +" - Hello World :)", INFORMATION_MESSAGE);
  if (!f.exists()) showMessageDialog(frame, "Setup will now try to find control IO instances.\n", "Setup - step 1/3", INFORMATION_MESSAGE);
  // Initialise the ControlIO
  //showSetupText("Initializing IO instances");
  control = ControlIO.getInstance(this);
  println("Instance:", control);
  // Find a device that matches the configuration file
  if (!f.exists()) showMessageDialog(frame, "Step 1 of setup has passed succesfully.\nSetup will now try to look for available game devices in your PC.\n", "Setup - step 2/3", INFORMATION_MESSAGE);
  String inputdevices = "";
  inputdevices = control.deviceListToText("");
  if (!f.exists()) showMessageDialog(frame, "\nThe following devices are found in your PC:\n\t\n"+inputdevices+"\nThe setup will now try to configure each device, but bare in mind that some devices may cause the app to crash.\nIf that happens, you may try to manually create COM_cfg.txt file (see manual.txt in data folder for instructions),\nor you may try to run wheel_control.pde source code from Processsing IDE version 3.5.4.\n", "Setup - list of available devices", INFORMATION_MESSAGE);
  println(inputdevices);
  //showSetupText("Looking for compatible devices");
  gpad = control.getMatchedDevice("Arduino Leonardo wheel v5");
  if (gpad == null) {
    println("No suitable device found");
    showSetupText("No suitable device found");
    System.exit(-1); // End the program NOW!
  } else {
    showSetupText("Found device: " + gpad);
    println("Device:", gpad);
  }
  int r;
  //println("   config:",f.exists());
  if (f.exists()) { // if there is COM_cfg.txt, load serial port number from cfg file
    COMport = loadStrings("/data/COM_cfg.txt");
    println("COM: loaded from txt");
    myPort = new Serial(this, COMport[0], 115200);
  } else {  // open window for selecting available COM ports
    println("COM: searching...");
    r = COMselector();
    if (r == 0) {
      System.exit(-1); // if errors or Arduino not connected
      println("COM: error");
    } else {
      String set[] = {Serial.list()[r]};
      saveStrings("/data/COM_cfg.txt", set);  //save COM port of Arduino in a file
      println("config: saved");
    }
  }
  myPort.bufferUntil(char(10)); // read serial data utill line feed character

  // Open whatever port is the one you're using.
  //String portName = Serial.list()[2]; //change the 0 to a 1 or 2 etc. to match your port
  //myPort = new Serial(this, portName, 115200);
  //myPort = new Serial(this, "COM5", 115200);

  font = createFont("Arial", 16, true);
  textSize(font_size);

  posY = height - (2.2*axisScale);

  // Create the sprites
  Domain domain = new Domain(0, 0, width, height);
  sprite[0] = new Sprite(this, "rane_wheel_rim_O-shape.png", 10);
  //sprite[0] = new Sprite(this, "rane_wheel_rim_D-shape.png", 10);
  //sprite[0] = new Sprite(this, "TX_wheel_rim_small_alpha.png", 10);
  sprite[0].setVelXY(0, 0);
  sprite[0].setXY(0.038*width+0.5*axisScale, posY-72);
  sprite[0].setDomain(domain, Sprite.REBOUND);
  sprite[0].respondToMouse(false);
  sprite[0].setZorder(20);
  //sprite[0].setScale(0.9);

  //for (int i = 0; i < wheels.length; i++) {
  wheels[0] = new Wheel(0.05*width+0.5*axisScale, posY-80, axisScale*0.9, str(frameRate));
  //wheels[1] = new Wheel(width/2+1.8*axisScale, height/2, axisScale*0.9, "LFS car's wheel Y");
  //}

  SetAxisColors(); // checks for existing colors in txt file

  slajderi[0] = new Slajder(axis_color[0], width/3.65 + 0*60, height-posY, 10, 65535, "X", "0", "0", false);
  slajderi[1] = new Slajder(axis_color[1], width/3.65 + 1*60, height-posY, 10, 1023, "Y", "a", "b", false);
  slajderi[2] = new Slajder(axis_color[2], width/3.65 + 2*60, height-posY, 10, 1023, "Z", "c", "d", false);
  slajderi[3] = new Slajder(axis_color[3], width/3.65 + 3*60, height-posY, 10, 1023, "RX", "e", "f", false);
  slajderi[4] = new Slajder(axis_color[4], width/3.65 + 4*60, height-posY, 10, 1023, "RY", "g", "h", false);

  for (int i=0; i<slajderi.length; i++) {
    slajderi[i].update(i);
  }
  prevaxis = slajderi[0].axisVal;

  for (int j = 0; j < dugmici.length; j++) { // wheel buttons
    if (j <= 7) {
      dugmici[j] = new Dugme(0.05*width +j*28, height-posY*1.85, 18);
    } else if (j > 7 && j < 16) {
      dugmici[j] = new Dugme(0.05*width +(j-8)*28, height-posY*1.85+28, 18);
    } else if (j > 15 && j < 24) {
      dugmici[j] = new Dugme(0.05*width +(j-16)*28, height-posY*1.85+2*28, 18);
    }
  }

  dialogs[0] = new Dialog(0.05*width, height-posY*1.85+3*28, 16, "waiting input..");

  // general control push buttons
  buttons[1] = new Button(Xoffset+width/2 + 6.35*60, height-posY+140, 50, 16, "default", "load default settings", 0);
  buttons[8] = new Button(Xoffset+width/2 + 7.6*60, height-posY+140, 38, 16, "save", "save all settings to arduino", 0);
  buttons[9] = new Button(Xoffset+width/2 + 5.3*60, height-posY+140, 38, 16, "pwm", "save pwm settings to arduino (arduino reset required)", 0);
  buttons[10] = new Button(Xoffset+width/2 + 10.04*60, height-posY+140, 38, 16, "store", "save all settings to PC", 0);

  // info buttons for displaying some settings
  String[] enc = new String[2];
  enc[0] = "opt."; // optical quadrature encoder
  enc[1] = "mag"; // magnetic encoder
  infobuttons[0] = new InfoButton (0.05*width + 3.45*60, height-posY-490, 70, 16, 2, enc, "enc. type", 0);

  // encoder and pedal calibration buttons
  buttons[0] = new Button(0.05*width + 3.45*60, height-posY-270, 48, 16, "center", "set to 0°", 0);
  buttons[14] = new Button(0.05*width + 4.3*60, height-posY-270, 18, 16, "z", "reset", 0);
  buttons[2] = new Button(width/3.7 + 2.9*60, height-posY+31, 70, 16, "auto pcal", "reset", 3);
  buttons[13] = new Button(width/3.7 + 2.9*60, height-posY+50, 70, 16, "man. pcal", "set cal", 3);

  // h-shifter buttons
  buttons[11] = new Button(width/3.7 + 1.0*60, height-posY+31, 63, 16, "H-shifter", "set cal", 0);
  buttons[12] = new Button(width/3.7 + 2.1*60, height-posY+31, 16, 16, "r", "8th", 3);
  buttons[15] = new Button(width/3.7 + 1.0*60, height-posY+50, 16, 16, "x", "inv", 2);
  buttons[16] = new Button(width/3.7 + 1.3*60, height-posY+50, 16, 16, "y", "inv", 3);
  buttons[17] = new Button(width/3.7 + 2.1*60, height-posY+50, 16, 16, "b", "inv", 3);

  // optional and ffb effect on/off toggle buttons
  buttons[3] = new Button(sldXoff+width/2+slider_width+60, slider_height/2*(1+8)-12, 16, 16, " ", "autocenter spring", 3);
  buttons[4] = new Button(sldXoff+width/2+slider_width+60, slider_height/2*(1+2)-12, 16, 16, " ", "user damper", 3);
  buttons[5] = new Button(sldXoff+width/2+slider_width+60, slider_height/2*(1+7)-12, 16, 16, " ", "user inertia", 3);
  buttons[6] = new Button(sldXoff+width/2+slider_width+60, slider_height/2*(1+3)-12, 16, 16, " ", "user friction", 3);
  buttons[7] = new Button(sldXoff+width/2+slider_width+60, slider_height/2*(1+1)-12, 16, 16, " ", "FFB monitor", 3);

  //keys
  keys[0] = "r";
  keys[1] = "c";
  keys[2] = "z";
  keys[3] = "s";
  keys[4] = "p";
  keys[5] = "u";
  keys[6] = "v";
  keys[7] = "d";
  keys[8] = "b";
  keys[9] = "+";
  keys[10] = "-";
  keys[11] = "i";

  description[0] = "read wheel buffer";
  description[1] = "re-center wheel";
  description[2] = "reset encoder Z-index";
  description[3] = "read encoder Z-state";
  description[4] = "reset pedal calibration";
  description[5] = "read wheel parameters";
  description[6] = "read wheel version";
  description[7] = "load FFB defaults";
  description[8] = "calibrate wheel (endstops)";
  description[9] = "change rotation by +1deg";
  description[10] = "change rotation by -1deg";
  description[11] = "show/hide information";

  for (int n = 0; n < infos.length; n++) {
    infos[n] = new Info(0.05*width, height-posY*1.85+4*28+2*n*font_size, font_size, description[n], keys[n]);
  }

  for (int k = 0; k < hatsw.length; k++) {
    hatsw[k] = new HatSW(0.05*width + 9*28 + 7, height-posY*1.85+1*28 + 10, 14, 48);
  }
  /*for (int i = 0; i < graphs.length; i++) {
   graphs[i] = new Graph(width/2, height/2, axisScale*2, 3);
   }*/
  xAxis_log_max = 1;
  for (int i = 0; i<=Nbits-1; i++) {
    xAxis_log_max = xAxis_log_max*2;
  }

  sliderlabel[0] = "Rotation [deg]";
  sliderlabel[1] = "General gain [%]";
  sliderlabel[2] = "Damper gain [%]";
  sliderlabel[3] = "Friction gain [%]";
  sliderlabel[4] = "Constant gain [%]";
  sliderlabel[5] = "Periodic gain [%]";
  sliderlabel[6] = "Spring gain [%]";
  sliderlabel[7] = "Inertia gain [%]";
  sliderlabel[8] = "Centering gain [%]";
  sliderlabel[9] = "Stop gain [%]";
  sliderlabel[10] = "Min torque PWM [%]";
  sliderlabel[11] = "Max brake pressure";

  for (int j = 0; j < sdr.length; j++) {
    sdr[j] = new GCustomSlider(this, width/2+sldXoff, slider_height/2*j-4, slider_width, slider_height, "red_yellow18px");
    // Some of the following statements are not actually
    // required because they are setting the default values only 
    sdr[j].setLocalColorScheme(2); 
    sdr[j].setOpaque(false); 
    sdr[j].setNbrTicks(10); 
    sdr[j].setShowLimits(false); 
    sdr[j].setShowValue(false); 
    sdr[j].setShowTicks(true); 
    sdr[j].setStickToTicks(false); 
    sdr[j].setEasing(1.0); 
    sdr[j].setRotation(0.0, GControlMode.CENTER);
  }

  // default FFB parameters
  defParmFFB[0] = 1080.0;
  defParmFFB[1] = 1.0;
  defParmFFB[2] = 0.5;
  defParmFFB[3] = 0.5;
  defParmFFB[4] = 1.0;
  defParmFFB[5] = 1.0;
  defParmFFB[6] = 1.0;
  defParmFFB[7] = 0.5;
  defParmFFB[8] = 0.7;
  defParmFFB[9] = 1.0;
  defParmFFB[10] = 0.0;
  defParmFFB[11] = 45.0;
  effstatedef = 1; // only autocentering spring is enabled by default
  maxTorquedef = 500;
  CPRdef = 2400;
  pwmstatedef = 9;
  xysParmDef[0] = 255;
  xysParmDef[1] = 511;
  xysParmDef[2] = 767;
  xysParmDef[3] = 255;
  xysParmDef[4] = 511;
  xysParmDef[5] = 2; // reverse in 6th gear

  // commands for adjusting FFB parameters
  command[0] = "G ";
  command[1] = "FG ";
  command[2] = "FD ";
  command[3] = "FF ";
  command[4] = "FC ";
  command[5] = "FS ";
  command[6] = "FM ";
  command[7] = "FI ";
  command[8] = "FA ";
  command[9] = "FB ";
  command[10] = "FJ ";
  command[11] = "B ";
  // XY shifter related commands
  shCommand[0] = "HA ";
  shCommand[1] = "HB ";
  shCommand[2] = "HC ";
  shCommand[3] = "HD ";
  shCommand[4] = "HE ";
  shCommand[5] = "HF ";
  shCommand[6] = "HG";
  shCommand[7] = "HR";
  // pedal manual calibration related commands
  pdlCommand[0] = "YA ";
  pdlCommand[1] = "YB ";
  pdlCommand[2] = "YC ";
  pdlCommand[3] = "YD ";
  pdlCommand[4] = "YE ";
  pdlCommand[5] = "YF ";
  pdlCommand[6] = "YG ";
  pdlCommand[7] = "YH ";
  pdlCommand[8] = "YR";

  //btnToggle[0] = new GImageToggleButton(this, 10+1*(slider_width+20), slider_height/2+20);
  //btnToggle[1] = new GImageToggleButton(this, 10+3*(slider_width+20), slider_height/2+20);

  refreshWheelParm(); // update all wheel FFB parms
  for (int i=0; i < wParmFFB.length; i++) {
    setSliderToParm(i); // update sliders with new wheel FFB parms
  }

  readFwVersion(); // read Arduino FFB Wheel firmware version
  // advanced debuging of firmware options
  if (bitRead(fwOpt, 1) == 1) { // if bit1=1 - encoder with Z-index channel suported by firmware (option "z")
    showSetupText("Encoder with a Z-index detected");
    println("Encoder Z-index detected");
  }
  if (bitRead(fwOpt, 2) == 1) { // if bit2=1 - hat Switch suported by firmware (option "h")
    hatsw[0].enabled = true;
    for (int i=0; i<4; i++) { // 2nd 4 buttons are unavailable if we are not using button matrix or button box
      if (!BBenabled && !BMenabled) {
        dugmici[i].enabled = true;
      }
    }
    showSetupText("Hat switch (D-pad) enabled");
    println("Hat switch enabled");
  } else { 
    for (int i=0; i<8; i++) {
      dugmici[i].enabled = true; // by default we have 8 direct pins for buttons available
    }
  }
  if (bitRead(fwOpt, 3) == 1) { // of bit3=1 - averaging of analog inputs is supported by firmware (option "i")
    showSetupText("Averaging of analog inputs for pedals enabled");
    println("Analog input averaging enabled");
    slajderi[1].am = 4095;
    slajderi[2].am = 4095;
    slajderi[3].am = 4095;
    slajderi[4].am = 4095;
  } else if (bitRead(fwOpt, 4) == 1) { // if bit4=1 - external 12bit ADC ads1105 is supported by firmware (option "s")
    showSetupText("External 12bit ADC ads1105 for pedals detected");
    println("ADS1105 detected");
    slajderi[1].am = 2047; // brake Y-axis 
    slajderi[2].am = 2047; // accelerator Z-axis 
    slajderi[3].am = 2047; // clutch RX-axis 
    slajderi[4].am = 2047; // handbrake RY-axis
  }

  if (bitRead(fwOpt, 6) == 1) { // if bit6=1 - 4x4 button matrix suported by firmware (option "t")
    for (int i=0; i<16; i++) {
      if (bitRead(fwOpt, 2) == 1 && i > 11) {  // enable first 16 buttons, except for last 4 if we have hat switch
        dugmici[i].enabled = false;
      } else {
        dugmici[i].enabled = true;
      }
    }
    showSetupText("4x4 button matrix detected");
    println("Button matrix detected");
  }
  if (BBenabled) { // if button box is supported by firmware, enable first 16 buttons
    for (int i=0; i<16; i++) {
      if (bitRead(fwOpt, 2) == 1 && i > 11) {  // enable first 16 buttons, except for last 4 if we have hat switch
        dugmici[i].enabled = false;
      } else {
        dugmici[i].enabled = true;
      }
    }
    if (bitRead(fwOpt2, 4) == 1) { // if bit4=1, we have firmware with 24 buttons supported (option "r")
      for (int i=0; i<8; i++) {
        dugmici[16+i].enabled = true; // enable last 8 buttons
      }
      showSetupText("24 buttons via shift register detected");
      println("24 buttons detected");
    } else { // otherwise is 16 buttons
      showSetupText("16 buttons via Arduino Nano detected");
      println("16 buttons detected");
    }
  }
  if (bitRead(fwOpt, 5) == 1) { // if bit5=1 - Arduino ProMicro pinouts suported by firmware (option "m")
    if (bitRead(fwOpt, 1) == 1 || bitRead(fwOpt, 4) == 1) {
      dugmici[3].enabled = false; // button3 is unavailable on proMicro if we use zindex, or any i2C device
    }
    showSetupText("Arduino ProMicro replacement pinouts detected");
    println("ProMicro pinouts detected");
  }
  if (!LCenabled) { // max brake slider becomes FFB balance if no load cell
    sliderlabel[11] = "FFB balance L/R";
    defParmFFB[11] = 128.0;
  } else {
    slajderi[1].am = 65535; // update bar graph max value for brake axis 
    showSetupText("Load Cell brake with HX711 detected");
    println("HX711 detected");
  }
  if (DACenabled) {
    showSetupText("Analog FFB output via DAC detected");
    println("DAC detected");
    sliderlabel[10] = "Min torque DAC [%]";
  }
  shifters[0] = new XYshifter(width/3.65-16, height-posY-500, 0.25);
  if (XYshifterEnabled) {
    //if (!LCenabled) dugmici[3].enabled = false;
    if (bitRead(fwOpt, 5) == 1) { // for option "m" in proMicro we have replacement pins for these buttons
      dugmici[1].enabled = true;
      dugmici[2].enabled = true;
    } else { // for leonardo or micro, these buttons are unavailable when XY shifter is used
      if (bitRead(fwOpt, 2) == 0) { // if no hat switch on leonardo or micro, we don't have these 4 buttons
        for (int i=0; i<4; i++) {
          dugmici[4+i].enabled = false;
        }
      }
    }
    for (int i=0; i<8; i++) {
      dugmici[16+i].enabled = true; // enable last 8 buttons for XY shifter gears
    }
    showSetupText("Analog XY H-shifter detected");
    println("H-shifter detected");
    buttons[11].active = true;
    buttons[12].active = true;
    if (fwVerNum >= 230) { // if fw-v230 - h-shifter advanced configuration
      buttons[15].active = true;
      buttons[16].active = true;
      buttons[17].active = true;
    } else {
      buttons[15].active = false;
      buttons[16].active = false;
      buttons[17].active = false;
    }
    refreshXYshifterCal(); // get shifter calibration config from arduino
    shifters[0].updateCal(rb); // decode and update shifter cal and config byte values
    showSetupText(rb);
    if (bitRead(shifters[0].sConfig, 0) == 1) { // if reverse gear button is inverted
      buttonpressed[17] = true;
    } else {
      buttonpressed[17] = false;
    }
    if (bitRead(shifters[0].sConfig, 1) == 1) { // if reverse gear in 8th
      buttonpressed[12] = true;
    } else {
      buttonpressed[12] = false;
    }
    if (bitRead(shifters[0].sConfig, 2) == 1) { // if shifter X-axis is inverted
      buttonpressed[15] = true;
    } else {
      buttonpressed[15] = false;
    }
    if (bitRead(shifters[0].sConfig, 3) == 1) { // if shifter Y-axis is inverted
      buttonpressed[16] = true;
    } else {
      buttonpressed[16] = false;
    }
  } else {
    buttons[11].active = false;
    buttons[12].active = false;
    buttons[15].active = false;
    buttons[16].active = false;
    buttons[17].active = false;
  }
  if (bitRead(fwOpt2, 0) == 1) { // if bit0=1 - extra buttons suported by firmware (option "e")
    // we have 2 extra buttons instead of clutch and handbrake
    if (bitRead(fwOpt, 2) == 1) { // if option "h" then buttons 4,5 are available
      dugmici[4].enabled = true;
      dugmici[5].enabled = true;
    } else {
      dugmici[8].enabled = true; // else remaped to buttons 8,9
      dugmici[9].enabled = true;
    }
    showSetupText("Two extra buttons detected");
    println("Extra buttons detected");
  }
  if (bitRead(fwOpt2, 1) == 1) { // if bit1=1 - analog axis for FFB suported by firmware (option "x")
    showSetupText("Analog axis for FFB enabled");
    println("Analog axis for FFB enabled");
  }
  if (bitRead(fwOpt2, 2) == 1) { // if bit2=1 - magnetic angle sensor AS5600 suported by firmware (option "w")
    if (bitRead(fwOpt, 5) == 1) { // if ProMicro
      if (bitRead(fwOpt, 2) == 1) { // if hat switch
        dugmici[3].enabled = false;
      }
    }
    infobuttons[0].as = 1; // set magnetic encoder in info button
    showSetupText("AS5600 magnetic encoder detected");
    println("AS5600 detected");
  } else {
    infobuttons[0].as = 0; // set optical quadrature encoder in info button
  }
  if (bitRead(fwOpt2, 3) == 1) { // if bit3=1 - hardware re-center is suported by firmware (option "c")
    showSetupText("Hardware re-center button enabled");
    println("Re-center button enabled");
  }
  if (fwVerNum >= 200) { // if =>fw-v200 - we have additional firmware options
    if (LCenabled) {
      slajderi[1].yLimits[0].active = false; // if load cell, inactivate manual cal for brake axis
      slajderi[1].yLimits[1].active = false;
    }
    if (bitRead(fwOpt2, 0) == 1) { // if bit0 of firmware options byte2 is HIGH, we have extra buttons and no clutch and handbrake
      if (!LCenabled) {  
        slajderi[3].yLimits[0].active = false; // only if no load cell, inactivate manual cal for clutch axis
        slajderi[3].yLimits[1].active = false;
      }
      slajderi[4].yLimits[0].active = false; // if extra buttons, inactivate manual cal for handbrake axis
      slajderi[4].yLimits[1].active = false;
    }
    if (bitRead(fwOpt, 7) == 1 && bitRead(fwOpt, 5) == 1) { // if options "f" and "m" clutch and hbrake axis are unavailable
      slajderi[3].yLimits[0].active = false;
      slajderi[3].yLimits[1].active = false;
      slajderi[4].yLimits[0].active = false;
      slajderi[4].yLimits[1].active = false;
    }
    if (bitRead(fwOpt2, 1) == 1) { // if bit1 of firmware options byte2 is HIGH, we have available FFB axis selector
      AFFBenabled = true;
    }
    if (bitRead(fwOpt, 0) == 0) {  // if bit0=0 - pedal autocalibration is disabled, then we have manual pedal calibration
      println("Manual pcal enabled");
      refreshPedalCalibration();
      updateLastPedalCalibration(rb);
      showSetupText("Manual calibration for pedals enabled");
      showSetupText(rb);
    } else {
      showSetupText("Automatic calibration for pedals enabled");
      println("Automatic pcal detected");
      buttons[13].active = false; // disable manual cal button if pedal auto calib firmware
    }
    if (bitRead(fwOpt, 1) == 1) { // if bit1=1, encoder z-index is supported by firmware
      buttons[14].active = true; // activate z-reset button
    } else {
      buttons[14].active = false; // inactivate z-reset button
    }
  }
  if (fwVerNum >= 240) { // in firmware v240 we are in-activating unavailable buttons, some buttons are re-mapped (just visual fix)
    dActByp = false; // do not bypass button in-activation
    infobuttons[0].hiden = false; // un-hide the encoder type info button
  }
  wb = "V";
  executeWR();

  //FFB graph
  ffbgraphs[0] = new FFBgraph(width, height-gbuffer/gskip, width, 1);

  // create number box object
  cp5 = new ControlP5(this);
  num1 = cp5.addNumberbox("CPR")
    .setSize(45, 18)
    .setPosition(int(width/3.65) - 15 +  0.0*60, height-posY+30)
    .setValue(lastCPR)
    .setRange(0, maxCPR)
    ;               
  makeEditable(num1);

  cp5 = new ControlP5(this);
  List b = Arrays.asList("fast top", "phase corr");
  List c = Arrays.asList("pwm +-", "pwm+dir");
  List c1 = Arrays.asList("pwm +-", "pwm+dir", "pwm0-50-100");
  List c2_rcm = Arrays.asList("pwm +-", "pwm+dir", "pwm0-50-100", "rcm");
  List d = Arrays.asList("dac +-", "dac+dir");
  List e = Arrays.asList("default");
  /* add a ScrollableList, by default it behaves like a DropdownList */
  cp5.addScrollableList("profile")
    .setPosition(Xoffset+int(width/3.5) - 15 + 14*60, height-posY+30+108)
    .setSize(66, 100)
    .setBarHeight(20)
    .setItemHeight(20)
    .addItems(e)
    ;
  cp5.get(ScrollableList.class, "profile").close();
  float[] def = new float[num_prfset];
  for (int i =0; i<num_sldr; i++) {
    def[i] = defParmFFB[i];
  }
  def[num_sldr] = int(effstatedef);
  def[num_sldr+1] = maxTorquedef;
  def[num_sldr+2] = CPRdef;
  def[num_sldr+3] = int(pwmstatedef);
  float[] empty = new float[num_prfset];
  for (int i =0; i<num_prfset; i++) {
    empty[i] = 0.0;
  }
  profiles[0] = new Profile("default", def); //create default profile
  for (int i=1; i<num_profiles; i++) {
    profiles[i] = new Profile("slot"+str(i), empty); //create remaining profiles
    cp5.get(ScrollableList.class, "profile").addItem(profiles[i].name, empty);
  }
  if (!enabledac) {
    /* add a ScrollableList, by default it behaves like a DropdownList */
    cp5.addScrollableList("frequency")
      .setPosition(Xoffset+int(width/3.5) - 15 + 564, height-posY+30+108)
      .setSize(56, 100)
      .setBarHeight(20)
      .setItemHeight(20)
      .addItems(a)
      //.setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST
      ;
    if (RCMenabled) { // fw-v210 has bigger pwm frequency selection
      cp5.get(ScrollableList.class, "frequency").removeItems(a);
      cp5.get(ScrollableList.class, "frequency").addItems(a1);
    }
    cp5.addScrollableList("pwmtype")
      .setPosition(Xoffset+int(width/3.5) - 15 + 402, height-posY+30+108)
      .setSize(66, 100)
      .setBarHeight(20)
      .setItemHeight(20)
      .addItems(b)
      //.setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST
      ;
    cp5.addScrollableList("pwmmode")
      .setPosition(Xoffset+int(width/3.5) - 15 + 479, height-posY+30+108)
      .setSize(74, 100)
      .setBarHeight(20)
      .setItemHeight(20)
      .addItems(c)
      //.setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST
      ;
    if (pwm0_50_100enabled) { // fw-v200 has pwm0.50.100 mode added
      cp5.get(ScrollableList.class, "pwmmode").removeItems(c);
      cp5.get(ScrollableList.class, "pwmmode").addItems(c1);
    } else if (RCMenabled) { // fw-v210 has RCM mode added
      cp5.get(ScrollableList.class, "pwmmode").removeItems(c);
      cp5.get(ScrollableList.class, "pwmmode").addItems(c2_rcm);
    }
    //println(pwm0_50_100enabled+" "+RCMenabled);
    cp5.get(ScrollableList.class, "frequency").close();
    cp5.get(ScrollableList.class, "pwmtype").close();
    cp5.get(ScrollableList.class, "pwmmode").close();
    // update lists to these value
    cp5.get(ScrollableList.class, "frequency").setValue(freqpwm);
    cp5.get(ScrollableList.class, "pwmtype").setValue(int(typepwm));
    cp5.get(ScrollableList.class, "pwmmode").setValue(int(modepwm));
  } else {
    cp5.addScrollableList("dacmode")
      .setPosition(Xoffset+int(width/3.5) - 15 + 9.4*60, height-posY+30+108)
      .setSize(60, 100)
      .setBarHeight(20)
      .setItemHeight(20)
      .addItems(d)
      //.setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST
      ;
    buttons[9].t =  " dac";
    cp5.get(ScrollableList.class, "dacmode").close();
    cp5.get(ScrollableList.class, "dacmode").setValue(int(modedac));
  }
  if (AFFBenabled) { // if firmware supports analog FFB axis
    List fb = Arrays.asList("x-enc", "y-brk", "z-acc", "rx-clt", "ry-hbr");
    if (bitRead(fwOpt, 5) == 1 && bitRead(fwOpt, 7) == 1) fb = Arrays.asList("x-enc", "y-brk", "z-acc"); // if "f" and "m" options, we don't have clutch and hbrake axis available
    cp5.addScrollableList("FFBaxis")
      .setPosition(Xoffset+int(width/3.5) - 15 - 0.6*60, height-posY+5)
      .setSize(50, 100)
      .setBarHeight(20)
      .setItemHeight(20)
      .addItems(fb)
      //.setType(ScrollableList.DROPDOWN) // currently supported DROPDOWN and LIST
      ;
    cp5.get(ScrollableList.class, "FFBaxis").close();
    cp5.get(ScrollableList.class, "FFBaxis").setValue(int(FFBAxisIndex));
  }
  loadProfiles(); // check if exists and load profiles from txt
  showSetupText("Configuration done");
  setupTextTimer = 0;
}

void draw() {
  background(51);
  drawGUI();
}

void drawGUI() {
  draw_labels();
  /*for (int j = 0; j < btnToggle.length; j++) {
   handleToggleButtonEvents(btnToggle[j], j);
   }*/
  for (int i = 0; i < slajderi.length; i++) {
    slajderi[i].update(i);
    slajderi[i].show();
  }
  for (int j = 0; j < dugmici.length; j++) {
    dugmici[j].update();
    buttonValue = Button[j];
    dugmici[j].show(j);
  }
  for (int k = 0; k < hatsw.length; k++) {
    hatsw[k].update();
    hatsw[k].show();
    hatsw[k].showArrow();
  }
  // my simple animated wheel gfx
  wheels[0].update(slajderi[FFBAxisIndex].axisVal*wParmFFB[0]/2); // update the angle in units of degrees
  wheels[0].showDeg(); // show the angle in units of degrees in a nice number format
  //wheels[0].show();

  // animated wheel from png sprite
  if (!buttonpressed[7]) {
    S4P.updateSprites(1);
    sprite[0].setRot(slajderi[FFBAxisIndex].axisVal*wParmFFB[0]/2/180*PI); // set the angle of the sprite in units of radians
    S4P.drawSprites();
  }

  //wheels[1].update();
  //axisValue = correct_axis(Axis[0]);
  //wheels[1].show();
  /*for (int i = 0; i < graphs.length; i++) {
   graphs[i].update();
   //graphs[i].show();
   }*/
  for (int j = 0; j < infobuttons.length; j++) {
    infobuttons[j].update();
    infobuttons[j].show();
  }
  for (int k = 0; k < buttons.length; k++) {
    buttons[k].update(k);
    buttons[k].show();
  }
  for (int l = 0; l < infos.length; l++) {
    infos[l].show(enableinfo);
  }
  for (int m = 0; m < ffbgraphs.length; m++) {
    if (buttonpressed[7]) {
      for (int i=0; i<ceil(gbuffer / frameRate); i++) {
        String temprb = readString();
        if (temprb != "empty") {
          ffbgraphs[m].update(temprb);
        }
      }
      ffbgraphs[m].show();
    } else {
      if (fbmnstp) { // read remaining serial read buffer content
        String temprb = "";
        for (int i=0; i<gskip+1; i++) {
          String tempString = readString();
          if (tempString != "empty") {
            temprb = rb;
            ffbgraphs[m].update(temprb);
          }
        }
        ffbgraphs[m].show();
        rb = temprb; // restore read buffer
        fbmnstp = false;
      }
    }
  }
  if (buttonpressed[7]) {
    dialogs[0].update("WB: "+ wb + ", RB: " + fbmnstring + "; " + str(rbt_ms) + "ms");
  } else {
    dialogs[0].update("WB: "+ wb + ", RB: " + rb + "; " + str(rbt_ms) + "ms");
  }
  dialogs[0].show();
  text(round(frameRate)+" fps", font_size/3, font_size);
  if (CPRlimit) {
    num1.setValue(maxAllowedCPR(wParmFFBprev[0]));
    CPRlimit = false;
  }
  if (!buttonpressed[7]) { // only available if ffb monitor is not enabled
    if (XYshifterEnabled) buttons[11].active = true; // re-enable only if firmware supports it
    if (XYshifterEnabled) buttons[12].active = true; 
    if (buttonpressed[11]) { // if we pressed shifter button
      refreshXYshifterPos(); // get new shifter XY position from arduino
      shifters[0].updatePos(); // update new shifter XY position
      shifters[0].setCal(); // actuate cal sliders and update limits
      shifters[0].show(); // display shifter - cal sliders, limits and xy shifter position
      buttons[7].active = false; // disable ffb monitor while we configure XY shifter
    } else {
      buttons[7].active = true; // re-enable ffb monitor if we are not configuring XY shifter
    }
  } else {
    buttons[11].active = false; // disable XY shifter button while we are running ffb monitor
    //buttons[12].active = false; // disable shifter r button while we are running ffb monitor
  }
  if (FFBAxisIndex != 0) { // if X-axis is not tied to FFB axis
    buttons[0].active = false; // disable center button
    buttons[14].active = false; // disable z button
  } else {
    buttons[0].active = true; // re-enable center button
    if (bitRead(fwOpt, 1) == 1) buttons[14].active = true; // re-enable z button if supported by firmware
  }
  draw_setupText();
  setupTextTimer = (frameCount / round(frameRate))*1000; // update timer for showing setup text
}

float correct_axis (float input) { // range of input is -1 to 1

  //coef1 = lfs_wheelTurn/lfs_car_wheelTurn;
  //coef2 = 0.0;
  //coef3 = lfs_compensation*1-coef1;

  float temp1, temp2;
  //float temp3, temp4, temp5;
  temp1 = input*coef1+input*input*coef2+input*input*input*coef3; // cubic function
  //temp2 = input*coef1; // linear function
  //temp3 = temp2 - temp1; // difference from linear function
  //temp4 = temp2 + temp3; // mirrored cubic function
  constrain(temp1, -1, 1);

  if (lfs_compensation == 0.0) { // if not compensation
    temp2 = input*lfs_car_wheelTurn/2;
  } else { // if compensation >=0.01
    if (lfs_wheelTurn >= lfs_car_wheelTurn) {
      temp2 = input*real_wheelTurn/2;
    } else { // is less
      temp2 = temp1*lfs_car_wheelTurn/2;
    }
  }
  if (temp2 >= lfs_car_wheelTurn/2) { // limit the range of output to car's wheel range
    temp2 = lfs_car_wheelTurn/2;
  } 
  if (temp2 <= -lfs_car_wheelTurn/2) {
    temp2 = -lfs_car_wheelTurn/2;
  }
  return temp2;
}

void draw_labels() {
  String labelStr;
  fill(255);
  for (int j = 0; j < sdr.length; j++) { // FFB slider values
    labelStr = str(slider_value[j]);
    if (j == 0 || j == 11) { // only for rotation and brake pressure
      labelStr=labelStr.substring(0, labelStr.length()-2); // do not show decimal places
      if (!LCenabled && j == 11) labelStr = str(slider_value[j]-128).substring(0, (str(slider_value[j]-128)).length()-2); // shift the value such that center iz at zero
    } else if (j == 10) { // only for min PWM
      if (slider_value[j] < 10.0 ) {
        labelStr=labelStr.substring(0, 3);
      } else {
        labelStr=labelStr.substring(0, 4);
      }
    } else {
      labelStr = str(ceil(slider_value[j]*100)); // fix, show 100% instead of 1.0%
      /*if (slider_value[j]*100 >= 100 ) {
       labelStr=labelStr.substring(0, 3);
       } else {
       if (labelStr.length() >= 4 ) {
       labelStr=labelStr.substring(0, 4);
       }
       }*/
    }
    //textMode(TOP);
    text(sliderlabel[j], sldXoff+width/2-slider_width/3, slider_height/2*(1+j)); // slider label
    text(labelStr, sldXoff+width/2+slider_width+20, slider_height/2*(1+j)); // slider value
  }
  if (AFFBenabled) text("FFB-axis", Xoffset+int(width/3.5) - 14 - 0.6*60, height-posY+2); // FFB axis selector label
  //text("Couple with pysical wheel turn", 70+1*(slider_width+20), slider_height/2+50);
  //text("Decouple coefs", 70+3*(slider_width+20), slider_height/2+50);
  pushMatrix();
  translate(width/3.5, height-159);
  text("Arduino FFB Wheel, HEX " + FullfwVerStr.substring(3, FullfwVerStr.length()), 0, 0);
  text("Control Panel " + cpVer, 0, 20);
  text("Miloš Ranković 2018-2024 ©", 0, 40);
  text("ranenbg@gmail.com, paypal@ranenbg.com", 0, 60);
  popMatrix();
}

// Event handler for image toggle buttons
void handleToggleButtonEvents(GImageToggleButton button, int btnID) { 
  //println(button + "   State: " + button.getState());
  /*if (btnID == 0) {
   if (button.getState() == 1) { // button on coupled
   real_wheelTurn = 80+int(sdr[1].getValueF()*1000.0);
   sdr[0].setValue(sdr[1].getValueF());
   } else { // button off decaupled - default
   real_wheelTurn = 80+int(sdr[0].getValueF()*1000.0);
   }
   }
   if (btnID == 1) { // button on - decouple
   if (button.getState() == 1) {
   coef1 = sdr[4].getValueF();
   coef2 = sdr[5].getValueF();
   coef3 = sdr[6].getValueF();
   } else { // button off - default
   coef3 = sdr[3].getValueF();
   lfs_compensation = coef3;
   coef2 = 0;
   coef1 = 1.0-coef3;
   sdr[4].setValue(coef1);
   sdr[5].setValue(coef2);
   sdr[6].setValue(coef3);
   }
   }*/
}

void writeString(String input) {
  myPort.write(input+char(13)); // add CR - carage return as output line terminator
}

String readString() {
  if (myPort.available() > 0) { // if serial port data is available
    rb = myPort.readStringUntil(char(10));  // read till terminator char - LF (line feed) and store it in rb
    if (rb != null) { // if there is something in rb
      rb = rb.substring(0, (rb.indexOf(char(13)))); // remove last 2 chars - Arduino sends both CR+LF, char(13)+char(10)
    } else {
      rb = "empty";
    }
  } else {
    rb = "empty";
  }
  return rb;
}

/*void serialEvent(Serial myPort) {
 String temp;
 try {
 temp = myPort.readStringUntil(char(10));  // read till terminator char - LF (line feed) and store it in rb
 if (temp != null) { // if there is something in rb
 temp = temp.substring(0, (rb.indexOf(char(13)))); // remove last 2 chars - Arduino sends both CR+LF, char(13)+char(10)
 }
 rb = temp;
 println("Serial event: " + temp);
 }
 catch(RuntimeException e) {
 e.printStackTrace();
 }
 }*/

void executeWR() {
  rbt_ms = 0;
  writeString(wb);
  //delay(21); // no longer needed since improved read functions
  // serial read period I've set in arduino is every 10ms
  for (int i = 0; i <=9999; i++) { // but just in case (calibration), we give arduino more time up to 10s   
    if (readString() == "empty") {
      rbt_ms++;
      delay(1);
    } else {
      break;
    }
  }
  fbmnstring = rb;
  println("WB:"+ wb + ", RB:" + rb + "; " + str(rbt_ms) + "ms");
}

void refreshWheelParm() {
  myPort.clear();
  writeString("U");
  if (UpdateWparms(readParmUntillEmpty())) {
    showSetupText("Firmware: OK, reading config");
    showSetupText(rb);
    println("Arduino FFB Wheel detected");
  } else {
    showSetupText("Firmware: ERROR");
    println("Incompatible firmware detected");
  }
  if (bitRead(effstate, 4) == 1) { // if FFB mon is running
    showSetupText("De-activating FFB monitor");
    println("De-activating FFB monitor");
    effstate = bitWrite(effstate, 4, false); // turn it OFF
    sendEffstate(); // send command to Arduino
    readParmUntillEmpty(); // read remaining FFB mon data
  }
  for (int i=0; i < wParmFFB.length; i++) {
    wParmFFBprev[i] = wParmFFB[i];
    print(wParmFFB[i]);
    print(" ");
  }
  readEffstate();
  readPWMstate();
  print(int(effstate));
  //print(" ");
  //print("read: " + int(FFBAxisIndex));
  print(" ");
  print(maxTorque);
  print(" ");
  print(lastCPR);
  print(" ");
  print(int(pwmstate));
  println("; " + str(rbt_ms) + "ms");
  /*print(typepwm);
   print(" ");
   print(modepwm);
   print(" ");
   println(freqpwm);*/
  //println(enabledac, modedac);
}


boolean UpdateWparms(String input) { // decode wheel parameters into FFB, CPR and PWM settings and returns false if format is incorrect
  boolean correct;
  float[] temp = float(split(input, ' '));
  if (temp.length > 0) {
    correct = true;
  } else {
    correct = false;
  }
  for (int i=0; i < temp.length; i++) {
    if (i == 0) {
      wParmFFB[0] = temp[0];
    } else {
      if (i < temp.length-4) { // for all but last 4 values
        if (i != 10 && i != 11) { //all except for min torque and brake pressure
          wParmFFB[i] = temp[i] / 100.0;
        } else {
          wParmFFB[i] = temp[i];
        }
      } else if (i == temp.length-4) { // this value is effstate in binary form
        effstate = byte(temp[i]);
      } else if (i == temp.length-3) { // this value is max torque or PWM resolution per channel
        maxTorque = int(temp[i]);
      } else if (i == temp.length-2) { // this value is encoder CPR
        lastCPR = int(temp[i]);
      } else if (i == temp.length-1) { // last value is pwmstate in binary form
        pwmstate = byte(temp[i]);
      }
    }
  }
  wParmFFB[10] = wParmFFB[10] / float(maxTorque) * 100.0; // recalculate to percentage min pwm value
  return correct;
}

String readParmUntillEmpty() { // reads serial buffer untill empty and returns a string longer than 5 chars (non-FFB monitor data)
  String buffer = "";
  String temp = "";
  rbt_ms = 0;
  for (int i=0; i<999; i++) {
    temp = readString();
    if (temp != "empty") {
      if (temp.length() > 6) { // 5 digits + sign
        buffer = temp;
        break;
      }
    } else {
      rbt_ms++;
      delay(1);
    }
  }
  return buffer;
}

void readFwVersion() { // reads firmware version from String, checks and updates all firmware options
  myPort.clear();
  println("Reading firmware version");
  wb = "V";
  executeWR();
  FullfwVerStr = rb;
  fwVerStr = rb.substring(4); // first 4 chars are allways "fw-v", followed by 3 numbers
  String fwTemp = fwVerStr;
  String fwOpts = "0";
  if (fwTemp.length() > 3) { // if there are any firmware options present
    fwVerStr = fwTemp.substring(0, 3); // remove everything after numbers
    fwOpts = fwTemp.substring(3, fwTemp.length());  // remove only numbers
  }
  fwVerNum = parseInt(fwVerStr);
  fwOpt = decodeFwOpts(fwOpts); // decode fw options into 1st byte
  fwOpt2 = decodeFwOpts2(fwOpts); // decode fw options into 2nd byte
  String fwVerNumStr = str(fwVerNum);
  int len = fwVerNumStr.length();
  if (fwVerNumStr.charAt(len-1) == '1') { // if last number is 1
    BBenabled = true;
  }
  if (fwVerNumStr.charAt(len-1) == '0' || fwVerNumStr.charAt(len-1) == '1') { // if last number is 0 or 1
    LCenabled = false; // we don't have load cell or dac
    DACenabled = false;
  }
  if (fwVerNumStr.charAt(len-1) == '2') { // if last number is 2
    BBenabled = true; // we have button box
    LCenabled = true; // we have load cell
  }
  if (fwVerNumStr.charAt(len-1) == '3') { // if last number is 3
    LCenabled = true; // we have load cell and dac
    DACenabled = true;
  }
  if (bitRead(fwOpt, 7) == 1) { // if bit7 is HIGH (xy shifter bit)
    XYshifterEnabled = true;
  }
  if (bitRead(fwOpt, 0) == 0) buttons[2].active = false; // if bit0 is LOW (no pedal autocalibration available)
  if (fwVerNum >= 200 && fwVerNum < 210) pwm0_50_100enabled = true;
  if (fwVerNum >= 210) RCMenabled = true;
  if (bitRead(fwOpt2, 0) == 1) { // if bit0 is HIGH (clutch and handbrake are unavailable)
    clutchenabled = false;
    hbrakeenabled = false;
  }
  if (bitRead(fwOpt, 6) == 1) { // if bit6=1 of fw opt 1st byte
    BMenabled = true; // we have button matrix available
  }
}
// decode 1st byte of firmware options
byte decodeFwOpts (String fopt) {
  byte temp = 0;
  if (fopt != "0") { // if firmware has any options
    for (int j=0; j<fopt.length(); j++) {
      if (fopt.charAt(j) == 'a') temp = bitWrite(temp, 0, true); // b0=1, pedal autocalibration enabled
      if (fopt.charAt(j) == 'z') temp = bitWrite(temp, 1, true); // b1=1, encoder z-index enabled
      if (fopt.charAt(j) == 'h') temp = bitWrite(temp, 2, true); // b2=1, hat switch enabled
      if (fopt.charAt(j) == 'i') temp = bitWrite(temp, 3, true); // b3=1, pedal averaging enabled
      if (fopt.charAt(j) == 's') temp = bitWrite(temp, 4, true); // b4=1, external ADC enabled
      if (fopt.charAt(j) == 'm') temp = bitWrite(temp, 5, true); // b5=1, proMicro replacement pinouts
      if (fopt.charAt(j) == 't') temp = bitWrite(temp, 6, true); // b6=1, 4x4 button matrix enabled
      if (fopt.charAt(j) == 'f') temp = bitWrite(temp, 7, true); // b7=1, XY analog shifter enabled
    }
  }
  //println("fw opt1: 0x" + hex(temp));
  return temp;
}
// decode 2nd byte of firmware options
byte decodeFwOpts2 (String fopt) {
  byte temp = 0;
  if (fopt != "0") { // has firmware any options
    for (int j=0; j<fopt.length(); j++) {
      if (fopt.charAt(j) == 'e') temp = bitWrite(temp, 0, true); // b0=1, extra buttons enabled
      if (fopt.charAt(j) == 'x') temp = bitWrite(temp, 1, true); // b1=1, analog FFB axis enabled
      if (fopt.charAt(j) == 'w') temp = bitWrite(temp, 2, true); // b2=1, AS5600 enabled
      if (fopt.charAt(j) == 'c') temp = bitWrite(temp, 3, true); // b3=1, center button enabled
      if (fopt.charAt(j) == 'r') temp = bitWrite(temp, 4, true); // b4=1, 24 buttons (via 3x8bit SR) enabled
    }
  }
  //println("fw opt2: 0x" + hex(temp));
  return temp;
}

void mousePressed() {
  if (mouseButton == LEFT) {
    for (int i=0; i < wParmFFB.length; i++) {
      wParmFFBprev[i] = wParmFFB[i];
    }
  }
}

void mouseReleased() {
  if (controlb[0]) { // if we pressed center button
    if (wheelMoved) { // only re-center if wheel moved from initial center pos
      wb = "C";
      executeWR();
      prevaxis = gpad.getSlider("Xaxis").getValue();
      wheelMoved = false;
    }
  }
  if (controlb[1]) { // if we pressed default button
    setDefaults();
  }
  if (controlb[2]) { // if we pressed center button
    wb = "P";
    executeWR();
  }
  if (controlb[3]) { // if we pressed autocenter spring on/off buton
    ActuateButton(3);
  }
  if (controlb[4]) { // if we pressed damper on/off button
    ActuateButton(4);
  }
  if (controlb[5]) { // if we pressed inertia on/off button
    ActuateButton(5);
  }
  if (controlb[6]) { // if we pressed friction on/off button
    ActuateButton(6);
  }
  if (controlb[7]) { // if we pressed ffb monitor on/off button
    ActuateButton(7);
  }
  if (controlb[8]) { // if we pressed save button
    wb = "A";
    executeWR();
  }
  if (controlb[9]) { // if we pressed pwm button
    if (pwmstate != pwmstateprev) { // send only if a change is made
      sendPWMstate (); // send buttons into effstate
      pwmstateprev = pwmstate;
    }
  }
  if (controlb[10]) { // if we pressed store button
    profiles[cur_profile].upload(); // update last FFB settings to a profile
    profiles[cur_profile].storeToFile("profile"+str(cur_profile));
    cp5.get(ScrollableList.class, "profile").setLabel(profiles[cur_profile].name);
  }
  if (controlb[11]) { // if we pressed shifter button
    ActuateButton(11);
  }
  if (controlb[12]) { // if we pressed shifter config "r" button
    ActuateButton(12);
    if (buttonpressed[12]) { // if pressed
      shifters[0].sConfig = bitWrite(shifters[0].sConfig, 1, true); // set sConfig bit1 HIGH - 8 gear mode
    } else { // if unpressed
      shifters[0].sConfig = bitWrite(shifters[0].sConfig, 1, false); // set sConfig bit1 LOW - 6 gear mode
    }
    wb = shCommand[5] + str(shifters[0].sConfig);
    executeWR();
  }
  if (controlb[15]) { // if we pressed shifter config "x" button
    ActuateButton(15);
    if (buttonpressed[15]) { // if pressed
      shifters[0].sConfig = bitWrite(shifters[0].sConfig, 2, true); // set sConfig bit1 HIGH - X-axis inverted
    } else { // if unpressed
      shifters[0].sConfig = bitWrite(shifters[0].sConfig, 2, false); // set sConfig bit1 LOW - X-axis normal
    }
    wb = shCommand[5] + str(shifters[0].sConfig);
    executeWR();
  }
  if (controlb[16]) { // if we pressed shifter config "y" button
    ActuateButton(16);
    if (buttonpressed[16]) { // if pressed
      shifters[0].sConfig = bitWrite(shifters[0].sConfig, 3, true); // set sConfig bit1 HIGH - Y-axis inverted
    } else { // if unpressed
      shifters[0].sConfig = bitWrite(shifters[0].sConfig, 3, false); // set sConfig bit1 LOW - Y-axis normal
    }
    wb = shCommand[5] + str(shifters[0].sConfig);
    executeWR();
  }
  if (controlb[17]) { // if we pressed shifter config "b" button
    ActuateButton(17);
    if (buttonpressed[17]) { // if pressed
      shifters[0].sConfig = bitWrite(shifters[0].sConfig, 0, true); // set sConfig bit0 HIGH - reverse gear button inverted (for logitech G25/G27/G29/G923 H-shifters)
    } else { // if unpressed
      shifters[0].sConfig = bitWrite(shifters[0].sConfig, 0, false); // set sConfig bit0 LOW - reverse gear button normal
    }
    wb = shCommand[5] + str(shifters[0].sConfig);
    executeWR();
  }
  if (controlb[13]) { // if we pressed manual cal button
    ActuateButton(13);
    if (buttonpressed[13]) {
      for (int i=1; i<=4; i++) slajderi[i].yLimitsVisible = true;
    } else {
      for (int i=1; i<=4; i++) slajderi[i].yLimitsVisible = false;
    }
  }
  if (controlb[14]) { // if we pressed z reset button
    wb = "Z";
    executeWR();
  }
  if (controlb[ctrl_btn+0]) { // if we pressed shifter calibration slider a
    wb = shCommand[0] + str(int(shifters[0].sCal[0]));
    executeWR();
  }
  if (controlb[ctrl_btn+1]) { // if we pressed shifter calibration slider b
    wb = shCommand[1] + str(int(shifters[0].sCal[1]));
    executeWR();
  }
  if (controlb[ctrl_btn+2]) { // if we pressed shifter calibration slider c
    wb = shCommand[2] + str(int(shifters[0].sCal[2]));
    executeWR();
  }
  if (controlb[ctrl_btn+3]) { // if we pressed shifter calibration slider d
    wb = shCommand[3] + str(int(shifters[0].sCal[3]));
    executeWR();
  }
  if (controlb[ctrl_btn+4]) { // if we pressed shifter calibration slider e
    wb = shCommand[4] + str(int(shifters[0].sCal[4]));
    executeWR();
  }
  if (controlb[ctrl_btn+ctrl_sh_btn+0]) { // if we pressed pedal calibration slider a
    wb = pdlCommand[0] + str(int(slajderi[1].pCal[0]));
    executeWR();
  }
  if (controlb[ctrl_btn+ctrl_sh_btn+1]) { // if we pressed pedal calibration slider b
    wb = pdlCommand[1] + str(int(slajderi[1].pCal[1]));
    executeWR();
  }
  if (controlb[ctrl_btn+ctrl_sh_btn+2]) { // if we pressed pedal calibration slider c
    wb = pdlCommand[2] + str(int(slajderi[2].pCal[0]));
    executeWR();
  }
  if (controlb[ctrl_btn+ctrl_sh_btn+3]) { // if we pressed pedal calibration slider d
    wb = pdlCommand[3] + str(int(slajderi[2].pCal[1]));
    executeWR();
  }
  if (controlb[ctrl_btn+ctrl_sh_btn+4]) { // if we pressed pedal calibration slider e
    wb = pdlCommand[4] + str(int(slajderi[3].pCal[0]));
    executeWR();
  }
  if (controlb[ctrl_btn+ctrl_sh_btn+5]) { // if we pressed pedal calibration slider f
    wb = pdlCommand[5] + str(int(slajderi[3].pCal[1]));
    executeWR();
  }
  if (controlb[ctrl_btn+ctrl_sh_btn+6]) { // if we pressed pedal calibration slider g
    wb = pdlCommand[6] + str(int(slajderi[4].pCal[0]));
    executeWR();
  }
  if (controlb[ctrl_btn+ctrl_sh_btn+7]) { // if we pressed pedal calibration slider h
    wb = pdlCommand[7] + str(int(slajderi[4].pCal[1]));
    executeWR();
  }
  updateEffstate(); // update effstate each time a button is realised
  if (effstate != effstateprev) { // send only if a change was made
    sendEffstate (); // send buttons into effstate
    effstateprev = effstate;
  }
  if (!profileActuated) {
    for (int i=0; i < wParmFFB.length; i++) {
      if (wParmFFB[i] != wParmFFBprev[i]) { // only if parm was changed update wb
        parmChanged = true;
        if (i != 0 && i != 10 && i != 11) {
          wb = command[i] + str(int(round(wParmFFB[i]*100.0)));
        } else if (i == 0 || i == 11) {
          wb = command[i] + str(int(round(wParmFFB[i])));
        } else if (i == 10) {
          wb = command[i] + str(int(round(wParmFFB[i]*10.0)));
        }
      }
    }
    if (parmChanged) { // you can only change 1 parm at once
      executeWR();
      parmChanged = false;
    }
  } else {
    profileActuated = false;
  }
}

void keyReleased() {
  if (key == 'r' ) {
    readString();
    wb = "none";
    println("RB: " + rb);
  }
  if (key == 'c' ) {
    if (wheelMoved) { // only update if it is not centered already
      wb = "C";
      executeWR();
      prevaxis = gpad.getSlider("Xaxis").getValue();
      wheelMoved = false;
    }
  }
  if (key == 'u' ) {
    wb = "U";
    executeWR();
  }
  if (key == 'v' ) {
    wb = "V";
    executeWR();
  }
  if (key == 's' ) {
    wb = "S";
    executeWR();
  }
  if (key == 'b' ) {
    wb = "R";
    executeWR();
  }
  if (key == 'd' ) {
    setDefaults();
  }
  if (key == '+' ) {
    changeRot(1.0);
    executeWR();
    wParmFFBprev[0]=wParmFFB[0];
  }
  if (key == '-' ) {
    changeRot(-1.0);
    executeWR();
    wParmFFBprev[0]=wParmFFB[0];
  }
  if (key == 'i' ) {
    if (!enableinfo) {
      enableinfo = true;
    } else {
      enableinfo = false;
    }
  }
  if (key == 'p' ) {
    wb = "P";
    executeWR();
  }
  if (key == 'z' ) {
    wb = "Z";
    executeWR();
  }
  buttonpressed[0] = false;
  buttonpressed[1] = false;
  buttonpressed[2] = false;
  buttonpressed[14] = false;
}

void keyPressed() {
  if (key == 'c') buttonpressed[0] = true;
  if (key == 'd') buttonpressed[1] = true;
  if (key == 'p') buttonpressed[2] = true;
  if (key == 'z') buttonpressed[14] = true;

  for (int i=0; i < wParmFFB.length; i++) {
    wParmFFBprev[i] = wParmFFB[i];
  }
}

void setDefaults() {
  for (int i=0; i < wParmFFB.length; i++) {
    if (wParmFFB[i] != defParmFFB[i]) { // only if parm different than default
      if (i != 0 && i != 10 && i != 11) {
        wb = command[i] + str(int(round(defParmFFB[i]*100.0)));
      } else if (i == 0 || i == 11) {
        wb = command[i] + str(int(round(defParmFFB[i])));
      } else if (i == 10) {
        wb = command[i] + str(int(defParmFFB[i]*10.0));
      }
      executeWR(); // send default parm to wheel and read buffer from wheel
      wParmFFB[i]=defParmFFB[i]; // update changed parm
      wParmFFBprev[i]=wParmFFB[i]; // update to latest parm
      setSliderToParm(i); // update i-th slider with new parm
    }
  }
  if (effstate != effstatedef) { // only if effstate different than default
    effstate = effstatedef;
    readEffstate(); // re-configure swithces to default values
    updateEffstate (); // update new values of effstate
    sendEffstate (); // send new values to arduino
    effstateprev = effstate;
  }
  if (lastCPR != CPRdef) {
    num1.setValue(CPRdef); // update the numberbox with the new value
  }
  if (XYshifterEnabled) { // if firmware supports shifter - load its default values
    for (int i=0; i<xysParmDef.length; i++) {
      wb = shCommand[i] + " " + xysParmDef[i]; 
      executeWR();
    }
    shifters[0].updateCal(str(xysParmDef[0])+" "+str(xysParmDef[1])+" "+str(xysParmDef[2])+" "+str(xysParmDef[3])+" "+str(xysParmDef[4])+" "+str(xysParmDef[5]));
  }
}

void setFromProfile() {
  for (int i=0; i < wParmFFB.length; i++) {
    if (wParmFFB[i] != wParmFFBprev[i]) { // only if parm different than previous
      if (i != 0 && i != 10 && i != 11) {
        wb = command[i] + str(int(round(wParmFFB[i]*100.0)));
      } else if (i == 0 || i == 11) {
        wb = command[i] + str(int(round(wParmFFB[i])));
      } else if (i == 10) {
        wb = command[i] + str(int(wParmFFB[i]*10.0));
      }
      executeWR(); // send default parm to wheel and read buffer from wheel
      wParmFFBprev[i]=wParmFFB[i]; // update to latest parm
      setSliderToParm(i); // update i-th slider with new parm
    }
  }
  if (effstate != effstateprev) { // only if effstate different than previous
    readEffstate(); // re-configure swithces to new values
    updateEffstate(); // update new values of effstate
    sendEffstate(); // send new values to arduino
    effstateprev = effstate;
    if (AFFBenabled) {
      cp5.get(ScrollableList.class, "FFBaxis").setValue(int(FFBAxisIndex)); // update analog FFB axis index if firmware supports it
    }
  }
  if (curCPR != lastCPR) {
    num1.setValue(curCPR); // update the numberbox with the new value and send to Arduino
  }
}

void setSliderToParm(int s) {
  if (s != 0 && s != 10 && s != 11) {
    sdr[s].setValue(wParmFFB[s]/slider_max); // all FFB sliders
  } else if (s == 0) {
    sdr[s].setValue(wParmFFB[s]/deg_max); // rotation deg
  } else if (s == 10) {
    sdr[s].setValue(wParmFFB[s]/minPWM_max); // maximal min torque
  } else if (s == 11) {
    sdr[s].setValue(wParmFFB[s]/brake_max); // max brake pressure
  }
  slider_value[s] = wParmFFB[s]; // update slider axisScaled value
}

void changeRot(float step) {
  if (step >= 0.0) {
    wParmFFB[0] += abs(step);
    if (wParmFFB[0] >= maxAllowedDeg(lastCPR)) {
      wParmFFB[0] = round(maxAllowedDeg(lastCPR));
    }
  } else {
    wParmFFB[0] -= abs(step);
    if (wParmFFB[0] <= deg_min) {
      wParmFFB[0] = deg_min;
    }
  }
  sdr[0].setValue(wParmFFB[0]/deg_max);
  slider_value[0] = wParmFFB[0];
  wb = command[0] + str(int(wParmFFB[0]));
}

void ActuateButton(int id) { // turns specific button on/off
  if (!buttonpressed[id]) {
    buttonpressed[id] = true;
  } else {
    buttonpressed[id] = false;
    if (id == 7) { // if ffb monitor button de-activated
      fbmnstp = true;
    }
  }
}

int bitRead(byte b, int bitPos) { // found this on net, now it is the same as bitRead in arduino
  int x = b & (1 << bitPos);
  return x == 0 ? 0 : 1;
}

byte bitWrite(byte register, int bitPos, boolean value) { // arduino's analog of bitWrite
  if (value) { // turn bit on at bitPos
    register |= 1 << bitPos;
  } else { // turn bit off at bitPos
    register &= ~(1 << bitPos);
  }
  return register;
}

void readEffstate () { // decode effstate byte
  for (int j=0; j<=4; j++) {
    buttonpressed[j+3] = boolean(bitRead(effstate, j)); // decode desktop user effect switches
  }
  for (int j=5; j<=7; j++) {
    FFBAxisIndex = bitWrite(byte(FFBAxisIndex), j-5, boolean(bitRead(effstate, j))); // decode FFB axis index
  }
  effstateprev = effstate;
}

void sendEffstate () { // send effstate byte to arduino
  wb = "E " + str(int(effstate)); // set command for switches
  executeWR(); // send switch values to arduino and read buffer from wheel
}

void updateEffstate () { // code settings into effstate byte
  for (int k=0; k <=4; k++) { //needs to be k<=4 here
    effstate = bitWrite(effstate, k, buttonpressed[k+3]); // code control switches
  }
  for (int k=5; k <=7; k++) {
    effstate = bitWrite(effstate, k, boolean(bitRead(byte(FFBAxisIndex), k-5))); // code FFB axis index
  }
}

void readPWMstate () { // decode settings from pwmstate value and update lists to those value
  typepwm = boolean(bitRead (pwmstate, 0)); // bit0 of pwmstate is pwm type
  // put pwmstate bit1 to modepwm bit0
  modepwm = bitWrite(byte(modepwm), 0, boolean(bitRead (pwmstate, 1))); // bit1 and bit6 of pwmstate contain pwm mode

  // pwmstate bits meaning  
  // bit1 bit6 pwm_mode
  // 0    0    pwm+-
  // 0    1    pwm0.50.100
  // 1    0    pwm+dir
  // 1    1    rcm

  for (int i=2; i<=5; i++) { // read frequency index, bits 2-5 of pwmstate
    freqpwm = bitWrite(byte(freqpwm), i-2, boolean(bitRead(pwmstate, i)));
  }
  if (DACenabled) {
    modedac = boolean(bitRead (pwmstate, 6)); // bit6 of pwmstate is DAC mode
  } else {
    // put pwmstate bit6 to modepwm bit1
    modepwm = bitWrite(byte(modepwm), 1, boolean(bitRead (pwmstate, 6))); // bit1 and bit6 of pwmstate contain pwm mode
  }
  enabledac = boolean(bitRead (pwmstate, 7)); // bit7 of pwmstate is DAC out enable
  pwmstateprev = pwmstate;
}

void sendPWMstate () { // send pwmstate value to arduino
  boolean settingAllowed = false;
  // check if selected pwm freq in RCM mode is allowed
  if (!RCMenabled) { // for older fw version all pwm modes are available
    settingAllowed = true;
  } else { // for RCM fw-v210 or above
    if (RCMselected) { // if we selected RCM mode
      if (freqpwm >= allowedRCMfreqID) settingAllowed = true; // if freq is lower or equal than 500Hz, freq ID higher or equal 4
    } else {  // if we selected any other pwm mode
      settingAllowed = true;
    }
  }
  if (settingAllowed) {
    wb = "W " + str(int(pwmstate)); // set command for pwm settings
    executeWR(); // send values to arduino and read buffer from wheel (arduino will save it in EEPPROM right away)
    //println(str(typepwm)+ " "+str(modepwm)+ " "+str(freqpwm));
  } else {
    showMessageDialog(frame, "You are trying to send pwm settings which are not allowed,\nplease set correct pwm settings first and try again.", "Caution", WARNING_MESSAGE);
  }
}

void updatePWMstate () { // code pwmstate byte from pwm settings values
  pwmstate = bitWrite(pwmstate, 0, typepwm);
  pwmstate = bitWrite(pwmstate, 1, boolean(bitRead(byte(modepwm), 0))); // only look at bit0 of modepwm
  for (int i=0; i <=5; i++) { // set frequency index, bits 2-5 of pwmstate
    pwmstate = bitWrite(pwmstate, i+2, boolean(bitRead(byte(freqpwm), i)));
  }
  if (DACenabled) {
    pwmstate = bitWrite(pwmstate, 6, modedac);
  } else {
    pwmstate = bitWrite(pwmstate, 6, boolean(bitRead(byte(modepwm), 1))); // only look at bit1 of modepwm
  }
  pwmstate = bitWrite(pwmstate, 7, enabledac);
  /*for (int i=0; i<8; i++) {
   print(bitRead(pwmstate, 7-i));
   }
   println("");*/
  //println("bit0="+str(bitRead(byte(modepwm), 0)) +", bit1= "+ str(bitRead(byte(modepwm), 1)));
}

// function that will be called when controller 'numbers' changes
public void CPR(int n) {
  int m = maxAllowedCPR(wParmFFBprev[0]); // last degrees of rotation
  if (n != lastCPR) {
    //println("received "+ n +" from Numberbox numbers ");
    if (n >= m) {
      n = m;
      CPRlimit = true;
    }
    wb = "O " + str(n); // set command for encoder CPR adjustment
    executeWR();
    lastCPR = n;
  }
}

void makeEditable(Numberbox n) {
  // allows the user to click a numberbox and type in a number which is confirmed with RETURN
  final NumberboxInput nin = new NumberboxInput(n); // custom input handler for the numberbox
  // control the active-status of the input handler when releasing the mouse button inside 
  // the numberbox. deactivate input handler when mouse leaves.
  n.onClick(new CallbackListener() {
    public void controlEvent(CallbackEvent theEvent) {
      nin.setActive(true);
    }
  }
  ).onLeave(new CallbackListener() {
    public void controlEvent(CallbackEvent theEvent) {
      nin.setActive(false); 
      nin.submit();
    }
  }
  );
}

void frequency(int n) {
  /* request the selected item based on index n */
  //println(n, cp5.get(ScrollableList.class, "frequency").getItem(n));
  /* here an item is stored as a Map with the following key-value pairs:
   * name, the given name of the item
   * text, the given text of the item by default the same as name
   * value, the given value of the item, can be changed by using .getItem(n).put("value", "abc"); a value here is of type Object therefore can be anything
   * color, the given color of the item, how to change, see below
   * view, a customizable view, is of type CDrawable 
   */
  CColor c = new CColor();
  c.setBackground(color(255, 0, 0));
  cp5.get(ScrollableList.class, "frequency").getItem(n).put("color", c);
  freqpwm = n;
  updatePWMstate ();
  if (n < allowedRCMfreqID) { // everything above 500Hz, or lower than freq ID 4
    if (RCMselected) showMessageDialog(frame, "This frequency is not available for RCM mode,\nplease select one of the other available ones.", "Caution", WARNING_MESSAGE);
  }
}

void pwmtype(int n) {
  CColor c = new CColor();
  c.setBackground(color(255, 0, 0));
  cp5.get(ScrollableList.class, "pwmtype").getItem(n).put("color", c);
  typepwm = boolean(n);
  updatePWMstate ();
}

void pwmmode(int n) {
  CColor c = new CColor();
  c.setBackground(color(255, 0, 0));
  cp5.get(ScrollableList.class, "pwmmode").getItem(n).put("color", c);
  modepwm = n;
  updatePWMstate ();
  if (n==3) { // if we selected RCM pwm mode, only available if firmware supports RCM pwm mode
    if (!RCMselected) { // if RCM mode is not selected
      cp5.get(ScrollableList.class, "frequency").removeItems(a1); // remove extended pwm freq selection
      cp5.get(ScrollableList.class, "frequency").addItems(a2_rcm); // add pwm freq selection for RCM pwm mode
      RCMselected = true;
    }
  } else { // if we selected anything else except for RCM mode
    if (RCMselected) { // if previous selection was RCM mode
      cp5.get(ScrollableList.class, "frequency").removeItems(a2_rcm); // remove freq selection for RCM pwm mode
      cp5.get(ScrollableList.class, "frequency").addItems(a1); // add the extented pwm freq selection
    }
    RCMselected = false;
  }
  cp5.get(ScrollableList.class, "frequency").setValue(freqpwm); // update the frequency list to the last freq selection
}

void dacmode(int n) {
  CColor c = new CColor();
  c.setBackground(color(255, 0, 0));
  cp5.get(ScrollableList.class, "dacmode").getItem(n).put("color", c);
  modedac = boolean(n);
  updatePWMstate();
}

void FFBaxis(int n) {
  CColor c = new CColor();
  c.setBackground(color(255, 0, 0));
  cp5.get(ScrollableList.class, "FFBaxis").getItem(n).put("color", c);
  FFBAxisIndex = byte(n);
  updateEffstate();
}

void profile(int n) {
  CColor c = new CColor();
  c.setBackground(color(255, 0, 0));
  cp5.get(ScrollableList.class, "profile").getItem(n).put("color", c);
  profileActuated = true;
  cur_profile = n;
  if (!profiles[n].isEmpty()) {
    profiles[n].download();
    //profiles[n].show();
    setFromProfile(); // update settings from Profile and send to Arduino if non-empty
  } else {
    println(profiles[n].name, "empty");
  }
  //listProfiles();
}

int COMselector() {
  //https://docs.oracle.com/javase/tutorial/uiswing/components/dialog.html
  //show dialog window to select a serial device
  String COMx, COMlist = "";
  int result;
  try {
    if (debug) printArray(Serial.list());
    int i = Serial.list().length;
    if (i != 0) {
      if (i >= 2) {
        // need to check which port the inst uses -
        // for now we'll just let the user decide
        for (int j = 0; j < i; ) {
          COMlist += "(" +char(j+'a') + ") " + Serial.list()[j];
          if (++j < i) COMlist += ",  ";
        }
        COMx = showInputDialog(frame, "Step 2 of setup passed succesfuly, we're almost finished.\n\t" + gpad + " at? (type letter only)\n" + COMlist, "Setup - step 3/3", QUESTION_MESSAGE);
        if (COMx == null) exit();
        if (COMx.isEmpty()) exit();

        i = int(COMx.toLowerCase().charAt(0) - 'a') + 1;
      }
      String portName = Serial.list()[i-1];
      if (debug) println(gpad, "at", portName);
      myPort = new Serial(this, portName, 115200); // change baud rate to your liking
      //myPort.bufferUntil('\n'); // buffer until CR/LF appears, but not required..
      result = i-1;
      //exit();
    } else {
      showMessageDialog(frame, "No serial port deviced detected.\n", "Warning", WARNING_MESSAGE);
      result = 0;
      //exit();
    }
  }
  catch (Exception e)
  { //Print the type of error
    showMessageDialog(frame, "Selected COM port is not available,\ndoes not exist or may be in use by\nanother program.\n", "Setup Error", ERROR_MESSAGE);
    println("Error:", e);
    result = 0;
    //exit();
  }
  return result;
}

public void handleSliderEvents(GValueControl slider, GEvent event) {
  int sdrID=0;
  for (int i=0; i<sdr.length; i++) {
    if (slider == sdr[i]) {
      sdrID = i;
      //println(i, sdr[i].getValueF());
    }
  }
  if (sdrID != 0 && sdrID != 10 && sdrID != 11) { // for all sliders except for deg of rotation, min torque and brake pressure
    slider_value[sdrID] = slider.getValueF()*slider_max;
    wParmFFB [sdrID] = slider_value[sdrID];
  } else if (sdrID == 0) { // for deg of rotation slider 0 and min torque slider 10
    slider_value[0] = round(slider.getValueF()*deg_max);
    if (slider_value[0] < deg_min) {
      slider_value[0] = deg_min;
      slider.setValue(0.0);
    }
    if (slider_value[0] >= maxAllowedDeg(lastCPR)) {
      slider_value[0] = maxAllowedDeg(lastCPR);
      slider.setValue(maxAllowedDeg(lastCPR)/deg_max);
    }
    wParmFFB [0] = slider_value[0];
  } else if (sdrID == 10) {
    slider_value[10] = slider.getValueF()*minPWM_max;
    if (slider_value[10] > minPWM_max) {
      slider_value[10] = minPWM_max;
      slider.setValue(1.0);
    }
    wParmFFB [10] = slider_value[10];
  } else if (sdrID == 11) {
    slider_value[11] = round(slider.getValueF()*brake_max);
    if (slider_value[11] < brake_min) {
      slider_value[11] = brake_min;
      slider.setValue(0.0);
    }
    if (slider_value[11] > brake_max) {
      slider_value[11] = brake_max;
      slider.setValue(1.0);
    }
    wParmFFB [11] = slider_value[11];
  }
}

String[] ProfileNameList() {
  String[] temp = new String[num_profiles];
  for (int i=0; i<num_profiles; i++) {
    temp[i] = profiles[i].name;
  }
  return temp;
}

void loadProfiles() { // checks if profiles exist and then loads them in memory
  for (int i=0; i<num_profiles; i++) {
    if (profiles[i].exists(i)) {
      profiles[i].loadFromFile("profile"+str(i));
      println("profile"+str(i)+".txt", "found");
    } else {
      //println("profile"+str(i)+".txt", "not found");
    }
    //profiles[i].show();
  }
  cp5.get(ScrollableList.class, "profile").setItems(ProfileNameList());
}

void listProfiles() {
  for (int i=0; i<num_profiles; i++) {
    //if (profiles[i].exists(i)) {
    profiles[i].show();
    //}
  }
}

int maxAllowedCPR (float deg) { // maximum allowed CPR for any gived rotation degrees range
  int temp = 0;
  temp = int((float(maxCPR_turns))/(deg/360.0));
  if (temp >= maxCPR) {
    temp = maxCPR;
  }
  return temp;
}

float maxAllowedDeg (float cpr) { // maximum allowed rotation degrees range for any given encoder CPR
  float temp = 0.0;
  temp = float(maxCPR_turns)/(cpr/360.0);
  if (temp >= deg_max) {
    temp = deg_max;
  }
  return temp;
}

void SetAxisColors() { // set default, load or save axis colors into a txt file
  File ac = new File(dataPath("axisColor_cfg.txt"));
  if (!ac.exists()) { // if file does not exist
    for (int i=0; i<num_axis; i++) { // initialize default axis colors
      axis_color[i] = color(i*48, 255, 255); // hue, saturation, brightness
    }
    String acset[] = {hex(axis_color[0]), hex(axis_color[1]), hex(axis_color[2]), hex(axis_color[3]), hex(axis_color[4])};
    saveStrings("/data/axisColor_cfg.txt", acset);  // save axis colors in HEX form
    println("axis colors: saved to txt");
  } else { // load colors from txt
    String[] newcolors = loadStrings("axisColor_cfg.txt");
    for (int i=0; i<num_axis; i++) {
      axis_color[i] = color(int(unhex(newcolors[i]))); //unhex returns int from string containing HEX number
    }
    println("axis colors: loaded from txt");
  }
}

/*void SquareAroundButtons() {
 strokeWeight(1);
 stroke(120);
 noFill();
 rect(Xoffset+width/2 + 1.5*60, height-posY+140, 274, 20); // for pwm
 rect(Xoffset+width/2 + 6.3*60, height-posY+140, 120, 20); // for for default, save
 rect(Xoffset+width/2 + 8.5*60, height-posY+140, 138, 20); // for for store
 }*/

void showSetupText(String text) {
  updateSetupText(text); // fill in the text buffer
  background(51);
  for (int i=1; i<setupTextBuffer.length; i++) {
    text(setupTextBuffer[i], 20, height-(i+1)*font_size);
  }
}

void updateSetupText(String inline) {
  setupTextBuffer[0] = inline;
  for (int i=setupTextBuffer.length-1; i>0; i--) {
    setupTextBuffer[i] = setupTextBuffer[i-1];
  }
}

void clearSetupText() {
  for (int i=0; i<setupTextBuffer.length; i++) {
    setupTextBuffer[i] = " ";
  }
}

void draw_setupText() {
  float maxWidth = 0;
  for (int i=0; i<setupTextBuffer.length; i++) {
    if (textWidth(setupTextBuffer[i]) >= maxWidth) maxWidth = textWidth(setupTextBuffer[i]);
  }
  if (setupTextTimer < setupTextTimeout_ms) {
    for (int i=1; i<setupTextBuffer.length; i++) {
      if (setupTextBuffer[i].equals(" ")) break; // do not show empty lines
      fill(51);
      strokeWeight(1);
      stroke(51);
      rect(20, height-(i+1)*font_size, maxWidth, -1.2*font_size);
      pushMatrix();
      translate(20, height-(i+1)*font_size);
      fill(255);
      textSize(font_size);
      text(setupTextBuffer[i], 0, 0);
      popMatrix();
    }
  }
}

void refreshXYshifterPos() {
  wb = shCommand[7];
  executeWR();
}
void refreshXYshifterCal() {
  wb = shCommand[6];
  executeWR();
}

void updateLastShifterConfig() { // update curent shifter cal and config values
  for (int i=0; i<shifterLastConfig.length; i++) {
    shifterLastConfig[i] = int(shifters[0].sCal[i]); // XY shifter calibration values
  }
  shifterLastConfig[5] = int(shifters[0].sConfig); // XY shifter configuration
}

void refreshPedalCalibration() {
  wb = pdlCommand[8];
  executeWR();
}

void updateLastPedalCalibration(String calibs) { // update curent firmware pedal manual cal limits
  float[] temp = float(split(calibs, ' ')); // format is "min max min max min max min max"
  for (int i=0; i<pdlMinParm.length; i++) {
    pdlMinParm[i] = temp[2*i]; // every even number is min
    pdlMaxParm[i] = temp[2*i+1]; // every odd number is max
    slajderi[i+1].updateCal(pdlMinParm[i], pdlMaxParm[i]); //update pCal
  }
}
