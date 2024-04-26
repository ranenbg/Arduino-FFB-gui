class FFBgraph {
  float x, y;
  int ps;
  int[] pointY = new int [gbuffer];
  float gwidthX, gh, sclX, sclY;

  FFBgraph(float posx, float posy, float gheight, int pointsize) {
    x = posx - 1;
    y = posy - 1;
    gh = gheight - 1;
    ps = pointsize;
    gwidthX = gbuffer / gskip;
    sclX = gwidthX / gbuffer;
    sclY = gh / (2*maxTorque);
  }

  void update(String val1) {
    pointY[0] = parseInt(val1);
    for (int i=pointY.length-1; i>0; i--) {
      pointY[i] = pointY[i-1];
    }
  }

  void show() {
    pushMatrix();
    translate(x, y);
    rotate(PI/2.0); // rotate CW by 90deg
    noFill();
    strokeWeight(1);
    stroke(255);
    rectMode(CORNER);
    rect(0, 0, gwidthX, gh); // graph frame
    text(pointY[0], (-str(pointY[0]).length()*0.59-1.3)*font_size, gh/2+0.3*font_size); // zero indicator
    //text(-maxTorque, -60, gh-5+0.3*font_size); // min ffb value indicator
    //text(maxTorque, -50, 5+0.3*font_size); // max ffb value indicator
    pushMatrix();
    translate(-9, gh);
    int l = 32;
    float n = gh/l;
    float m = n/5;
    for (int i = 0; i >= -l; i--) {
      for (int j = 0; j > -5; j--) {
        line(0, n*i, 9, n*i); // major ticks
        if (i > -l) line(4, m*j + n*i, 9, m*j + n*i); // small ticks (do not draw them after last major tick)
      }
    }
    popMatrix();
    for (int i=0; i<pointY.length-1; i++) {
      /*noStroke();
       fill(128, 255, 255);
       ellipse(1+i*sclX, gh/2+sclY*maxTorque, ps, ps); // min limit
       fill(0, 255, 255);
       ellipse(1+i*sclX, gh/2-sclY*maxTorque, ps, ps); // max limit*/
      //fill(32, 255, 255);
      //ellipse(1+i*sclX, gh/2-sclY*pointY[i], ps, ps); // ffb signal
      //stroke(32, 255, 255);
      strokeWeight(ps);
      stroke(map(abs(pointY[i]), 0, maxTorque, 145, 0), 255, 255);
      line(sclX*i+1, gh/2-sclY*pointY[i], sclX*(i+1)+1, gh/2-sclY*pointY[i+1]);
    }
    popMatrix();
  }
}
