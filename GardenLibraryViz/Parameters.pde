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
int bookshelfTop   = 10; //0;
float langBarWAll  =  2;//10;//20; 

float langBarWAllB  = 10;//20;// added for Bookshelf

float langBarWLang =  10;//20;
float langBarWBook =  10;//15;
float bookPadding  =  0.3;//0.4;//0.3;
int   sizeBookView = 100;//40;//40;

float maxBookHeight  = 10;
float bookOutlineW   = 1;

float bookBubbleTailH = 20;// 30; // Height of the tail of the box bubble

// Wheel parameters:
int wheelTop = 20; // 0;
float wheelRadius = 200; //230;
int trailLength = 50;
float wheelDispEmo = 200;   // How much the wheel is translated down the Y axis when selecting an emo...
float wheelScaleEmo = 1.3;  // ...and how much it is scaled.
float wheelDispBook = 600;  // Idem when selecting a book...
float wheelScaleBook = 2.0; // ...

// History parameters
float historyTop = 90;// 120;//80;
int emoBandAlpha = 120; // doesn't seem to have any effect
int bookStrokeAlpha = 180;
boolean showSolidEmoHistory = false;

// Increment (in days) for each step of the animation.
int animationIncDays = 7;//28;

// Fonts:
String fontName = "Droid Sans";
//String fontName = "Helvetica";
int fontSize    = 11;

String langFontName = "Droid Sans Bold";
//String langFontName = "Helvetica Bold";
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

