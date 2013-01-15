// Garden Library project
// Romy Achituv, Andres Colubri
// 
// GardenLibraryViz app, version 10.0 (Janauary 6th, 2013).
// 
// Changes:
// * Books can be sorted by emotion first, language second in the bookshelf view.
// * Some code reorganization
//
// Fixes
// 
//
// Issues:
// * Some optimization of the book grouping algorithm?
// * Remove ART, children and reference books from display because they don't participate of the emotional judgement system.
// * Make the app use the entire browser canvas:
//   https://forum.processing.org/topic/fullscreen-app-using-processing-js-and-canvas
//   Check this site: www.adamtindale.com   
//   it does just this thing. There is a small function that resizes the canvas when the window size changes. 
//PImage img;//added

void setup() {
  //  size(1154, 692);
  size(1155, 643);
  smooth(8);
  // img = loadImage("media/header.gif");//added
  loadTimeText();
  initialize(LOADING);
}

void draw() {    
  if (currentTask < RUNNING) {
    initialize(currentTask);
    loadingAnimation();
  } 
  else { 
    background(backgroundColor);

    checkMouseActivity();

    // Update UI
    for (InterfaceElement e: ui) {
      e.update();
    }
    hintInfo.update();


    // Draw UI
    for (InterfaceElement e: ui) {
      e.draw();
    }

    hintInfo.draw();
  }
  //   image(img,0,0);// added here on top of legend anim
  //  printFrameRate();
}

void mousePressed() {  
  if (currentTask < RUNNING) return;
  for (InterfaceElement e: ui) {
    e.mousePressed();
  }
}

void mouseDragged() {
  if (currentTask < RUNNING) return;  
  for (InterfaceElement e: ui) {
    e.mouseDragged();
  }
}

void mouseReleased() {
  if (currentTask < RUNNING) return;  
  for (InterfaceElement e: ui) {
    e.mouseReleased();
  }
}

void mouseMoved() {
  if (currentTask < RUNNING) return;  
  for (InterfaceElement e: ui) {
    e.mouseMoved();
  }
}

void keyPressed() {
  if (key == ' ') {
    int days = daysSinceStart.getInt();
    if (groupByLangFirst) {
      groupByLangFirst = false;
      groupBooksByEmotion(days, false);
    } 
    else {
      groupByLangFirst = true;
      groupBooksByEmotion(days, true);
    }     
    setViewRegionAllBookshelf();
  }
}

