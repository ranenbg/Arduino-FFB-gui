// input handler for a Numberbox that allows the user to 
// key in numbers with the keyboard to change the value of the numberbox
public class NumberboxInput {
  String text = "";
  Numberbox n;
  boolean active;

  NumberboxInput(Numberbox theNumberbox) {
    n = theNumberbox;
    registerMethod("keyEvent", this);
  }

  public void keyEvent(KeyEvent k) {
    // only process key event if input is active 
    if (k.getAction()==KeyEvent.PRESS && active) {
      if (k.getKey()=='\n') { // confirm input with enter
        submit();
        return;
      } else if (k.getKeyCode()==BACKSPACE) { 
        text = text.isEmpty() ? "":text.substring(0, text.length()-1);
        //text = ""; // clear all text with backspace
      } else if (k.getKey()<255) {
        // check if the input is a valid (decimal) number
        //final String regex = "\\d+([.]\\d{0,2})?";
        // check if the input is a 5 digit decimal number
        final String regex = "\\d{1,5}?";
        String s = text + k.getKey();
        if (java.util.regex.Pattern.matches(regex, s) ) {
          text += k.getKey();
        }
      }
      n.getValueLabel().setText(this.text);
    }
  }

  public void setActive(boolean b) {
    active = b;
    if (active) {
      n.getValueLabel().setText("");
      text = "";
    }
  }

  public void submit() {
    if (!text.isEmpty()) {
      n.setValue(int(text));
      text = "";
    } else {
      n.getValueLabel().setText(""+int(n.getValue()));
    }
  }
}
