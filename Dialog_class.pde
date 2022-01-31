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

  void update(String newText) {
    t=newText;
    //l=newText.length();
    l=textWidth(newText) + font_size;
  }

  void show() {
    fill(148, 200, 100);
    strokeWeight(1);
    stroke(255);
    //rect(x, y, (l+4)*font_size/2, font_size*1.5);
    rect(x, y, l, s*1.2);
    pushMatrix();
    textSize(font_size);
    fill(255);
    translate(x, y);
    text(t, font_size*0.15+2, font_size*1.1);
    popMatrix();
  }
}
