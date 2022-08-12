class Graph {
  float x;
  float y;
  int gs;
  int ps;
  float pointX;
  float pointY;

  Graph(float posx, float posy, int graphsize, int pointsize) {
    x = posx;
    y = posy;
    gs = graphsize;
    ps = pointsize;
  }

  void update() {
  }

  void show() {
    int value = floor(map(Axis[0], -1, 1, 0, xAxis_log_max-1));
    pushMatrix();
    translate(x-gs/2, y-gs/2);
    fill(128, 255, 255);
    text("Y = AX + BXX + CXXX", 4, 15);
    pushMatrix();
    pushMatrix();
    fill(96, 255, 255);
    translate(gs-50, 45);
    rotate(-PI/4);
    text("Y = X", 0, 0);
    popMatrix();
    translate(gs/2, -gs/2);
    for (int i=-gs/2; i<=gs/2; i++) {
      pointX = i;  
      if (lfs_compensation == 0.0) {
      pointY = gs*(1-(correct_axis (float(i)/(gs/2))/real_wheelTurn));
      } else {
        pointY = gs*(1-(correct_axis (float(i)/(gs/2))/lfs_wheelTurn));
      }
      ellipseMode(CENTER);
      fill(128, 255, 255, 200);
      noStroke();
      ellipse(pointX, pointY, ps, ps); // graph points
    }
    stroke(127);
    int Ypos = int (correct_axis(Axis[0])/real_wheelTurn*axisScale*2);
    line(-gs/2, gs-Ypos, gs/2, gs-Ypos); // horisontal 0 line
    int Xpos = int (Axis[0]*axisScale);
    line(Xpos, gs/2, Xpos, gs/2+gs); // vertical 0 line
    stroke(96, 255, 255, 200);
    line(-gs/2, gs+gs/2, gs/2, gs/2); // diagonal (linear or 1:1) line
    popMatrix();
    noFill();
    strokeWeight(1);
    stroke(255);
    rectMode(CORNER);
    rect(0, 0, gs, gs); // graph frame
    popMatrix();

    // graph X axis
    axisValue = Axis[0]*real_wheelTurn/2;
    level = axisValue/real_wheelTurn*axisScale;
    pushMatrix();
    translate(x-axisScale, y+axisScale+17);
    rotate(PI/2);
    float n = axisScale/10.0;
    float m = n/5.0;
    for (int i = 0; i > -20; i--) {
      for (int j = 0; j > -5; j--) {
        line(0, i*n, 10, i*n);
        line(0, j*m + i*n, 5, j*m + i*n);
      }
    }
    line(0, -20*n, 10, -20*n);
    fill(255);
    pushMatrix();
    translate(0, -axisScale);
    rotate(-PI/2);
    text(value, -4, 25);
    text(axisValue, axisScale-50, 25);
    popMatrix();
    popMatrix();

    // graph X axis arrow
    pushMatrix();
    beginShape();
    translate(x, y+axisScale); // center of ruler axisScale
    //rotate(-PI/2);
    translate(level*2, 2); // moving along the ruler
    int hg = 0;
    fill(hg, 255, 255);
    strokeWeight(1);
    stroke(255);
    vertex(-4, hg+0);
    vertex(4, hg+0);
    vertex(4, hg+5);
    vertex(6, hg+5);
    vertex(0, hg+12);
    vertex(-6, hg+5);
    vertex(-4, hg+5);
    endShape();
    popMatrix();
    /*print(value);
     print(" ");
     print(a);*/

    // graph Y axis
    pushMatrix();
    axisValue = correct_axis(Axis[0]);
    level = axisValue/real_wheelTurn*axisScale;
    translate(x+axisScale+17, y+axisScale);
    //float n = axisScale/10;
    //float m = n/5;
    for (int i = 0; i > -20; i--) {
      for (int j = 0; j > -5; j--) {
        line(0, i*n, 10, i*n);
        line(0, j*m + i*n, 5, j*m + i*n);
      }
    }
    line(0, -20*n, 10, -20*n);
    fill(255);
    //text(value, 0, -(2*n+1)*10);
    //text(axisValue, 0, 20);
    text(axisValue, 20, -(2*n)*10+4);
    float minlock = -axisScale+float(lfs_car_wheelTurn)/float(real_wheelTurn)*axisScale;
    float maxlock = -minlock -axisScale*2;
    strokeWeight(3);
    stroke(128, 255, 255);
    line(14, minlock, 20, minlock); // min lock limit (red)
    line(14, maxlock, 20, maxlock); // max lock limit (green)
    strokeWeight(1);
    popMatrix();

    // graph Y axis arrow
    pushMatrix();
    beginShape();
    translate(x+axisScale/2+2, y); // center of ruler axisScale
    rotate(-PI/2);
    translate(level*2, 0); // moving along the ruler
    hg = 128;
    fill(hg, 255, 255);
    strokeWeight(1);
    stroke(255);
    vertex(-4, hg+0);
    vertex(4, hg+0);
    vertex(4, hg+5);
    vertex(6, hg+5);
    vertex(0, hg+12);
    vertex(-6, hg+5);
    vertex(-4, hg+5);
    endShape();
    popMatrix();
    /*print(value);
     print(" ");
     print(a);*/
  }
}
