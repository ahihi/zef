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
    resetShader();
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

class GreezScene extends Scene {
  PShader sprunge;
  
  public GreezScene(float duration) {
    super(duration);
    sprunge = loadShader("sprunge.glsl");
    sprunge.set("iResolution", (float)width, (float)height);
    
  }
  
  void setup() {
    rectMode(CORNER);
    stroke(0);
  }
  
  void draw(float beats) {
    clear();
    shader(sprunge);
    
    String[] groups = {"", "<3", "", "Peisik", "", "REN", "", "firebug", "", "sooda", "", "Epoch", "", "pants^", "", "Paraguay", "", "Mercury", "", "DOT"};
    int i = floor(beats / duration * groups.length);
    
    if(groups[i].equals(""))
      sprunge.set("iSaturation", 1.0);
    else
      sprunge.set("iSaturation", 0.0);
    sprunge.set("iGlobalTime", beatsToSecs(beats));
    rect(0, 0, width, height);
    resetShader();  
    

          
    
    float timePerText = duration/groups.length;
    float timePassed = 0.0;
    
    fill(255, 0, 100);
    textSize(32);
    textAlign(CENTER, CENTER);

    text(groups[i], width/2.0, height/2.0, 0);

   
  }
}

class BlankScene extends Scene {
  public BlankScene(float duration) {
    super(duration);
  }  
  
  public void setup() {
    background(0);    
  }
}

class CylinderScene extends Scene {
  PShader stardust;
  PShape cylinder;
  PImage texture;
  
  public CylinderScene(float duration) {
    super(duration);
    stardust = loadShader("stardust.glsl");
    stardust.set("iResolution", (float)width, (float)height);
    cylinder = loadShape("AbstractSylinder.obj");
    texture = loadImage("sheetmetal.jpg");
  }
  
  void setup() {
    
    noStroke();      
    textureWrap(REPEAT);
    textureMode(NORMAL);    
  }
  
  void draw(float beats) {
      float secs = beatsToSecs(beats);
      pushMatrix();
      clear();
      rectMode(CORNER);
      shader(stardust);
      stardust.set("iGlobalTime", secs);
      hint(DISABLE_DEPTH_TEST);
      rect(0, 0, width, height);
      hint(ENABLE_DEPTH_TEST);
      resetShader();
      
      beginCamera();
        camera(0, 0, 14, 0, 0, 0, 0, 1, 0);
        float fov = PI/3.0;
        float cameraZ = (height/2.0) / tan(fov/2.0);
        perspective(fov, float(width)/float(height), cameraZ/100.0, cameraZ*10.0);
        
        directionalLight(126, 126, 126, 0, 0, -1);
        ambientLight(102, 102, 102);
          
          pushMatrix();      
      
            rotateZ(PI/2.0);
            rotateX(-5.8);
            rotateY(secs * 0.5);
            
            beginShape();
            texture(texture);
            tint(0, 153, 204);
            shape(cylinder);
            endShape();
          popMatrix();
      endCamera();
      popMatrix();
      
      float fade = max(0.0, min(1.0, 1.0 - beats / 8.0));
      fill(0, 0, 0, fade*255.0);
      rect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
    }
}

class ShadertoyScene extends Scene {
  public PShader shader;
  
  public ShadertoyScene(float duration, String shaderPath) {
    super(duration);
    this.shader = loadShader(shaderPath);
    shader(this.shader);
    resetShader();
  }
  
  public void setup() {
    noSmooth();
    
    fill(255);
  }
  
  public void draw(float beats) {
    background(255);
    shader(this.shader);
    this.shader.set("iResolution", float(CANVAS_WIDTH), float(CANVAS_HEIGHT));
    this.shader.set("iBeats", beats);
    this.shader.set("iGlobalTime", beatsToSecs(beats));
    rect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
  }
}

class CreditsScene extends Scene {
  public PShader shader;
  
  public CreditsScene(float duration) {
    super(duration);
    this.shader = loadShader("noise.glsl");
    this.shader.set("iResolution", float(CANVAS_WIDTH), float(CANVAS_HEIGHT));
  }
  
  public void setup() {
    noStroke();
    frameRate(30);
    fill(255);
    smooth();
  }
  
  void effectMatrix(int time) {
    String texts[] = {"Credits", "", "code", "{", "Kitai", "ahihi", "Lumian", "}", "", "music", "{", "ahihi", "}", "", "@ Graffathon 2015"};
    float speeds[] = {1, 0, 1.5, 1.25, 1, 1.5, 1, 1.25, 0, 1.5, 1.25, 1.5, 1.25, 1, 1};
    
    pushMatrix();
      scale(0.003);
      rotateX(radians(180));
      fill(255, 255, 255, 80 + 50*sin(time*0.001));
      noStroke();
      textSize(40);
  
      for (int i = 0; i < texts.length; i++) {
        for (int j = 0; j < texts[i].length(); j++) {
          float randomNumber = random(10);
          
          if (randomNumber < 7) {
            text(texts[i].charAt(j), i*50 + sin(time*0.001), j*40 -300 + 300*sin(time*0.0001*speeds[i]), 0);
          }
          else {
            text((char) int(random(33, 127)), i*50 + sin(time*0.001), j*40 -300 + 300*sin(time*0.0001*speeds[i]), 0);
          }
        }
      }
      
      popMatrix();
  }
  
  public void draw(float beats) {
    clear();
    
    pushMatrix();
      translate(0,CANVAS_HEIGHT/2.0,-800); // needed in 3D mode
      scale(1.5*(CANVAS_WIDTH/2.0)/ASPECT_RATIO, -CANVAS_HEIGHT/2.0);
      effectMatrix((int)(beats * 1000));
    popMatrix();
    
    this.shader.set("iGlobalTime", beatsToSecs(beats));
    
    fill(0,0,0,0);
    shader(shader);
    rect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
    resetShader();
  }
}

class SnowflakeScene extends Scene {
  PShader shader;
  
  public SnowflakeScene(float duration) {
    super(duration);
    
    shader = loadShader("clouds.glsl");
    shader.set("iResolution", (float)CANVAS_WIDTH, (float)CANVAS_HEIGHT);
  }
  
  void setup() {
    noStroke();
  }
  
  void tree(int time, int level, int branches, float x, float y, float angle, boolean firstRun) {
    if (level < 0){ 
      return; 
    }
    
    //vasen
    float x2 = x + (level * 0.1 * sin(angle) * (1.0 + 0.1*sin(time*0.0005*(level+1))));
    float y2 = y + (level * 0.1 * cos(angle) * (1.0 + 0.1*sin(time*0.0005*(level+1))));
    
    if (!firstRun) {
      stroke(255, 255, 255, 20 + 10*sin(time*0.001));
      strokeWeight(level/5.0 + 0.1);
      line(x,y,x2,y2);
      
      stroke(255, 255, 255, 30 + 30*sin(time*0.001));
      strokeWeight(level/15.0 + 0.1);
      line(x,y,x2,y2);
      
      stroke(255, 255, 255, 100 + 50*sin(time*0.001));
      strokeWeight(level/30.0 + 0.1);
      line(x,y,x2,y2);
    }
    
    if (!firstRun) {
      tree(time, level-1, branches, x2, y2, radians(0)+angle, false);      
      tree(time, level-1, branches, x2, y2, radians(40)+angle, false);      
      tree(time, level-1, branches, x2, y2, radians(-40)+angle, false);
    }
    else {
      for (int i = 0; i < branches; i++) {
        tree(time, level-1, branches, x2, y2, radians(i * 360/branches)+angle, false);
      }
    }
  }

  void effectTree(int time, int level, float angle) {
      if (level == 0){ 
        return; 
      }
      
      pushMatrix();
      
      fill(255, 255, 255, 80 + 50*sin(time*0.001));
      
      float scaleValue = 0.25;
      scale(scaleValue);
      
      stroke(255);
      strokeWeight(1);

      createFallingSnowFlake(time, level, 5, 0, -1, 0, true);
      
      createFallingSnowFlake(time, level - 1, 6, -2, 0, 0, true);
      
      createFallingSnowFlake(time, level,     5, 1, 3, 0, true);
        
      createFallingSnowFlake(time, level - 1, 6, 5, -3, 0, true);
      
      createFallingSnowFlake(time, level - 1, 6, -4, 1, 0, true);
    
      createFallingSnowFlake(time, level - 1, 6, 3.5, -1, 0, true);
      
      createFallingSnowFlake(time, level - 1,     5, 2, 5, 0, true);
      
      createFallingSnowFlake(time, level - 1,     5, -1, -3, 0, true);
      
      createFallingSnowFlake(time, level,     6, -1, -1.5, 0, true);
      
      createFallingSnowFlake(time, level - 2,     6, -2, 4, 0, true);
    
      scale(0.03);
      translate(0, -5, 0);
      rotateX(radians(180));
    
      popMatrix();
  }
  
  void createFallingSnowFlake(int time, int level, int branches, float x, float y, float angle, boolean isFirstCall) {
      pushMatrix();
      float yTranslate = -( 20 - (time*(0.0005 + 0.0005 * abs(y)/2.0) % (40)));
      
      translate(x -1 + 2*sin(time*0.0005 + x), yTranslate);
      rotateZ(radians(time*0.005));
      
      tree(time, level, branches, x, y, angle, true);
      
      popMatrix();
  }
  
  void draw(float beats) {
    pushMatrix();
    translate(CANVAS_WIDTH/2.0, CANVAS_HEIGHT/2, -800); // needed in 3D mode
    scale((CANVAS_WIDTH/2.0)/ASPECT_RATIO, -CANVAS_HEIGHT/2.0);
    clear();

    background(0);
    
    float time = beats * 1000;
    effectTree((int)time, 5, 0);
    
    popMatrix();
    
    float clouds_fade = pow(min(1.0, 1.0 - beats / 32.0), 2.0);
    shader.set("iFade", clouds_fade);
    shader.set("iBeats", beats);
    shader.set("iGlobalTime", beats);
    shader(shader);
    fill(100, 100, 100, 0.5);
    rect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
    resetShader();
    
    float fade = max(0.0, min(1.0, beats < 16.0 ? 1.0 - beats / 16.0 : (beats - 56.0) / 8.0));
    fill(0, 0, 0, 255.0 * fade);
    rect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
  }
}

class StairsScene extends Scene {
  PShader shader;
  
  public StairsScene(float duration) {
    super(duration);

    shader = loadShader("clouds.glsl");
    shader.set("iResolution", (float)CANVAS_WIDTH, (float)CANVAS_HEIGHT);
    shader.set("iFade", 0.0);
  }
  
  void setup() {
    noStroke();
    background(10, 2, 12);
  }
  
  void draw(float beats) {
    clear();
    
    int time = round(beatsToSecs(beats) * 1000.0);
    
    shader.set("iGlobalTime", (float)sin(time*0.001));

    pushMatrix();
    translate(CANVAS_WIDTH/2, CANVAS_HEIGHT/2,-0.3*CANVAS_WIDTH); // needed in 3D mode
    lights();
    rotateY(-time * 0.0005);
    translate(0, time * 0.1, 0);
    fill(36, 36, 67);
    float towerWidth = CANVAS_WIDTH/4;
    int towerHeight = 5*CANVAS_HEIGHT;
    translate(0, -1.5*CANVAS_HEIGHT, 0);
    
    //filter(shader);
    
    shader(shader);
    box(towerWidth, towerHeight, towerWidth);
    resetShader();
    
    
    int amountOfStairs = 5;
    float stairWidth = towerWidth/amountOfStairs;
    float stairHeight = CANVAS_WIDTH/100;
    float stairDepth = towerWidth/10;
    //float stairDepth = stairWidth;
    float heightDifferenceBetweenSteps = (int) (1.7 * stairHeight);
    translate(-0.5*towerWidth, 1.1*CANVAS_HEIGHT, (towerWidth + stairDepth)/2);
    
    for (int k = 0; k < 25; k++) {
      for (int i = 0; i < amountOfStairs; i++) {
        fill(10, 2, 12);
        
        if((beats % 2.0 < 1.0) && ((i % 3.0 * time*0.001) < 1.0)) {
          fill(152, 146, 193);
          fill(36, 36, 67);
          fill(1.5*20, 1.5*4, 1.5*24);
        }
        if ((beats % 4.0 < 1.0) && (((i*k+i) * 0.1*beats) % 2.0 < 1.0)) {
          fill(191, 189, 191);
          //fill(89, 54, 67);
          fill(152, 146, 193);
        }
        
        translate(stairWidth, -heightDifferenceBetweenSteps, 0);
        box(stairWidth, stairHeight, stairDepth);
      }
      
      rotateY(PI/2);
      
      translate((stairDepth)/2, 0, (stairDepth)/2);
    }

    popMatrix();
    
    resetShader();
  }
}

class StairsScene2 extends Scene {
  PShader shader;
  PShader shader2;
  
  public StairsScene2(float duration) {
    super(duration);

    shader = loadShader("lines2.glsl");
    shader.set("iResolution", (float)CANVAS_WIDTH, (float)CANVAS_HEIGHT);
    
    shader2 = loadShader("lines3.glsl");
    shader2.set("iResolution", (float)CANVAS_WIDTH, (float)CANVAS_HEIGHT);
  }
  
  void setup() {
    noStroke();
  }
  
  void draw(float beats) {
    clear();
    
    int time = round(beatsToSecs(beats) * 1000.0);
    
    shader.set("iGlobalTime", (float)sin(time*0.001));
    shader2.set("iGlobalTime", (float)sin((time+60)*0.001));

    pushMatrix();
    translate(CANVAS_WIDTH/2, CANVAS_HEIGHT/2,-0.3*CANVAS_WIDTH); // needed in 3D mode
    lights();
    rotateY(1.5*PI/2 + -time * 0.0005);
    translate(0, time * 0.1, 0);
    fill(36, 36, 67);
    float towerWidth = CANVAS_WIDTH/3;
    int towerHeight = 4*CANVAS_HEIGHT;
    translate(0, -2.0*CANVAS_HEIGHT, 0);
    
    //filter(shader);
    
    //shader(shader);
    //box(towerWidth, towerHeight, towerWidth);
    //resetShader();
    
    
    int amountOfStairs = 5;
    float stairWidth = towerWidth/amountOfStairs;
    float stairHeight = CANVAS_WIDTH/100;
    float stairDepth = stairWidth;
    //float stairDepth = stairWidth;
    float heightDifferenceBetweenSteps = (int) (3.0 * stairHeight);
    translate(-0.5*towerWidth, 1.1*CANVAS_HEIGHT, (towerWidth + stairDepth)/2);
    
    for (int k = 0; k < 30; k++) {
      for (int i = 0; i < amountOfStairs; i++) {
        fill(36, 36, 67);
        
        if(beats % 2.0 < 1.0 && (i+k+time*0.001) % 3.0 < 1.0) {
          fill(152, 146, 193);
        }
        
        translate(stairWidth, -heightDifferenceBetweenSteps, 0);
        box(stairWidth, stairHeight, stairDepth);
      }
      
      rotateY(PI/2);
      
      //translate((stairDepth)/2, 0, (stairDepth)/2);
    }

    popMatrix();
    
    shader(shader);
    fill(100, 100, 100, 0.5);
    rect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
    
    shader(shader2);
    fill(100, 100, 100, 0.5);
    rect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
    
    resetShader();
  }
}

class RotatingObjectScene extends Scene {
  PShader shader;
  PShader shader2;
  PShape metalObject;
  
  public RotatingObjectScene(float duration) {
    super(duration);
    
    metalObject = loadShape("metalObject.obj");

    shader = loadShader("lines.glsl");
    shader2 = loadShader("shaderLumian.glsl");
    shader.set("iResolution", (float)CANVAS_WIDTH, (float)CANVAS_HEIGHT);
    shader2.set("iResolution", (float)CANVAS_WIDTH, (float)CANVAS_HEIGHT);
  }
  
  void setup() {
    noStroke();
  }
  
  void draw(float beats) {
    clear();
    
    int time = round(beatsToSecs(beats) * 1000.0);

    pushMatrix();

    translate(CANVAS_WIDTH/2, CANVAS_HEIGHT/2,-0.5*CANVAS_WIDTH); // needed in 3D mode
    lights();
    
    if (beats%2 < 1.0) {
      scale(24.0);
    }
    else {
      scale(20.0);
    }
    
    this.shader.set("iGlobalTime", beatsToSecs(beats));
    this.shader2.set("iGlobalTime", beatsToSecs(beats));
    
    rotateX(sin(time*0.001));
    rotateY(cos(time*0.0001));
    rotateZ(sin(time*0.0001)*cos(time*0.001));
    translate(30*sin(time*0.001), 30*cos(time*0.001), 0.7*sin(time*0.01));
    shader(shader2);
    shape(metalObject, 0, 0);
    resetShader();

    popMatrix();
    
    shader(shader);
    fill(100, 100, 100, 0.5);
    rect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
    
    resetShader();
  }
}

// Constants
int CANVAS_WIDTH = 1920/4;
int CANVAS_HEIGHT = 1080/4;
float ASPECT_RATIO = (float)CANVAS_WIDTH/CANVAS_HEIGHT;
float TEMPO = 123.0; // beats/minute
float BEAT_DURATION = 60.0 / TEMPO; // seconds 
int SKIP_DURATION = round(4.0 * 1000.0 * BEAT_DURATION); // milliseconds
float PREDELAY_DURATION = 0.0; // seconds

// Global state
Timeline timeline;
boolean predelay = true; // are we still in the pre-delay period?

void setup() {
  size(CANVAS_WIDTH, CANVAS_HEIGHT, P3D);

  timeline = new Timeline(this, "data/Vector Space Odyssey.mp3");
  timeline.addScene(new GreezScene(30.0));
  timeline.addScene(new SnowflakeScene(64.0));
  timeline.addScene(new CylinderScene(32.0));
  timeline.addScene(new StairsScene2(32.0));
  timeline.addScene(new ShadertoyScene(64.0, "data/robotik.frag"));
  timeline.addScene(new ShadertoyScene(64.0, "data/tunnel.frag")); // start at 128
  
  timeline.addScene(new CreditsScene(60.0));
  timeline.addScene(new RotatingObjectScene(60.0));
  timeline.addScene(new StairsScene2(64.0));

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
    float offset = 0.0;
    timeline.song.play(round(offset * 1000.0 * BEAT_DURATION));
  }
  
  timeline.drawScene();
}


