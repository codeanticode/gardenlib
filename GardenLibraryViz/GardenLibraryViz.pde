// Garden Library visualization
// Concept: Romy Achituv
// Design: Romy Achituv, Andres Colubri
// Development: Andres Colubri, Moon Jung Hyun
// 
// Version 13 (February 14th, 2013)

void setup() {
  size(WIDTH, HEIGHT);
  //smooth(8);
  
  frame.setResizable(RESIZE);
  frame.setBackground(new java.awt.Color(0, 0, 0));

  // img = loadImage("media/header.gif");//added  
  initialize(LOADING);
}

void draw() {
  if (currentTask < RUNNING) {
    initialize(currentTask);
    loadingAnimation();
  } else {     
    background(backgroundColor);
    
    checkResize();

    checkMouseActivity();

    // Update UI    
    for (InterfaceElement e: ui) {
      e.update();
    }

    // Draw UI    
    for (InterfaceElement e: ui) {
      e.draw();
    }
    
    hintInfo.update();
    hintInfo.draw();
    
    if (showingHelp) {
      drawHelpLayer();  
    }    
  }
  //   image(img,0,0);// added here on top of legend anim
  //  printFrameRate();
}

void mousePressed() {  
  if (currentTask < RUNNING) return;
  if (showingHelp) {
    showingHelp = false;
    viewFadeinAlpha.set(255);
    return;
  }
  for (InterfaceElement e: ui) {
    e.mousePressed();
  }
}

void mouseDragged() {
  if (currentTask < RUNNING || showingHelp) return;
  for (InterfaceElement e: ui) {
    e.mouseDragged();
  }
}

void mouseReleased() {
  if (currentTask < RUNNING || showingHelp) return;
  for (InterfaceElement e: ui) {
    e.mouseReleased();
  }
}

void mouseMoved() {
  if (currentTask < RUNNING || showingHelp) return;
  for (InterfaceElement e: ui) {
    e.mouseMoved();
  }
}

