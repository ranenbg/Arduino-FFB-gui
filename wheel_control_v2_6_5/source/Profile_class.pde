class Profile {
  String name; // profile name
  float[] parm; // ffb setting parameter
  int[] pMin = new int[num_axis-1]; // pedal min calibration limit
  int[] pMax = new int[num_axis-1]; // pedal max calibration limit
  int[] xyshCfg = new int[6]; // xy shifter calibration and config
  String pedalCalCfg, shifterCalCfg; // pedals and shifter calibration data packed into a string
  String[] contents = new String[num_prfset+1]; // we keep settings in each line of profile txt file, where 1st is profile name

  Profile(String n, float[] p, String pcfg, String scfg) {
    this.name = n;
    this.parm = p;
    this.pedalCalCfg = pcfg;
    this.shifterCalCfg = scfg;
    this.toContents();
  }

  void upload() { // upload last FFB settings from GUI to a profile
    for (int i=0; i<num_sldr; i++) {
      this.parm[i] = wParmFFBprev[i];
    }
    this.parm[num_sldr] = int(effstateprev);
    this.parm[num_sldr+1] = maxTorque;
    this.parm[num_sldr+2] = lastCPR;
    this.parm[num_sldr+3] = int(pwmstateprev);
    // pack pedals and shifter calibration settings from GUI
    // if firmware doesn't support it, pack the default values
    packPedalCal();
    packShifterCal();
    this.toContents();
    println(this.name, "uploaded");
  }

  void download() {  // download profile to current FFB settings in GUI
    //this.fromContents();
    for (int i=0; i<num_sldr; i++) {
      wParmFFB[i] = this.parm[i];
    }
    effstate = byte(int(this.parm[num_sldr]));
    //maxTorque = int(parm[num_sldr+1]);  // do not load maxTorque from profiles
    curCPR = int(this.parm[num_sldr+2]);
    //pwmstate = byte(int(parm[num_sldr+3])); // do not load pwmstate from profiles
    // unpack pedals and shifter calibration from profile (applied to arduino only if firmware supports it)
    unpackPedalCal();
    unpackShifterCal();
    println(this.name, "downloaded");
  }

  void loadFromFile(String fn) {
    this.contents = loadStrings(fn+".txt");
    this.fromContents();
  }

  void storeToFile(String fn) {
    String tempStr = "";
    int result = -1;
    if (this.name.equals("default")) {
      showMessageDialog(frame, "Can not be modified.\nSelect another profile.");
    } else {
      tempStr = showInputDialog("Save profile name as?", this.name);
      if (tempStr != null) {
        this.name = tempStr;
        cp5.get(ScrollableList.class, "profile").setItems(ProfileNameList());
        if (nameExists(this.name)) { // if this profile name arleady exists
          result = showConfirmDialog(frame, "Name already exists.\nOverwrite?");
        } 
        if (result == YES_OPTION || result == -1) {
          upload();
          saveStrings("/data/"+fn+".txt", contents);
          println(this.name, "saved as "+fn+".txt");
        }
      }
    }
  }

  String getPrfParm(int iProfile, int iParm) { // retrieve certain parameter from a given profile
    String profileContents[] = new String[num_profiles];
    profileContents = loadStrings("profile"+str(iProfile)+".txt");
    if (profileContents == null) {
      return null;
    } else {
      return profileContents[iParm];
    }
  }

  boolean nameExists(String cName) { // returns true if profile with this name already exists
    String pName;
    boolean c = false;
    for (int i=1; i<num_profiles; i++) { // look through all found profiles
      File p = new File(dataPath("profile"+str(i)+".txt"));
      if (p.exists()) {
        pName = getPrfParm(i, 0);
        if (pName.equals(cName)) {
          c = true;
        }
      }
    }
    return c;
  }

  boolean exists(int i) {
    boolean r = false;
    File p = new File(dataPath("profile"+str(i)+".txt"));
    if (p.exists()) {
      r = true;
    }
    return r;
  }

  boolean isEmpty() {
    this.fromContents();
    boolean e = true;
    for (int i=0; i<num_sldr; i++) {
      if (parm[i] != 0.0) e = false; // at least 1 slider value has to be non-zero
    }
    return e;
  }

  void fromContents() {
    for (int j=0; j<num_prfset+1; j++) {
      if (j == 0) {
        this.name = this.contents[j];
      } else if (j == 17) { // pedal calibration
        this.pedalCalCfg = this.contents[j];
      } else if (j == 18) { // shifter calibration
        this.shifterCalCfg = this.contents[j];
      } else {
        this.parm[j-1] = float(this.contents[j]);
      }
    }
    //println(this.name, "fromContents");
  }

  void toContents() {
    for (int k=0; k<num_prfset+1; k++) {
      if (k == 0) {
        this.contents[k] = this.name;
      } else if (k == 17) { // pedal calibration
        this.contents[k] = this.pedalCalCfg;
      } else if (k == 18) { // shifter calibration
        this.contents[k] = this.shifterCalCfg;
      } else {
        this.contents[k] = str(this.parm[k-1]);
      }
    }
    //println(this.name, "toContents");
  }

  void packPedalCal() {
    this.pedalCalCfg = "";
    String[] axispCals = new String[4]; // individual pedal axis cal limits
    for (int i=0; i<axispCals.length; i++) {
      if (bitRead(fwOpt, 0) == 0) {  // if bit0=0 - pedal autocalibration is disabled in firmware, we have manual pedal calibration
        this.pMin[i] = int(pdlMinParm[i]);
        this.pMax[i] = int(pdlMaxParm[i]);
      } else { // otherwise pack default pedal calibration
        this.pMin[i] = int(pdlParmDef[2*i]);
        this.pMax[i] = int(pdlParmDef[2*i+1]);
      }
      if (i != 3) {
        axispCals[i] = str(this.pMin[i]) + ' ' + str(this.pMax[i]) + ' ';
      } else {
        axispCals[i] = str(this.pMin[i]) + ' ' + str(this.pMax[i]); // do not add space at end of string
      }
      this.pedalCalCfg += axispCals[i];
    }
  }
  void unpackPedalCal() {
    int[] axispCals = int(split(this.pedalCalCfg, ' '));
    for (int j=0; j<(axispCals.length)/2; j++) {
      this.pMin[j] = axispCals[2*j]; // even
      this.pMax[j] = axispCals[2*j+1]; // odd
    }
  }
  void packShifterCal() {
    this.shifterCalCfg = "";
    for (int i=0; i<shifterLastConfig.length; i++) {
      if (XYshifterEnabled) { // if firmware supports xy shifter
        this.xyshCfg[i] = shifterLastConfig[i];
      } else { // otherwise pack default shifter calibration
        this.xyshCfg[i] = xysParmDef[i];
      }
      if (i != 5) {
        this.shifterCalCfg += str(this.xyshCfg[i]) + ' ';
      } else {
        this.shifterCalCfg += str(this.xyshCfg[i]);
      }
    }
  }
  void unpackShifterCal() {
    int[] xyshCals = int(split(this.shifterCalCfg, ' '));
    for (int j=0; j<xyshCals.length; j++) {
      this.xyshCfg[j] = xyshCals[j];
    }
  }
  // returns true if profile vales are different
  boolean checkPedalCfg() { // checks if any pedal cal parm form profile is different than curent pedal config
    boolean check = false;
    for (int i=0; i<pdlMinParm.length; i++) {
      if (this.pMin[i] != int(pdlMinParm[i]) || this.pMax[i] != int(pdlMaxParm[i])) check = true;
    }
    return check;
  }
  // returns true if profile vales are different
  boolean checkShifterCfg() { // checks if any shifter cal parm form profile is different than curent shifter config 
    boolean check = false;
    for (int i=0; i<shifterLastConfig.length; i++) {
      if (this.xyshCfg[i] != shifterLastConfig[i]) check = true;
    }
    return check;
  }

  void show() {
    for (int i=0; i<this.contents.length; i++) {
      println(this.contents[i]);
    }
  }
}
