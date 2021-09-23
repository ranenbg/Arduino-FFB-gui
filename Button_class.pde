class Button {
  float x;
  float y;
  float sx, sy;
  String t;

  Button(float posx, float posy, float sizex, float sizey, String text) {
    x = posx;
    y = posy;
    sx = sizex;
    sy = sizey;
    t = text;
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
    } else if (controlb[i] && !mousePressed) { // yellow with white text (howered)
      col[0] = 40;
      col[1] = 200;
      col[2] = 180;
      thue = 255;
    } else if (!controlb[i]) { // red with white text (deactivated)
      col[0] = 0;
      col[1] = 200;
      col[2] = 150;
      thue = 255;
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
  }
}
