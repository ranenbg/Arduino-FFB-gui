class Slajder {
  int h;
  float x;
  float y;
  float s;
  float v;
  String l;

  Slajder(int hue, float posx, float posy, float size, float value, String label) {
    h = hue;
    x = posx;
    y = posy;
    s = size;
    v = value;
    l = label;
  }

  void update() {
    Axis[0] = gpad.getSlider("Xaxis").getValue();
    Axis[1] = -gpad.getSlider("Yaxis").getValue();
    Axis[2] = -gpad.getSlider("Zaxis").getValue();
    Axis[3] = -gpad.getSlider("Xrotation").getValue();
    //Axis[4] = gpad.getSlider("Zrotation").getValue();
  }

  void show() {
    int value = round(map(axisValue, -1, 1, v, 0));
    fill(h, 255, 255);
    strokeWeight(1);
    stroke(255);
    pushMatrix();
    rectMode(CORNER);
    rect(x, y, s, scaledValue);
    translate(x-15, y);

    float n = scale/10;
    float m = n/5;
    for (int i = 0; i > -20; i--) {
      for (int j = 0; j > -5; j--) {
        line(0, i*n, 10, i*n);
        line(0, j*m + i*n, 5, j*m + i*n);
      }
    }
    line(0, -20*n, 10, -20*n);
    fill(255);
    text(value, 0, -(2*n+1)*10);
    text(l, 0, 20);
    popMatrix();
    //print(value);
    //print(" ");
  }
}
