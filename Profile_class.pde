class Profile {
  String name;
  float[] parm;
  String[] contents = new String[num_prfset+1];

  Profile(String n, float[] p) {
    this.name = n;
    this.parm = p;
    /*for (int i=0; i<num_prfset+1; i++) {
     if (i == 0) {
     this.contents[i] = this.name;
     } else {
     this.contents[i] = str(this.parm[i-1]);
     }
     }*/
    this.toContents();
  }

  void upload() { // upload last FFB settings to a profile
    for (int i=0; i<num_sldr; i++) {
      this.parm[i] = wParmFFBprev[i];
    }
    this.parm[num_sldr] = int(effstateprev);
    this.parm[num_sldr+1] = maxTorque;
    this.parm[num_sldr+2] = lastCPR;
    this.parm[num_sldr+3] = int(pwmstateprev);
    this.toContents();
    println(this.name, "uploaded");
  }
  void download() {  // download profile to current FFB settings
    this.fromContents();
    for (int i=0; i<num_sldr; i++) {
      wParmFFB[i] = this.parm[i];
    }
    effstate = byte(int(this.parm[num_sldr]));
    //maxTorque = int(parm[num_sldr+1]);  // do not load maxTorque from profiles
    curCPR = int(this.parm[num_sldr+2]);
    //pwmstate = byte(int(parm[num_sldr+3])); // do not load pwmstate from profiles
    println(this.name, "downloaded");
  }
  void loadFromFile(String fn) {
    this.contents = loadStrings(fn+".txt");
    this.fromContents();
  }
  void storeToFile(String fn) {
    String tempStr = "";
    int tempOpt = -1;
    if (this.name.equals("default")) {
      showMessageDialog(frame, "Can not be modified.\nSelect another profile.");
    } else {
      tempStr = showInputDialog("Save profile name as?", this.name);
      if (tempStr != null) {
        this.name = tempStr;
        cp5.get(ScrollableList.class, "profile").setItems(ProfileNameList());
        if (nameExists(name)) { // if this profile name arleady exists
          showConfirmDialog(frame, "Name already exists.\nOverwrite?");
        }
        if (tempOpt == -1 || tempOpt == 0) {
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
      } else {
        this.contents[k] = str(this.parm[k-1]);
      }
    }
    //println(this.name, "toContents");
  }
  void show() {
    for (int i=0; i<num_prfset+1; i++) {
      if (i == 0) {
        //print(this.name);
        print(this.contents[i]);
      } else {
        //print(this.parm[i-1]);
        print(this.contents[i]);
      }
      print(" ");
    }
    println("empty:", isEmpty());
  }
}
