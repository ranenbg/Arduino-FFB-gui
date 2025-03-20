class Wheel {
  float x, jx;
  float y, jy;
  float s;
  String wl;
  float rotRad, rotDeg;

  Wheel(float posx, float posy, float size, String wLabel) {
    x = posx;
    y = posy;
    s = size;
    wl = wLabel;
  }

  void updateWheel(float angle) {
    rotDeg = angle; // wheel angle in degrees
    rotRad = rotDeg/180.0*PI; // wheel angle in radians
  }

  void updateJoy(float jxpos, float jypos) {
    jx = jxpos;
    jy = jypos;
  }

  void showJoy() {
    float fx = float(ffbx) / float(maxTorque);
    float fy = float(ffby) / float(maxTorque);
    float fmag = sqrt(fx*fx + fy*fy);
    float dL = s/25;
    int n = 20; // number of axis ticks
    int nl = 4; // tick length
    float pn = s / float(n); // tick pos
    String al = "-axis";
    pushMatrix();
    stroke(255, 200);
    strokeWeight(1);
    translate(x, y);
    noFill();
    rect(-s/2, -s/2, s, s);
    strokeWeight(1);
    stroke(255, 100);
    line(-s/2, 0, s/2, 0); // horizontal axis
    for (int i = 0; i <= n; i++) {
      line (-nl/2, i*pn-s/2, nl/2, i*pn-s/2); // horizontal axis ticks
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
    text(xl+al, s/2-2, -dL/2); // horizontal axis label
    textAlign(LEFT);
    pushMatrix();
    rotate(PI/2);
    line(-s/2, 0, s/2, 0); // vertcal axis
    for (int i = 0; i <= n; i++) {
      line (-nl/2, i*pn-s/2, nl/2, i*pn-s/2); // vertical axis ticks
    }
    String yl = "y"; // y-axis label (not configurable)
    text(yl+al, -s/2+2, -dL/2); // vertical axis label
    popMatrix();
    fill(32, 255, 255);
    noStroke();
    //ellipse(jx*s/2, -jy*s/2, dL/2, dL/2); // joystick xy pos (dot)
    pushMatrix();
    translate(jx*s/2, -jy*s/2);
    stroke(32, 255, 255);
    line(-dL, 0, dL, 0);  // joystick xy pos (cross) horisontal part
    line(0, -dL, 0, dL);  // joystick xy pos (cross) vertical part
    popMatrix();
    stroke(map(abs(fmag), 0, 1, 145, 0), 255, 255);
    strokeWeight(3);
    if (buttonpressed[7]) line(0, 0, fx*s/2, -fy*s/2); // XY ffb line
    popMatrix();
  }

  void showWheel() {
    pushMatrix();
    stroke(255);
    strokeWeight(1);
    translate(x, y);
    pushMatrix();
    textSize(16);
    fill(255);
    text(wl, -22, -axisScale/2-16);
    textSize(font_size);
    popMatrix();
    rotate(rotRad);
    ellipseMode(CENTER);
    noFill();
    float wd = 0.85;
    ellipse(0, 0, s, s); // wheel rim outer
    ellipse(0, 0, wd*s, wd*s); // wheel rim inner
    rectMode(CENTER);
    rect(0, 0, wd*s, s/8); // cross bar
    rectMode(CORNER);
    rect(-s/16, s/16, s/8, s/2-(1-wd)*s); // botom bar
    fill(255);
    rect(-s/32, -s/2, s/16, (1-wd)/2*s); // center stripe
    popMatrix();
  }

  void showWheelDeg() {
    pushMatrix();
    fill(255);
    translate(x, y);
    text(formatText(rotDeg)+"°", axisScale/2-25, axisScale/2+8);
    popMatrix();
  }

  void showJoyPos() {
    String jxs = formatText(jx*100.0); // joy x-axis pos in percents
    String jys = formatText(jy*100.0); // joy x-axis pos in percents
    String jxys = jxs +", "+ jys;
    pushMatrix();
    fill(255);
    translate(x, y);
    text(jxys+"%", axisScale/2-25, axisScale/2+8);
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
