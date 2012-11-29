// Garden Library project
// Romy Achituv, Andres Colubri
//
// This is the Jetty server that queries the data in the MySQL database and creates
// the plain text files that the client app reads from.
// 
// Version 004 (October 15th, 2012)
// Changes:
// * Reads the language Colors and items ISBNs

import java.io.*;
import java.util.*;
import java.sql.*;

import javax.servlet.*;
import javax.servlet.http.*;

import com.mysql.jdbc.Driver;

public class UpdateServlet extends HttpServlet {
  static final int PORT = 3306;
  protected HashSet<String> commonLang;
     
  protected void doGet(HttpServletRequest req, HttpServletResponse resp)
    throws ServletException, IOException {
    String action = req.getParameter("action");
        
    if (action.equals("run")) {
      String host = "localhost";
      String dbname = "gardenlib";
      String user = "root"; 
      String pass = "";
      String url = "jdbc:mysql://" + host + ":" + PORT + "/" + dbname;
      try {
        String log = "UPDATE PROCESS:<br>";
        String appPath = getServletContext().getRealPath("/app");              
              
        Class.forName("com.mysql.jdbc.Driver");
        Connection connection = DriverManager.getConnection(url, user, pass); 
        Statement statement = connection.createStatement();

        log += "Updating emotions...";
        updateEmotions(resp, statement, appPath);
        log += "done<br>";        
        
        log += "Updating languages...";
        loadCommonLanguages(statement);
        updateLanguages(resp, statement, appPath);
        log += "done<br>";

        log += "Updating books...";
        updateBooks(resp, statement, appPath);
        log += "done<br>";

        log += "Updating history...";
        updateHistory(resp, statement, appPath);
        log += "done<br>";
        
        log += "UPDATE COMPLETED";   
        createPage(resp, log);        
      } catch (Exception e) {
        StackTraceElement[] stackTrace = e.getStackTrace();
        String error = e.toString();
        for (int i = 0; i < stackTrace.length; i++) {
          error += "\n" + stackTrace[i].toString();
        }
        createPage(resp, error);
      }
    } else {
      createPage(resp, "Nothing to be done.");
    }
  }

  protected void doPost(HttpServletRequest req, HttpServletResponse resp)
    throws ServletException, IOException {
    String field = req.getParameter("field");
    createPage(resp, "You entered \"" + field + "\" into the text box.");
  }
  
  protected void updateEmotions(HttpServletResponse resp, Statement stat, String path) 
    throws java.sql.SQLException, IOException {    
    String result = "";        
    stat.execute("SELECT * FROM Emotions");
    ResultSet res = stat.getResultSet();
    while (res.next()) {
      String emoId = getStringData(res, 1);
      String emoName = getStringData(res, 2);
      String emoColor = getStringData(res, 3);
      result += emoId + "\t" + emoName + "\t" + emoColor + "\n";
    }
    String fn = path + "/emotions.txt";
    createFile(resp, fn, result); 
  }
  
  protected void loadCommonLanguages(Statement stat) 
    throws java.sql.SQLException {    
    commonLang = new HashSet<String>();
    String result = "";        
    stat.execute("SELECT cmnLangId FROM CommonLanguages");
    ResultSet res = stat.getResultSet();
    while (res.next()) {
      String lngId = getStringData(res, 1);
      commonLang.add(lngId);
    }    
  }
  
  protected void updateLanguages(HttpServletResponse resp, Statement stat, String path) 
    throws java.sql.SQLException, IOException {    
    String result = "";        
    stat.execute("SELECT * FROM Languages");
    ResultSet res = stat.getResultSet();
    while (res.next()) {
      String lngId = getStringData(res, 1);
      if (commonLang.contains(lngId)) {
        String lngCode = getStringData(res, 2);
        String lngTitle = getStringData(res, 3);
        String lngColor = getStringData(res, 4);
        result += lngId + "\t" + lngCode + "\t" + lngTitle + "\t" + lngColor + "\n";
      }
    }
    String filename = path + "/languages.txt";
    createFile(resp, filename, result);    
  }
    
  protected void updateBooks(HttpServletResponse resp, Statement stat, String path) 
    throws java.sql.SQLException, IOException {    
    String result = "";        
    stat.execute("SELECT itmId, itmBarcode, itmAuthor, itmTitle, itmLanguage, itmISBN FROM Items");
    ResultSet res = stat.getResultSet();
    while (res.next()) {
      String itmId = getStringData(res, 1);
      String itmBarcode = getStringData(res, 2);
      String itmAuthor = getStringData(res, 3);
      String itmTitle = getStringData(res, 4);
      String itmLanguage = getStringData(res, 5);      
      String itmISBN = getStringData(res, 6);      
      result += itmId + "\t" + itmBarcode + "\t" + itmAuthor + "\t" + itmTitle + "\t" + itmLanguage + "\t" + itmISBN + "\n";
    }
    String fn = path + "/books.txt";
    createFile(resp, fn, result); 
  }
  
  protected void updateHistory(HttpServletResponse resp, Statement stat, String path) 
    throws java.sql.SQLException, IOException {    
    String result = "";        
    stat.execute("SELECT chkItemId, chkReturnTimestamp, chkEmotionalScore From Checkouts");
    ResultSet res = stat.getResultSet();
    while (res.next()) {    
      String chkItemId = getStringData(res, 1);
      String chkReturnTimestamp = getStringData(res, 2); 
      String chkEmotionalScore = getStringData(res, 3);
      result += chkItemId + "\t" + chkReturnTimestamp + "\t" + chkEmotionalScore + "\n";
    }
    String fn = path + "/history.txt";
    createFile(resp, fn, result);  
  }
  
  protected String getStringData(ResultSet res, int idx) 
    throws java.sql.SQLException {
    String data = res.getString(idx);
    if (data == null) {
      return "NULL";
    } else {
      data = data.trim();
      if (data.equals("")) {
        return "NULL";
      } else {
        return data;
      }
    }
  }
  
  protected void createFile(HttpServletResponse resp, String fn, String txt)
    throws IOException {
    FileWriter fstream = new FileWriter(fn);
    BufferedWriter out = new BufferedWriter(fstream);
    out.write(txt);
    out.close();
  }
  
  protected void createPage(HttpServletResponse resp, String msg) 
    throws IOException {
    PrintWriter out = resp.getWriter();
    out.println("<html>");
    out.println("<body>");
    out.println(msg);
    out.println("</body>");
    out.println("</html>");       
  }  
}