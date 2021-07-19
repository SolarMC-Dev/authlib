#!/bin/bash

JAR_PATH=$1
MODULE_NAME=$2
JDK_VERSION=$3
PROJECT_VERSION=$4
EXTRA_COMPILER_ARGS=$5

MULTI_RELEASE=$JDK_VERSION

echo "Extra compiler arguments: $EXTRA_COMPILER_ARGS"

mkdir -p target/module-gen/

JAR_PATH_ORIGINAL=$JAR_PATH
JAR_PATH_MODULAR="target/module-gen/$MODULE_NAME.jar"

mv $JAR_PATH $JAR_PATH_MODULAR
JAR_PATH=$JAR_PATH_MODULAR

# Generate module-info.java
jdeps --module-path target/dependency/ --multi-release $MULTI_RELEASE --generate-module-info target/module-gen $JAR_PATH

MODULE_INFO_JAVA="target/module-gen/$MODULE_NAME/versions/$MULTI_RELEASE/module-info.java"

# Open packages to Gson
sed -i '2i opens com.mojang.authlib.yggdrasil.request to com.google.gson;' $MODULE_INFO_JAVA
sed -i '2i opens com.mojang.authlib.yggdrasil.response to com.google.gson;' $MODULE_INFO_JAVA

# Compile module-info.java
javac --module-path target/dependency/ $EXTRA_COMPILER_ARGS --release $JDK_VERSION --patch-module $MODULE_NAME=$JAR_PATH $MODULE_INFO_JAVA

# Reseal jar
cd target/module-gen/$MODULE_NAME/versions/$MULTI_RELEASE/
echo "Creating final jar"
ls -la $PWD
UPPER_JAR_PATH="../../../../../$JAR_PATH"
jar --update --file $UPPER_JAR_PATH --module-version=$PROJECT_VERSION -C . module-info.class
cd ../../../../../

mv $JAR_PATH $JAR_PATH_ORIGINAL
