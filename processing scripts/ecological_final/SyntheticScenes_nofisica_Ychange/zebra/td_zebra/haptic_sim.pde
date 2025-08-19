/** Haptics simulation */
class SimulationThread implements Runnable {
  float samp = 0;
  boolean leave = false;
  boolean inside = false;
  int wallcount = 0;
  PVector pushdir_right = new PVector(1,0,0) ;
  PVector pushdir_left = new PVector(-1,0,0) ;
  PVector pushdir_up = new PVector(0,-1,0) ;
  PVector pushdir_down = new PVector(0,1,0) ;
  int framecount = 0;
  int circlenum = 0;
  int circletouch = 0;
  boolean ping = true;
  float k_walls = 10;
  PVector fDamp = new PVector(0, 0);
  
  public void run() {
    renderingForce = true;
    PVector force = new PVector(0, 0);
    lastTime = currTime;
    currTime = System.nanoTime();
    if (haplyBoard.data_available()) {
      widget.device_read_data();
      angles.set(widget.get_device_angles());
      posEE.set(widget.get_device_position(angles.array()));
      posEE.set(device_to_graphics(posEE));
      velEE.set(PVector.mult(PVector.sub(posEE, posEELast),((1000000000f)/(currTime-lastTime))));
      // LPF
      filt.push(velEE.copy());
      velEE.set(filt.calculate());
      
      posEELast.set(posEE);
      
      final float speed = velEE.mag();
      
      // Calculate force
      framecount = framecount + 1;
      for (HapticSwatch s : objects) {
        circlenum = circlenum + 1;
        PVector rDiff = posEE.copy().sub(s.center);
        if (rDiff.mag() < s.radius) {
          if (!s.active) {
            s.active = true;
            s.onsetFlag = true;
          }
          
          // Spring
          rDiff.setMag(s.radius - rDiff.mag());
          force.set(force.add(rDiff.mult(s.k)));
          
          // Friction
          final float vTh = 0.1;
          final float mass = 0.25; // kg
          final float fnorm = mass * 9.81; // kg * m/s^2 (N)
          final float b = fnorm * s.mu / vTh; // kg / s

          if (speed < vTh) {
            force.set(force.add(velEE.copy().mult(-b)));
          } else {
            force.set(force.add(velEE.copy().setMag(-s.mu * fnorm)));
          }
          // Texture
          final float maxV = vTh;
          fText.set(velEE.copy().rotate(HALF_PI).setMag(
              min(s.maxAH, speed * s.maxAH / maxV) * sin(textureConst * 150f * samp) +
              min(s.maxAL, speed * s.maxAL / maxV) * sin(textureConst * 25f * samp)
          ));
          force.set(force.add(fText));
          
           //Dampening 
           //println(velEE.mag());
           //fDamp.set(velEE.copy());
          fDamp.set(velEE.copy().setMag(velEE.mag() * -0.3));
          force.set(force.add(fDamp));
          
          circletouch = circlenum;
          
          if (circlenum == 1 && ping){
            zebra1.play();
            ping = false;
          } else if (circlenum == 2  && ping){
            zebra2.play();
            ping = false;
          }else if (circlenum == 3  && ping){
            zebra3.play();
            ping = false;
          }else if (circlenum == 4 && ping){
            zebra4.play();
            ping = false;
          }else if (circlenum == 5 && ping){
            zebra5.play();
            ping = false;
          }
          
        } else {
          if (s.active) {
            s.active = false;
            s.offsetFlag = true;
            ping = true;
          }
        }
      }
      
      circlenum = 0;
      circletouch = 0;
      
      for (HapticBox s : walls) {
        wallcount = wallcount + 1;
        if ((posEE.x >= s.getTopLeft().x) && (posEE.x <= s.getTopRight().x) && (posEE.y >= s.getTopLeft().y) && (posEE.y <= s.getBottomLeft().y)) {
          
          if (!s.active) {
            s.active = true;
            s.onsetFlag = true;
          }
           //Spring
          if (wallcount == 1){
            float k_portion = 1-((posEE.copy().y - s.getTopLeft().y)/s.getLength());
            force.set(force.add(pushdir_down.copy().mult(k_walls * k_portion)));
          }
          if (wallcount == 2){
            float k_portion = 1-((posEE.copy().x - s.getTopLeft().x)/s.getWidth());
            force.set(force.add(pushdir_right.copy().mult(k_walls * k_portion)));         
          }
          if (wallcount == 3){
            float k_portion = 1+((posEE.copy().x - s.getTopRight().x)/s.getWidth());
            force.set(force.add(pushdir_left.copy().mult(k_walls * k_portion)));
          }
          if (wallcount == 4){
            float k_portion = 1+((posEE.copy().y - s.getBottomLeft().y)/s.getLength());
            force.set(force.add(pushdir_up.copy().mult(k_walls * k_portion)));
          }
          
          // Friction
          //final float vTh = 0.25; // vibes based, m/s
          //final float vTh = 0.015;
          final float vTh = 0.1;
          final float mass = 0.25; // kg
          final float fnorm = mass * 9.81; // kg * m/s^2 (N)
          final float b = fnorm * s.mu / vTh; // kg / s
          //print(b +"//////////////");
          //print(velEE + "lllllllllllllllllll");
          //if (speed < vTh) {
          //  force.set(force.add(velEE.copy().mult(-b)));
          //} else {
          //  force.set(force.add(velEE.copy().setMag(-s.mu * fnorm)));
          //}
          // Texture
          final float maxV = vTh;
          fText.set(velEE.copy().setMag(velEE.mag() * -1));
          //force.set(force.add(fText));
          if (inside == false){
            //print("  WALL " + wallcount +" Angles: " + angles + "     ");
            inside = true;
            leave = false;
          }
        } else {
          if (s.active) {
            s.active = false;
            s.offsetFlag = true;
            if (inside ) {
              inside = false;     
              if (leave == false){
                leave = true;
                //print("   WALL Angles: " + angles + "     ");
              }
            }
          }
        }
      }
      for (HapticBox s : dampeners) {
        wallcount = wallcount + 1;
        if ((posEE.x >= s.getTopLeft().x) && (posEE.x <= s.getTopRight().x) && (posEE.y >= s.getTopLeft().y) && (posEE.y <= s.getBottomLeft().y)) {
          
          if (!s.active) {
            s.active = true;
            s.onsetFlag = true;
          }
          
          // Friction
          final float vTh = 0.1;
          final float mass = 0.25; // kg
          final float fnorm = mass * 9.81; // kg * m/s^2 (N)
          final float b = fnorm * s.mu / vTh; // kg / s
          if (speed < vTh) {
            force.set(force.add(velEE.copy().mult(-b)));
          } else {
            force.set(force.add(velEE.copy().setMag(-s.mu * fnorm)));
          }
          // Dampening
          //final float maxV = vTh;
          fText.set(velEE.copy().setMag(velEE.mag() * -1));
          //force.set(force.add(fText));
          if (inside == false){
            print("  Damp " + wallcount +" Velocity: " + velEE + "     ");
            println("  Damp " + wallcount +" opposing Velocity: " + velEE.copy().setMag(velEE.mag() * -1) + "     ");
            inside = true;
            leave = false;
          }
        } else {
          if (s.active) {
            s.active = false;
            s.offsetFlag = true;
            if (inside ) {
              inside = false;     
              if (leave == false){
                leave = true;
              }
            }
          }
        }
      }
      if (framecount > 10){
          TableRow newRow= log.addRow(); 
          long starttime = System.nanoTime();
          newRow.setLong("time",starttime);
          newRow.setFloat("x",posEE.x);
          newRow.setFloat("y",posEE.y);    
          newRow.setInt("Object",circletouch);
          framecount = 0;
      }
      wallcount = 0;
      samp = (samp + 1) % targetRate;
      fEE.set(graphics_to_device(force));
    }
    torques.set(widget.set_device_torques(fEE.array()));
    widget.device_write_torques();
    renderingForce = false;
  }
}
