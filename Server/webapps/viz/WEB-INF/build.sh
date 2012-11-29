# This script builds the update servlet
javac -cp lib/servlet-api-3.0.jar:lib/mysql-connector-java-5.1.21-bin.jar src/UpdateServlet.java
cp src/UpdateServlet.class classes
