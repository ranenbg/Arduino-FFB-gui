class xyCal {
  float x, y, sx, sy;
  float[] limits = new float [4];
  boolean active, changing, grabed;
  int orn;
  String t;

  xyCal(float posx, float posy, float xsize, float ysize, int orientation, String text) {
    x = posx;
    y = posy;
    sx = xsize;
    sy = ysize;
    t = text;
    active = true;
    changing = false;
    grabed = false;
    orn = orientation; // 0-top, 1-right, 2-bottom, 3-left
  }

  void updateColors(int i) {
    if (active) {
      if (mouseX >= x-sx/2 && mouseX <= x+sx/2 && mouseY >= y-sy/2 && mouseY <= y+sy/2) { // if mouse pointer is howered over
        controlb[i] = true;
      } else {
        controlb[i] = false;
      }
      if (controlb[i] && mousePressed) { // green with black text (activated)
        col[0] = 96;
        col[1] = 200;
        col[2] = 150;
        thue = 0;
        changing = true;
      } else if (controlb[i] && !mousePressed) { // yellow with white text (howered)
        col[0] = 40;
        col[1] = 200;
        col[2] = 180;
        thue = 255;
        changing = false;
      } else if (!controlb[i] || !grabed) { // red with white text (deactivated)
        col[0] = 0;
        col[1] = 200;
        col[2] = 150;
        thue = 255;
        changing = false;
      } 
    } else {
      col[0] = 0;
      col[1] = 0;
      col[2] = 100;
      thue = 255;
    }
  }

  void showPointer(float dx, float dy) {
    float yoffs = sy+2; // pointer y offset
    pushMatrix();
    fill(col[0], col[1], col[2]);
    strokeWeight(1);
    stroke(255);
    if (orn == 0) {
      translate(x, y);
    } else if (orn == 1) {
      translate(x, y);
    } else if (orn == 2) {
      translate(x, y);
    } else if (orn == 3) {
      translate(x, y);
    }
    rotate(float(orn)/2.0*PI);
    beginShape();
    vertex(-sx/2, -sy/2);
    vertex(sx/2, -sy/2);
    vertex(sx/2, sy/2);
    vertex(0, sy);
    vertex(-sx/2, sy/2);
    vertex(-sx/2, -sy/2);
    endShape();
    textSize(font_size);
    if (sx < font_size) textSize(sx);
    fill(thue);
    stroke(150);
    if (orn == 0) {
      text(t, -sx/2, sy/2);
      pushMatrix();
      translate(0, yoffs);
      line(0, 1, 0, dy-1);
      popMatrix();
    } else if (orn == 1) {
      pushMatrix();
      rotate(-float(orn)/2.0*PI);
      translate(-yoffs, 0);
      text(t, sx, sy/2);
      line(-dx+1, 0, -1, 0);
      popMatrix();
    } else if (orn == 2) {
      pushMatrix();
      translate(0, yoffs);
      line(0, 1, 0, dy-1);
      rotate(-float(orn)/2.0*PI);
      text(t, -sx/2, 1.5*sy);
      popMatrix();
    } else if (orn == 3) {
      pushMatrix();
      rotate(-float(orn)/2.0*PI);
      text(t, -sx/2, 0.35*sy);
      translate(dx+yoffs, 0);
      line(-dx+1, 0, -1, 0);
      popMatrix();
    }
    popMatrix();
    textSize(font_size);
  }
}
