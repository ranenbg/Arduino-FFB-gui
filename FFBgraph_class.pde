class FFBgraph {
  float x;
  float y;
  int gh;
  int ps;
  int[] pointY = new int [gbuffer];
  float gwidthX, sclX, sclY;

  FFBgraph(float posx, float posy, int gheight, int pointsize) {
    x = posx;
    y = posy;
    gh = gheight;
    ps = pointsize;
    gwidthX = gbuffer/gskip;
    sclX = gwidthX / gbuffer;
    sclY = float(gh) / (2*maxTorque);
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
    float n = (gh+1)/l;
    float m = n/5;
    for (int i = 0; i >= -l; i--) {
      for (int j = 0; j > -5; j--) {
        if (i > -l) {
          line(0, i*n, 9, i*n); // small ticks
          line(4, j*m + i*n, 9, j*m + i*n); // major ticks
        } else {
          line(0, (i*n)+1, 9, (i*n)+1);
        }
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
      line(1+i*sclX, gh/2-sclY*pointY[i], 1+(i+1)*sclX, gh/2-sclY*pointY[i+1]);
    }
    popMatrix();
  }
}
