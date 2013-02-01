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
  float w0;
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
    w0 = w;
    bookBubble = new BookBubble();
    dateInfo = new Message(selHistoryColor);
    langTab = new LanguageTab();
    emoTab = new EmotionTab();
    langBarY = y + bookshelfTop + bookBubbleTailH + fontSize + 5 * (fontSize + 5) + 5 + 10;
  }

  void update() {
    if (currentMode == MODE_BOOKSHELF) {
      for (Book book: books) {
        book.update(currentMode);
      }
      viewRegion.update();
      if (daysSinceStart.update()) {
        groupBooksByEmotion(daysSinceStart.getInt(), true);
      }  
      bookStrokeWeight.update();

      langBarH.update(); 
      bookTopHeight.update();
      bookHeightTimer.update();

      langTab.update();
      emoTab.update();
    } 
    else if (currentMode == MODE_WHEEL) {
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
      daysSinceStart.update();

      bookStrokeWeight.update();
      bookTopHeight.update();

      wheelRAngle.update();
      wheelYPos.update();
      wheelScale.update();
      
      wheelWidth.update();
    } 
    else {
      daysSinceStart.update();      
    }

    dateInfo.update();
    bookBubble.update();

    viewFadeinAlpha.update();
    viewLeftMargin.update();

    float xoff = viewLeftMargin.get();
    bounds.x = xoff;
    bounds.w = w0 - xoff;
  }

  void draw() {
    if (currentMode == MODE_BOOKSHELF) {

      if (groupByLangFirst) {      
        if (insideLangBar(mouseX, mouseY, bounds, langBarY)) {
          selLang = getSelectedLanguageInBookshelf(mouseX, mouseY, bounds, langBarY);
        } 
        else {
          selLang = null;
        }  
        langTab.open(selLang);
        langTab.draw();
        emoTab.close();
      } 
      else {
        if (insideLangBar(mouseX, mouseY, bounds, langBarY)) {
          selEmo = getSelectedEmotionInBookshelf(mouseX, mouseY, bounds, langBarY);
        } 
        else {
          selEmo = null;
        }  
        emoTab.open(selEmo);
        emoTab.draw();
        langTab.close();
      }

      if (insideBookshelf(mouseX, mouseY, bounds, langBarY)) {
        if (groupByLangFirst) {
          selBook = getSelectedBookInBookshelfGroupByLang(mouseX, mouseY, bounds, langBarY);
        } else {
          selBook = getSelectedBookInBookshelfGroupByEmo(mouseX, mouseY, bounds, langBarY);
        }
      } 
      else {
        selBook = null;
      }
      bookBubble.open(selBook);
      bookBubble.draw();

      if (!mouseActivity && selBook == null && selLang == null && viewRegion.zoomLevel != VIEW_ALL) {
        hintInfo.open("click anywhere above the language bar to zoom out");
      }

      drawBookshelf(bounds, langBarY);
    } 
    else if (currentMode == MODE_WHEEL) {
      if (viewRegion.zoomLevel == VIEW_BOOK) {
        selBook = getSelectedBookInWheel(bounds, selBook, wheelTop);
      }
      bookBubble.open(selBook);
      bookBubble.draw();      

      if (!mouseActivity && viewRegion.zoomLevel != VIEW_ALL) {
        hintInfo.open("click anywhere outside the language circle to zoom out");
      }

      animatingTrails = drawWheel(bounds, wheelTop);
    } 
    else if (currentMode == MODE_HISTORY) {      
      drawHistory(bounds, historyTop);

      if (!histLocked && (abs(pmouseX - mouseX) > 0 || abs(pmouseY - mouseY) > 0)) {        
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
    }
    bookBubble.draw();
    dateInfo.draw();
  }

  boolean mousePressed() {
    if (!contains(mouseX, mouseY)) return false;

    selected = true;

    if (currentMode == MODE_BOOKSHELF) { 
      setViewRegionBookshelf(mouseX, mouseY, bounds, langBarY);
    } 
    else if (currentMode == MODE_WHEEL) {      
      pressX0 = mouseX;
      pressY0 = mouseY;
      draggingWheel = false;
    } else if (currentMode == MODE_HISTORY) {
      histLocked = !histLocked;  
    }
    return true;
  }

  boolean mouseDragged() {
    if (!selected) return false;

    if (currentMode == MODE_BOOKSHELF) {
      if (langBarY - langBarH.get() <= mouseY && mouseY <= langBarY) { 
        dragViewRegion(pmouseX, mouseX);
      }
    } 
    else if (currentMode == MODE_WHEEL) {
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
    } 
    else if (currentMode == MODE_WHEEL) {
      if (!draggingWheel) {
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
    noStroke();
    fill(replaceAlpha(backgroundColor, 180));
    rect(bounds.x, bounds.y, bounds.w, bounds.h);

    stroke(menuStrokeColor);
    strokeWeight(1);

    float xl = bounds.x;

    float xc = xl + w5/2 - bw/2;
    float yc = bounds.y + h2 - bw/2;
    if (currentMode == MODE_BOOKSHELF) {
      image(bookshelfSel, xc, yc);
    } 
    else { 
      image(bookshelfUnsel, xc, yc);
    }     

    xl += w5;
    xc = xl + w5/2 - ww/2;
    if (currentMode == MODE_WHEEL) {
      image(wheelSel, xc, yc);
    } 
    else { 
      image(wheelUnsel, xc, yc);
    }      

    xl += w5;
    xc = xl + w5/2 - hw/2;
    if (currentMode == MODE_HISTORY) {
      image(historySel, xc, yc);
    } 
    else { 
      image(historyUnsel, xc, yc);
    }

    if (currentMode == MODE_BOOKSHELF) {
      xl += w5;
      xc = xl + w5/2 - lw/2;
      if (groupByLangFirst) {
        image(langSel, xc, yc);
      } else {
        image(langUnsel, xc, yc);
      }

      xl += w5;
      xc = xl + w5/2 - ew/2;
      if (!groupByLangFirst) {
        image(emoSel, xc, yc);
      } else {
        image(emoUnsel, xc, yc);
      }      
    }
   
    hint.draw(); 
  }

  boolean mousePressed() {
    hint.close();
    
    if (!contains(mouseX, mouseY)) return false;
    
    selected = true;

    if (contains(mouseX, mouseY)) {
      int p = int((mouseX - bounds.x) / w5);
      if (p == 0) {
        setCurrenMode(MODE_BOOKSHELF);
      } 
      else if (p == 1) {
        setCurrenMode(MODE_WHEEL);
      } 
      else if (p == 2) {
        setCurrenMode(MODE_HISTORY);
      } else if (currentMode == MODE_BOOKSHELF) {
        if (p == 3) {
          setGrouping(true);
        }
        else if (p == 4) {
          setGrouping(false);
        }
      }
    }
    return true;
  }

  void setCurrenMode(int mode) {
    if (currentMode != mode) {
      currentMode = mode;
      int days = daysSinceStart.getInt();
      if (mode == MODE_BOOKSHELF) {
        groupBooksByEmotion(days, true);
        setViewRegionAllBookshelf();
      } 
      else if (mode == MODE_WHEEL) {
        groupBooksByEmotion(days, true);
        setViewRegionAllWheel();
      } 
      else if (mode == MODE_HISTORY) {
        groupBooksByEmotion(daysRunningTot, true);
      }
      // Trigger fade-in animation.
      viewFadeinAlpha.set(0);
      viewFadeinAlpha.setTarget(255);

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
      groupByLangFirst = true;
      groupBooksByEmotion(days, true);    
    } else {
      groupByLangFirst = false;
      groupBooksByEmotion(days, false);
    }
    setViewRegionAllBookshelf();
  }
  
  void mouseMoved() {
    if (!contains(mouseX, mouseY)) {
      hint.close();
      return;
    }
    
    int p = int((mouseX - bounds.x) / w5);
      
    float x = mouseX;
    float y = bounds.y + h2 - bw;
      
    if (p == 0) {
      hint.open("bookshelf view", x, y);
    } 
    else if (p == 1) {
      hint.open("wheel view", x, y);
    } 
    else if (p == 2) {
      hint.open("history view", x, y);
    } else if (currentMode == MODE_BOOKSHELF) {
      if (p == 3) {
        hint.open("group by language", x, y);
      }
      else if (p == 4) {
        hint.open("group by emotion", x, y);
      }
    }
  } 
  
  void resize(float x, float y, float w, float h) {
    super.resize(x, y, w, h);
    w5 = w/5;
    h2 = h/2;  
  } 
}

class Timeline extends InterfaceElement {
  float h2;
  float margin;
  boolean compact;
  boolean animating;
  boolean insideDragArea;

  Timeline(float x, float y, float w, float h) {
    super(x, y, w, h);  
    h2 = h/2;
    margin = 100;
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
    noStroke();
    fill(replaceAlpha(backgroundColor, 180));
    rect(bounds.x, bounds.y, bounds.w, bounds.h);

    fill(defTextColor);

    float xm = bounds.x + bounds.w - margin + 10;
    if (currentMode == MODE_WHEEL) {
      if (animating) {
        text("stop animation", xm, bounds.y + h2 + fontSize/2);
      } 
      else {
        text("play animation", xm, bounds.y + h2 + fontSize/2);
      }
    } 
    else if (currentMode == MODE_BOOKSHELF && viewRegion.zoomLevel == VIEW_BOOK) {
      // } else if (currentMode == MODE_BOOKSHELF) {
      if (compactTime) {
        text("expand time", xm, bounds.y + h2 + fontSize/2);
      } 
      else {
        text("compact time", xm, bounds.y + h2 + fontSize/2);
      }
    }   

    float x0 = bounds.x;
    float x1 = bounds.x + bounds.w - margin;

    if (currentMode == MODE_HISTORY) { // added expand timeline for history mode
      x1 = bounds.x + bounds.w-20;
    }

    stroke(timelineColor);
    strokeWeight(1);
    line(x0, bounds.y + h2, x1, bounds.y + h2);
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
    triangle(xc - 5, bounds.y + h2 - 10, xc + 5, bounds.y + h2 - 10, xc, bounds.y + h2);
    Date selDate = dateAfter(startDate, int(daysSinceStart.get()));
    drawTimeBox(xc, x0, x1, bounds.y + h2 - 15, selDate);
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
  }

  boolean mousePressed() {    
    if (currentMode == MODE_HISTORY && dist(mouseX, mouseY, historyCircleX, historyCircleY) < 10) {
      // Hack to drag the white circle in the history view and control the timeline, part 1 
      // (see setTimeHistoryHack() function below for the rest) 
      selected = true;
      return true;
    }
    
    if (!contains(mouseX, mouseY)) return false;
    selected = true;
    if (mouseX > bounds.x + bounds.w - margin) {

      if (currentMode == MODE_WHEEL) {
        animating = !animating;

        if (animating) {
          //daysSinceStart.set(0);
          //groupBooksByEmotion(0, true);
          playingAnim = true;
        } 
        else {
          playingAnim = false;
        }
      } 
      else if (viewRegion.zoomLevel == VIEW_BOOK) {
        compact = !compact;

        if (compactTime) {
          bookHeightTimer.setTarget(0);
          compactTime = false;
        } 
        else {
          bookHeightTimer.setTarget(1);
          compactTime = true;
        }
      }
    } 
    else {
      insideDragArea = true;
      setTime(mouseX);
    }

    return true;
  }

  boolean mouseDragged() {
    if (!selected) return false;
    if (bounds.x < mouseX && mouseX < bounds.x + bounds.w - margin && 
        bounds.y < mouseY && mouseY < bounds.y + bounds.h) {
      setTime(mouseX);
    } else if (currentMode == MODE_HISTORY) {
      setTimeHistoryHack(mouseX);      
    }
    return true;
  }

  void setTime(float mx) {
    int days = int(map(mx, bounds.x, bounds.x + bounds.w - margin, 0, daysRunningTot));
    daysSinceStart.setTarget(days);
    if (currentMode == MODE_BOOKSHELF) {
      if (groupByLangFirst) {
        groupBooksByEmotion(days, true);
      } 
      else {
        groupBooksByEmotion(days, false);
        viewRegion.update(numBooksWithEmo());
      }
    } 
    else if (currentMode == MODE_WHEEL) {
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

    //    noStroke(); // backgroung rect of show/hide legend
    //    fill(replaceAlpha(backgroundColor, 180));
    //    rect(bx, by, bw, bh);

    strokeWeight(1);
    stroke(legendLineColor);
    // stroke(143);
    fill(255);
    // rect(bx, by + bh/2 - fontSize/2, fontSize, fontSize);
    rect(bx +1, by + bh/2 - fontSize/2, fontSize -1, fontSize -2);
    line(bx + fontSize/2, bounds.y, bx + fontSize/2, by + bh/2 - fontSize/2);

    fill(defTextColor);
    if (closed) {
      text("show legend", xc, yc);
    } 
    else {
      text("hide legend", xc, yc);

      float xlang = 0.4 * bounds.w;
      float xemo = 0.6 * bounds.w;
      float h = bounds.h * animTimer.get(); 

      //      line(xlang, bounds.y, xlang, bounds.y + h);
      //      line(xemo, bounds.y, xemo, bounds.y + h + animTimer.get() * 20);    
      line(xlang, bounds.y, xlang, bounds.y + h-35);
      line(xemo, bounds.y, xemo, bounds.y + h + animTimer.get() * 20-42); 

      //  float y = h - 20; // height of legend
      float y = h - 55;
      for (int i = languages.size() - 1; i >= 0; i--) {
        int ri = languages.size() - 1 - i;
        int ei = emotions.size() - ri - 1;

        if (bounds.x + 20 < y) {         
          Language lang = languages.get(i);  
          if (lang.id == 0) continue;

          float x0 = xlang - 10;
          float y0 = y;
          float x1 = x0 + 20; 
          float y1 = y0 + 0.7 * fontSize;

          fill(lang.argb);             
          rect(x0, y0, x1 - x0, y1 - y0);   // lang rects       
          fill(defTextColor);
          float tw = textWidth(lang.name);
          //text(lang.name, xlang - 15 - tw, y + 0.7 * fontSize/2 + fontSize/2); // location of lang text
          text(lang.name, xlang - 15 - tw, y + 0.7 * fontSize/2 + fontSize/2 -1); // location of lang text

          if (0 <= ei) {
            Emotion emo = emotions.get(ei);
            fill(emo.argb);
            //  rect(xemo - 0.7 * fontSize/2, y, 0.7 * fontSize, 0.7 * fontSize); // emo rects         
            rect(xemo - 0.9 * fontSize/2, y, 0.95 * fontSize, 0.8 * fontSize);
            fill(defTextColor);
            // text(emo.name, xemo + 0.7 * fontSize, y + 0.7 * fontSize/2 + fontSize/2);
            text(emo.name, xemo + 0.7 * fontSize+3, y + 0.7 * fontSize/2 + fontSize/2 -1); // locaton of emo text
          }

          if (x0 < mouseX && mouseX <= x1 && y0 <= mouseY && mouseY <= y1 && !mouseActivity) {
            //  hintInfo.open("click language to open the webpage for the " + lang.name + " community"); // rollover message
            hintInfo.open("click language to open the webpage for the " + lang.name + " community"); // rollover message

            //            String msg = ;
            //            tw = textWidth(msg);
            //            noStroke();
            //            fill(0, 180);
            //            rect(x1 + 8, y - 0.5 * fontSize/2, tw + 4, 1.5 * fontSize);            
            //            stroke(legendLineColor);
            //            
            //            fill(defTextColor);
            //            text(msg, x1 + 10, y + 0.7 * fontSize/2 + fontSize/2);
          }

          //     y -= 0.7 * fontSize + 20;
          y -= 0.7 * fontSize + 22;// distance between sqs
        } 
        else {
          break;
        }
      }
    }
  }

  boolean mousePressed() {
    if (contains(mouseX, mouseY)) {
      selected = true;
      if (closed) {
        open();
      } 
      else {
        close();
      }   
      return true;
    } 
    else if (!closed) {     

      float xlang = 0.4 * bounds.w;
      float h = bounds.h * animTimer.get();       
      float y = h - 20;
      for (int i = languages.size() - 1; i >= 0; i--) {
        Language lang = languages.get(i);  
        if (lang.id == 0) continue;

        float x0 = xlang - 10;
        float y0 = y;
        float x1 = x0 + 20; 
        float y1 = y0 + 0.7 * fontSize;        
        if (x0 < mouseX && mouseX <= x1 && y0 <= mouseY && mouseY <= y1) {
          if (!lang.url.equals("")) {
            //     link(lang.url, "_new");  // hyperlink
          }
          return true;
        }

        y -= 0.7 * fontSize + 20;
      }

      return false;
    } 
    else {
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

// -------------------------------------------------------------------------------------------------
//
// Assorted interface-related functions, maybe the can be put inside the appropiate interface class?

void setViewRegionAll() {
  if (currentMode == MODE_BOOKSHELF) {
    setViewRegionAllBookshelf();
  } 
  else if (currentMode == MODE_WHEEL) {
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

    if (groupByLangFirst) {
      setLanguage(x, bounds);
    } 
    else {
      setEmotion(x, bounds);
    }
  } 
  else {
    viewRegion.zoomLevel = VIEW_BOOK; 
    bookStrokeWeight.setTarget(bookOutlineW);
    bookTopHeight.setTarget(maxBookHeight);
    currLang = null;
    currEmo = null;

    // Set view region around selected book
    if (groupByLangFirst) {
      setViewRegionBookshelfGroupByLang(x, bounds);
    } 
    else {
      setViewRegionBookshelfGroupByEmo(x, bounds);
    }
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

void setViewRegionAllBookshelf() {
  int count = groupByLangFirst ? books.size() : numBooksWithEmo();
  viewRegion.setTarget(0, count);

  viewRegion.zoomLevel = VIEW_ALL;  
  bookStrokeWeight.set(0);
  bookTopHeight.setTarget(0);
  langBarH.setTarget(langBarWAll);
  bookHeightTimer.setTarget(0);
  compactTime = false; 
  currLang = null;
  currEmo = null;
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

  if (r0 < d && d < r1) {
    int emoCount = 0;
    for (Emotion emo: emotions) {
      if (emo.id == 0) continue;

      // Draw emotion arc
      float a0 = bookAngle(emoCount);
      emoCount += emo.booksInEmo.size();
      float a1 = bookAngle(emoCount);

      if (a0 <= angle && angle <= a1) {
        wheelYPos.setTarget(wheelDispEmo);
        wheelScale.setTarget(wheelScaleEmo);
        float centAngle = PI + HALF_PI - 0.5 * (a0 + a1);
        if (PI < centAngle) centAngle = centAngle - TWO_PI;
        wheelRAngle.setTarget(centAngle);
        viewRegion.zoomLevel = VIEW_EMO;
        wheelWidth.set(wheelWidthView);
        return;
      }
    }
  } 
  else if (r1 < d && d < r1 + maxBookHeight) {
    selectBookInWheel(d, angle);
  } 
  else {
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
  SelectedBook res = null;
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
            int e = book.insideBookshelf(x, y, firstBook, w, bounds.x, yTop, h, totLen);            
            if (-1 < e) {
              res = new SelectedBook(book, emotionsByID.get(e), book.getBookCenterX(firstBook, w, bounds.x), 
              yTop - h - bookTopHeight.get() - 5);
              return res;
            }
          }
        }
      }      
      count += bemo.size();
    }
  } 

  return res;
}

SelectedBook getSelectedBookInBookshelfGroupByEmo(float x, float y, Rectangle bounds, float yTop) {
  SelectedBook res = null;
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
            int e = book.insideBookshelf(x, y, firstBook, w, bounds.x, yTop, h, totLen);            
            if (-1 < e) {
              res = new SelectedBook(book, emotionsByID.get(e), book.getBookCenterX(firstBook, w, bounds.x), 
              yTop - h - bookTopHeight.get() - 5);
              return res;
            }
          }
        }
      }      
      count += blang.size();
    }
  } 

  return res;
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

  SelectedBook res = null;
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
          res = new SelectedBook(book, emo, mx, my);
          return res;
        }
      }
      pt0 = pt;
    }
  }
  return res;
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
    } 
    else {
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
  bookHeightTimer.setTarget(0);
  compactTime = false;  
  int langCount = 0;
  for (Language lang: languages) {  
    if (lang.id == 0) continue;
    int langCount0 = langCount;
    float x0 = bookX(langCount, bounds.x, bounds.w);       
    langCount += lang.booksInLang.size();      
    float x1 = bookX(langCount, bounds.x, bounds.w); 

    if (x0 <= x && x <= x1) {
      if (langCount - langCount0 < sizeBookView) {
        // The number of books in this language is too small, 
        // centering around the middle book and using
        int imid = (langCount0 + langCount)/2; 
        viewRegion.setTarget(imid - sizeBookView/2, imid + sizeBookView/2, books.size());
      } 
      else {
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
  bookTopHeight.setTarget(0);
  langBarH.setTarget(langBarWLang);
  bookHeightTimer.setTarget(0);
  compactTime = false;    
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
      } 
      else {
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
    langCount += lang.booksInLang.size(); 

    if (lang == selLang) {      
      if (langCount - langCount0 < sizeBookView) {
        // The number of books in this language is too small, 
        // centering around the middle book and using
        int imid = (langCount0 + langCount)/2; 
        viewRegion.setTarget(imid - sizeBookView/2, imid + sizeBookView/2, books.size());
      } 
      else {
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
      } 
      else {
        viewRegion.setTarget(emoCount0, emoCount, totCount);
      }  
      return;
    }
  }
}

SelectedLanguage getSelectedLanguageInBookshelf(float x, float y, Rectangle bounds, float yTop) {
  float w = bounds.w / viewRegion.getBookCount();
  float langPadding = bookPadding * w/2;
  SelectedLanguage res = null;
  int langCount = 0;
  for (Language lang: languages) {  
    if (lang.id == 0) continue;
    int langCount0 = langCount;
    float x0 = bookX(langCount, bounds.x, bounds.w);       
    langCount += lang.booksInLang.size();      
    float x1 = bookX(langCount, bounds.x, bounds.w);     
    if (x0 <= x && x <= x1) {            
      res = new SelectedLanguage(lang, max(bounds.x, x0 + langPadding), yTop - langBarH.get());
      return res;
    }
  }
  return res;
}

SelectedEmotion getSelectedEmotionInBookshelf(float x, float y, Rectangle bounds, float yTop) {
  float w = bounds.w / viewRegion.getBookCount();
  float emoPadding = bookPadding * w/2;
  SelectedEmotion res = null;
  int emoCount = 0;
  for (Emotion emo: emotions) {  
    if (emo.id == 0) continue;
    int emoCount0 = emoCount;
    float x0 = bookX(emoCount, bounds.x, bounds.w);       
    emoCount += emo.booksInEmo.size();      
    float x1 = bookX(emoCount, bounds.x, bounds.w);     
    if (x0 <= x && x <= x1) {            
      res = new SelectedEmotion(emo, max(bounds.x, x0 + emoPadding), yTop - langBarH.get());
      return res;
    }
  }
  return res;
}

void dragViewRegion(float px, float x) {
  if (viewRegion.zoomLevel == VIEW_ALL) return;

  if (viewRegion.zoomLevel == VIEW_LANG) {
    if (groupByLangFirst) {
      dragViewRegionGroupByLang(px, x);
    } 
    else {
      dragViewRegionGroupByEmo(px, x);
    }
  } 
  else {
    currLang = null;
    currEmo = null;

    float first = viewRegion.firstBook.get();
    float last = viewRegion.lastBook.get();
    float f = 20 * (float)(last - first);
    float diff = f * (px - x) / width;
    int count = groupByLangFirst ? books.size() : numBooksWithEmo();
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

void checkMouseActivity() {
  if (abs(pmouseX - mouseX) == 0 && abs(pmouseY - mouseY) == 0 && !mousePressed) {
    noMouseActivityCount++;
  } 
  else {
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
    viewMenu.resize(10, height - 50, 180, 50);
    timeline.resize(205, height - 50, width - 200, 50); 
    viewArea.resize(0, -8, width, height - 90);
    legendArea.resize(0, 0, 200, height - 100);
    
    WIDTH = width;
    HEIGHT = height; 
  }   
}

