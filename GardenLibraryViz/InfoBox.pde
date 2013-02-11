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
    isbnStr = "ISBN: " + book.ISBN;
    langStr = "Language: " + lang.name;
    emoStr = "Emotion: " + emo.name;

    float w = max(new float[] { 
      textWidth(titleStr), 
      textWidth(authorStr), 
      textWidth(isbnStr), 
      textWidth(langStr), 
      textWidth(emoStr)
    } 
    ) + 5;

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

      float w = mainW.get();
      float xmax = x0 + w + 20;
      
      noStroke();
      fill(lang.argb);
      rect(x0 - 10, y0 - tailH.get() - mainH.get(), fontSize + 10, mainH.get());
      triangle(x0 - 10 + 5, y0 - tailH.get() + 5, 
               x0 + fontSize - 5, y0 - tailH.get() + 5, 
               x0 + fontSize/2 - 5, y0 - tailH.get() + 10);

      float s = codeScale.get();
      if (0 < s) {
        textFont(langFont);
        float cw = textWidth(book.barcode);
        fill(0);

        pushMatrix();          
        translate(x0, y0 - tailH.get() - mainH.get()/2);
        rotate(HALF_PI);          
        scale(s); 
        text(book.barcode, -cw/2, fontSize/2);
        popMatrix();
      }
       
      strokeWeight(0.5);
      stroke(150);
      fill(0, 166);

      float x1, x2;
      if (xmax <= width) {
        // Left to right orientation
        float wl = fontSize + 10 + 3;
        x1 = x0 + wl - 10;
        x2 = x0 + wl + w; 
      } else {
        // Right to left orientation          
        x1 = x0 - 10 - 3 - w - 10;
        x2 = x0 - 10 - 3;
      }
        
      beginShape(POLYGON); 
      vertex(x2, y0 - tailH.get());
      vertex(x2, y0 - tailH.get() - mainH.get());
      vertex(x1, y0 - tailH.get() - mainH.get());
      vertex(x1, y0 - tailH.get());
      endShape(CLOSE);
        
      textFont(defFont);
      fill(langFontColor);
      float xt = x1 + 5;
      float yt = y0 - tailH.get() - mainH.get();
      float h = fontSize + 5;
      if (h < mainH.get()) text(chopString(titleStr), xt, yt + h);
      h += fontSize + 5;
      if (h < mainH.get()) text(chopString(authorStr), xt, yt + h);
      h += fontSize + 5;
      if (h < mainH.get()) text(chopString(isbnStr), xt, yt + h);
      h += fontSize + 5;
      if (h < mainH.get()) text(chopString(langStr), xt, yt + h);
      h += fontSize + 5;
      if (h < mainH.get()) text(chopString(emoStr), xt, yt + h);
    }
  }

  String chopString(String str) {
    if (isAnimating()) {
      String chopStr = chopStringRight(str, defFont, mainW.get());
      return chopStr;
    } 
    else {
      return str;
    }
  } 

  void open(float x, float y) {
    if (!visible) {
      super.open(x, y);      
      tailH.setTarget(bookBubbleTailH);
      mainH.setTarget(5 * (fontSize + 5) + 7);
      codeScale.setTarget(1);
    } 
    else {
      moveTo(x, y);
    }
  }

  void open(SelectedBook sel) {
    if (sel == null) {
      close();
    } 
    else {
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
  SoftFloat tabH;
  float tabW;
  boolean animating;

  InfoTab() {
    super();
    tabH = new SoftFloat();
  } 

  void update() {
    animating = tabH.update();
  }

  void open(float x, float y) {
    if (!visible) {
      super.open(x, y);      
      tabH.setTarget(2 * (fontSize + 5) + 5);
    } 
    else {
      moveTo(x, y);
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

class LanguageTab extends InfoTab {
  Language lang;
  Emotion emo;
  String txt;

  void setLanguage(SelectedLanguage sel) {
    if (lang != null && lang != sel.lang) {
      visible = false; 
      tabH.set(0);
    }
    lang = sel.lang;
    emo = sel.emo;
    if (emo == null) {          
      int numRead = lang.numReadBooks();
      int numTot = lang.numTotBooks();      
      txt = "Books: " + numRead + "/" + numTot;      
    } else {
      ArrayList<Book> blang = emo.booksPerLang.get(lang.id);      
      txt = "Books: " + blang.size(); 
    }
    tabW = max(new float[] { 
      textWidth(lang.name), 
      textWidth(txt)
    } 
    );
  }

  void draw() {
    if (visible) {      
      noStroke();
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
        text(txt, x0 - xoff + 5, y0 - tabH.get() - bh + 2 * fontSize + 10);
      }
    }
  }

  void open(SelectedLanguage sel) {
    if (sel == null) {
      close();
    } 
    else {
      setLanguage(sel);
      open(sel.x, sel.y);
    }
  }
}

class EmotionTab extends InfoTab {
  Emotion emo;
  String txt;

  void setEmotion(SelectedEmotion sel) {
    if (emo != null && emo != sel.emo) {
      visible = false; 
      tabH.set(0);
    }
    emo = sel.emo;
    txt = "Books: " + emo.booksInEmo.size();
    tabW = max(new float[] { 
      textWidth(emo.name), 
      textWidth(txt)
    } 
    );
  }

  void draw() {
    if (visible) {      
      noStroke();
      fill(emo.argb);

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
      text(emo.name, x0 - xoff + 5, y0 - tabH.get() - bh + fontSize + 5);
      if (fontSize < tabH.get()) {
        text(txt, x0 - xoff + 5, y0 - tabH.get() - bh + 2 * fontSize + 10);
      }
    }
  }

  void open(SelectedEmotion sel) {
    if (sel == null) {
      close();
    } 
    else {
      setEmotion(sel);
      open(sel.x, sel.y);
    }
  }
}

class HintInfo extends InfoBox {
  String message;
  boolean animating;
  SoftFloat animTimer;
  float msgWidth;

  HintInfo() {
    super();
    message =  "";
    animating = false;
    animTimer = new SoftFloat();
  }

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

  void open(String message, float x, float y) {
    moveTo(x, y);
    open(message);
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

class Message extends InfoBox {
  String message;
  boolean animating;
  SoftFloat animTimer;
  float msgWidth;
  int textColor;

  Message(int tcolor) {
    super();
    message =  "";
    animating = false;
    animTimer = new SoftFloat();
    textColor = tcolor;
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
      fill(replaceAlpha(textColor, int(255 * t)));      
      float x = x0;
      float y = y0;
      if (width < x + msgWidth) {
        x -= x + msgWidth - width;    
      }       
      text(message, x, y);
    }
  }

  void open(String message) {
    this.message = message;
    msgWidth = textWidth(message);
    if (!visible) {    
      visible = true;      
      animTimer.set(0);
      animTimer.setTarget(1);
    }
  }

  void open(String message, float x, float y) {    
    moveTo(x, y);
    open(message);
  }

  void close() {
    if (visible) {
      visible = false;
      animTimer.set(0);
    }
  }

  boolean isAnimating() {
    return animating;
  }
}

