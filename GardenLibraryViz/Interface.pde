// The interface classes.

class Rectangle {
  float x, y, w, h;

  Rectangle(float x, float y, float w, float h) {
    set(x, y, w, h);
  }

  void set(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;    
  }

  boolean contains(float mx, float my) {
    return x <= mx && mx <= x + w && y <= my && my <= y + h;
  }
}

class InterfaceElement {
  Rectangle bounds;
  boolean selected;

  InterfaceElement(float x, float y, float w, float h) {
    bounds = new Rectangle(x, y, w, h);
    selected = false;
  }

  void update() {
  }
  
  void draw() {
  }

  boolean mousePressed() {
    selected = contains(mouseX, mouseY);
    return selected;
  }
  boolean mouseDragged() {
    return selected;
  }
  void mouseReleased() {
    selected = false;
  }
  void mouseMoved() {
  }

  boolean contains(float mx, float my) {
    return bounds.contains(mx, my);
  }
  
  void resize(float x, float y, float w, float h) {
    bounds.set(x, y, w, h);  
  }
}  

class ViewArea extends InterfaceElement {
  float x0, w0;
  float pressX0, pressY0;
  boolean animatingTrails;
  boolean draggingWheel;
  boolean histLocked;
  BookBubble bookBubble;
  Message dateInfo;
  LanguageTab langTab;
  EmotionTab emoTab;  

  float langBarY; // Position of the language bar (with respect to the top of the bound rectangle)

  ViewArea(float x, float y, float w, float h) {
    super(x, y, w, h);
    x0 = x;
    w0 = w;
    bookBubble = new BookBubble();
    dateInfo = new Message(selHistoryColor);
    langTab = new LanguageTab();
    emoTab = new EmotionTab();
    langBarY = y + bookshelfTop + bookBubbleTailH + fontSize + (numBookBubbleLines + 1) * (fontSize + 5) + 5 + 10;
  }

  void update() {
    boolean timeChanged = daysSinceStart.update();
    if (currentMode == MODE_BOOKSHELF) {
      for (Book book: books) {
        book.update(currentMode);
      }
      viewRegion.update();
      if (timeChanged) {
        groupBooksByEmotion(daysSinceStart.getInt(), true);
      }  
      bookStrokeWeight.update();

      langBarH.update(); 
      bookTopHeight.update();
      bookHeightTimer.update();

      langTab.update();
      emoTab.update();
    } else if (currentMode == MODE_WHEEL) {
      if (playingAnim) {
        float days0 = daysSinceStart.get();

        if (!daysSinceStart.targeting && !animatingTrails && days0 < daysRunningTot) {      
          float daysMax = daysRunningTot - days0;
          float days1 = days0 + min(animationIncDays, daysMax);
          daysSinceStart.setTarget(days1);   
          groupBooksByEmotion((int)days1, false);
        }    
        if (daysRunningTot <= daysSinceStart.get()) {
          daysSinceStart.set(0);
          groupBooksByEmotion(0, true);          
          //playingAnim = false;
        }
      }

      for (Book book: books) {
        book.update(currentMode);
      }

      bookStrokeWeight.update();
      bookTopHeight.update();

      wheelRAngle.update();
      wheelYPos.update();
      wheelScale.update();
      
      wheelWidth.update();
    } else if (currentMode == MODE_INFO) {
      
    }

    if (currentMode != MODE_INFO) {
      dateInfo.update();
      bookBubble.update();
    }

    viewFadeinAlpha.update();
    viewLeftMargin.update();

    float xoff = viewLeftMargin.get();
    bounds.x = x0 + xoff;
    bounds.w = w0 - bounds.x;
  }

  void draw() {
    if (currentMode == MODE_BOOKSHELF) {
      if (!showingHelp) {
        if (sortByLang) {      
          selLang = getSelectedLangInBookshelf(mouseX, mouseY, bounds, langBarY);
          selEmo = null;
          selBook = getSelectedBookInBookshelfGroupByLang(mouseX, mouseY, bounds, langBarY);        
        } else {
          selLang = getSelectedLangInBookshelfGroupByEmo(mouseX, mouseY, bounds, langBarY);
          selEmo = getSelectedEmoInBookshelf(mouseX, mouseY, bounds, langBarY);                
          selBook = getSelectedBookInBookshelfGroupByEmo(mouseX, mouseY, bounds, langBarY);
        }
      }

      emoTab.open(selEmo);
      emoTab.draw();
      langTab.open(selLang);
      langTab.draw();
      bookBubble.open(selBook);
      bookBubble.draw();

      if (!mouseActivity) {
        if (selBook == null && selLang == null && viewRegion.zoomLevel != VIEW_ALL) {
          hintInfo.open("click anywhere above the language bar to zoom out");
        }
        if (selBook != null) {
          hintInfo.open("right click to search the book by ISBN on google books");
        }
      }

      drawBookshelf(bounds, langBarY);
    } else if (currentMode == MODE_WHEEL) {
      if (!showingHelp) {
        if (viewRegion.zoomLevel == VIEW_BOOK) {
          selBook = getSelectedBookInWheel(bounds, selBook, wheelTop);
        }
      }
      
      bookBubble.open(selBook);
      bookBubble.draw();      

      if (!mouseActivity && viewRegion.zoomLevel != VIEW_ALL) {
        hintInfo.open("click anywhere outside the language circle to zoom out");
      }

      animatingTrails = drawWheel(bounds, wheelTop);
    } else if (currentMode == MODE_HISTORY) {      
      drawHistory(bounds, historyTop, w0);

      if (!showingHelp && !histLocked && (abs(pmouseX - mouseX) > 0 || abs(pmouseY - mouseY) > 0)) {        
        if (contains(mouseX, mouseY)) {
          selBook = selectBookInHistory(mouseX, mouseY, bounds, historyTop);
        }
        bookBubble.open(selBook);
      }

      if (selBook != null) {        
        drawBookHistory(selBook, bounds, historyTop);
        if (histLocked) {
          SelectedText selDate = selectDateInBookHistory(mouseX, mouseY, selBook, bounds, historyTop);
          if (selDate == null) {
            dateInfo.close();
          } else {            
            dateInfo.open(selDate.text, selDate.x, selDate.y); 
          }
        }
      }

      historyCircleX = map(daysSinceStart.get(), 0, daysRunningTot, bounds.x, bounds.x + bounds.w);
      historyCircleY = bounds.y + bounds.h + 5;
      strokeWeight(1);
      stroke(historyLineColor);
      line(historyCircleX, 0, historyCircleX, historyCircleY + 5);
      fill(255);
      ellipse(historyCircleX, historyCircleY, 10, 10);
    } else if (currentMode == MODE_INFO) {
      
    }
    
    if (currentMode != MODE_INFO) {
      bookBubble.draw();
      dateInfo.draw();
    }
  }

  boolean mousePressed() {
    if (!contains(mouseX, mouseY) || currentMode == MODE_INFO) {
      selected = false;
      return selected;
    }

    selected = true;
    if (currentMode == MODE_BOOKSHELF && !helpMenu.contains(mouseX, mouseY)) {
      
      if (mouseButton == RIGHT && selBook != null && showISBN) {
        String isbn = selBook.book.ISBN;
//      String isbn = "9780140285000";
        String url = "https://www.google.com/search?tbo=p&tbm=bks&q=isbn:" + isbn + "&num=10";
        link(url, "_new");
        return selected;  
      }

      setViewRegionBookshelf(mouseX, mouseY, bounds, langBarY);
    } else if (currentMode == MODE_WHEEL) {      
      pressX0 = mouseX;
      pressY0 = mouseY;
      draggingWheel = false;
    } else if (currentMode == MODE_HISTORY) {
      histLocked = !histLocked;  
    }
    
    return selected;
  }

  boolean mouseDragged() {
    if (!selected) return false;

    if (currentMode == MODE_BOOKSHELF) {
      if (langBarY - langBarH.get() <= mouseY && mouseY <= langBarY) { 
        dragViewRegion(pmouseX, mouseX);
      }
    } else if (currentMode == MODE_WHEEL) {
      if (viewRegion.zoomLevel == VIEW_EMO || viewRegion.zoomLevel == VIEW_BOOK) {
        dragWheel(pressX0, pressY0, mouseX, mouseY, bounds);
        draggingWheel = true;
      }
    }

    return true;
  }

  void mouseReleased() {
    if (!selected) return;

    if (currentMode == MODE_BOOKSHELF) {
    } else if (currentMode == MODE_WHEEL) {
      if (!draggingWheel && !helpMenu.contains(mouseX, mouseY)) {
        // An emotion can be selected only by a single
        // click that doesn't involve dragging.
        setViewRegionWheel(mouseX, mouseY, bounds, wheelTop);
        selBook = null;
      } 
      draggingWheel = false;
      selected = false;
    }
  }
  
  void resize(float x, float y, float w, float h) {
    super.resize(x, y, w, h);
    w0 = w;    
  }
}

class ViewMenu extends InterfaceElement {
  PImage bookshelfSel, bookshelfUnsel;
  PImage wheelSel, wheelUnsel;
  PImage historySel, historyUnsel;
  PImage langSel, langUnsel;
  PImage emoSel, emoUnsel;
  Message hint;
  
  float w5, h2;
  float bw, ww, hw, lw, ew;
  float hbw, hww, hhw, hlw, hew;

  ViewMenu(float x, float y, float w, float h) {
    super(x, y, w, h);  
    w5 = w/5;
    h2 = h/2;
    
    bookshelfSel = loadImage("media/bookshelf_green.gif");
    bookshelfUnsel = loadImage("media/bookshelf_grey.gif");
    wheelSel = loadImage("media/wheel_green.gif");
    wheelUnsel = loadImage("media/wheel_grey.gif");
    historySel = loadImage("media/history_green.gif");
    historyUnsel = loadImage("media/history_grey.gif");
    langSel = loadImage("media/languages_green.gif");
    langUnsel = loadImage("media/languages_grey.gif");    
    emoSel = loadImage("media/emotions_green.gif");
    emoUnsel = loadImage("media/emotions_grey.gif");

    hbw = textWidth("bookshelf view");
    hww = textWidth("wheel view");
    hhw = textWidth("history view");
    hlw = textWidth("sort by language");
    hew = textWidth("sort by emotion");

    bw = bookshelfSel.width;
    ww = wheelSel.width;
    hw = historySel.width;
    lw = langSel.width;
    ew = emoSel.width;
    
    hint = new Message(defTextColor);
  }

  void update() {
    hint.update();  
  }

  void draw() {
    if (currentMode == MODE_INFO) return;
    
    noStroke();
    fill(replaceAlpha(backgroundColor, 180));
    rect(bounds.x, bounds.y, bounds.w, bounds.h);

    stroke(menuStrokeColor);
    strokeWeight(1);

    float xl = bounds.x;

    tint(255);

    float xc = xl + w5/2 - bw/2;
    float yc = bounds.y + h2 - bw/2;
    if (currentMode == MODE_BOOKSHELF) {
      image(bookshelfSel, xc, yc);
    } else { 
      image(bookshelfUnsel, xc, yc);
    }     

    xl += w5;
    xc = xl + w5/2 - ww/2;
    if (currentMode == MODE_WHEEL) {
      image(wheelSel, xc, yc);
    } else { 
      image(wheelUnsel, xc, yc);
    }      

    xl += w5;
    xc = xl + w5/2 - hw/2;
    if (currentMode == MODE_HISTORY) {
      image(historySel, xc, yc);
    } else { 
      image(historyUnsel, xc, yc);
    }

    if (currentMode == MODE_BOOKSHELF) {
      xl += w5;
      xc = xl + w5/2 - lw/2;
      if (sortByLang) {
        image(langSel, xc, yc);
      } else {
        image(langUnsel, xc, yc);
      }

      xl += w5;
      xc = xl + w5/2 - ew/2;
      if (!sortByLang) {
        image(emoSel, xc, yc);
      } else {
        image(emoUnsel, xc, yc);
      }      
    }
   
    hint.draw(); 
  }

  boolean mousePressed() {
    hint.close();
    
    selected = false;
    if (currentMode == MODE_INFO) return selected;    
    if (!contains(mouseX, mouseY)) return selected;
    
    selected = true;

    if (contains(mouseX, mouseY)) {
      int p = int((mouseX - bounds.x) / w5);
      if (p == 0) {
        setCurrentMode(MODE_BOOKSHELF);
      } else if (p == 1) {
        setCurrentMode(MODE_WHEEL);
      } else if (p == 2) {
        setCurrentMode(MODE_HISTORY);
      } else if (currentMode == MODE_BOOKSHELF) {
        if (p == 3) {
          setGrouping(true);
        } else if (p == 4) {
          setGrouping(false);
        }
      }
    }
    return selected;
  }
  
  void mouseMoved() {
    if (currentMode == MODE_INFO) return;
    
    if (!contains(mouseX, mouseY)) {
      hint.close();
      return;
    }
    
    float hx;
    float hy = bounds.y + h2 - bw; 
    
    float xl = bounds.x;

    float xc = xl + w5/2 - bw/2;
    float yc = bounds.y + h2 - bw/2;
    if (insideIcon(xc, yc)) {
      hx = xc + bw/2 - hbw/2; 
      if (hx < bounds.x) {
        hx += bounds.x - hx; 
      }      
      hint.open("bookshelf view", hx, hy);
      return;
    }

    xl += w5;
    xc = xl + w5/2 - ww/2;
    if (insideIcon(xc, yc)) {
      hx = xc + bw/2 - hww/2; 
      hint.open("wheel view", hx, hy);
      return;
    }

    xl += w5;
    xc = xl + w5/2 - hw/2;
    if (insideIcon(xc, yc)) {
      hx = xc + bw/2 - hhw/2; 
      hint.open("history view", hx, hy);
      return;
    }
    
    if (currentMode == MODE_BOOKSHELF) {
      xl += w5;
      xc = xl + w5/2 - lw/2;
      if (insideIcon(xc, yc)) {
        hx = xc + bw/2 - hlw/2; 
        hint.open("sort by language", hx, hy);
        return;
      }

      xl += w5;
      xc = xl + w5/2 - ew/2;
      if (insideIcon(xc, yc)) {
        hx = xc + bw/2 - hew/2; 
        if (bounds.x + bounds.w < hx + hew) {
          hx -= (hx + hew) - (bounds.x + bounds.w); 
        }         
        hint.open("sort by emotion", hx, hy);
        return;
      }      
    }    
    
    hint.close();
  } 
  
  boolean insideIcon(float xc, float yc) {
    return xc < mouseX && mouseX < xc + bw &&
           yc < mouseY && mouseY < yc + bw;      
  }
  
  void resize(float x, float y, float w, float h) {
    super.resize(x, y, w, h);
    w5 = w/5;
    h2 = h/2;  
  } 
}

class HelpMenu extends InterfaceElement {
  int zoomStatus;
  int infoStatus;
  PImage[] zoomIcon;
  PImage[] infoIcon;
  
  HelpMenu(float x, float y, float w, float h) {
    super(x, y, w, h);
    zoomIcon = new PImage[2];
    zoomIcon[0] = loadImage("media/mag_grey.gif");
    zoomIcon[1] = loadImage("media/mag_green.gif");
    
    infoIcon = new PImage[2];
    infoIcon[0] = loadImage("media/q_mark_grey.gif");
    infoIcon[1] = loadImage("media/q_mark_green.gif");
    
    zoomStatus = 0;
    infoStatus = 0;
  }  
  
  void draw() {
    if (currentMode == MODE_INFO) return;
    
    if (currentMode != MODE_HISTORY) {
      image(zoomIcon[zoomStatus], bounds.x, bounds.y);
    }
    image(infoIcon[infoStatus], bounds.x + zoomIcon[zoomStatus].width + 5, bounds.y);
  }
  
  boolean mousePressed() {
    if (currentMode == MODE_INFO) {
      selected = false;
      return selected;
    }
    
    if (contains(mouseX, mouseY)) {     
      if (currentMode != MODE_HISTORY && insideIcon(zoomIcon[zoomStatus], bounds.x, bounds.y)) {
        cycleZoom();        
      }

      if (insideIcon(infoIcon[infoStatus], bounds.x + zoomIcon[zoomStatus].width + 5, bounds.y)) {
        showingHelp = true;
        helpMaskAlpha.set(0);
        helpMaskAlpha.setTarget(targetHelpMaskAlpha);
      }     
      selected = true;
    } else {
      selected = false;  
    }
    
    return selected;
  }  
  
  void mouseMoved() {
    if (currentMode == MODE_INFO) return;
    
    if (contains(mouseX, mouseY)) {
      if (insideIcon(zoomIcon[zoomStatus], bounds.x, bounds.y)) {
        zoomStatus = 1;
      } else {
        zoomStatus = 0;
      }
      if (insideIcon(infoIcon[infoStatus], bounds.x + zoomIcon[zoomStatus].width + 5, bounds.y)) {
        infoStatus = 1;
      } else {
        infoStatus = 0;
      }
    } else {
      zoomStatus = 0;
      infoStatus = 0;
    }   
  }
  
  boolean insideIcon(PImage icon, float x, float y) {
    return x < mouseX && mouseX < x + icon.width & y < mouseY && mouseY < y + icon.height;
  }
  
  void cycleZoom() {
    if (currentMode == MODE_BOOKSHELF) {
      float xc = viewArea.bounds.x + viewArea.bounds.w/2;
      if (viewRegion.zoomLevel == VIEW_ALL) {
        setViewRegionLangBookshelf(xc, viewArea.bounds);
      } else if (viewRegion.zoomLevel == VIEW_LANG) {
        setViewRegionBookBookshelf(xc, viewArea.bounds);
        if (compactTime) {
          disableCompactTime();
        }        
      } else if (viewRegion.zoomLevel == VIEW_BOOK) {
        if (!compactTime) {
          enableCompactTime();
        } else {
          // Return to fully zoomed-out view
          setViewRegionAllBookshelf();
        }  
      }
    } else if (currentMode == MODE_WHEEL) {
      if (viewRegion.zoomLevel == VIEW_ALL) {
        float d = wheelRadius + wheelWidth.get() + maxBookHeight/2;
        float angle = 0;   
        selectBookInWheel(d, angle);
      } else if (viewRegion.zoomLevel == VIEW_BOOK) {
        setViewRegionAllWheel();  
        selBook = null;
      }
    }    
  }
}

class Timeline extends InterfaceElement {
  float h2;
  float lmargin;
  float rmargin;
  boolean compact;
  boolean animating;
  boolean insideDragArea;

  Timeline(float x, float y, float w, float h) {
    super(x, y, w, h);  
    h2 = h/2;
    lmargin = 5;
    rmargin = 100;
    compact = false;
    animating = false;
  }

  void update() {
    if (!playingAnim && animating) {
      // To update the UI when the animation is concluded.
      animating = false;
    }
  }

  void draw() {
    if (currentMode == MODE_INFO) return;
    
    noStroke();
    fill(replaceAlpha(backgroundColor, 180));
    rect(bounds.x, bounds.y, bounds.w, bounds.h);

    fill(defTextColor);

    float x0 = getLeft();
    float x1 = getRight();
    float xm = x1 + 10;
    if (currentMode == MODE_WHEEL) {
      if (animating) {
        text("stop animation", xm, bounds.y + h2 + fontSize/2);
      } else {
        text("play animation", xm, bounds.y + h2 + fontSize/2);
      }
    } else if (currentMode == MODE_BOOKSHELF && viewRegion.zoomLevel == VIEW_BOOK) {
      // } else if (currentMode == MODE_BOOKSHELF) {
      if (compactTime) {
        text("expand time", xm, bounds.y + h2 + fontSize/2);
      } else {
        text("compact time", xm, bounds.y + h2 + fontSize/2);
      }
    }   

    if (currentMode == MODE_HISTORY) { // added expand timeline for history mode
      x1 = x0 + bounds.w - 20;
    }

    stroke(timelineColor);
    strokeWeight(1);
    //line(x0, bounds.y + h2, x1, bounds.y + h2);
    float elapsed = daysRunningTot;
    Date currDate = dateAfter(startDate, int(elapsed));
    Date date = new Date();
    date.copy(startDate);
    while (date.isBefore (endDate)) {
      int days = daysBetween(startDate, date);
      float xt = map(days, 0, daysRunningTot, x0, x1);
      line(xt, bounds.y + h2 - 5, xt, bounds.y + h2 + 5);
      date.addMonth();
    }
    line(x1, bounds.y + h2 - 5, x1, bounds.y + h2 + 5); // last tickmark. 

    float xc = map(daysSinceStart.get(), 0, daysRunningTot, x0, x1);
    fill(255);  
    noStroke();      
    triangle(xc - 4, bounds.y + h2 - 10, xc + 4, bounds.y + h2 - 10, xc, bounds.y + h2 - 6);
    Date selDate = dateAfter(startDate, int(daysSinceStart.get()));
        
    drawNewsBox(xc, x0, x1, bounds.y + h2 - 15, selDate);
    
    textFont(dateFont);
    String dstr = selDate.toNiceString();    
    float dw = textWidth(dstr);
    fill(defTextColor);
    if (x1 < xc + dw/2) {
      xc -= xc + dw/2 - (x1);
    }
    if (x0 > xc - dw/2) {
      xc += x0 - (xc - dw/2);
    }
    text(dstr, xc - dw/2, bounds.y + h2 - 15);
    textFont(defFont);
    
    if (!mouseActivity && contains(mouseX, mouseY)) { 
      String url = urlInCurrNewsText();      
      if (!url.equals("") && newsAlpha > 0 && !daysSinceStart.targeting) {
        hintInfo.open("right click to open the news link");
      }
    }    
  }

  boolean mousePressed() {
    if (currentMode == MODE_INFO) {
      selected = false;
      return selected;
    }

    if (currentMode == MODE_HISTORY && dist(mouseX, mouseY, historyCircleX, historyCircleY) < 10) {
      // Hack to drag the white circle in the history view and control the timeline, part 1 
      // (see setTimeHistoryHack() function below for the rest) 
      selected = true;
      return selected;
    }
    
    if (!contains(mouseX, mouseY)) {
      selected = false;
      return selected;
    }
    selected = true;
    
    if (mouseButton == RIGHT && currNewsText != null && newsAlpha > 0) {   
      String url = urlInCurrNewsText();
      if (!url.equals("")) {
        link(url, "_new");  
      }
    }
    
    float x0 = getLeft();
    float x1 = getRight();
    if (mouseX > x1) {
      if (currentMode == MODE_WHEEL) {
        animating = !animating;

        if (animating) {
          //daysSinceStart.set(0);
          //groupBooksByEmotion(0, true);
          playingAnim = true;
        } else {
          playingAnim = false;
        }
      } else if (viewRegion.zoomLevel == VIEW_BOOK) {
        compact = !compact;

        if (compactTime) {
          disableCompactTime();
        } else {
          enableCompactTime();
        }
      }
    } else {
      insideDragArea = true;
      setTime(mouseX);
    }

    return true;
  }

  boolean mouseDragged() {    
    if (!selected || mouseButton == RIGHT) return false;
    float x0 = getLeft();
    float x1 = getRight();    
    if (x0 < mouseX && mouseX < x1 && 
        bounds.y < mouseY && mouseY < bounds.y + bounds.h) {
      setTime(mouseX);
    } else if (currentMode == MODE_HISTORY) {
      setTimeHistoryHack(mouseX);      
    }
    return true;
  }

  void setTime(float mx) {
    float x0 = getLeft();
    float x1 = getRight();
    int days = int(constrain(map(mx, x0, x1, 0, daysRunningTot), 0, daysRunningTot));
    daysSinceStart.setTarget(days);
    if (currentMode == MODE_BOOKSHELF) {
      if (sortByLang) {
        groupBooksByEmotion(days, true);
      } else {        
        groupBooksByEmotion(days, false);
        viewRegion.update(numBooksWithEmo());        
        if (viewRegion.zoomLevel == VIEW_EMO && currEmo != null) {
          // Stay centered around currently selected emotion.
          viewEmotion(currEmo);
        } 
      }
    } else if (currentMode == MODE_WHEEL) {
      groupBooksByEmotion(days, false);
    }
  }
  
  void setTimeHistoryHack(float mx) {
    // Hack to drag the white circle in the history view and control the timeline, part 2
    int days = int(map(mx, viewArea.bounds.x, viewArea.bounds.x + viewArea.bounds.w, 0, daysRunningTot));
    if (0 <= days && days <= daysRunningTot) {      
      daysSinceStart.setTarget(days);
    }  
  }
  
  void resize(float x, float y, float w, float h) {
    super.resize(x, y, w, h);
    h2 = h/2;
  }   
  
  float getLeft() {
    return bounds.x + lmargin;        
  }
  
  float getRight() {
    float x0 = getLeft();    
    if (currentMode == MODE_HISTORY) {
      return x0 + bounds.w - 20;
    } else {
      return x0 + bounds.w - rmargin; 
    }    
  }
}

class LegendArea extends InterfaceElement {
  float bx, by, bw, bh;
  float sw, hw;
  boolean closed;
  SoftFloat animTimer;

  LegendArea(float bx, float by, float bw, float bh, 
             float x, float y, float w, float h) {
    super(x, y, w, h);         
    this.bx = bx;
    this.by = by;
    this.bw = bw;
    this.bh = bh;
    animTimer = new SoftFloat();

    closed = true;
    sw = textWidth("show legend");
    hw = textWidth("hide help");
  }

  void update() {
    if (animTimer.targeting) {
      if (0.7 * bounds.w < viewLeftMargin.get()) {       
        animTimer.update();
      }
    }
  }

  void draw() {
    float xc = bx + fontSize + 5;
    float yc = by + bh/2 + fontSize/2;
          
      strokeWeight(1);
      stroke(legendLineColor);
      fill(255);
      if (currentMode != MODE_INFO) {
        rect(bx +1, by + bh/2 - fontSize/2, fontSize -1, fontSize -2);
        line(bx + fontSize/2, bounds.y, bx + fontSize/2, by + bh/2 - fontSize/2);
      }
    
      fill(defTextColor);
      if (closed) {
        text("show legend", xc, yc);
      } else {
        if (currentMode != MODE_INFO) {        
          text("hide legend", xc, yc);
        }
  
        float xlang = 0.4 * bounds.w;
        float xemo = 0.6 * bounds.w;
        float h = bounds.h * animTimer.get();   
  
        line(xlang, bounds.y, xlang, bounds.y + h - 85);
        line(xemo, bounds.y, xemo, bounds.y + h + animTimer.get() * 20 - 42); 
  
        float y = h - 55; // height of legend
        for (int i = languages.size() - 1; i >= 0; i--) {
          int ri = languages.size() - 1 - i;
          int ei = emotions.size() - ri - 1;
  
          if (bounds.y + 20 < y) {         
            Language lang = languages.get(i);  
          if (lang.id == 0) continue;

          float x0 = xlang - 10;
          float y0 = y - 60;
          float x1 = x0 + 20; 
          float y1 = y0 + 0.7 * fontSize;

          fill(lang.argb);          
          rect(x0, y0, x1 - x0, y1 - y0);   // lang rects
          
          fill(defTextColor);
          float tw = textWidth(lang.name);
          text(lang.name, xlang - 15 - tw, y0 + 0.7 * fontSize/2 + fontSize/2 -1); // location of lang text

          if (x0 < mouseX && mouseX <= x1 && y0 <= mouseY && mouseY <= y1 && !mouseActivity && currentMode != MODE_INFO) {
            hintInfo.open("click language to see information about the labor migration in Israel"); // rollover message
          }

          if (0 <= ei) {
            Emotion emo = emotions.get(ei);
            fill(emo.argb);
            x0 = xemo - 0.9 * fontSize/2;
            y0 = y;
            x1 = x0 + 0.95 * fontSize;
            y1 = y0 + 0.8 * fontSize;         
            rect(x0, y0, x1 - x0, y1 - y0);
            fill(defTextColor);
            text(emo.name, xemo + 0.7 * fontSize+3, y + 0.7 * fontSize/2 + fontSize/2 -1); // locaton of emo text
            
            if (x0 < mouseX && mouseX <= x1 && y0 <= mouseY && mouseY <= y1 && !mouseActivity && currentMode != MODE_INFO) {
              hintInfo.open("click emotion to see information about the cataloguing system"); // rollover message
            }            
          }
          
          y -= 0.7 * fontSize + 22;// distance between sqs
        } else {
          break;
        }
      }
       
      if (currentMode == MODE_INFO) {
        // Fading out either language or emotion legends
        noStroke();
        fill(replaceAlpha(0, viewFadeinAlpha.getInt()));
        if (showingMigrantInfo) {
          rect(xemo - 20, bounds.y, bounds.w - xemo + 20, h + animTimer.get() * 20 - 42);
        } else {
          rect(bounds.x, bounds.y, xlang + 20 - bounds.x, h - 85);
        }
      }      
    }
  }

  boolean mousePressed() {
    if (currentMode == MODE_INFO) {
      selected = false;
      return selected;
    }
    
    if (contains(mouseX, mouseY)) {
      selected = true;
      if (closed) {
        open();
      } else {
        close();
      }   
      return true;
    } else if (!closed) {     
      float xlang = 0.4 * bounds.w;
      float xemo = 0.6 * bounds.w;
      float h = bounds.h * animTimer.get();       
      float y = h - 55;
      for (int i = languages.size() - 1; i >= 0; i--) {
        int ri = languages.size() - 1 - i;
        int ei = emotions.size() - ri - 1;

        if (bounds.y + 20 < y) {  
          Language lang = languages.get(i);  
          if (lang.id == 0) continue;
          
          float x0 = xlang - 10;
          float y0 = y - 60;
          float x1 = x0 + 20; 
          float y1 = y0 + 0.7 * fontSize;        
          if (x0 < mouseX && mouseX <= x1 && y0 <= mouseY && mouseY <= y1) {
            setCurrentMode(MODE_INFO);
            showingMigrantInfo = true;
            infoArea.restart();
            return true;
          }          
          
          if (0 <= ei) {
            Emotion emo = emotions.get(ei);
            x0 = xemo - 0.9 * fontSize/2;
            y0 = y;
            x1 = x0 + 0.95 * fontSize;
            y1 = y0 + 0.8 * fontSize;
            if (x0 < mouseX && mouseX <= x1 && y0 <= mouseY && mouseY <= y1) {
              setCurrentMode(MODE_INFO);
              showingMigrantInfo = false;
              infoArea.restart();
              return true;
            }            
          }
        }
        
        y -= 0.7 * fontSize + 22;
      }

      return false;
    } else {
      return false;
    }
  }

  boolean contains(float mx, float my) {
    return bx <= mx && mx < bx + bw && by <= my && my < by + bh;
  }

  void open() {
    closed = false;
    viewLeftMargin.setTarget(bounds.w);
    animTimer.set(0);
    animTimer.setTarget(1);    
  }

  void close() {
    closed = true;
    viewLeftMargin.setTarget(0);
  }
}

class InfoArea extends InterfaceElement {
  HashMap<String, PImage> images;
  boolean showScrollUp, showScrollDown;
  float startY;
  float margin;
  float infoLineSpaceReg, infoLineSpaceTitle, infoLineSpaceCapt;
  
  InfoArea(float x, float y, float w, float h) {
    super(x, y, w, h);
    images = new HashMap<String, PImage>();
    showScrollUp = false;
    showScrollDown = false;
    startY = bounds.y;  
    
    margin = max(70, bounds.w * 0.1);
    infoLineSpaceReg = infoFontRegSize + 2;
    infoLineSpaceTitle = infoFontTitleSize + 2;
    infoLineSpaceCapt = infoFontCaptSize + 2;    
  }  
  
  void restart() {
    startY = bounds.y;  
  }
  
  void draw() {
    if (currentMode == MODE_INFO) {      
      clip(bounds.x, bounds.y, bounds.w, bounds.h);
      
      XML data = showingMigrantInfo ? migrantInfo : catalogInfo;
       
      float y = startY;      
      for (XML child: data.getChildren()) {
        String content = child.getContent().trim();
        if (!content.equals("")) {
          String type = child.getName();
          if (type.equals("title")) {
            fill(replaceAlpha(infoFontTitleColor, 2 * viewFadeinAlpha.getInt()));
            textFont(infoFontTitle);            
            textLeading(infoLineSpaceTitle);
            float len = textWidth(content);
            float w = bounds.w - 2 * margin;
            float h = ceil(len / w) * infoLineSpaceTitle + 3;            
            text(content, bounds.x + margin, y, bounds.w - 2 * margin, h);
            y += h + infoLineSpaceTitle;
          } else if (type.equals("paragraph")) {
            fill(replaceAlpha(infoFontRegColor, 2 * viewFadeinAlpha.getInt()));
            textFont(infoFontReg);
            textLeading(infoLineSpaceReg);
            float len = textWidth(content);
            float w = bounds.w - 2 * margin;
            float h = ceil(len / w + 1) * infoLineSpaceReg + 3;            
            text(content, bounds.x + margin, y, bounds.w - 2 * margin, h + 5);
            y += h;
          } else if (type.equals("image")) {
            String fn = child.getChild("filename").getContent().trim();
            String caption = child.getChild("caption").getContent().trim();
            PImage img = images.get(fn);
            if (img == null) {
              img = loadImage(fn);
              images.put(fn, img);
            }            
          } else if (type.equals("link")) {
            fill(replaceAlpha(color(0, 0, 255), 2 * viewFadeinAlpha.getInt()));
            textFont(infoFontReg);
            textLeading(infoLineSpaceReg);
            float len = textWidth(content);
            float w = bounds.w - 2 * margin;
            float h = ceil(len / w + 1) * infoLineSpaceReg + 3;            
            text(content, bounds.x + margin, y, bounds.w - 2 * margin, h + 5);
            y += h;

            
            
//            fill(replaceAlpha(infoFontTitleColor, 2 * viewFadeinAlpha.getInt()));
//            textFont(infoFontTitle);            
//            float len = textWidth(content);
//            float w = bounds.w - 2 * margin;
//            float h = ceil(len / w) * infoLineSpaceTitle + 3;            
//            text(content, bounds.x + margin, y, bounds.w - 2 * margin, h);
//            y += h + infoLineSpaceTitle;

            
          }            
        } 
      }
                 
      showScrollDown = bounds.y + bounds.h < y;
      showScrollUp = startY < bounds.y;      
       
      noStroke();
      
      float x1, y1, x2, y2, x3, y3;

      x1 = bounds.x + bounds.w - 25;
      y1 = bounds.y + bounds.h - 10;
      x2 = bounds.x + bounds.w - 35;
      y2 = bounds.y + bounds.h - 20;
      x3 = bounds.x + bounds.w - 15;
      y3 = bounds.y + bounds.h - 20;
      if (showScrollDown) {        
        fill(replaceAlpha(color(255), 2 * viewFadeinAlpha.getInt()));
      } else {
        fill(replaceAlpha(color(50), 2 * viewFadeinAlpha.getInt()));
      }      
      triangle(x1, y1, x2, y2, x3, y3);

      x2 = bounds.x + bounds.w - 35;
      y2 = bounds.y + bounds.h - 25;
      x3 = bounds.x + bounds.w - 15;
      y3 = bounds.y + bounds.h - 25;
      x1 = bounds.x + bounds.w - 25;
      y1 = bounds.y + bounds.h - 35;
      if (showScrollUp) {        
        fill(replaceAlpha(color(255), 2 * viewFadeinAlpha.getInt()));
      } else {
        fill(replaceAlpha(color(50), 2 * viewFadeinAlpha.getInt()));
      }      
      triangle(x1, y1, x2, y2, x3, y3);        
                   
      textFont(defFont);             
      noClip();       
    }
  }
  
  boolean mousePressed() {
    selected = false;
    
    if (currentMode != MODE_INFO) {
      return selected;  
    }
    
    if (contains(mouseX, mouseY)) {
      selected = true;
      
      if (insideDownButton()) {
        if (showScrollDown) {
          startY -= infoLineSpaceReg;          
        }
        return selected;
      } else if (insideUpButton()) {
        if (showScrollUp) {
          startY += infoLineSpaceReg;            
        }
        return selected;
      }
      
      setCurrentMode(previousMode);
    }
    
    return selected;
  }
  
  boolean insideDownButton() {
    float x0 = bounds.x + bounds.w - 35;
    float x1 = bounds.x + bounds.w - 15;    
    float y0 = bounds.y + bounds.h - 20;
    float y1 = bounds.y + bounds.h - 10;
    return x0 < mouseX && mouseX < x1 && y0 < mouseY && mouseY < y1;  
  }
  
  boolean insideUpButton() {
    float x0 = bounds.x + bounds.w - 35;
    float x1 = bounds.x + bounds.w - 15;    
    float y0 = bounds.y + bounds.h - 35;
    float y1 = bounds.y + bounds.h - 25;
    return x0 < mouseX && mouseX < x1 && y0 < mouseY && mouseY < y1;  
  }  
}

// -------------------------------------------------------------------------------------------------
//
// Assorted interface-related functions, maybe the can be put inside the appropiate interface class?

void setViewRegionAll() {
  if (currentMode == MODE_BOOKSHELF) {
    setViewRegionAllBookshelf();
  } else if (currentMode == MODE_WHEEL) {
    setViewRegionAllWheel();
  }
}

void setViewRegionBookshelf(float x, float y, Rectangle bounds, float yTop) {
  float h = langBarH.get();
  float bh = bookTopHeight.get();

  if (y < yTop - h - bh) {
    setViewRegionAllBookshelf();
    return;
  }

  if (yTop - h < y && y < yTop) {
    if (viewRegion.zoomLevel != VIEW_ALL) return; // can select language only from fully zoomed-out view.
    setViewRegionLangBookshelf(x, bounds);
  } else {
    setViewRegionBookBookshelf(x, bounds);
  }
}

void setViewRegionAllBookshelf() {
  int count = sortByLang ? books.size() : numBooksWithEmo();
  viewRegion.setTarget(0, count);

  viewRegion.zoomLevel = VIEW_ALL;  
  bookStrokeWeight.set(0);
  bookTopHeight.setTarget(sortByLang ? 0 : maxBookHeight); 
  langBarH.setTarget(langBarWAll);
  disableCompactTime(); 
  currLang = null;
  currEmo = null;
}

void setViewRegionLangBookshelf(float x, Rectangle bounds) {
  if (sortByLang) {
    setLanguage(x, bounds);
  } else {
    setEmotion(x, bounds);
  }  
}

void setViewRegionBookBookshelf(float x, Rectangle bounds) {
  viewRegion.zoomLevel = VIEW_BOOK; 
  bookStrokeWeight.setTarget(bookOutlineW);
  bookTopHeight.setTarget(maxBookHeight);
  currLang = null;
  currEmo = null;

  // Set view region around selected book
  if (sortByLang) {
    setViewRegionBookshelfGroupByLang(x, bounds);
  } else {
    setViewRegionBookshelfGroupByEmo(x, bounds);
  }  
}

void setViewRegionBookshelfGroupByLang(float x, Rectangle bounds) {
  int count = 0;
  int langCount = 0;
  for (Language lang: languages) {  
    if (lang.id == 0) continue;

    for (Emotion emo: emotions) {
      ArrayList<Book> bemo = lang.booksPerEmo.get(emo.id);
      if (bemo == null) continue; 

      int i0 = count; 
      int i1 = i0 + bemo.size() - 1;

      float startBook = viewRegion.getFirstBook();  
      float viewBooks = viewRegion.getBookCount();         

      if (viewRegion.intersects(i0, i1)) {        
        for (int i = 0; i < bemo.size(); i++) {
          int iabs = i0 + i;
          float x0 = bookX(iabs, bounds.x, bounds.w);          
          if (abs(x - x0) < 5) {
            viewRegion.setTarget(iabs - sizeBookView/2, iabs + sizeBookView/2, books.size());
            return;
          }
        }
      }
      count += bemo.size();
    }
  }
}

void setViewRegionBookshelfGroupByEmo(float x, Rectangle bounds) {
  int totCount = numBooksWithEmo();
  int count = 0;
  int emoCount = 0;  
  for (Emotion emo: emotions) {  
    if (emo.id == 0) continue;

    for (Language lang: languages) {
      ArrayList<Book> blang = emo.booksPerLang.get(lang.id);
      if (blang == null) continue;

      int i0 = count; 
      int i1 = i0 + blang.size() - 1;

      float startBook = viewRegion.getFirstBook();  
      float viewBooks = viewRegion.getBookCount();         

      if (viewRegion.intersects(i0, i1)) {        
        for (int i = 0; i < blang.size(); i++) {
          int iabs = i0 + i;
          float x0 = bookX(iabs, bounds.x, bounds.w);          
          if (abs(x - x0) < 5) {
            viewRegion.setTarget(iabs - sizeBookView/2, iabs + sizeBookView/2, totCount);
            return;
          }
        }
      }
      count += blang.size();
    }
  }
}

void disableCompactTime() {
  bookHeightTimer.setTarget(0);
  compactTime = false;  
}

void enableCompactTime() {
  bookHeightTimer.setTarget(1);
  compactTime = true;
}

void setViewRegionWheel(float x, float y, Rectangle bounds, float yTop) {
  float xc = bounds.x + bounds.w/2;
  float yc = bounds.y + yTop + bounds.h/2;

  float h = wheelWidth.get();
  float r0 = wheelRadius;
  float r1 = wheelRadius + h;

  float sx0 = x - xc;
  float sy0 = y - yc - wheelYPos.get();
  sx0 /= wheelScale.get();
  sy0 /= wheelScale.get();

  float sx = cos(-wheelRAngle.get()) * sx0 - sin(-wheelRAngle.get()) * sy0;
  float sy = sin(-wheelRAngle.get()) * sx0 + cos(-wheelRAngle.get()) * sy0;

  float d = sqrt(sx * sx + sy * sy);
  float angle = atan2(sy, sx);
  if (angle < 0) {
    angle += TWO_PI;
  }  

// Disabled emo-level zoom in wheel.
//  if (r0 < d && d < r1) {
//    int emoCount = 0;
//    for (Emotion emo: emotions) {
//      if (emo.id == 0) continue;
//
//      // Draw emotion arc
//      float a0 = bookAngle(emoCount);
//      emoCount += emo.booksInEmo.size();
//      float a1 = bookAngle(emoCount);
//
//      if (a0 <= angle && angle <= a1) {
//        wheelYPos.setTarget(wheelDispEmo);
//        wheelScale.setTarget(wheelScaleEmo);
//        float centAngle = PI + HALF_PI - 0.5 * (a0 + a1);
//        if (PI < centAngle) centAngle = centAngle - TWO_PI;
//        wheelRAngle.setTarget(centAngle);
//        viewRegion.zoomLevel = VIEW_EMO;
//        wheelWidth.set(wheelWidthView);
//        return;
//      }
//    }
//  } 
//  else
  
  if (r0 < d && d < r1 + maxBookHeight) {
    selectBookInWheel(d, angle);
  } else {
    setViewRegionAllWheel();
  }
}

void setViewRegionAllWheel() {
  viewRegion.zoomLevel = VIEW_ALL;
  wheelYPos.setTarget(0);
  wheelScale.setTarget(1);
  wheelWidth.set(wheelWidthWAll);
}

void selectBookInWheel(float d, float angle) {
  float r1 = wheelRadius + wheelWidth.get();
  int count = 0;    
  for (Emotion emo: emotions) {
    if (emo.id == 0) continue;

    for (Language lang: languages) {
      ArrayList<Book> blang = emo.booksPerLang.get(lang.id);
      if (blang == null) continue; 

      int i0 = count; 
      int i1 = i0 + blang.size() - 1;
      float a0 = bookAngle(i0);    
      float a1 = bookAngle(i1);
      float angPerBook = min(1, (a1 - a0) / blang.size());

      for (int i = 0; i < blang.size(); i++) {
        int iabs = i0 + i;
        Book book = blang.get(i);
        if (!book.traveling && d <= r1 + book.wheelHeight.get()) {
          float a = book.wheelAngle.get();            
          if (a - angPerBook/2 <= angle && angle <= a1 + angPerBook/2) {
            viewRegion.zoomLevel = VIEW_BOOK;
            wheelYPos.setTarget(wheelDispBook);
            wheelScale.setTarget(wheelScaleBook);          

            float centAngle = PI + HALF_PI - a;
            if (PI < centAngle) centAngle = centAngle - TWO_PI;
            wheelRAngle.setTarget(centAngle);
            wheelWidth.set(wheelWidthBook);
            return;
          }
        }
      }

      count += blang.size();
    }
  }
}

boolean aboveBookshelf(float x, float y, Rectangle bounds, float yTop) {
  float h = langBarH.get();
  float bh = bookTopHeight.get();  
  return (bounds.x < x && x < bounds.x + bounds.w) && 
    (bounds.y < y && y < yTop - h - bh);
}

boolean insideBookshelf(float x, float y, Rectangle bounds, float yTop) {
  float h = langBarH.get();
  float bh = bookTopHeight.get();  
  return (bounds.x < x && x < bounds.x + bounds.w) && 
    ((yTop < y && y < height) || (yTop - h - bh < y && y < yTop - h));
}

boolean insideLangBar(float x, float y, Rectangle bounds, float yTop) {
  float h = langBarH.get();
  return (bounds.x < x && x < bounds.x + bounds.w) && (yTop - h < y && y < yTop);
}

SelectedBook getSelectedBookInBookshelfGroupByLang(float x, float y, Rectangle bounds, float yTop) {
  if (!insideBookshelf(x, y, bounds, yTop)) {
    return null;  
  }    
    
  float firstBook = viewRegion.getFirstBook();  
  float bookCount = viewRegion.getBookCount(); 

  float elapsed = daysSinceStart.get();  

  float h = langBarH.get();
  float totLen = map(elapsed, 0, daysRunningTot, 0, bounds.y + bounds.h - yTop);

  float w = (float)(bounds.w) / bookCount;   

  int count = 0;
  int langCount = 0;
  for (Language lang: languages) {  
    if (lang.id == 0) continue;

    for (Emotion emo: emotions) {
      ArrayList<Book> bemo = lang.booksPerEmo.get(emo.id);
      if (bemo == null) continue; 

      int i0 = count; 
      int i1 = i0 + bemo.size() - 1;

      if (viewRegion.intersects(i0, i1)) {        
        for (int i = 0; i < bemo.size(); i++) {
          int iabs = i0 + i;
          if (firstBook <= iabs && iabs < firstBook + bookCount) {
            Book book = bemo.get(i);
            float bh = bookTopHeight.get();
            int e = book.insideBookshelf(x, y, firstBook, w, bounds.x, yTop, h, bh, totLen);            
            if (-1 < e) {
              return new SelectedBook(book, emotionsByID.get(e), book.getBookCenterX(firstBook, w, bounds.x), 
                                      yTop - h -bh - 5);
            }
          }
        }
      }      
      count += bemo.size();
    }
  } 

  return null;
}

SelectedBook getSelectedBookInBookshelfGroupByEmo(float x, float y, Rectangle bounds, float yTop) {
  if (!insideBookshelf(x, y, bounds, yTop)) {
    return null;  
  }
  
  float firstBook = viewRegion.getFirstBook();  
  float bookCount = viewRegion.getBookCount(); 

  float elapsed = daysSinceStart.get();  

  float h = langBarH.get();
  float totLen = map(elapsed, 0, daysRunningTot, 0, bounds.y + bounds.h - yTop);

  float w = (float)(bounds.w) / bookCount;   

  int count = 0;
  int emoCount = 0;
  for (Emotion emo: emotions) {  
    if (emo.id == 0) continue;

    for (Language lang: languages) {
      ArrayList<Book> blang = emo.booksPerLang.get(lang.id);
      if (blang == null) continue; 

      int i0 = count; 
      int i1 = i0 + blang.size() - 1;

      if (viewRegion.intersects(i0, i1)) {        
        for (int i = 0; i < blang.size(); i++) {
          int iabs = i0 + i;
          if (firstBook <= iabs && iabs < firstBook + bookCount) {
            Book book = blang.get(i);
            int e = book.insideBookshelf(x, y, firstBook, w, bounds.x, yTop, h, 0, totLen);
            if (-1 < e) {
              return new SelectedBook(book, emotionsByID.get(e), book.getBookCenterX(firstBook, w, bounds.x), 
                                      yTop - h - bookTopHeight.get() - 5);
            }
          }
        }
      }      
      count += blang.size();
    }
  } 

  return null;
}

SelectedBook getSelectedBookInWheel(Rectangle bounds, SelectedBook defSelBook, float yTop) {
  SelectedBook res = defSelBook;

  // To update the selected book, we look for the book
  // that is right at the top of the wheel: 
  float xc = bounds.x + bounds.w/2;
  float yc = bounds.y + yTop + bounds.h/2;
  float h = wheelWidth.get();  
  float r0 = wheelRadius;
  float r1 = wheelRadius + h;

  float x = xc;
  float y = 0;

  float sx0 = x - xc;
  float sy0 = y - yc - wheelYPos.get();
  sx0 /= wheelScale.get();
  sy0 /= wheelScale.get();

  float sx = cos(-wheelRAngle.get()) * sx0 - sin(-wheelRAngle.get()) * sy0;
  float sy = sin(-wheelRAngle.get()) * sx0 + cos(-wheelRAngle.get()) * sy0;

  float d = sqrt(sx * sx + sy * sy);
  float angle = atan2(sy, sx);
  if (angle < 0) {
    angle += TWO_PI;
  }  

  int count = 0;    
  for (Emotion emo: emotions) {
    if (emo.id == 0) continue;

    for (Language lang: languages) {
      ArrayList<Book> blang = emo.booksPerLang.get(lang.id);
      if (blang == null) continue; 

      int i0 = count; 
      int i1 = i0 + blang.size() - 1;
      float a0 = bookAngle(i0);    
      float a1 = bookAngle(i1);
      float angPerBook = min(1, (a1 - a0) / blang.size());

      for (int i = 0; i < blang.size(); i++) {
        int iabs = i0 + i;
        Book book = blang.get(i);
        if (!book.traveling) {
          float a = book.wheelAngle.get();            
          if (a - angPerBook/2 <= angle && angle <= a + angPerBook/2) {
            float wh = book.wheelHeight.get();
            float x0 = bounds.x + bounds.w/2;
            float y0 = bounds.y + yTop + bounds.h/2 + wheelYPos.get() - wheelScale.get() * (wheelRadius + h + wh) - 5; 
            res = new SelectedBook(book, emo, x0, y0);
            return res;
          }
        }
      }

      count += blang.size();
    }
  }

  if (res != null) {
    // Update position of currently selected book to take into account margin animation.
    res.x = bounds.x + bounds.w/2;
  }
  return res;
}

SelectedBook selectBookInHistory(float mx, float my, Rectangle bounds, float yTop) {
  float xc = bounds.x;
  float yc = bounds.y + yTop;
  int historyW = int(bounds.w);
  int historyH = int(bounds.h - yTop - 20);  

  for (Book book: books) {
    PVector pt0 = null;
    for (PVector pt: book.history) {

      if (pt0 != null) {
        float bx0 = xc + historyW * pt0.x; 
        float by0 = yc + historyH * squeezeY(pt0.x, pt0.y);
        float bx1 = xc + historyW * pt.x; 
        float by1 = yc + historyH * squeezeY(pt.x, pt.y);

        if (segmentCircleIntersect(bx0, by0, bx1, by1, mx, my, 2)) {          
          int days = int(map(mx, xc, yc + historyW, 0, daysRunningTot));
          Emotion emo = emotionsByID.get(book.getEmotion(days));
          return new SelectedBook(book, emo, mx, my);
        }
      }
      pt0 = pt;
    }
  }
  return null;
}

SelectedText selectDateInBookHistory(float mx, float my, SelectedBook sel, Rectangle bounds, float yTop) {
  Book book = sel.book;

  int historyW = int(bounds.w);
  int historyH = int(bounds.h - yTop - 20);  
  float xc = bounds.x;
  float yc = bounds.y + yTop;
  PVector pt0 = null;
  for (PVector pt: book.history) {
    if (pt0 != null) {
      int days0 = int(map(pt0.x, 0, 1, 0, daysRunningTot));
      int days1 = int(map(pt.x, 0, 1, 0, daysRunningTot));
      float x1 = xc + historyW * pt.x;
      float y1 = yc + historyH * squeezeY(pt.x, pt.y); 
      if (book.checkedIn(days0, days1) && dist(mx, my, x1, y1) < 7) {
        Date retDate = dateAfter(startDate, days1);
        return new SelectedText("Returned on " + retDate.toNiceString(), x1 + 10, y1 + 10);
      }
    } else {
      int days1 = int(map(pt.x, 0, 1, 0, daysRunningTot));
      float x1 = xc + historyW * pt.x;
      float y1 = yc + historyH * squeezeY(pt.x, pt.y);
      if (dist(mx, my, x1, y1) < 7) {
        Date retDate = dateAfter(startDate, days1);
        return new SelectedText("Returned on " + retDate.toNiceString(), x1 + 10, y1 + 10);
      }
    }

    pt0 = pt;
  }

  return null;
}

void setLanguage(float x, Rectangle bounds) {  
  viewRegion.zoomLevel = VIEW_LANG;
  bookStrokeWeight.set(0);
  bookTopHeight.setTarget(0);
  langBarH.setTarget(langBarWLang);
  disableCompactTime();  
  int langCount = 0;
  for (Language lang: languages) {  
    if (lang.id == 0) continue;
    int langCount0 = langCount;
    float x0 = bookX(langCount, bounds.x, bounds.w);       
    langCount += lang.numTotBooks();
    float x1 = bookX(langCount, bounds.x, bounds.w); 

    if (x0 <= x && x <= x1) {
      if (langCount - langCount0 < sizeBookView) {
        // The number of books in this language is too small, 
        // centering around the middle book and using
        int imid = (langCount0 + langCount)/2; 
        viewRegion.setTarget(imid - sizeBookView/2, imid + sizeBookView/2, books.size());
      } else {
        viewRegion.setTarget(langCount0, langCount, books.size());
      }  

      currLang = lang;
      currEmo = null;
      return;
    }
  }
}

void setEmotion(float x, Rectangle bounds) {
  int totCount = numBooksWithEmo();
  viewRegion.zoomLevel = VIEW_LANG;
  bookStrokeWeight.set(0);
  bookTopHeight.setTarget(maxBookHeight);  
  langBarH.setTarget(langBarWLang);
  disableCompactTime();    
  int emoCount = 0;
  for (Emotion emo: emotions) {  
    if (emo.id == 0) continue;
    int emoCount0 = emoCount;
    float x0 = bookX(emoCount, bounds.x, bounds.w);       
    emoCount += emo.booksInEmo.size();      
    float x1 = bookX(emoCount, bounds.x, bounds.w); 

    if (x0 <= x && x <= x1) {
      if (emoCount - emoCount0 < sizeBookView) {
        // The number of books in this language is too small, 
        // centering around the middle book and using
        int imid = (emoCount0 + emoCount)/2; 
        viewRegion.setTarget(imid - sizeBookView/2, imid + sizeBookView/2, totCount);
      } else {
        viewRegion.setTarget(emoCount0, emoCount, totCount);
      }  

      currLang = null;
      currEmo = emo;
      return;
    }
  }
}

// Sets the view region to cover exactly the specificed language.
void viewLanguage(Language selLang) {  
  int langCount = 0;
  for (Language lang: languages) {  
    if (lang.id == 0) continue;
    int langCount0 = langCount;
    langCount += lang.numTotBooks(); 

    if (lang == selLang) {      
      if (langCount - langCount0 < sizeBookView) {
        // The number of books in this language is too small, 
        // centering around the middle book and using
        int imid = (langCount0 + langCount)/2; 
        viewRegion.setTarget(imid - sizeBookView/2, imid + sizeBookView/2, books.size());
      } else {
        viewRegion.setTarget(langCount0, langCount, books.size());
      }  
      return;
    }
  }
}

// Sets the view region to cover exactly the specificed emotion.
void viewEmotion(Emotion selEmo) {
  int totCount = numBooksWithEmo();
  int emoCount = 0;
  for (Emotion emo: emotions) {  
    if (emo.id == 0) continue;
    int emoCount0 = emoCount;
    emoCount += emo.booksInEmo.size(); 

    if (emo == selEmo) {      
      if (emoCount - emoCount0 < sizeBookView) {
        // The number of books in this language is too small, 
        // centering around the middle book and using
        int imid = (emoCount0 + emoCount)/2; 
        viewRegion.setTarget(imid - sizeBookView/2, imid + sizeBookView/2, totCount);
      } else {
        viewRegion.setTarget(emoCount0, emoCount, totCount);
      }
      currLang = null;
      currEmo = emo;
      return;
    }
  }
}

SelectedLanguage getSelectedLangInBookshelf(float x, float y, Rectangle bounds, float yTop) {
  if (!insideLangBar(x, y, bounds, yTop)) {
    return null;  
  }
  
  float w = bounds.w / viewRegion.getBookCount();
  float langPadding = bookPadding * w/2;
  int langCount = 0;
  for (Language lang: languages) {  
    if (lang.id == 0) continue;
    int langCount0 = langCount;
    float x0 = bookX(langCount, bounds.x, bounds.w);       
    langCount += lang.numTotBooks();      
    float x1 = bookX(langCount, bounds.x, bounds.w);     
    if (x0 <= x && x <= x1) {            
      return new SelectedLanguage(lang, max(bounds.x, x0 + langPadding), yTop - langBarH.get());
    }
  }
  return null;
}

SelectedEmotion getSelectedEmoInBookshelf(float x, float y, Rectangle bounds, float yTop) {
 if (!insideLangBar(x, y, bounds, yTop)) {
    return null;  
  } 
  
  float w = bounds.w / viewRegion.getBookCount();
  float emoPadding = bookPadding * w/2;
  int emoCount = 0;
  for (Emotion emo: emotions) {  
    if (emo.id == 0) continue;
    int emoCount0 = emoCount;
    float x0 = bookX(emoCount, bounds.x, bounds.w);       
    emoCount += emo.booksInEmo.size();      
    float x1 = bookX(emoCount, bounds.x, bounds.w);     
    if (x0 <= x && x <= x1) {            
      return new SelectedEmotion(emo, max(bounds.x, x0 + emoPadding), yTop - langBarH.get());
    }
  }
  return null;
}

SelectedLanguage getSelectedLangInBookshelfGroupByEmo(float x, float y, Rectangle bounds, float yTop) {
  float h = langBarH.get();
  float bh = bookTopHeight.get();
  float y0 = yTop - h - bh;
  float y1 = y0 + 0.7 * bh; 
  if (0 < bh && y0 < y && y < y1) {    
    float firstBook = viewRegion.getFirstBook();  
    float bookCount = viewRegion.getBookCount();     
    int emoCount = 0;
    int count = 0;
    float w = bounds.w / bookCount;
    for (Emotion emo: emotions) {
      if (emo.id == 0) continue;

      for (Language lang: languages) {
        float x0 = -1, x1 = -1; 
      
        ArrayList<Book> blang = emo.booksPerLang.get(lang.id);
        if (blang == null) continue;

        int i0 = count; 
        int i1 = i0 + blang.size() - 1;

        if (viewRegion.intersects(i0, i1)) {        
          for (int i = 0; i < blang.size(); i++) {
            int iabs = i0 + i;
            if (firstBook <= iabs && iabs < firstBook + bookCount) {
              Book book = blang.get(i); 
              if (x0 == -1) {
                x0 = book.bookBookshelfX0(firstBook, w, bounds.x);
              }
              x1 = book.bookBookshelfX1(firstBook, w, bounds.x);
            }
          }
        }
     
        if (-1 < x0 && x0 < x && x < x1) {
          return new SelectedLanguage(lang, emo, max(bounds.x, x0), y1);
        }

        count += blang.size();
      }
    }
  }

  return null;
}

void dragViewRegion(float px, float x) {
  if (viewRegion.zoomLevel == VIEW_ALL) return;

  if (viewRegion.zoomLevel == VIEW_LANG) {
    if (sortByLang) {
      dragViewRegionGroupByLang(px, x);
    } else {
      dragViewRegionGroupByEmo(px, x);
    }
  } else {
    currLang = null;
    currEmo = null;

    float first = viewRegion.firstBook.get();
    float last = viewRegion.lastBook.get();
    float f = 20 * (float)(last - first);
    float diff = f * (px - x) / width;
    int count = sortByLang ? books.size() : numBooksWithEmo();
    viewRegion.setTarget(first + diff, last + diff, count);
  }
}

void dragViewRegionGroupByLang(float px, float x) {
  if (currLang == null) return;
  if (viewRegion.isTargeting()) return; // to avoid moving to another language before reaching the one selected first.      

  Language prevLang = currLang;
  Language nextLang = currLang;            
  for (int i = 0; i < languages.size(); i++) {
    Language lang = languages.get(i);
    if (currLang == lang) {
      if (0 < i) {
        prevLang = languages.get(i - 1);
      }   
      if (i < languages.size() - 1) {
        nextLang = languages.get(i + 1);
      }
      break;
    }
  }

  float diff = px - x;      
  if (0 < diff) {
    viewLanguage(nextLang);
    currLang = nextLang;
  } 

  if (diff < 0) {
    viewLanguage(prevLang);
    currLang = prevLang;
  }
}

void dragViewRegionGroupByEmo(float px, float x) {
  if (currEmo == null) return;
  if (viewRegion.isTargeting()) return; // to avoid moving to another language before reaching the one selected first.      

  Emotion prevEmo = currEmo;
  Emotion nextEmo = currEmo;
  for (int i = 0; i < emotions.size(); i++) {
    Emotion emo = emotions.get(i);
    if (currEmo == emo) {
      if (0 < i) {
        prevEmo = emotions.get(i - 1);
      }   
      if (i < emotions.size() - 1) {
        nextEmo = emotions.get(i + 1);
      }
      break;
    }
  }

  float diff = px - x;      
  if (0 < diff) {
    viewEmotion(nextEmo);
    currEmo = nextEmo;
  } 

  if (diff < 0) {
    viewEmotion(prevEmo);
    currEmo = prevEmo;
  }
}

void dragWheel(float x0, float y0, float x, float y, Rectangle bounds) { 
  float xc = bounds.x + bounds.w/2;
  float yc = bounds.y + bounds.h/2;

  float sx0 = x0 - xc;
  float sy0 = y0 - yc - wheelYPos.get();
  sx0 /= wheelScale.get();
  sy0 /= wheelScale.get();  
  float a0 = atan2(sy0, sx0);
  if (a0 < 0) {
    a0 += TWO_PI;
  }  

  float sx1 = x - xc;
  float sy1 = y - yc - wheelYPos.get();
  sx1 /= wheelScale.get();
  sy1 /= wheelScale.get();
  float a1 = atan2(sy1, sx1);
  if (a1 < 0) {
    a1 += TWO_PI;
  }

  wheelRAngle.setTarget(wheelRAngle.get() + a1 - a0);
}

void setCurrentMode(int mode) {
  if (currentMode != mode) {
    previousMode = currentMode;
    currentMode = mode;
    int days = daysSinceStart.getInt();
    if (mode == MODE_BOOKSHELF) {
      groupBooksByEmotion(days, true);
      setViewRegionAllBookshelf();
    } else if (mode == MODE_WHEEL) {
      groupBooksByEmotion(days, true);
      setViewRegionAllWheel();
    } else if (mode == MODE_HISTORY) {
      groupBooksByEmotion(daysRunningTot, true);
    } 
    
    if (mode == MODE_INFO) {
      // Trigger fade-out animation.
      viewFadeinAlpha.set(0);
      viewFadeinAlpha.setTarget(127);      
    } else {
      // Trigger fade-in animation.
      viewFadeinAlpha.set(0);
      viewFadeinAlpha.setTarget(255);  
    }   

    // Be sure nothing remains selected.
    selBook = null;
    selLang = null;

    // Animation is stopped.
    playingAnim = false;
  }
}
  
void setGrouping(boolean byLang) {
  int days = daysSinceStart.getInt(); 
  if (byLang) {
    sortByLang = true;
    groupBooksByEmotion(days, true);    
  } else {
    sortByLang = false;
    groupBooksByEmotion(days, false);
  }
  setViewRegionAllBookshelf();
}

void checkMouseActivity() {
  if (abs(pmouseX - mouseX) == 0 && abs(pmouseY - mouseY) == 0 && !mousePressed) {
    noMouseActivityCount++;
  } else {
    noMouseActivityCount = 0;
    mouseActivity = true;
    hintInfo.close();
  }
  if (30 < noMouseActivityCount) {
    mouseActivity = false;
    if (300 < noMouseActivityCount) {
      hintInfo.closeGracefully();
    }
  }
}

void timelineRollOver(float x, float y) {
  int areaExpand = 60;
  int areaAdjust_Y = 5;

  newsRollover = x - areaExpand/2 < mouseX && mouseX < x + areaExpand/2 &&
                 y - areaExpand/2 + areaAdjust_Y < mouseY && mouseY < y + areaExpand/2 + areaAdjust_Y;
}

void checkResize() {
  if (WIDTH != width || HEIGHT != height) {
    viewMenu.resize(0, height - 50, 200, 50);
    timeline.resize(200, height - 50, width - 200, 50); 
    viewArea.resize(0, -8, width, height - 90);
    helpMenu.resize(width - 60, 20, 70, 30);
    legendArea.resize(0, 0, 200, height - 100);
    infoArea.resize(200, 0, width - 200, height);
    
    WIDTH = width;
    HEIGHT = height;
    historyCanvas[0] = historyCanvas[1] = null; 
  }   
}

