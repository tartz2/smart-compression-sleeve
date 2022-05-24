import grafica.*;
import processing.serial.*;
import controlP5.*;
import java.util.*;

ControlP5 cp5;

Serial myPort;  // Create object from Serial class
String val;     // Data received from the serial port
String[] arr;   // Parsed input

int nPoints = 40;            // amount of plotted points
GPlot muscleGraph1;          // stride graph
GPlot muscleGraph2;          // stride graph
GPointsArray group1Points;   // points for the graph
GPointsArray group2Points;   // points for the graph
int group1Index = 0;         // current place to put new values in array
int group2Index = 0;         // current place to put new values in array

int flexReading = 0;         // val read in from flex sensor
int bicep = 0;               // val read in from EMG 1
int tricep = 0;              // val read in from EMG 2
int bicepReps;
int tricepReps;

boolean flexing = false;  
int currentReps = 0;            
int maxReps;
int sets = 0;
int bicepSets = 0;
int tricepSets = 0;
int maxSets;
boolean isFinished = true;
boolean screen1 = true;
boolean overButton = false;
int frames = 0;
int seconds = 0;
int minutes = 0;
String time = "";

int setBicepRecord = 0;
int repBicepRecord = 0;
int setTricepRecord = 0;
int repTricepRecord = 0;
int maxBicep = 0;
int maxTricep = 0;
int workouts = 0;
int curRep = 0;
int curFlex = 0;

boolean activeWorkout = false;
boolean bicepFlag, tricepFlag = false;
boolean flexFlag = false;
boolean workoutInProgress = false;
boolean workoutDone = false;
boolean doTime = false;

workout[] workoutList;
workout curWorkout = null;

String[] bicepNames = {"Concentration Curl", "Hammer Curls", 
  "Bicep Curls", "Cross Chest Curl"};
  
String[] tricepNames = {"Lying Tricep Extension", "Tricep Dips",
  "One Arm Tricep Push Up", "Triceps Kickback"};

List biceps = Arrays.asList("Level 1: Concentration Curl", "Level 2: Hammer Curls", 
  "Level 3: Bicep Curls", "Level 4: Cross Chest Curl");
List triceps = Arrays.asList("Level 1: Lying Tricep Extension", "Level 2: Tricep Dips",
  "Level 3: One Arm Tricep Push Up", "Level 4: Triceps Kickback");

// use with dropdown
PImage currentImage1;
PImage currentImage2;
int flexVal = 0;

void setup(){
  size(1200, 800);
  
  //get serial input
  //String portName = Serial.list()[1]; //change the 0 to a 1 or 2 etc. to match your port
  //myPort = new Serial(this, portName, 115200);
  //myPort.bufferUntil('\n');
  //val = "";
  
  // example workouts
  selectLevel();
  workoutList = new workout[10];

  muscleGroup1Setup();
  muscleGroup2Setup();
}

void draw(){
  // reset screen
  clear();
  background(0xff);
  // if in main screen
  if(screen1){
    cp5.show();
    text("Welcome to Muscle Management", 412, 41);
    
    if(doTime){
      increaseTime();
      image(currentImage1, 110, 150);
      image(currentImage2, 240, 400);
    }
    //serialPortRead();
    // draw the graphs
    drawGraph1();
    drawGraph2();
    
    // draw the text
    drawFlex();
    drawSets();
    drawReps();
    
    
    /* somewhere in here, if a button is hit from the dropdown that will be added, you should
       have a corresponding workout object attached to that button, then you
       can call startNewWorkout(string name, int level) and set activeWorkout
       to true when they hit a start button afterwards. The list of workouts will 
       automatically add the new workout to the list and initialize it. */
       
    /* in the serialPortRead we already update the flexes and reps,
       so it just calls this update function at the end of draw here
       to keep the most recently added workout in the list updated */
       
       updateWorkout();
       
       
       drawSummaryButton();
       if(!doTime)
         drawStartButton();
       else
         text(workoutList[workouts-1].workoutName, 900, 30);
         
       
       
    // if in summary
  } else {
    cp5.hide();
    drawSummary();
  }
}

void selectLevel(){
    // Initialize the dropdown list
  cp5 = new ControlP5(this);
  
  /* add a ScrollableList, by default it behaves like a DropdownList */
  cp5.addScrollableList("Select Bicep Workout")
    .setPosition(100, 100)
    .setSize(200, 100)
    .setBarHeight(20)
    .setItemHeight(20)
    .addItems(biceps)
    .setOpen(false);
    ;
    
    
  cp5.addScrollableList("Select Tricep Workout")
  .setPosition(400, 100)
  .setSize(200, 100)
  .setBarHeight(20)
  .setItemHeight(20)
  .addItems(triceps)
  .setOpen(false);
  ;
  
    
}

void serialPortRead(){
  
  // clear the graph if full
  if(group1Index == nPoints){
    group1Index = 0;
    group1Points = new GPointsArray(nPoints);
    muscleGroup1Setup();
  } 
  if(group2Index == nPoints){
    group2Index = 0;
    group2Points = new GPointsArray(nPoints);
    muscleGroup2Setup();
  }
  
  if (myPort.available() > 0) 
  {  // If data is available, read it and store it in val
    val = myPort.readStringUntil('\n');    
    if(val != null){
      if(val.indexOf("Flex: ") != -1){
        arr = val.split(" ");
        flexReading = parseInt(arr[1].trim());
      } else if (val.indexOf("Bicep: ") != -1){
        
        arr = val.split(" ");
        bicep = parseInt(arr[1].trim());
        
        // update the max
        if(bicep > maxBicep){
          maxBicep = bicep;
          setBicepRecord = bicepSets;
          repBicepRecord = bicepReps;
        }
        
        // add the value to the graph
        if(doTime){
          group1Points.add(group1Index, bicep);
          group1Index++;
        }
      } else if (val.indexOf("Tricep: ") != -1){
        arr = val.split(" ");
        tricep = parseInt(arr[1].trim());
        
        // update the max
        if(tricep > maxTricep){
          maxTricep = tricep;
          setTricepRecord = tricepSets;
          repTricepRecord = tricepReps;
        }
        
        // add the value to the graph]
        if(doTime){
          group2Points.add(group2Index, tricep);
          group2Index++;
        }
     
      } 
      else if (val.indexOf("Bicep Reps: ") != -1){
        bicepFlag = true;
        if(bicepFlag && tricepFlag){
          curRep++;
          bicepFlag = false;
          tricepFlag = false;
        }
        arr = val.split(" ");
        bicepReps = parseInt(arr[2].trim());
        //println(bicepReps+"\n");
   
      }
      else if (val.indexOf("Tricep Reps: ") != -1){
        tricepFlag = true;
        if(bicepFlag && tricepFlag){
          curRep++;
          bicepFlag = false;
          tricepFlag = false;
        }
        arr = val.split(" ");
        tricepReps = parseInt(arr[2].trim());
        //println(tricepReps+"\n");
        
        // make sure the ino file sends these next two flex flags
      } else if (val.indexOf("Flex: ") != -1){
        arr = val.split(" ");
        flexVal = parseInt(arr[1]);
        if(flexVal > 15){
          flexFlag = true;
        }
      }
    }
  }
}

void drawSets(){
  
  if(bicepReps % 10 == 0 && bicepReps != 0){
    bicepSets = bicepReps/10;
    workoutDone = true;
  }
  
  if(tricepReps % 10 == 0 && tricepReps != 0){
    tricepSets = tricepReps/10;
    workoutDone = true;
  }
  
  fill(0xFFFFFF);
  rect(250, 650, 150, 100); //350, 80, 200, 100
  textSize(16);
  fill(0x000000);
  text("Bicep Sets: "+bicepSets, 265, 680);  //375, 110
  
  textSize(16);
  fill(0x000000);
  text("Tricep Sets: "+tricepSets, 265, 720); //375, 150
  
}

void drawReps(){
  fill(0xFFFFFF);
  rect(60, 650, 150, 100); //110, 80, 200, 100
  textSize(16);
  fill(0x000000);
  text("Bicep Reps: "+bicepReps, 75, 680);
  
  textSize(16);
  fill(0x000000);
  text("Tricep Reps: "+tricepReps, 75, 720);
}

void muscleGroup1Setup(){
  muscleGraph1 = new GPlot(this);
  muscleGraph1.setPos(650, 50); //800, 50
  muscleGraph1.setTitleText("Bicep Activity");
  muscleGraph1.setOuterDim(500, 350); //600, 400
  muscleGraph1.setYLim(0,1000);
  muscleGraph1.setXLim(0, nPoints);   
  muscleGraph1.getXAxis().getAxisLabel().setText("Time");
  muscleGraph1.getYAxis().getAxisLabel().setText("Activity");
  muscleGraph1.getXAxis().setDrawTickLabels(false);
  group1Points = new GPointsArray(nPoints);
}

void muscleGroup2Setup(){
  muscleGraph2 = new GPlot(this);
  muscleGraph2.setPos(650, 400);
  muscleGraph2.setTitleText("Tricep Activity");
  muscleGraph2.setOuterDim(500, 350);
  muscleGraph2.setYLim(0,1000);
  muscleGraph2.setXLim(0, nPoints);   
  muscleGraph2.getXAxis().getAxisLabel().setText("Time");
  muscleGraph2.getYAxis().getAxisLabel().setText("Activity");
  muscleGraph2.getXAxis().setDrawTickLabels(false);
  group2Points = new GPointsArray(nPoints);
}

// function to render graph 1
void drawGraph1(){
  muscleGraph1.setPoints(group1Points);
  muscleGraph1.beginDraw();
  muscleGraph1.drawBackground();
  muscleGraph1.drawBox();
  muscleGraph1.drawXAxis();
  muscleGraph1.drawYAxis();
  muscleGraph1.drawTitle();
  muscleGraph1.drawLines();
  muscleGraph1.endDraw();
}

// function to render graph 2
void drawGraph2(){
  muscleGraph2.setPoints(group2Points);
  muscleGraph2.beginDraw();
  muscleGraph2.drawBackground();
  muscleGraph2.drawBox();
  muscleGraph2.drawXAxis();
  muscleGraph2.drawYAxis();
  muscleGraph2.drawTitle();
  muscleGraph2.drawLines();
  muscleGraph2.endDraw();
}

void drawFlex(){
  // checkFlex()
  
  String flex;
  if(flexing){
    flex = "Flexing";
    if(!flexFlag){
      curFlex++;
      flexFlag = true;
    }
  } else {
    flex = "Not flexing";
    flexFlag = false;
  }
  
  // if they finished the background will be green
  
  // otherise it'll either be gray for not flexing or orange for flexing

  if(flexing)
    fill(196, 134, 33);
  else
    fill(225, 225, 225);
      
  rect(60, 760, 340, 30);
  textSize(15);
  fill(0x00);
  text("Status: " + flex, 190, 780);

}

void repIncr(){
  if(currentReps == maxReps){
    currentReps = 0;
    sets++;
    if(sets == maxSets)
      isFinished = true;
  } else {
    currentReps++;
  }
}

void drawSummary(){
  fill(194, 194, 194);
  rect(10, 10, 1180, 780);
  fill(0x00);
  textSize(30);
  text("Workout Summary", 50, 100);
  textSize(20);
  text("Name of Workout", 50, 200);
  text("Workout Level", 300, 200);
  text("Duration", 500, 200);
  text("# of Flex", 650, 200);
  text("# of Reps", 800, 200);
  int[] xList = {50, 300, 500, 650, 800};
  int yOffset = 200;
  textSize(15);
  for(int i = 0; i < workouts; i++){
    text(workoutList[i].workoutName, xList[0], yOffset + 60);
    text(workoutList[i].workoutLevel, xList[1], yOffset + 60);
    text(workoutList[i].totalTime, xList[2], yOffset + 60);
    text(workoutList[i].flex, xList[3], yOffset + 60);
    text(workoutList[i].rep, xList[4], yOffset + 60);
    
    yOffset += 60;
  }
  
 
  fill(137, 204, 116);
  int rectX = 1050;
  int rectY = 650;
  int rectSizeX = 100;
  int rectSizeY = 100;
  
  rect(rectX, rectY, rectSizeX, rectSizeY);
  overButton = overRect(rectX, rectY, rectSizeX, rectSizeY);
  fill(0x00);
  text("Back", rectX + 25, rectY + 55);
}

void mousePressed() {
  if (overButton) {
    screen1 = !screen1;
    frames = 0;
    seconds = 0;
    minutes = 0;
    doTime = false;
    //println("hello");
  }
  if(activeWorkout && !workoutInProgress && curWorkout != null){
    workoutInProgress = true;
    doTime = true;
    startNewWorkout(curWorkout.workoutName, curWorkout.workoutLevel);
  }
}

boolean overRect(int x, int y, int width, int height)  {
  if (mouseX >= x && mouseX <= x+width && 
      mouseY >= y && mouseY <= y+height) {
    return true;
  } else {
    return false;
  }
}

void increaseTime(){
  frames++;
  if(frames % 60 == 0){
    seconds++;
    if(seconds % 60 == 0){
      seconds = 0;
      minutes++;
    }
    frames = 0;
  }
  
  time = minutes + ":" + seconds + " min";
  workoutList[workouts-1].totalTime = time;
  
  text("Time: " + time, 730, 30);
}

// initialize a new workout and add it to the list
void startNewWorkout(String workoutName, int workoutLevel){
  workout curWorkout = new workout(workoutName, workoutLevel);
  workoutList[workouts] = curWorkout;
  workouts++;
  frames = 0;
  curRep = 0;
  curFlex = 0;
}

// stay on top of the reps and sets
void updateWorkout(){
  if(activeWorkout && workouts != 0){
    workoutList[workouts - 1].totalTime = time;
    workoutList[workouts - 1].flex = curFlex;
    workoutList[workouts - 1].rep = curRep;
  }
  if(curRep >= maxReps){
    activeWorkout = false;
    workoutInProgress = false;
  }
}

void drawSummaryButton(){
  fill(137, 204, 116);
  int rectX = 580;
  int rectY = 650;
  int rectSizeX = 100;
  int rectSizeY = 100;
 
  rect(rectX, rectY, rectSizeX, rectSizeY);
  overButton = overRect(rectX, rectY, rectSizeX, rectSizeY);
  fill(0x00);
  text("Summary", rectX + 18, rectY + 55);
}

public void controlEvent(ControlEvent ce) {
  String tmp = ce.toString();

  if(tmp.indexOf("value") != -1){
    arr = tmp.split(" ");
    String type = arr[5];
    arr = arr[3].split(":");
    String level = arr[1];
    
    int lvl = parseInt(level);
    //println("LEVEL " + lvl);

    if(type.indexOf("Bicep") != -1){
      // lvl can be index of a list with images in order like the String[] bicepNames
      // for the appropriate images
      curWorkout = new workout(bicepNames[lvl], lvl+1);
      if(!doTime){
        if(lvl == 0){
          currentImage1 = loadImage("cc1.png");
          currentImage2 = loadImage("cc2.png");
        } else if(lvl == 1){
          currentImage1 = loadImage("hc1.png");
          currentImage2 = loadImage("hc2.png");
        } else if(lvl == 2){
          currentImage1 = loadImage("bc1.png");
          currentImage2 = loadImage("bc2.png");
        } else if(lvl == 3){
          currentImage1 = loadImage("ccc1.png");
          currentImage2 = loadImage("ccc2.png");
        }
      }
    } else if (type.indexOf("Tricep") != -1){
      // lvl can be index of a list with images in order like the String[] tricepNames
      // for the appropriate images
      curWorkout = new workout(tricepNames[lvl], lvl+1);
      if(!doTime){
        if(lvl == 0){
          currentImage1 = loadImage("lte1.png");
          currentImage2 = loadImage("lte2.png");
        } else if(lvl == 1){
          currentImage1 = loadImage("td1.png");
          currentImage2 = loadImage("td2.png");
        } else if(lvl == 2){
          currentImage1 = loadImage("oatpu1.png");
          currentImage2 = loadImage("oatpu2.png");
        } else if(lvl == 3){
          currentImage1 = loadImage("tk1.png");
          currentImage2 = loadImage("tk2.png");
        }
      }
    }
  }
}

void drawStartButton(){
  fill(137, 204, 116);
  int rectX = 440;
  int rectY = 650;
  int rectSizeX = 100;
  int rectSizeY = 100;
 
  rect(rectX, rectY, rectSizeX, rectSizeY);
  activeWorkout = overRect(rectX, rectY, rectSizeX, rectSizeY);
  
  fill(0x00);
  text("Start", rectX + 30, rectY + 55);
}
