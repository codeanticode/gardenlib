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

SoftFloat langBarHB; // added for bookshelf

SoftFloat bookTopHeight;
//SelectedBook selBook;
boolean didDrag;

// bookshelf
boolean compactTime;
SoftFloat bookHeightTimer;
Language currLang;
Emotion currEmo;
boolean groupByLangFirst = true;

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
SelectedEmotion selEmo = null;

ViewArea viewArea;
ViewMenu viewMenu;
GroupMenu groupMenu;
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
  } 
  else if (task == LOAD_EMOTIONS) {
    loadEmotions();

    currentTask = LOAD_LANGUAGES;
  } 
  else if (task == LOAD_LANGUAGES) {
    loadLanguages();
    loadWebLinks();

    currentTask = LOAD_BOOKS;
  } 
  else if (task == LOAD_BOOKS) {
    loadBooks();

    currentTask = GROUP_BY_LANG;
  } 
  else if (task == GROUP_BY_LANG) {
    groupBooksByLanguage();

    currentTask = BUILD_HISTORY;
  } 
  else if (task == BUILD_HISTORY) {
    buildHistory(); 

    currentTask = GROUP_BY_EMO;
  } 
  else if (task == GROUP_BY_EMO) {
    daysSinceStart = new SoftFloat();
    daysSinceStart.setTarget(daysRunningTot);   
    groupBooksByEmotion(daysSinceStart.getInt(), true);

    currentTask = FINISH_INIT;
  } 
  else if (task == FINISH_INIT) {
    // Init viewing range:
    viewRegion = new ViewRegion();
    if (groupByLangFirst) {
      viewRegion.setTarget(0, books.size());
    } 
    else {
      groupBooksByEmotion(int(daysSinceStart.getTarget()), true);
      viewRegion.setTarget(0, numBooksWithEmo());
    }

    viewRegion.zoomLevel = VIEW_ALL;

    bookStrokeWeight = new SoftFloat();
    langBarH = new SoftFloat();
    langBarH.setTarget(langBarWAllB);// added B for height of bookshelf

    //    if (currentMode == MODE_BOOKSHELF){ // doesn't work
    //    langBarH = new SoftFloat();
    //    langBarH.setTarget(langBarWAll);
    //    } else {
    //       langBarH = new SoftFloat();
    //    langBarH.setTarget(langBarWAllB);
    //    
    //    }

    langBarHB = new SoftFloat(); // added for bookshelf
    langBarHB.setTarget(langBarWAllB);


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
    // viewMenu = new ViewMenu(0, height - 50, 250, 50);
    viewMenu = new ViewMenu(20, height - 50, 180, 50);

    groupMenu = new GroupMenu(20, height - 100, 180, 50);

    // timeline = new Timeline(250, height - 50, width - 250, 50);  
    timeline = new Timeline(205, height - 50, width - 200, 50); 

    // viewArea = new ViewArea(0, 50, width, height - 120);  
    viewArea = new ViewArea(0, -8, width, height - 90);

    legendArea = new LegendArea(150, 30, 100, 20, 
    0, 0, 200, height - 100);
    ui = new ArrayList<InterfaceElement>();

    ui.add(viewArea);    
    ui.add(legendArea);// changed view area and legend layers
    ui.add(viewMenu);
    ui.add(groupMenu);    
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

