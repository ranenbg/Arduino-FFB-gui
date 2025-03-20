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

  void show(int i) {
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
    //if (twoFFBaxis_enabled) {
      if (i == 0) { // for X-axis
        gT = "x" + gT;
      } else { // for Y-axis
        gT = "y" + gT;
        gL = "down";
        gR = "up";
      }
      textAlign(RIGHT);
      text(pointY[0], 0.25*font_size-gh/2, font_size); // X-axis value (horizontal orientation)
      text(gR, -font_size*0.4, font_size);
      textAlign(LEFT);
      text(gT, gT.length()*font_size-gh/2, font_size);
      text(gL, gL.length()*font_size*0.1 - gh, font_size);
    //}
    rotate(PI/2.0); // rotate CW by 90deg
    rectMode(CORNER);
    rect(0, 0, gwidthX, gh); // graph frame
    if (!twoFFBaxis_enabled) {
      //text(pointY[0], (-str(pointY[0]).length()*0.59-1.3)*font_size, gh/2+0.3*font_size); // ffb axis value (vertical orientation), at center of graph
    }
    //text(-maxTorque, -60, gh-5+0.3*font_size); // min ffb value indicator
    //text(maxTorque, -50, 5+0.3*font_size); // max ffb value indicator
    pushMatrix();
    translate(0, gh);
    int majl = 8; // major tick length
    int minl = 4; // minor tick length
    if (twoFFBaxis_enabled) { // shorten ticks when we display 2 FFB monitor graphs on top of each other
      majl = 5; 
      minl = 3;
    }
    int l = 32; // num of major ticks
    int p = 5; // num of minor ticks between each major tick
    float n = gh/float(l); // major tick pos
    float m = n/float(p); // minor tick pos
    for (int j = 0; j >= -l; j--) { // draw l+1 major ticks
      for (int k = 0; k > -p; k--) {
        int f = 1;
        if (j < -l/2) f = 0; // for some reason ticks after this one are shifted down by 1 pixel, this is a brute force fix
        line(f, n*j, f-majl, n*j); // major ticks
        if (j > -l) { // only draw them before last major tick
          if (k != 0) { // do not draw minor tick on top of major tick
            int t = 0;
            if (j == -l/2 && k < -p/2) t = -1;
            line(f+t, m*k + n*j, f+t-minl, m*k + n*j); // small ticks
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
