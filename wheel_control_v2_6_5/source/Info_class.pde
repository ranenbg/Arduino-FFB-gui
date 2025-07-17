class Info {
  float x;
  float y;
  int s;
  String txt;
  String btn;
  String fullinfo;

  Info(float posx, float posy, int size, String text, String button) {
    x = posx;
    y = posy;
    s = size;
    txt = text;
    btn = button;
    fullinfo = btn + " : " + txt;
  }

  void update(int i, boolean resize) {
    if (resize) {
      float d = min(wScaleX, wScaleY)*(btn_size_init+btn_sep_init);
      x = 0.05*widthprev;
      y = heightprev-posY*1.85+4*d+2*i*font_size;
    }
  }

  void show(boolean enable) {
    float textLength = 0;
    textLength = textWidth(fullinfo) + font_size;
    if (enable) {
      noFill();
      strokeWeight(1);
      stroke(255);
      rect(x, y, textLength, 1.2*font_size);
      pushMatrix();
      textSize(font_size);
      fill(255);
      translate(x, y);
      text(fullinfo, font_size/2, 0.9*font_size);
      popMatrix();
    }
  }
}
