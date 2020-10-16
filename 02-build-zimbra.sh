#!/bin/bash
#
# Script to build Zimbra

# Variables
MAINDIR=/home/git
PROJECTDIR=zimbra

USERID=`echo $USER`

if [ -d "$MAINDIR" ]
then
  echo "$MAINDIR directory exists, continuing..."
else
  sudo mkdir $MAINDIR
  sudo chown $USERID:$USERID $MAINDIR
fi

if [ -d "$MAINDIR/$PROJECTDIR" ]
then
  echo "$PROJECTDIR directory exists, continuing..."
else
  sudo mkdir $MAINDIR/$PROJECTDIR
  sudo chown $USERID:$USERID $MAINDIR
fi

cp config.build $MAINDIR/$PROJECTDIR
cp zimbra-store.patch $MAINDIR/$PROJECTDIR
cd $MAINDIR/$PROJECTDIR
git clone https://github.com/zimbra/zm-build
cd zm-build
git checkout origin/develop
cd ..
cp config.build $MAINDIR/$PROJECTDIR/zm-build

# Patch zimbra-store.sh to fix issue when convertd directory doesn't exist
# else build will fail
patch $MAINDIR/$PROJECTDIR/zm-build/instructions/bundling-scripts/zimbra-store.sh zimbra-store.patch

# Change to build directory and build Zimbra
cd $MAINDIR/$PROJECTDIR/zm-build
./build.pl

# Inform where archive can be found
echo -e "\nZimbra archive file can be found under $MAINDIR/$PROJECTDIR/.staging\n"
