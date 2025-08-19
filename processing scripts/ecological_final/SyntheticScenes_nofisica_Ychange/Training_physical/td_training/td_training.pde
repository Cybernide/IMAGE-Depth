import processing.serial.*;
import static java.util.concurrent.TimeUnit.*;
import java.util.concurrent.*;
import java.lang.System;
import processing.sound.*;
import controlP5.*;
import netP5.*;
import oscP5.*;

private final ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(2);

public enum HaplyVersion {
  V2,
  V3,
  V3_1
}

final HaplyVersion version = HaplyVersion.V3_1;
ControlP5 cp5;
//Knob k, b, maxAL, maxAH;
long currTime, lastTime = 0;

/** 2DIY setup */
Board haplyBoard;
Device widget;
Mechanisms pantograph;

byte widgetID = 5;
int CW = 0;
int CCW = 1;
boolean renderingForce = false; 
long baseFrameRate = 120;
ScheduledFuture<?> handle;
Filter filt;
Table log;

PVector angles = new PVector(0, 0);
PVector torques = new PVector(0, 0);
PVector posEE = new PVector(0, 0);
PVector posEELast = new PVector(0, 0);
PVector velEE = new PVector(0, 0);
PVector fEE = new PVector(0, 0);

// haptic values for all circles
float k = 200;
float mu = 0;
float maxAL = 0.47;
float maxAH = 0.32;

final float targetRate = 1000f;
final float textureConst = 2*PI/targetRate;
PVector fText = new PVector(0, 0);
int boxnum = 0;

// object position
float x1 = 0.17;
float x2 = 0.50;
float x3 = 0.74;

float z1 = 0.35;
float z2 = 0.71;
float z3 = 0.47;

/* initialization of TTS */
SoundFile dog1;
SoundFile dog2;
SoundFile flowerpot;

// French or English
public enum Language {
  french,
  english
}

final Language lang = Language.english;

/** Params */
// haptic circles within the scene
HapticSwatch[] objects = {
  new HapticSwatch(-0.075 +(0.1*x1), 0.125 - (0.075 *z1), 0.007), // object radius is 0.005 and end effector radius is 0.002. Rather than increase the end effector size, simply increased the object sizes to match
  new HapticSwatch(-0.075 +(0.1*x2), 0.125 - (0.075 *z2), 0.007),
  new HapticSwatch(-0.075 +(0.1*x3), 0.125 - (0.075 *z3), 0.007)
};
// spring walls defining scene size 
HapticBox[] walls = {
   // walls
   new HapticBox(-0.095,0.03,0.02,0.15), //max (-0.11,0.03,0.01,0.18)    TOP HORIZONTAL 
   new HapticBox(-0.095,0.03,0.12,0.02),  //max (-0.11,0.03,0.1,0.01)     LEFT VERTICAL
   new HapticBox(0.035,0.03,0.12,0.02),   //max (0.06,0.03,0.1,0.01)      RIGHT VERTICAL
   new HapticBox(-0.095,0.125,0.02,0.15)   //max (-0.09,0.125,0.02,0.18) BOTTOM HORIZONTAL
};
// dampening boxes, not used but kept for future
HapticBox[] dampeners = {
   // walls
   //new HapticBox(-0.09,0.03,0.025,0.18), //max (-0.11,0.03,0.01,0.18)
   //new HapticBox(-0.09,0.03,0.1,0.025),  //max (-0.11,0.03,0.1,0.01)
   //new HapticBox(0.04,0.03,0.1,0.025),   //max (0.06,0.03,0.1,0.01)
   //new HapticBox(-0.09,0.125,0.025,0.18)   //max (-0.09,0.125,0.02,0.18)
};

/** Main thread */
void setup() {
  size(1000, 650);
  frameRate(baseFrameRate);
  filt = new Butter2();
  
  for (HapticSwatch s : objects) {
    s.setHaptics(k,mu,maxAL,maxAH);
  }
  
  /* ping definitions */
  if (lang == Language.english){
    println("English language selected");
    dog1 = new SoundFile(this, "dog1.wav");
    dog2 = new SoundFile(this, "dog2.wav");
    flowerpot = new SoundFile(this, "flowerpot.wav");
  } else {
    println("French language selected");
    dog1 = new SoundFile(this, "chien1.wav");
    dog2 = new SoundFile(this, "chien2.wav");
    flowerpot = new SoundFile(this, "potsdefleurs.wav");
  }
  ///*table setup */
  log = new Table();
  log.addColumn("time");
  log.addColumn("x");
  log.addColumn("y");
  log.addColumn("Object");
    
  /** Haply */
  haplyBoard = new Board(this, Serial.list()[0], 0);
  widget = new Device(widgetID, haplyBoard);
  if (version == HaplyVersion.V2) {
    pantograph = new Pantograph();
    widget.set_mechanism(pantograph);
    widget.add_actuator(1, CCW, 2);
    widget.add_actuator(2, CW, 1);
    widget.add_encoder(1, CCW, 241, 10752, 2);
    widget.add_encoder(2, CW, -61, 10752, 1);
  } else if (version == HaplyVersion.V3 || version == HaplyVersion.V3_1) {
    pantograph = new Pantographv3();
    widget.set_mechanism(pantograph);
    widget.add_actuator(1, CCW, 2);
    widget.add_actuator(2, CCW, 1);
    if (version == HaplyVersion.V3) {
      widget.add_encoder(1, CCW, 97.23, 2048*2.5*1.0194*1.0154, 2);   //right in theory
      widget.add_encoder(2, CCW, 82.77, 2048*2.5*1.0194, 1);    //left in theory
    } else {
      widget.add_encoder(1, CCW, 168, 4880, 2);
      widget.add_encoder(2, CCW, 12, 4880, 1); 

    }
  }
  widget.device_set_parameters();
  panto_setup();
  
  /** Spawn haptics thread */
  SimulationThread st = new SimulationThread();
  handle = scheduler.scheduleAtFixedRate(st, 1000, (long)(1000000f / targetRate), MICROSECONDS);
}

void exit() {
  handle.cancel(true);
  scheduler.shutdown();
  widget.set_device_torques(new float[]{0, 0});
  widget.device_write_torques();
  saveTable(log, "log.csv");
  super.exit();
}

void draw() {
  if (renderingForce == false) {
    background(255);
    for (HapticSwatch s : objects) {
      shape(create_ellipse(s.center.x, s.center.y, s.radius, s.radius));
    }
    for (HapticBox s : walls) {
      shape(create_box(s.topLeft.x, s.topLeft.y, s.L, s.W));
    }
    update_animation(angles.x * radsPerDegree, angles.y * radsPerDegree, posEE.x, posEE.y);
    fill(0, 0, 0);
    fill(255, 255, 255);
  }
}

void keyPressed() {
  if (key == 'c') {
    print(" Position of Cursor is : " + posEE + "    ");
  }
  else if (key == 'w') {
    saveTable(log, "log.csv");
  }
  else if (key == 'x') {
    exit();
  }
}

/** Helper */
PVector device_to_graphics(PVector deviceFrame) {
  return deviceFrame.set(-deviceFrame.x, deviceFrame.y);
}

PVector graphics_to_device(PVector graphicsFrame) {
  return graphicsFrame.set(-graphicsFrame.x, graphicsFrame.y);
}
