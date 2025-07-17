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

  void update(int i, boolean resize) {
    if (resize) {
      if (t != " ") {
        sx = textWidth(t)+font_size;
      } else {
        sx = 1.4*font_size;
      }
      sy = 1.4*font_size;
      if (i == 0) {
        x = 0.123*widthprev + (wScaleX*axisHeight_init*0.8)/2;
        y = 0.223*heightprev + (wScaleY*axisHeight_init*0.8)/2;
      } else if (i == 14) {
        x = 0.123*widthprev + (wScaleX*axisHeight_init*0.8)/2 + textWidth(buttons[0].t) + 1.25*font_size;
        y = 0.223*heightprev + (wScaleY*axisHeight_init*0.8)/2;
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
        y = 2.325*axisHeight;
      } else if (i == 13) {
        x = xPosAxis(i);
        y = 2.325*axisHeight+sy+0.25*font_size;
      } else if (i == 11) {
        x = xPosAxis(i);
        y = 2.325*axisHeight;
      } else if (i == 12) {
        sx = textWidth(buttons[i].t)+font_size;
        x = xPosAxis(11) + textWidth(buttons[11].t)+1.25*font_size;
        y = 2.325*axisHeight;
      } else if (i == 15) {
        sx = textWidth(buttons[12].t)+font_size;
        x = xPosAxis(i);
        y = 2.325*axisHeight+sy+0.25*font_size;
      } else if (i == 17) {
        sx = textWidth(buttons[12].t)+font_size;
        x = xPosAxis(11) + textWidth(buttons[11].t)+1.25*font_size;
        y = 2.325*axisHeight+sy+0.25*font_size;
      } else if (i == 16) {
        sx = textWidth(buttons[12].t)+font_size;
        x = xPosAxis(15) + textWidth(buttons[12].t)+1.25*font_size;
        y = 2.325*axisHeight+sy+0.25*font_size;
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

  void show() {
    fill(col[0], col[1], col[2]);
    strokeWeight(1);
    stroke(255);
    pushMatrix();
    translate(x, y);
    rect(0, 0, sx, sy);
    pushMatrix();
    textSize(font_size);
    fill(thue);
    text(t, 0.5*(sx-textWidth(t)), font_size);
    popMatrix();
    if (showInfo) {
      pushMatrix();
      if (dp == 0) {
        translate(0, -1.15*sy); // put description above
      } else if (dp == 1) {
        translate(0, 1.15*sy); // put description bellow
      } else if (dp == 2) {
        translate(-textWidth(d)-font_size, 0); // put description to the left side
      } else if (dp == 3) {
        translate(sx, 0); // put description to the right side
      }
      noFill();
      rect(0, 0, textWidth(d)+font_size, sy);
      text(d, 0.5*font_size, font_size);
      popMatrix();
    }
    popMatrix();
  }
}
