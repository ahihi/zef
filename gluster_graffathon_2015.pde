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

// Global state
Minim minim;
AudioPlayer song;

void setupAudio() {
  minim = new Minim(this);
  song = minim.loadFile("assets/Vector Space Odyssey.mp3");
  song.play();
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
  frameRate(60);
  fill(255);
  smooth();
  textSize(32);
  
  setupAudio();
}

void keyPressed() {
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

void draw() {
  float beat = getBeats();
  float beat_flash = 1.0 - beat % 1.0; 
  
  if(beat % 2.0 < 1.0) {
    background(255.0 * 0.33 * beat_flash, 0, 0);    
  } else {
    background(0, 255.0 * 0.33 * beat_flash, 0);
  }
  
  text("" + beat, 20, 0.5 * CANVAS_HEIGHT);
}
