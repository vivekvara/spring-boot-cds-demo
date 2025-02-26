#!/bin/sh

IMAGE_TAG=$(date +%s)
IMAGE_TARGET_TAG=latest

docker image rm spring-boot-cds-prebuild spring-boot-cds-backport

mkdir -p ${PWD}/src/main/jib/appcds

echo "Building the prebuild image, the tag is: $IMAGE_TAG"
./mvnw package jib:dockerBuild -Djib.to.image=spring-boot-cds-prebuild -Djib.to.tags=$IMAGE_TAG -Djib.containerizingMode=packaged -Dmaven.test.skip=true

#echo "Running the prebuild image to prepare the CDS class list"
#docker run -w /app -ti --entrypoint=/usr/bin/java \
#  -v ${PWD}/src/main/jib/appcds:/appcds spring-boot-cds-prebuild -Xlog:cds -XX:DumpLoadedClassList=/appcds/classes.lst \
#  -cp "@jib-classpath-file" com.example.appcdsdemo.CdsDemoApplication --appcds=true

echo "Running the prebuild image to prepare the CDS archive" #  -Xshare:dump -XX:SharedClassListFile=/appcds/classes.lst
docker run -w /app -ti --entrypoint=/usr/bin/java \
  -v ${PWD}/src/main/jib/appcds:/appcds spring-boot-cds-prebuild -Xlog:cds -XX:ArchiveClassesAtExit=/appcds/appcds.jsa \
  -Dspring.context.exit=onRefresh \
  -cp "@jib-classpath-file" com.example.appcdsdemo.CdsDemoApplicationcc

echo "Building the final image, the tag is: $IMAGE_TAG"
./mvnw package jib:dockerBuild \
  -Djib.to.image=spring-boot-cds-backport \
  -Djib.container.jvmFlags="-Xshare:on,-Xlog:cds,-XX:SharedArchiveFile=/appcds/appcds.jsa" \
  -Djib.containerizingMode=packaged \
  -Djib.to.tags=$IMAGE_TAG,$IMAGE_TARGET_TAG -Dmaven.test.skip=true

echo "Image has been built, the tag is: $IMAGE_TAG"