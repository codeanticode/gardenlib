// Basic date type with functionality to move month by month, etc. 
// Adapted from:
// http://www.roseindia.net/tutorial/java/core/implementDateclass.html
class Date {
  int[] DAYS = { 
    0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
  }; // 0 because months are counted from 1.
  int[] DOW  = {     
    0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4
  };
  String[] MONTH_SHORT_NAMES = { 
    "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  };
  String[] MONTH_FULL_NAMES = { 
    "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"
  }; 

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
    } 
    if (m == 2 && d == 29 && !isLeapYear(y)) {
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