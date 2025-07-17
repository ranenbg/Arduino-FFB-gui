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

  void updateWheel(float angle, boolean resize) {
    if (resize) {
      x = 0.123*widthprev;
      y = 0.223*heightprev;
      sx = min(wScaleX, wScaleY)*axisHeight_init*0.95;
      sy = sx;
    }
    rotDeg = angle; // wheel angle in degrees
    rotRad = rotDeg/180.0*PI; // wheel angle in radians
  }

  void updateJoy(float jxpos, float jypos, boolean resize) {
    if (resize) {
      x = 0.123*widthprev;
      y = 0.223*heightprev;
      sx = wScaleX*axisHeight_init*0.8;
      sy = wScaleY*axisHeight_init*0.8;
    }
    jx = jxpos;
    jy = jypos;
  }

  void showJoy() {
    float fx = float(ffbx) / float(maxTorque);
    float fy = float(ffby) / float(maxTorque);
    float fmag = sqrt(fx*fx + fy*fy);
    float dLx = sx/25;
    float dLy = sy/25;
    int n = 20; // number of axis ticks
    int nl = 4; // tick length
    float pnx = sx / float(n); // tick pos
    float pny = sy / float(n);
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

  void showWheel() {
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
    float wd = 0.85;
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

  void showWheelDeg() {
    pushMatrix();
    fill(255);
    translate(0.123*widthprev + (wScaleX*axisHeight_init*0.8)/2, 0.223*heightprev + (wScaleY*axisHeight_init*0.8)/2 + 2*buttons[0].sy);
    text(formatText(rotDeg)+"°", 0, 0);
    popMatrix();
  }

  void showJoyPos() {
    String jxs = formatText(jx*100.0); // joy x-axis pos in percents
    String jys = formatText(jy*100.0); // joy x-axis pos in percents
    String jxys = jxs +", "+ jys;
    pushMatrix();
    fill(255);
    translate(x, y);
    text(jxys+"%", axisHeight/2-25, axisHeight/2+8);
    popMatrix();
  }

  String formatText(float inp) {
    String out;
    int len = str(inp).length();
    if (inp > 0.0) { // positive values
      if (inp < 10.0) { //0-9.9
        out = str(inp).substring(0, 4);
      } else {  // >=10
        if (len > 4) {
          out = str(inp).substring(0, 5);
        } else {
          out = str(inp)+"0";
        }
      }
    } else { // negative values
      if (inp < -10.0) {
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
