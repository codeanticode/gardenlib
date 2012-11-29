// Garden Library project
// Romy Achituv, Andres Colubri
// 
// GardenLibraryViz app, version 9.9 (November 5th, 2012).
// 
// Changes:
// * “compact time” button should appear only on close-up view
// * Restore lines instead of area display
// * Legend is on by default.
// * vertical language code font is Druid Sans Bold, 12, white.
// * Rollover languages displays “click languages for community page”
// * Un-smooth text
// * The animated mode does not stop when reaching the end, but cycle through, option to step faster
// * Clicking back and forth on the timeline in the wheel view changes the opacity/color of the gray lines of the legend.
// * Added info hint.
// * Added top variable for bookshelf, wheel and history.
// * Added accurate fps calculation and printout.
//
// Fixes
// * clicking “show legend” displays a small vertical line before animating the legend
// * in the expanded time view rolling over the emotions does not display the right emotions in the info bo 
// * The history compressed view aligns to the left and doesn’t stretch back after opening the legend before
//   showing the history for the first time.
// * Rolling over spikes does not display book info properly (doesn’t change from spike to spike)
// * Don't load books with invalid titles (NULL or containing ????), and remove languages without books.
// * Updates position of book bubble when opening/closing legend bar.
// * Fixed problem showing latest emotions in bookshelf.
// * Don't show language code text if scale == 0.
// * Skips null entries in timeTextSet. 
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
  } else { 
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
