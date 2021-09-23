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

  void show(boolean enable) {
    if (enable) {
      noFill();
      strokeWeight(1);
      stroke(255);
      rect(x, y, s/2*(fullinfo.length()+3), s*1.2);
      pushMatrix();
      textSize(font_size);
      fill(255);
      text(fullinfo, x+font_size/2, y+font_size-1);
      popMatrix();
    }
  }
}
