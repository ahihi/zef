import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

abstract class Scene {
  public float duration; // scene duration in beats
  
  public Scene(float duration) {
      this.duration = duration;
  }
  
  public void setup() {}
  public void draw(float beats) {}
}

class Timeline {
  public Minim minim;
  public AudioPlayer song;
  public int currentScene; // index of current scene
  public float currentStartTime;
  public float currentEndTime;
  public ArrayList<Scene> scenes;
  
  public Timeline(Object processing, String songPath) {
    this.minim = new Minim(processing);
    this.song = minim.loadFile(songPath);

    this.currentScene = -1;
    this.scenes = new ArrayList<Scene>();
  }
  
  public void addScene(Scene scene) {
    this.scenes.add(scene);
  }
  
  public void drawScene() {
    float beats = 0.001 * song.position() / BEAT_DURATION;

    Scene scene = null;
    boolean sceneChanged = false;
    
    if(this.currentScene >= 0 && this.currentStartTime <= beats && beats < this.currentEndTime) {
      scene = this.scenes.get(this.currentScene);
    }
    
    boolean terminated = false;
    float accumStartTime = 0.0;
    for(int i = 0; i < this.scenes.size(); i++) {
      scene = this.scenes.get(i);
      float endTime = accumStartTime + scene.duration;
      if(accumStartTime <= beats && beats < endTime) {
          terminated = true;
          sceneChanged = i != this.currentScene;
          
          this.currentScene = i;
          this.currentStartTime = accumStartTime;
          this.currentEndTime = endTime;
          
          break;
      }
      accumStartTime += scene.duration;
    }
    
    if(!terminated) {
      this.currentScene = -1;      
    }
    
    if(this.currentScene < 0) {
      background(0);
      return; 
    }
    
    if(sceneChanged) {
      // Scene changed, set up the new one
      scene.setup();
    }
    
    scene.draw(beats - this.currentStartTime);
  }
}

float beatsToSecs(float beats) {
  return beats * BEAT_DURATION;
}

// Scenes

class TestScene extends Scene {
  public boolean green;
  
  public TestScene(float duration, boolean green) {
    super(duration);
    this.green = green;
  }
  
  void setup() {
    textSize(32);
    noStroke();
    fill(255);    
  }
  
  void draw(float beats) {
    if(this.green) {
      background(0, 255, 0);      
    } else {
      background(255, 0, 0);
    }
    text("" + beats, 10, 0.5 * CANVAS_HEIGHT);
  }
}

class StairsScene extends Scene {
  public StairsScene(float duration) {
    super(duration);
  }
  
  void setup() {}
  
  void draw(float beats) {
    int time = round(beatsToSecs(beats) * 1000.0);
    pushMatrix();
    translate(0,0,-0.6*CANVAS_WIDTH); // needed in 3D mode
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
}

// Constants
int CANVAS_WIDTH = 1920/2;
int CANVAS_HEIGHT = 1080/2;
float TEMPO = 123.0; // beats/minute
float BEAT_DURATION = 60.0 / TEMPO; // seconds 
int SKIP_DURATION = round(4.0 * 1000.0 * BEAT_DURATION); // milliseconds
float PREDELAY_DURATION = 5.0; // seconds

// Global state
Timeline timeline;
boolean predelay = true; // are we still in the pre-delay period?

void setup() {
  size(CANVAS_WIDTH, CANVAS_HEIGHT, P3D);

  timeline = new Timeline(this, "assets/Vector Space Odyssey.mp3");
  timeline.addScene(new TestScene(16.0, false));
  timeline.addScene(new TestScene(16.0, true));

  frameRate(60);
  background(0);
  fill(255);
  smooth();
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
      timeline.song.skip((isLeft ? -1 : 1) * SKIP_DURATION);  
    }
  } else if(key == ' ') {
    // Space: play/pause
    if(timeline.song.isPlaying()) {
      timeline.song.pause();
    } else {
      timeline.song.play();
    }
  } /*else if(key == ENTER) {
    // Enter: spit out the current position (for syncing)
    println("" + getBeats() + " b / " + getSeconds() + " s");
  }*/
}

void draw() {
  if(predelay) {
    if(0.001 * millis() < PREDELAY_DURATION) {
      return;      
    }
    
    // Predelay ended, start the song
    predelay = false;
    timeline.song.play();
  }
  
  timeline.drawScene();
}

