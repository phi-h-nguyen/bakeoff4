import java.util.ArrayList;
import java.util.Collections;
import ketai.sensors.*;
import ketai.camera.*;

import processing.sound.*;
AudioIn input;
Amplitude analyzer;


KetaiCamera cam;
KetaiSensor sensor;
float light = 0; 
float proxSensorThreshold = 5; //you will need to change this per your device.

private class Target
{
  int target = 0;
  int action = 0;
}

int trialCount = 10; //this will be set higher for the bakeoff
int trialIndex = 0;
ArrayList<Target> targets = new ArrayList<Target>();

int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
boolean userDone = false;
int camCountDownTimerWait = 0;
int lightCountDownTimerWait = 0;

float curX = 0;
float curY = 0;
float curZ = 0;

float screenMidX = 240;
float screenMidY = 470;
float screenMaxX = 480;
float screenMaxY = 940;
int camWidth = 10;
int camHeight = 10;

int selectedQuad = -1;

final String file = "test.jpg";

boolean started = false;

void setup() {
  size(480, 940); //you should change this to be fullscreen per your phones screen
  frameRate(60);
  
  sensor = new KetaiSensor(this);
  sensor.start();
  
  textFont(createFont("Arial", 40)); //sets the font to Arial size 20
  textAlign(CENTER);
  
  for (int i = 0; i < trialCount; i++) {
    Target t = new Target();
    t.target = ((int)random(1000)) % 4;
    t.action = ((int)random(1000)) % 2;
    targets.add(t);
    println("created target with " + t.target + "," + t.action);
  }
  
  Collections.shuffle(targets); // randomize the order of the button;
  
  cam = new KetaiCamera(this, camWidth, camHeight, 30);
  // 0: back camera; 1: front camera
  cam.setCameraID(0);
}

void draw() {
  background(80); 
  
  if (!started) {
    fill(0, 0, 0);
    text("Click anywhere to start!", width / 2, 490);
  } else {
    int index = trialIndex;
    
    camCountDownTimerWait--;   
    lightCountDownTimerWait--;  
    
    if (index >=  targets.size() && !userDone) {
      userDone = true;
      finishTime = millis();
      cam.stop();   
    }
    
    if (userDone) {
      fill(0, 0, 0);
      text("User completed " + trialCount + " trials", width / 2, 400);
      text("User took " + nfc((finishTime - startTime) / 1000f / trialCount, 2), width / 2, 450);
      text("seconds per target", width / 2, 490);
      return;
    }
    
    fill(0, 0, 0);
    text("Trial " + (index + 1) + " of " + trialCount, width / 2, 50);
    
    line(240, 0, 240, 940);
    line(0, 470, 480, 470);
    
    fill(150, 200, 0, 100);
    
    if (trialIndex >=  targets.size()) {
      fill(0, 0, 0);
      text("User completed " + trialCount + " trials", width / 2, 400);
      text("User took " + nfc((finishTime - startTime) / 1000f / trialCount, 2), width / 2, 450);
      text("seconds per target", width / 2, 490);
      return;
    }

    String msg;
    Target t = targets.get(trialIndex);
    fill(0, 200, 0, 50);
    if (t.action == 0) msg = "Back!";
    else msg = "Front!";
    if (t.target == 0) {
      rect(0, 0, screenMidX, screenMidY);
      fill(0, 0, 0);
      text(msg, screenMidX / 2, screenMidY / 2);
    }
    if (t.target == 1) {
      rect(screenMidX, 0, screenMidX, screenMidY);
      fill(0, 0, 0);
      text(msg, screenMidX * 1.5, screenMidY / 2);
    }
    if (t.target == 2) {
      rect(0, screenMidY, screenMidX, screenMidY);
      fill(0, 0, 0);
      text(msg, screenMidX / 2, screenMidY * 1.5);
    }
    if (t.target == 3) {
      rect(screenMidX, screenMidY, screenMidX, screenMidY);
      fill(0, 0, 0);
      text(msg, screenMidX * 1.5, screenMidY * 1.5);
    }
    
    fill(0, 200, 0, 100);
    if (selectedQuad == 0) rect(0, 0, screenMidX, screenMidY);
    if (selectedQuad == 1) rect(screenMidX, 0, screenMidX, screenMidY);
    if (selectedQuad == 2) rect(0, screenMidY, screenMidX, screenMidY);
    if (selectedQuad == 3) rect(screenMidX, screenMidY, screenMidX, screenMidY);
    
  }
  
  if (selectedQuad == -1) {
    fill(180, 0, 0);
    ellipse(240 - curX * 20, 470 + curY * 40, 50, 50);
  }
}

void onAccelerometerEvent(float x, float y, float z) {
  if (userDone || trialIndex >=  targets.size())
    return;
  
  Target t = targets.get(trialIndex);
  
  if (t ==  null)
    return;
  
  curX = x;
  curY = y;
  curZ = z;
  if (!started || userDone) {
    return;
  }
  
  if (selectedQuad == -1) {
    if (curX > 3) {
      if (curY < - 3) selectedQuad = 0;
      else if (curY > 3) selectedQuad = 2;
    } else if (curX < - 3) {
      if (curY < - 3) selectedQuad = 1;
      else if (curY > 3) selectedQuad = 3;
    } 
  }  
}

void onLightEvent(float light) {
  if (userDone || trialIndex >=  targets.size()) return;
    
  Target t = targets.get(trialIndex);
  
  if (light <= proxSensorThreshold && selectedQuad != -1 && lightCountDownTimerWait < 0) {
    println("CLICKED FRONT");
    
    if (t.target == selectedQuad && t.action == 1) {
      trialIndex ++;
      println("Corrrect!");
    } else {
      if (trialIndex > 0) trialIndex--;
      println("Wrong!");
    }
    
    selectedQuad = -1;
    lightCountDownTimerWait = 30;
  }
}

void mousePressed() {
  if (!userDone) {
    started = true;
    
    if (!cam.isStarted())
      cam.start();    
  }
  if (startTime == 0) startTime = millis();
}

void onCameraPreviewEvent() {
  
  if (camCountDownTimerWait > 0 || userDone || trialIndex >= targets.size()) return;
  
  Target t = targets.get(trialIndex);
  
  cam.read();
  cam.loadPixels();
  float avgB = 0;
  for (int i = 0; i < cam.pixels.length; i++) {
    avgB += brightness(cam.pixels[i]);
  }
  avgB /= cam.pixels.length;
  if (avgB < 40 && selectedQuad != -1) {
    println("CLICKED BACK");
    
    if (t.target == selectedQuad && t.action == 0) {
      trialIndex ++;
      println("Corrrect!");
    } else {
      if (trialIndex > 0) trialIndex--;
      println("Wrong!");
    }
    selectedQuad = -1;
    camCountDownTimerWait = 30;
  }
}
