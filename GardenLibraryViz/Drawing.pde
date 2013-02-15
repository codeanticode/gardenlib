// The writing functions that take care of the bookshelf, wheel and history views.

void drawBookshelf(Rectangle bounds, float yTop) {
  clip(bounds.x, bounds.y, bounds.w, bounds.h);

  float firstBook = viewRegion.getFirstBook();  
  float bookCount = viewRegion.getBookCount(); 

  float elapsed = daysSinceStart.get();  

  float h = langBarH.get();

  //float h = 10; //add 8 pix to height of lang bar
  float totLen = map(elapsed, 0, daysRunningTot, 0, bounds.y + bounds.h - yTop);

  float w = bounds.w / bookCount;
  
  if (1 < w) bookStrokeWeight.enable();
  else bookStrokeWeight.disable(); // to stop the stroke appearing when the book rects are still too thin.

  if (sortByLang) { // Grouping the books first by language, then by emotion.
    drawBookshelfGroupByLang(bounds, firstBook, bookCount, yTop, totLen, w, h);
  } else { // Grouping the books first by emotion, then by language.
    drawBookshelfGroupByEmo(bounds, firstBook, bookCount, yTop, totLen, w, h);
  }

  noClip();
}

void drawBookshelfGroupByLang(Rectangle bounds, float firstBook, float bookCount, float yTop, float totLen, float w, float h) {
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
            book.drawInBookshelf(firstBook, w, bounds.x, yTop, h, totLen, true);
          }
        }
      }

      count += bemo.size();
    }

    // Draw language rectangle    
    float x0 = bookX(langCount, bounds.x, bounds.w);
    langCount += lang.numTotBooks();        
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

void drawBookshelfGroupByEmo(Rectangle bounds, float firstBook, float bookCount, float yTop, float totLen, float w, float h) {
  int emoCount = 0;
  int count = 0;
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
            book.drawInBookshelf(firstBook, w, bounds.x, yTop, h, totLen, false);
            if (x0 == -1) {
              x0 = book.bookBookshelfX0(firstBook, w, bounds.x);
            }
            x1 = book.bookBookshelfX1(firstBook, w, bounds.x);            
          }
        }
      }

     // Draw language bar
     float bh = bookTopHeight.get();
     if (-1 < x0 && x0 < x1 && 0 < bh) {
       fill(replaceAlpha(lang.argb, viewFadeinAlpha.getInt()));       
       noStroke(); 
       rect(x0, yTop - h - bh, x1 - x0, 0.7 * bh); 
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
      } else {
        x0 = bounds.x;
      } 
      if (x1 < bounds.x + bounds.w) { // right padding
        x1 -= bookPadding * w/2;
      } else {
        x1 = bounds.x + bounds.w;
      }  
      noStroke();

      fill(replaceAlpha(emo.argb, viewFadeinAlpha.getInt()));          
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

  float h = wheelWidth.get();

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

void drawHistory(Rectangle bounds, float yTop, float w0) {
  // We use to canvas to avoid resizing and slowing down rendering with JAVA2D  
  int sel = 0;
  float margin = viewLeftMargin.get();
  int historyW, historyH;  
  if (0 < margin) {
    sel = 1;
    historyW = int(w0 - viewLeftMargin.getTarget());
  } else {
    sel = 0;
    historyW = int(bounds.w);  
  }
  historyH = int(bounds.h - yTop - 20);  
  
  if (historyCanvas[sel] == null) {   
    PGraphics pg = createGraphics(historyW, historyH);
    historyCanvas[sel] = pg;
    pg.beginDraw();

    if (showSolidEmoHistory) {
      // Draw background for each emotion
      pg.noStroke();
      for (int i = 0; i < emotions1.size(); i++) {
        Emotion emo = emotions1.get(i);

        float minx = 1;
        pg.fill(red(emo.argb), green(emo.argb), blue(emo.argb), emoBandAlpha);

        pg.beginShape(POLYGON);
        if (i == 0) { // first
          for (int d7 = 0; d7 <= daysRunningTot + 7; d7 += 7) {
            int days = constrain(d7, 0, daysRunningTot);
            float x = map(days, 0, daysRunningTot, 0, 1);
            pg.vertex(x * historyW, squeezeY(x, 0) * historyH);
          }
          minx = 0;
        } else {
          for (PVector v: emo.border) {
            pg.vertex(historyW * v.x, historyH * squeezeY(v.x, v.y));
            minx = min(v.x, minx);
          }
        }

        if (i == emotions1.size() - 1) { // last
          for (int d7 = 0; d7 <= daysRunningTot + 7; d7 += 7) {
            int days = constrain(d7, 0, daysRunningTot);
            float x = map(days, 0, daysRunningTot, 1, 0);
            pg.vertex(x * historyW, squeezeY(x, 1) * historyH);
          }
        } else {
          float minx1 = 1;
          Emotion emo1 = emotions1.get(i + 1);
          for (int j = emo1.border.size() - 1; j >= 0; j--) {
            PVector v = emo1.border.get(j);
            pg.vertex(historyW * v.x, historyH * squeezeY(v.x, v.y));
            minx1 = min(v.x, minx1);
          }

          if (minx == 0 && 0 < minx1) {
            // shape won't close properly, need to find another point
            // in the next emos.
            for (int j = i + 2; j <= emotions1.size(); j++) {
              if (j < emotions1.size()) {
                emo1 = emotions1.get(j); 
                PVector v = emo1.border.get(0);
                pg.vertex(historyW * v.x, historyH * squeezeY(v.x, v.y));
                minx1 = min(v.x, minx1);
                if (minx1 == 0) break;
              } else {
                pg.vertex(0, squeezeY(0, 1) * historyH);
              }
            }
          }
        }

        pg.endShape(CLOSE);
      }      
    }

    // Draw each book
    Book sbook = null;
    for (Book book: books) {
      PVector pt0 = null;
      for (PVector pt: book.history) {
        if (book == sbook) continue;
        if (pt0 != null && pt0.z == pt.z) {        
          pg.strokeWeight(1);
          pg.stroke(replaceAlpha(int(pt0.z), bookStrokeAlpha));
          pg.noFill();
          pg.line(historyW * pt0.x, historyH * squeezeY(pt0.x, pt0.y), // option for stretching vertically
                  historyW * pt.x, historyH * squeezeY(pt.x, pt.y));
        }
        pt0 = pt;
      }
    }
    pg.endDraw();
  }
  
  // Due to some bug in Java2D, the tint transparency must be set to 255, otherwise
  // the image will be completely transparent all the time, apparently because
  // was set as zero the first time.
//  tint(255, viewFadeinAlpha.getInt());
  tint(255, 255);
  image(historyCanvas[sel], bounds.x, bounds.y + yTop, bounds.w, historyH);
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

void drawNewsBox(float x, float x0, float x1, float y, Date selDate) {
  timelineRollOver(x, y);

  //if (!daysSinceStart.targeting) {
  if (abs(daysSinceStart.velocity) < 0.2) { // So the news text shows up faster        
    for (int i = 0; i < timelineNews.length; i++) {
      NewsText news = timelineNews[i];
      if (news.isBefore(selDate)) {     
        currNewsText = timelineNews[i].text;
        int days = daysBetween(startDate, news.date);      
        newsX = map(days, 0, daysRunningTot, x0, x1);
      }
    }    
  } else {
    newsAlpha = 0;
  }

  // to change the alpha of the text box
  if (newsRollover) {
    if (newsAlpha < 255) {
      newsAlpha = constrain(newsAlpha + newsAlphaSpeed, 0, 255);
    }
  } else {
    if (newsAlpha > 0) {
      newsAlpha = constrain(newsAlpha - newsAlphaSpeed, 0, 255);
    }
  }

  if (0 < newsAlpha && currNewsText != null) {
    float newsLineSpace = newsFontSize + 2;
    textFont(newsFont);
    float y0 = y;
    for (int i = currNewsText.length - 1; i >= 0 ; i--) {
      String par = currNewsText[i];
      
      // calculate the position of the box
      float textLength = textWidth(par);
      float boxWidth = x1 - x0;
      float boxHeight = ceil(textLength/boxWidth) * newsLineSpace + 3;
      float boxPosX = x0;
      float boxPosY = y0 - boxHeight - newsAdjustY;

      // draw the box and text
      noStroke();
      fill(0, newsAlpha * 2);
      rect(boxPosX, boxPosY, boxWidth, boxHeight);
      fill(replaceAlpha(newsFontColor, newsAlpha));
      textLeading(newsLineSpace);
      text(par, boxPosX, boxPosY, boxWidth, boxHeight);
      
      y0 = y0 - boxHeight;
    }
    textFont(defFont);
    fill(255, 0, 0, newsAlpha);
    ellipse(newsX, y + 15, 8, 8);
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

void drawHelpLayer() {
  noStroke();
  fill(0, viewFadeinAlpha.getInt());
  rect(0, 0, width, height);  
    
  textFont(helpFont);
  
  if (currentMode == MODE_BOOKSHELF) {
    if (sortByLang) {
      if (viewRegion.zoomLevel != VIEW_BOOK) {
        drawHelpBookshelfSortByLang(0);
      } else {
        if (!compactTime) {
          drawHelpBookshelfSortByLang(1);
        } else {
          drawHelpBookshelfSortByLang(2);
        }        
      }
    } else {
      if (viewRegion.zoomLevel != VIEW_BOOK) {
        drawHelpBookshelfSortByEmo(0);
      } else {
        if (!compactTime) {
          drawHelpBookshelfSortByEmo(1);  
        } else {
          drawHelpBookshelfSortByEmo(2);
        }        
      }
    }
  } else if (currentMode == MODE_WHEEL) {
    if (viewRegion.zoomLevel == VIEW_ALL) {
      drawHelpWheel(1);
    } else {
      drawHelpWheel(2);
    }
  } else if (currentMode == MODE_HISTORY) {
    if (selBook == null) {
      drawHelpHistory(1);
    } else {
      drawHelpHistory(2);
    }
  }
  
  textFont(defFont);
}

void drawHelpBookshelfSortByLang(int option) {
  if (option == 0) {
    float x, y, w;
    
    x = viewArea.bounds.x;
    y = viewArea.langBarY - langBarH.get() - 5;
    fill(replaceAlpha(helpFontColor, 2 * viewFadeinAlpha.getInt()));
    text("language categories", x, y);
    w = textWidth("language categories");
    drawHorizontalHelpArrow(x + w + 5, x + w + 100, y - 0.25 * helpFontSize);
        
    x = viewArea.bounds.x + 50;
    y = viewArea.langBarY + 50;
    fill(replaceAlpha(helpFontColor, 2 * viewFadeinAlpha.getInt()));
    text("emotional judgements", x, y);
    drawVerticalHelpArrow(y + helpFontSize - 10, y + helpFontSize + 100, x + 50);    
  } else if (option == 1 || option == 2) {
    float x, y, w, wj;
    
    x = viewArea.bounds.x;
    y = viewArea.langBarY;
    w = textWidth("language categories");
    wj = textWidth("current emotional judgements");
    fill(replaceAlpha(helpFontColor, 2 * viewFadeinAlpha.getInt()));
    text("current emotional judgements", x + w + 100, y - langBarH.get() - bookTopHeight.get() - 30);
    drawVerticalHelpArrow(y - langBarH.get() - bookTopHeight.get() - 25, y - langBarH.get() - bookTopHeight.get() - 5, x + w + 100 + wj/2);
    drawVerticalHelpArrow(y - langBarH.get() - bookTopHeight.get() - 25, y - langBarH.get() - bookTopHeight.get() - 5, x + w + 100 + wj/2 - 30);
    drawVerticalHelpArrow(y - langBarH.get() - bookTopHeight.get() - 25, y - langBarH.get() - bookTopHeight.get() - 5, x + w + 100 + wj/2 + 30);
        
    fill(replaceAlpha(helpFontColor, 2 * viewFadeinAlpha.getInt()));
    text("language categories", x, y);
    
    drawHorizontalHelpArrow(x + w + 5, x + w + 100, y - 0.25 * helpFontSize);

    x = viewArea.bounds.x + 70;
    y = viewArea.langBarY + 50;
    fill(replaceAlpha(helpFontColor, 2 * viewFadeinAlpha.getInt()));
    text("emotional judgements", x, y);
    drawVerticalHelpArrow(y + helpFontSize - 10, y + helpFontSize + 100, x + 50);

    x += 60;
    y += 30;
    fill(replaceAlpha(helpFontColor, 2 * viewFadeinAlpha.getInt()));
    text("number of vertical segments indicates the number of times a book has been borrowed;", x, y);
    if (option == 1) {
      text("their length indicates the time a book has held to a particular emotional judgement", x, y + 20);
    } else {      
      text("each vertical segment represents one emotional judgement", x, y + 20);      
    }
  }
}

void drawHelpBookshelfSortByEmo(int option) {
  if (option == 0) {
    float x, y, w, wj;
    
    x = viewArea.bounds.x;
    y = viewArea.langBarY;
    w = textWidth("emotional categories");
    wj = textWidth("languages");
    fill(replaceAlpha(helpFontColor, 2 * viewFadeinAlpha.getInt()));
    text("languages", x + w + 200, y - langBarH.get() - bookTopHeight.get() - 30);
    drawVerticalHelpArrow(y - langBarH.get() - bookTopHeight.get() - 25, y - langBarH.get() - bookTopHeight.get() - 5, x + w + 200 + wj/2);
    drawVerticalHelpArrow(y - langBarH.get() - bookTopHeight.get() - 25, y - langBarH.get() - bookTopHeight.get() - 5, x + w + 200 + wj/2 - 30);
    drawVerticalHelpArrow(y - langBarH.get() - bookTopHeight.get() - 25, y - langBarH.get() - bookTopHeight.get() - 5, x + w + 200 + wj/2 + 30);
        
    fill(replaceAlpha(helpFontColor, 2 * viewFadeinAlpha.getInt()));
    text("emotional categories", x, y);
    
    drawHorizontalHelpArrow(x + w + 5, x + w + 100, y - 0.25 * helpFontSize);
        
    x = viewArea.bounds.x + 50;
    y = viewArea.langBarY + 50;
    fill(replaceAlpha(helpFontColor, 2 * viewFadeinAlpha.getInt()));
    text("emotional judgements", x, y);
    drawVerticalHelpArrow(y + helpFontSize - 10, y + helpFontSize + 100, x + 50);    
  } else if (option == 1 || option == 2) {
    float x, y, w, wj;
    
    x = viewArea.bounds.x;
    y = viewArea.langBarY;
    w = textWidth("emotional categories");
    wj = textWidth("languages");
    fill(replaceAlpha(helpFontColor, 2 * viewFadeinAlpha.getInt()));
    text("languages", x + w + 200, y - langBarH.get() - bookTopHeight.get() - 30);
    drawVerticalHelpArrow(y - langBarH.get() - bookTopHeight.get() - 25, y - langBarH.get() - bookTopHeight.get() - 5, x + w + 200 + wj/2);
    drawVerticalHelpArrow(y - langBarH.get() - bookTopHeight.get() - 25, y - langBarH.get() - bookTopHeight.get() - 5, x + w + 200 + wj/2 - 30);
    drawVerticalHelpArrow(y - langBarH.get() - bookTopHeight.get() - 25, y - langBarH.get() - bookTopHeight.get() - 5, x + w + 200 + wj/2 + 30);
        
    fill(replaceAlpha(helpFontColor, 2 * viewFadeinAlpha.getInt()));
    text("emotional categories", x, y);
    
    drawHorizontalHelpArrow(x + w + 5, x + w + 100, y - 0.25 * helpFontSize);

    x = viewArea.bounds.x + 70;
    y = viewArea.langBarY + 50;
    fill(replaceAlpha(helpFontColor, 2 * viewFadeinAlpha.getInt()));
    text("emotional judgements", x, y);
    drawVerticalHelpArrow(y + helpFontSize - 10, y + helpFontSize + 100, x + 50);

    x += 60;
    y += 30;
    fill(replaceAlpha(helpFontColor, 2 * viewFadeinAlpha.getInt()));
    text("number of vertical segments indicates the number of times a book has been borrowed;", x, y);
    if (option == 1) {
      text("their length indicates the time a book has held to a particular emotional judgement", x, y + 20);
    } else {      
      text("each vertical segment represents one emotional judgement", x, y + 20);      
    }
  }
}

void drawHelpWheel(int option) {
  if (option == 1) {
    float x, y, xc, yc, w1, w2;
    
    x = viewArea.bounds.x;
    y = viewArea.bounds.y;
    
    xc = x + viewArea.bounds.w/2;
    yc = y + wheelTop + viewArea.bounds.h/2;  
    
    fill(replaceAlpha(helpFontColor, 2 * viewFadeinAlpha.getInt()));
    text("each ray illustrates a borrowed book and its previous emotional judgement", x + 50, y + 85);
  
    text("current emotional judgements", xc - wheelRadius/2, yc);
    drawHorizontalHelpArrow(xc - wheelRadius/2 - 5, xc - wheelRadius - wheelWidth.get(), yc - 0.25 * helpFontSize);
    
    w1 = textWidth("animations illustrate books wandering");
    w2 = textWidth("between emotional categories");
    text("animations illustrate books wandering", xc - w1/2, yc + 80);    
    text("between emotional categories", xc - w2/2, yc + 80 + 30);
  } else if (option == 2) {
    float x, y;
    x = viewArea.bounds.x;
    y = viewArea.bounds.y + wheelTop + viewArea.bounds.h/2 - 50;
    fill(replaceAlpha(helpFontColor, 2 * viewFadeinAlpha.getInt()));
    text("each ray illustrates a borrowed book and its previous emotional judgement", x + 50, y + 85);
    text("spin the wheel to view book info", x + 50, y + 115);  
  }  
}

void drawHelpHistory(int option) {
  if (option == 1) {
    float x, y;
    
    x = viewArea.bounds.x;
    y = viewArea.bounds.y + historyTop + (viewArea.bounds.h - historyTop - 20)/2;

    fill(replaceAlpha(helpFontColor, 2 * viewFadeinAlpha.getInt()));
    text("the colored bands are formed by the books passing through each emotion at a specific point in time", x + 20, y);    
  } else if (option == 2) {
    Book book = selBook.book;
    int l = book.history.size();
    if (0 < l) {
      float w = viewArea.bounds.w;
      float h = viewArea.bounds.h - historyTop - 20;
      float xc = viewArea.bounds.x;
      float yc = viewArea.bounds.y + historyTop;  
      int idx = constrain(l/2, 0, l - 1);
  
      PVector pt = book.history.get(idx);
      float x = xc + w * pt.x;
      float y = yc + h * squeezeY(pt.x, pt.y);
      
      fill(replaceAlpha(helpFontColor, 2 * viewFadeinAlpha.getInt()));
      
      float xp = x;
      float yp = y;
      float y0;
      
      if (y < viewArea.bounds.y + historyTop + h - 100) {
        y += 70;
        y0 = y - helpFontSize;        
        yp += 5; 
      } else {
        y -= 70;
        y0 = y + 5;
        yp -= 5;
      }
      
      float tw = textWidth("a single book's history of emotional judgements");
      if (viewArea.bounds.x + w < x + tw) {
        x -= (x + tw) - (viewArea.bounds.x + w);    
      }
      
      text("a single book's history of emotional judgements", x - 10, y);
      drawVerticalHelpArrow(y0, yp, xp);
    }
  }
}

void drawHorizontalHelpArrow(float x0, float x1, float y) {
  float trsize = 5;
  float xt = x0 < x1 ? x1 - trsize: x1 + trsize;    
  strokeWeight(1);
  stroke(255, 2 * viewFadeinAlpha.getInt());
  line(x0, y, xt, y);  
  noStroke();
  fill(255, 2 * viewFadeinAlpha.getInt());
  triangle(xt, y + trsize, x1, y, xt, y - trsize);  
} 

void drawVerticalHelpArrow(float y0, float y1, float x) {
  float trsize = 7;
  float yt = y0 < y1 ? y1 - trsize: y1 + trsize;    
  strokeWeight(1);
  stroke(255, 2 * viewFadeinAlpha.getInt());
  line(x, y0, x, y1);  
  noStroke();
  fill(255, 2 * viewFadeinAlpha.getInt());
  triangle(x - trsize, yt, x + trsize, yt, x, y1);   
} 
