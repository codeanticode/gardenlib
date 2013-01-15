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

  int i0 = 0;
  if (currentMode == MODE_BOOKSHELF) {
    // Update positions of the books in the bookshelf

    if (groupByLangFirst) {
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
    } 
    else {    
      for (Emotion emo: emotions) {  
        for (Language lang: languages) {
          ArrayList<Book> blang = emo.booksPerLang.get(lang.id);
          if (blang == null) continue;

          for (int i = 0; i < blang.size(); i++) {
            Book book = blang.get(i);        
            book.setBookshelfPos(i + i0);
          }
          i0 += blang.size();
        }
      }
    }
  } 
  else if (currentMode == MODE_WHEEL) {
    // Update positions of the books in the wheel. 
    for (Emotion emo: emotions) {  
      for (Language lang: languages) {
        ArrayList<Book> blang = emo.booksPerLang.get(lang.id);
        if (blang == null) continue;

        for (int i = 0; i < blang.size(); i++) {
          Book book = blang.get(i);
          if (init) {
            book.initWheelPos(i + i0);
          } 
          else {
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

    int totCount = numBooksWithEmo();
    //    for (Emotion emo: emotions) {
    //      if (emo.id == 0) continue;
    //    
    //      for (Language lang: languages) {
    //        ArrayList<Book> blang = emo.booksPerLang.get(lang.id);
    //        if (blang == null) continue;
    //        totCount += blang.size();
    //      }
    //    }    

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

// Returns the number of books with an emotional assignment.
int numBooksWithEmo() {
  int count = 0;
  for (Emotion emo: emotions) {
    if (emo.id == 0) continue;

    for (Language lang: languages) {
      ArrayList<Book> blang = emo.booksPerLang.get(lang.id);
      if (blang == null) continue;
      count += blang.size();
    }
  }
  return count;
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
  } 
  else {
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
  } 
  else {
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
    } 
    else {
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
  while (tmp.isBefore (endDate)) {
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
  } 
  else {
    return y;
  }
}

int replaceAlpha(int argb, int a) {
  return a << 24 | (argb & 0xFFFFFF);
}

int fcount, lastm;
float frate;
int fint = 3;
void printFrameRate() {
  fcount += 1;
  int m = millis();
  if (m - lastm > 1000 * fint) {
    frate = float(fcount) / fint;
    fcount = 0;
    lastm = m;
    println("fps: " + frate);
  }
}

