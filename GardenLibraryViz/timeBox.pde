TimeText[] timeTextSet;

int BOX_ADJUST_Y = 16;
int TEXTLINE_SPACE = 13;
int CATCH_AREA = 10;

// TimeLine Status:
int CURSOR_STATE = 0;
int DEGREE_MOVEMENT = 10;
int ROLLOVER_STATE = 0;
int TIMEBOX_ALPHASPEED = 10;
int TIMEBOX_SCROLLALPHA = 70;

String currDetail = "";

int timeBox_alpha = 0;
float timecursor_prevX = 0;
float timecursor_speed = 0;


class TimeText {
  int year;
  int month;
  int day;
  String detail;

  TimeText(int _d, int _m, int _y) {
    this.day = _d;
    this.month = _m;
    this.year = _y;
    detail =  "";
  }
  void setDetail(String detail) {   
    this.detail = detail;
  }
}


void loadTimeText() {
  String details[] = loadStrings("details.txt"); 
  
  timeTextSet = new TimeText[ceil(details.length/3)+1];
  for (int i=0; i < details.length; i++) {
    if (i%3 == 0) { 
      String[] parts = split(details[i], " ");    
      int dd = parseInt(parts[0]);
      int mm = parseInt(parts[1]);
      int yyyy = parseInt(parts[2]);
      TimeText timeTxt = new TimeText(dd, mm, yyyy); 
      timeTextSet[floor(i/3)] = timeTxt; 
    } 
    else if (i%3 == 1) {
      timeTextSet[floor(i/3)].setDetail(details[i]);
    }
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
  for (int i=0; i < timeTextSet.length; i++) {
    TimeText timeTxt = timeTextSet[i];
    if (timeTxt == null) continue;
    int textDays = timeTxt.year*360 + timeTxt.month*30 + timeTxt.day;    
    if (textDays <= _year*360 + _month*30 + _day) {      
      currDetail = timeTextSet[i].detail;
      int days = (timeTextSet[i].year-2009)*360 + timeTextSet[i].month*30 + timeTextSet[i].day;
      indicatorX = map(days, 11*30, 1080+11*30, _x0, _x1);      
    }
  }
  
  
  if (indicatorX < _x0){
    indicatorX = _x0;
  }

  
  // to change the alpha of the text box
  if (ROLLOVER_STATE == 1) {
    if (timeBox_alpha < 255) {
      timeBox_alpha+=TIMEBOX_ALPHASPEED;
    }
  } 
  else {
    if (timeBox_alpha > 0) {
      timeBox_alpha-=TIMEBOX_ALPHASPEED;
    }
  }

  //to calculate the position of the box
  float textLength = textWidth(currDetail);
  float boxWidth = _x1 - _x0;
  float boxHeight = ceil(textLength/boxWidth)*TEXTLINE_SPACE+3;
  float boxPosX = _x0;
  float boxPosY = _y - boxHeight - BOX_ADJUST_Y;

  //to draw the box and text
  noStroke();
  fill(0, timeBox_alpha*2);
  rect(boxPosX, boxPosY, boxWidth, boxHeight);
  fill(160, timeBox_alpha);
  textLeading(TEXTLINE_SPACE);
  text(currDetail, boxPosX, boxPosY, boxWidth, boxHeight);
  fill(255, 0, 0, timeBox_alpha);
  ellipse(indicatorX, _y+15, 8, 8);
  noFill();
}


void timelineRollOver(float _x, float _y) {
  int areaExpand = 60;
  int areaAdjust_Y = 5;

  ROLLOVER_STATE = 0;
  if (mouseX > _x-areaExpand/2 && mouseX < _x+areaExpand/2) {
    if (mouseY > _y-areaExpand/2 +areaAdjust_Y && mouseY < _y+areaExpand/2 +areaAdjust_Y) {
      ROLLOVER_STATE = 1;
    }
  }

  //  to check the area
  /*
  fill(255, 0, 0, 100);
   rect(_x - areaExpand/2, _y-areaExpand/2 + areaAdjust_Y, areaExpand, areaExpand);
   noFill();
   */
}

