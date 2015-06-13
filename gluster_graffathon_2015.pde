import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

// Constants
int CANVAS_WIDTH = 1920;
int CANVAS_HEIGHT = 1080;
float TEMPO = 123.0; // beats/minute
float BEAT_DURATION = 60.0 / TEMPO; // seconds 
int SKIP_DURATION = round(4.0 * 1000.0 * BEAT_DURATION); // milliseconds
float PREDELAY_DURATION = 5.0; // seconds

// Global state
Minim minim;
AudioPlayer song;
boolean predelay = true; // are we still in the pre-delay period?

void setupAudio() {
  minim = new Minim(this);
  song = minim.loadFile("assets/Vector Space Odyssey.mp3");
}

float getSeconds() {
  return 0.001 * song.position();   
}

float getBeats() {
  return getSeconds() / BEAT_DURATION;
}

void setup() {
  size(CANVAS_WIDTH, CANVAS_HEIGHT, P3D);

  noStroke();
  background(0);
  rectMode(CENTER);
  frameRate(60);
  fill(255);
  smooth();
  textSize(32);
  
  setupAudio();
}

void keyPressed() {
  if(predelay) {
    return;
  }
  
  if(key == CODED) {
    // Left/right arrow keys: seek song
    boolean isLeft = keyCode == LEFT;
    boolean isRight = keyCode == RIGHT;
    if(isLeft || isRight) {
      song.skip((isLeft ? -1 : 1) * SKIP_DURATION);  
    }
  } else if(key == ' ') {
    // Space: play/pause
    if(song.isPlaying()) {
      song.pause();
    } else {
      song.play();
    }
  } else if(key == ENTER) {
    // Enter: spit out the current position (for syncing)
    println("" + getBeats() + " b / " + getSeconds() + " s");
  }
}

void stairs(int time) {
  pushMatrix();
  rotateY(time * 0.0005);
  fill(100, 100, 100);
  int towerWidth = CANVAS_WIDTH/4;
  int towerHeight = CANVAS_HEIGHT;
  box(towerWidth, towerHeight, towerWidth);
  
  int amountOfStairs = 5;
  int stairWidth = (CANVAS_WIDTH/4)/amountOfStairs;
  int stairHeight = 8;
  int stairDepth = 20;
  int heightDifferenceBetweenSteps = (int) (1.7 * stairHeight);
  translate(-CANVAS_WIDTH/8 - stairWidth/2, CANVAS_HEIGHT/4, (towerWidth + stairDepth)/2);
  
  for (int i = 0; i < amountOfStairs; i++) {
    fill(100, 100, 150);
    translate(stairWidth, -heightDifferenceBetweenSteps, 0);
    box(stairWidth, stairHeight, stairDepth);
  }
  
  translate(stairWidth+(stairDepth-stairWidth)/2, 0, (stairDepth-stairWidth)/2);
  rotateY(PI/2);
  
  for (int i = 0; i < amountOfStairs; i++) {
    fill(200, 100, 150);
    box(stairWidth, stairHeight, stairDepth);
    translate(stairWidth, -heightDifferenceBetweenSteps, 0);
  }

  popMatrix();
}

void draw() {
  if(predelay) {
    if(0.001 * millis() < PREDELAY_DURATION) {
      return;      
    }
    
    // Predelay ended, start the song
    predelay = false;
    song.play();
  }
  
  resetMatrix();
  clear();
  
  float beat = getBeats();
  float beat_flash = 1.0 - beat % 1.0;
  
  int time = millis();
  
  translate(0,0,-0.6*CANVAS_WIDTH); // needed in 3D mode
  
  // EFFECTS:
  
  if(beat % 2.0 < 1.0) {
    background(255.0 * 0.33 * beat_flash, 0, 0);    
  } else {
    background(0, 255.0 * 0.33 * beat_flash, 0);
  }
  
  text("" + beat, 20, 0.5 * CANVAS_HEIGHT);
  
  stairs(time);
}

