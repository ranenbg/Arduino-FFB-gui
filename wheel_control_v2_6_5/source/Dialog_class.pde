class Dialog {
  float x;
  float y;
  float s;
  String t;
  float l;

  Dialog(float posx, float posy, float size, String text) {
    x = posx;
    y = posy;
    s = size;
    t = text;
  }

  void update(String newText, boolean resize) {
    if (resize) {
      float d = min(wScaleX, wScaleY)*(btn_size_init+btn_sep_init);
      x = 0.05*widthprev;
      y = heightprev-posY*1.85+4*d+2*(-1.15)*font_size;
    }
    l=textWidth(newText) + font_size;
    t=newText;
  }

  void show() {
    colorMode(RGB, 255, 255, 255);
    fill(0, 45, 90);
    //fill(148, 200, 100);
    strokeWeight(1);
    colorMode(HSB);
    stroke(255);
    rect(x, y, l, 1.5*font_size);
    pushMatrix();
    textSize(font_size);
    fill(255);
    translate(x, y);
    text(t, 0.5*font_size, 1.1*font_size);
    popMatrix();
  }
}
