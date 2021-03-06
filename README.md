# Zimbra Build Scripts

The following scripts are for use with Zimbra's Github repository: https://github.com/zimbra/zm-build

The scripts created here are based on the zm-build documentation, and are to help make things much easier for you.  The scripts automatically detect your distribution, installs dependencies, and builds Zimbra without you having to do anything else manually.  So far it supports the distributions below:

* CentOS 7/8
* Ubuntu 16.04/18.04

There is also a pre-configured ```config.build``` which will build ```Zimbra 9.0.0 OSE/FOSS```

For future Zimbra 9.x releases, all that will be required is to adapt the contents of ```config.build``` with the appropriate version numbers (or download a particular release [here](https://github.com/ianw1974/zimbra-build-scripts/releases):

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

If you have any issues/problems when using the scripts, please open an [issue](https://github.com/ianw1974/zimbra-build-scripts/issues) so that I can help resolve it.

## What's working

I have tested with all versions supported by these scripts, and successfully built Zimbra.

## Preparation

You will need a github account, as the Zimbra build process needs to connect to github via SSH.  Therefore, you will need to generate an SSH key if you don't have one, and then upload the contents of ```id_rsa.pub``` here: https://github.com/settings/keys

Please do not attempt to build Zimbra without completing this step, as it simply won't work.

You can create a key by doing this:

```
ssh-keygen -t rsa -b 4096 -C "your_email@address"
```

the email address needs to be the one used for your github account.

Make sure that there are no other versions of JRE/JDK installed on your build server as these will conflict with openjdk-8 which Zimbra uses.

Now clone this repository:

```
git clone https://github.com/ianw1974/zimbra-build-scripts
cd zimbra-build-scripts
```

now you can run the scripts.

## Installing the dependencies

Install the dependencies by running:

```
./01-install-build-deps.sh
```

this will detect the distribution and version you are running, and run the appropriate commands to install the build dependencies.

## Building Zimbra

First edit the ```config.build``` if necessary as this will build ```9.0.0``` by default.  This will ensure you are building for the version you want.
By default, ```02-build-zimbra.sh``` will create and build under ```/home/git/zimbra``` and everything related to the build will be located here.  This ensures your system stays tidy during the build process (everything will be placed under /home/git/zimbra - about 59+ directories).  If you really want to build it somewhere else then edit the script and change the variables as seen below:

```
# Variables
MAINDIR=/home/git
PROJECTDIR=zimbra
```

only change these if you really, really need to, otherwise the build process might fail if the two values above are incorrectly supplied, or you put on a partition that doesn't have enough disk space to build Zimbra.  Please also note, if you git pull my repository in the future, the changes you made will disappear and will need to be made again before you attempt to build.  This functionality exists for the advanced user who would like a bit of customisation.

Once you have done all the changes you need, build Zimbra by running:

```
./02-build-zimbra.sh
```

The script will automatically clone https://github.com/zimbra/zm-build so you don't need to do this.  Then the script patches ```zimbra/zm-build/instructions/bundling-scripts/zimbra-store.sh``` because of a failure for non-existant directory ```convertd```.  This may not be needed in the future if Synacor fix their build script.  The patch fixes the script to create it before building.

After the patch has been applied, it builds Zimbra.

At the end, you will find the created Zimbra archive file under ```/home/git/zimbra/.staging/UBUNTU18_64-KEPLER-900-20201013092939-FOSS-1/zm-build/zcs-9.0.0_GA_1.UBUNTU18_64.20201013092939.tgz``` if building for Ubuntu 18.04.  The directory name and archive file name will vary if building for different distributions.

You can then unpack this archive file and install/upgrade Zimbra in the usual manner.

# Disclaimer

Please note I cannot be held responsible for misuse of this script or any adverse affects on your system. The scripts are provided as-is.

Zimbra is a Synacor copyright/trademark.  I am in no way associated or related with Zimbra or Synacor, I am just a long-time user of Zimbra who likes to support the community where I possibly can.
