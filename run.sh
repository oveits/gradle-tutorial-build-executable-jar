#!/usr/bin/env bash

java -jar -Dlog4j.configuration=file:`pwd`/log4j.properties build/libs/dateUtils-1.0-SNAPSHOT.jar
