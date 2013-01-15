// Info boxes to show contextual information

class InfoBox {
  float x0, y0;
  boolean visible;

  InfoBox() {
    visible = false;
  }

  void update() {
  }

  void draw() {
  }

  void open(float x, float y) {
    x0 = x;
    y0 = y;
    visible = true;
  }

  void close() {
    visible = false;
  }

  void moveTo(float x, float y) {
    x0 = x;
    y0 = y;
  }

  boolean isAnimating() {
    return false;
  }

  boolean isVisible() {
    return visible;
  }
}

class BookBubble extends InfoBox {
  boolean animatingTail;
  boolean animatingMain;
  boolean animatingCode;

  Book book;
  Emotion emo;
  Language lang;

  SoftFloat tailH;
  SoftFloat mainH;
  SoftFloat mainW;
  SoftFloat codeScale;

  String titleStr, authorStr, isbnStr, langStr, emoStr;

  BookBubble() {
    super();
    tailH = new SoftFloat();
    mainH = new SoftFloat();
    mainW = new SoftFloat();
    codeScale = new SoftFloat();
  }

  void setBook(SelectedBook s) {
    book = s.book;      
    emo = s.emo;
    lang = languagesByID.get(s.book.lang);

    titleStr = "Title: " + book.title;
    authorStr = "Author: " + book.author;
    //isbnStr = "ISBN: " + book.ISBN;
    langStr = "Language: " + lang.name;
    emoStr = "Emotion: " + emo.name;

    float w = max(new float[] { textWidth(titleStr), 
                                textWidth(authorStr), 
//                                textWidth(isbnStr), 
                                textWidth(langStr), 
                                textWidth(emoStr) } ) + 5;

    mainW.setTarget(w);
  }

  void update() {
    animatingTail = tailH.update();
    boolean uh = mainH.update();
    boolean uw = mainW.update();
    animatingMain = uh || uw;
    codeScale.update();
  }

  void draw() {
    if (visible) {
      strokeWeight(1);
      stroke(0);
      fill(255);

      float w = mainW.get();
      float xmax = x0 + w + 20;
      if (xmax <= width) {
        // Left to right orientation
        beginShape(POLYGON); 
        vertex(x0, y0);
        vertex(x0 + 20, y0 - tailH.get());
        vertex(x0 + w, y0 - tailH.get());
        vertex(x0 + w, y0 - tailH.get() - mainH.get());
        vertex(x0 - 10, y0 - tailH.get() - mainH.get());
        vertex(x0 - 10, y0 - tailH.get());
        vertex(x0, y0 - tailH.get());      
        endShape(CLOSE);

        fill(0);
        float xt = x0 - 5;
        float yt = y0 - tailH.get() - mainH.get();
        float h = fontSize + 5;
        if (h < mainH.get()) text(chopString(titleStr), xt, yt + h);
        h += fontSize + 5;
        if (h < mainH.get()) text(chopString(authorStr), xt, yt + h);
        //h += fontSize + 5;
        //if (h < mainH.get()) text(chopString(isbnStr), xt, yt + h);
        h += fontSize + 5;
        if (h < mainH.get()) text(chopString(langStr), xt, yt + h);
        h += fontSize + 5;
        if (h < mainH.get()) text(chopString(emoStr), xt, yt + h);

        fill(lang.argb);
        rect(x0 + w, y0 - tailH.get() - mainH.get(), fontSize + 10, mainH.get());

        fill(infoTextColor);
   
        float s = codeScale.get();
        if (0 < s) {
          pushMatrix();
          translate(x0 + w + fontSize/2 + 5, y0 - tailH.get() - mainH.get()/2);
          rotate(HALF_PI);
          textFont(langFont);
          float cw = textWidth(book.barcode);
          scale(s);
          fill(langFontColor);
          text(book.barcode, -cw/2, fontSize/2);
          textFont(defFont);
          popMatrix();
        } 
      } else {
        // Right to left orientation
        beginShape(POLYGON);
        vertex(x0, y0);
        vertex(x0 + 20, y0 - tailH.get());
        vertex(x0 + 30, y0 - tailH.get());
        vertex(x0 + 30, y0 - tailH.get() - mainH.get());
        vertex(x0 - w + 10, y0 - tailH.get() - mainH.get());
        vertex(x0 - w + 10, y0 - tailH.get());
        vertex(x0, y0 - tailH.get());
        endShape(CLOSE);

        fill(0);
        float xt = x0 - w + 15;
        float yt = y0 - tailH.get() - mainH.get();
        float h = fontSize + 5;
        if (h < mainH.get()) text(chopString(titleStr), xt, yt + h);
        h += fontSize + 5;
        if (h < mainH.get()) text(chopString(authorStr), xt, yt + h);
        //h += fontSize + 5;
        //if (h < mainH.get()) text(chopString(isbnStr), xt, yt + h);
        h += fontSize + 5;
        if (h < mainH.get()) text(chopString(langStr), xt, yt + h);
        h += fontSize + 5;
        if (h < mainH.get()) text(chopString(emoStr), xt, yt + h);

        fill(lang.argb);
        rect(x0 - w + 10 - (fontSize + 10), y0 - tailH.get() - mainH.get(), fontSize + 10, mainH.get());
        
        fill(infoTextColor);
   
        float s = codeScale.get();
        if (0 < s) {
          pushMatrix();
          translate(x0 - w + 10 - (fontSize + 10)/2, y0 - tailH.get() - mainH.get()/2);
          rotate(HALF_PI);
          textFont(langFont);        
          float cw = textWidth(book.barcode);
          scale(s);
          fill(langFontColor);
          text(book.barcode, -cw/2, fontSize/2);
          textFont(defFont);
          popMatrix();       
        }   
      }
    }
  }

  String chopString(String str) {
    if (isAnimating()) {
      String chopStr = chopStringRight(str, defFont, mainW.get());
      return chopStr;
    } else {
      return str;  
    }
  } 

  void open(float x, float y) {
    if (!visible) {
      super.open(x, y);      
      tailH.setTarget(bookBubbleTailH);
      mainH.setTarget(4 * (fontSize + 5) + 7);
      codeScale.setTarget(1);
    } else {
      moveTo(x, y);
    }
  }

  void open(SelectedBook sel) {
    if (sel == null) {
      close();
    } else {
      setBook(sel);
      open(sel.x, sel.y);
    }
  }

  void close() {
    super.close();
    tailH.set(0);
    mainW.set(30);
    mainH.set(0);
    codeScale.set(0);
  }

  boolean isAnimating() {
    return animatingTail || animatingMain || animatingCode;
  }  
}

class InfoTab extends InfoBox {
  Language lang;
  SoftFloat tabH;
  float tabW;
  boolean animating;

  InfoTab() {
    super();
    tabH = new SoftFloat();
  } 

  void setLanguage(SelectedLanguage sel) {
    if (lang != null && lang != sel.lang) {
      visible = false; 
      tabH.set(0);
    }
    lang = sel.lang;
    tabW = max(new float[] { textWidth(lang.name), 
                             textWidth("Books: " + lang.booksInLang.size()) } );                      
  }

  void update() {
    animating = tabH.update();
  }

  void draw() {
    if (visible) {      
      //strokeWeight(1);
      noStroke();
      //stroke(0);
      fill(lang.argb);

      float xmax = x0 + tabW + 10;
      float xoff = 0;
      if (width < xmax) {
        xoff = (xmax - width);
      }
      float bh = bookTopHeight.get();

      beginShape(POLYGON);
      vertex(x0 - xoff, y0);
      vertex(x0 - xoff + tabW + 10, y0);
      vertex(x0 - xoff + tabW + 10, y0 - tabH.get() - bh);
      vertex(x0 - xoff, y0 - tabH.get() - bh);      
      endShape(CLOSE);

      fill(0);
      text(lang.name, x0 - xoff + 5, y0 - tabH.get() - bh + fontSize + 5);
      if (fontSize < tabH.get()) {
        text("Books: " + lang.booksInLang.size(), x0 - xoff + 5, y0 - tabH.get() - bh + 2 * fontSize + 10);
      }
    }
  }

  void open(float x, float y) {
    if (!visible) {
      super.open(x, y);      
      tabH.setTarget(2 * (fontSize + 5) + 5);
    } else {
      moveTo(x, y);
    }
  }

  void open(SelectedLanguage sel) {
    if (sel == null) {
      close();
    } else {
      setLanguage(sel);
      open(sel.x, sel.y);
    }
  }

  void close() {
    super.close();
    tabH.setTarget(0);
  }

  boolean isAnimating() {
    return animating;
  }
}

class HintInfo extends InfoBox {
  String message;
  boolean animating;
  SoftFloat animTimer;
  float msgWidth;
  
  HintInfo(float x, float y) {
    super();
    x0 = x;
    y0 = y;
    message =  "";
    animating = false;
    animTimer = new SoftFloat();
  }

  void update() {
    animating = animTimer.update();
    if (!animating && animTimer.target == 0) {
      visible = false;
    }
  }
  
  void draw() {
    if (visible && !message.equals("")) {
      float t = animTimer.get();
      float h = y0 * t;
      
      noStroke();
      fill(replaceAlpha(backgroundColor, 180));
      rect(x0 + 5, h - fontSize + 2, msgWidth, fontSize + 4);      
      
      strokeWeight(1);
      stroke(legendLineColor);      
      line(x0, 0, x0, h);
            
      fill(replaceAlpha(defTextColor, int(255 * t)));
      text(message, x0 + 5, h);
    }  
  }
  
  void open(String message) {
    if (!this.message.equals(message)) {   
      this.message = message;
      msgWidth = textWidth(message);
      if (!visible) {    
        visible = true;      
        animTimer.set(0);
        animTimer.setTarget(1);
      }  
    }
  }
  
  void close() {
    if (visible) {
      visible = false;
      animTimer.set(0);
    }
  }
  
  void closeGracefully() {
    animTimer.setTarget(0);
  }

  boolean isAnimating() {
    return animating;
  }   
}
