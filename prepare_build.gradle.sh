#!/usr/bin/env bash

[ "$MAINCLASS" == "" ] && MAINCLASS=`grep '<mainClass' pom.xml | cut -f2 -d">" | cut -f1 -d"<"`
if [ "$MAINCLASS" == "" ]; then
  echo MAINCLASS could not be retrieved from the file pom.xml >&2
  exit 1
fi

[ "$DEPENDENCY_JARS" == "" ] && DEPENDENCY_JARS=dependency-jars

# Create backup of build.gradle file
MILLISECONDS=`date +%N | cut -c1-3`; # did not work, but cut -c1-3 has worked: let MILLISECONDS/=1000000
DATETIME=`date +"%Y-%m-%d-%H-%M"`.$MILLISECONDS
cp -p build.gradle build.gradle.bak.$DATETIME

# Remove automatically inserted content from build.gradle, if present
if grep -q "# AUTOMATICALLY INSERTED" build.gradle; then 
  echo "build.gradle already has automatically inserted content. Cleaning now..."
  cat build.gradle | sed '/^# AUTOMATICALLY INSERTED/,/^\# END AUTOMATICALLY INSERTED/d' > build.gradle.tmp
  mv build.gradle.tmp build.gradle
fi

# Prepare to copy dependent Jars 
echo "Preparing to copy dependent Jars"

cat << ENDCOPYJARS >> build.gradle

# AUTOMATICALLY INSERTED
// copy dependency jars to build/libs/$DEPENDENCY_JARS 
task copyJarsToLib (type: Copy) {
    def toDir = "build/libs/$DEPENDENCY_JARS"

    // create directories, if not already done:
    file(toDir).mkdirs()

    // copy jars to lib folder:
    from configurations.compile
    into toDir
}
ENDCOPYJARS

# Prepare the Creation of an executable JAR File
echo "Preparing the Creation of an executable JAR File"

cat << ENDCREATEJAR >> build.gradle

jar {
    // exclude log properties (recommended)
    exclude ("log4j.properties")

    // make jar executable: see http://stackoverflow.com/questions/21721119/creating-runnable-jar-with-gradle
    manifest {
        attributes (
            'Main-Class': '$MAINCLASS',
            // add classpath to Manifest; see http://stackoverflow.com/questions/30087427/add-classpath-in-manifest-file-of-jar-in-gradle
            "Class-Path": '. dependency-jars/' + configurations.compile.collect { it.getName() }.join(' dependency-jars/')
            )
    }
}
ENDCREATEJAR

# Define build Dependencies 
echo "Defining build Dependencies"

cat << ENDDEFINEBUILDDEPENDENCIES >> build.gradle

// always call copyJarsToLib when building jars:
jar.dependsOn copyJarsToLib
# END AUTOMATICALLY INSERTED 
ENDDEFINEBUILDDEPENDENCIES

echo DONE
