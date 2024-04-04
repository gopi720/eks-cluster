#!/bin/bash
set -e
nohup u01/anitha/apache-tomcat-9.0.87/bin/startup.sh &
exec $@