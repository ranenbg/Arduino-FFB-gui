class HatSW {
  float x;
  float y;
  float r;
  float R;

  HatSW (float posx, float posy, float radius, float Radius) {
    x = posx;
    y = posy;
    r = radius;
    R = Radius;
  }

  void update() {
    if (gpad.getButton("Hat").pressed()) { 
      hatvalue = floor(gpad.getButton("Hat").getValue());
      //println(hatvalue);
    } else {
      //println(0);
    }
  }

  void show() {
    int hue;
    if (gpad.getButton("Hat").pressed()) {
      hue = 64;
    } else {
      hue = 0;
    }
    stroke(255);
    strokeWeight(1);
    fill(hue, 255, 255);
    ellipse(x, y, r, r);
    noFill();
    stroke(255, 200);
    ellipse(x, y, R, R);
  }

  void showArrow() {
    if (gpad.getButton("Hat").pressed()) {
      pushMatrix();
      translate(x, y);
      rotate(TWO_PI*hatvalue/8.0+(1.0/2.0)*PI);
      beginShape();
      //strokeWeight(1);
      //stroke(255);
      noStroke();
      fill(64, 255, 255);
      int hg = floor(R*0.4);
      vertex(-4, hg+0);
      vertex(4, hg+0);
      vertex(4, hg+5);
      vertex(6, hg+5);
      vertex(0, hg+12);
      vertex(-6, hg+5);
      vertex(-4, hg+5);
      endShape();
      popMatrix();
    }
  }
}
