class InfoButton {
  int ns, as, dp;
  float x, y, sx, sy;
  String[] n = new String[ns];
  String d;
  Boolean enabled, hiden, showDescription;

  InfoButton(float posx, float posy, float sizex, float sizey, int nSegments, String[] name, String description, int descriptionPos) {
    x = posx;
    y = posy;
    sx = sizex;
    sy = sizey;
    ns = nSegments;
    n = name;
    as = -1; // no segment is active
    d = description;
    dp = descriptionPos;
    enabled = false;
    hiden = true;
    showDescription = false;
  }

  void update(boolean resize) {
    if (resize) {
      if (d != " ") {
        sx = textWidth(d)+font_size;
      } else {
        sx = 1.4*font_size;
      }
      sy = 1.4*font_size;
      x = 0.123*widthprev + (wScaleX*axisHeight_init*0.8)/2;
      y = 0.223*heightprev - (wScaleY*axisHeight_init*0.8)/2 - sy;
    }
    if (mouseX >= x && mouseX <= x+sx && mouseY >= y && mouseY <= y+sy) {
      showDescription = true; // if howered with mouse
    } else {
      showDescription = false; // if not howered
    }
  }
  void show() {
    color ce = color (0, 200, 150); // red
    color cd = color (0, 0, 100); // gray
    thue = 255; // white
    if (!hiden) {
      for (int i=0; i<ns; i++) {
        fill(cd);
        if (i == as) fill(ce);
        strokeWeight(1);
        stroke(255);
        pushMatrix();
        translate(x, y);
        rect(i*(sx/ns), 0, sx/ns, sy);
        textSize(font_size);
        fill(thue);
        text(n[i], i*(sx/ns)+0.5*(sx/ns - textWidth(n[i])), font_size);
        popMatrix();
      }
      if (showDescription) {
        pushMatrix();
        if (dp == 0) {
          translate(x, y-1.15*sy); // put description above
        } else if (dp == 1) {
          translate(x, y+1.15*sy); // put description bellow
        } else if (dp == 2) {
          translate(x-textWidth(d)-font_size, y); // put description to the left side
        } else if (dp == 3) {
          translate(x+sx, y); // put description to the right side
        }
        noFill();
        rect(0, 0, textWidth(d)+font_size, sy);
        text(d, 0.5*font_size, font_size);
        popMatrix();
      }
    }
  }
}
