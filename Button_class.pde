class Button {
  int dp;
  float x;
  float y;
  float sx, sy;
  String t, d;
  boolean showInfo;

  Button(float posx, float posy, float sizex, float sizey, String text, String description, int descriptionPos) {
    x = posx;
    y = posy;
    sx = sizex;
    sy = sizey;
    t = text;
    d = description;
    dp = descriptionPos; // 0-up, 1-down, 2-left, 3-right
    showInfo = false;
  }

  void update(int i) {
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
  }

  void show() {
    fill(col[0], col[1], col[2]);
    strokeWeight(1);
    stroke(255);
    rect(x, y, sx, sy);
    pushMatrix();
    textSize(font_size);
    fill(thue);
    text(t, x+font_size*0.5, y+font_size);
    popMatrix();
    if (showInfo) {
      pushMatrix();
      if (dp == 0) {
        translate(x, y-1.2*sy); // put description above
      } else if (dp == 1) {
        translate(x, y+1.2*sy); // put description bellow
      } else if (dp == 2) {
        translate(x-textWidth(d)-font_size, y); // put description to the left side
      } else if (dp == 3) {
        translate(x+sx+10, y); // put description to the right side
      }
      noFill();
      rect(0, 0, textWidth(d)+font_size, sy);
      text(d, font_size*0.5, font_size);
      popMatrix();
    }
  }
}
