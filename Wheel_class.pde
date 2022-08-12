class Wheel {
  float x;
  float y;
  float s;
  String wl;
  float rotRad, rotDeg;

  Wheel(float posx, float posy, float size, String wheel_label) {
    x = posx;
    y = posy;
    s = size;
    wl = wheel_label;
  }

  void update(float angle) {
    rotDeg = angle; // wheel angle in degrees
    rotRad = rotDeg/180.0*PI; // wheel angle in radians
  }

  void show() {
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
  void showDeg() {
    pushMatrix();
    fill(255);
    translate(x, y);
    text(FormatText(rotDeg)+"°", axisScale/2-40, axisScale/2+20);
    //text(deg+"°", scale/2-40, scale/2+20);
    popMatrix();
  }

  String FormatText(float inp) {
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
