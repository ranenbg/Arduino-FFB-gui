class Slajder {
  color c;
  float x, y, s, am, axisVal;
  String l, la, lb;
  xyCal[] yLimits = new xyCal[2];
  boolean yLimitsVisible;
  float[] pCal = new float[2];
  int id;

  Slajder(color acolor, float posx, float posy, float size, float axisMax, String label, String labela, String labelb) {
    c = acolor;
    x = posx;
    y = posy;
    s = size;
    am = axisMax;
    l = label;
    la = labela;
    lb = labelb;
    yLimits[0] = new xyCal(x-2.8*s, y, s, s, 3, la);
    yLimits[1] = new xyCal(x-2.8*s, y-2*axisScale, s, s, 3, lb);
    yLimits[0].active = true;
    yLimits[1].active = true;
    yLimitsVisible = false;
    pCal[0] = 0; // minimum cal value
    pCal[1] = axisMax;  // maximum cal value
  }

  void update(int i) {
    if (i == 0) {        // X-axis
      axisVal = gpad.getSlider("Xaxis").getValue();
      if (axisVal != prevaxis) wheelMoved = true;
    } else if (i == 1) { // Y-axis
      axisVal = -gpad.getSlider("Yaxis").getValue();
    } else if (i == 2) { // Z-axis
      axisVal = -gpad.getSlider("Zaxis").getValue();
    } else if (i == 3) { // RX-axis
      axisVal = -gpad.getSlider("RXaxis").getValue();
    } else if (i == 4) { // RY-axis
      axisVal = -gpad.getSlider("RYaxis").getValue();
    } else {
      axisVal = 0.0;
    }
    setpCal();
    id = i;
  }

  void getyLimits(int i) { // get yLimits value from mouse position
    yLimits[i].y = mouseY; // update yLimits y position
    updateyLimitsLimit(i);
    checkyLimitsLimit(i);
  }

  void setpCal() { // get pedal calibration from wheel control
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

  void updateyLimitsLimit(int i) { // update pedal calibration limits in the scaled units
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
    } else if (yLimits[i].y >= yLimits[i].limits[3]) {
      yLimits[i].y = yLimits[i].limits[3];
    }
  }

  void show() {
    fill(c);
    strokeWeight(1);
    stroke(255);
    pushMatrix();
    rectMode(CORNER);
    rect(x, y, s, -axisScale+axisVal*axisScale);
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
    text(round(map(axisVal, -1, 1, am, 0)), 0, -(2*n+1)*10);
    text(l, 0, 20);
    popMatrix();
    if (yLimitsVisible) {
      for (int j=0; j<yLimits.length; j++) {
        yLimits[j].updateColors(ctrl_btn+ctrl_sh_btn+2*(id-1)+j);
        yLimits[j].showPointer(2.8*s, 0);
      }
    }
  }
}
