// Garden Library project
// Romy Achituv, Andres Colubri
// 
// GardenLibraryViz app, version 8 (October 28th, 2012).
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
//
// Issues:
// * Some optimization of the book grouping algorithm?
// * Remove ART, children and reference books from display because they don't participate of the emotional judgement system.
// * Make the app use the entire browser canvas:
//   https://forum.processing.org/topic/fullscreen-app-using-processing-js-and-canvas

void setup() {
  size(1154, 692);
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
// Run status:
int LOADING        = 0;
int LOAD_EMOTIONS  = 1;
int LOAD_LANGUAGES = 2;
int LOAD_BOOKS     = 3;
int GROUP_BY_LANG  = 4;
int BUILD_HISTORY  = 5;
int GROUP_BY_EMO   = 6;
int FINISH_INIT    = 7;
int RUNNING        = 8;

// Constants for view mode
int MODE_BOOKSHELF = 0;
int MODE_WHEEL     = 1;
int MODE_HISTORY   = 2;

// Constants for zoom level
int VIEW_ALL  = 0;
int VIEW_LANG = 1;
int VIEW_EMO  = 1;
int VIEW_BOOK = 2;
// Data loading methods

void loadEmotions() {
  emotions = new ArrayList<Emotion>();
  emotions1 = new ArrayList<Emotion>();
  emotionsByID = new HashMap<Integer, Emotion>();
  
  String[] data = loadStrings(emoFilename); 
  
  for (String row: data) {
    String[] parts = split(row, '\t');    
    int eid = parseInt(parts[0]);
    String ename = parts[1];
    int ecolor = unhex("ff" + parts[2]);
    Emotion emo = new Emotion(eid, ename, ecolor);
    emotionsByID.put(eid, emo);
    emotions.add(emo);
    if (eid != 0) {
      emotions1.add(emo);
    }        
  } 
  // Add empty emotion
  Emotion emo = new Emotion(0, "None", 0xffffffff);
  emotionsByID.put(0, emo);
  emotions.add(emo);  
}

void loadLanguages() {
  languages = new ArrayList<Language>();
  languagesByID = new HashMap<Integer, Language>();
  languagesByCode = new HashMap<String, Language>();  
  
  String[] data = loadStrings(langFilename); 

  for (String row: data) {
    String[] parts = split(row, '\t');
    
    int lid = parseInt(parts[0]);
    String lcode = parts[1];
    String lname = parts[2];
    int lcolor = unhex("ff" + parts[3]);
    
    Language lang = new Language(lid, lcode, lname, lcolor);
    languagesByID.put(lid, lang);    
    languagesByCode.put(lcode, lang);    
    languages.add(lang);
  }  
}

void loadBooks() {
  books = new ArrayList<Book>();
  booksByID = new HashMap<Integer, Book>();
  
  String[] booksData = loadStrings(booksFilename); 
  
  String[] histoData = loadStrings(histoFilename);
  
  for (String row: booksData) {
    String[] parts = split(row, '\t');
    
    int item = parseInt(parts[0]);
    int biblio = item;
    String barcode = parts[1];
    String author = parts[2];
    String title = parts[3];
    if (title.equals("NULL") || -1 < title.indexOf("????")) continue;
    if (author.equals("NULL") || -1 < author.indexOf("????")) {
      author = "Not recorded";  
    }
    
    int lid = parseInt(parts[4]);
    Language lang = languagesByID.get(lid);
    String ISBN = parts[5];
    if (lang == null) continue;
    Book book = new Book(item, biblio, barcode, title, author, lang.id, ISBN);   
    
    loadHistory(book, histoData);      
    booksByID.put(item, book);
    books.add(book);
  }
}

void loadHistory(Book book, String[] histoData) {
  for (String row: histoData) {
    String[] parts = split(row, '\t');
    if (parts[0].equals("NULL")) continue; 
    
    int item = parseInt(parts[0]);    
    if (item == book.item) {
      String[] timestamp = split(parts[1], ' ');      
      String retStr = timestamp[0];
      int emo = parseInt(parts[2]);
      
      Date retDate = null;
      if (!retStr.equals("NULL")) {
        retDate = new Date(retStr);
      } 
            
      if (retDate != null) {
        int days = daysBetween(startDate, retDate);
        book.addEmotion(days, emo);
      }  
    } 
  }  
}

void loadWebLinks() {
  String[] data = loadStrings(linksFilename); 
  
  String defURL = "";
  
  for (String row: data) {
    String[] parts = split(row, '\t');
    if (parts[0].equals("DEFAULT")) {
      defURL = parts[1];
    } else {
      Language lang = languagesByCode.get(parts[0]);
      if (lang != null) {
        lang.url = parts[1];  
      }
    }    
  }  
  
  // Setting default URL for languages with empty URL.
  for (Language lang: languages) {
    if (lang.url.equals("")) {
      lang.url = defURL;
    }  
  }
}
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
    } else if (mode == MODE_WHEEL) {
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
    
    for (int n = 0; n < days.size(); n++) {
      float y0, y1;
      float len0, len1, len = 0;      
      if (compactTime && n + 1 == days.size()) {
        // We are in compact mode, drawing the last emotional assignment, which will be
        // represented in the book rect at the top, so we don't need to add it to the full 
        // history below.
        y0 = y1 = top;
      } else {        
        len0 = constrain(map(days.get(n), 0, elapsed, maxlen, 0), 0, maxlen);
        len1 = (days.size() - n - 1) * maxBookHeight;       
        len = (1 - factor) * len0 + factor * len1;
        y0 = top + len;         
        if (n + 1 < days.size()) {
          len0 = constrain(map(days.get(n + 1), 0, elapsed, maxlen, 0), 0, maxlen); 
          len1 = (days.size() - n) * maxBookHeight;       
        } else {
          len0 = 0;
          len1 = (days.size() - n) * maxBookHeight;
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
      } else {
        e = emos.get(n);
        last = n == days.size() - 1;
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
    } else {
      if (arrived) {
        wheelTrail.draw();
        wheelTrail.add(x1, y1);
        wheelHeight.setTarget(maxBookHeight);
        arrived = false;
      }
      float wh = wheelHeight.get();
      float xh = xc + (rad * wheelRadius + h + wh) * cos(a1);
      float yh = yc + (rad * wheelRadius + h + wh) * sin(a1);

      stroke(replaceAlpha(historyTrailsColor, viewFadeinAlpha.getInt()));
      strokeWeight(1);      
      line(x1, y1, xh, yh);     
    }    
  }      
  
  // TODO: the logic in this function should be simplified, same as drawInBookshelf
  int insideBookshelf(float x, float y, float first, float weight, float left, float top, float h, float maxlen) {
    float x0 = left + weight * (getBookshelfPos() - first);    
    if (x0 < x && x <= x0 + weight) {
      float factor = bookHeightTimer.get();
      float elapsed = daysSinceStart.get();
      
      for (int n = 0; n < days.size(); n++) {
        float y0, y1;
        float len0, len1, len = 0;      
        if (compactTime && n + 1 == days.size()) {
          // We are in compact mode, drawing the last emotional assignment, which will be
          // represented in the book rect at the top, so we don't need to add it to the full 
          // history below.
          y0 = y1 = top;
        } else {        
          len0 = constrain(map(days.get(n), 0, elapsed, maxlen, 0), 0, maxlen);
          len1 = (days.size() - n - 1) * maxBookHeight;       
          len = (1 - factor) * len0 + factor * len1;
          y0 = top + len;         
          if (n + 1 < days.size()) {
            len0 = constrain(map(days.get(n + 1), 0, elapsed, maxlen, 0), 0, maxlen); 
            len1 = (days.size() - n) * maxBookHeight;       
          } else {
            len0 = 0;
            len1 = (days.size() - n) * maxBookHeight;
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
        } else {
          e = emos.get(n);
          last = n == days.size() - 1;
        }
              
        //int e = emos.get(n);        
        if (((y1 <= y && y <= y0) || (y0 <= y && y <= y1)) && (e != 0)) {   
          return e;    
        }
        
        float bh = bookTopHeight.get();
        if (n == days.size() - 1 && 0 < bh) {
          y0 = top - h - bh;
          y1 = top - h;
          if ((y1 <= y && y <= y0) || (y0 <= y && y <= y1)) {   
            return e;
          } 
        }
      
        if (elapsed < days.get(n)) {
          return e;
        }
      }   
      return -1;      
    } else {
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
      } else {
        wheelRadius = 1;
        traveling = false;
        arrived = true;
      }  
    } else {
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
    } else {
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
  ArrayList<Book> allBooks;

  ViewRegion(ArrayList<Book> allBooks) {
    firstBook = new SoftFloat();
    lastBook = new SoftFloat();
    this.allBooks = allBooks;
  }  
  
  void update() {
    firstBook.update();
    lastBook.update(); 
  }
  
  void setTarget(float first, float last) {
    // Making sure that the interval remains inside the bounds.
    if (first < 0) {
      last -= first;
      first = 0;      
    }
    if (allBooks.size() - 1 < last) {
      float diff = last - allBooks.size() + 1;
      first -= diff;
      last  -= diff;
    }
    
    // additional constraining (should make sense only if 
    // diff between first and last is greater than the total
    // number of books).
    first = constrain(first, 0, allBooks.size() - 1);
    last = constrain(last, firstBook.get(), allBooks.size() - 1);
    
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
    } else {
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
    } else {
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
// Basic date type with functionality to move month by month, etc. 
// Adapted from:
// http://www.roseindia.net/tutorial/java/core/implementDateclass.html
class Date {
  int[] DAYS = { 0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }; // 0 because months are counted from 1.
  int[] DOW  = {     0,  3,  2,  5,  0,  3,  5,  1,  4,  6,  2,  4 };
  String[] MONTH_SHORT_NAMES = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" };
  String[] MONTH_FULL_NAMES =  { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" }; 
  
  int year;
  int month;
  int day;
  int hours;
  int minutes;
  float seconds;
  
  Date() {
    year = 0;    
    month = 0;
    day = 0;    
    hours = 0;
    minutes = 0;
    seconds = 0;        
  }  
  
  // Parses a string of the form
  // 2011-06-08 14:53:34.0
  // The second part (hour:minute:second) could be missing,
  // in which case the corresponding part of the date is set 
  // to zeroes.
  Date(String str) {   
    String strtr = str.trim();
    String[] dateTime = str.split(" ");   
    if (0 < dateTime.length) {
      String dateStr = dateTime[0];      
      String[] date = dateStr.split("-");
      if (date.length != 3) {
        throw new RuntimeException("Invalid date string");
      }
      int y = parseInt(date[0]);
      int m = parseInt(date[1]);
      int d = parseInt(date[2]);    
      
      int hr = 0;
      int min = 0;
      float sec = 0;
      
      if (1 < dateTime.length) {
        String timeStr = dateTime[1];
        String[] time = timeStr.split(":");
        if (time.length != 3) {
          throw new RuntimeException("Invalid date string");
        }
        hr = parseInt(time[0]);
        min = parseInt(time[1]);
        sec = parseFloat(time[2]);   
      }
      
      if (!isValid(y, m, d, hr, min, sec)) {
        throw new RuntimeException("Invalid date");
      }
      year = y;    
      month = m;
      day = d;    
      hours = hr;
      minutes = min;
      seconds = sec;        
      
    } else {
      throw new RuntimeException("Invalid date string");
    }
  }

  Date(int y, int m, int d) {
    this(y, m, d, 0, 0, 0);
  }
  
  Date(int y, int m, int d, int hr, int min, float sec) {
    if (!isValid(d, m, y, hr, min, sec)) {
      //throw new RuntimeException("Invalid date");
    }
    year = y;    
    month = m;
    day = d;    
    hours = hr;
    minutes = min;
    seconds = sec;    
  }
  
  void copy(Date src) {
    year = src.year;    
    month = src.month;
    day = src.day;    
    hours = src.hours;
    minutes = src.minutes;
    seconds = src.seconds;        
  }  
  
  int getYear() {
    return year;
  } 
  
  // Number of month (1-12)
  int getMonth() {
    return month;
  } 

  // Day of the month (1-31)
  int getDay() {
    return day;
  }
  
  // Day of the week (0 - 6). 0 = Sunday, ... , 6 = Saturday
  int getDate() {    
    return getDOW();
  }

  // Day of the week (0 - 6). 0 = Sunday, ... , 6 = Saturday
  int getDOW() {
    // Algorithm devised by Tomohiko Sakamoto in 1993, it is accurate for any Gregorian date:
    // http://en.wikipedia.org/wiki/Determination_of_the_day_of_the_week#Implementation-dependent_methods_of_Sakamoto.2C_Lachman.2C_Keith_and_Craver
    int m = month;     
    int yr = m < 3 ? year - 1: year;
    return (yr + yr/4 - yr/100 + yr/400 + DOW[m - 1] + yr) % 7;
  }

  // Number of hours (0 - 23)
  int getHours() {
    return hours;
  }
  
  // Number of minutes (0 - 59)
  int getMinutes() {
    return minutes;
  }

  // Number of seconds (0 - 59)
  float getSeconds() {
    return seconds;
  }  
    
  // Number of milliseconds since 1/1/1970 @ 12:00 AM
  long getTime() {
    return getMillis();    
  } 
  
  // Number of milliseconds since 1/1/1970 @ 12:00 AM
  // TODO: write implementation so it works on JS as well
  long getMillis() {
    return 0;
  }

  public void addYear() {
    year++;
  }  

  public void addMonth() {
    if (month < 12) {
      month++;
      day = min(day, DAYS[month]);
    } else {      
      day = min(day, DAYS[1]);
      month = 1;
      year++;    
    }    
  }

  public void addDay() {
    if (isValid(year, month, day + 1)) {
      day++;
    } else if (isValid(year, month + 1, 1)) {
      day = 1;
      month++;      
    } else {
      day = 1;
      month = 1;
      year++;
    }
  }
  
  void addHour() {
    if (hours < 23) {
      hours++;  
    } else {
      hours = 0;
      addDay();  
    }
  }

  void addMinute() {
    if (minutes < 59) {
      minutes++;        
    } else {
      minutes = 0;
      addHour();
    }
  }

  void addSecond() {
    if (seconds < 59) {
      seconds++;
    } else {
      seconds = 0;
      addMinute();
    }
  }

  boolean isAfter(Date b) {
    return compareTo(b) > 0;
  }

  boolean isBefore(Date b) {
    return compareTo(b) < 0;
  }

  float compareTo(Date b) {
    if (year != b.year) {
      return year - b.year;
    } else if (month != b.month) {
      return month - b.month;
    } else if (day != b.day) { 
      return day - b.day;
    } else if (hours != b.hours) {
      return hours - b.hours;
    } else if (minutes != b.minutes) {
      return minutes - b.minutes;
    } else if (0.001 <= abs(seconds - b.seconds)) {
      return seconds - b.seconds;
    } else {
      return 0;
    }  
  }

  String toString() {
    return year + "-" + month + "-" + day + " " + hours + ":" + minutes + ":" + seconds;
  }

  String toYYYYMMString() {
    return year + "-" + month;
  }

  String toYYYYMMDDString() {
    return year + "-" + month + "-" + day;
  }

  String toMMDDString() {
    return month + "-" + day;
  }
  
  String toNiceString() {
    return MONTH_SHORT_NAMES[month - 1] + " " + day + ", " + year;
  }
  
  boolean isValid(int y, int m, int d) {
    return isValid(y, m, d, hours, minutes, seconds);
  }  
  
  boolean isValid(int y, int m, int d, int hr, int min, float sec) {
    if (m < 1 || m > 12) {
      return false;
    } else if (d < 1 || d > DAYS[m]) {
      return false;
    } if (m == 2 && d == 29 && !isLeapYear(y)) {
      return false;
    } else { 
      return 0 <= hr && hr < 24 && 0 <= min && min < 60 && 0 <= sec && sec < 60;
    }
  }

  boolean isLeapYear(int y) {
    if (y % 400 == 0) {
      return true;
    } else if (y % 100 == 0) {
      return false;
    } else {
      return (y % 4 == 0);
    }
  }  
} 

// The writing functions that take care of the bookshelf, wheel and history views.

void drawBookshelf(Rectangle bounds, float yTop) {
  float firstBook = viewRegion.getFirstBook();  
  float bookCount = viewRegion.getBookCount(); 
    
  float elapsed = daysSinceStart.get();  
    
  float h = langBarH.get();
  float totLen = map(elapsed, 0, daysRunningTot, 0, bounds.y + bounds.h - yTop);
  
  int count = 0;
  
  float w = bounds.w / bookCount;
  if (1 < w) bookStrokeWeight.enable();
  else bookStrokeWeight.disable(); // to stop the stroke appearing when the book rects are still too thin.

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
            book.drawInBookshelf(firstBook, w, bounds.x, yTop, h, totLen);            
          }
        }        
      }
      
      count += bemo.size();
    }

    // Draw language rectangle    
    float x0 = bookX(langCount, bounds.x, bounds.w);
    langCount += lang.booksInLang.size();        
    float x1 = bookX(langCount, bounds.x, bounds.w);    
    if (intervalIntersect(x0, x1, bounds.x, bounds.x + bounds.w)) {
      // Adding paddings between languages:
      if (bounds.x < x0) { // left padding
        x0 += bookPadding * w/2; 
      } else {
         x0 = bounds.x;
      }  
      if (x1 < bounds.x + bounds.w) { // right padding
        x1 -= bookPadding * w/2;      
      } else {
         x1 = bounds.x + bounds.w;
      }  
      noStroke();
      
      fill(replaceAlpha(lang.argb, viewFadeinAlpha.getInt()));          
      rect(x0, yTop - h, x1 - x0, h);    
    } 
  }  
}

boolean drawWheel(Rectangle bounds, float yTop) {
  boolean animatingTrails = false;
  float firstBook = 0;
  float bookCount = 0;
  for (Emotion emo: emotions) {
    if (emo.id == 0) continue;
    
    for (Language lang: languages) {
      ArrayList<Book> blang = emo.booksPerLang.get(lang.id);
      if (blang == null) continue;
      bookCount += blang.size();
    }
  }
    
  float elapsed = daysSinceStart.get();  
    
  float h = langBarH.get();
  
  float xc = bounds.x + bounds.w/2;
  float yc = bounds.y + yTop + bounds.h/2;
  
  int count = 0;
  
  float w = bounds.w / bookCount;

  pushMatrix();
  translate(xc, yc + wheelYPos.get());
  scale(wheelScale.get());
  rotate(wheelRAngle.get());

  // Draw books:
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
        book.drawInWheel(0, 0, wheelRadius, h, angPerBook);
        animatingTrails |= book.traveling;
      }
   
      count += blang.size();
    }
  }  
  
  // Draw emotion arcs:
  count = 0;
  for (int i = 0; i < emotions.size(); i++) {
    Emotion emo = emotions.get(i);
    if (emo.id == 0) continue;
      
    int i0 = count;
    int i1 = i0 + emo.booksInEmo.size();  
    float a0 = bookAngle(i0);    
    float a1 = bookAngle(i1);
    
    noStroke();    
    fill(replaceAlpha(emo.argb, viewFadeinAlpha.getInt()));    
    solidArc(0, 0, RAD_TO_DEG * a0, RAD_TO_DEG * a1, wheelRadius, h);

    count += emo.booksInEmo.size();    
  }  
  
  popMatrix();
  return animatingTrails;
}

void solidArc(float xc, float yc, float deg0, float deg1, float rad, float w) {  
  int a0 = int(min(deg0 / SINCOS_PRECISION, SINCOS_LENGTH));
  int a1 = int(min(deg1 / SINCOS_PRECISION, SINCOS_LENGTH));
  beginShape();
  for (int i = a0; i <= a1; i++) {
    vertex(cosLUT[i] * (rad)     + xc, sinLUT[i] * (rad)     + yc);
  }  
  for (int i = a1; i >= a0 ; i--) {
    vertex(cosLUT[i] * (rad + w) + xc, sinLUT[i] * (rad + w) + yc);
  }
  endShape(CLOSE);  
}

void drawHistory(Rectangle bounds, float yTop) {  
  int historyW = int(bounds.w + viewLeftMargin.get());
  int historyH = int(bounds.h - yTop - 20);  
  if (historyCanvas == null) {
    historyCanvas = createGraphics(historyW, historyH);
  
    historyCanvas.beginDraw();
    
    if (showSolidEmoHistory) {
      // Draw background for each emotion
      historyCanvas.noStroke();
      for (int i = 0; i < emotions1.size(); i++) {
        Emotion emo = emotions1.get(i);
    
        float minx = 1;
        historyCanvas.fill(red(emo.argb), green(emo.argb), blue(emo.argb), emoBandAlpha);
      
        historyCanvas.beginShape(POLYGON);
        if (i == 0) { // first
          for (int d7 = 0; d7 <= daysRunningTot + 7; d7 += 7) {
            int days = constrain(d7, 0, daysRunningTot);
            float x = map(days, 0, daysRunningTot, 0, 1);
            historyCanvas.vertex(x * historyW, squeezeY(x, 0) * historyH);
          }
          minx = 0;
        } else {
          for (PVector v: emo.border) {
            historyCanvas.vertex(historyW * v.x, historyH * squeezeY(v.x, v.y));
            minx = min(v.x, minx); 
          }    
        }
    
        if (i == emotions1.size() - 1) { // last
          for (int d7 = 0; d7 <= daysRunningTot + 7; d7 += 7) {
            int days = constrain(d7, 0, daysRunningTot);
            float x = map(days, 0, daysRunningTot, 1, 0);
            historyCanvas.vertex(x * historyW, squeezeY(x, 1) * historyH);
          }

        } else {      
     
          float minx1 = 1;
          Emotion emo1 = emotions1.get(i + 1);
          for (int j = emo1.border.size() - 1; j >= 0; j--) {
            PVector v = emo1.border.get(j);
            historyCanvas.vertex(historyW * v.x, historyH * squeezeY(v.x, v.y));
            minx1 = min(v.x, minx1);        
          }
       
          if (minx == 0 && 0 < minx1) {
            // shape won't close properly, need to find another point
            // in the next emos.
            for (int j = i + 2; j <= emotions1.size(); j++) {
              if (j < emotions1.size()) {
                emo1 = emotions1.get(j); 
                PVector v = emo1.border.get(0);
                historyCanvas.vertex(historyW * v.x, historyH * squeezeY(v.x, v.y));
                minx1 = min(v.x, minx1);
                if (minx1 == 0) break;     
              } else {
                historyCanvas.vertex(0, squeezeY(0, 1) * historyH);  
              }    
            }
          }      
        }
    
        historyCanvas.endShape(CLOSE);
      }
    }
        
    // Draw each book
    Book sbook = null;
    for (Book book: books) {
      PVector pt0 = null;
      for (PVector pt: book.history) {
        if (book == sbook) continue;
        if (pt0 != null && pt0.z == pt.z) {        
          historyCanvas.strokeWeight(1);
          historyCanvas.stroke(replaceAlpha(int(pt0.z), bookStrokeAlpha));
          historyCanvas.noFill();
          historyCanvas.line(historyW * pt0.x, historyH * squeezeY(pt0.x, pt0.y), 
                             historyW * pt.x,  historyH * squeezeY(pt.x, pt.y));             
        }
        pt0 = pt;      
      }
    }
  }
  
  historyCanvas.endDraw();
  tint(255, viewFadeinAlpha.getInt());
  image(historyCanvas, bounds.x, bounds.y + yTop, bounds.w, historyH);
}  

void drawBookHistory(SelectedBook sel, Rectangle bounds, float yTop) {  
  Book book = sel.book;
  
  int historyW = int(bounds.w);
  int historyH = int(bounds.h - yTop - 20);  
  float xc = bounds.x;
  float yc = bounds.y + yTop;
  PVector pt0 = null;
  for (PVector pt: book.history) {
    if (pt0 != null) {
      strokeWeight(2);
      stroke(replaceAlpha(selHistoryColor, viewFadeinAlpha.getInt()));
      noFill();
      float x0 = xc + historyW * pt0.x; 
      float y0 = yc + historyH * squeezeY(pt0.x, pt0.y);
      float x1 = xc + historyW * pt.x;
      float y1 = yc + historyH * squeezeY(pt.x, pt.y);
      
      line(x0, y0, x1, y1);
      
      int days0 = int(map(pt0.x, 0, 1, 0, daysRunningTot));
      int days1 = int(map(pt.x, 0, 1, 0, daysRunningTot));
      if (book.checkedIn(days0, days1)) {
        // The book was checked in between days0 and days1
        noStroke();
        fill(replaceAlpha(selHistoryColor, viewFadeinAlpha.getInt()));
        ellipse(x1, y1, 7, 7);        
      }
    } else {
      float x1 = xc + historyW * pt.x;
      float y1 = yc + historyH * squeezeY(pt.x, pt.y);
      noStroke();
      fill(replaceAlpha(selHistoryColor, viewFadeinAlpha.getInt()));
      ellipse(x1, y1, 7, 7);      
    }
    
    pt0 = pt;     
  }
}

void loadingAnimation() {
  background(0);
  String msg = "Loading data";
  float w = textWidth(msg);
  for (int i = 0; i < currentTask; i++) {
    msg += ".";    
  }  
  fill(255);
  text(msg, width/2 - w/2, height/2);
}

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
   
        pushMatrix();
        translate(x0 + w + fontSize/2 + 5, y0 - tailH.get() - mainH.get()/2);
        rotate(HALF_PI);
        textFont(langFont);
        float cw = textWidth(book.barcode);
        scale(codeScale.get());
        fill(langFontColor);
        text(book.barcode, -cw/2, fontSize/2);
        textFont(defFont);
        popMatrix();
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
   
        pushMatrix();
        translate(x0 - w + 10 - (fontSize + 10)/2, y0 - tailH.get() - mainH.get()/2);
        rotate(HALF_PI);
        textFont(langFont);        
        float cw = textWidth(book.barcode);
        scale(codeScale.get());
        fill(langFontColor);
        text(book.barcode, -cw/2, fontSize/2);
        textFont(defFont);
        popMatrix();
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

class LanguageTab extends InfoBox {
  Language lang;
  SoftFloat tabH;
  float tabW;
  boolean animating;

  LanguageTab() {
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

// The interface classes.

class Rectangle {
  float x, y, w, h;

  Rectangle(float x, float y, float w, float h) {
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
}  

class ViewArea extends InterfaceElement {
  float w0;
  float pressX0, pressY0;
  boolean animatingTrails;
  boolean draggingWheel;
  BookBubble bookBubble;
  LanguageTab langTab; 
  
  float langBarY; // Position of the language bar (with respect to the top of the bound rectangle)

  ViewArea(float x, float y, float w, float h) {
    super(x, y, w, h);
    w0 = w;
    bookBubble = new BookBubble();
    langTab = new LanguageTab();
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
      daysSinceStart.update();

      bookStrokeWeight.update();
      langBarH.update();
      bookTopHeight.update();

      wheelRAngle.update();
      wheelYPos.update();
      wheelScale.update();  
    } else {
      daysSinceStart.update();
    }
    
    bookBubble.update();
    
    viewFadeinAlpha.update();
    viewLeftMargin.update();
    
    float xoff = viewLeftMargin.get();
    bounds.x = xoff;
    bounds.w = w0 - xoff;
  }
  
  void draw() {
    if (currentMode == MODE_BOOKSHELF) {
      if (insideLangBar(mouseX, mouseY, bounds, langBarY)) {
        selLang = getSelectedLanguageInBookshelf(mouseX, mouseY, bounds, langBarY);        
      } else {
        selLang = null;
      }  
      langTab.open(selLang);
      langTab.draw(); 
      
      if (insideBookshelf(mouseX, mouseY, bounds, langBarY)) {
        selBook = getSelectedBookInBookshelf(mouseX, mouseY, bounds, langBarY);
      } else {
        selBook = null;
      }      
      bookBubble.open(selBook);
      bookBubble.draw();

      if (!mouseActivity && selBook == null && selLang == null && viewRegion.zoomLevel != VIEW_ALL) {
        hintInfo.open("click anywhere above the language bar to zoom out");
      }

      drawBookshelf(bounds, langBarY);
    } else if (currentMode == MODE_WHEEL) {
      if (viewRegion.zoomLevel == VIEW_BOOK) {
        selBook = getSelectedBookInWheel(bounds, selBook, wheelTop);
      }
      bookBubble.open(selBook);
      bookBubble.draw();      
      
      if (!mouseActivity && viewRegion.zoomLevel != VIEW_ALL) {
        hintInfo.open("click anywhere outside the language circle to zoom out");
      }
      
      animatingTrails = drawWheel(bounds, wheelTop);
    } else if (currentMode == MODE_HISTORY) {      
      drawHistory(bounds, historyTop);
      
      if (abs(pmouseX - mouseX) > 0 || abs(pmouseY - mouseY) > 0) {        
        if (contains(mouseX, mouseY)) {
          selBook = selectBookInHistory(mouseX, mouseY, bounds, historyTop);
        }
        bookBubble.open(selBook);
      }
      
      if (selBook != null) {
        drawBookHistory(selBook, bounds, historyTop);
      }
      
      float xc = map(daysSinceStart.get(), 0, daysRunningTot, bounds.x, bounds.x + bounds.w);
      strokeWeight(1);
      stroke(historyLineColor);
      line(xc, 0, xc, bounds.y + bounds.h + 10);
      fill(255);
      ellipse(xc, bounds.y + bounds.h + 5, 10, 10);
      
      bookBubble.draw(); 
    }
  }

  boolean mousePressed() {
    if (!contains(mouseX, mouseY)) return false;

    selected = true;

    if (currentMode == MODE_BOOKSHELF) { 
      setViewRegionBookshelf(mouseX, mouseY, bounds, langBarY);
    } else if (currentMode == MODE_WHEEL) {      
      pressX0 = mouseX;
      pressY0 = mouseY;
      draggingWheel = false;
    }
    return true;
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
}

class ViewMenu extends InterfaceElement {
  float w3, bw, ww, hw, h2;

  ViewMenu(float x, float y, float w, float h) {
    super(x, y, w, h);  
    w3 = w/3;
    h2 = h/2;
    bw = textWidth("bookshelf");
    ww = textWidth("wheel");
    hw = textWidth("history");
  }

  void draw() {
    noStroke();
    fill(replaceAlpha(backgroundColor, 180));
    rect(bounds.x, bounds.y, bounds.w, bounds.h);
    
    stroke(menuStrokeColor);
    strokeWeight(1);
    
    float xl = bounds.x;
    
    float xc = xl + w3/2 - bw/2;
    float yc = bounds.y + h2 + fontSize/2;
    if (currentMode == MODE_BOOKSHELF) {
      fill(selOptionColor);
    } else { 
      fill(defTextColor);
    }     
    text("bookshelf", xc, yc);
    
    xl += w3;
    line(xl, bounds.y + h2 - fontSize/2, xl, bounds.y + h2 + fontSize/2);
    
    xc = xl + w3/2 - ww/2;
    if (currentMode == MODE_WHEEL) {
      fill(selOptionColor);
    } else { 
      fill(defTextColor);
    }      
    text("wheel", xc, yc);
    
    xl += w3;
    line(xl, bounds.y + h2 - fontSize/2, xl, bounds.y + h2 + fontSize/2);

    xc = xl + w3/2 - hw/2;
    if (currentMode == MODE_HISTORY) {
      fill(selOptionColor);
    } else { 
      fill(defTextColor);
    }     
    text("history", xc, yc);
  }

  boolean mousePressed() {
    if (!contains(mouseX, mouseY)) return false;

    selected = true;

    if (contains(mouseX, mouseY)) {
      int p = int((mouseX - bounds.x) / w3);
      if (p == 0) {
        setCurrenMode(MODE_BOOKSHELF);
      } else if (p == 1) {
        setCurrenMode(MODE_WHEEL);
      } else {
        setCurrenMode(MODE_HISTORY);
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
      } else if (mode == MODE_WHEEL) {
        groupBooksByEmotion(days, true);
        setViewRegionAllWheel();
      } else if (mode == MODE_HISTORY) {
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
      } else {
        text("play animation", xm, bounds.y + h2 + fontSize/2);
      }
    } else if (currentMode == MODE_BOOKSHELF && viewRegion.zoomLevel == VIEW_BOOK) {
      if (compactTime) {
        text("expand time", xm, bounds.y + h2 + fontSize/2);
      } else {
        text("compact time", xm, bounds.y + h2 + fontSize/2);
      }
    }   
    
    float x0 = bounds.x;
    float x1 = bounds.x + bounds.w - margin;
    stroke(timelineColor);
    strokeWeight(1);
    line(x0, bounds.y + h2, x1, bounds.y + h2);
    float elapsed = daysRunningTot;
    Date currDate = dateAfter(startDate, int(elapsed));
    Date date = new Date();
    date.copy(startDate);
    while (date.isBefore(endDate)) {
      int days = daysBetween(startDate, date);
      float xt = map(days, 0, daysRunningTot, x0, x1);
      line(xt, bounds.y + h2 - 5, xt, bounds.y + h2 + 5); 
      date.addMonth();
    }
    line(x1, bounds.y + h2 - 5, x1, bounds.y + h2 + 5); // last tickmark. 

    float xc = map(daysSinceStart.get(), 0, daysRunningTot, x0, x1);
    fill(255);      
    triangle(xc - 5, bounds.y + h2 - 10, xc + 5, bounds.y + h2 - 10, xc, bounds.y + h2);
    fill(defTextColor);
    Date selDate = dateAfter(startDate, int(daysSinceStart.get()));
    String dstr = selDate.toNiceString();      
    float dw = textWidth(dstr);
    if (x1 < xc + dw/2) {
      xc -= xc + dw/2 - (x1);  
    }
    if (x0 > xc - dw/2) {
      xc += x0 - (xc - dw/2);  
    }        
    text(dstr, xc - dw/2, bounds.y + h2 - 15); 
  }

  boolean mousePressed() {
    if (!contains(mouseX, mouseY)) return false;
    selected = true;
    if (mouseX > bounds.x + bounds.w - margin) {

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
          bookHeightTimer.setTarget(0);
          compactTime = false;
        } else {
          bookHeightTimer.setTarget(1);
          compactTime = true;
        }
      }
    } else {
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
    }
    return true;
  }

  void setTime(float mx) {
    int days = int(map(mx, bounds.x, bounds.x + bounds.w - margin, 0, daysRunningTot));
    daysSinceStart.setTarget(days);
    if (currentMode == MODE_BOOKSHELF) {
      groupBooksByEmotion(days, true);
    } else if (currentMode == MODE_WHEEL) {
      groupBooksByEmotion(days, false);
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
    
    noStroke();
    fill(replaceAlpha(backgroundColor, 180));
    rect(bx, by, bw, bh);
    
    strokeWeight(1);
    stroke(legendLineColor);
    fill(255);
    rect(bx, by + bh/2 - fontSize/2, fontSize, fontSize);
    line(bx + fontSize/2, bounds.y, bx + fontSize/2, by + bh/2 - fontSize/2);

    fill(defTextColor);
    if (closed) {
      text("show legend", xc, yc);
    } else {
      text("hide legend", xc, yc);
      
      float xlang = 0.4 * bounds.w;
      float xemo = 0.6 * bounds.w;
      float h = bounds.h * animTimer.get(); 
   
      line(xlang, bounds.y, xlang, bounds.y + h);
      line(xemo, bounds.y, xemo, bounds.y + h + animTimer.get() * 20);    
       
      float y = h - 20;
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
          rect(x0, y0, x1 - x0, y1 - y0);          
          fill(defTextColor);
          float tw = textWidth(lang.name);
          text(lang.name, xlang - 15 - tw, y + 0.7 * fontSize/2 + fontSize/2);
        
          if (0 <= ei) {
            Emotion emo = emotions.get(ei);
            fill(emo.argb);
            rect(xemo - 0.7 * fontSize/2, y, 0.7 * fontSize, 0.7 * fontSize);          
            fill(defTextColor);
            text(emo.name, xemo + 0.7 * fontSize, y + 0.7 * fontSize/2 + fontSize/2);
          }

          if (x0 < mouseX && mouseX <= x1 && y0 <= mouseY && mouseY <= y1 && !mouseActivity) {
              hintInfo.open("click language to open the webpage for the " + lang.name + " community");
            
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
        
          y -= 0.7 * fontSize + 20;
        } else {
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
      } else {
        close();
      }   
      return true;            
    } else if (!closed) {     
      
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
            link(lang.url, "_new");
          }
          return true;
        }
         
        y -= 0.7 * fontSize + 20;
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
    setLanguage(x, bounds);
  } else {
    viewRegion.zoomLevel = VIEW_BOOK; 
    bookStrokeWeight.setTarget(bookOutlineW);
    bookTopHeight.setTarget(maxBookHeight);
    langBarH.setTarget(langBarWBook);    
    selLanguage = null;

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
              viewRegion.setTarget(iabs - sizeBookView/2, iabs + sizeBookView/2);
              return;
            }
          }
        }

        count += bemo.size();
      }
    }
  }
}

void setViewRegionAllBookshelf() {
  viewRegion.setTarget(0, books.size());
  viewRegion.zoomLevel = VIEW_ALL;
  bookStrokeWeight.set(0);
  bookTopHeight.setTarget(0);
  langBarH.setTarget(langBarWAll);
  bookHeightTimer.setTarget(0);
  compactTime = false; 
  selLanguage = null;
}

void setViewRegionWheel(float x, float y, Rectangle bounds, float yTop) {
  float xc = bounds.x + bounds.w/2;
  float yc = bounds.y + yTop + bounds.h/2;

  float h = langBarH.get();
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
        return;
      }
    }
  } else if (r1 < d && d < r1 + maxBookHeight) {
    selectBookInWheel(d, angle);
  } else {
    setViewRegionAllWheel();
  }
}

void setViewRegionAllWheel() {
  viewRegion.zoomLevel = VIEW_ALL;
  wheelYPos.setTarget(0);
  wheelScale.setTarget(1);
  langBarH.set(langBarWAll);
}

void selectBookInWheel(float d, float angle) {
  float r1 = wheelRadius + langBarH.get();
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

SelectedBook getSelectedBookInBookshelf(float x, float y, Rectangle bounds, float yTop) {
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

SelectedBook getSelectedBookInWheel(Rectangle bounds, SelectedBook defSelBook, float yTop) {
  SelectedBook res = defSelBook;
  
  // To update the selected book, we look for the book
  // that is right at the top of the wheel: 
  float xc = bounds.x + bounds.w/2;
  float yc = bounds.y + yTop + bounds.h/2;
  float h = langBarH.get();  
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
        viewRegion.setTarget(imid - sizeBookView/2, imid + sizeBookView/2);
      } else {
        viewRegion.setTarget(langCount0, langCount);
      }  
      
      selLanguage = lang;
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
        viewRegion.setTarget(imid - sizeBookView/2, imid + sizeBookView/2);
      } else {
        viewRegion.setTarget(langCount0, langCount);
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

void dragViewRegion(float px, float x) {
  if (viewRegion.zoomLevel == VIEW_ALL) return;

  if (viewRegion.zoomLevel == VIEW_LANG) {
    if (selLanguage != null) {

      if (viewRegion.isTargeting()) return; // to avoid moving to another language before reaching the one selected first.

      Language prevLang = selLanguage;
      Language nextLang = selLanguage;            
      for (int i = 0; i < languages.size(); i++) {
        Language lang = languages.get(i);
        if (selLanguage == lang) {
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
        selLanguage = nextLang;
      } 

      if (diff < 0) {
        viewLanguage(prevLang);
        selLanguage = prevLang;
      }
    }
  } else {
    selLanguage = null;
 
    float first = viewRegion.firstBook.get();
    float last = viewRegion.lastBook.get();

    float f = 20 * (float)(last - first);

    float diff = f * (px - x) / width;

    viewRegion.setTarget(first + diff, last + diff);
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
String startDateString = "2009-11-01"; // Date the library opened
//String endDateString   = "2010-12-31";
String endDateString   = "";           // If left empty, then the current date will be used

// Input files:
String emoFilename   = "emotions.txt";
String langFilename  = "languages.txt";
String booksFilename = "books.txt";
String histoFilename = "history.txt";
String linksFilename = "links.txt";

// Bookshelf parameters:
int bookshelfTop   = 0;
float langBarWAll  =  10;//20; 
float langBarWLang =  10;//20;
float langBarWBook =  10;//15;
float bookPadding  =  0.3;//0.4;//0.3;
int   sizeBookView = 100;//40;//40;

float maxBookHeight  = 10;
float bookOutlineW   = 1;

float bookBubbleTailH = 30; // Height of the tail of the box bubble

// Wheel parameters:
int wheelTop = 0;
float wheelRadius = 230;
int trailLength = 50;
float wheelDispEmo = 200;   // How much the wheel is translated down the Y axis when selecting an emo...
float wheelScaleEmo = 1.3;  // ...and how much it is scaled.
float wheelDispBook = 600;  // Idem when selecting a book...
float wheelScaleBook = 2.0; // ...

// History parameters
float historyTop = 80;
int emoBandAlpha = 120;
int bookStrokeAlpha = 180;
boolean showSolidEmoHistory = false;

// Increment (in days) for each step of the animation.
int animationIncDays = 28;

// Fonts:
String fontName = "Droid Sans";
int fontSize    = 11;

String langFontName = "Druid Sans Bold";
int langFontSize    = 12;
color langFontColor = color(255);

color defTextColor = color(175);

// Colors
color backgroundColor = color(0);
color selOptionColor = color(195, 224, 0);
color menuStrokeColor = color(150);
color timelineColor = color(150);
color legendLineColor = color(150);
color historyLineColor = color(150);

color infoTextColor = color(0);

color bookshelfLinesColor = color(0);

color historyTrailsColor = color(255);

color selHistoryColor = color(255);

// Simple soft float class to implement smooth animations
class SoftFloat {
  float ATTRACTION = 0.1;
  float DAMPING = 0.5;

  float value;
  float velocity;
  float acceleration;

  boolean enabled;  
  boolean targeting;
  float source;
  float target;

  SoftFloat() {
    value = source = target = 0;
    targeting = false;
    enabled = true;
  }
  
  void set(float v) {
    value = v;
    targeting = false;
  }  
  
  float get() {
    return value;
  }

  int getInt() {
    return (int)value;
  }

  void enable() {
    enabled = true;
  }
  
  void disable() {
    enabled = false;
  }


  boolean update() {
    if (!enabled) return false;
    
    if (targeting) {
      acceleration += ATTRACTION * (target - value);
      velocity = (velocity + acceleration) * DAMPING;
      value += velocity;
      acceleration = 0;
      if (abs(velocity) > 0.0001) {
        return true;
      }
      // arrived, set it to the target value to prevent rounding error
      value = target;
      targeting = false;
    }
    return false;
  }
  
  void setTarget(float t) {
    targeting = true;
    target = t;
    source = value;
  }
  
  float getTarget() {
    return targeting ? target : value;
  }
}
void groupBooksByLanguage() {
  for (Language lang: languages) {
    for (Book book: books) {
      if (book.lang == lang.id) {
        lang.addBook(book);
      }
    }
  }
  
  // Removing languages with no books.
  for (int i = languages.size() - 1; i >= 0; i--) {
    Language lang = languages.get(i);
    if (lang.booksInLang.size() == 0) {
      languages.remove(i);
    }
  }  
}

void groupBooksByEmotion(int days, boolean init) {
  for (Emotion emo: emotions) {
    emo.clearBooks();    
    for (Book book: books) {
      int et = book.getEmotion(days);
      if (et == emo.id) {
        emo.addBook(book);
      }
    }    
  }

  // Updating the emotional gruping of books
  // within each language.
  for (Language lang: languages) {
    lang.updateBooksPerEmo(days);
  }

  if (currentMode == MODE_BOOKSHELF) {
    int i0 = 0;
    // Update positions of the books in the bookshelf
    for (Language lang: languages) {  
      if (lang.id == 0) continue;
    
      for (Emotion emo: emotions) {  
        ArrayList<Book> bemo = lang.booksPerEmo.get(emo.id);
        if (bemo == null) continue;      
        for (int i = 0; i < bemo.size(); i++) {
          Book book = bemo.get(i);        
          book.setBookshelfPos(i + i0);
        }  
        i0 += bemo.size();        
      }
    }
  } else if (currentMode == MODE_WHEEL) {
    int i0 = 0;
    // Update positions of the books in the wheel. 
    for (Emotion emo: emotions) {  
      for (Language lang: languages) {
        ArrayList<Book> blang = emo.booksPerLang.get(lang.id);
        if (blang == null) continue;

        for (int i = 0; i < blang.size(); i++) {
          Book book = blang.get(i);
          if (init) {
            book.initWheelPos(i + i0);
          } else {
            book.setWheelPos(i + i0); 
          }
        }
      
        i0 += blang.size();
      }
    }
  }
}  

void buildHistory() {
  for (int d7 = 0; d7 <= daysRunningTot + 7; d7 += 7) {
    int days = constrain(d7, 0, daysRunningTot);
    
    groupBooksByEmotion(days, false);
    float x = float(days) / float(daysRunningTot);
    
    int totCount = 0;
    for (Emotion emo: emotions) {
      if (emo.id == 0) continue;
    
      for (Language lang: languages) {
        ArrayList<Book> blang = emo.booksPerLang.get(lang.id);
        if (blang == null) continue;
        totCount += blang.size();
      }
    }    
    
    int count = 0;
    for (Emotion emo: emotions) {
      float miny = 1;
      boolean hasBook = false;
      if (emo.id == 0) continue;
    
      for (Language lang: languages) {
        ArrayList<Book> blang = emo.booksPerLang.get(lang.id);
        if (blang == null) continue;        
        for (int i = 0; i < blang.size(); i++) {          
          Book book = blang.get(i);
          float y = float(count) / float(totCount);
          miny = min(miny, y);
          hasBook = true;
          book.addHistoryPoint(x, y, emo.argb);          
          count++;
        }
      }
      if (hasBook) {
        emo.addBorderPoint(x, miny);
      }      
    }
  } 
}  

// Returns the x coordinate for the book with absolute coordinate i, corresponding to the
// current viewing range.
float bookX(int i, float x, float w) {
  float first = viewRegion.getFirstBook();
  float last = viewRegion.getLastBook(); 
  float count = last - first + 1;
  float w1 = w / count; // width of a single book
  return map(i, first, last, x, x + w - w1);
}

float bookAngle(int i) {
  int first = 0;
  int count = 0;
  for (Emotion emo: emotions) {
    if (emo.id == 0) continue;
    
    for (Language lang: languages) {
      ArrayList<Book> blang = emo.booksPerLang.get(lang.id);
      if (blang == null) continue;
      count += blang.size();
    }
  }

  int last = first + count - 1;
  return constrain(map(i, first, last, 0, TWO_PI), 0, TWO_PI);
}

// Returns the intersection points between a line segment between (x1, y1) and
// (x2, y2) and the circle (x3, y3) with radius r:
// http://paulbourke.net/geometry/sphereline/
boolean segmentCircleIntersect(float x1, float y1, float x2, float y2,
                               float x3, float y3, float r) {                                    
  // Let's first determine if there the possibility of an intersection 
  // between the segment and the circle
  float num = ((x3 - x1) * (x2 - x1) + (y3 - y1) * (y2 - y1));
  float den = ((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
 
  if (abs(den) < 0.001) return false;
  
  float u = num / den;
    
  if (u < 0 || 1 < u) {
    // no intersection
    return false;
  }
    
  // Closest point on the segment to the center of the circle
  float cx = x1 + u * (x2 - x1);
  float cy = y1 + u * (y2 - y1);
    
  // Distance between (cx, cy) and the center of the circle must
  // be smaller than the radius r
  float d = dist(cx, cy, x3, y3);
    
  if (r < d) {
    return false;
  }
    
  return true;
}

boolean intervalIntersect(float a, float b, float c, float d) {
  if (b < c || d < a) {
      // No intersection.
      return false;
   } else {
     return true;
   } 
}

float centerIntersection(float a, float b, float c, float d) {
  if (b < c || d < a) {
    // No intersection.
    return 0;
  }
    
  float x, y;
  if (a < c) {
    x = c;
    y = b < d ? b : d;
  } else {
    x = a;
    y = b < d ? b : d;
  }    
  return (x + y)/2;
}

String chopStringRight(String str, PFont font, float maxw) {
   textFont(font);
   String chopped = str;
   float w = textWidth(chopped);    
   while (w > maxw) {
     int n = chopped.length() - 1;
     if (-1 < n) {
        chopped = chopped.substring(0, n);
      } else {
        return "";
      }
      w = textWidth(chopped);
   }
   return chopped;    
}

int daysBetween(Date startDate, Date endDate) {
  int btw = 0;
  Date tmp = new Date();
  tmp.copy(startDate);
  while (tmp.isBefore(endDate)) {
    tmp.addDay();
    btw++;
  }  
  return btw;
}    

// Returns a data object that results of adding days to startDate.
Date dateAfter(Date startDate, int days) {
  Date res = new Date();
  res.copy(startDate);
  for (int i = 0; i < days; i++) {
    res.addDay();
  }
  return res;
}

// Squeezes the y value around 0.5 when is close to zero. Both assumed to be between 0 and 1.
float squeezeY(float x, float y) {
  float x0 = 0.25;
  float y0 = 0.75;
  if (x < x0) {
    float f = bezierPoint(y0, 1, 1, 1.0, map(x, 0, x0, 0, 1));    
    return 0.5 + f * (y - 0.5);
  } else {
    return y;
  }
}

int replaceAlpha(int argb, int a) {
  return a << 24 | (argb & 0xFFFFFF);  
}
int currentTask = -1;
int currentMode = MODE_BOOKSHELF;

// Data:
ArrayList<Emotion> emotions;
ArrayList<Emotion> emotions1; // what is it for? I forgot...
ArrayList<Language> languages;
ArrayList<Book> books;
HashMap<Integer, Emotion> emotionsByID;
HashMap<String, Language> languagesByCode;
HashMap<Integer, Language> languagesByID;
HashMap<Integer, Book> booksByID;

// Data range:
ViewRegion viewRegion;

// Time variables:
Date startDate;
Date endDate;
int daysRunningTot;
SoftFloat daysSinceStart;

// UI variables:
// general
SoftFloat bookStrokeWeight;
SoftFloat langBarH;
SoftFloat bookTopHeight;
//SelectedBook selBook;
boolean didDrag;

// bookshelf
boolean compactTime;
SoftFloat bookHeightTimer;
Language selLanguage;

// wheel
boolean playingAnim;
boolean selectedPlayAnim;

SoftFloat wheelRAngle;
SoftFloat wheelYPos;
SoftFloat wheelScale;

SoftFloat viewFadeinAlpha;      // View left margin 
SoftFloat viewLeftMargin; // View left margin

int noMouseActivityCount = 0;
boolean mouseActivity = false;

SelectedBook selBook = null;
SelectedLanguage selLang = null;

ViewArea viewArea;
ViewMenu viewMenu;
Timeline timeline;
LegendArea legendArea;
ArrayList<InterfaceElement> ui;
HintInfo hintInfo;

PFont defFont;
PFont langFont;

float sinLUT[];
float cosLUT[];
float SINCOS_PRECISION = 1.0;
int SINCOS_LENGTH = int((360.0 / SINCOS_PRECISION));

PGraphics historyCanvas;

void initialize(int task) {
  if (task == LOADING) {
    strokeCap(RECT);
    strokeJoin(RECT);
    
    defFont = createFont(fontName, fontSize, false);
    textFont(defFont);
    
    langFont = createFont(langFontName, langFontSize, false);
    
    initLUT();
   
    // Time setup:  
    if (endDateString.equals("")) {
      endDateString = year() + "-" + month() + "-" + day();
    }  
    startDate = new Date(startDateString);
    endDate = new Date(endDateString);
    daysRunningTot = daysBetween(startDate, endDate);
    
    currentTask = LOAD_EMOTIONS;
  } else if (task == LOAD_EMOTIONS) {
    loadEmotions();
  
    currentTask = LOAD_LANGUAGES;  
  } else if (task == LOAD_LANGUAGES) {
    loadLanguages();
    loadWebLinks();
    
    currentTask = LOAD_BOOKS;
  } else if (task == LOAD_BOOKS) {
    loadBooks();
    
    currentTask = GROUP_BY_LANG;
  } else if (task == GROUP_BY_LANG) {
    groupBooksByLanguage();
    
    currentTask = BUILD_HISTORY;
  } else if (task == BUILD_HISTORY) {
    buildHistory(); 
    
    currentTask = GROUP_BY_EMO;
  } else if (task == GROUP_BY_EMO) {
    daysSinceStart = new SoftFloat();
    daysSinceStart.setTarget(daysRunningTot);   
    groupBooksByEmotion(daysSinceStart.getInt(), true);
  
    currentTask = FINISH_INIT;
  } else if (task == FINISH_INIT) {
    // Init viewing range:
    viewRegion = new ViewRegion(books);
    viewRegion.setTarget(0, books.size());  
    viewRegion.zoomLevel = VIEW_ALL;
  
    bookStrokeWeight = new SoftFloat();
    langBarH = new SoftFloat();
    langBarH.setTarget(langBarWAll);
  
    bookTopHeight = new SoftFloat();
    bookHeightTimer = new SoftFloat();
    bookHeightTimer.setTarget(0);
    compactTime = false;

    wheelRAngle = new SoftFloat();
    wheelRAngle.set(0);
    wheelYPos = new SoftFloat();
    wheelYPos.set(0);
    wheelScale = new SoftFloat();
    wheelScale.set(1);
  
    viewFadeinAlpha = new SoftFloat();
    viewFadeinAlpha.set(255);
    viewLeftMargin = new SoftFloat();

    // Create UI    
    viewMenu = new ViewMenu(0, height - 50, 250, 50);
    timeline = new Timeline(250, height - 50, width - 250, 50);  
    viewArea = new ViewArea(0, 50, width, height - 120);  
    legendArea = new LegendArea(150, 30, 100, 20,
                                0, 0, 200, height - 100);
    ui = new ArrayList<InterfaceElement>();
    ui.add(viewArea);
    ui.add(legendArea);        
    ui.add(viewMenu);
    ui.add(timeline); 
    
    hintInfo = new HintInfo(600, 30);
  
    legendArea.open();
    currentTask = RUNNING;
    
    // Trigger initial fade-in animation.
    viewFadeinAlpha.set(0);
    viewFadeinAlpha.setTarget(255);    
  }
}

void initLUT() {
  // Fill the tables
  sinLUT = new float[SINCOS_LENGTH + 1];
  cosLUT = new float[SINCOS_LENGTH + 1];
  for (int i = 0; i <= SINCOS_LENGTH; i++) {
    sinLUT[i] = (float) Math.sin(i * DEG_TO_RAD * SINCOS_PRECISION);
    cosLUT[i] = (float) Math.cos(i * DEG_TO_RAD * SINCOS_PRECISION);
  }  
}

