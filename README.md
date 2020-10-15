# Zimbra Build Scripts

The following scripts are for use with Zimbra's Github repository: https://github.com/zimbra/zm-build

The script basically installs all the required dependencies you need for building Zimbra for the following distributions:

* CentOS 7/8
* Ubuntu 16.04/18.04

and with a pre-configured ```config.build``` it will build ```Zimbra 9.0.0 OSE/FOSS```

For future Zimbra 9.x releases, all that will be required is to adapt the contents of ```config.build``` with the appropriate version numbers:

```
BUILD_NO		= 0001
BUILD_RELEASE		= KEPLER
BUILD_RELEASE_NO	= 9.0.0
BUILD_RELEASE_CANDIDATE	= GA
BUILD_TYPE		= FOSS
BUILD_THIRDPARTY_SERVER	= files.zimbra.com
INTERACTIVE		= 0
```

the information that you likely will want to change is ```BUILD_NO```, ```BUILD_RELEASE```, ```BUILD_RELEASE_NO```.  The remaining values shouldn't need to be changed.

## Installing the dependencies

Install the dependencies by running:

```
./01-install-build-deps.sh
```

this will detect the distribution and version you are running, and run the appropriate commands to install the build dependencies.

## Building Zimbra

First edit the ```config.build``` if necessary as this will build ```9.0.0``` by default.  This will ensure you are building for the version you want.
Next, edit ```02-build-zimbra.sh``` and change the directories if required.  By default, it will create and build under ```/home/git/zimbra``` and everything related to the build will be located here.  This ensures your system stays tidy during the build process.  The variables to change are:

```
#!/bin/bash
#
# Script to build Zimbra

# Variables
MAINDIR=/home/git
PROJECTDIR=zimbra
```

these are the only two things you might want to change in this script, unless you are happy with it building in /home/git/zimbra.

Once you have done all the changes you need, build Zimbra by running:

```
02-build-zimbra.sh
```

The script will automatically clone https://github.com/zimbra/zm-build so you don't need to do this.  Then the script patches ```zimbra/zm-build/instructions/bundling-scripts/zimbra-store.sh``` because of a failure for non-existant directory ```convertd```.  This may not be needed in the future if Synacor fix their build script.  The patch fixes the script to create it before building.

After the patch has been applied, it builds Zimbra.

At the end, you will find the created Zimbra archive file under ```/home/git/zimbra/.staging/UBUNTU18_64-KEPLER-900-20201013092939-FOSS-1/zm-build/zcs-9.0.0_GA_1.UBUNTU18_64.20201013092939.tgz``` if building for Ubuntu 18.04.  The directory name and archive file name will vary if building for different distributions.
