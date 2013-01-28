// Garden Library project
// Romy Achituv, Andres Colubri
// 
// GardenLibraryViz app, version 10.1 (Janauary 27th, 2013).

void setup() {
  size(1155, 643);
  smooth(8);
  
  frame.setResizable(true);
  
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

