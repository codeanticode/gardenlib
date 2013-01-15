// Simple soft float class to implement smooth animations
class SoftFloat {
  float ATTRACTION = 0.1;
  float DAMPING = 0.5;

  float value;
  float velocity;
  float acceleration;

  boolean enabled;  
  boolean targeting;
  float source;
  float target;

  SoftFloat() {
    value = source = target = 0;
    targeting = false;
    enabled = true;
  }

  void set(float v) {
    value = v;
    targeting = false;
  }  

  float get() {
    return value;
  }

  int getInt() {
    return (int)value;
  }

  void enable() {
    enabled = true;
  }

  void disable() {
    enabled = false;
  }


  boolean update() {
    if (!enabled) return false;

    if (targeting) {
      acceleration += ATTRACTION * (target - value);
      velocity = (velocity + acceleration) * DAMPING;
      value += velocity;
      acceleration = 0;
      if (abs(velocity) > 0.0001) {
        return true;
      }
      // arrived, set it to the target value to prevent rounding error
      value = target;
      targeting = false;
    }
    return false;
  }

  void setTarget(float t) {
    targeting = true;
    target = t;
    source = value;
  }

  float getTarget() {
    return targeting ? target : value;
  }
}

