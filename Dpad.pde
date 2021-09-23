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
    if (gpad.getButton("D pad").pressed()){ 
    hatvalue = floor(gpad.getButton("D pad").getValue());
    println(hatvalue);
    } else {
      println(0); 
      }  
  }
  
  void show() {
    int hue;
    if (gpad.getButton("D pad").pressed()){
      hue = 64;
    } else {
      hue = 0;
      }
    stroke(255);
    strokeWeight(2);
    fill(hue, 255, 255);
    ellipse(x, y, r, r);
    noFill();
    stroke(255, 200);
    ellipse(x, y, R, R);
        
  }
  
  void showArrow() {
    if (gpad.getButton("D pad").pressed()){
    pushMatrix();
    translate(x, y);
    rotate(TWO_PI*hatvalue/8.0+(1.0/2.0)*PI);
    beginShape();
    strokeWeight(1);
    stroke(255);
    fill(144, 255, 255);
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
