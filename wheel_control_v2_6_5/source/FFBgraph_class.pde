class FFBgraph {
  float x, y;
  int ps, l, p;
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
    l = 32;
    p = 5;
  }

  void updateSize(boolean resize) {
    if (resize) {
      gh = widthprev - 1;
      x = gh;
      sclY = gh / (2*maxTorque);
      gwidthX = wScaleY*gbuffer / gskip;
      sclX = gwidthX / gbuffer;
    }
  }

  void update(String val1) {
    pointY[0] = parseInt(val1);
    for (int i=pointY.length-1; i>0; i--) {
      pointY[i] = pointY[i-1];
    }
  }

  void show(int i) {
    if (i == 0) {
      y = heightprev-wScaleY*gbuffer/gskip;
    } else {
      y = heightprev-2*(wScaleY*gbuffer/gskip);
    }
    String gT = "FFB";
    String gL = "left";
    String gR = "right";
    pushMatrix();
    translate(x, y);
    noFill();
    strokeWeight(1);
    stroke(255);
    noFill();
    strokeWeight(1);
    stroke(255);
    if (i == 0) { // for X-axis
      gT = "x" + gT;
    } else { // for Y-axis
      gT = "y" + gT;
      gL = "down";
      gR = "up";
    }
    textAlign(RIGHT);
    text(pointY[0], 0.25*font_size-gh/2, font_size); // X-axis value (horizontal orientation)
    text(gR, -0.4*font_size, font_size);
    textAlign(LEFT);
    text(gT, gT.length()*font_size-gh/2, font_size);
    text(gL, gL.length()*0.1*font_size - gh, font_size);
    rotate(PI/2.0); // rotate CW by 90deg
    rectMode(CORNER);
    rect(0, 0, gwidthX, gh); // graph frame
    /*if (!twoFFBaxis_enabled) {
     text(pointY[0], (-str(pointY[0]).length()*0.59-1.3)*font_size, gh/2+0.3*font_size); // ffb axis value (vertical orientation), at center of graph
     }*/
    //text(-maxTorque, -60, gh-5+0.3*font_size); // min ffb value indicator
    //text(maxTorque, -50, 5+0.3*font_size); // max ffb value indicator
    pushMatrix();
    translate(0, gh);
    int majl = int(8*wScaleY); // major tick length
    int minl = int(4*wScaleY); // minor tick length
    if (twoFFBaxis_enabled) { // shorten ticks when we display 2 FFB monitor graphs on top of each other
      majl = int(5*wScaleY); 
      minl = int(3*wScaleY);
    }
    float n = gh/float(l); // major tick pos
    float m = n/float(p); // minor tick pos
    if (m < 8) {
      p -= 1;
      m = n/float(p);
    }
    if (m > 10) {
      p += 1;
      if (p > 10) p = 10;
      m = n/float(p);
    }

    for (int j = 0; j >= -l; j--) { // draw l+1 major ticks
      for (int k = 0; k > -p; k--) {
        int f = -1; // tick y-offset
        line(f, n*j, f-majl, n*j); // major ticks
        if (j > -l) { // only draw them before last major tick
          if (k != 0) { // do not draw minor tick on top of major tick
            line(f, m*k + n*j, f-minl, m*k + n*j); // small ticks
          }
        }
      }
    }
    popMatrix();
    for (int a=0; a<pointY.length-1; a++) {
      /*noStroke();
       fill(128, 255, 255);
       ellipse(1+a*sclX, gh/2+sclY*maxTorque, ps, ps); // min limit
       fill(0, 255, 255);
       ellipse(1+a*sclX, gh/2-sclY*maxTorque, ps, ps); // max limit*/
      //fill(32, 255, 255);
      //ellipse(1+a*sclX, gh/2-sclY*pointY[i], ps, ps); // ffb signal
      //stroke(32, 255, 255);
      strokeWeight(ps);
      stroke(map(abs(pointY[a]), 0, maxTorque, 145, 0), 255, 255);
      line(sclX*a+1, gh/2-sclY*pointY[a], sclX*(a+1)+1, gh/2-sclY*pointY[a+1]);
    }
    popMatrix();
  }
}
