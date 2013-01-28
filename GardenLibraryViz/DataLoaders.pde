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
  Emotion emo = new Emotion(0, "none", 0xffffffff);
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

void loadTimeText() {
  String details[] = loadStrings(newsFilename); 
  timeTextSet = new TimeText[details.length];
  for (int i = 0; i < details.length; i++) {
    String[] parts = split(details[i], "\t");
    String dateStr = parts[0];
    String detStr = parts[1];
    
    String[] ddmmyyyy = split(dateStr, " ");
    int dd = parseInt(ddmmyyyy[0]);
    int mm = parseInt(ddmmyyyy[1]);
    int yyyy = parseInt(ddmmyyyy[2]);
    TimeText timeTxt = new TimeText(dd, mm, yyyy); 
    timeTextSet[i] = timeTxt;
    timeTextSet[i].setDetail(detStr);
  }
}

void loadWebLinks() {
  String[] data = loadStrings(linksFilename); 

  String defURL = "";

  for (String row: data) {
    String[] parts = split(row, '\t');
    if (parts[0].equals("DEFAULT")) {
      defURL = parts[1];
    } 
    else {
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

