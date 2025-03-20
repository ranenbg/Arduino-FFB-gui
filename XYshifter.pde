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
    dx = s*1023.0;
    dy = s*1023.0;
    lx = dx/25.5;
    ly = dy/25.5;
    sd = lx;
    revGearBit = 0;
    xycals[0] = new xyCal(x, y-ly-2, lx, ly, 0, "a");
    xycals[1] = new xyCal(x, y+ly+2+dy, lx, ly, 2, "b");
    xycals[2] = new xyCal(x, y-ly-2, lx, ly, 0, "c");
    xycals[3] = new xyCal(x+dx+lx+2, y, lx, ly, 1, "d");
    xycals[4] = new xyCal(x+0*dx-lx-2, y, lx, ly, 3, "e");
  }
  void updatePos() { // update shifter xy position form arduino read buffer string
    int[] temp = int(split(rb, ' '));
    shX = temp[0];
    shY = temp[1];
  }
  void updateCal(String calibration) { // update shifter calibration form arduino string
    float[] temp = float(split(calibration, ' '));
    for (int i=0; i<xycals.length; i++) {
      sCal[i] = temp[i]; // update cal values
      if (i < 3) {
        xycals[i].x = convertToxycals(i); // update scaled x cal values
      } else {
        xycals[i].y = convertToxycals(i); // update scaled x cal values
      }
      updatexycalsLimit(i); // update scaled cal limits
    }
    sConfig = byte(temp[5]);
    //println(str(sCal[0])+" "+str(sCal[1])+" "+str(sCal[2])+" "+str(sCal[3])+" "+str(sCal[4])); // show shifter calibration parameters
    //println(str(xycals[0].x)+" "+str(xycals[1].x)+" "+str(xycals[2].x)+" "+str(xycals[3].y)+" "+str(xycals[4].y)); // show shifter scaled calibration parameters
  }
  float convertToxycals(int i) {
    float temp = 0;
    float k = sCal[i]/1023.0;
    if (i < 3) {
      temp = x + k*dx; // a, b, c
    } else {
      temp = y + (1-k)*dy; // d, e
    }
    return temp;
  }
  float convertsCalFromxycals(int i) { // convert scaled cal values into cal values
    float temp;
    if (i < 3) {
      temp = (xycals[i].x-x)/s;
    } else {
      temp = 1023.0-(xycals[i].y-y)/s;
    }
    return temp;
  }
  void getxycals(int i) { // get xycal value from mouse position
    if (i < 3) {
      xycals[i].x = mouseX; // update cal x position
    } else {
      xycals[i].y = mouseY; // update cal y position
    }
    updatexycalsLimit(i); // update cal limits
    checkxycalsLimit(i); // constrain cal values to limits
  }
  int getGear(boolean showGear) { // return the curent shifter gear (0 is neutral, -1 is reverse)
    int g;
    float sx, sy;
    sx = x + shX/1023.0*dx;
    sy = y +(1-shY/1023.0)*dy;
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
  void setCal() { // get shifter calibration from wheel control
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
  void show() {
    pushMatrix();
    noStroke();
    translate(x, y+dy);
    fill(51);
    rect(-0.025*dx, 0.09*dy, dx*1.15, -dy*1.18); // shifter background
    stroke(255);
    strokeWeight(1);
    noFill();
    rect(0, 0, dx, -dy); // shifter zone
    fill(255);
    String sName = "Analog XY H-shifter";
    text(sName, dx-textWidth(sName), font_size);
    noStroke();
    fill(32, 255, 255);
    ellipse(shX/1023.0*dx, -shY/1023.0*dy, sd/2, sd/2); // current shifter position
    getGear(true);
    popMatrix();
    for (int j=0; j<xycals.length; j++) {
      xycals[j].updateColors(ctrl_btn+j);
      xycals[j].showPointer(dx, dy);
    }
  }

  void updatexycalsLimit(int i) { // update shifter calibration values in the scaled units for displaying shifter
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
  void checkxycalsLimit(int i) { // checks if scaled cal values are withing limits and limit them if they are not
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
