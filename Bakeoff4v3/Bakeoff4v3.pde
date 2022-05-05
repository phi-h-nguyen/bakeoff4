import java.util.ArrayList;
import java.util.Collections;
import ketai.sensors.*;
import ketai.camera.*;

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

float screenMidX = 240;
float screenMidY = 470;

int camWidth = 10;
int camHeight = 10;

int selectedQuad = -1;

boolean started = false;

int verHeight = 325;
int horWidth = 125;

void setup() {
  size(480, 940);
  frameRate(60);
  
  sensor = new KetaiSensor(this);
  sensor.start();
  
  textFont(createFont("Arial", 40));
  textAlign(CENTER);
  
  for (int i = 0; i < trialCount; i++) {
    Target t = new Target();
    t.target = ((int)random(1000)) % 4;
    t.action = ((int)random(1000)) % 2;
    targets.add(t);
    println("created target with " + t.target + "," + t.action);
  }
  
  Collections.shuffle(targets);
  
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
    
    if (index >= targets.size() && !userDone) {
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
    
    if (trialIndex >= targets.size()) {
      fill(0, 0, 0);
      text("User completed " + trialCount + " trials", width / 2, 400);
      text("User took " + nfc((finishTime - startTime) / 1000f / trialCount, 2), width / 2, 450);
      text("seconds per target", width / 2, 490);
      return;
    }
    
    fill(0, 0, 0);
    stroke(5);
    line(240, verHeight, 240, height - verHeight);
    line(horWidth, 470, width - horWidth, 470);
    Target t = targets.get(trialIndex);
    
    // top
    if (t.target == 0) fill(0, 200, 0, 100);
    else fill(200, 0, 0, 100);
    rect(50, 0, width - 100, verHeight);
    
    //left
    if (t.target == 1) fill(0, 200, 0, 100);
    else fill(200, 0, 0, 100);
    rect(0, verHeight, horWidth, height - 2 * verHeight);
    
    // right
    if (t.target == 2) fill(0, 200, 0, 100);
    else fill(200, 0, 0, 100);
    rect(width - horWidth, verHeight, horWidth, height - 2 * verHeight);
    
    // bottom
    if (t.target == 3) fill(0, 200, 0, 100);
    else fill(200, 0, 0, 100);
    rect(50, height - verHeight, width - 100, verHeight);
    
    if (t.target == selectedQuad) fill(0, 100, 0, 200);
    else fill(100, 0, 0, 200);
    if (selectedQuad == 0) rect(50, 0, width - 100, verHeight);
    else if (selectedQuad == 1) rect(0, verHeight, horWidth, height - 2 * verHeight);
    else if (selectedQuad == 2) rect(width - horWidth, verHeight, horWidth, height - 2 * verHeight);
    else if (selectedQuad == 3) rect(50, height - verHeight, width - 100, verHeight);
    
    String msg;
    fill(0, 0, 0);
    
    if (t.action == 0) msg = "Back!";
    else msg = "Front!";
    
    if (t.target == 0) text(msg, screenMidX, verHeight / 2);
    else if (t.target == 1) text(msg, horWidth / 2, screenMidY);
    else if (t.target == 2) text(msg, width - horWidth / 2, screenMidY);
    else if (t.target == 3) text(msg, screenMidX, height - verHeight / 2);
    
    fill(0, 0, 0);
    text("Trial " + (index + 1) + " of " + trialCount, width / 2, 50);
  }
  
  if (selectedQuad == -1) {
    fill(180, 0, 0);
    if (abs(curX) > abs(curY)) {
      if (started && trialIndex < targets.size()) {
        Target t = targets.get(trialIndex);
        if (t.target == 2 || t.target == 1) fill(0, 180, 0);
      }
      ellipse(240 - curX * 20, screenMidY, 50, 50);
    } else {
      if (started && trialIndex < targets.size()) {
        Target t = targets.get(trialIndex);
        if (t.target == 0 || t.target == 3) fill(0, 180, 0);
      }
      ellipse(screenMidX, 470 + curY * 40, 50, 50);
    }
  }
}

void onAccelerometerEvent(float x, float y, float z) {
  if (userDone || trialIndex >= targets.size())
    return;
  
  Target t = targets.get(trialIndex);
  
  if (t ==  null)
    return;
  
  curX = x;
  curY = y;
  if (!started || userDone) {
    return;
  }
  
  float xVal = 240 - curX * 20;
  float yVal = 470 + curY * 40;
  
  if (selectedQuad == -1) {
    if (yVal < verHeight) selectedQuad = 0;
    if (yVal > height - verHeight) selectedQuad = 3;
    if (xVal < horWidth) selectedQuad = 1;
    if (xVal > width - horWidth) selectedQuad = 2;
  }  
}

void onLightEvent(float light) {
  if (userDone || trialIndex >= targets.size()) return;
  
  Target t = targets.get(trialIndex);
  
  if (light <= proxSensorThreshold && selectedQuad != -1 && lightCountDownTimerWait < 0) {    
    if (t.target == selectedQuad && t.action == 1) {
      trialIndex ++;
    } else {
      if (trialIndex > 0) trialIndex--;
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
    
    if (t.target == selectedQuad && t.action == 0) {
      trialIndex ++;
    } else {
      if (trialIndex > 0) trialIndex--;
    }
    selectedQuad = -1;
    camCountDownTimerWait = 30;
  }
}
