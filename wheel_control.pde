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
int cntl_btn = 11; //number of controll buttons
int key_btn = 11;  //number of keyboard function buttons
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
boolean moved = false; // keep track if wheel axis is used
float prevaxis = 0.0; // previous steer axis value 
int[] col = new int[3]; // colors for control buttons, hsb mode
int thue; // color for text of control button, gray scale mode
boolean[] buttonpressed = new boolean[cntl_btn]; // true if button is pressed
String[] description = new String[key_btn]; // keyboard button function description
String[] keys = new String[key_btn]; // keyboard buttons
boolean enableinfo = true;
byte effstate, effstateprev, effstatedef; // current, previous and default desktop effect state in binary form
byte pwmstate, pwmstateprev, pwmstatedef; // current, previous and default pwm settings in binary form
boolean typepwm, modepwm; // keeps track of PWM settings
int freqpwm; // keeps track of PWM frequency index selection
int minTorque, maxTorque, maxTorquedef; // min, max ffb value or PWM steps
int curCPR, lastCPR, CPRdef;
float deg_min = 30.0;
float deg_max = 1800.0;
float minPWM_max = 20.0;
float brake_min = 1.0;
float brake_max = 255.0;
boolean fbmnstp = false; // keeps track if we deactivated ffb monitor
String fbmnstring; // string from ffb monitor readout
String COMport[]; // string for serial port on which Arduino Leonardo is reported
String fwVersion; // Arduino firmware version
boolean LCenabled = false; // keeps track if load cell is enabled (3 digit fw's ending with 2)
boolean checkFwVer = true; // when enabled update fwVersion will take place
boolean enabledac, modedac; // keeps track of DAC settings
boolean profileActuated = false; // keeps track if we pressed the profile selection
boolean CPRlimit = false; // true if we input more than max allowed CPR

GImageToggleButton[] btnToggle = new GImageToggleButton[2];

ControlIO control;
Configuration config;
ControlDevice gpad; 

// gamepad axis array
float[] Axis = new float[5];
float axisValue;
float scaledValue;
// gamepad button array
boolean[] Button = new boolean [num_btn];
boolean buttonValue = false;
// gamepad D-pad
int[] Dpad = new int[8];
int hatvalue;
// control buttons
boolean[] controlb = new boolean[cntl_btn]; // true as long as mouse is howered over

PFont font;
int font_size = 12;

int scale = 250; // length of axis ruler scale
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

Wheel[] wheels = new Wheel [1];
Slajder[] slajderi = new Slajder[5];
Dugme[] dugmici = new Dugme[num_btn];
//HatSW[] hatsw = new HatSW[1];
//Graph[] graphs = new Graph [1];
Dialog[] dialogs = new Dialog [1];
Button[] buttons = new Button[cntl_btn];
Info[] infos = new Info[key_btn];
FFBgraph[] ffbgraphs = new FFBgraph[1];
Profile[] profiles = new Profile[num_profiles];

void setup() {
  size(1440, 800, JAVA2D);
  colorMode (HSB);
  //frameRate(120);
  font = createFont("Arial", 16, true);
  textSize(font_size);
  File f = new File(dataPath("COM_cfg.txt"));
  if (!f.exists()) showMessageDialog(frame, "Setup will now try to look for IO instances.", "Step 1/3", INFORMATION_MESSAGE);
  // Initialise the ControlIO
  control = ControlIO.getInstance(this);
  println("Instance:", control);
  // Find a device that matches the configuration file
  if (!f.exists()) showMessageDialog(frame, "Setup will now try to get devices.\n", "Step 2/3", INFORMATION_MESSAGE);
  gpad = control.getMatchedDevice("Arduino Leonardo wheel v4");
  if (gpad == null) {
    println("No suitable device configured");
    System.exit(-1); // End the program NOW!
  } else {
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

  // Open whatever port is the one you're using.
  //String portName = Serial.list()[2]; //change the 0 to a 1 or 2 etc. to match your port
  //myPort = new Serial(this, portName, 115200);
  //myPort = new Serial(this, "COM5", 115200);

  posY = height - (2.2*scale);

  // Create the sprites
  Domain domain = new Domain(1440, 800, width, height);
  sprite[0] = new Sprite(this, "TX_wheel_rim_small_alpha.png", 10);
  //sprite[0] = new Sprite(this, "599XXEVO30_alpha_small.png", 10);
  sprite[0].setVelXY(0, 0);
  sprite[0].setXY(0.05*width+0.5*scale, posY-80);
  sprite[0].setDomain(domain, Sprite.REBOUND);
  sprite[0].respondToMouse(false);
  sprite[0].setZorder(20);

  //for (int i = 0; i < wheels.length; i++) {
  wheels[0] = new Wheel(0.05*width+0.5*scale, posY-80, scale*0.9, str(frameRate));
  //wheels[1] = new Wheel(width/2+1.8*scale, height/2, scale*0.9, "LFS car's wheel Y");
  //}
  slajderi[0] = new Slajder(0*48, width/3.65 + 0*60, height-posY, 10, 65535, "X");
  slajderi[1] = new Slajder(1*48, width/3.65 + 1*60, height-posY, 10, 4095, "Y");
  slajderi[2] = new Slajder(2*48, width/3.65 + 2*60, height-posY, 10, 4095, "Z");
  slajderi[3] = new Slajder(3*48, width/3.65 + 3*60, height-posY, 10, 4095, "RX");
  slajderi[4] = new Slajder(4*48, width/3.65 + 4*60, height-posY, 10, 4095, "RY");

  for (int j = 0; j < dugmici.length; j++) { // wheel buttons
    if (j <=7) {
      dugmici[j] = new Dugme(0.05*width +j*28, height-posY*1.85, 18);
    } else if (j>7 && j<16) {
      dugmici[j] = new Dugme(0.05*width +(j-8)*28, height-posY*1.85+28, 18);
    } else if (j>15 && j<24) {
      dugmici[j] = new Dugme(0.05*width +(j-16)*28, height-posY*1.85+2*28, 18);
    }
  }

  dialogs[0] = new Dialog(0.05*width, height-posY*1.85+3*28, 16, "waiting input..");

  int Xoffset = -44;

  // general control buttons
  buttons[0] = new Button(0.05*width + 3.5*60, height-posY-270, 50, 16, "center");
  buttons[1] = new Button(Xoffset+width/2 + 6.35*60, height-posY+140, 50, 16, "default");
  buttons[2] = new Button(width/3.7 + 2*60, height-posY+31, 50, 16, "recalib");
  buttons[8] = new Button(Xoffset+width/2 + 7.6*60, height-posY+140, 38, 16, "save");
  buttons[9] = new Button(Xoffset+width/2 + 5.3*60, height-posY+140, 38, 16, "pwm");
  buttons[10] = new Button(Xoffset+width/2 + 10.04*60, height-posY+140, 38, 16, "store");

  // optional ffb effect on/off buttons
  buttons[3] = new Button(sldXoff+width/2+slider_width+60, slider_height/2*(1+8)-12, 16, 16, " ");
  buttons[4] = new Button(sldXoff+width/2+slider_width+60, slider_height/2*(1+2)-12, 16, 16, " ");
  buttons[5] = new Button(sldXoff+width/2+slider_width+60, slider_height/2*(1+7)-12, 16, 16, " ");
  buttons[6] = new Button(sldXoff+width/2+slider_width+60, slider_height/2*(1+3)-12, 16, 16, " ");
  buttons[7] = new Button(sldXoff+width/2+slider_width+60, slider_height/2*(1+1)-12, 16, 16, " ");

  //keys
  keys[0] = "r";
  keys[1] = "c";
  keys[2] = "p";
  keys[3] = "u";
  keys[4] = "v";
  keys[5] = "d";
  keys[6] = "b";
  keys[7] = "s";
  keys[8] = "+";
  keys[9] = "-";
  keys[10] = "i";

  description[0] = "read wheel buffer";
  description[1] = "center wheel";
  description[2] = "reset pedal calibration";
  description[3] = "show wheel parameters";
  description[4] = "show wheel version";
  description[5] = "load FFB defaults";
  description[6] = "calibrate wheel";
  description[7] = "show wheel state";
  description[8] = "change rotation by +1deg";
  description[9] = "change rotation by -1deg";
  description[10] = "show/hide information";

  for (int n = 0; n < infos.length; n++) {
    infos[n] = new Info(0.05*width, height-posY*1.85+4*28+2*n*font_size, font_size, description[n], keys[n]);
  }

  /*for (int k = 0; k < hatsw.length; k++) {
   hatsw[k] = new HatSW(0.89*width, height-posY - 12*28, 16, 64);
   }
   for (int i = 0; i < graphs.length; i++) {
   graphs[i] = new Graph(width/2, height/2, scale*2, 3);
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
    // required because they are setting the default value. 
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

  // commands for adjusting wheel FFB parameters
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

  //btnToggle[0] = new GImageToggleButton(this, 10+1*(slider_width+20), slider_height/2+20);
  //btnToggle[1] = new GImageToggleButton(this, 10+3*(slider_width+20), slider_height/2+20);

  refreshWheelParm(); // update all wheel FFB parms
  for (int i=0; i < wParmFFB.length; i++) {
    setSliderToParm(i); // update sliders with new wheel FFB parms
  }

  readFwVersion(); // read wheel firmware version
  if (!LCenabled) {
    sliderlabel[11] = "FFB balance L/R";
    defParmFFB[11] = 128.0;
  }

  //FFB graph
  ffbgraphs[0] = new FFBgraph(width-1, height-1-gbuffer/gskip, width-1, 1);

  // create number box object
  cp5 = new ControlP5(this);
  num1 = cp5.addNumberbox("CPR")
    .setSize(45, 18)
    .setPosition(int(width/3.65) - 15 +  0.0*60, height-posY+30)
    .setValue(lastCPR)
    ;               
  makeEditable(num1);

  cp5 = new ControlP5(this);
  List a = Arrays.asList("40.0 kHz", "20.0 kHz", "16.0kHz", "8.0 kHz", "4.0 kHz", "3.2 kHz", " 1.60 kHz", "976 Hz", "800 Hz", "488 Hz");
  List b = Arrays.asList("fast top", "phase corr");
  List c = Arrays.asList("pwm +-", "pwm+dir");
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
      .setPosition(Xoffset+int(width/3.5) - 15 + 9.3*60, height-posY+30+108)
      .setSize(66, 100)
      .setBarHeight(20)
      .setItemHeight(20)
      .addItems(a)
      //.setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST
      ;
    cp5.addScrollableList("pwmtype")
      .setPosition(Xoffset+int(width/3.5) - 15 + 7.0*60, height-posY+30+108)
      .setSize(66, 100)
      .setBarHeight(20)
      .setItemHeight(20)
      .addItems(b)
      //.setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST
      ;
    cp5.addScrollableList("pwmmode")
      .setPosition(Xoffset+int(width/3.5) - 15 + 8.2*60, height-posY+30+108)
      .setSize(60, 100)
      .setBarHeight(20)
      .setItemHeight(20)
      .addItems(c)
      //.setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST
      ;
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
  loadProfiles(); //check if exist and load profiles from txt
}

void draw() {
  background(51);
  drawWheelControll();
}

void drawWheelControll() {
  draw_labels();
  /*for (int j = 0; j < btnToggle.length; j++) {
   handleToggleButtonEvents(btnToggle[j], j);
   }*/
  for (int i = 0; i < slajderi.length; i++) {
    slajderi[i].update();
    axisValue = Axis[i];
    scaledValue = -scale+Axis[i]*scale;
    slajderi[i].show();
  }
  for (int j = 0; j < dugmici.length; j++) {
    dugmici[j].update();
    buttonValue = Button[j];
    dugmici[j].show(j);
  }
  /*for (int k = 0; k < hatsw.length; k++) {
   hatsw[k].update();
   hatsw[k].show();
   hatsw[k].showArrow();
   }*/
  wheels[0].update();
  axisValue = Axis[0]*wParmFFB[0]/2;
  //axisValue = sin(float(frameCount)/60.0*0.05*2.0*PI)*wParmFFB[0]/2; // testing
  wheels[0].showDeg(axisValue);

  if (!buttonpressed[7]) {
    S4P.updateSprites(1);
    S4P.drawSprites();
    sprite[0].setRot(axisValue/180*PI);
  }

  //wheels[0].show();

  //wheels[1].update();
  //axisValue = correct_axis(Axis[0]);
  //wheels[1].show();
  /*for (int i = 0; i < graphs.length; i++) {
   graphs[i].update();
   //graphs[i].show();
   }*/

  for (int k = 0; k < buttons.length; k++) {
    buttons[k].update(k);
    buttons[k].show();
  }
  for (int l = 0; l < infos.length; l++) {
    infos[l].show(enableinfo);
  }
  for (int m = 0; m < ffbgraphs.length; m++) {
    if (buttonpressed[7]) {
      for (int i=0; i<(gbuffer / frameRate)+1; i++) {
        String temprb = readString();
        if (temprb != "empty") {
          ffbgraphs[m].update(int(float(temprb)));
        }
      }
      ffbgraphs[m].show();
    } else {
      if (fbmnstp) { // read remaining serial read buffer content
        String temprb = "";
        for (int i=0; i<gskip; i++) {
          String tempString = readString();
          if (tempString != "empty") {
            temprb = rb;
            ffbgraphs[m].update(int(float(tempString)));
          }
        }
        ffbgraphs[m].show();
        rb = temprb; // restore read buffer
        fbmnstp = false;
      }
    }
  }
  if (buttonpressed[7]) {
    dialogs[0].update("WB: "+ wb + ", RB: " + fbmnstring);
  } else {
    dialogs[0].update("WB: "+ wb + ", RB: " + rb);
  }
  dialogs[0].show();
  text(round(frameRate)+" fps", font_size/3, font_size);
  if (CPRlimit) {
    num1.setValue(maxAllowedCPR(wParmFFBprev[0]));
    CPRlimit = false;
  }
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
  String label;
  fill(255);
  for (int j = 0; j < sdr.length; j++) {
    label = str(slider_value[j]);
    if (j == 0 || j == 11) { // only for rotation and brake pressure
      label=label.substring(0, label.length()-2);
    } else if (j == 10) { // only for min PWM
      if (slider_value[j] < 10.0 ) {
        label=label.substring(0, 3);
      } else {
        label=label.substring(0, 4);
      }
    } else {
      if (label.length() >= 4 ) {
        label=label.substring(0, 4);
      }
    }
    //textMode(TOP);
    text(sliderlabel[j], sldXoff+width/2-slider_width/3, slider_height/2*(1+j)); // slider label
    text(label, sldXoff+width/2+slider_width+20, slider_height/2*(1+j)); // slider value
  }
  //text("Couple with pysical wheel turn", 70+1*(slider_width+20), slider_height/2+50);
  //text("Decouple coefs", 70+3*(slider_width+20), slider_height/2+50);
  pushMatrix();
  translate(width/3.5, height-159);
  text("Arduino FFB Wheel", 0, 0);
  text("Control panel v1.9", 0, 20);
  text("Miloš Ranković 2018-2021", 0, 40);
  text("ranenbg@gmail.com", 0, 60);
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
  if ( myPort.available() > 0) 
  {  // If data is available,
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

void executeWR() {
  writeString(wb);
  //delay(21); // no longer needed since improved read functions
  // serial read period I've set in arduino is every 10ms
  for (int i = 0; i <=9999; i++) { // but just in case (calibration), we give arduino more time up to 10s   
    if (readString() == "empty") {
      delay(1);
    } else {
      break;
    }
  }
  fbmnstring = rb;
  println("WB:"+ wb + ", RB:" + rb);
}

void refreshWheelParm() {
  myPort.clear();
  writeString("U");
  println("Wheel parameters:");
  delay(60);
  UpdateWparms(readParmUntillEmpty());
  if (bitRead(effstate, 4) == 1) {  // if FFB monitor is ON
    bitWrite(effstate, 4, false); // turn it OFF
    updateEffstate();
    sendEffstate(); // send command to Arduino
  }
  //rb = " "; // do not clear rb
  for (int i=0; i < wParmFFB.length; i++) {
    wParmFFBprev[i] = wParmFFB[i];
    print(wParmFFB[i]);
    print(" ");
  }
  readEffstate();
  readPWMstate();
  print(int(effstate));
  print(" ");
  print(maxTorque);
  print(" ");
  print(lastCPR);
  print(" ");
  println(int(pwmstate));
  /*print(typepwm);
   print(" ");
   print(modepwm);
   print(" ");
   println(freqpwm);*/
  //println(enabledac, modedac);
}


void UpdateWparms(String input) {
  float[] temp = float(split(input, ' '));
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
}

String readParmUntillEmpty() { // reads untill empty and returns a string longer than 5 chars (non-FFB monitor data)
  String buffer = "";
  String temp = "";
  for (int i=0; i<9999; i++) {
    temp = readString();
    if (temp != "empty") {
      if (temp.length() > 5) {
        buffer = temp;
        break;
      } else {
        //delay(1);
      }
    } else {
      break;
    }
  }
  return buffer;
}

int readFwVersion() { // reads firmware version from String and checks if load cell is enabled
  myPort.clear();
  wb = "V";
  delay(20);
  executeWR();
  String temp = rb;
  int ver = 0;
  if (temp.length() <= 5) {
    // read all remaining data from FFB mon
    for (int i=0; i<20; i++) {
      temp = readString();
      delay(1);
    }
  }
  executeWR();
  int len = rb.length()-4;
  String fwDigits = rb.substring(4);
  ver = int(float(fwDigits));
  if (fwDigits.charAt(len-1) == '2') { // if last number is 2
    LCenabled = true;
  } else {
    LCenabled = false;
  }
  return ver;
}

void mousePressed() {
  if (mouseButton == LEFT) {
    for (int i=0; i < wParmFFB.length; i++) {
      wParmFFBprev[i] = wParmFFB[i];
    }
  }
}

void mouseReleased() {
  //int wheel_axis;
  if (controlb[0]) { // if we pressed center button
    if (moved) { // only update if it is not centered
      wb = "C";
      executeWR();
      prevaxis = gpad.getSlider("Xaxis").getValue();
      moved = false;
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
  updateEffstate (); // update effstate each time a button is realised
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
    if (moved) { // only update if it is not centered already
      wb = "C";
      executeWR();
      prevaxis = gpad.getSlider("Xaxis").getValue();
      moved = false;
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
  buttonpressed[0] = false;
  buttonpressed[1] = false;
  buttonpressed[2] = false;
}

void keyPressed() {
  if (key == 'c') {
    buttonpressed[0] = true;
  }
  if (key == 'd') {
    buttonpressed[1] = true;
  }
  if (key == 'p') {
    buttonpressed[2] = true;
  }
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
  if (effstate != effstateprev) { // only if effstate different than default
    readEffstate(); // re-configure swithces to new values
    updateEffstate (); // update new values of effstate
    sendEffstate (); // send new values to arduino
    effstateprev = effstate;
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
  slider_value[s] = wParmFFB[s]; // update slider scaled value
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

void readEffstate () { // decode switches from effstate value
  for (int j=3; j <=7; j++) {
    buttonpressed[j] = boolean(bitRead(effstate, j-3));
  }
}

void sendEffstate () { // send effstate value to arduino
  wb = "E " + str(int(effstate)); // set command for switches
  executeWR(); // send switch values to arduino and read buffer from wheel
}

void updateEffstate () { // code switches into effstate value
  for (int k=0; k <=4; k++) { //needs to be k<=4 here
    effstate = bitWrite(effstate, k, buttonpressed[k+3]);
  }
}

void readPWMstate () { // decode settings from pwmstate value and update lists to those value
  typepwm = boolean(bitRead (pwmstate, 0)); // bit0 of pwmstate is pwm type
  modepwm = boolean(bitRead (pwmstate, 1)); // bit1 of pwmstate is pwm mode
  for (int i=2; i<=5; i++) { // read frequency index, bits 2-5 of pwmstate
    freqpwm = bitWrite(byte(freqpwm), i-2, boolean(bitRead(pwmstate, i)));
  }
  modedac = boolean(bitRead (pwmstate, 6)); // bit6 of pwmstate is DAC mode
  enabledac = boolean(bitRead (pwmstate, 7)); // bit7 of pwmstate is DAC out enable
  pwmstateprev = pwmstate;
}

void sendPWMstate () { // send pwmstate value to arduino
  wb = "W " + str(int(pwmstate)); // set command for pwm settings
  executeWR(); // send values to arduino and read buffer from wheel (arduino will save it in EEPPROM right away)
}

void updatePWMstate () { // code to pwm settings from pwm settings values
  pwmstate = bitWrite(pwmstate, 0, typepwm);
  pwmstate = bitWrite(pwmstate, 1, modepwm);
  for (int i=0; i <=5; i++) { // set frequency index, bits 2-5 of pwmstate
    pwmstate = bitWrite(pwmstate, i+2, boolean(bitRead(byte(freqpwm), i)));
  }
  pwmstate = bitWrite(pwmstate, 6, modedac);
  pwmstate = bitWrite(pwmstate, 7, enabledac);
  //println(pwmstate);
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
  /* here an item is stored as a Map  with the following key-value pairs:
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
  modepwm = boolean(n);
  updatePWMstate ();
}

void dacmode(int n) {
  CColor c = new CColor();
  c.setBackground(color(255, 0, 0));
  cp5.get(ScrollableList.class, "dacmode").getItem(n).put("color", c);
  modedac = boolean(n);
  updatePWMstate ();
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
        COMx = showInputDialog(gpad + " at? (letter only)\n" + COMlist);
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
      showMessageDialog(frame, "Device is not connected to the PC");
      result = 0;
      //exit();
    }
  }
  catch (Exception e)
  { //Print the type of error
    showMessageDialog(frame, "COM port is not available\ndoes not exist or may be\nin use by another program");
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
  } else if (sdrID == 0) { // for def of rotation slider 0 and min torque slider 10
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
  temp = int(65535.0/(deg/360.0));
  if (temp >= 32767) {
    temp = 32767;
  }
  return temp;
}

float maxAllowedDeg (float cpr) { // maximum allowed rotation degrees range for any given encoder CPR
  float temp = 0.0;
  temp = 65535.0/(cpr/360.0);
  if (temp >= deg_max) {
    temp = deg_max;
  }
  return temp;
}
