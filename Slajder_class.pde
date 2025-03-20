class Slajder {
  color c;
  float x, y, s, am, axisVal;
  String l, la, lb;
  xyCal[] yLimits = new xyCal[2];
  boolean yLimitsVisible, xffb, yffb, inactive;
  float[] pCal = new float[2];
  int id;

  Slajder(color acolor, float posx, float posy, float size, float axisMax, String label, String labela, String labelb, boolean xffbaxis, boolean yffbaxis) {
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
    yLimits[0] = new xyCal(x-2.8*s, y, s, s, 3, la);
    yLimits[1] = new xyCal(x-2.8*s, y-2*axisScale, s, s, 3, lb);
    yLimits[0].active = true;
    yLimits[1].active = true;
    yLimitsVisible = false;
    pCal[0] = 0;
    pCal[1] = am;
    yLimits[0].y = convertToyLimits(0);
    yLimits[1].y = convertToyLimits(1);
  }

  void update(int i) {
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
      axisVal = 0.0;
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

  void getyLimits(int i) { // get yLimits value from mouse position
    yLimits[i].y = mouseY; // update yLimits y position
    updateyLimitsLimit(i);
    checkyLimitsLimit(i);
  }

  void setpCal() { // set pedal calibration from wheel control
    for (int i=0; i<yLimits.length; i++) {
      if (yLimits[i].changing) {
        getyLimits(i);
        pCal[i] = getpCalFromyLimits(i);
      }
    }
  }

  void updateCal(float min, float max) {
    pCal[0] = min;
    pCal[1] = max;
    for (int i=0; i<yLimits.length; i++) {
      yLimits[i].y = convertToyLimits(i);
      updateyLimitsLimit(i);
      checkyLimitsLimit(i);
    }
  }

  float getpCalFromyLimits(int i) { // convert graph coordinates into pCal values
    return map(yLimits[i].y, y, y-2*axisScale, 0, am);
  }

  float convertToyLimits(int i) {  // convert pCal values into graph coordinates
    return map(pCal[i], 0, am, y, y-2*axisScale);
  }

  void updateyLimitsLimit(int i) { // update pedal calibration limits in the scaled pCal units
    if (i == 0) {
      yLimits[i].limits[2] = yLimits[i+1].y + s; // d low limit is e
      yLimits[i].limits[3] = y - 0*s/2; // d high limit is 2*axisScale
    }
    if (i == 1) {
      yLimits[i].limits[2] = y-2*axisScale + 0*s/2; // e low limit is 0
      yLimits[i].limits[3] = yLimits[i-1].y - s; // e high limit is d
    }
  }

  void checkyLimitsLimit(int i) { // checks if scaled pCal values are withing limits and limit them if they are not
    if (yLimits[i].y <= yLimits[i].limits[2]) {
      yLimits[i].y = yLimits[i].limits[2];
    } else if (yLimits[i].y > yLimits[i].limits[3]) {
      yLimits[i].y = yLimits[i].limits[3];
    }
  }

  void show() {
    if (inactive) {
      c = color(0, 0, 100); // inactive gray
    }
    fill(c);
    strokeWeight(1);
    stroke(255);
    pushMatrix();
    rectMode(CORNER);
    rect(x, y, s, -axisScale-axisVal*axisScale);
    translate(x-15, y);
    float n = axisScale/10;
    float m = n/5;
    for (int i = 0; i > -20; i--) {
      for (int j = 0; j > -5; j--) {
        line(0, i*n, 10, i*n);
        line(0, j*m + i*n, 5, j*m + i*n);
      }
    }
    line(0, -20*n, 10, -20*n);
    fill(255);
    text(round(map(axisVal, -1, 1, 0, am)), 0, -(2*n+1)*10);
    noFill();
    textSize(0.8*font_size);
    if (xffb && yffb) {
      rect(15, 14, 28, -10);
      if (twoFFBaxis_enabled) {
        text("xyFFB", 15, 13);
      } else {
        text("xFFB", 15, 13);
      }
    } else if (xffb) {
      rect(15, 14, 23, -10);
      text("xFFB", 15, 13);
    } else if (yffb) {
      if (twoFFBaxis_enabled) {
        text("yFFB", 15, 13);
        rect(15, 14, 23, -10);
      }
    }
    fill(255);
    textSize(font_size);
    if (id < 3) {
      text(l, -2, 20);
    } else {
      text(l, -font_size/2, 20);
    }
    popMatrix();
    if (yLimitsVisible) {
      for (int j=0; j<yLimits.length; j++) {
        yLimits[j].updateColors(ctrl_btn+ctrl_sh_btn+2*id+j); // milos, was id-1 to skip X-axis cal limits
        yLimits[j].showPointer(2.8*s, 0);
      }
    }
  }
}
