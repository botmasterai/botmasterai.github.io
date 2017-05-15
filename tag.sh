#!/bin/bash
if [ $# -ne 1 ]
  then echo -e "ERROR: tag needs to be run with exaclty one tag name"
  exit 1
fi

echo -e "Adding tag $1"

git tag $1

yarn build

cp -r documentation/latest documentation/$1