#!/bin/bash
if [ $# -ne 1 ]
  then echo -e "ERROR: tag needs to be run withexaclty one tag name"
  exit 1
fi

echo -e "Adding tag $1"

git tag $1

yarn build

yarn copy-favicon

cp -r documentation/latest documentation/$1