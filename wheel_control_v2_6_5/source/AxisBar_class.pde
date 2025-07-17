class AxisBar {
  color c;
  float x, y, s, am, axisVal;
  String l, la, lb;
  xyCal[] yLimits = new xyCal[2];
  boolean yLimitsVisible, xffb, yffb, inactive;
  float[] pCal = new float[2];
  int id, bigTicks, smallTicks;
  int bTn, sTn, bTl, sTl;

  AxisBar(color acolor, float posx, float posy, float size, float axisMax, String label, String labela, String labelb, boolean xffbaxis, boolean yffbaxis) {
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
    yLimits[1] = new xyCal(x-2.8*s, y-2*axisHeight, s, s, 3, lb);
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

  void update(int i, boolean resize) {
    if (resize) {
      shXoff = s*wScaleX;
      x = float(widthprev)/3.65 + i*6*s*wScaleX;
      axisHeight = int(wScaleY*axisHeight_init);
      y = 2.2*axisHeight;
      posY = heightprev - (2.2*axisHeight);
      yLimits[0].y = convertToyLimits(0);
      yLimits[1].y = convertToyLimits(1);
      yLimits[0].x = x-2.8*s*wScaleX;
      yLimits[1].x = x-2.8*s*wScaleX;
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
    return map(yLimits[i].y, y, y-2*axisHeight, 0, am);
  }

  float convertToyLimits(int i) {  // convert pCal values into graph coordinates
    return map(pCal[i], 0, am, y, y-2*axisHeight);
  }

  void updateyLimitsLimit(int i) { // update pedal calibration limits in the scaled pCal units
    if (i == 0) {
      yLimits[i].limits[2] = yLimits[i+1].y + s; // d low limit is e
      yLimits[i].limits[3] = y - 0*s/2; // d high limit is 2*axisHeight
    }
    if (i == 1) {
      yLimits[i].limits[2] = y-2*axisHeight + 0*s/2; // e low limit is 0
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
    rect(x, y, s*wScaleX, -axisHeight-axisVal*axisHeight);
    translate(x-1.5*s*wScaleX, y);
    float n = float(axisHeight)/float(bTn);
    float m = n/float(sTn);
    if (m < 4) {
      sTn -= 1;
      m = n/float(sTn);
    }
    if (m > 5) {
      sTn += 1;
      if (sTn > 5) sTn = 5;
      m = n/float(sTn);
    }
    for (int i = 0; i > -2*bTn; i--) {
      for (int j = 0; j > -sTn; j--) {
        line(0, i*n, wScaleX*bTl, i*n);
        line(0, j*m + i*n, wScaleX*sTl, j*m + i*n);
      }
    }
    line(0, -2*bTn*n, wScaleX*bTl, -2*bTn*n);
    fill(255);
    text(round(map(axisVal, -1, 1, 0, am)), 0, -2*n*bTn-1.0*font_size);
    noFill();
    textSize(0.8*font_size);
    String ffbmark = "xFFB";
    if (xffb && yffb) {
      if (twoFFBaxis_enabled) {
        ffbmark = "xyFFB";
      } else {
        ffbmark = "xFFB";
      }
      rect(wScaleX*15, wScaleY*15-font_size, textWidth(ffbmark)+1, font_size);
      text(ffbmark, wScaleX*15, wScaleY*15-0.15*font_size);
    } else if (xffb) {
      ffbmark = "xFFB";
      rect(wScaleX*15, wScaleY*15-font_size, textWidth(ffbmark)+1, font_size);
      text(ffbmark, wScaleX*15, wScaleY*15-0.15*font_size);
    } else if (yffb) {
      if (twoFFBaxis_enabled) {
        ffbmark = "yFFB";
        rect(wScaleX*15, wScaleY*15-font_size, textWidth(ffbmark)+1, font_size);
        text(ffbmark, wScaleX*15, wScaleY*15-0.15*font_size);
      }
    }
    fill(255);
    textSize(font_size);
    text(l, -textWidth(l)/5, 1.7*font_size);
    //if (id < 3) {
    //text(l, -2, wScaleY*20);
    //} else {
    //text(l, -font_size/2, 20*wScaleY);
    //}
    popMatrix();
    if (yLimitsVisible) {
      for (int j=0; j<yLimits.length; j++) {
        yLimits[j].updateColors(ctrl_btn+ctrl_sh_btn+2*id+j); // milos, was id-1 to skip X-axis cal limits
        yLimits[j].showPointer(2.8*s, 0);
      }
    }
  }
}
