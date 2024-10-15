class Dugme {
  float x;
  float y;
  float s;
  boolean enabled;

  Dugme(float posx, float posy, float size) {
    x = posx;
    y = posy;
    s = size;
    enabled = false;
  }

  void update() {
    if (gpad.getButton("0").pressed()) {
      Button[0] = true;
    } else {
      Button[0] = false;
    }
    if (gpad.getButton("1").pressed()) {
      Button[1] = true;
    } else {
      Button[1] = false;
    }
    if (gpad.getButton("2").pressed()) {
      Button[2] = true;
    } else {
      Button[2] = false;
    }
    if (gpad.getButton("3").pressed()) {
      Button[3] = true;
    } else {
      Button[3] = false;
    } 
    if (gpad.getButton("4").pressed()) {
      Button[4] = true;
    } else {
      Button[4] = false;
    }
    if (gpad.getButton("5").pressed()) {
      Button[5] = true;
    } else {
      Button[5] = false;
    }
    if (gpad.getButton("6").pressed()) {
      Button[6] = true;
    } else {
      Button[6] = false;
    }
    if (gpad.getButton("7").pressed()) {
      Button[7] = true;
    } else {
      Button[7] = false;
    }
    if (gpad.getButton("8").pressed()) {
      Button[8] = true;
    } else {
      Button[8] = false;
    }
    if (gpad.getButton("9").pressed()) {
      Button[9] = true;
    } else {
      Button[9] = false;
    }
    if (gpad.getButton("10").pressed()) {
      Button[10] = true;
    } else {
      Button[10] = false;
    }
    if (gpad.getButton("11").pressed()) {
      Button[11] = true;
    } else {
      Button[11] = false;
    }
    if (gpad.getButton("12").pressed()) {
      Button[12] = true;
    } else {
      Button[12] = false;
    }
    if (gpad.getButton("13").pressed()) {
      Button[13] = true;
    } else {
      Button[13] = false;
    }
    if (gpad.getButton("14").pressed()) {
      Button[14] = true;
    } else {
      Button[14] = false;
    }
    if (gpad.getButton("15").pressed()) {
      Button[15] = true;
    } else {
      Button[15] = false;
    }
    if (gpad.getButton("16").pressed()) {
      Button[16] = true;
    } else {
      Button[16] = false;
    }
    if (gpad.getButton("17").pressed()) {
      Button[17] = true;
    } else {
      Button[17] = false;
    }
    if (gpad.getButton("18").pressed()) {
      Button[18] = true;
    } else {
      Button[18] = false;
    }
    if (gpad.getButton("19").pressed()) {
      Button[19] = true;
    } else {
      Button[19] = false;
    }
    if (gpad.getButton("20").pressed()) {
      Button[20] = true;
    } else {
      Button[20] = false;
    }
    if (gpad.getButton("21").pressed()) {
      Button[21] = true;
    } else {
      Button[21] = false;
    }
    if (gpad.getButton("22").pressed()) {
      Button[22] = true;
    } else {
      Button[22] = false;
    }
    if (gpad.getButton("23").pressed()) {
      Button[23] = true;
    } else {
      Button[23] = false;
    }
    /*if (gpad.getButton("24").pressed()) {
     Button[24] = true;
     } else {
     Button[24] = false;
     }
     if (gpad.getButton("25").pressed()) {
     Button[25] = true;
     } else {
     Button[25] = false;
     }
     if (gpad.getButton("26").pressed()) {
     Button[26] = true;
     } else {
     Button[26] = false;
     }
     if (gpad.getButton("27").pressed()) {
     Button[27] = true;
     } else {
     Button[27] = false;
     }
     if (gpad.getButton("28").pressed()) {
     Button[28] = true;
     } else {
     Button[28] = false;
     }
     if (gpad.getButton("29").pressed()) {
     Button[29] = true;
     } else {
     Button[29] = false;
     }
     if (gpad.getButton("30").pressed()) {
     Button[30] = true;
     } else {
     Button[30] = false;
     }*/
  }

  void show(int i) {
    if (dActByp) enabled = true; // bypass the button in-activation
    int hue;
    if (buttonValue) {
      hue = 64;
    } else {
      hue = 0;
    }
    if (enabled) {
      fill(hue, 255, 255); // red
    } else {
      fill(0, 0, 100); // gray
    }
    strokeWeight(1);
    stroke(255);
    rect(x, y, s, s);
    pushMatrix();
    textSize(font_size);
    if (enabled) {
      fill(0); // black text when activated
    } else {
      fill(235); // white-ish text when de-activated
    }
    if (i<=9) {
      text(i, x+font_size/2, y+font_size*1.2);
    } else {
      text(i, x+font_size*0.15, y+font_size*1.2);
    }
    popMatrix();
  }
}
