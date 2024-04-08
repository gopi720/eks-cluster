FROM Ubuntu:20.04
RUN mkdir -p u01/anitha
WORKDIR u01/anitha
RUN apt update -y
RUN apt install -y openjdk-11-jdk
ADD https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.87/bin/apache-tomcat-9.0.87.tar.gz .
RUN  tar -xzvf  apache-tomcat-9.0.87.tar.gz
RUN rm -rf apache-tomcat-9.0.87.tar.gz
COPY target/airtelcare2.war apache-tomcat-9.0.87/webapps
COPY  run.sh .
RUN chmod 755 run.sh
ENTRYPOINT [" ./run.sh "]