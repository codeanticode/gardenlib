// The writing functions that take care of the bookshelf, wheel and history views.

void drawBookshelf(Rectangle bounds, float yTop) {
  clip(bounds.x, bounds.y, bounds.w, bounds.h);

  float firstBook = viewRegion.getFirstBook();  
  float bookCount = viewRegion.getBookCount(); 

  float elapsed = daysSinceStart.get();  

  // float h = langBarH.get();

  float h = langBarHB.get();// added for Bookshelf

  //float h = 10; //add 8 pix to height of lang bar
  float totLen = map(elapsed, 0, daysRunningTot, 0, bounds.y + bounds.h - yTop);

  int count = 0;

  float w = bounds.w / bookCount;
  
  if (1 < w) bookStrokeWeight.enable();
  else bookStrokeWeight.disable(); // to stop the stroke appearing when the book rects are still too thin.

  if (groupByLangFirst) { // Grouping the books first by language, then by emotion.
    drawBookshelfGroupByLang(bounds, count, firstBook, bookCount, yTop, totLen, w, h);
  } 
  else { // Grouping the books first by emotion, then by language.
    drawBookshelfGroupByEmo(bounds, count, firstBook, bookCount, yTop, totLen, w, h);
  }

  noClip();
}

void drawBookshelfGroupByLang(Rectangle bounds, int count, float firstBook, float bookCount, float yTop, float totLen, float w, float h) {
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
            book.drawInBookshelf(firstBook, w, bounds.x, yTop, h, totLen, true);
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
      } 
      else {
        x0 = bounds.x;
      }  
      if (x1 < bounds.x + bounds.w) { // right padding
        x1 -= bookPadding * w/2;
      } 
      else {
        x1 = bounds.x + bounds.w;
      }  
      noStroke();

      fill(replaceAlpha(lang.argb, viewFadeinAlpha.getInt()));          
      rect(x0, yTop - h, x1 - x0, h);
    }
  }
}

void drawBookshelfGroupByEmo(Rectangle bounds, int count, float firstBook, float bookCount, float yTop, float totLen, float w, float h) {
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
            book.drawInBookshelf(firstBook, w, bounds.x, yTop, h, totLen, false);
          }
        }
      }

      count += blang.size();
    }

    // Draw emotion rectangle  
    float x0 = bookX(emoCount, bounds.x, bounds.w);
    emoCount += emo.booksInEmo.size();        
    float x1 = bookX(emoCount, bounds.x, bounds.w);    
    if (intervalIntersect(x0, x1, bounds.x, bounds.x + bounds.w)) {
      // Adding paddings between languages:
      if (bounds.x < x0) { // left padding
        x0 += bookPadding * w/2;
      } 
      else {
        x0 = bounds.x;
      } 
      if (x1 < bounds.x + bounds.w) { // right padding
        x1 -= bookPadding * w/2;
      } 
      else {
        x1 = bounds.x + bounds.w;
      }  
      noStroke();

      fill(replaceAlpha(emo.argb, viewFadeinAlpha.getInt()));          
      rect(x0, yTop - h, x1 - x0, h);
    }
  }
}

boolean drawWheel(Rectangle bounds, float yTop) {
  //clip(bounds.x, bounds.y, bounds.w, bounds.h);

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
  //noClip();
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
        } 
        else {
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
        } 
        else {      

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
              } 
              else {
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
          historyCanvas.line(historyW * pt0.x, historyH * squeezeY(pt0.x, pt0.y), // option for stretching vertically
          historyW * pt.x, historyH * squeezeY(pt.x, pt.y));
        }
        pt0 = pt;
      }
    }
  }

  historyCanvas.endDraw();
  tint(255, viewFadeinAlpha.getInt());
  image(historyCanvas, bounds.x, bounds.y + yTop, bounds.w, historyH);
  //image(historyCanvas, bounds.x, bounds.y + yTop, bounds.w, historyH +30); // stretch bottom
}  

void drawBookHistory(SelectedBook sel, Rectangle bounds, float yTop) {  //white line
  Book book = sel.book;

  int historyW = int(bounds.w);
  int historyH = int(bounds.h - yTop - 20);  
  float xc = bounds.x;
  float yc = bounds.y + yTop;
  PVector pt0 = null;
  for (PVector pt: book.history) {
    if (pt0 != null) {
      //  strokeWeight(2);
      strokeWeight(1);
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
    } 
    else {
      float x1 = xc + historyW * pt.x;
      float y1 = yc + historyH * squeezeY(pt.x, pt.y);
      noStroke();
      fill(replaceAlpha(selHistoryColor, viewFadeinAlpha.getInt()));
      ellipse(x1, y1, 7, 7);
    }

    pt0 = pt;
  }
}

void drawTimeBox(float _x, float _x0, float _x1, float _y, int _day, int _month, int _year) {

  // to check the speed of the cursor movemnent
  /*
  timecursor_speed = abs(_x - timecursor_prevX);
   timecursor_prevX = _x;
   
   if (timecursor_speed > DEGREE_MOVEMENT) {
   CURSOR_STATE = 1;
   } 
   else {
   CURSOR_STATE = 0;
   }
   */
  timelineRollOver(_x, _y);

  float indicatorX = 0;


  // to correct the details
  for (int i = 0; i < timelineNews.length; i++) {
    NewsText timeTxt = timelineNews[i];
    if (timeTxt == null) continue;
    int textDays = timeTxt.year*360 + timeTxt.month*30 + timeTxt.day;    
    if (textDays <= _year*360 + _month*30 + _day) {      
      currNewsText = timelineNews[i].text;
      int days = (timelineNews[i].year-2009)*360 + timelineNews[i].month*30 + timelineNews[i].day;
      indicatorX = map(days, 11*30, 1080+11*30, _x0, _x1);
    }
  }


  if (indicatorX < _x0) {
    indicatorX = _x0;
  }


  // to change the alpha of the text box
  if (newsRollover) {
    if (newsAlpha < 255) {
      newsAlpha += newsAlphaSpeed;
    }
  } 
  else {
    if (newsAlpha > 0) {
      newsAlpha -= newsAlphaSpeed;
    }
  }

  //to calculate the position of the box
  float textLength = textWidth(currNewsText);
  float boxWidth = _x1 - _x0;
  float boxHeight = ceil(textLength/boxWidth)*newsLineSpace+3;
  float boxPosX = _x0;
  float boxPosY = _y - boxHeight - newsAdjustY;

  //to draw the box and text
  noStroke();
  fill(0, newsAlpha*2);
  rect(boxPosX, boxPosY, boxWidth, boxHeight);
  fill(160, newsAlpha);
  textLeading(newsLineSpace);
  text(currNewsText, boxPosX, boxPosY, boxWidth, boxHeight);
  fill(255, 0, 0, newsAlpha);
  ellipse(indicatorX, _y+15, 8, 8);
  noFill();
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

