int currentTask = -1;
int currentMode = MODE_BOOKSHELF;
int previousMode;
boolean showingHelp = false; 
boolean showingMigrantInfo = false;

// Data:
ArrayList<Emotion> emotions;  // All the emotions, including the null (0) emotion
ArrayList<Emotion> emotions1; // Only non-null emotions
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
boolean didDrag;

// bookshelf
boolean compactTime;
SoftFloat bookHeightTimer;
Language currLang;
Emotion currEmo;
boolean sortByLang = true;
int numBookBubbleLines;

// wheel
boolean playingAnim;
boolean selectedPlayAnim;
SoftFloat wheelWidth;
SoftFloat wheelRAngle;
SoftFloat wheelYPos;
SoftFloat wheelScale;

// history
float historyCircleX, historyCircleY;
PGraphics[] historyCanvas;

// News timebox
NewsText[] timelineNews;
String[] currNewsText;
float newsX = 0;
boolean newsRollover;
int newsAlpha = 0;

// Info
XML migrantInfo;
XML catalogInfo;

// Global control of alpha and left margin
SoftFloat viewFadeinAlpha; 
SoftFloat viewLeftMargin; 
SoftFloat helpMaskAlpha;

int noMouseActivityCount = 0;
boolean mouseActivity = false;

SelectedBook selBook = null;
SelectedLanguage selLang = null;
SelectedEmotion selEmo = null;

ViewArea viewArea;
ViewMenu viewMenu;
Timeline timeline;
HelpMenu helpMenu;
LegendArea legendArea;
InfoArea infoArea;
ArrayList<InterfaceElement> ui;
HintInfo hintInfo;

PFont defFont;
PFont langFont;
PFont helpFont;
PFont newsFont;
PFont dateFont;
PFont infoFontReg;
PFont infoFontTitle;
PFont infoFontCapt;

float sinLUT[];
float cosLUT[];
float SINCOS_PRECISION = 1.0;
int SINCOS_LENGTH = int((360.0 / SINCOS_PRECISION));

void initialize(int task) {
  if (task == LOADING) {
    strokeCap(RECT);
    strokeJoin(RECT);

    defFont = createFont(fontName, fontSize, false);
    textFont(defFont);

    // The font for the language code in the book bubble looks
    // better with smoothing.
    langFont = createFont(langFontName, langFontSize);

    helpFont = createFont(helpFontName, helpFontSize, false);
    
    newsFont = createFont(newsFontName, newsFontSize, false);

    dateFont = createFont(dateFontName, dateFontSize, false);

    infoFontReg = createFont(infoFontRegName, infoFontRegSize, false);    
    infoFontTitle = createFont(infoFontTitleName, infoFontTitleSize);    
    infoFontCapt = createFont(infoFontCaptName, infoFontCaptSize);

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

    currentTask = LOAD_TIMELINE_NEWS;
  } else if (task == LOAD_TIMELINE_NEWS) { 
    loadTimelineNews();
    
    currentTask = LOAD_INFO_DATA;
  } else if (task == LOAD_INFO_DATA) { 
    loadInfoData();
  
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
    viewRegion = new ViewRegion();
    if (sortByLang) {
      viewRegion.setTarget(0, books.size());
    } else {
      groupBooksByEmotion(int(daysSinceStart.getTarget()), true);
      viewRegion.setTarget(0, numBooksWithEmo());
    }

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
    wheelWidth = new SoftFloat();
    wheelWidth.setTarget(wheelWidthWAll);

    viewFadeinAlpha = new SoftFloat();
    viewFadeinAlpha.set(255);
    viewLeftMargin = new SoftFloat();
    helpMaskAlpha = new SoftFloat();

    numBookBubbleLines = showISBN ? 5 : 4;

    // Create UI    
    viewMenu = new ViewMenu(0, height - 50, 200, 50);
    timeline = new Timeline(200, height - 50, width - 200, 50); 
    viewArea = new ViewArea(20, -8, width, height - 90);
    helpMenu = new HelpMenu(width - 60, 20, 70, 30);
    legendArea = new LegendArea(150, 30, 100, 20, 0, 0, 200, height - 100);
    infoArea = new InfoArea(200, 0, width - 200, height);
    ui = new ArrayList<InterfaceElement>();

    ui.add(legendArea);
    ui.add(helpMenu);
    ui.add(viewArea);        
    ui.add(viewMenu);    
    ui.add(timeline); 
    ui.add(infoArea);

    hintInfo = new HintInfo(600, 30);

    legendArea.open();
    currentTask = RUNNING;

    // Trigger initial fade-in animation.
    viewFadeinAlpha.set(0);
    viewFadeinAlpha.setTarget(255);
    
    historyCanvas = new PGraphics[2];
    historyCanvas[0] = historyCanvas[1] = null;
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