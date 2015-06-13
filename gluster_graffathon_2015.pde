import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

// Constants
int CANVAS_WIDTH = 1024;
int CANVAS_HEIGHT = 768;
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

void stairs(int time, float beat) {
  pushMatrix();
  
  lights();
  rotateY(-time * 0.0005);
  translate(0, time * 0.05, 0);
  fill(100, 100, 100);
  float towerWidth = CANVAS_WIDTH/6;
  
  int towerHeight = 4*CANVAS_HEIGHT;
  translate(0, -CANVAS_HEIGHT, 0);
  box(towerWidth, towerHeight, towerWidth);
  
  int amountOfStairs = 5;
  float stairWidth = towerWidth/amountOfStairs;
  float stairHeight = CANVAS_WIDTH/100;
  float stairDepth = towerWidth/10;
  //float stairDepth = stairWidth;
  float heightDifferenceBetweenSteps = (int) (1.7 * stairHeight);
  translate(-0.5*towerWidth, 1.1*CANVAS_HEIGHT, (towerWidth + stairDepth)/2);
  
  for (int k = 0; k < 28; k++) {
    for (int i = 0; i < amountOfStairs; i++) {
      fill(100+150/((i*k+k) + 1), 100, 150);
      
      if(beat % 2.0 < 1.0 && (i+k+time*0.001) % 3.0 < 1.0) {
        fill(255, 255, 255);
      }
      
      translate(stairWidth, -heightDifferenceBetweenSteps, 0);
      box(stairWidth, stairHeight, stairDepth);
    }
    
    rotateY(PI/2);

    translate((stairDepth)/2, 0, (stairDepth)/2);
  }
  
  /*for (int i = 0; i < amountOfStairs; i++) {
    fill(200, 100, 150);
    box(stairWidth, stairHeight, stairDepth);
    translate(stairWidth, -heightDifferenceBetweenSteps, 0);
  }
*/
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
  
  stairs(time, beat);
}

