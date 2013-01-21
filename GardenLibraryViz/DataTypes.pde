// All the basic data types: books, emotions, languages. 

// Class storing all the information for a single book
class Book {
  int item;
  int biblio;
  String barcode;
  String ISBN;

  String title;
  String author;

  int lang;  

  SoftFloat bookshelfPos;

  SoftFloat wheelAngle;
  float wheelRadius;
  Trail wheelTrail;  
  SoftFloat wheelHeight;
  boolean traveling;
  boolean arrived;
  int prevEmo, currEmo;

  ArrayList<PVector> history;

  ArrayList<Integer> days;
  ArrayList<Integer> emos;

  Book(int item, int biblio, String barcode, String title, String author, int lang, String ISBN) {
    this.item = item;  
    this.biblio = biblio;
    this.barcode = barcode;
    this.title = title;
    this.author = author;
    this.lang = lang;
    this.ISBN = ISBN;

    bookshelfPos = new SoftFloat();

    wheelAngle = new SoftFloat();
    wheelAngle.ATTRACTION = 0.02;
    wheelHeight = new SoftFloat();
    traveling = false;
    arrived = false;  
    wheelTrail = new Trail(trailLength);  

    days = new ArrayList<Integer>();
    emos = new ArrayList<Integer>();
    days.add(0);
    emos.add(0);

    history = new ArrayList<PVector>();
  }

  void clearTrail() {    
    wheelTrail.clear();
  }  

  void addEmotion(int t, int e) {
    days.add(t);
    emos.add(e);
  }

  int getEmotion(int t) {
    int t0 = days.get(0);
    int emo = emos.get(0);
    for (int n = 1; n <= days.size(); n++) {
      int t1 = n < days.size() ? days.get(n) : daysRunningTot + 1;    
      if (t0 <= t && t < t1) {
        emo = emos.get(n - 1);
        break;
      }   
      t0 = t1;
    }   
    return emo;
  }  

  void setEmotion(int emo) {
    prevEmo = currEmo;  
    currEmo = emo;
  }

  boolean checkedIn(int t0, int t1) {
    for (int n = 0; n < days.size(); n++) {
      int t = days.get(n);
      if (t0 <= t && t < t1) {
        return true;
      }
    }
    return false;
  }  

  boolean emotionChanged() {
    return prevEmo != currEmo;
  }  

  void addHistoryPoint(float x, float y, float c) {
    history.add(new PVector(x, y, c));
  }

  void update(int mode) {
    if (mode == MODE_BOOKSHELF) {
      updateBookshelfPos();
    } 
    else if (mode == MODE_WHEEL) {
      updateWheelPos();
    }
  }

  // TODO: the logic in this function should be simplified
  void drawInBookshelf(float first, float weight, float left, float top, float h, float maxlen) {
    float x = left + weight * (getBookshelfPos() - first);

    // Factor is used to interpolate between the fully emotional story bars and the compact 
    // representation (each emotional assigment has the same height). 
    float factor = bookHeightTimer.get();
    float elapsed = daysSinceStart.get();

    int nmax = 0;
    while (nmax < days.size () - 1) {
      if (days.get(nmax + 1) <= elapsed) {
        nmax++;
      } 
      else {
        break;
      }
    }
    nmax++;

    for (int n = 0; n < nmax; n++) {
      float y0, y1;
      float len0, len1, len = 0;      
      if (compactTime && n + 1 == nmax) {
        // We are in compact mode, drawing the last emotional assignment, which will be
        // represented in the book rect at the top, so we don't need to add it to the full 
        // history below.
        y0 = y1 = top;
      } 
      else {        
        len0 = constrain(map(days.get(n), 0, elapsed, maxlen, 0), 0, maxlen);
        len1 = (nmax - n - 1) * maxBookHeight;       
        len = (1 - factor) * len0 + factor * len1;
        y0 = top + len;         
        if (n + 1 < nmax) {
          len0 = constrain(map(days.get(n + 1), 0, elapsed, maxlen, 0), 0, maxlen); 
          len1 = (nmax - n) * maxBookHeight;
        } 
        else {
          len0 = 0;
          len1 = (nmax - n) * maxBookHeight;
        }      
        len = (1 - factor) * len0 + factor * len1;      
        y1 = top + len;  

        if (compactTime) {
          y0 -= maxBookHeight;
          y1 -= maxBookHeight;
        }
      }

      int e = 0;
      boolean last = false;      
      if (elapsed < days.get(n)) {
        e = emos.get(n - 1);
        last = true;
      } 
      else {
        e = emos.get(n);
        last = n == nmax - 1;
      }

      //int e = emos.get(n);
      Emotion emo0 = emotionsByID.get(e);         
      noStroke();
      fill(replaceAlpha(emo0.argb, viewFadeinAlpha.getInt()));

      // Top rect identifying the book.
      float bh = bookTopHeight.get();      
      if (last && 0 < bh) {        
        rect(x + bookPadding * weight, top - h - bh, max(1, (1 - 2 * bookPadding) * weight), bh);
      }

      // We draw the current emotional assignment only if the emotion is not "empty".
      if (e != 0) {        
        float x0 = x + bookPadding * weight;
        float x1 = x0 + max(1, (1 - 2 * bookPadding) * weight); // max() function to make things work in JS         
        rect(x0, y0, x1 - x0, y1 - y0);
        float w = bookStrokeWeight.get();
        if (0.5 <= abs(w)) {        
          stroke(replaceAlpha(bookshelfLinesColor, viewFadeinAlpha.getInt()));
          strokeWeight(w);
          line(x0, y1, x1, y1);
        }
      }  
      if (elapsed < days.get(n)) {
        break;
      }
    }
  }

  void drawInWheel(float xc, float yc, float rad, float h, float a) {    
    float a1 = wheelAngle.get();
    float x1 = xc + (rad * wheelRadius + h) * cos(a1);
    float y1 = yc + (rad * wheelRadius + h) * sin(a1);

    if (traveling) {
      wheelTrail.draw();
      wheelTrail.add(x1, y1);

      rectMode(CENTER);
      noStroke();
      Emotion emo = emotionsByID.get(prevEmo);
      fill(replaceAlpha(emo.argb, viewFadeinAlpha.getInt()));
      if (dist(x1, y1, xc, yc) < rad) {      
        // The book is still no under the circle border, so we
        // draw the rect.
        rect(x1, y1, 5, 5);
      }
      rectMode(CORNER);
    } 
    else {
      if (arrived) {
        wheelTrail.draw();
        wheelTrail.add(x1, y1);
        //         wheelHeight.setTarget(maxBookHeight);
        wheelHeight.setTarget(500);
        arrived = false;
      }
      float wh = wheelHeight.get();
      float xh = xc + (rad * wheelRadius + h + wh) * cos(a1);
      float yh = yc + (rad * wheelRadius + h + wh) * sin(a1);

      // stroke(replaceAlpha(historyTrailsColor, viewFadeinAlpha.getInt()));
      Emotion emo = emotionsByID.get(prevEmo);
      //   Emotion emo = emotionsByID.get(currEmo);
      stroke(replaceAlpha(emo.argb, viewFadeinAlpha.getInt()));
      // strokeWeight(1);  
      strokeWeight(0.5);      
      line(x1, y1, xh, yh);
    }
  }      

  // TODO: the logic in this function should be simplified, same as drawInBookshelf
  int insideBookshelf(float x, float y, float first, float weight, float left, float top, float h, float maxlen) {
    float x0 = left + weight * (getBookshelfPos() - first);    
    if (x0 < x && x <= x0 + weight) {
      float factor = bookHeightTimer.get();
      float elapsed = daysSinceStart.get();

      int nmax = 0;
      while (nmax < days.size () - 1) {
        if (days.get(nmax + 1) <= elapsed) {
          nmax++;
        } 
        else {
          break;
        }
      }
      nmax++;      

      for (int n = 0; n < nmax; n++) {
        float y0, y1;
        float len0, len1, len = 0;      
        if (compactTime && n + 1 == nmax) {
          // We are in compact mode, drawing the last emotional assignment, which will be
          // represented in the book rect at the top, so we don't need to add it to the full 
          // history below.
          y0 = y1 = top;
        } 
        else {        
          len0 = constrain(map(days.get(n), 0, elapsed, maxlen, 0), 0, maxlen);
          len1 = (nmax - n - 1) * maxBookHeight;       
          len = (1 - factor) * len0 + factor * len1;
          y0 = top + len;         
          if (n + 1 < nmax) {
            len0 = constrain(map(days.get(n + 1), 0, elapsed, maxlen, 0), 0, maxlen); 
            len1 = (nmax - n) * maxBookHeight;
          } 
          else {
            len0 = 0;
            len1 = (nmax - n) * maxBookHeight;
          }      
          len = (1 - factor) * len0 + factor * len1;      
          y1 = top + len;  

          if (compactTime) {
            y0 -= maxBookHeight;
            y1 -= maxBookHeight;
          }
        }

        int e = 0;
        boolean last = false;
        if (elapsed < days.get(n)) {
          e = emos.get(n - 1);
          last = true;
        } 
        else {
          e = emos.get(n);
          last = n == nmax - 1;
        }

        //int e = emos.get(n);        
        if (((y1 <= y && y <= y0) || (y0 <= y && y <= y1)) && (e != 0)) {   
          return e;
        }

        float bh = bookTopHeight.get();
        if (n == nmax - 1 && 0 < bh) {
          y0 = top - h - bh;
          y1 = top - h;
          if ((y1 <= y && y <= y0) || (y0 <= y && y <= y1)) {   
            return e;
          }
        }

        if (elapsed < days.get(n)) {
          return -1;
        }
      }   
      return -1;
    } 
    else {
      return -1;
    }
  }

  float getBookCenterX(float first, float weight, float left) {
    return left + weight * (getBookshelfPos() - first) + weight/2;
  }

  void updateBookshelfPos() {
    bookshelfPos.update();
  }

  void setBookshelfPos(float pos) {
    bookshelfPos.setTarget(pos);
  }

  float getBookshelfPos() {
    return bookshelfPos.get();
  }

  void updateWheelPos() {    
    wheelAngle.update(); 
    if (traveling) {           
      if (wheelAngle.targeting && emotionChanged()) {
        float t = constrain(map(wheelAngle.value, wheelAngle.source, wheelAngle.target, -1, +1), -1, +1);
        float range = abs(wheelAngle.target - wheelAngle.source) / TWO_PI;
        wheelRadius = constrain((1 - range) + range * t * t, 0, 1);
      } 
      else {
        wheelRadius = 1;
        traveling = false;
        arrived = true;
      }
    } 
    else {
      wheelHeight.update();
    }
  }

  void initWheelPos(float pos) {
    float a = bookAngle(int(pos));    
    wheelAngle.set(a);
    wheelHeight.setTarget(maxBookHeight);
    wheelRadius = 1;
  }

  void setWheelPos(float pos) {
    float a = bookAngle(int(pos));
    if (prevEmo == 0) {
      // When the book appears in the wheel, it 
      // does at its current position, without trail
      // animation.
      wheelAngle.set(a);
    } 
    else {
      wheelAngle.setTarget(a);
    }
    if (emotionChanged()) {
      wheelHeight.set(0);
    }
    traveling = true;
    arrived = false;
  }

  float getWheelPos() {
    return wheelAngle.get();
  }
}

// A selection comprises a book and the emotion associated to the book
// at the point of selection (not necessarily the latest emotional assignment).
class SelectedBook {
  Book book;
  Emotion emo;
  float x, y;  

  SelectedBook(Book book, Emotion emo, float x, float y) {
    this.book = book;
    this.emo = emo;    
    this.x = x;
    this.y = y;
  }
}

class SelectedLanguage {
  Language lang;
  float x, y;

  SelectedLanguage(Language lang, float x, float y) {
    this.lang = lang;
    this.x = x;
    this.y = y;
  }
}

class SelectedEmotion {
  Emotion emo;
  float x, y;

  SelectedEmotion(Emotion emo, float x, float y) {
    this.emo = emo;
    this.x = x;
    this.y = y;
  }
}

// Class storing the properties of an emotion
class Emotion {
  int id;
  String name;
  color argb;

  ArrayList<Book> booksInEmo;
  HashMap<Integer, ArrayList<Book>> booksPerLang;

  ArrayList<PVector> border;

  Emotion(int id, String name, color argb) {
    this.id = id;
    this.name = name;
    this.argb = argb;

    booksInEmo = new ArrayList<Book>();
    booksPerLang = new HashMap();
    border = new ArrayList<PVector>();
  }  

  void clearBooks() {
    booksInEmo.clear();   
    for (int lang: booksPerLang.keySet()) {
      booksPerLang.get(lang).clear();
    }
  }

  void addBook(Book book) {
    booksInEmo.add(book);

    ArrayList<Book> blang = booksPerLang.get(book.lang);
    if (blang == null) {
      blang = new ArrayList<Book>();       
      booksPerLang.put(book.lang, blang);
    } 
    blang.add(book);
  }

  void addBorderPoint(float x, float y) {
    border.add(new PVector(x, y, 0));
  }
}

// Class storing the properties of a language
class Language {
  int id;
  String code;
  String name;
  color argb;
  String url;

  ArrayList<Book> booksInLang;
  HashMap<Integer, ArrayList<Book>> booksPerEmo;

  Language(int id, String code, String name, color argb) {
    this.id = id;
    this.code = code;
    this.name = name;
    this.argb = argb;    

    booksInLang = new ArrayList<Book>();
    booksPerEmo = new HashMap();

    url = "";
  }

  void updateBooksPerEmo(int t) {
    for (int emo: booksPerEmo.keySet()) {
      booksPerEmo.get(emo).clear();
    }

    for (Book book: booksInLang) {
      int emo = book.getEmotion(t);
      ArrayList<Book> bemo = booksPerEmo.get(emo);
      if (bemo == null) {
        bemo = new ArrayList<Book>();       
        booksPerEmo.put(emo, bemo);
      } 
      bemo.add(book);
      book.setEmotion(emo);
      book.clearTrail();
      if (book.prevEmo == 0) {
        book.wheelAngle.set(random(0, TWO_PI));
      }
    }
  } 

  void addBook(Book book) {
    booksInLang.add(book);
  }
}

class ViewRegion {
  SoftFloat firstBook;
  SoftFloat lastBook;
  int zoomLevel;

  ViewRegion() {
    firstBook = new SoftFloat();
    lastBook = new SoftFloat();
  }  

  void update() {
    firstBook.update();
    lastBook.update();
  }

  void setTarget(float first, float last) {
    setTarget(first, last, int(last));
  }

  void setTarget(float first, float last, int bookCount) {
    // Making sure that the interval remains inside the bounds.
    if (first < 0) {
      last -= first;
      first = 0;
    }
     
    if (bookCount - 1 < last) {
      float diff = last - bookCount + 1;
      first -= diff;
      last  -= diff;
    }
     
    // additional constraining (should make sense only if 
    // diff between first and last is greater than the total
    // number of books).
    first = constrain(first, 0, bookCount - 1);
    last = constrain(last, first, bookCount - 1); 
     
    firstBook.setTarget(first);
    lastBook.setTarget(last);
  }

  float getFirstBook() {
    return firstBook.get();
  }

  float getLastBook() {
    return lastBook.get();
  }  

  float getBookCount() {
    return lastBook.get() - firstBook.get() + 1;
  }

  boolean isTargeting() {
    return firstBook.targeting || lastBook.targeting;
  }

  boolean intersects(int i0, int i1) {
    float first = firstBook.get();
    float last = lastBook.get();
    if (i1 < first || last < i0) {
      return false;
    } 
    else {
      return true;
    }
  }
}

class Trail {
  float[] x;
  float[] y;
  int len;  

  Trail(int n) {
    x = new float[n];
    y = new float[n];  
    len = 0;
  }

  void clear() {      
    len = 0;
  }

  void init(float x0, float y0) {
    for (int i = 0; i < x.length; i++) {
      x[i] = x0;
      y[i] = y0;
    }
  }  

  void add(float newx, float newy) {
    if (len == 0) {
      init(newx, newy);
    } 
    else {
      if (abs(newx - x[0]) < 0.001 && abs(newy - y[0]) < 0.001) return;
    }    

    for (int i = len - 1; 0 < i; i--) {
      x[i] = x[i - 1];
      y[i] = y[i - 1];
    }
    x[0] = newx;
    y[0] = newy;

    if (len < x.length) {
      len++;
    }
  }

  void draw() {
    strokeWeight(0.5);
    float r = red(historyTrailsColor);
    float g = green(historyTrailsColor);
    float b = blue(historyTrailsColor);
    for (int i = 1; i < len; i++) {      
      float opacity = map(i, 0, x.length - 1, 255, 0);
      stroke(r, g, b, opacity);
      line(x[i - 1], y[i - 1], x[i], y[i]);
    }
  }
}

