#!/bin/bash
#
# Script to build Zimbra

# Variables
MAINDIR=/git
PROJECTDIR=zimbra
BUILDDIR=zm-build
BUILDNO="0001"
BUILDTS=`date +'%Y%m%d%H%M%S'`
BUILDREL="KEPLER"
BUILDRELNO="9.0.0"

if [ -d "$MAINDIR" ]
then
  echo "$MAINDIR directory exists, continuing..."
else
  mkdir $MAINDIR
fi

if [ -d "$PROJECTDIR" ]
then
  echo "$PROJECTDIR directory exists, continuing..."
else
  mkdir $MAINDIR/$PROJECTDIR
fi

cd $MAINDIR/$PROJECTDIR
git clone https://github.com/zimbra/zm-build
git checkout origin/develop
cp config.build $MAINDIR/$PROJECTDIR/zm-build/

# Patch zimbra-store.sh to fix issue when convertd directory doesn't exist
# else build will fail
patch $MAINDIR/$PROJECTDIR/zm-build/instructions/bundling-scripts/zimbra-store.sh zimbra-store.patch

# Change to build directory and build Zimbra
cd $MAINDIR/$PROJECTDIR/$BUILDDIR
./build.pl --build-no=$BUILDNO --build-ts=$BUILDTS --build-release=$BUILDREL--build-release-no=$BUILDRELNO --build-release-candidate=GA --build-type=FOSS --build-thirdparty-server=files.zimbra.com --no-interactive

# Inform where archive can be found
echo -e "\nZimbra archive file can be found under $MAINDIR/$PROJECTDIR/.staging\n"
