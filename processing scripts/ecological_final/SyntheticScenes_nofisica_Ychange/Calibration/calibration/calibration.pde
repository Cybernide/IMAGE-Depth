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

PVector pos1 = new PVector(0,0);
PVector pos2 = new PVector(0,0);
PVector pos3 = new PVector(0,0);

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
float x1 = 0.2;
float x2 = 0.6;
float x3 = 0.7;
float x4 = 0.3;

float z1 = 0.85;
float z2 = 0.28;
float z3 = 0.71;
float z4 = 0.45;

/* initialization of pings */
SoundFile ping1;
SoundFile ping2;
SoundFile ping3;
SoundFile ping4;

/** Params */
// spring walls defining scene size 
HapticBox[] walls = {
   // walls
   new HapticBox(-0.095,0.03,0.02,0.15), //max (-0.11,0.03,0.01,0.18)    TOP HORIZONTAL 
   new HapticBox(-0.095,0.03,0.1,0.02),  //max (-0.11,0.03,0.1,0.01)     LEFT VERTICAL
   new HapticBox(0.035,0.03,0.1,0.02),   //max (0.06,0.03,0.1,0.01)      RIGHT VERTICAL
   new HapticBox(-0.095,0.125,0.02,0.15)   //max (-0.09,0.125,0.02,0.18) BOTTOM HORIZONTAL
};


/** Main thread */
void setup() {
  size(1000, 650);
  frameRate(baseFrameRate);
  filt = new Butter2();
  
  
  /* ping definitions */
  ping1 = new SoundFile(this, "yping1.mp3");
  ping2 = new SoundFile(this, "yping2.mp3");
  ping3 = new SoundFile(this, "yping3.mp3");
  ping4 = new SoundFile(this, "yping4.mp3");
    
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
    println("X Position of Cursor is : " + (posEE.x * pixelsPerMeter) + "   Y Position of Cursor is: " + (posEE.y * pixelsPerMeter));
  }
  else if (key == 'w') {
    saveTable(log, "log.csv");
  }
  else if (key == 'x') {
    exit();
  }
  else if (key == '1') {
    pos1 = posEE.copy();
    println(pos1);
  }
  else if (key == '2') {
    pos2 = posEE.copy();
    println(pos2);
  }
  else if (key == '3') {
    println("Length in X is: " + (pos2.x - pos1.x) + "   Length in Y is: " + (pos2.y - pos1.y));
  }
  else if (key == '4') {
    println("New Pixel per Meter value along X" + ((pos2.x - pos1.x)* pixelsPerMeter)/0.1 + "   New Pixel per Meter value along Y" + ((pos2.y - pos1.y)* pixelsPerMeter)/0.1);
  }
  
}

/** Helper */
PVector device_to_graphics(PVector deviceFrame) {
  return deviceFrame.set(-deviceFrame.x, deviceFrame.y);
}

PVector graphics_to_device(PVector graphicsFrame) {
  return graphicsFrame.set(-graphicsFrame.x, graphicsFrame.y);
}
