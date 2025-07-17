import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import org.gamecontrolplus.gui.*; 
import org.gamecontrolplus.*; 
import net.java.games.input.*; 
import processing.serial.*; 
import sprites.*; 
import sprites.maths.*; 
import sprites.utils.*; 
import controlP5.*; 
import java.util.*; 
import static javax.swing.JOptionPane.*; 
import javax.swing.JFrame.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class wheel_control extends PApplet {

/*Arduino Force Feedback Wheel User Interface
 
 Copyright 2018-2025 Milos Rankovic (ranenbg [at] gmail [dot] com)
 
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
 and fitness. In no event shall the author be liable for any
 special, indirect or consequential damages or any damages
 whatsoever resulting from loss of use, data or profits, whether
 in an action of contract, negligence or other tortious action,
 arising out of or in connection with the use or performance of
 this software.
 */




//import g4p_controls.*;









String cpVer="v2.6.5"; // control panel version
int xSize_init = 1440; // default window width
int ySize_init = 800; // default window height
int bckBrgt = 51; // background brignthness 

Serial myPort; // Create object from Serial class
String rb;     // Data received from the serial port
String wb;     // Data to send to the serial port
final boolean debug = true;

Sprite[] sprite = new Sprite[1];
Domain domain;

ControlP5 cp5; // Editable Numberbox for ControlP5
Numberbox num1; // encoder cpr 
// drowdown menu lists
ScrollableList ffb_axis; // ffb x-axis selector dropdown menu list
ScrollableList profile; // profile dropdown menu list
ScrollableList pwm_type; // pwm type dropdown menu list
ScrollableList pwm_mode; // pwm mode dropdown menu list
ScrollableList pwm_freq; // pwm frequency dropdown menu list
ScrollableList dac_mode; // dac mode dropdown menu list
ScrollableList dac_out; // dac output dropdown menu list

int num_axis = 5; // number of HID device axis
int num_sldr = 12; // number of FFB sliders
//GCustomSlider[] sdr = new GCustomSlider [num_sldr]; // g4p sliders for ffb/firmware settings
Slider[] cp5sdr = new Slider[num_sldr]; // cp5 sliders for ffb/firmware settings
int num_btn = 24;  // number of wheel buttons
int btn_size_init = 18; // initial button size before re-sizing
int btn_sep_init = 10; // initial button separation before re-sizing
int hatsw_r_init = 14; // initial hatswitch small radius before re-sizing
int hatsw_R_init = 48; // initial hatswitch big radius before re-sizing
int ctrl_btn = 18; // number of control buttons
int ctrl_sh_btn = 5; // number of control buttons for XY shifter
int ctrl_axis_btn = 2*num_axis; // number of control buttons for HID device axis
int key_btn = 12;  // number of keyboard function buttons
int gbuffer = 500; // number of points to show in ffb graph
int gskip = 8; // ffb monitor graph vertical divider
int num_profiles = 64; // number of FFB setting profiles (including default profile)
int num_prfset = 18; // number of FFB settings inside a profile
int cur_profile; // currently loaded FFB settings profile
String[] command = new String[num_sldr]; // commands for wheel FFB parameters set
float[] wParmFFB = new float[num_sldr]; // current wheel FFB parameters
float[] wParmFFBprev = new float[num_sldr]; // previous wheel FFB parameters
float[] defParmFFB = new float[num_sldr]; // deafault wheel FFB parameters
String[] sliderlabel = new String[num_sldr];
float[] slider_value = new float[num_sldr];
boolean parmChanged = false; // keep track if any FFB parm was changed
boolean wheelMoved = false; // keep track if wheel axis is centered
float prevaxis = 0.0f; // previous steer axis value
int axisHeight = 250; // curent length of axis ruler axisHeight
int axisHeight_init = 250; // initial length of axis ruler axisHeight (before re-sizing)
float posY;
int[] col = new int[3]; // colors for control buttons, hsb mode
int thue; // color for text of control button, gray axisHeight mode
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
float deg_min = 30.0f; // minimal allowed angle by firmware
float deg_max = 1800.0f; // maximal allowed angle by firmware
int maxCPR_turns = maxCPR*PApplet.parseInt(deg_max/360.0f); // maximum acceptable CPR*turns by firmware
float minPWM_max = 20.0f; // maximum allowed value for minPWM
float brake_min = 1.0f; // minimal brake pressure
float brake_max = 255.0f; // max brake pressure
boolean fbmnstp = false; // keeps track if we deactivated ffb monitor
String fbmnstring; // string from ffb monitor readout
String COMport[]; // string for serial port on which Arduino Leonardo is reported
boolean BBenabled = false; // keeps track if button box is supported (3 digit fw ending with 1, only up to v240)
boolean BMenabled = false; // keeps track if button matrix is supported (option "t") 
boolean LCenabled = false; // keeps track if load cell is supported (3 digit fw ending with 2, only up to v240)
boolean DACenabled = false; // keeps track if FFB DAC output is supported in firmware (3 digit fw ending with 3, only up to v240)
boolean TCA9548enabled = false; // keeps track if multiplexer chip is supported in firmware (option "u")
boolean checkFwVer = true; // when enabled update fwVersion will take place
boolean enabledac; // keeps track if DAC output is not zeroed
int modedac; // keeps track of DAC output settings
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
byte fwOpt = 0; // Arduino firmware options 1st byte, if present bit is HIGH (b0-a, b1-z, b2-h, b3-s, b4-i, b5-m, b6-t, b7-f)
byte fwOpt2 = 0; // Arduino firmware options 2nd byte, if present bit is HIGH (b0-e, b1-x, b2-w, b3-c, b4-r, b5-b, b6-d, b7-p)
byte fwOpt3 = 0; // Arduino firmware options 3rd byte, if present bit is HIGH (b0-, b1-l, b2-g, b3-u, b4-, b5-, b6-, b7-)
boolean noOptEnc = false; // true if firmware with "d" option without optical encoder support
boolean noMagEnc = true; // false if firmware with "w" option which supports magnetic encoder AS5600
boolean clutchenabled = true; // true if firmware supports clutch analog axis (not the case only for fw option "e")
boolean hbrakeenabled = true; // true if firmware supports handbrake analog axis (not the case only for fw option "e")
boolean twoFFBaxis_enabled = false; // true if firmware supports 2 FFB axis (option "b")
int Xoffset = -44; // X-axis offset for buttons
boolean XYshifterEnabled = false; // keeps track if XY analog shifter is supported by firmware
int shifterLastConfig[] = new int[6]; // last XY shifter calibration and configuration settings
String[] shCommand = new String[ctrl_sh_btn+3]; // commands for XY shifter settings
float shScale_init = 0.25f; // XY shifter size
float shXoff; // XY shifter horizontal offset from first axisBar
int[] xysParmDef = new int [6]; // XY shifter defaults
String[] pdlCommand = new String[9]; // commands for pedal calibration
float[] pdlMinParm = new float [num_axis-1]; // curent pedal minimum cal values
float[] pdlMaxParm = new float [num_axis-1]; // curent pedal maximum cal values
float[] pdlParmDef = new float [2*(num_axis-1)]; // default pedal cal values
int pdlDefMax = 1023; // default pedal Max calibration value for standard firmware
// pwm frequency selection possibilities - depends on firmware version and RCM mode
List a = Arrays.asList("40.0 kHz", "20.0 kHz", "16.0 kHz", "8.0 kHz", "4.0 kHz", "3.2 kHz", "1.6 kHz", "976 Hz", "800 Hz", "488 Hz"); // for fw-v200 or lower
List a1 = Arrays.asList("40.0 kHz", "20.0 kHz", "16.0 kHz", "8.0 kHz", "4.0 kHz", "3.2 kHz", "1.6 kHz", "976 Hz", "800 Hz", "488 Hz", "533 Hz", "400 Hz", "244 Hz"); // wider pwm freq selection (fw-v210+), no RCM selected
List a2_rcm = Arrays.asList("na", "na", "na", "na", "500 Hz", "400 Hz", "200 Hz", "122 Hz", "100 Hz", "61 Hz", "67 Hz", "50 Hz", "30 Hz"); // alternate pwm freq selection if RCM selected
List b, c, c1, c2_rcm, c3_2pwm, d, d_250, d_250_2ch, d2, e, fb; // create scrolable list objects for other drop down menu lists
int allowedRCMfreqID = 4; // first allowed pwm freq ID for RCM mode from the above list (anything after including 500Hz is allowed)
int xFFBAxisIndex; // index of axis that is tied to the xFFB axis (bits 5-7 from effstate byte)
int yFFBAxisIndex = 1; // index of axis that is tied to the yFFB axis (at the moment fixed to y-axis in firmware)
int setupTextLines = 24; // number of available lines for text in configuration window
String[] setupTextBuffer = new String[setupTextLines]; // array that holds all text for configuration window
int setupTextTimeout_ms = 5000; // show setup text only during this timeout in [ms]
int setupTextFadeout_ms = 1500; // durration of setup text fadeout at the end of timeout [ms]
boolean showSetupText = true; // set to false after timeout + fadeout
float setupTextInitAlpha = 255; // initial setup text alpha before fadeout
float setupTextAlpha; // current text setup alpha
int setupTextLength = 0; // keeps track of how many lines of text we have in the setup text buffer
int ffbx = 0; // x-axis FFB value from FFB monitor
int ffby = 0; // y-axis FFB value from FFB monitor
boolean reSizeGUI = false; // keeps track if we need to re-draw re-scaled GUI elemets (save resources if window size remains unchanged)
int widthprev, heightprev; // last values of window size before rescaling
float wScaleX = 1.0f; // window X scale
float wScaleY = 1.0f; // window Y scale
int widthmin = 400; // minimal window X size
int heightmin = 222; // minimal window Y size
float cp5xoff = 1.75f; // horizontal divider offset from left for cp5 sliders
float cp5yoff = 0.055f; // vertical offset from top for cp5 sliders
float cp5sdy = 44; // height divider for cp5 sliders (vertical separation)
float cp5sx = 3.5f; // x size divider for cp5 sliders
float cp5sy = 65; // y size divider for cp5 sliders

ControlIO control;
Configuration config;
ControlDevice gpad;

// gamepad axis array
float[] Axis = new float[num_axis];
float axisValue;
//float axisHeightdValue;
// gamepad button array
boolean[] Button = new boolean [num_btn];
boolean buttonValue = false;
// gamepad D-pad
//int[] Dpad = new int[8];
int hatvalue;
// control buttons
boolean[] controlb = new boolean[ctrl_btn+ctrl_sh_btn+ctrl_axis_btn]; // true as long as mouse is howered over

PFont font, fontd;
int font_size_init = 12;
int font_size = 12;

int slider_width = 400;
int slider_height = 110;
int sldXoff = 100;
float slider_max = 2.0f;
int[] axis_color = new int [num_axis];

Wheel[] wheels = new Wheel [1];
AxisBar[] axisBars = new AxisBar[num_axis];
WheelButton[] wbuttons = new WheelButton[num_btn];
HatSW[] hatsw = new HatSW[1];
Dialog[] dialogs = new Dialog [1];
Button[] buttons = new Button[ctrl_btn];
Info[] infos = new Info[key_btn];
FFBgraph[] ffbgraphs = new FFBgraph[2];
Profile[] profiles = new Profile[num_profiles];
XYshifter[] shifters = new XYshifter[1];
InfoButton[] infobuttons = new InfoButton [1];

// Default dimensions if no arguments are provided or they are invalid
int defaultWidth = xSize_init;
int defaultHeight = ySize_init;
int windowWidth = defaultWidth;
int windowHeight = defaultHeight;

public void settings() {
  // Check if command-line arguments were provided
  if (args != null && args.length >= 2) {
    println("Window size arguments received: ", args.length); // Optional: print received args count
    println("width: ", args[0]);
    println("height: ", args[1]);
    try {
      // Attempt to parse the first two arguments as integers
      windowWidth = Integer.parseInt(args[0]);
      windowHeight = Integer.parseInt(args[1]);
      println("Using custom window size: ", windowWidth, "x", windowHeight);
    } 
    catch (NumberFormatException e) {
      // Handle cases where arguments are not valid numbers
      windowWidth = defaultWidth;
      windowHeight = defaultHeight;
      System.err.println("Error parsing arguments for window size. Using " + str(windowWidth) + "x" + str(windowHeight));
      System.err.println(e.getMessage());
    }
  } else {
    // Use default size if no or not enough arguments are provided
    windowWidth = defaultWidth;
    windowHeight = defaultHeight;
    println("None or invalid arguments for window size. Using " + str(windowWidth) + "x" + str(windowHeight));
  }
  // Set the size
  size(windowWidth, windowHeight, JAVA2D);
  //noSmooth();
  smooth(2);
}

public void setup() {
  //size(1440, 800, JAVA2D); // window size is given by the arguments in app shortcut, if none/invalid is provided - defaults from beginning of sketch are used
  widthprev = xSize_init;
  heightprev = ySize_init;
  surface.setTitle("Wheel Control " + cpVer);
  surface.setResizable(true);
  colorMode (HSB);
  frameRate(100);
  background(bckBrgt);
  PImage icon = loadImage("/data/rane_wheel_rim_O-shape.png");
  surface.setIcon(icon);
  println("=======================================================\n  Arduino-FFB-Wheel Graphical User Interface\t\n  Wheel Control "+cpVer +" created by\t\n  Milos Rankovic 2018-2025");
  clearSetupTextBuffer();
  showSetupTextLine("Wheel control "+cpVer+" configuration initialized");
  showSetupTextLine("Resolution: " + str(widthprev) + "x" + str(heightprev));
  File f = new File(dataPath("COM_cfg.txt"));
  //https://docs.oracle.com/javase/tutorial/uiswing/components/dialog.html
  if (!f.exists()) showMessageDialog(frame, "COM_cfg.txt was not found in your PC, but do not worry.\nYou either run the app for the 1st time, or you have\ndeleted the configuration file for a fresh start.\n\t\nPress OK to continue with the automatic setup process.", "Arduino FFB Wheel " + cpVer +" - Hello World :)", INFORMATION_MESSAGE);
  if (!f.exists()) showMessageDialog(frame, "Setup will now try to find control IO instances.\n", "Setup - step 1/3", INFORMATION_MESSAGE);
  // Initialise the ControlIO
  //showSetupTextLine("Initializing IO instances");
  control = ControlIO.getInstance(this);
  println("Instance:", control);
  // Find a device that matches the configuration file
  if (!f.exists()) showMessageDialog(frame, "Step 1 of setup has passed succesfully.\nSetup will now try to look for available game devices in your PC.\n", "Setup - step 2/3", INFORMATION_MESSAGE);
  String inputdevices = "";
  inputdevices = control.deviceListToText("");
  if (!f.exists()) showMessageDialog(frame, "\nThe following devices are found in your PC:\n\t\n"+inputdevices+"\nThe setup will now try to configure each device, but bare in mind that some devices may cause the app to crash.\nIf that happens, you may try to manually create COM_cfg.txt file (see manual.txt in data folder for instructions),\nor you may try to run wheel_control.pde source code from Processsing IDE version 3.5.4.\n", "Setup - list of available devices", INFORMATION_MESSAGE);
  println(inputdevices);
  //showSetupTextLine("Looking for compatible devices");
  gpad = control.getMatchedDevice("Arduino Leonardo wheel v5");
  if (gpad == null) {
    println("No suitable HID device found");
    showSetupTextLine("No suitable HID device found");
    System.exit(-1); // End the program NOW!
  } else {
    showSetupTextLine("HID device: " + gpad);
    println("HID device:", gpad);
  }
  int r;
  //println("   config:",f.exists());
  if (f.exists()) { // if there is COM_cfg.txt, load serial port number from cfg file
    COMport = loadStrings("/data/COM_cfg.txt");
    showSetupTextLine("Port: " + COMport[0] + ", loaded from txt");
    ExportSetupTextLog();
    //showMessageDialog(frame, "COM_cfg.txt found\nDetected port: " + COMport[0], "Info", INFORMATION_MESSAGE);
    println("Port: " + COMport[0] + ", loaded from txt");
    myPort = new Serial(this, COMport[0], 115200);
  } else {  // open window for selecting available COM ports
    println("COM: searching...");
    showSetupTextLine("COM_cfg not found, starting setup wizard.");
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
  myPort.bufferUntil(PApplet.parseChar(10)); // read serial data utill line feed character (we still need to toss carriage return char from input string)

  //font = createFont("Arial", 16, true);
  textSize(font_size);

  posY = height - (2.2f*axisHeight);

  // Create the sprites
  Domain domain = new Domain(0, 0, width, height);
  sprite[0] = new Sprite(this, "rane_wheel_rim_O-shape.png", 10);
  //sprite[0] = new Sprite(this, "rane_wheel_rim_D-shape.png", 10);
  sprite[0].setVelXY(0, 0);
  sprite[0].setXY(0.038f*width+0.5f*axisHeight, posY-72);
  sprite[0].setDomain(domain, Sprite.REBOUND);
  sprite[0].respondToMouse(false);
  sprite[0].setZorder(1);
  //sprite[0].setScale(0.9);

  //for (int i = 0; i < wheels.length; i++) {
  //wheels[0] = new Wheel(0.054*width+0.4*axisHeight, posY-72, axisHeight_init*0.95, axisHeight_init*0.95, str(frameRate));
  //wheels[1] = new Wheel(width/2+1.8*axisHeight, height/2, axisHeight*0.9, "LFS car's wheel Y");
  //}
  
  wheels[0] = new Wheel(0.123f*widthprev, 0.223f*heightprev, wScaleX*axisHeight_init*0.8f, wScaleY*axisHeight_init*0.8f, str(frameRate));

  SetAxisColors(); // checks for existing colors in txt file

  axisBars[0] = new AxisBar(axis_color[0], width/3.65f + 0*60, height-posY, 10, 65535, "X", "c", "d", false, false);
  axisBars[1] = new AxisBar(axis_color[1], width/3.65f + 1*60, height-posY, 10, pdlDefMax, "Y", "a", "b", false, true);
  axisBars[2] = new AxisBar(axis_color[2], width/3.65f + 2*60, height-posY, 10, pdlDefMax, "Z", "c", "d", false, false);
  axisBars[3] = new AxisBar(axis_color[3], width/3.65f + 3*60, height-posY, 10, pdlDefMax, "RX", "e", "f", false, false);
  axisBars[4] = new AxisBar(axis_color[4], width/3.65f + 4*60, height-posY, 10, pdlDefMax, "RY", "g", "h", false, false);

  for (int i=0; i<axisBars.length; i++) {
    axisBars[i].update(i, false);
  }
  prevaxis = axisBars[0].axisVal;

  for (int j = 0; j < wbuttons.length; j++) { // wheel buttons
    if (j <= 7) {
      wbuttons[j] = new WheelButton(0.05f*width +j*(btn_size_init+btn_sep_init), height-posY*1.85f, btn_size_init);
    } else if (j > 7 && j < 16) {
      wbuttons[j] = new WheelButton(0.05f*width +(j-8)*(btn_size_init+btn_sep_init), height-posY*1.85f+(btn_size_init+btn_sep_init), btn_size_init);
    } else if (j > 15 && j < 24) {
      wbuttons[j] = new WheelButton(0.05f*width +(j-16)*(btn_size_init+btn_sep_init), height-posY*1.85f+2*(btn_size_init+btn_sep_init), btn_size_init);
    }
  }

  dialogs[0] = new Dialog(0.05f*width, height-posY*1.85f+3*28, 16, "waiting input..");

  // info buttons for displaying some settings
  String[] enc = new String[2];
  enc[0] = "opt."; // optical quadrature encoder
  enc[1] = "mag"; // magnetic encoder
  infobuttons[0] = new InfoButton (0.05f*width + 3.45f*60, height-posY-490, 70, 16, 2, enc, "enc. type", 0);

  // encoder and pedal calibration buttons
  buttons[0] = new Button(0.05f*width + 3.45f*60, height-posY-270, 48, 16, "center", "set to 0°", 0);
  buttons[14] = new Button(0.05f*width + 4.3f*60, height-posY-270, 18, 16, "z", "reset", 0);
  buttons[2] = new Button(width/3.7f + 2.9f*60, height-posY+31, 70, 16, "auto pcal", "reset", 3);
  buttons[13] = new Button(width/3.7f + 2.9f*60, height-posY+50, 70, 16, "man. pcal", "set cal", 3);

  // h-shifter buttons
  buttons[11] = new Button(width/3.7f + 1.0f*60, height-posY+31, 63, 16, "H-shifter", "set cal", 0);
  buttons[15] = new Button(width/3.7f + 1.0f*60, height-posY+50, 16, 16, "x", "inv", 2);
  buttons[12] = new Button(width/3.7f + 2.1f*60, height-posY+31, 16, 16, "r", "8th", 3);
  buttons[17] = new Button(width/3.7f + 2.1f*60, height-posY+50, 16, 16, "b", "inv", 3);
  buttons[16] = new Button(width/3.7f + 1.3f*60, height-posY+50, 16, 16, "y", "inv", 3);

  // optional and ffb effect on/off toggle buttons
  /*buttons[7] = new Button(sldXoff+width/2+slider_width+60, slider_height/2*(1+1)-12, 16, 16, " ", "FFB monitor", 3);
   buttons[4] = new Button(sldXoff+width/2+slider_width+60, slider_height/2*(1+2)-12, 16, 16, " ", "user damper", 3);
   buttons[5] = new Button(sldXoff+width/2+slider_width+60, slider_height/2*(1+7)-12, 16, 16, " ", "user inertia", 3);
   buttons[6] = new Button(sldXoff+width/2+slider_width+60, slider_height/2*(1+3)-12, 16, 16, " ", "user friction", 3);
   buttons[3] = new Button(sldXoff+width/2+slider_width+60, slider_height/2*(1+8)-12, 16, 16, " ", "autocenter spring", 3);*/
  buttons[7] = new Button(xPosCP5sdr(7), yPosCP5sdr(1), 16, 16, " ", "FFB monitor", 3);
  buttons[4] = new Button(xPosCP5sdr(4), yPosCP5sdr(2), 16, 16, " ", "user damper", 3);
  buttons[5] = new Button(xPosCP5sdr(5), yPosCP5sdr(7), 16, 16, " ", "user inertia", 3);
  buttons[6] = new Button(xPosCP5sdr(6), yPosCP5sdr(3), 16, 16, " ", "user friction", 3);
  buttons[3] = new Button(xPosCP5sdr(3), yPosCP5sdr(8), 16, 16, " ", "autocenter spring", 3);

  // general control push buttons
  buttons[9] = new Button(Xoffset+width/2 + 5.3f*60, height-posY+140, 38, 16, "pwm", "set and save pwm settings to arduino (arduino reset required)", 0);
  buttons[1] = new Button(Xoffset+width/2 + 6.35f*60, height-posY+140, 50, 16, "default", "load default settings", 0);
  buttons[8] = new Button(Xoffset+width/2 + 7.6f*60, height-posY+140, 38, 16, "save", "save all settings to arduino", 0);
  buttons[10] = new Button(Xoffset+width/2 + 10.04f*60, height-posY+140, 38, 16, "store", "save all settings to PC", 0);
  /*buttons[9] = new Button(xPosCP5sdr(9), yPosCP5sdr(12), 38, 16, "pwm", "set and save pwm settings to arduino (arduino reset required)", 0);
   buttons[1] = new Button(xPosCP5sdr(1), yPosCP5sdr(12), 50, 16, "default", "load default settings", 0);
   buttons[8] = new Button(xPosCP5sdr(8), yPosCP5sdr(12), 38, 16, "save", "save all settings to arduino", 0);
   buttons[10] = new Button(xPosCP5sdr(10), yPosCP5sdr(12), 38, 16, "store", "save all settings to PC", 0);*/

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

  description[0] = "read serial buffer";
  description[1] = "re-center X axis";
  description[2] = "reset encoder Z-index";
  description[3] = "read encoder Z-state";
  description[4] = "reset pedal calibration";
  description[5] = "read firmware settings";
  description[6] = "read frimware version";
  description[7] = "load default settings";
  description[8] = "calibrate right endstop";
  description[9] = "increase rotation (+1deg)";
  description[10] = "decrease rotation (-1deg)";
  description[11] = "show/hide information";

  for (int n = 0; n < infos.length; n++) {
    infos[n] = new Info(0.05f*width, height-posY*1.85f+4*(btn_size_init+btn_sep_init)+2*n*font_size, font_size, description[n], keys[n]);
  }

  for (int k = 0; k < hatsw.length; k++) {
    hatsw[k] = new HatSW(0.05f*width + 9*(btn_size_init+btn_sep_init) + 7, height-posY*1.85f+1*(btn_size_init+btn_sep_init) + 10, hatsw_r_init, hatsw_R_init);
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

  // create G4P (red) sliders for configuring firmware and ffb parameters
  /*for (int j = 0; j < sdr.length; j++) {
   sdr[j] = new GCustomSlider(this, width/2+sldXoff, slider_height/2*j-4, slider_width, slider_height, "red_yellow18px");
   // Some of the following statements are not actually required because they are setting the default values only 
   sdr[j].setLocalColorScheme(2); 
   sdr[j].setOpaque(false); 
   sdr[j].setNbrTicks(10); 
   sdr[j].setShowLimits(false); 
   sdr[j].setShowValue(false); 
   sdr[j].setShowTicks(true); 
   sdr[j].setStickToTicks(false); 
   sdr[j].setEasing(1.0); 
   sdr[j].setRotation(0.0, GControlMode.CENTER);
   }*/

  // create CP5 (blue) sliders for configuring firmware and ffb parameters
  cp5 = new ControlP5(this);
  for (int i=0; i<cp5sdr.length; i++) {
    cp5sdr[i] = cp5.addSlider(sliderlabel[i])
      .setPosition(PApplet.parseInt(widthprev/cp5xoff), PApplet.parseInt(heightprev*(cp5yoff + i*3/cp5sdy)))
      .setSize(PApplet.parseInt(widthprev/cp5sx), PApplet.parseInt(heightprev/cp5sy))
      .setRange(0, 1)
      .setValue(slider_value[i])
      .setLabelVisible(false)
      //.setNumberOfTickMarks(10)
      .snapToTickMarks(false)
      .setSliderMode(Slider.FLEXIBLE)
      ;
  }

  // default FFB parameters and firmware settings
  defParmFFB[0] = 1080.0f;
  defParmFFB[1] = 1.0f;
  defParmFFB[2] = 0.5f;
  defParmFFB[3] = 0.5f;
  defParmFFB[4] = 1.0f;
  defParmFFB[5] = 1.0f;
  defParmFFB[6] = 1.0f;
  defParmFFB[7] = 0.5f;
  defParmFFB[8] = 0.7f;
  defParmFFB[9] = 1.0f;
  defParmFFB[10] = 0.0f;
  defParmFFB[11] = 45.0f;
  effstatedef = 1; // only autocentering spring is enabled by default
  maxTorquedef = 2047;
  CPRdef = 2400;
  pwmstatedef = 12; // fast pwm, 7.8kHz, pwm+-
  // default XY shifter calibration values
  xysParmDef[0] = 255;
  xysParmDef[1] = 511;
  xysParmDef[2] = 767;
  xysParmDef[3] = 255;
  xysParmDef[4] = 511;
  xysParmDef[5] = 2; // reverse in 6th gear, x-normal, y-normal, b-normal

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
  // pedal calibration related commands
  pdlCommand[0] = "YA ";
  pdlCommand[1] = "YB ";
  pdlCommand[2] = "YC ";
  pdlCommand[3] = "YD ";
  pdlCommand[4] = "YE ";
  pdlCommand[5] = "YF ";
  pdlCommand[6] = "YG ";
  pdlCommand[7] = "YH ";
  pdlCommand[8] = "YR";
  // XY shifter calibration related commands
  shCommand[0] = "HA ";
  shCommand[1] = "HB ";
  shCommand[2] = "HC ";
  shCommand[3] = "HD ";
  shCommand[4] = "HE ";
  shCommand[5] = "HF ";
  shCommand[6] = "HG";
  shCommand[7] = "HR";

  refreshWheelParm(); // update all wheel FFB parms and close FFB mon if left running
  for (int i=0; i < wParmFFB.length; i++) {
    setSliderFromParm(i); // update sliders with new wheel FFB parms
  }
  readFwVersion(); // get Arduino FFB Wheel firmware version

  // advanced debugging of firmware options
  if (bitRead(fwOpt, 1) == 1) { // if bit1=1 - encoder with Z-index channel suported by firmware (option "z")
    showSetupTextLine("Encoder with a Z-index detected");
    println("Encoder Z-index detected");
  }
  if (bitRead(fwOpt, 2) == 1) { // if bit2=1 - hat Switch suported by firmware (option "h")
    hatsw[0].enabled = true;
    for (int i=0; i<4; i++) {
      if (!BBenabled && !BMenabled) { // last 4 buttons of 2nd byte are unavailable if we are not using button matrix or button box
        wbuttons[i].enabled = true;
      }
    }
    showSetupTextLine("Hat switch (D-pad) enabled");
    println("Hat switch enabled");
  } else { 
    for (int i=0; i<8; i++) {
      wbuttons[i].enabled = true; // by default we have 8 direct pins for buttons available
    }
  }
  if (bitRead(fwOpt, 3) == 1) { // of bit3=1 - averaging of analog inputs is supported by firmware (option "i")
    showSetupTextLine("Averaging of analog inputs for pedals enabled");
    println("Analog input averaging enabled");
    pdlDefMax = 4095;
    axisBars[1].am = pdlDefMax;
    axisBars[2].am = pdlDefMax;
    axisBars[3].am = pdlDefMax;
    axisBars[4].am = pdlDefMax;
  } else if (bitRead(fwOpt, 4) == 1) { // if bit4=1 - external 12bit ADC ads1105 is supported by firmware (option "s")
    showSetupTextLine("External 12bit ADC ads1105 for pedals detected");
    println("ADS1105 detected");
    pdlDefMax = 2047;
    axisBars[1].am = pdlDefMax; // brake Y-axis 
    axisBars[2].am = pdlDefMax; // accelerator Z-axis 
    axisBars[3].am = pdlDefMax; // clutch RX-axis 
    axisBars[4].am = pdlDefMax; // handbrake RY-axis
  }

  // default pedal calibration settings (depend on firmware options so we need to read fw version first)
  for (int i=0; i<pdlMinParm.length; i++) {
    pdlParmDef[2*i] = 0;
    pdlParmDef[2*i+1] = pdlDefMax;
  }

  if (bitRead(fwOpt, 6) == 1) { // if bit6=1 - 4x4 button matrix suported by firmware (option "t")
    for (int i=0; i<16; i++) {
      if (bitRead(fwOpt, 2) == 1 && i > 11) {  // enable first 16 buttons, except for last 4 if we have hat switch
        wbuttons[i].enabled = false;
      } else {
        wbuttons[i].enabled = true;
      }
    }
    showSetupTextLine("4x4 button matrix detected");
    println("Button matrix detected");
  }
  if (BBenabled) { // if button box is supported by firmware, enable first 16 buttons
    for (int i=0; i<16; i++) {
      if (bitRead(fwOpt, 2) == 1 && i > 11) {  // enable first 16 buttons, except for last 4 if we have hat switch
        wbuttons[i].enabled = false;
      } else {
        wbuttons[i].enabled = true;
      }
    }
    if (bitRead(fwOpt2, 4) == 1) { // if bit4=1, we have firmware with 24 buttons supported (option "r")
      for (int i=0; i<8; i++) {
        wbuttons[16+i].enabled = true; // enable last 8 buttons
      }
      if (bitRead(fwOpt, 2) == 1) { // if we have hat switch, then only last 4 buttons are unavailable
        for (int i=0; i<4; i++) {
          wbuttons[12+i].enabled = true; // re-enable last 4 buttons in 2nd byte
          wbuttons[20+i].enabled = false; // disable last 4 buttons in 3rd byte
        }
      }
      showSetupTextLine("Using shift register: SN74ALS166N (24 buttons)");
      println("Nano button box detected");
    } else { // otherwise is 16 buttons
      showSetupTextLine("Using shift register: nano button box (16 buttons)");
      println("SN74ALS166N detected");
    }
  }
  if (bitRead(fwOpt, 5) == 1) { // if bit5=1 - Arduino ProMicro pinouts suported by firmware (option "m")
    if (bitRead(fwOpt, 1) == 1 || bitRead(fwOpt, 4) == 1) {
      wbuttons[3].enabled = false; // button3 is unavailable on proMicro if we use zindex, or any i2C device
    }
    showSetupTextLine("Arduino ProMicro replacement pinouts detected");
    println("ProMicro pinouts detected");
  }
  if (!LCenabled) { // max brake slider becomes FFB balance if no load cell
    sliderlabel[11] = "FFB balance L/R";
    defParmFFB[11] = 128.0f;
  } else {
    //axisBars[1].am = 65535; // update bar graph max value for brake axis
    showSetupTextLine("Load Cell brake with HX711 detected");
    println("HX711 detected");
  }
  if (DACenabled) {
    showSetupTextLine("Analog FFB output via MCP4725 DAC detected");
    println("MCP4725 detected");
    sliderlabel[10] = "Min torque DAC [%]";
  }
  shifters[0] = new XYshifter(width/3.65f-16, height-posY-500, shScale_init);
  if (XYshifterEnabled) {
    //if (!LCenabled) wbuttons[3].enabled = false;
    if (bitRead(fwOpt, 5) == 1) { // for option "m" in proMicro we have replacement pins for these buttons
      wbuttons[1].enabled = true;
      wbuttons[2].enabled = true;
    } else { // for leonardo or micro, these buttons are unavailable when XY shifter is used
      if (bitRead(fwOpt, 2) == 0) { // if no hat switch on leonardo or micro, we don't have these 4 buttons
        for (int i=0; i<4; i++) {
          wbuttons[4+i].enabled = false;
        }
      }
    }
    for (int i=0; i<8; i++) {
      wbuttons[16+i].enabled = true; // enable last 8 buttons for XY shifter gears
    }
    showSetupTextLine("Analog XY H-shifter detected");
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
    updateLastShifterConfig(); // get shifter cal values into global variables
    showSetupTextLine(rb);
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
      wbuttons[4].enabled = true;
      wbuttons[5].enabled = true;
    } else {
      wbuttons[8].enabled = true; // else remaped to buttons 8,9
      wbuttons[9].enabled = true;
    }
    showSetupTextLine("Two extra buttons detected");
    println("Extra buttons detected");
  }
  if (bitRead(fwOpt2, 1) == 1) { // if bit1=1 - analog axis for FFB suported by firmware (option "x")
    showSetupTextLine("Analog axis for FFB enabled");
    println("Analog axis for FFB enabled");
  }
  if (bitRead(fwOpt2, 2) == 1) { // if bit2=1 - magnetic angle sensor AS5600 suported by firmware (option "w")
    if (bitRead(fwOpt, 5) == 1) { // if ProMicro
      if (bitRead(fwOpt, 2) == 1) { // if hat switch
        wbuttons[3].enabled = false;
      }
    }
    infobuttons[0].as = 1; // set magnetic encoder in info button
    noMagEnc = false;
    showSetupTextLine("AS5600 magnetic encoder detected");
    println("AS5600 detected");
  } else {
    noMagEnc = true;
    infobuttons[0].as = 0; // set optical quadrature encoder in info button
  }
  if (bitRead(fwOpt3, 3) == 1) { // if bit3=1 - tca9548 multiplexer is suported by firmware (option "u")
    TCA9548enabled = true;
    showSetupTextLine("TCA9548A i2C multiplexer detected");
    println("TCA9548A i2C multiplexer detected");
  }
  if (bitRead(fwOpt2, 3) == 1) { // if bit3=1 - hardware re-center is suported by firmware (option "c")
    showSetupTextLine("Hardware re-center button enabled");
    println("Re-center button enabled");
  }
  if (bitRead(fwOpt2, 6) == 1) { // if bit6=1 - no optical encoder is suported by firmware (option "d")
    noOptEnc = true;
    showSetupTextLine("No optical encoder supported");
    println("No optical encoder supported");
  } else {
    noOptEnc = false;
  }
  if (bitRead(fwOpt2, 5) == 0) { // if bit5=0, only 1 FFB axis is supported by firmware
    twoFFBaxis_enabled = false;
    ffbgraphs[0] = new FFBgraph(width, height-gbuffer/gskip, width, 1);  // FFB graph for X-axis
  } else { // if bit5=0, only 2 FFB axis are supported by firmware (split-view FFB monitor graphs)
    String out = "PWM";
    if (DACenabled) out = "DAC";
    showSetupTextLine("2 FFB axis and 2 channel " +out+ " output enabled");
    println("2 FFB axis detected");
    twoFFBaxis_enabled = true;
    wbuttons[7].enabled = false;
    gbuffer = 250; // half the graph data points
    ffbgraphs[0] = new FFBgraph(width, height-gbuffer/gskip, width, 1);  // FFB graph for X-axis
    ffbgraphs[1] = new FFBgraph(width, height-2*(gbuffer/gskip), width, 1);  // FFB graph for Y-axis
  }
  if (noOptEnc && noMagEnc) {
    infobuttons[0].as = -1; // deactivate both options in info button
    axisBars[2].yLimits[0].active = false; // disable cal limits on Z-axis
    axisBars[2].yLimits[1].active = false;
    axisBars[2].inactive = true; // inactivate Z-axis
  }
  if (fwVerNum >= 200) { // if =>fw-v200 - we have additional firmware options
    if (LCenabled) {
      axisBars[1].yLimits[0].active = false; // if load cell, inactivate manual cal for brake axis
      axisBars[1].yLimits[1].active = false;
    }
    if (bitRead(fwOpt2, 0) == 1) { // if bit0 of firmware options byte2 is HIGH, we have extra buttons and no clutch and handbrake
      if (!LCenabled) {  
        axisBars[3].yLimits[0].active = false; // only if no load cell, inactivate manual cal for clutch axis
        axisBars[3].yLimits[1].active = false;
      }
      axisBars[4].yLimits[0].active = false; // if extra buttons, inactivate manual cal for handbrake axis
      axisBars[4].yLimits[1].active = false;
    }
    if (bitRead(fwOpt, 7) == 1 && bitRead(fwOpt, 5) == 1) { // if options "f" and "m" clutch and hbrake axis are unavailable
      axisBars[3].yLimits[0].active = false;
      axisBars[3].yLimits[1].active = false;
      axisBars[4].yLimits[0].active = false;
      axisBars[4].yLimits[1].active = false;
    }
    if (bitRead(fwOpt2, 1) == 1) { // if bit1 of firmware options byte2 is HIGH, we have available FFB axis selector
      AFFBenabled = true;
    }
    if (bitRead(fwOpt, 0) == 0) {  // if bit0=0 - pedal autocalibration is disabled, then we have manual pedal calibration
      println("Manual pcal enabled");
      refreshPedalCalibration();
      updateLastPedalCalibration(rb);
      if (LCenabled) {
        axisBars[1].am = 65535; // update bar graph max value for brake axis to full 16bit resolution
      }
      showSetupTextLine("Manual calibration for pedals enabled");
      showSetupTextLine(rb);
    } else {
      showSetupTextLine("Automatic calibration for pedals enabled");
      println("Automatic pcal detected");
      buttons[13].active = false; // disable manual cal button if pedal auto calib firmware
    }
    if (bitRead(fwOpt, 1) == 1) { // if bit1=1, encoder z-index is supported by firmware
      buttons[14].active = true; // activate z-reset button
    } else {
      buttons[14].active = false; // inactivate z-reset button
    }
  }
  if (bitRead(fwOpt2, 7) == 1) { // if bit7 of firmware options byte2 is HIGH, EEPROM is not used in firmware
    showSetupTextLine("EEPROM is not used");
    println("EEPROM is not used");
  } else {
    showSetupTextLine("Using EEPROM to load/save settings");
    println("Using EEPROM to load/save settings");
  }
  if (fwVerNum >= 240) { // in firmware v240 we are in-activating unavailable buttons, some buttons are re-mapped (just visual fix)
    dActByp = false; // do not bypass button in-activation
    infobuttons[0].hiden = false; // un-hide the encoder type info button
  }
  wb = "V";
  executeWR();

  // create number box object for CPR adjustment
  //cp5 = new ControlP5(this);
  num1 = cp5.addNumberbox("CPR")
    .setSize(45, 18)
    .setPosition(PApplet.parseInt(width/3.65f) - 15 +  0.0f*60, height-posY+30)
    .setValue(lastCPR)
    .setRange(0, maxCPR)
    ;               
  makeEditable(num1);

  // define scrolable list objects
  b = Arrays.asList("fast pwm", "phase corr");
  c = Arrays.asList("pwm +-", "pwm+dir");
  c1 = Arrays.asList("pwm +-", "pwm+dir", "pwm0-50-100");
  c2_rcm = Arrays.asList("pwm +-", "pwm+dir", "pwm0-50-100", "rcm");
  c3_2pwm = Arrays.asList("2ch pwm +-", "2ch pwm+dir", "2ch pwm0-50-100", "2ch rcm");
  d = Arrays.asList("dac +-", "dac+dir");
  d_250 = Arrays.asList("dac +-", "dac+dir", "dac0-50-100");
  d_250_2ch = Arrays.asList("1ch dac +- (xFFB)", "2ch dac+dir", "2ch dac0-50-100");
  d2 = Arrays.asList("dac off", "dac on");
  e = Arrays.asList("default");
  String xm = "enc";
  if (noOptEnc && noMagEnc) xm = "pot"; // x-axis is on analog input, potentiometer
  fb = Arrays.asList("x-"+xm, "y-brk", "z-acc", "rx-clt", "ry-hbr");

  /* add a ScrollableList, by default it behaves like a DropdownList */
  profile = cp5.addScrollableList("profile")
    .setPosition(Xoffset+PApplet.parseInt(width/3.5f) - 15 + 14*60, height-posY+30+108)
    .setSize(66, 100)
    .setBarHeight(20)
    .setItemHeight(20)
    .addItems(e)
    ;
  profile.close();
  float[] def = new float[num_prfset];
  for (int i =0; i<num_sldr; i++) {
    def[i] = defParmFFB[i];
  }
  def[num_sldr] = PApplet.parseInt(effstatedef);
  def[num_sldr+1] = maxTorquedef;
  def[num_sldr+2] = CPRdef;
  def[num_sldr+3] = PApplet.parseInt(pwmstatedef);
  float[] empty = new float[num_prfset];
  for (int i =0; i<num_prfset; i++) {
    empty[i] = 0.0f;
  }
  String pdef = str(PApplet.parseInt(pdlParmDef[0])) + ' ' + str(PApplet.parseInt(pdlParmDef[1])) + ' ' + str(PApplet.parseInt(pdlParmDef[2])) + ' ' + str(PApplet.parseInt(pdlParmDef[3])) + ' ' + str(PApplet.parseInt(pdlParmDef[4])) + ' ' + str(PApplet.parseInt(pdlParmDef[5])) + ' ' + str(PApplet.parseInt(pdlParmDef[6])) + ' ' + str(PApplet.parseInt(pdlParmDef[7]));
  String sdef = str(xysParmDef[0]) + ' ' + str(xysParmDef[1]) + ' ' + str(xysParmDef[2]) + ' ' + str(xysParmDef[3]) + ' ' + str(xysParmDef[4]) + ' ' + str(xysParmDef[5]);
  String pempty = "0 0 0 0 0 0 0 0";
  String sempty = "0 0 0 0 0 0";
  profiles[0] = new Profile("default", def, pdef, sdef); // create default profile
  for (int i=1; i<num_profiles; i++) {
    profiles[i] = new Profile("slot"+str(i), empty, pempty, sempty); // create remaining empty profiles
    profile.addItem(profiles[i].name, empty);
  }
  if (!DACenabled) {
    /* add a ScrollableList, by default it behaves like a DropdownList */
    pwm_freq = cp5.addScrollableList("frequency")
      .setPosition(Xoffset+PApplet.parseInt(width/3.5f) - 15 + 564, height-posY+30+108)
      .setSize(56, 100)
      .setBarHeight(20)
      .setItemHeight(20)
      .addItems(a)
      //.setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST
      ;
    if (RCMenabled) { // fw-v210 has larger pwm frequency selection
      pwm_freq.removeItems(a);
      pwm_freq.addItems(a1);
    }
    pwm_type = cp5.addScrollableList("pwmtype")
      .setPosition(Xoffset+PApplet.parseInt(width/3.5f) - 15 + 402, height-posY+30+108)
      .setSize(66, 60)
      .setBarHeight(20)
      .setItemHeight(20)
      .addItems(b)
      //.setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST
      ;
    pwm_mode = cp5.addScrollableList("pwmmode")
      .setPosition(Xoffset+PApplet.parseInt(width/3.5f) - 15 + 479, height-posY+30+108)
      .setSize(74, 100)
      .setBarHeight(20)
      .setItemHeight(20)
      .addItems(c)
      //.setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST
      ;
    if (twoFFBaxis_enabled) { // fw-v240b has 2ch PWM+- mode instead of 1ch PWM+-
      pwm_mode.removeItems(c);
      pwm_mode.addItems(c3_2pwm);
      pwm_type.setPosition(Xoffset+PApplet.parseInt(width/3.5f) - 15 + 373, height-posY+30+108);
      pwm_mode.setPosition(Xoffset+PApplet.parseInt(width/3.5f) - 15 + 454, height-posY+30+108);
      pwm_mode.setSize(94, 100);
    } else {
      if (pwm0_50_100enabled) { // fw-v200 has pwm0.50.100 mode added
        pwm_mode.removeItems(c);
        pwm_mode.addItems(c1);
      } else if (RCMenabled) { // fw-v210 has RCM mode added
        pwm_mode.removeItems(c);
        pwm_mode.addItems(c2_rcm);
      }
    }
    //println(pwm0_50_100enabled+" "+RCMenabled);
    pwm_freq.close();
    pwm_type.close();
    pwm_mode.close();
    // update lists to these value
    pwm_freq.setValue(freqpwm);
    pwm_type.setValue(PApplet.parseInt(typepwm));
    pwm_mode.setValue(PApplet.parseInt(modepwm));
  } else { // if DAC enabled
    dac_mode = cp5.addScrollableList("dacmode")
      .setPosition(Xoffset+PApplet.parseInt(width/3.5f) - 15 + 9.4f*60, height-posY+30+108)
      .setSize(60, 100)
      .setBarHeight(20)
      .setItemHeight(20)
      .addItems(d)
      //.setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST
      ;
    buttons[9].t = " dac";
    buttons[9].d = "set and save dac settings to arduino (no restart required)";
    if (fwVerNum >= 250 && !twoFFBaxis_enabled) {
      dac_mode.removeItems(d);
      dac_mode.addItems(d_250);
      dac_mode.setSize(74, 100);
      dac_mode.setPosition(Xoffset+PApplet.parseInt(width/3.5f) - 20 + 9.2f*60, height-posY+30+108);
    } else if (fwVerNum >= 250 && twoFFBaxis_enabled) {
      dac_mode.removeItems(d);
      dac_mode.addItems(d_250_2ch);
      dac_mode.setSize(90, 100);
      dac_mode.setPosition(Xoffset+PApplet.parseInt(width/3.5f) - 20 + 9.0f*60, height-posY+30+108);
    }
    dac_mode.close();
    dac_mode.setValue(PApplet.parseInt(modedac));
    dac_out = cp5.addScrollableList("dacout")
      .setPosition(Xoffset+PApplet.parseInt(width/3.5f) - 5 + 7.6f*60, height-posY+30+108)
      .setSize(53, 100)
      .setBarHeight(20)
      .setItemHeight(20)
      .addItems(d2)
      //.setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST
      ;
    if (!twoFFBaxis_enabled) dac_out.setPosition(Xoffset+PApplet.parseInt(width/3.5f) + 4 + 7.6f*60, height-posY+30+108);
    dac_out.close();
    dac_out.setValue(PApplet.parseInt(enabledac));
  }
  if (bitRead(fwOpt, 5) == 1 && bitRead(fwOpt, 7) == 1) fb = Arrays.asList("x-"+xm, "y-brk", "z-acc"); // if "f" and "m" options, we don't have clutch and hbrake axis available
  if (AFFBenabled) { // if firmware supports analog FFB axis
    ffb_axis = cp5.addScrollableList("xFFBaxis")
      .setPosition(Xoffset+PApplet.parseInt(width/3.5f) - 19 - 0.85f*60, height-posY+5)
      .setSize(60, 120)
      .setBarHeight(20)
      .setItemHeight(20)
      .addItems(fb)
      //.setType(ScrollableList.DROPDOWN) // currently supported DROPDOWN and LIST
      ;
    ffb_axis.close();
    ffb_axis.setValue(PApplet.parseInt(xFFBAxisIndex));
  }
  loadProfiles(); // check if exists and load profiles from txt
  showSetupTextLine("Configuration done");
  ExportSetupTextLog();
  setupTextAlpha = setupTextInitAlpha;
}

public void draw() {
  background(bckBrgt);
  drawGUI(GUIresized());
}

public boolean GUIresized() {
  boolean r = false;
  if (widthprev != width) {
    widthprev = width;
    if (widthprev <= widthmin) widthprev = widthmin;
    wScaleX = PApplet.parseFloat(widthprev) / PApplet.parseFloat(xSize_init);
    r = true;
  }
  if (heightprev != height) {
    heightprev = height;
    if (heightprev <= heightmin) heightprev = heightmin;
    wScaleY = PApplet.parseFloat(heightprev) / PApplet.parseFloat(ySize_init);
    r = true;
  }
  if (r) {
    font_size = PApplet.parseInt(font_size_init*min(wScaleX, wScaleY));
    fontd = createFont("lucidasansunicode.ttf", PApplet.parseInt(0.8f*font_size), true);
  }
  textSize(font_size);
  text(str(widthprev) +"x"+ str(heightprev), font_size/3, 2*font_size);

  return r;
}

public void drawGUI(boolean resize) {
  draw_labels();
  for (int i = 0; i < axisBars.length; i++) {
    axisBars[i].update(i, resize);
    axisBars[i].show();
  }
  for (int j = 0; j < wbuttons.length; j++) {
    wbuttons[j].update();
    buttonValue = Button[j];
    wbuttons[j].show(j, resize);
  }
  for (int k = 0; k < hatsw.length; k++) {
    hatsw[k].update(resize);
    hatsw[k].show();
    hatsw[k].showArrow();
  }
  if (!twoFFBaxis_enabled) {
    // my simple animated wheel gfx
    wheels[0].updateWheel(axisBars[xFFBAxisIndex].axisVal*wParmFFB[0]/2, resize); // update the angle in units of degrees
    wheels[0].showWheelDeg(); // show the angle in units of degrees in a nice number format
    //wheels[0].showWheel();
    if (!buttonpressed[7]) {
      if (resize) {
        sprite[0].setXY(0.123f*widthprev, 0.223f*heightprev);
        sprite[0].setScale(min(wScaleX, wScaleY));
      }
      S4P.updateSprites(1);  // animated wheel from png sprite
      sprite[0].setRot(axisBars[xFFBAxisIndex].axisVal*wParmFFB[0]/2/180*PI); // set the angle of the sprite in units of radians
      S4P.drawSprites();
    }
  } else {
    wheels[0].updateJoy(axisBars[xFFBAxisIndex].axisVal, axisBars[1].axisVal, resize); // xFFB on X-axis, yFFB on Y-axis
    wheels[0].showJoy();
    wheels[0].showJoyPos();
  }
  for (int j = 0; j < infobuttons.length; j++) {
    infobuttons[j].update(resize);
    infobuttons[j].show();
  }
  for (int k = 0; k < buttons.length; k++) {
    buttons[k].update(k, resize);
    buttons[k].show();
  }
  for (int l = 0; l < infos.length; l++) {
    infos[l].update(l, resize);
    infos[l].show(enableinfo);
  }
  ffbgraphs[0].updateSize(resize);
  if (twoFFBaxis_enabled)ffbgraphs[1].updateSize(resize);
  if (buttonpressed[7]) {
    int gmult = 1;
    if (twoFFBaxis_enabled) gmult = 2;
    for (int i=0; i<ceil(gbuffer / frameRate * gmult); i++) {
      String temprb = readString();
      if (temprb != "empty") {
        if (twoFFBaxis_enabled) {
          int[] val = PApplet.parseInt(split(temprb, ' '));
          if (val.length > 1) {
            ffbx = val[0]; // X-axis FFB data
            ffby = val[1]; // Y-axis FFB data
            ffbgraphs[0].update(str(ffbx));
            ffbgraphs[1].update(str(ffby));
          }
        } else {
          ffbgraphs[0].update(temprb); // X-axis FFB data
        }
      }
    }
    ffbgraphs[0].show(0); // X-axis FFB data
    if (twoFFBaxis_enabled) ffbgraphs[1].show(1); // Y-axis FFB data
  } else {
    if (fbmnstp) { // read remaining serial read buffer content
      String temprb = "";
      while (readString() != "empty") {
        temprb = rb;
      }
      rb = temprb; // restore read buffer
      fbmnstp = false;
    }
  }
  if (buttonpressed[7]) {
    dialogs[0].update("WB: "+ wb + ", RB: " + fbmnstring + "; " + str(rbt_ms) + "ms", resize);
  } else {
    dialogs[0].update("WB: "+ wb + ", RB: " + rb + "; " + str(rbt_ms) + "ms", resize);
  }
  dialogs[0].show();
  text(round(frameRate)+" fps", font_size/3, font_size);
  if (CPRlimit) {
    num1.setValue(maxAllowedCPR(wParmFFBprev[0]));
    CPRlimit = false;
  }
  if (!buttonpressed[7]) { // only available if ffb monitor is not enabled
    if (XYshifterEnabled) {
      shifters[0].update(resize);
      buttons[11].active = true; // re-enable only if firmware supports it
      buttons[12].active = true;
    }
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
  }
  if (noOptEnc && noMagEnc) buttons[0].active = false; // disable center button if we have no digital encoders
  if (twoFFBaxis_enabled) buttons[0].d = "set x to 0%";
  if (twoFFBaxis_enabled && TCA9548enabled && !noMagEnc) {
    buttons[0].d = "set x,y to 0%";
    axisBars[1].am = 65535;
  }
  if (bitRead(fwOpt, 1) == 1) buttons[14].active = true; // re-enable z button if supported by firmware
  if (showSetupText) {
    animateSetupTextBuffer(frameCount);
  }
  updateCP5_elements(resize);
  reSizeGUI = false;
}

public void draw_labels() {
  String labelStr;
  fill(255);
  for (int j = 0; j < num_sldr; j++) { // FFB slider values
    labelStr = str(slider_value[j]);
    if (j == 0 || j == 11) { // only for rotation and brake pressure
      labelStr=labelStr.substring(0, labelStr.length()-2); // do not show decimal places
      if (!LCenabled && j == 11) labelStr = str(slider_value[j]-128).substring(0, (str(slider_value[j]-128)).length()-2); // shift the value such that center iz at zero
    } else if (j == 10) { // only for min PWM
      if (slider_value[j] < 10.0f ) {
        labelStr=labelStr.substring(0, 3);
      } else {
        labelStr=labelStr.substring(0, 4);
      }
    } else {
      labelStr = str(ceil(slider_value[j]*100)); // fix, show 100% instead of 1.0%
    }
    //textMode(TOP);
    //text(sliderlabel[j], sldXoff+width/2-slider_width/3, slider_height/2*(1+j)); // slider label
    //text(labelStr, sldXoff+width/2+slider_width+20, slider_height/2*(1+j)); // slider value
    text(sliderlabel[j], PApplet.parseInt(widthprev/cp5xoff)-textWidth(sliderlabel[10])-font_size, PApplet.parseInt((cp5yoff + j*3/cp5sdy)*heightprev)+0.8f*font_size); // left aligned according to the "min Torque PWM" slider, index 10
    text(labelStr, PApplet.parseInt(widthprev/cp5xoff + widthprev/cp5sx)+font_size, PApplet.parseInt((cp5yoff + j*3/cp5sdy)*heightprev)+0.8f*font_size);
  }
  if (AFFBenabled) {
    text("xFFB-axis", xPosAxis(0), heightprev-posY+2); // xFFB axis selector label
  }
  // about info display
  pushMatrix();
  translate(widthprev/3.5f, heightprev - (0.64f*axisHeight));
  text("Arduino FFB Wheel, HEX " + FullfwVerStr.substring(3, FullfwVerStr.length()), 0, 0);
  text("Control Panel " + cpVer, 0, 1.6f*font_size);
  text("Miloš Ranković 2018-2025 ©", 0, 3.2f*font_size);
  text("ranenbg@gmail.com, paypal@ranenbg.com", 0, 4.8f*font_size);
  popMatrix();

  int tn = 10;
  float tl = 5;
  float sl = 4;
  tl *= wScaleY;

  for (int i=0; i<cp5sdr.length; i++) {
    float x = widthprev/cp5xoff;
    float y = heightprev*(cp5yoff + i*3/cp5sdy);
    float sx = widthprev/cp5sx-sl;
    float sy = heightprev/cp5sy;
    float dx = sx / tn;
    stroke(255);
    for (int j=0; j<=tn; j++) { // ticks below slider
      int k = 1;
      if (j == tn) k = 0;
      line(k*sl/2+x+j*dx, y+sy, k*sl/2+x+j*dx, y+sy+tl);
    }
  }
}

public void writeString(String input) {
  myPort.write(input+PApplet.parseChar(13)); // add CR - carage return as output line terminator
}

public String readString() {
  if (myPort.available() > 0) { // if serial port data is available
    rb = myPort.readStringUntil(PApplet.parseChar(10));  // read till terminator char - LF (line feed) and store it in rb
    if (rb != null) { // if there is something in rb
      rb = rb.substring(0, (rb.indexOf(PApplet.parseChar(13)))); // remove last 2 chars - Arduino sends both CR+LF, char(13)+char(10)
    } else {
      rb = "empty";
    }
  } else {
    rb = "empty";
  }
  return rb;
}

public void executeWR() {
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

public void refreshWheelParm() {
  myPort.clear();
  writeString("U");
  if (UpdateWparms(readParmUntillEmpty())) {
    showSetupTextLine("Firmware settings detected");
    showSetupTextLine(rb);
    println("Firmware settings detected");
  } else {
    showSetupTextLine("Incompatible firmware settings");
    println("Incompatible firmware settings");
  }
  if (bitRead(effstate, 4) == 1) { // if FFB mon is running
    showSetupTextLine("De-activating FFB monitor");
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
  print(PApplet.parseInt(effstate));
  //print(" ");
  //print("read: " + int(xFFBAxisIndex));
  print(" ");
  print(maxTorque);
  print(" ");
  print(lastCPR);
  print(" ");
  print(PApplet.parseInt(pwmstate));
  println("; " + str(rbt_ms) + "ms");
}

public String readParmUntillEmpty() { // reads serial buffer untill empty and returns a string longer than 11 chars (non-FFB monitor data)
  String buffer = "";
  String temp = "";
  rbt_ms = 0;
  for (int i=0; i<999; i++) {
    temp = readString();
    if (temp != "empty") {
      if (temp.length() > 11) {
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

public boolean UpdateWparms(String input) { // decode wheel parameters into FFB, CPR and PWM settings and returns false if format is incorrect
  boolean correct;
  float[] temp = PApplet.parseFloat(split(input, ' '));
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
          wParmFFB[i] = temp[i] / 100.0f;
        } else {
          wParmFFB[i] = temp[i];
        }
      } else if (i == temp.length-4) { // this value is effstate in binary form
        effstate = PApplet.parseByte(temp[i]);
      } else if (i == temp.length-3) { // this value is max torque or PWM resolution per channel
        maxTorque = PApplet.parseInt(temp[i]);
      } else if (i == temp.length-2) { // this value is encoder CPR
        lastCPR = PApplet.parseInt(temp[i]);
      } else if (i == temp.length-1) { // last value is pwmstate in binary form
        pwmstate = PApplet.parseByte(temp[i]);
      }
    }
  }
  wParmFFB[10] = wParmFFB[10] / PApplet.parseFloat(maxTorque) * 100.0f; // recalculate to percentage min pwm value
  return correct;
}

public void readFwVersion() { // reads firmware version from String, checks and updates all firmware options
  myPort.clear();
  println("Reading firmware version");
  wb = "V";
  executeWR();
  FullfwVerStr = rb;
  showSetupTextLine("HEX version: " + FullfwVerStr);
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
  fwOpt3 = decodeFwOpts3(fwOpts); // decode fw options into 2nd byte
  String fwVerNumStr = str(fwVerNum);
  int len = fwVerNumStr.length();
  if (fwVerNum < 250) { // for all firmware prior to fw-v250
    if (fwVerNumStr.charAt(len-1) == '0' || fwVerNumStr.charAt(len-1) == '1') { // if last number is 0 or 1
      LCenabled = false; // we don't have load cell or dac
      DACenabled = false;
    }
    if (fwVerNumStr.charAt(len-1) == '1') { // if last number is 1
      BBenabled = true;
    }
    if (fwVerNumStr.charAt(len-1) == '2') { // if last number is 2
      BBenabled = true; // we have button box
      LCenabled = true; // we have load cell
    }
    if (fwVerNumStr.charAt(len-1) == '3') { // if last number is 3
      LCenabled = true; // we have load cell and dac
      DACenabled = true;
    }
  } else { // for fw-v250 and onward I have changed how we interpret firmware version - load cell, button box and dac are firmware options now
    if (bitRead(fwOpt3, 0) == 1) { // if bit0 is HIGH (option "n" - button box)
      BBenabled = true;
    } else {
      BBenabled = false;
    }
    if (bitRead(fwOpt3, 1) == 1) { // if bit1 is HIGH (option "l" - load cell)
      LCenabled = true;
    } else {
      LCenabled = false;
    }
    if (bitRead(fwOpt3, 2) == 1) { // if bit2 is HIGH (option "g" - external dac)
      DACenabled = true;
    } else {
      DACenabled = false;
    }
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
public byte decodeFwOpts (String fopt) {
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
public byte decodeFwOpts2 (String fopt) {
  byte temp = 0;
  if (fopt != "0") { // has firmware any options
    for (int j=0; j<fopt.length(); j++) {
      if (fopt.charAt(j) == 'e') temp = bitWrite(temp, 0, true); // b0=1, extra buttons enabled
      if (fopt.charAt(j) == 'x') temp = bitWrite(temp, 1, true); // b1=1, analog FFB axis enabled
      if (fopt.charAt(j) == 'w') temp = bitWrite(temp, 2, true); // b2=1, AS5600 enabled
      if (fopt.charAt(j) == 'c') temp = bitWrite(temp, 3, true); // b3=1, center button enabled
      if (fopt.charAt(j) == 'r') temp = bitWrite(temp, 4, true); // b4=1, 24 buttons (via 3x8bit SR) enabled
      if (fopt.charAt(j) == 'b') temp = bitWrite(temp, 5, true); // b5=1, 2 FFB axis (2nd PWM output) enabled
      if (fopt.charAt(j) == 'd') temp = bitWrite(temp, 6, true); // b6=1, no optical encoder
      if (fopt.charAt(j) == 'p') temp = bitWrite(temp, 7, true); // b7=1, no EEPROM
    }
  }
  //println("fw opt2: 0x" + hex(temp));
  return temp;
}
// decode 2nd byte of firmware options
public byte decodeFwOpts3 (String fopt) {
  byte temp = 0;
  if (fopt != "0") { // has firmware any options
    for (int j=0; j<fopt.length(); j++) {
      if (fopt.charAt(j) == 'n') temp = bitWrite(temp, 0, true); // b0=0, nano button box enabled
      if (fopt.charAt(j) == 'l') temp = bitWrite(temp, 1, true); // b1=1, load cell enabled
      if (fopt.charAt(j) == 'g') temp = bitWrite(temp, 2, true); // b2=1, external dac enabled
      if (fopt.charAt(j) == 'u') temp = bitWrite(temp, 3, true); // b3=1, TCA9548 enabled (two AS5600 encoders)
    }
  }
  //println("fw opt3: 0x" + hex(temp));
  return temp;
}

public void mousePressed() {
  if (mouseButton == LEFT) {
    for (int i=0; i < wParmFFB.length; i++) {
      wParmFFBprev[i] = wParmFFB[i];
    }
  }
}

public void mouseReleased() {
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
    profile.setLabel(profiles[cur_profile].name);
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
    shifterLastConfig[5] = shifters[0].sConfig;
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
    shifterLastConfig[5] = shifters[0].sConfig;
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
    shifterLastConfig[5] = shifters[0].sConfig;
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
    shifterLastConfig[5] = shifters[0].sConfig;
    wb = shCommand[5] + str(shifters[0].sConfig);
    executeWR();
  }
  if (controlb[13]) { // if we pressed manual cal button
    ActuateButton(13);
    int im = 1;
    if (noOptEnc && noMagEnc) {
      im = 0;
    }
    if (buttonpressed[13]) {
      for (int i=im; i<=4; i++) axisBars[i].yLimitsVisible = true;
      if (!noMagEnc && TCA9548enabled && twoFFBaxis_enabled) { // we are using dual AS5600
        axisBars[1].yLimitsVisible = false; // inactivate cal limits on Y-axis
      }
    } else {
      for (int i=im; i<=4; i++) axisBars[i].yLimitsVisible = false;
    }
  }
  if (controlb[14]) { // if we pressed z reset button
    wb = "Z";
    executeWR();
  }
  if (controlb[ctrl_btn+0]) { // if we pressed shifter calibration slider a
    shifterLastConfig[0] = PApplet.parseInt(shifters[0].sCal[0]);
    wb = shCommand[0] + str(PApplet.parseInt(shifters[0].sCal[0]));
    executeWR();
  }
  if (controlb[ctrl_btn+1]) { // if we pressed shifter calibration slider b
    shifterLastConfig[1] = PApplet.parseInt(shifters[0].sCal[1]);
    wb = shCommand[1] + str(PApplet.parseInt(shifters[0].sCal[1]));
    executeWR();
  }
  if (controlb[ctrl_btn+2]) { // if we pressed shifter calibration slider c
    shifterLastConfig[2] = PApplet.parseInt(shifters[0].sCal[2]);
    wb = shCommand[2] + str(PApplet.parseInt(shifters[0].sCal[2]));
    executeWR();
  }
  if (controlb[ctrl_btn+3]) { // if we pressed shifter calibration slider d
    shifterLastConfig[3] = PApplet.parseInt(shifters[0].sCal[3]);
    wb = shCommand[3] + str(PApplet.parseInt(shifters[0].sCal[3]));
    executeWR();
  }
  if (controlb[ctrl_btn+4]) { // if we pressed shifter calibration slider e
    shifterLastConfig[4] = PApplet.parseInt(shifters[0].sCal[4]);
    wb = shCommand[4] + str(PApplet.parseInt(shifters[0].sCal[4]));
    executeWR();
  }
  if (controlb[ctrl_btn+ctrl_sh_btn+0]) { // if we pressed pedal calibration slider c on X-axis
    float sf = axisBars[2].am / axisBars[0].am; // we need to rescale cal values to the ones of Z-axis
    pdlMinParm[1] = PApplet.parseInt(axisBars[0].pCal[0]*sf);
    wb = pdlCommand[2] + str(PApplet.parseInt(axisBars[0].pCal[0]*sf));
    executeWR();
    if (twoFFBaxis_enabled) {
      if (noOptEnc && noMagEnc) axisBars[2].yLimits[0].y = axisBars[0].yLimits[0].y; // copy x-axis cal limits to z-axis cal limits
    }
  }
  if (controlb[ctrl_btn+ctrl_sh_btn+1]) { // if we pressed pedal calibration slider d on X-axis
    float sf = axisBars[2].am / axisBars[0].am; // we need to rescale cal values to the ones of Z-axis
    pdlMaxParm[1] = PApplet.parseInt(axisBars[0].pCal[1]*sf);
    wb = pdlCommand[3] + str(PApplet.parseInt(axisBars[0].pCal[1]*sf));
    executeWR();
    if (twoFFBaxis_enabled) {
      if (noOptEnc && noMagEnc) axisBars[2].yLimits[1].y = axisBars[0].yLimits[1].y;  // copy x-axis cal limits to z-axis cal limits
    }
  }
  if (controlb[ctrl_btn+ctrl_sh_btn+2]) { // if we pressed pedal calibration slider a
    pdlMinParm[0] = PApplet.parseInt(axisBars[1].pCal[0]);
    wb = pdlCommand[0] + str(PApplet.parseInt(axisBars[1].pCal[0]));
    executeWR();
  }
  if (controlb[ctrl_btn+ctrl_sh_btn+3]) { // if we pressed pedal calibration slider b
    pdlMaxParm[0] = PApplet.parseInt(axisBars[1].pCal[1]);
    wb = pdlCommand[1] + str(PApplet.parseInt(axisBars[1].pCal[1]));
    executeWR();
  }
  if (controlb[ctrl_btn+ctrl_sh_btn+4]) { // if we pressed pedal calibration slider c on Z-axis
    pdlMinParm[1] = PApplet.parseInt(axisBars[2].pCal[0]);
    wb = pdlCommand[2] + str(PApplet.parseInt(axisBars[2].pCal[0]));
    executeWR();
  }
  if (controlb[ctrl_btn+ctrl_sh_btn+5]) { // if we pressed pedal calibration slider d on Z-axis
    pdlMaxParm[1] = PApplet.parseInt(axisBars[2].pCal[1]);
    wb = pdlCommand[3] + str(PApplet.parseInt(axisBars[2].pCal[1]));
    executeWR();
  }
  if (controlb[ctrl_btn+ctrl_sh_btn+6]) { // if we pressed pedal calibration slider e
    pdlMinParm[2] = PApplet.parseInt(axisBars[3].pCal[0]);
    wb = pdlCommand[4] + str(PApplet.parseInt(axisBars[3].pCal[0]));
    executeWR();
  }
  if (controlb[ctrl_btn+ctrl_sh_btn+7]) { // if we pressed pedal calibration slider f
    pdlMaxParm[2] = PApplet.parseInt(axisBars[3].pCal[1]);
    wb = pdlCommand[5] + str(PApplet.parseInt(axisBars[3].pCal[1]));
    executeWR();
  }
  if (controlb[ctrl_btn+ctrl_sh_btn+8]) { // if we pressed pedal calibration slider g
    pdlMinParm[3] = PApplet.parseInt(axisBars[4].pCal[0]);
    wb = pdlCommand[6] + str(PApplet.parseInt(axisBars[4].pCal[0]));
    executeWR();
  }
  if (controlb[ctrl_btn+ctrl_sh_btn+9]) { // if we pressed pedal calibration slider h
    pdlMaxParm[3] = PApplet.parseInt(axisBars[4].pCal[1]);
    wb = pdlCommand[7] + str(PApplet.parseInt(axisBars[4].pCal[1]));
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
          wb = command[i] + str(PApplet.parseInt(round(wParmFFB[i]*100.0f)));
        } else if (i == 0 || i == 11) {
          wb = command[i] + str(PApplet.parseInt(round(wParmFFB[i])));
        } else if (i == 10) {
          wb = command[i] + str(PApplet.parseInt(round(wParmFFB[i]*10.0f)));
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

public void keyReleased() {
  if (key == 'r') {
    readString();
    wb = "none";
    println("RB: " + rb);
  }
  if (key == 'c') {
    if (wheelMoved) { // only update if not centered already
      wb = "C";
      executeWR();
      prevaxis = gpad.getSlider("Xaxis").getValue();
      wheelMoved = false;
    }
  }
  if (key == 'u') {
    wb = "U";
    executeWR();
  }
  if (key == 'v') {
    wb = "V";
    executeWR();
  }
  if (key == 's') {
    wb = "S";
    executeWR();
  }
  if (key == 'b') {
    wb = "R";
    executeWR();
  }
  if (key == 'd') {
    setDefaults();
  }
  if (key == '+') {
    changeRot(1.0f);
    executeWR();
    wParmFFBprev[0]=wParmFFB[0];
  }
  if (key == '-') {
    changeRot(-1.0f);
    executeWR();
    wParmFFBprev[0]=wParmFFB[0];
  }
  if (key == 'i') {
    if (!enableinfo) {
      enableinfo = true;
    } else {
      enableinfo = false;
    }
  }
  if (key == 'p') {
    wb = "P";
    executeWR();
  }
  if (key == 'z') {
    wb = "Z";
    executeWR();
  }
  buttonpressed[0] = false;
  buttonpressed[1] = false;
  buttonpressed[2] = false;
  buttonpressed[14] = false;
}

public void keyPressed() {
  if (key == 'c') buttonpressed[0] = true;
  if (key == 'd') buttonpressed[1] = true;
  if (key == 'p') buttonpressed[2] = true;
  if (key == 'z') buttonpressed[14] = true;

  for (int i=0; i < wParmFFB.length; i++) {
    wParmFFBprev[i] = wParmFFB[i];
  }
}

public void setDefaults() {
  for (int i=0; i < wParmFFB.length; i++) {
    if (wParmFFB[i] != defParmFFB[i]) { // only if parm different than default
      if (i != 0 && i != 10 && i != 11) {
        wb = command[i] + str(PApplet.parseInt(round(defParmFFB[i]*100.0f)));
      } else if (i == 0 || i == 11) {
        wb = command[i] + str(PApplet.parseInt(round(defParmFFB[i])));
      } else if (i == 10) {
        wb = command[i] + str(PApplet.parseInt(defParmFFB[i]*10.0f));
      }
      executeWR(); // send default parm to wheel and read buffer from wheel
      wParmFFB[i]=defParmFFB[i]; // update changed parm
      wParmFFBprev[i]=wParmFFB[i]; // update to latest parm
      setSliderFromParm(i); // update i-th slider with new parm
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
  if (bitRead(fwOpt, 0) == 0) {  // if firmware supports manual pedal calib - load default values and send to arduino
    for (int i=0; i<pdlMinParm.length; i++) {
      if (pdlMinParm[i] != pdlParmDef[2*i]) { // only update if default pedal calibration value is different than current GUI value
        pdlMinParm[i] = pdlParmDef[2*i];
        wb = pdlCommand[2*i] + PApplet.parseInt(pdlMinParm[i]); // update write buffer
        executeWR(); // send command to arduino
      }
      if (pdlMaxParm[i] != pdlParmDef[2*i+1]) {  // only update if default pedal calibration value is different than current GUI value
        pdlMaxParm[i] = pdlParmDef[2*i+1];
        wb = pdlCommand[2*i+1] + PApplet.parseInt(pdlMaxParm[i]); // update write buffer
        executeWR(); // send command to arduino
      }
      axisBars[i+1].updateCal(pdlMinParm[i], pdlMaxParm[i]); // update GUI pedal calibration values to default ones
    }
    if (twoFFBaxis_enabled) {
      if (noOptEnc && noMagEnc) {
        float sf = axisBars[0].am / axisBars[2].am;
        axisBars[0].updateCal(pdlMinParm[1]*sf, pdlMaxParm[1]*sf); // update x-axis cal limits from z-axis
      }
    }
  }
  if (XYshifterEnabled) { // if firmware supports shifter - load its default values
    for (int i=0; i<xysParmDef.length; i++) {
      if (shifterLastConfig[i] != xysParmDef[i]) {  // only update if particular default shifter calibration value is different than current GUI value
        shifterLastConfig[i] = xysParmDef[i];
        wb = shCommand[i] + xysParmDef[i];
        executeWR();
      }
    }
    shifters[0].updateCal(str(xysParmDef[0])+" "+str(xysParmDef[1])+" "+str(xysParmDef[2])+" "+str(xysParmDef[3])+" "+str(xysParmDef[4])+" "+str(xysParmDef[5])); // update state of GUI shifter calibration sliders
    decodeShifterConfig(shifterLastConfig[5]); // update state of GUI shifter configuration buttons to latest ones
  }
}

public void setFromProfile() {
  for (int i=0; i < wParmFFB.length; i++) {
    if (wParmFFB[i] != wParmFFBprev[i]) { // only if parm different than previous
      if (i != 0 && i != 10 && i != 11) {
        wb = command[i] + str(PApplet.parseInt(round(wParmFFB[i]*100.0f)));
      } else if (i == 0 || i == 11) {
        wb = command[i] + str(PApplet.parseInt(round(wParmFFB[i])));
      } else if (i == 10) {
        wb = command[i] + str(PApplet.parseInt(wParmFFB[i]*10.0f));
      }
      executeWR(); // send default parm to wheel and read buffer from wheel
      wParmFFBprev[i]=wParmFFB[i]; // update to latest parm
      setSliderFromParm(i); // update i-th slider with new parm
    }
  }
  if (effstate != effstateprev) { // only if effstate different than previous
    readEffstate(); // re-configure swithces to new values
    updateEffstate(); // update new values of effstate
    sendEffstate(); // send new values to arduino
    effstateprev = effstate;
    if (AFFBenabled) {
      ffb_axis.setValue(PApplet.parseInt(xFFBAxisIndex)); // update analog FFB axis index if firmware supports it
    }
  }
  if (curCPR != lastCPR) {
    num1.setValue(curCPR); // update the numberbox with the new value and send to Arduino
  }
  if (bitRead(fwOpt, 0) == 0) {  // if firmware supports manual pedal calib - load values from profile and send to arduino
    boolean override = true; // change this to false and uncomment part below to allow user to select if he wants to override calibration
    int result;
    if (profiles[cur_profile].checkPedalCfg()) { // check if profile values are different than curent ones, notify and ask the user if he wants to override
      result = showConfirmDialog(frame, "This profile contains pedal calibration\nthat differs from current settings.\nOverwrite?");
      if (result == YES_OPTION) override = true;
    }
    if (override) {
      println("pedal calibration loaded from profile" + str(cur_profile));
      for (int i=0; i<pdlMinParm.length; i++) {
        if (pdlMinParm[i] != profiles[cur_profile].pMin[i]) { // only update if particular pedal calibration value from profile is different than current GUI value
          pdlMinParm[i] = profiles[cur_profile].pMin[i];
          wb = pdlCommand[2*i] + PApplet.parseInt(pdlMinParm[i]); // update write buffer
          executeWR(); // send command to arduino
        }
        if (pdlMaxParm[i] != profiles[cur_profile].pMax[i]) {
          pdlMaxParm[i] = profiles[cur_profile].pMax[i];
          wb = pdlCommand[2*i+1] + PApplet.parseInt(pdlMaxParm[i]); // update write buffer
          executeWR(); // send command to arduino
        }
        axisBars[i+1].updateCal(pdlMinParm[i], pdlMaxParm[i]); // update GUI pedal calibration values to new ones from profile
      }
      if (twoFFBaxis_enabled) {
        if (noOptEnc && noMagEnc) {
          float sf = axisBars[0].am / axisBars[2].am;
          axisBars[0].updateCal(pdlMinParm[1]*sf, pdlMaxParm[1]*sf); // update x-axis cal limits from z-axis
        }
      }
    }
  }
  if (XYshifterEnabled) { // if firmware supports shifter - load values from profile and send to arduino
    boolean override = true; // change this to false and uncomment part below to allow user to select if he wants to override calibration
    int result;
    if (profiles[cur_profile].checkShifterCfg()) {  // check if profile values are different than curent ones, notify and ask the user if he wants to override
      result = showConfirmDialog(frame, "This profile contains shifter calibration\nthat differs from current settings.\nOverwrite?");
      if (result == YES_OPTION) override = true;
    }
    if (override) {
      println("shifter calibration loaded from profile" + str(cur_profile));
      for (int i=0; i<shifterLastConfig.length; i++) {
        if (shifterLastConfig[i] != profiles[cur_profile].xyshCfg[i]) { // only update if particular shifter setting from profile is different than current GUI value
          shifterLastConfig[i] = profiles[cur_profile].xyshCfg[i]; // update GUI values from profile settings
          wb = shCommand[i] + shifterLastConfig[i]; // update write buffer
          executeWR(); // send command to arduino
        }
      }
      shifters[0].updateCal(str(shifterLastConfig[0])+" "+str(shifterLastConfig[1])+" "+str(shifterLastConfig[2])+" "+str(shifterLastConfig[3])+" "+str(shifterLastConfig[4])+" "+str(shifterLastConfig[5]));
    }
    decodeShifterConfig(shifterLastConfig[5]); // update state of GUI shifter configuration buttons to latest ones
  }
}

public void setSliderFromParm(int s) {
  if (s != 0 && s != 10 && s != 11) { // all FFB sliders
    //sdr[s].setValue(wParmFFB[s]/slider_max);
    cp5sdr[s].setValue(wParmFFB[s]/slider_max);
  } else if (s == 0) { // rotation deg
    //sdr[s].setValue(wParmFFB[s]/deg_max);
    cp5sdr[s].setValue(wParmFFB[s]/deg_max);
  } else if (s == 10) { // min torque PWM
    //sdr[s].setValue(wParmFFB[s]/minPWM_max);
    cp5sdr[s].setValue(wParmFFB[s]/minPWM_max);
  } else if (s == 11) {  // max brake pressure
    //sdr[s].setValue(wParmFFB[s]/brake_max);
    cp5sdr[s].setValue(wParmFFB[s]/brake_max);
  }
  slider_value[s] = wParmFFB[s]; // update slider value string
}

// controlEvent(CallbackEvent) is called whenever a callback 
// has been triggered. controlEvent(CallbackEvent) is detected by 
// controlP5 automatically.
public void controlEvent(CallbackEvent theEvent) {
  if (theEvent == null) {
    println("controlEvent received a null CallbackEvent. Ignoring.");
    return;
  }
  int sdrID = -1;
  for (int i=0; i<cp5sdr.length; i++) {
    if (theEvent.getController().equals(cp5sdr[i]) && theEvent.getAction() == ControlP5.ACTION_BROADCAST) sdrID = i;
  }
  if (sdrID != -1) {
    if (sdrID != 0 && sdrID != 10 && sdrID != 11) { // for all sliders except for deg of rotation, min torque and brake pressure
      slider_value[sdrID] = cp5sdr[sdrID].getValue()*slider_max;
      wParmFFB [sdrID] = slider_value[sdrID];
    } else if (sdrID == 0) { // for deg of rotation slider 0 and min torque slider 10
      slider_value[sdrID] = round(cp5sdr[sdrID].getValue()*deg_max);
      if (slider_value[sdrID] < deg_min) {
        slider_value[sdrID] = deg_min;
      }
      if (slider_value[sdrID] >= maxAllowedDeg(lastCPR)) {
        slider_value[sdrID] = maxAllowedDeg(lastCPR);
        cp5sdr[sdrID].setValue(maxAllowedDeg(lastCPR)/deg_max);
      }
      wParmFFB [sdrID] = slider_value[0];
    } else if (sdrID == 10) {
      slider_value[sdrID] = cp5sdr[sdrID].getValue()*minPWM_max;
      if (slider_value[sdrID] > minPWM_max) {
        slider_value[sdrID] = minPWM_max;
      }
      wParmFFB [sdrID] = slider_value[sdrID];
    } else if (sdrID == 11) {
      slider_value[sdrID] = round(cp5sdr[sdrID].getValue()*brake_max);
      if (slider_value[sdrID] < brake_min) {
        slider_value[sdrID] = brake_min;
      }
      if (slider_value[sdrID] > brake_max) {
        slider_value[sdrID] = brake_max;
      }
      wParmFFB [sdrID] = slider_value[sdrID];
    }
  }
}

/*public void handleSliderEvents(GValueControl slider, GEvent event) { // old red GP4 sliders, replaced by blue CP5 ones
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
 }*/

public void changeRot(float step) {
  if (step >= 0.0f) {
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
  //sdr[0].setValue(wParmFFB[0]/deg_max);
  cp5sdr[0].setValue(wParmFFB[0]/deg_max);
  slider_value[0] = wParmFFB[0];
  wb = command[0] + str(PApplet.parseInt(wParmFFB[0]));
}

public void ActuateButton(int id) { // turns specific button on/off
  if (!buttonpressed[id]) {
    buttonpressed[id] = true;
  } else {
    buttonpressed[id] = false;
    if (id == 7) { // if ffb monitor button de-activated
      fbmnstp = true;
    }
  }
}

public int bitRead(byte b, int bitPos) { // found this on net, now it is the same as bitRead in arduino
  int x = b & (1 << bitPos);
  return x == 0 ? 0 : 1;
}

public byte bitWrite(byte register, int bitPos, boolean value) { // arduino's analog of bitWrite
  if (value) { // turn bit on at bitPos
    register |= 1 << bitPos;
  } else { // turn bit off at bitPos
    register &= ~(1 << bitPos);
  }
  return register;
}

public void readEffstate () { // decode effstate byte
  for (int j=0; j<=4; j++) {
    buttonpressed[j+3] = PApplet.parseBoolean(bitRead(effstate, j)); // decode desktop user effect switches
  }
  for (int j=5; j<=7; j++) {
    xFFBAxisIndex = bitWrite(PApplet.parseByte(xFFBAxisIndex), j-5, PApplet.parseBoolean(bitRead(effstate, j))); // decode FFB axis index
  }
  effstateprev = effstate;
}

public void sendEffstate () { // send effstate byte to arduino
  wb = "E " + str(PApplet.parseInt(effstate)); // set command for switches
  executeWR(); // send switch values to arduino and read buffer from wheel
}

public void updateEffstate () { // code settings into effstate byte
  for (int k=0; k <=4; k++) { //needs to be k<=4 here
    effstate = bitWrite(effstate, k, buttonpressed[k+3]); // code control switches
  }
  for (int k=5; k <=7; k++) {
    effstate = bitWrite(effstate, k, PApplet.parseBoolean(bitRead(PApplet.parseByte(xFFBAxisIndex), k-5))); // code FFB axis index
  }
}

public void readPWMstate () { // decode settings from pwmstate value
  typepwm = PApplet.parseBoolean(bitRead (pwmstate, 0)); // bit0 of pwmstate is pwm type
  // put bit1 of pwmstate to bit0 modepwm 
  modepwm = bitWrite(PApplet.parseByte(modepwm), 0, PApplet.parseBoolean(bitRead (pwmstate, 1))); // bit1 and bit6 of pwmstate contain pwm mode (here we take care of bit1)

  // pwmstate bits meaning when no DAC
  // bit1 bit6 pwm_mode     pwm_mode2 (2-ffb axis)
  // 0    0    pwm+-        2ch pwm+-
  // 0    1    pwm0.50.100  2ch pwm0.50.100 (not available yet)
  // 1    0    pwm+dir      2ch pwm+dir     (not available yet)
  // 1    1    rcm          2ch rcm         (not available yet)

  for (int i=2; i<=5; i++) { // read frequency index, bits 2-5 of pwmstate
    freqpwm = bitWrite(PApplet.parseByte(freqpwm), i-2, PApplet.parseBoolean(bitRead(pwmstate, i)));
  }

  // pwmstate bits meaning with DAC
  // bit6 bit5 dac_mode      dac_mode2 (2-ffb axis)
  // 0    0    dac+-         1ch dac+-
  // 0    1    dac0.50.100   2ch dac0.50.100
  // 1    0    dac+dir       2ch dac+dir
  // 1    1    none          none

  // modedac
  // bit0 bit1 dac_mode
  // 0    0    dac+-
  // 0    1    dac+dir
  // 1    0    dac0.50.100
  // 1    1    none

  // bit6 and bit5 of pwmstate contain DAC mode
  modedac = bitWrite(PApplet.parseByte(modedac), 0, PApplet.parseBoolean(bitRead(pwmstate, 6))); // put bit6 of pwmstate to bit0 of modedac
  modedac = bitWrite(PApplet.parseByte(modedac), 1, PApplet.parseBoolean(bitRead(pwmstate, 5))); // put bit5 of pwmstate to bit1 of modedac
  // put bit6 of pwmstate to bit1 of modepwm 
  modepwm = bitWrite(PApplet.parseByte(modepwm), 1, PApplet.parseBoolean(bitRead(pwmstate, 6))); // bit1 and bit6 of pwmstate contain pwm mode (here we take care of bit6)
  enabledac = PApplet.parseBoolean(bitRead(pwmstate, 7)); // bit7 of pwmstate is DAC out enable
  pwmstateprev = pwmstate;
}

public void sendPWMstate () { // send pwmstate value to arduino
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
    wb = "W " + str(PApplet.parseInt(pwmstate)); // set command for pwm settings
    executeWR(); // send values to arduino and read response from it (arduino will save it in EEPPROM right away)
  } else {
    showMessageDialog(frame, "You are trying to set pwm/dac settings that are not allowed,\nplease set correct pwm/dac settings first and try again.", "Caution", WARNING_MESSAGE);
  }
}

public void updatePWMstate () { // code pwmstate byte from pwm/dac setting values
  pwmstate = bitWrite(pwmstate, 0, typepwm);
  pwmstate = bitWrite(pwmstate, 1, PApplet.parseBoolean(bitRead(PApplet.parseByte(modepwm), 0))); // copy bit0 of modepwm into bit1 of pwmstate
  for (int i=2; i <=5; i++) { // set frequency index, bits 2-5 of pwmstate
    pwmstate = bitWrite(pwmstate, i, PApplet.parseBoolean(bitRead(PApplet.parseByte(freqpwm), i-2)));
  }
  if (DACenabled) {
    pwmstate = bitWrite(pwmstate, 6, PApplet.parseBoolean(bitRead(PApplet.parseByte(modedac), 0)));
    if (fwVerNum >= 250) pwmstate = bitWrite(pwmstate, 5, PApplet.parseBoolean(bitRead(PApplet.parseByte(modedac), 1))); // since fw-v250 we have introduced dac0.50.100 mode so we need to read one more bit in order to configure 3 modes
  } else {
    enabledac = false; // we set bit7 of pwmstate LOW when not using dac output, because it is unused (for simplicity we keep it 0 since this is MSB of pwmstate)
    pwmstate = bitWrite(pwmstate, 6, PApplet.parseBoolean(bitRead(PApplet.parseByte(modepwm), 1))); // only look at bit1 of modepwm (beacause we only have 2 modes: fast pwm and phase correct)
  }
  pwmstate = bitWrite(pwmstate, 7, enabledac); // update DAC enable/disable state (for pwm output mode, it's just 0)
}

// function that will be called when controller 'numbers' change
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

public void makeEditable(Numberbox n) {
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

public void frequency(int n) {
  /* request the selected item based on index n
   here an item is stored as a Map with the following key-value pairs:
   name, the given name of the item
   text, the given text of the item by default the same as name
   value, the given value of the item, can be changed by using .getItem(n).put("value", "abc"); a value here is of type Object therefore can be anything
   color, the given color of the item, how to change, see below
   view, a customizable view, is of type CDrawable */
  CColor c = new CColor();
  c.setBackground(color(255, 0, 0));
  pwm_freq.getItem(n).put("color", c);
  freqpwm = n;
  updatePWMstate ();
  if (n < allowedRCMfreqID) { // everything above 500Hz, or lower than freq ID 4
    if (RCMselected) showMessageDialog(frame, "This frequency is not available for RCM mode,\nplease select the other one.", "Caution", WARNING_MESSAGE);
  }
}

public void pwmtype(int n) {
  CColor c = new CColor();
  c.setBackground(color(255, 0, 0));
  pwm_type.getItem(n).put("color", c);
  typepwm = PApplet.parseBoolean(n);
  updatePWMstate();
}

public void pwmmode(int n) {
  CColor c = new CColor();
  c.setBackground(color(255, 0, 0));
  pwm_mode.getItem(n).put("color", c);
  modepwm = n;
  updatePWMstate ();
  if (n == 3) { // if we selected RCM pwm mode, only available if firmware supports RCM pwm mode
    if (!RCMselected) { // if RCM mode is not selected
      pwm_freq.removeItems(a1); // remove extended pwm freq selection
      pwm_freq.addItems(a2_rcm); // add pwm freq selection for RCM pwm mode
      RCMselected = true;
    }
  } else { // if we selected anything else except for RCM mode
    if (RCMselected) { // if previous selection was RCM mode
      pwm_freq.removeItems(a2_rcm); // remove freq selection for RCM pwm mode
      pwm_freq.addItems(a1); // add the extented pwm freq selection
    }
    RCMselected = false;
  }
  pwm_freq.setValue(freqpwm); // update the frequency list to the last freq selection
}

public void dacmode(int n) {
  CColor c = new CColor();
  c.setBackground(color(255, 0, 0));
  dac_mode.getItem(n).put("color", c);
  modedac = n;
  updatePWMstate();
}

public void dacout(int n) {
  CColor c = new CColor();
  c.setBackground(color(255, 0, 0));
  dac_mode.getItem(n).put("color", c);
  enabledac = PApplet.parseBoolean(n);
  updatePWMstate();
}

public void xFFBaxis(int n) {
  CColor c = new CColor();
  c.setBackground(color(255, 0, 0));
  ffb_axis.getItem(n).put("color", c);
  xFFBAxisIndex = PApplet.parseByte(n);
  updateEffstate();
}

public void profile(int n) {
  CColor c = new CColor();
  c.setBackground(color(255, 0, 0));
  profile.getItem(n).put("color", c);
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

public int COMselector() {
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
          COMlist += "(" +PApplet.parseChar(j+'a') + ") " + Serial.list()[j];
          if (++j < i) COMlist += ",  ";
        }
        COMx = showInputDialog(frame, "Step 2 of setup passed succesfuly, we're almost finished.\n\t" + gpad + " at? (type letter only)\n" + COMlist, "Setup - step 3/3", QUESTION_MESSAGE);
        if (COMx == null) {
          exit();
        } else {
          if (COMx.isEmpty()) exit();
          i = PApplet.parseInt(COMx.toLowerCase().charAt(0) - 'a') + 1;
        }
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

public String[] ProfileNameList() {
  String[] temp = new String[num_profiles];
  for (int i=0; i<num_profiles; i++) {
    temp[i] = profiles[i].name;
  }
  return temp;
}

public void loadProfiles() { // checks if profiles exist and then load them in memory
  for (int i=0; i<num_profiles; i++) {
    if (profiles[i].exists(i)) {
      profiles[i].loadFromFile("profile"+str(i));
      println("profile"+str(i)+".txt", "loaded in memory");
    } else {
      //println("profile"+str(i)+".txt", "not found");
    }
    //profiles[i].show();
  }
  profile.setItems(ProfileNameList());
}

public void listProfiles() {
  for (int i=0; i<num_profiles; i++) {
    //if (profiles[i].exists(i)) {
    profiles[i].show();
    //}
  }
}

public int maxAllowedCPR (float deg) { // maximum allowed CPR for any gived rotation degrees range
  int temp = 0;
  temp = PApplet.parseInt((PApplet.parseFloat(maxCPR_turns))/(deg/360.0f));
  if (temp >= maxCPR) {
    temp = maxCPR;
  }
  return temp;
}

public float maxAllowedDeg (float cpr) { // maximum allowed rotation degrees range for any given encoder CPR
  float temp = 0.0f;
  temp = PApplet.parseFloat(maxCPR_turns)/(cpr/360.0f);
  if (temp >= deg_max) {
    temp = deg_max;
  }
  return temp;
}

public void SetAxisColors() { // set default, load or save axis colors into a txt file
  File ac = new File(dataPath("axisColor_cfg.txt"));
  if (!ac.exists()) { // if file does not exist
    for (int i=0; i<num_axis; i++) { // initialize default axis colors
      axis_color[i] = color(i*48, 255, 255); // hue, saturation, brightness
    }
    String acset[] = {hex(axis_color[0]), hex(axis_color[1]), hex(axis_color[2]), hex(axis_color[3]), hex(axis_color[4])};
    saveStrings("/data/axisColor_cfg.txt", acset);  // save axis colors in HEX form
    println("Axis colors: saved to txt");
    showSetupTextLine("Axis colors: saved to txt");
  } else { // load colors from txt
    String[] newcolors = loadStrings("axisColor_cfg.txt");
    for (int i=0; i<num_axis; i++) {
      axis_color[i] = color(PApplet.parseInt(unhex(newcolors[i]))); //unhex returns int from string containing HEX number
    }
    println("Axis colors: loaded from txt");
    showSetupTextLine("Axis colors: loaded from txt");
  }
}

// show one line of setup text and append it to buffer
public void showSetupTextLine(String text) {
  updateSetupTextLine(text); // append line to buffer
  background(bckBrgt);
  for (int i=1; i<setupTextBuffer.length; i++) {
    text(setupTextBuffer[i], 20, heightprev-(i+1)*font_size);
  }
}

// append one line of setup text in the buffer
public void updateSetupTextLine(String s) {
  setupTextLength++;
  setupTextBuffer[0] = s;
  for (int i=setupTextBuffer.length-1; i>0; i--) {
    setupTextBuffer[i] = setupTextBuffer[i-1];
  }
}

// clear setup text buffer
public void clearSetupTextBuffer() {
  for (int i=0; i<setupTextBuffer.length; i++) {
    setupTextBuffer[i] = " ";
  }
}

// display setup text buffer
public void drawSetupTextBuffer(float a) {
  float maxWidth = 0;
  for (int i=0; i<setupTextBuffer.length; i++) {
    if (textWidth(setupTextBuffer[i]) >= maxWidth) maxWidth = textWidth(setupTextBuffer[i]);
  }
  for (int i=1; i<=setupTextLength; i++) {
    //if (setupTextBuffer[i].equals(" ")) break; // do not show empty lines
    fill(bckBrgt, a);
    strokeWeight(1);
    stroke(bckBrgt, a);
    rect(20, heightprev-(i+1)*font_size, maxWidth, -1.1f*font_size);
    pushMatrix();
    translate(20, heightprev-(i+1.1f)*font_size);
    fill(255, a);
    textSize(font_size);
    text(setupTextBuffer[i], 0, 0);
    popMatrix();
  }
}

public void animateSetupTextBuffer(int frames) {
  float t = (PApplet.parseFloat(frames) / frameRate); // update timer for showing setup text
  float as = (1000.0f * setupTextInitAlpha) / (PApplet.parseFloat(setupTextFadeout_ms) * frameRate); // fade out step for setupTextAlpha in each frame
  float t_s = PApplet.parseFloat(setupTextTimeout_ms)/1000.0f; // timeout in s
  if (t > t_s) {
    setupTextAlpha -= as; // decrease setupTextAlpha until 0
    if (setupTextAlpha < 0) {
      setupTextAlpha = 0; // prevent negative
      showSetupText = false;
    }
  }
  drawSetupTextBuffer(setupTextAlpha);
}

public void ExportSetupTextLog() {
  String[] e = new String[setupTextLength];
  for (int i=0; i<setupTextLength; i++) {
    e[i] = setupTextBuffer[setupTextLength-i]; // reverse the order of lines
  }
  saveStrings("/data/setupTextLog.txt", e);
  println("Exported setupTextLog.txt");
}

public void refreshXYshifterPos() {
  wb = shCommand[7];
  executeWR();
}
public void refreshXYshifterCal() {
  wb = shCommand[6];
  executeWR();
}

public void updateLastShifterConfig() { // update curent shifter cal and config values
  for (int i=0; i<shifterLastConfig.length-1; i++) {
    shifterLastConfig[i] = PApplet.parseInt(shifters[0].sCal[i]); // XY shifter calibration values
  }
  shifterLastConfig[5] = PApplet.parseInt(shifters[0].sConfig); // XY shifter configuration
}

public void codeShifterLastConfig() { // code shifter configuration buttons from GUI into a last config integer global variable
  if (buttonpressed[17]) { // if b pressed
    shifterLastConfig[5] = bitWrite(PApplet.parseByte(shifterLastConfig[5]), 0, true); // sConfig bit0 HIGH - reverse gear button inverted (for logitech G25/G27/G29/G923 H-shifters)
  } else { // if unpressed
    shifterLastConfig[5] = bitWrite(PApplet.parseByte(shifterLastConfig[5]), 0, false); // sConfig bit0 LOW - reverse gear button normal
  }
  if (buttonpressed[12]) { // if r pressed
    shifterLastConfig[5] = bitWrite(PApplet.parseByte(shifterLastConfig[5]), 1, true); // sConfig bit1 HIGH - 8 gear mode
  } else { // if unpressed
    shifterLastConfig[5] = bitWrite(PApplet.parseByte(shifterLastConfig[5]), 1, false); // sConfig bit1 LOW - 6 gear mode
  }
  if (buttonpressed[15]) { // if x pressed
    shifterLastConfig[5] = bitWrite(PApplet.parseByte(shifterLastConfig[5]), 2, true); // sConfig bit1 HIGH - X-axis inverted
  } else { // if unpressed
    shifterLastConfig[5] = bitWrite(PApplet.parseByte(shifterLastConfig[5]), 2, false); // sConfig bit1 LOW - X-axis normal
  }
  if (buttonpressed[16]) { // if y pressed
    shifterLastConfig[5] = bitWrite(PApplet.parseByte(shifterLastConfig[5]), 3, true); // sConfig bit1 HIGH - Y-axis inverted
  } else { // if unpressed
    shifterLastConfig[5] = bitWrite(PApplet.parseByte(shifterLastConfig[5]), 3, false); // sConfig bit1 LOW - Y-axis normal
  }
}

public void decodeShifterConfig(int cfg) { // decode shifter config integer (from profile) into GUI shifter config buttons
  byte shcfg = PApplet.parseByte(cfg);
  if (bitRead(shcfg, 0) == 1) { // if rev gear button is inverted
    buttonpressed[17] = true; // set b button high
  } else {
    buttonpressed[17] = false; // set b button low
  }
  if (bitRead(shcfg, 1) == 1) { // if 8 gear mode
    buttonpressed[12] = true; // set r button high
  } else {
    buttonpressed[12] = false; // set r button low
  }
  if (bitRead(shcfg, 2) == 1) { // if X-axis inverted
    buttonpressed[15] = true; // set x button high
  } else {
    buttonpressed[15] = false; // set x button low
  }
  if (bitRead(shcfg, 3) == 1) { // if Y-axis inverted
    buttonpressed[16] = true; // set y button high
  } else {
    buttonpressed[16] = false; // set y button low
  }
}

public void refreshPedalCalibration() {
  wb = pdlCommand[8];
  executeWR();
}

public void updateLastPedalCalibration(String calibs) { // update curent GUI pedal calibration limits from a string
  float[] temp = PApplet.parseFloat(split(calibs, ' ')); // format is "min max min max min max min max"
  for (int i=0; i<pdlMinParm.length; i++) {
    pdlMinParm[i] = temp[2*i]; // every even number is min
    pdlMaxParm[i] = temp[2*i+1]; // every odd number is max
    axisBars[i+1].updateCal(pdlMinParm[i], pdlMaxParm[i]); //update pCal
  }
  if (twoFFBaxis_enabled) {
    if (noOptEnc && noMagEnc) {
      float sf = axisBars[0].am / axisBars[2].am; // scale factor to convert x-axis cal limits range to z-axis cal limits range
      axisBars[0].updateCal(pdlMinParm[1]*sf, pdlMaxParm[1]*sf); // copy z-axis cal limits to x-axis cal limits
    }
  }
}

public void updateCP5_elements(boolean resize) {
  if (resize) {
    int sy = PApplet.parseInt(1.6f*font_size); 
    for (int i=0; i<cp5sdr.length; i++) {
      cp5sdr[i]
        .setPosition(PApplet.parseInt(widthprev/cp5xoff), PApplet.parseInt(heightprev*(cp5yoff + i*3/cp5sdy)))
        .setSize(PApplet.parseInt(widthprev/cp5sx), PApplet.parseInt(heightprev/cp5sy));
    }
    num1
      .setFont(fontd)
      .setPosition(PApplet.parseInt(xPosAxis(1)), PApplet.parseInt(2.32f*axisHeight))
      .setSize(PApplet.parseInt(textWidth("99999")+font_size), sy);
    profile
      .setFont(fontd)
      .setPosition(PApplet.parseInt(xPosCP5sdr(18)), PApplet.parseInt(yPosCP5sdr(12)))
      .setSize(PApplet.parseInt(textWidth("profile")+2.0f*font_size), 5*sy)
      .setBarHeight(sy)
      .setItemHeight(sy);
    ffb_axis
      .setFont(fontd)
      .setPosition(PApplet.parseInt(xPosAxis(0)), heightprev-posY+5)
      .setSize(PApplet.parseInt(textWidth("ry-hbr")+2.0f*font_size), 6*sy)
      .setBarHeight(sy)
      .setItemHeight(sy);
    pwm_type
      .setFont(fontd)
      .setPosition(PApplet.parseInt(xPosCP5sdr(21)), PApplet.parseInt(yPosCP5sdr(12)))
      .setSize(PApplet.parseInt(textWidth("phase corr")+2.0f*font_size), 3*sy)
      .setBarHeight(sy)
      .setItemHeight(sy);
    pwm_mode
      .setFont(fontd)
      .setPosition(PApplet.parseInt(xPosCP5sdr(20)), PApplet.parseInt(yPosCP5sdr(12)))
      .setSize(PApplet.parseInt(textWidth("pwm mode")+2.0f*font_size), 5*sy)
      .setBarHeight(sy)
      .setItemHeight(sy);
    pwm_freq
      .setFont(fontd)
      .setPosition(PApplet.parseInt(xPosCP5sdr(19)), PApplet.parseInt(yPosCP5sdr(12)))
      .setSize(PApplet.parseInt(textWidth("40.0 kHz")+1.0f*font_size), 5*sy)
      .setBarHeight(sy)
      .setItemHeight(sy);
    if (DACenabled) {
      dac_mode.setFont(fontd);
      if (fwVerNum >= 250 && !twoFFBaxis_enabled) {
        dac_mode.setPosition(Xoffset+PApplet.parseInt(widthprev/3.5f) - 20 + 9.2f*60, PApplet.parseInt(yPosCP5sdr(12)));
      } else if (fwVerNum >= 250 && twoFFBaxis_enabled) {
        dac_mode.setPosition(Xoffset+PApplet.parseInt(widthprev/3.5f) - 20 + 9.0f*60, PApplet.parseInt(yPosCP5sdr(12)));
      }
      dac_mode.setSize(PApplet.parseInt(wScaleX*60), PApplet.parseInt(wScaleY*100));
      dac_out.setFont(fontd);
      if (!twoFFBaxis_enabled) {
        dac_out.setPosition(Xoffset+PApplet.parseInt(widthprev/3.5f) + 4 + 7.6f*60, PApplet.parseInt(yPosCP5sdr(12)));
      } else {
        dac_out.setPosition(Xoffset+PApplet.parseInt(widthprev/3.5f) - 5 + 7.6f*60, PApplet.parseInt(yPosCP5sdr(12)));
      }
      dac_out.setSize(PApplet.parseInt(wScaleX*60), PApplet.parseInt(wScaleY*100));
    }
  }
}

public float xPosCP5sdr(int i) { // these are relative to cp5 slider x-positions
  float x = 0;
  float[] mx = new float[22]; // x-offset multiplyers
  mx[3] = mx[4] = mx[5] = mx[6] = mx[7] = 1.15f; // for ffb user effect buttons
  mx[9] = 0.42f; // for pwm button
  mx[1] = 0.57f; // for default button
  mx[8] = 0.755f; // for save button
  mx[10] = 1.107f; // for store button
  mx[11] = mx[12] = mx[15] = mx[16] = mx[17] = 6; // for shifter buttons
  mx[18] = 0.9f; // for profile drop down menu list
  mx[19] = 0.224f; // for pwm freq drop down menu list
  mx[20] = -0.01f; // for pwm mode drop down menu list
  mx[21] = -0.225f; // for pwm type drop down menu list
  x = widthprev*(1.0f/cp5xoff + mx[i]/cp5sx);
  return x;
}

public float yPosCP5sdr(int i) {  // these are relative to cp5 slider y-positions
  float y = 0;
  if (i == 12) {
    y = heightprev*(cp5yoff + i*3/cp5sdy)-buttons[0].sy*0.55f; // for pwm(9), default(1), save(8) and store(10) buttons, pwm_type, pwm_mode, pwm_freq and profile drop down menu lists
  } else {
    y = heightprev*(cp5yoff + i*3/cp5sdy);
  }
  return y;
}

public float xPosAxis(int i) { // these are relative to AxisBars x-positions
  float x = 0;
  float[] mx = new float[32]; // x-offset multiplyers
  mx[0] = 0.206f; // for ffb_axis drop down menu list
  mx[1] = 0.264f; // for numberbox cpr adjustment
  mx[2] = 0.391f; // for auto cal button
  mx[13] = 0.391f; // for manual cal button
  mx[11] = 0.312f; // for H-shifter button
  mx[15] = 0.312f; // for x shifter button
  mx[12] = 0.355f; // for r shifter button
  mx[17] = 0.355f; // for b shifter button
  mx[16] = 0.315f; // for y shifter button
  x = widthprev*mx[i];
  return x;
}
class AxisBar {
  int c;
  float x, y, s, am, axisVal;
  String l, la, lb;
  xyCal[] yLimits = new xyCal[2];
  boolean yLimitsVisible, xffb, yffb, inactive;
  float[] pCal = new float[2];
  int id, bigTicks, smallTicks;
  int bTn, sTn, bTl, sTl;

  AxisBar(int acolor, float posx, float posy, float size, float axisMax, String label, String labela, String labelb, boolean xffbaxis, boolean yffbaxis) {
    c = acolor;
    x = posx;
    y = posy;
    s = size;
    am = axisMax;
    l = label;
    la = labela;
    lb = labelb;
    xffb = xffbaxis;
    yffb = yffbaxis;
    yLimits[0] = new xyCal(x-2.8f*s, y, s, s, 3, la);
    yLimits[1] = new xyCal(x-2.8f*s, y-2*axisHeight, s, s, 3, lb);
    yLimits[0].active = true;
    yLimits[1].active = true;
    yLimitsVisible = false;
    pCal[0] = 0;
    pCal[1] = am;
    yLimits[0].y = convertToyLimits(0);
    yLimits[1].y = convertToyLimits(1);
    bTn = 10; // number of big ticks
    sTn = 5; // number of small ticks
    bTl = 10; // length of big ticks
    sTl = 5; // length of small ticks
  }

  public void update(int i, boolean resize) {
    if (resize) {
      shXoff = s*wScaleX;
      x = PApplet.parseFloat(widthprev)/3.65f + i*6*s*wScaleX;
      axisHeight = PApplet.parseInt(wScaleY*axisHeight_init);
      y = 2.2f*axisHeight;
      posY = heightprev - (2.2f*axisHeight);
      yLimits[0].y = convertToyLimits(0);
      yLimits[1].y = convertToyLimits(1);
      yLimits[0].x = x-2.8f*s*wScaleX;
      yLimits[1].x = x-2.8f*s*wScaleX;
      yLimits[0].sx = wScaleY*s;
      yLimits[0].sy = wScaleX*s;
      yLimits[1].sx = wScaleY*s;
      yLimits[1].sy = wScaleX*s;
    }
    if (i == 0) {        // X-axis
      axisVal = gpad.getSlider("Xaxis").getValue();
      if (axisVal != prevaxis) wheelMoved = true;
    } else if (i == 1) { // Y-axis
      axisVal = gpad.getSlider("Yaxis").getValue();
    } else if (i == 2) { // Z-axis
      axisVal = gpad.getSlider("Zaxis").getValue();
    } else if (i == 3) { // RX-axis
      axisVal = gpad.getSlider("RXaxis").getValue();
    } else if (i == 4) { // RY-axis
      axisVal = gpad.getSlider("RYaxis").getValue();
    } else {
      axisVal = 0.0f;
    }
    // update axis view with xFFB marking (for now only x is configurable)
    if (xFFBAxisIndex == i) {
      xffb = true; // axis with xFFB mark
    } else {
      xffb = false; // axis without xFFB mark
    }
    // update axis view with yFFB marking (not configurable for now)
    if (yFFBAxisIndex == i) {
      yffb = true; // axis with yFFB mark
    } else {
      yffb = false; // axis without yFFB mark
    }
    setpCal();
    id = i;
  }

  public void getyLimits(int i) { // get yLimits value from mouse position
    yLimits[i].y = mouseY; // update yLimits y position
    updateyLimitsLimit(i);
    checkyLimitsLimit(i);
  }

  public void setpCal() { // set pedal calibration from wheel control
    for (int i=0; i<yLimits.length; i++) {
      if (yLimits[i].changing) {
        getyLimits(i);
        pCal[i] = getpCalFromyLimits(i);
      }
    }
  }

  public void updateCal(float min, float max) {
    pCal[0] = min;
    pCal[1] = max;
    for (int i=0; i<yLimits.length; i++) {
      yLimits[i].y = convertToyLimits(i);
      updateyLimitsLimit(i);
      checkyLimitsLimit(i);
    }
  }

  public float getpCalFromyLimits(int i) { // convert graph coordinates into pCal values
    return map(yLimits[i].y, y, y-2*axisHeight, 0, am);
  }

  public float convertToyLimits(int i) {  // convert pCal values into graph coordinates
    return map(pCal[i], 0, am, y, y-2*axisHeight);
  }

  public void updateyLimitsLimit(int i) { // update pedal calibration limits in the scaled pCal units
    if (i == 0) {
      yLimits[i].limits[2] = yLimits[i+1].y + s; // d low limit is e
      yLimits[i].limits[3] = y - 0*s/2; // d high limit is 2*axisHeight
    }
    if (i == 1) {
      yLimits[i].limits[2] = y-2*axisHeight + 0*s/2; // e low limit is 0
      yLimits[i].limits[3] = yLimits[i-1].y - s; // e high limit is d
    }
  }

  public void checkyLimitsLimit(int i) { // checks if scaled pCal values are withing limits and limit them if they are not
    if (yLimits[i].y <= yLimits[i].limits[2]) {
      yLimits[i].y = yLimits[i].limits[2];
    } else if (yLimits[i].y > yLimits[i].limits[3]) {
      yLimits[i].y = yLimits[i].limits[3];
    }
  }

  public void show() {
    if (inactive) {
      c = color(0, 0, 100); // inactive gray
    }
    fill(c);
    strokeWeight(1);
    stroke(255);
    pushMatrix();
    rectMode(CORNER);
    rect(x, y, s*wScaleX, -axisHeight-axisVal*axisHeight);
    translate(x-1.5f*s*wScaleX, y);
    float n = PApplet.parseFloat(axisHeight)/PApplet.parseFloat(bTn);
    float m = n/PApplet.parseFloat(sTn);
    if (m < 4) {
      sTn -= 1;
      m = n/PApplet.parseFloat(sTn);
    }
    if (m > 5) {
      sTn += 1;
      if (sTn > 5) sTn = 5;
      m = n/PApplet.parseFloat(sTn);
    }
    for (int i = 0; i > -2*bTn; i--) {
      for (int j = 0; j > -sTn; j--) {
        line(0, i*n, wScaleX*bTl, i*n);
        line(0, j*m + i*n, wScaleX*sTl, j*m + i*n);
      }
    }
    line(0, -2*bTn*n, wScaleX*bTl, -2*bTn*n);
    fill(255);
    text(round(map(axisVal, -1, 1, 0, am)), 0, -2*n*bTn-1.0f*font_size);
    noFill();
    textSize(0.8f*font_size);
    String ffbmark = "xFFB";
    if (xffb && yffb) {
      if (twoFFBaxis_enabled) {
        ffbmark = "xyFFB";
      } else {
        ffbmark = "xFFB";
      }
      rect(wScaleX*15, wScaleY*15-font_size, textWidth(ffbmark)+1, font_size);
      text(ffbmark, wScaleX*15, wScaleY*15-0.15f*font_size);
    } else if (xffb) {
      ffbmark = "xFFB";
      rect(wScaleX*15, wScaleY*15-font_size, textWidth(ffbmark)+1, font_size);
      text(ffbmark, wScaleX*15, wScaleY*15-0.15f*font_size);
    } else if (yffb) {
      if (twoFFBaxis_enabled) {
        ffbmark = "yFFB";
        rect(wScaleX*15, wScaleY*15-font_size, textWidth(ffbmark)+1, font_size);
        text(ffbmark, wScaleX*15, wScaleY*15-0.15f*font_size);
      }
    }
    fill(255);
    textSize(font_size);
    text(l, -textWidth(l)/5, 1.7f*font_size);
    //if (id < 3) {
    //text(l, -2, wScaleY*20);
    //} else {
    //text(l, -font_size/2, 20*wScaleY);
    //}
    popMatrix();
    if (yLimitsVisible) {
      for (int j=0; j<yLimits.length; j++) {
        yLimits[j].updateColors(ctrl_btn+ctrl_sh_btn+2*id+j); // milos, was id-1 to skip X-axis cal limits
        yLimits[j].showPointer(2.8f*s, 0);
      }
    }
  }
}
class InfoButton {
  int ns, as, dp;
  float x, y, sx, sy;
  String[] n = new String[ns];
  String d;
  Boolean enabled, hiden, showDescription;

  InfoButton(float posx, float posy, float sizex, float sizey, int nSegments, String[] name, String description, int descriptionPos) {
    x = posx;
    y = posy;
    sx = sizex;
    sy = sizey;
    ns = nSegments;
    n = name;
    as = -1; // no segment is active
    d = description;
    dp = descriptionPos;
    enabled = false;
    hiden = true;
    showDescription = false;
  }

  public void update(boolean resize) {
    if (resize) {
      if (d != " ") {
        sx = textWidth(d)+font_size;
      } else {
        sx = 1.4f*font_size;
      }
      sy = 1.4f*font_size;
      x = 0.123f*widthprev + (wScaleX*axisHeight_init*0.8f)/2;
      y = 0.223f*heightprev - (wScaleY*axisHeight_init*0.8f)/2 - sy;
    }
    if (mouseX >= x && mouseX <= x+sx && mouseY >= y && mouseY <= y+sy) {
      showDescription = true; // if howered with mouse
    } else {
      showDescription = false; // if not howered
    }
  }
  public void show() {
    int ce = color (0, 200, 150); // red
    int cd = color (0, 0, 100); // gray
    thue = 255; // white
    if (!hiden) {
      for (int i=0; i<ns; i++) {
        fill(cd);
        if (i == as) fill(ce);
        strokeWeight(1);
        stroke(255);
        pushMatrix();
        translate(x, y);
        rect(i*(sx/ns), 0, sx/ns, sy);
        textSize(font_size);
        fill(thue);
        text(n[i], i*(sx/ns)+0.5f*(sx/ns - textWidth(n[i])), font_size);
        popMatrix();
      }
      if (showDescription) {
        pushMatrix();
        if (dp == 0) {
          translate(x, y-1.15f*sy); // put description above
        } else if (dp == 1) {
          translate(x, y+1.15f*sy); // put description bellow
        } else if (dp == 2) {
          translate(x-textWidth(d)-font_size, y); // put description to the left side
        } else if (dp == 3) {
          translate(x+sx, y); // put description to the right side
        }
        noFill();
        rect(0, 0, textWidth(d)+font_size, sy);
        text(d, 0.5f*font_size, font_size);
        popMatrix();
      }
    }
  }
}
class WheelButton {
  float x;
  float y;
  float s;
  boolean enabled;

  WheelButton(float posx, float posy, float size) {
    x = posx;
    y = posy;
    s = size;
    enabled = false;
  }

  public void update() {
    if (gpad.getButton("0").pressed()) {
      Button[0] = true;
    } else {
      Button[0] = false;
    }
    if (gpad.getButton("1").pressed()) {
      Button[1] = true;
    } else {
      Button[1] = false;
    }
    if (gpad.getButton("2").pressed()) {
      Button[2] = true;
    } else {
      Button[2] = false;
    }
    if (gpad.getButton("3").pressed()) {
      Button[3] = true;
    } else {
      Button[3] = false;
    } 
    if (gpad.getButton("4").pressed()) {
      Button[4] = true;
    } else {
      Button[4] = false;
    }
    if (gpad.getButton("5").pressed()) {
      Button[5] = true;
    } else {
      Button[5] = false;
    }
    if (gpad.getButton("6").pressed()) {
      Button[6] = true;
    } else {
      Button[6] = false;
    }
    if (gpad.getButton("7").pressed()) {
      Button[7] = true;
    } else {
      Button[7] = false;
    }
    if (gpad.getButton("8").pressed()) {
      Button[8] = true;
    } else {
      Button[8] = false;
    }
    if (gpad.getButton("9").pressed()) {
      Button[9] = true;
    } else {
      Button[9] = false;
    }
    if (gpad.getButton("10").pressed()) {
      Button[10] = true;
    } else {
      Button[10] = false;
    }
    if (gpad.getButton("11").pressed()) {
      Button[11] = true;
    } else {
      Button[11] = false;
    }
    if (gpad.getButton("12").pressed()) {
      Button[12] = true;
    } else {
      Button[12] = false;
    }
    if (gpad.getButton("13").pressed()) {
      Button[13] = true;
    } else {
      Button[13] = false;
    }
    if (gpad.getButton("14").pressed()) {
      Button[14] = true;
    } else {
      Button[14] = false;
    }
    if (gpad.getButton("15").pressed()) {
      Button[15] = true;
    } else {
      Button[15] = false;
    }
    if (gpad.getButton("16").pressed()) {
      Button[16] = true;
    } else {
      Button[16] = false;
    }
    if (gpad.getButton("17").pressed()) {
      Button[17] = true;
    } else {
      Button[17] = false;
    }
    if (gpad.getButton("18").pressed()) {
      Button[18] = true;
    } else {
      Button[18] = false;
    }
    if (gpad.getButton("19").pressed()) {
      Button[19] = true;
    } else {
      Button[19] = false;
    }
    if (gpad.getButton("20").pressed()) {
      Button[20] = true;
    } else {
      Button[20] = false;
    }
    if (gpad.getButton("21").pressed()) {
      Button[21] = true;
    } else {
      Button[21] = false;
    }
    if (gpad.getButton("22").pressed()) {
      Button[22] = true;
    } else {
      Button[22] = false;
    }
    if (gpad.getButton("23").pressed()) {
      Button[23] = true;
    } else {
      Button[23] = false;
    }
    /*if (gpad.getButton("24").pressed()) {
     Button[24] = true;
     } else {
     Button[24] = false;
     }
     if (gpad.getButton("25").pressed()) {
     Button[25] = true;
     } else {
     Button[25] = false;
     }
     if (gpad.getButton("26").pressed()) {
     Button[26] = true;
     } else {
     Button[26] = false;
     }
     if (gpad.getButton("27").pressed()) {
     Button[27] = true;
     } else {
     Button[27] = false;
     }
     if (gpad.getButton("28").pressed()) {
     Button[28] = true;
     } else {
     Button[28] = false;
     }
     if (gpad.getButton("29").pressed()) {
     Button[29] = true;
     } else {
     Button[29] = false;
     }
     if (gpad.getButton("30").pressed()) {
     Button[30] = true;
     } else {
     Button[30] = false;
     }*/
  }

  public void show(int i, boolean resize) {
    if (resize) {
      s = min(wScaleX, wScaleY)*btn_size_init;
      float d = min(wScaleX, wScaleY)*(btn_size_init+btn_sep_init);
      if (i <= 7) {
        x = 0.05f*widthprev +i*d;
        y = heightprev-posY*1.85f;
      } else if (i > 7 && i < 16) {
        x = 0.05f*widthprev +(i-8)*d;
        y = heightprev-posY*1.85f+d;
      } else if (i > 15 && i < 24) {
        x = 0.05f*widthprev +(i-16)*d;
        y = heightprev-posY*1.85f+2*d;
      }
    }
    if (dActByp) enabled = true; // bypass the button in-activation
    int hue;
    if (buttonValue) {
      hue = 64;
    } else {
      hue = 0;
    }
    if (enabled) {
      fill(hue, 255, 255); // red
    } else {
      fill(0, 0, 100); // gray
    }
    strokeWeight(1);
    stroke(255);
    pushMatrix();
    translate(x, y);
    rect(0, 0, s, s);
    textSize(font_size);
    if (enabled) {
      fill(0); // black text when activated
    } else {
      fill(235); // white-ish text when de-activated
    }
    if (wScaleX <= 1.0f && wScaleY <= 1.0f) {
      if (i<=9) {
        text(i, 0.5f*font_size, 1.1f*font_size);
      } else {
        text(i, 0.15f*font_size, 1.1f*font_size);
      }
    } else {
      text(i, 0.5f*(s - textWidth(str(i))), 1.1f*font_size);
    }
    popMatrix();
  }
}
class Button {
  int dp;
  float x;
  float y;
  float sx, sy;
  String t, d;
  boolean showInfo;
  boolean active;

  Button(float posx, float posy, float sizex, float sizey, String text, String description, int descriptionPos) {
    x = posx;
    y = posy;
    sx = sizex;
    sy = sizey;
    t = text;
    d = description;
    dp = descriptionPos; // 0-up, 1-down, 2-left, 3-right
    showInfo = false;
    active = true;
  }

  public void update(int i, boolean resize) {
    if (resize) {
      if (t != " ") {
        sx = textWidth(t)+font_size;
      } else {
        sx = 1.4f*font_size;
      }
      sy = 1.4f*font_size;
      if (i == 0) {
        x = 0.123f*widthprev + (wScaleX*axisHeight_init*0.8f)/2;
        y = 0.223f*heightprev + (wScaleY*axisHeight_init*0.8f)/2;
      } else if (i == 14) {
        x = 0.123f*widthprev + (wScaleX*axisHeight_init*0.8f)/2 + textWidth(buttons[0].t) + 1.25f*font_size;
        y = 0.223f*heightprev + (wScaleY*axisHeight_init*0.8f)/2;
      } else if (i == 7) {
        x = xPosCP5sdr(i);
        y = yPosCP5sdr(1);
      } else if (i == 4) {
        x = xPosCP5sdr(i);
        y = yPosCP5sdr(2);
      } else if (i == 5) {
        x = xPosCP5sdr(i);
        y = yPosCP5sdr(7);
      } else if (i == 6) {
        x = xPosCP5sdr(i);
        y = yPosCP5sdr(3);
      } else if (i == 3) {
        x = xPosCP5sdr(i);
        y = yPosCP5sdr(8);
      } else if (i == 9) {
        x = xPosCP5sdr(i);
        y = yPosCP5sdr(12);
      } else if (i == 1) {
        x = xPosCP5sdr(i);
        y = yPosCP5sdr(12);
      } else if (i == 8) {
        x = xPosCP5sdr(i);
        y = yPosCP5sdr(12);
      } else if (i == 10) {
        x = xPosCP5sdr(i);
        y = yPosCP5sdr(12);
      } else if (i == 2) {
        sx = textWidth(buttons[13].t)+font_size;
        x = xPosAxis(i);
        y = 2.325f*axisHeight;
      } else if (i == 13) {
        x = xPosAxis(i);
        y = 2.325f*axisHeight+sy+0.25f*font_size;
      } else if (i == 11) {
        x = xPosAxis(i);
        y = 2.325f*axisHeight;
      } else if (i == 12) {
        sx = textWidth(buttons[i].t)+font_size;
        x = xPosAxis(11) + textWidth(buttons[11].t)+1.25f*font_size;
        y = 2.325f*axisHeight;
      } else if (i == 15) {
        sx = textWidth(buttons[12].t)+font_size;
        x = xPosAxis(i);
        y = 2.325f*axisHeight+sy+0.25f*font_size;
      } else if (i == 17) {
        sx = textWidth(buttons[12].t)+font_size;
        x = xPosAxis(11) + textWidth(buttons[11].t)+1.25f*font_size;
        y = 2.325f*axisHeight+sy+0.25f*font_size;
      } else if (i == 16) {
        sx = textWidth(buttons[12].t)+font_size;
        x = xPosAxis(15) + textWidth(buttons[12].t)+1.25f*font_size;
        y = 2.325f*axisHeight+sy+0.25f*font_size;
      }
    }
    if (active) {
      if (mouseX >= x && mouseX <= x+sx && mouseY >= y && mouseY <= y+sy) {
        controlb[i] = true;
      } else {
        controlb[i] = false;
      }
      if (controlb[i] && mousePressed || buttonpressed[i] ) { // green with black text (activated)
        col[0] = 96;
        col[1] = 200;
        col[2] = 150;
        thue = 0;
        showInfo = false;
      } else if (controlb[i] && !mousePressed) { // yellow with white text (howered)
        col[0] = 40;
        col[1] = 200;
        col[2] = 180;
        thue = 255;
        showInfo = true;
      } else if (!controlb[i]) { // red with white text (deactivated)
        col[0] = 0;
        col[1] = 200;
        col[2] = 150;
        thue = 255;
        showInfo = false;
      }
    } else { // gray with white text (not enabled)
      col[0] = 0;
      col[1] = 0;
      col[2] = 100;
      thue = 255;
      showInfo = false;
    }
  }

  public void show() {
    fill(col[0], col[1], col[2]);
    strokeWeight(1);
    stroke(255);
    pushMatrix();
    translate(x, y);
    rect(0, 0, sx, sy);
    pushMatrix();
    textSize(font_size);
    fill(thue);
    text(t, 0.5f*(sx-textWidth(t)), font_size);
    popMatrix();
    if (showInfo) {
      pushMatrix();
      if (dp == 0) {
        translate(0, -1.15f*sy); // put description above
      } else if (dp == 1) {
        translate(0, 1.15f*sy); // put description bellow
      } else if (dp == 2) {
        translate(-textWidth(d)-font_size, 0); // put description to the left side
      } else if (dp == 3) {
        translate(sx, 0); // put description to the right side
      }
      noFill();
      rect(0, 0, textWidth(d)+font_size, sy);
      text(d, 0.5f*font_size, font_size);
      popMatrix();
    }
    popMatrix();
  }
}
class Dialog {
  float x;
  float y;
  float s;
  String t;
  float l;

  Dialog(float posx, float posy, float size, String text) {
    x = posx;
    y = posy;
    s = size;
    t = text;
  }

  public void update(String newText, boolean resize) {
    if (resize) {
      float d = min(wScaleX, wScaleY)*(btn_size_init+btn_sep_init);
      x = 0.05f*widthprev;
      y = heightprev-posY*1.85f+4*d+2*(-1.15f)*font_size;
    }
    l=textWidth(newText) + font_size;
    t=newText;
  }

  public void show() {
    colorMode(RGB, 255, 255, 255);
    fill(0, 45, 90);
    //fill(148, 200, 100);
    strokeWeight(1);
    colorMode(HSB);
    stroke(255);
    rect(x, y, l, 1.5f*font_size);
    pushMatrix();
    textSize(font_size);
    fill(255);
    translate(x, y);
    text(t, 0.5f*font_size, 1.1f*font_size);
    popMatrix();
  }
}
class FFBgraph {
  float x, y;
  int ps, l, p;
  int[] pointY = new int [gbuffer];
  float gwidthX, gh, sclX, sclY;

  FFBgraph(float posx, float posy, float gheight, int pointsize) {
    x = posx - 1;
    y = posy - 1;
    gh = gheight - 1;
    ps = pointsize;
    gwidthX = gbuffer / gskip;
    sclX = gwidthX / gbuffer;
    sclY = gh / (2*maxTorque);
    l = 32;
    p = 5;
  }

  public void updateSize(boolean resize) {
    if (resize) {
      gh = widthprev - 1;
      x = gh;
      sclY = gh / (2*maxTorque);
      gwidthX = wScaleY*gbuffer / gskip;
      sclX = gwidthX / gbuffer;
    }
  }

  public void update(String val1) {
    pointY[0] = parseInt(val1);
    for (int i=pointY.length-1; i>0; i--) {
      pointY[i] = pointY[i-1];
    }
  }

  public void show(int i) {
    if (i == 0) {
      y = heightprev-wScaleY*gbuffer/gskip;
    } else {
      y = heightprev-2*(wScaleY*gbuffer/gskip);
    }
    String gT = "FFB";
    String gL = "left";
    String gR = "right";
    pushMatrix();
    translate(x, y);
    noFill();
    strokeWeight(1);
    stroke(255);
    noFill();
    strokeWeight(1);
    stroke(255);
    if (i == 0) { // for X-axis
      gT = "x" + gT;
    } else { // for Y-axis
      gT = "y" + gT;
      gL = "down";
      gR = "up";
    }
    textAlign(RIGHT);
    text(pointY[0], 0.25f*font_size-gh/2, font_size); // X-axis value (horizontal orientation)
    text(gR, -0.4f*font_size, font_size);
    textAlign(LEFT);
    text(gT, gT.length()*font_size-gh/2, font_size);
    text(gL, gL.length()*0.1f*font_size - gh, font_size);
    rotate(PI/2.0f); // rotate CW by 90deg
    rectMode(CORNER);
    rect(0, 0, gwidthX, gh); // graph frame
    /*if (!twoFFBaxis_enabled) {
     text(pointY[0], (-str(pointY[0]).length()*0.59-1.3)*font_size, gh/2+0.3*font_size); // ffb axis value (vertical orientation), at center of graph
     }*/
    //text(-maxTorque, -60, gh-5+0.3*font_size); // min ffb value indicator
    //text(maxTorque, -50, 5+0.3*font_size); // max ffb value indicator
    pushMatrix();
    translate(0, gh);
    int majl = PApplet.parseInt(8*wScaleY); // major tick length
    int minl = PApplet.parseInt(4*wScaleY); // minor tick length
    if (twoFFBaxis_enabled) { // shorten ticks when we display 2 FFB monitor graphs on top of each other
      majl = PApplet.parseInt(5*wScaleY); 
      minl = PApplet.parseInt(3*wScaleY);
    }
    float n = gh/PApplet.parseFloat(l); // major tick pos
    float m = n/PApplet.parseFloat(p); // minor tick pos
    if (m < 8) {
      p -= 1;
      m = n/PApplet.parseFloat(p);
    }
    if (m > 10) {
      p += 1;
      if (p > 10) p = 10;
      m = n/PApplet.parseFloat(p);
    }

    for (int j = 0; j >= -l; j--) { // draw l+1 major ticks
      for (int k = 0; k > -p; k--) {
        int f = -1; // tick y-offset
        line(f, n*j, f-majl, n*j); // major ticks
        if (j > -l) { // only draw them before last major tick
          if (k != 0) { // do not draw minor tick on top of major tick
            line(f, m*k + n*j, f-minl, m*k + n*j); // small ticks
          }
        }
      }
    }
    popMatrix();
    for (int a=0; a<pointY.length-1; a++) {
      /*noStroke();
       fill(128, 255, 255);
       ellipse(1+a*sclX, gh/2+sclY*maxTorque, ps, ps); // min limit
       fill(0, 255, 255);
       ellipse(1+a*sclX, gh/2-sclY*maxTorque, ps, ps); // max limit*/
      //fill(32, 255, 255);
      //ellipse(1+a*sclX, gh/2-sclY*pointY[i], ps, ps); // ffb signal
      //stroke(32, 255, 255);
      strokeWeight(ps);
      stroke(map(abs(pointY[a]), 0, maxTorque, 145, 0), 255, 255);
      line(sclX*a+1, gh/2-sclY*pointY[a], sclX*(a+1)+1, gh/2-sclY*pointY[a+1]);
    }
    popMatrix();
  }
}
class HatSW {
  float x;
  float y;
  float r;
  float R;
  boolean enabled;

  HatSW (float posx, float posy, float radius, float Radius) {
    x = posx;
    y = posy;
    r = radius;
    R = Radius;
    enabled = false;
  }

  public void update(boolean resize) {
    if (resize) {
      float d = min(wScaleX, wScaleY)*(btn_size_init+btn_sep_init);
      x = 0.05f*widthprev + 9*d + 7;
      y = heightprev-posY*1.82f+d;
      r = min(wScaleX, wScaleY)*hatsw_r_init;
      R = min(wScaleX, wScaleY)*hatsw_R_init;
    }
    if (gpad.getButton("Hat").pressed()) { 
      hatvalue = floor(gpad.getButton("Hat").getValue());
    }
  }

  public void show() {
    int hue;
    if (gpad.getButton("Hat").pressed()) {
      hue = 64;
    } else {
      hue = 0;
    }
    stroke(255);
    strokeWeight(1);
    if (enabled) {
      fill(hue, 255, 255);
    } else {
      fill(0, 0, 100);
    }
    ellipse(x, y, r, r);
    noFill();
    stroke(255, 200);
    ellipse(x, y, R, R);
  }

  public void showArrow() {
    if (gpad.getButton("Hat").pressed()) {
      pushMatrix();
      translate(x, y);
      rotate(TWO_PI*hatvalue/8.0f+(1.0f/2.0f)*PI);
      beginShape();
      noStroke();
      fill(64, 255, 255);
      int hg = floor(R*0.4f);
      vertex(-4, hg+0);
      vertex(4, hg+0);
      vertex(4, hg+5);
      vertex(6, hg+5);
      vertex(0, hg+12);
      vertex(-6, hg+5);
      vertex(-4, hg+5);
      endShape();
      popMatrix();
    }
  }
}
class Info {
  float x;
  float y;
  int s;
  String txt;
  String btn;
  String fullinfo;

  Info(float posx, float posy, int size, String text, String button) {
    x = posx;
    y = posy;
    s = size;
    txt = text;
    btn = button;
    fullinfo = btn + " : " + txt;
  }

  public void update(int i, boolean resize) {
    if (resize) {
      float d = min(wScaleX, wScaleY)*(btn_size_init+btn_sep_init);
      x = 0.05f*widthprev;
      y = heightprev-posY*1.85f+4*d+2*i*font_size;
    }
  }

  public void show(boolean enable) {
    float textLength = 0;
    textLength = textWidth(fullinfo) + font_size;
    if (enable) {
      noFill();
      strokeWeight(1);
      stroke(255);
      rect(x, y, textLength, 1.2f*font_size);
      pushMatrix();
      textSize(font_size);
      fill(255);
      translate(x, y);
      text(fullinfo, font_size/2, 0.9f*font_size);
      popMatrix();
    }
  }
}
// input handler for a Numberbox that allows the user to 
// key in numbers with the keyboard to change the value of the numberbox
public class NumberboxInput {
  String text = "";
  Numberbox n;
  boolean active;

  NumberboxInput(Numberbox theNumberbox) {
    n = theNumberbox;
    registerMethod("keyEvent", this);
  }

  public void keyEvent(KeyEvent k) {
    // only process key event if input is active 
    if (k.getAction()==KeyEvent.PRESS && active) {
      if (k.getKey()=='\n') { // confirm input with enter
        submit();
        return;
      } else if (k.getKeyCode()==BACKSPACE) { 
        text = text.isEmpty() ? "":text.substring(0, text.length()-1);
        //text = ""; // clear all text with backspace
      } else if (k.getKey()<255) {
        // check if the input is a valid (decimal) number
        //final String regex = "\\d+([.]\\d{0,2})?";
        // check if the input is a 5 digit decimal number
        final String regex = "\\d{1,5}?";
        String s = text + k.getKey();
        if (java.util.regex.Pattern.matches(regex, s) ) {
          text += k.getKey();
        }
      }
      n.getValueLabel().setText(this.text);
    }
  }

  public void setActive(boolean b) {
    active = b;
    if (active) {
      n.getValueLabel().setText("");
      text = "";
    }
  }

  public void submit() {
    if (!text.isEmpty()) {
      n.setValue(PApplet.parseInt(text));
      text = "";
    } else {
      n.getValueLabel().setText(""+PApplet.parseInt(n.getValue()));
    }
  }
}
class Profile {
  String name; // profile name
  float[] parm; // ffb setting parameter
  int[] pMin = new int[num_axis-1]; // pedal min calibration limit
  int[] pMax = new int[num_axis-1]; // pedal max calibration limit
  int[] xyshCfg = new int[6]; // xy shifter calibration and config
  String pedalCalCfg, shifterCalCfg; // pedals and shifter calibration data packed into a string
  String[] contents = new String[num_prfset+1]; // we keep settings in each line of profile txt file, where 1st is profile name

  Profile(String n, float[] p, String pcfg, String scfg) {
    this.name = n;
    this.parm = p;
    this.pedalCalCfg = pcfg;
    this.shifterCalCfg = scfg;
    this.toContents();
  }

  public void upload() { // upload last FFB settings from GUI to a profile
    for (int i=0; i<num_sldr; i++) {
      this.parm[i] = wParmFFBprev[i];
    }
    this.parm[num_sldr] = PApplet.parseInt(effstateprev);
    this.parm[num_sldr+1] = maxTorque;
    this.parm[num_sldr+2] = lastCPR;
    this.parm[num_sldr+3] = PApplet.parseInt(pwmstateprev);
    // pack pedals and shifter calibration settings from GUI
    // if firmware doesn't support it, pack the default values
    packPedalCal();
    packShifterCal();
    this.toContents();
    println(this.name, "uploaded");
  }

  public void download() {  // download profile to current FFB settings in GUI
    //this.fromContents();
    for (int i=0; i<num_sldr; i++) {
      wParmFFB[i] = this.parm[i];
    }
    effstate = PApplet.parseByte(PApplet.parseInt(this.parm[num_sldr]));
    //maxTorque = int(parm[num_sldr+1]);  // do not load maxTorque from profiles
    curCPR = PApplet.parseInt(this.parm[num_sldr+2]);
    //pwmstate = byte(int(parm[num_sldr+3])); // do not load pwmstate from profiles
    // unpack pedals and shifter calibration from profile (applied to arduino only if firmware supports it)
    unpackPedalCal();
    unpackShifterCal();
    println(this.name, "downloaded");
  }

  public void loadFromFile(String fn) {
    this.contents = loadStrings(fn+".txt");
    this.fromContents();
  }

  public void storeToFile(String fn) {
    String tempStr = "";
    int result = -1;
    if (this.name.equals("default")) {
      showMessageDialog(frame, "Can not be modified.\nSelect another profile.");
    } else {
      tempStr = showInputDialog("Save profile name as?", this.name);
      if (tempStr != null) {
        this.name = tempStr;
        cp5.get(ScrollableList.class, "profile").setItems(ProfileNameList());
        if (nameExists(this.name)) { // if this profile name arleady exists
          result = showConfirmDialog(frame, "Name already exists.\nOverwrite?");
        } 
        if (result == YES_OPTION || result == -1) {
          upload();
          saveStrings("/data/"+fn+".txt", contents);
          println(this.name, "saved as "+fn+".txt");
        }
      }
    }
  }

  public String getPrfParm(int iProfile, int iParm) { // retrieve certain parameter from a given profile
    String profileContents[] = new String[num_profiles];
    profileContents = loadStrings("profile"+str(iProfile)+".txt");
    if (profileContents == null) {
      return null;
    } else {
      return profileContents[iParm];
    }
  }

  public boolean nameExists(String cName) { // returns true if profile with this name already exists
    String pName;
    boolean c = false;
    for (int i=1; i<num_profiles; i++) { // look through all found profiles
      File p = new File(dataPath("profile"+str(i)+".txt"));
      if (p.exists()) {
        pName = getPrfParm(i, 0);
        if (pName.equals(cName)) {
          c = true;
        }
      }
    }
    return c;
  }

  public boolean exists(int i) {
    boolean r = false;
    File p = new File(dataPath("profile"+str(i)+".txt"));
    if (p.exists()) {
      r = true;
    }
    return r;
  }

  public boolean isEmpty() {
    this.fromContents();
    boolean e = true;
    for (int i=0; i<num_sldr; i++) {
      if (parm[i] != 0.0f) e = false; // at least 1 slider value has to be non-zero
    }
    return e;
  }

  public void fromContents() {
    for (int j=0; j<num_prfset+1; j++) {
      if (j == 0) {
        this.name = this.contents[j];
      } else if (j == 17) { // pedal calibration
        this.pedalCalCfg = this.contents[j];
      } else if (j == 18) { // shifter calibration
        this.shifterCalCfg = this.contents[j];
      } else {
        this.parm[j-1] = PApplet.parseFloat(this.contents[j]);
      }
    }
    //println(this.name, "fromContents");
  }

  public void toContents() {
    for (int k=0; k<num_prfset+1; k++) {
      if (k == 0) {
        this.contents[k] = this.name;
      } else if (k == 17) { // pedal calibration
        this.contents[k] = this.pedalCalCfg;
      } else if (k == 18) { // shifter calibration
        this.contents[k] = this.shifterCalCfg;
      } else {
        this.contents[k] = str(this.parm[k-1]);
      }
    }
    //println(this.name, "toContents");
  }

  public void packPedalCal() {
    this.pedalCalCfg = "";
    String[] axispCals = new String[4]; // individual pedal axis cal limits
    for (int i=0; i<axispCals.length; i++) {
      if (bitRead(fwOpt, 0) == 0) {  // if bit0=0 - pedal autocalibration is disabled in firmware, we have manual pedal calibration
        this.pMin[i] = PApplet.parseInt(pdlMinParm[i]);
        this.pMax[i] = PApplet.parseInt(pdlMaxParm[i]);
      } else { // otherwise pack default pedal calibration
        this.pMin[i] = PApplet.parseInt(pdlParmDef[2*i]);
        this.pMax[i] = PApplet.parseInt(pdlParmDef[2*i+1]);
      }
      if (i != 3) {
        axispCals[i] = str(this.pMin[i]) + ' ' + str(this.pMax[i]) + ' ';
      } else {
        axispCals[i] = str(this.pMin[i]) + ' ' + str(this.pMax[i]); // do not add space at end of string
      }
      this.pedalCalCfg += axispCals[i];
    }
  }
  public void unpackPedalCal() {
    int[] axispCals = PApplet.parseInt(split(this.pedalCalCfg, ' '));
    for (int j=0; j<(axispCals.length)/2; j++) {
      this.pMin[j] = axispCals[2*j]; // even
      this.pMax[j] = axispCals[2*j+1]; // odd
    }
  }
  public void packShifterCal() {
    this.shifterCalCfg = "";
    for (int i=0; i<shifterLastConfig.length; i++) {
      if (XYshifterEnabled) { // if firmware supports xy shifter
        this.xyshCfg[i] = shifterLastConfig[i];
      } else { // otherwise pack default shifter calibration
        this.xyshCfg[i] = xysParmDef[i];
      }
      if (i != 5) {
        this.shifterCalCfg += str(this.xyshCfg[i]) + ' ';
      } else {
        this.shifterCalCfg += str(this.xyshCfg[i]);
      }
    }
  }
  public void unpackShifterCal() {
    int[] xyshCals = PApplet.parseInt(split(this.shifterCalCfg, ' '));
    for (int j=0; j<xyshCals.length; j++) {
      this.xyshCfg[j] = xyshCals[j];
    }
  }
  // returns true if profile vales are different
  public boolean checkPedalCfg() { // checks if any pedal cal parm form profile is different than curent pedal config
    boolean check = false;
    for (int i=0; i<pdlMinParm.length; i++) {
      if (this.pMin[i] != PApplet.parseInt(pdlMinParm[i]) || this.pMax[i] != PApplet.parseInt(pdlMaxParm[i])) check = true;
    }
    return check;
  }
  // returns true if profile vales are different
  public boolean checkShifterCfg() { // checks if any shifter cal parm form profile is different than curent shifter config 
    boolean check = false;
    for (int i=0; i<shifterLastConfig.length; i++) {
      if (this.xyshCfg[i] != shifterLastConfig[i]) check = true;
    }
    return check;
  }

  public void show() {
    for (int i=0; i<this.contents.length; i++) {
      println(this.contents[i]);
    }
  }
}
class Wheel {
  float x, jx;
  float y, jy;
  float sx, sy;
  String wl;
  float rotRad, rotDeg;

  Wheel(float posx, float posy, float sizex, float sizey, String wLabel) {
    x = posx;
    y = posy;
    sx = sizex;
    sy = sizey;
    wl = wLabel;
  }

  public void updateWheel(float angle, boolean resize) {
    if (resize) {
      x = 0.123f*widthprev;
      y = 0.223f*heightprev;
      sx = min(wScaleX, wScaleY)*axisHeight_init*0.95f;
      sy = sx;
    }
    rotDeg = angle; // wheel angle in degrees
    rotRad = rotDeg/180.0f*PI; // wheel angle in radians
  }

  public void updateJoy(float jxpos, float jypos, boolean resize) {
    if (resize) {
      x = 0.123f*widthprev;
      y = 0.223f*heightprev;
      sx = wScaleX*axisHeight_init*0.8f;
      sy = wScaleY*axisHeight_init*0.8f;
    }
    jx = jxpos;
    jy = jypos;
  }

  public void showJoy() {
    float fx = PApplet.parseFloat(ffbx) / PApplet.parseFloat(maxTorque);
    float fy = PApplet.parseFloat(ffby) / PApplet.parseFloat(maxTorque);
    float fmag = sqrt(fx*fx + fy*fy);
    float dLx = sx/25;
    float dLy = sy/25;
    int n = 20; // number of axis ticks
    int nl = 4; // tick length
    float pnx = sx / PApplet.parseFloat(n); // tick pos
    float pny = sy / PApplet.parseFloat(n);
    String al = "-axis";
    pushMatrix();
    stroke(255, 200);
    strokeWeight(1);
    translate(x, y);
    noFill();
    rect(-sx/2, -sy/2, sx, sy);
    strokeWeight(1);
    stroke(255, 100);
    line(-sx/2, 0, sx/2, 0); // horizontal axis
    for (int i = 0; i <= n; i++) {
      line (-nl/2, i*pny-sy/2, nl/2, i*pny-sy/2); // horizontal axis ticks
    }
    String xl = "x"; // x-axis label (configurable by xFFB-axis selector)
    if (xFFBAxisIndex == 1) {
      xl = "y";
    } else if (xFFBAxisIndex == 2) {
      xl = "z";
    } else if (xFFBAxisIndex == 3) {
      xl = "rx";
    } else if (xFFBAxisIndex == 4) {
      xl = "ry";
    }
    textAlign(RIGHT);
    fill(255, 150);
    text(xl+al, sx/2-2, -dLx/2); // horizontal axis label
    textAlign(LEFT);
    pushMatrix();
    rotate(PI/2);
    line(-sy/2, 0, sy/2, 0); // vertcal axis
    for (int i = 0; i <= n; i++) {
      line (-nl/2, i*pnx-sx/2, nl/2, i*pnx-sx/2); // vertical axis ticks
    }
    String yl = "y"; // y-axis label (not configurable)
    text(yl+al, -sy/2+2, -dLy/2); // vertical axis label
    popMatrix();
    fill(32, 255, 255);
    noStroke();
    //ellipse(jx*s/2, -jy*s/2, dL/2, dL/2); // joystick xy pos (dot)
    pushMatrix();
    translate(jx*sx/2, -jy*sy/2);
    stroke(32, 255, 255);
    line(-dLx, 0, dLx, 0);  // joystick xy pos (cross) horisontal part
    line(0, -dLy, 0, dLy);  // joystick xy pos (cross) vertical part
    popMatrix();
    stroke(map(abs(fmag), 0, 1, 145, 0), 255, 255);
    strokeWeight(3);
    if (buttonpressed[7]) line(0, 0, fx*sx/2, -fy*sy/2); // XY ffb line
    popMatrix();
  }

  public void showWheel() {
    pushMatrix();
    stroke(255);
    strokeWeight(1);
    translate(x, y);
    pushMatrix();
    //textSize(16);
    //fill(255);
    //text(wl, -22, -axisHeight/2-16);
    textSize(font_size);
    popMatrix();
    rotate(rotRad);
    ellipseMode(CENTER);
    noFill();
    float wd = 0.85f;
    ellipse(0, 0, sx, sy); // wheel rim outer
    ellipse(0, 0, wd*sx, wd*sy); // wheel rim inner
    rectMode(CENTER);
    rect(0, 0, wd*sx, sy/8); // cross bar
    rectMode(CORNER);
    rect(-sx/16, sy/16, sx/8, sy/2-(1-wd)*sy); // botom bar
    fill(255);
    rect(-sx/32, -sy/2, sx/16, (1-wd)/2*sy); // center stripe
    popMatrix();
  }

  public void showWheelDeg() {
    pushMatrix();
    fill(255);
    translate(0.123f*widthprev + (wScaleX*axisHeight_init*0.8f)/2, 0.223f*heightprev + (wScaleY*axisHeight_init*0.8f)/2 + 2*buttons[0].sy);
    text(formatText(rotDeg)+"°", 0, 0);
    popMatrix();
  }

  public void showJoyPos() {
    String jxs = formatText(jx*100.0f); // joy x-axis pos in percents
    String jys = formatText(jy*100.0f); // joy x-axis pos in percents
    String jxys = jxs +", "+ jys;
    pushMatrix();
    fill(255);
    translate(x, y);
    text(jxys+"%", axisHeight/2-25, axisHeight/2+8);
    popMatrix();
  }

  public String formatText(float inp) {
    String out;
    int len = str(inp).length();
    if (inp > 0.0f) { // positive values
      if (inp < 10.0f) { //0-9.9
        out = str(inp).substring(0, 4);
      } else {  // >=10
        if (len > 4) {
          out = str(inp).substring(0, 5);
        } else {
          out = str(inp)+"0";
        }
      }
    } else { // negative values
      if (inp < -10.0f) {
        if (len > 5) {
          out = str(inp).substring(0, 6);
        } else {
          out = str(inp)+"0";
        }
      } else { // >=-10
        out = str(inp).substring(0, 5);
      }
    }
    return out;
  }
}
class XYshifter {
  float x, y, s, sd, dx, dy, lx, ly;
  float shX, shY;
  float sCal[] = new float[5];
  byte sConfig;
  int gear;
  int revGearBit;
  xyCal[] xycals = new xyCal[5];

  XYshifter(float posx, float posy, float scale) {
    x = posx;
    y = posy;
    s = scale;
    dx = s*1023.0f;
    dy = s*1023.0f;
    lx = dx/25.5f;
    ly = dy/25.5f;
    sd = lx;
    revGearBit = 0;
    xycals[0] = new xyCal(x, y-ly-2, lx, ly, 0, "a");
    xycals[1] = new xyCal(x, y+ly+2+dy, lx, ly, 2, "b");
    xycals[2] = new xyCal(x, y-ly-2, lx, ly, 0, "c");
    xycals[3] = new xyCal(x+dx+lx+2, y, lx, ly, 1, "d");
    xycals[4] = new xyCal(x+0*dx-lx-2, y, lx, ly, 3, "e");
  }
  public void update (boolean resize) {
    if (resize) {
      x = widthprev/3.65f-shXoff-5*wScaleX;
      y = 0.06f*heightprev;
      s = min(wScaleX, wScaleY)*shScale_init;
      dx = s*1023.0f;
      dy = s*1023.0f; 
      lx = dx/25.5f;
      ly = dy/25.5f;
      sd = lx;
      xycals[0].x = convertToxycals(0);
      xycals[0].y = y-ly-2;
      xycals[0].sx = lx;
      xycals[0].sy = ly;
      xycals[1].x = convertToxycals(1);
      xycals[1].y = y+ly+2+dy;
      xycals[1].sx = lx;
      xycals[1].sy = ly;
      xycals[2].x = convertToxycals(2);
      xycals[2].y = y-ly-2;
      xycals[2].sx = lx;
      xycals[2].sy = ly;
      xycals[3].x = x+dx+lx+2;
      xycals[3].y = convertToxycals(3);
      xycals[3].sx = lx;
      xycals[3].sy = ly;
      xycals[4].x = x+0*dx-lx-2;
      xycals[4].y = convertToxycals(4);
      xycals[4].sx = lx;
      xycals[4].sy = ly;
    }
  }
  public void updatePos() { // update shifter xy position form arduino read buffer string
    int[] temp = PApplet.parseInt(split(rb, ' '));
    shX = temp[0];
    shY = temp[1];
  }
  public void updateCal(String calibration) { // update shifter calibration form arduino string
    float[] temp = PApplet.parseFloat(split(calibration, ' '));
    for (int i=0; i<xycals.length; i++) {
      sCal[i] = temp[i]; // update cal values
      if (i < 3) {
        xycals[i].x = convertToxycals(i); // update scaled x cal values
      } else {
        xycals[i].y = convertToxycals(i); // update scaled x cal values
      }
      updatexycalsLimit(i); // update scaled cal limits
    }
    sConfig = PApplet.parseByte(temp[5]);
    //println(str(sCal[0])+" "+str(sCal[1])+" "+str(sCal[2])+" "+str(sCal[3])+" "+str(sCal[4])); // show shifter calibration parameters
    //println(str(xycals[0].x)+" "+str(xycals[1].x)+" "+str(xycals[2].x)+" "+str(xycals[3].y)+" "+str(xycals[4].y)); // show shifter scaled calibration parameters
  }
  public float convertToxycals(int i) {
    float temp = 0;
    float k = sCal[i]/1023.0f;
    if (i < 3) {
      temp = x + k*dx; // a, b, c
    } else {
      temp = y + (1-k)*dy; // d, e
    }
    return temp;
  }
  public float convertsCalFromxycals(int i) { // convert scaled cal values into cal values
    float temp;
    if (i < 3) {
      temp = (xycals[i].x-x)/s;
    } else {
      temp = 1023.0f-(xycals[i].y-y)/s;
    }
    return temp;
  }
  public void getxycals(int i) { // get xycal value from mouse position
    if (i < 3) {
      xycals[i].x = mouseX; // update cal x position
    } else {
      xycals[i].y = mouseY; // update cal y position
    }
    updatexycalsLimit(i); // update cal limits
    checkxycalsLimit(i); // constrain cal values to limits
  }
  public int getGear(boolean showGear) { // return the curent shifter gear (0 is neutral, -1 is reverse)
    int g;
    float sx, sy;
    sx = x + shX/1023.0f*dx;
    sy = y +(1-shY/1023.0f)*dy;
    pushMatrix();
    noStroke();
    fill(255, 63);
    if (sx < xycals[0].x && sy < xycals[4].y) { // 1st gear
      g = 1;
      if (showGear) {
        rect(1, 1-dy, xycals[0].x-x-2, xycals[4].y-y-2);
        fill(255);
        translate(-font_size/3, font_size/3);
        text(1, (xycals[0].x-x)/2, (xycals[4].y-y)/2-dy);
      }
    } else if (sx < xycals[0].x && sy >= xycals[3].y) { // 2nd gear
      g = 2;
      if (showGear) {
        rect(1, -2, xycals[0].x-x-2, xycals[3].y-y-dy+4);
        fill(255);
        translate(-font_size/3, font_size/3);
        text(2, (xycals[0].x-x)/2, (xycals[3].y-y-dy)/2);
      }
    } else if (sx >= xycals[0].x && sx < xycals[1].x && sy < xycals[4].y) { // 3rd gear
      g = 3;
      if (showGear) {
        rect(xycals[0].x-x+2, 1-dy, xycals[1].x-xycals[0].x-3, xycals[4].y-y-2);
        fill(255);
        translate(-font_size/3, font_size/3);
        text(3, (xycals[1].x-xycals[0].x)/2+xycals[0].x-x, (xycals[4].y-y)/2-dy);
      }
    } else if (sx >= xycals[0].x && sx < xycals[1].x && sy >= xycals[3].y) { // 4th gear
      g = 4;
      if (showGear) {
        rect(xycals[0].x-x+2, -2, xycals[1].x-xycals[0].x-3, xycals[3].y-y-dy+4);
        fill(255);
        translate(-font_size/3, font_size/3);
        text(4, (xycals[1].x-xycals[0].x)/2+xycals[0].x-x, (xycals[3].y-y-dy)/2);
      }
    } else if (sx >= xycals[1].x && sx < xycals[2].x && sy < xycals[4].y) { // 5th gear
      g = 5;
      if (showGear) {
        rect(xycals[1].x-x+2, 1-dy, xycals[2].x-xycals[1].x-3, xycals[4].y-y-2);
        fill(255);
        translate(-font_size/3, font_size/3);
        text(5, (xycals[2].x-xycals[1].x)/2+xycals[1].x-x, (xycals[4].y-y)/2-dy);
      }
    } else if (sx >= xycals[1].x && sx < xycals[2].x && sy >= xycals[3].y) { // 6th gear
      g = 6;
      if (showGear) {
        rect(xycals[1].x-x+2, -2, xycals[2].x-xycals[1].x-3, xycals[3].y-y-dy+4);
        fill(255);
        String gr;
        if (Button[revGearBit] && bitRead(sConfig, 1) == 0) { // if bit1 of sConfig is LOW - 6 gear mode
          gr = "r";
        } else {
          gr = "6";
        }
        translate(-font_size/3, font_size/3);
        text(gr, (xycals[2].x-xycals[1].x)/2+xycals[1].x-x, (xycals[3].y-y-dy)/2);
      }
    } else if (sx >= xycals[2].x && sy < xycals[4].y) { // 7th gear
      g = 7;
      if (showGear) {
        rect(xycals[2].x-x+2, 1-dy, dx+x-xycals[2].x-2, xycals[4].y-y-2);
        fill(255);
        translate(-font_size/3, font_size/3);
        text(7, dx-(x+dx-xycals[2].x)/2, (xycals[4].y-y)/2-dy);
      }
    } else if (sx >= xycals[2].x && sy >= xycals[3].y) { // 8th gear
      g = 8;
      if (showGear) {
        rect(xycals[2].x-x+2, -2, dx+x-xycals[2].x-2, xycals[3].y-y-dy+4);
        fill(255);
        String gr;
        if (Button[revGearBit] && bitRead(sConfig, 1) == 1) {  // if bit1 of sConfig is HIGH - 8 gear mode
          gr = "r";
        } else {
          gr = "8";
        }
        translate(-font_size/3, font_size/3);
        text(gr, dx-(x+dx-xycals[2].x)/2, (xycals[3].y-y-dy)/2);
      }
    } else {
      g = 0;
      if (showGear) {
        //rect(0, 0, 0, 0);
        //fill(255);
      }
    }
    popMatrix();
    return g;
  }
  public void setCal() { // get shifter calibration from wheel control
    for (int i=0; i<xycals.length; i++) {
      if (xycals[i].changing) {
        getxycals(i);
        sCal[i] = convertsCalFromxycals(i);
        /*if (i < 3) {
         println(str(xycals[i].limits[0])+" "+xycals[i].t +"="+str(xycals[i].x)+" "+str(xycals[i].limits[1])); // x limits for xycals
         } else {
         println(str(xycals[i].limits[2])+" "+xycals[i].t +"="+str(xycals[i].y)+" "+str(xycals[i].limits[3])); // y limits for xycals
         }*/
      }
    }
    //println(str(sCal[0])+" "+str(sCal[1])+" "+str(sCal[2])+" "+str(sCal[3])+" "+str(sCal[4])); // show shifter calibration parameters
    //println(str(xycals[0].x)+" "+str(xycals[1].x)+" "+str(xycals[2].x)+" "+str(xycals[3].y)+" "+str(xycals[4].y)); // show shifter scaled calibration parameters
  }
  public void show() {
    pushMatrix();
    noStroke();
    translate(x, y+dy);
    fill(51);
    rect(-0.025f*dx, 0.09f*dy, dx*1.15f, -dy*1.18f); // shifter background
    stroke(255);
    strokeWeight(1);
    noFill();
    rect(0, 0, dx, -dy); // shifter zone
    fill(255);
    String sName = "Analog XY H-shifter";
    text(sName, dx-textWidth(sName), font_size);
    noStroke();
    fill(32, 255, 255);
    ellipse(shX/1023.0f*dx, -shY/1023.0f*dy, sd/2, sd/2); // current shifter position
    getGear(true);
    popMatrix();
    for (int j=0; j<xycals.length; j++) {
      xycals[j].updateColors(ctrl_btn+j);
      xycals[j].showPointer(dx, dy);
    }
  }

  public void updatexycalsLimit(int i) { // update shifter calibration values in the scaled units for displaying shifter
    if (i == 0) {
      xycals[i].limits[0]= x + lx/2; // a low limit is 0
      xycals[i].limits[1]= xycals[i+1].x - lx/2; // a high limit is b
    }
    if (i == 1) {
      xycals[i].limits[0] = xycals[i-1].x + lx/2; // b low limit is a
      xycals[i].limits[1] = xycals[i+1].x - lx/2; // b high limit is c
    }
    if (i == 2) {
      xycals[i].limits[0] = xycals[i-1].x + lx/2; // c low limit is b
      xycals[i].limits[1] = x+dx - lx/2; // c high limit is dx
    }
    if (i == 3) {
      xycals[i].limits[2] = xycals[i+1].y + ly/2; // d low limit is e
      xycals[i].limits[3] = y+dy - ly/2; // d high limit is dy
    }
    if (i == 4) {
      xycals[i].limits[2] = y + ly/2; // e low limit is 0
      xycals[i].limits[3] = xycals[i-1].y - ly/2; // e high limit is d
    }
  }
  public void checkxycalsLimit(int i) { // checks if scaled cal values are withing limits and limit them if they are not
    if (i < 3) {
      if (xycals[i].x <= xycals[i].limits[0]) {
        xycals[i].x = xycals[i].limits[0];
      } else if (xycals[i].x > xycals[i].limits[1]) {
        xycals[i].x = xycals[i].limits[1];
      }
    } else {
      if (xycals[i].y <= xycals[i].limits[2]) {
        xycals[i].y = xycals[i].limits[2];
      } else if (xycals[i].y > xycals[i].limits[3]) {
        xycals[i].y = xycals[i].limits[3];
      }
    }
  }
}
class xyCal {
  float x, y, sx, sy;
  float[] limits = new float [4];
  boolean active, changing, grabed;
  int orn;
  String t;

  xyCal(float posx, float posy, float xsize, float ysize, int orientation, String text) {
    x = posx;
    y = posy;
    sx = xsize;
    sy = ysize;
    t = text;
    active = true;
    changing = false;
    grabed = false;
    orn = orientation; // 0-top, 1-right, 2-bottom, 3-left
  }

  public void updateColors(int i) {
    if (active) {
      if (mouseX >= x-sx/2 && mouseX <= x+sx/2 && mouseY >= y-sy/2 && mouseY <= y+sy/2) { // if mouse pointer is howered over
        controlb[i] = true;
      } else {
        controlb[i] = false;
      }
      if (controlb[i] && mousePressed) { // green with black text (activated)
        col[0] = 96;
        col[1] = 200;
        col[2] = 150;
        thue = 0;
        changing = true;
      } else if (controlb[i] && !mousePressed) { // yellow with white text (howered)
        col[0] = 40;
        col[1] = 200;
        col[2] = 180;
        thue = 255;
        changing = false;
      } else if (!controlb[i] || !grabed) { // red with white text (deactivated)
        col[0] = 0;
        col[1] = 200;
        col[2] = 150;
        thue = 255;
        changing = false;
      } 
    } else {
      col[0] = 0;
      col[1] = 0;
      col[2] = 100;
      thue = 255;
    }
  }

  public void showPointer(float dx, float dy) {
    float yoffs = sy+2; // pointer y offset
    pushMatrix();
    fill(col[0], col[1], col[2]);
    strokeWeight(1);
    stroke(255);
    if (orn == 0) {
      translate(x, y);
    } else if (orn == 1) {
      translate(x, y);
    } else if (orn == 2) {
      translate(x, y);
    } else if (orn == 3) {
      translate(x, y);
    }
    rotate(PApplet.parseFloat(orn)/2.0f*PI);
    beginShape();
    vertex(-sx/2, -sy/2);
    vertex(sx/2, -sy/2);
    vertex(sx/2, sy/2);
    vertex(0, sy);
    vertex(-sx/2, sy/2);
    vertex(-sx/2, -sy/2);
    endShape();
    textSize(font_size);
    if (sx < font_size) textSize(sx);
    fill(thue);
    stroke(150);
    if (orn == 0) {
      text(t, -sx/2, sy/2);
      pushMatrix();
      translate(0, yoffs);
      line(0, 1, 0, dy-1);
      popMatrix();
    } else if (orn == 1) {
      pushMatrix();
      rotate(-PApplet.parseFloat(orn)/2.0f*PI);
      translate(-yoffs, 0);
      text(t, sx, sy/2);
      line(-dx+1, 0, -1, 0);
      popMatrix();
    } else if (orn == 2) {
      pushMatrix();
      translate(0, yoffs);
      line(0, 1, 0, dy-1);
      rotate(-PApplet.parseFloat(orn)/2.0f*PI);
      text(t, -sx/2, 1.5f*sy);
      popMatrix();
    } else if (orn == 3) {
      pushMatrix();
      rotate(-PApplet.parseFloat(orn)/2.0f*PI);
      text(t, -sx/2, 0.35f*sy);
      translate(dx+yoffs, 0);
      line(-dx+1, 0, -1, 0);
      popMatrix();
    }
    popMatrix();
    textSize(font_size);
  }
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "wheel_control" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
