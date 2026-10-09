FROM tomcat:10.1-jdk17-temurin
RUN rm -rf /usr/local/tomcat/webapps/*
RUN mkdir -p /usr/local/tomcat/webapps/ROOT/WEB-INF/lib /usr/local/tomcat/webapps/ROOT/WEB-INF/classes
COPY *.jsp *.jspf *.css *.js /usr/local/tomcat/webapps/ROOT/
COPY web.xml /usr/local/tomcat/webapps/ROOT/WEB-INF/web.xml
COPY *.java /tmp/
RUN curl -fsSL -o /usr/local/tomcat/webapps/ROOT/WEB-INF/lib/gson.jar https://repo1.maven.org/maven2/com/google/code/gson/gson/2.10.1/gson-2.10.1.jar \
 && javac -cp /usr/local/tomcat/webapps/ROOT/WEB-INF/lib/gson.jar:/usr/local/tomcat/lib/servlet-api.jar -d /usr/local/tomcat/webapps/ROOT/WEB-INF/classes /tmp/*.java
EXPOSE 8080
