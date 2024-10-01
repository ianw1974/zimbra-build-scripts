# Zimbra Build Script

# Instructions

The following script is for use with Zimbra's GitHub repository: https://github.com/zimbra/zm-build

Builds created with this build script can be found on my website [here](https://techfiles.online/zimbra/) if you want to save yourself the hassle of building yourself!  Builds on the website will be updated quarterly.

The script created here are based on the zm-build documentation, and are to help make things much easier for you.  The script automatically detect your distribution, installs dependencies, and builds Zimbra without you having to do anything else manually.  So far it supports the distributions below:

* AlmaLinux 8
* CentOS 7/8
* Oracle Enterprise Linux 8
* Red Hat Enterprise Linux 7/8
* Rocky Linux 8
* Ubuntu 20.04 / 22.04 (Ubuntu 22.04 support only for Zimbra 10.1.0 and higher)

There is also a pre-configured ```config.build``` which will build ```Zimbra 9.0.0 OSE/FOSS```

For future Zimbra 9.x releases, all that will be required is to adapt the contents of ```config.build``` with the appropriate version numbers - or download a particular release [here](https://github.com/ianw1974/zimbra-build-scripts/releases):

```
BUILD_NO                = 0001
BUILD_RELEASE           = KEPLER
BUILD_RELEASE_NO        = 9.0.0
BUILD_RELEASE_CANDIDATE = GA
BUILD_TYPE              = FOSS
BUILD_THIRDPARTY_SERVER = files.zimbra.com
INTERACTIVE             = 0
```

the information that you likely will want to change is ```BUILD_NO```, ```BUILD_RELEASE```, ```BUILD_RELEASE_NO```.  The remaining values shouldn't need to be changed.

If you have any issues/problems when using the script, please open an [issue](https://github.com/ianw1974/zimbra-build-scripts/issues) so that I can help resolve it.

## What's working

I have tested with all versions supported by this script, and successfully built Zimbra.

## Preparation

The build server will need at least 4GB ram.  Previously it was possible to build on 2GB, but this now fails for some of the java packages with an error: ```error starting modern compiler```.  Therefore if you see this error, increase the memory of the build server.

You will need a GitHub account, as the Zimbra build process needs to connect to GitHub via SSH.  Therefore, you will need to generate an SSH key if you don't have one, and then upload the contents of ```id_rsa.pub``` here: https://github.com/settings/keys

Please do not attempt to build Zimbra without completing this step, as it simply won't work.

You can create a key by doing this:

```
ssh-keygen -t rsa -b 4096 -C "your_email@address"
```

the email address needs to be the one used for your GitHub account.

Make sure that there are no other versions of JRE/JDK installed on your build server as these will conflict with openjdk-8 which Zimbra uses.  For example on Ubuntu 18.04 by default some OpenJDK-11 packages are installed, so these needs to be removed prior to building.

Now clone this repository:

```
git clone https://github.com/ianw1974/zimbra-build-scripts
cd zimbra-build-scripts
```

now you can run the script.

## Interactive Help

A help parameter ```--help``` has been added to the script so you can reference it to find out what steps need to be done to build Zimbra.  These saves you from having to reference this readme file.  It summarises the steps required, to make sure that you have uploaded an SSH key to your GitHub profile, that any other version of Java has been removed from your system prior to installing dependencies and building Zimbra.

```
./zimbra-build-helper.sh --help

Zimbra Build Helper script!

Valid parameters are as follows:

  --install-deps   - Installs required dependencies
  --build-zimbra   - Builds Zimbra
  --cleanup        - Cleanup previously attempted builds
  --help           - Shows this help screen

At the beginning of the script these variables can be changed if you want:

MAINDIR=/home/git
PROJECTDIR=zimbra

Build summary step-by-step:

  1. Generate ssh key: ssh-keygen -t rsa -b 4096 -C "your_email@address"
  2. Upload this to your GitHub profile: https://github.com/settings/keys
  3. Only OpenJDK 8 can be installed on the build server, remove other versions
  4. Run:./zimbra-build-helper.sh --install-deps
  5. Run:./zimbra-build-helper.sh --build-zimbra
```

Also, if you run the script without passing a parameter, it will display output asking you to use the ```--help``` parameter for more info to help you.

## Installing the dependencies

Install the dependencies by running:

```
./zimbra-build-helper.sh --install-deps
```

this will detect the distribution and version you are running, and run the appropriate commands to install the build dependencies.

## Building Zimbra

First edit the ```config.build``` if necessary as this will build ```9.0.0``` by default.  This will ensure you are building for the version you want.

By default, it will create and build under ```/home/git/zimbra``` and everything related to the build will be located here.  This ensures your system stays tidy during the build process (everything will be placed under /home/git/zimbra - about 59+ directories).  If you really want to build it somewhere else then edit the script and change the variables as seen below:

```
# Variables
MAINDIR=/home/git
PROJECTDIR=zimbra
```

only change these if you really, really need to, otherwise the build process might fail if the two values above are incorrectly supplied, or you put on a partition that doesn't have enough disk space to build Zimbra.  Zimbra needs approximately ```5GB``` of available space to build successfully.

Please note, if you pull my repository in the future, or when downloading a new release, these changes will be lost.  So if you use a custom location/settings to build other than what I have by default, you will need to change this each time you pull/download.

Once you have done all the changes you need, build Zimbra by running:

```
./zimbra-build-helper.sh --build-zimbra
```

Depending on the CPU/RAM available on your build server, the build process could take approximately 1 hour, maybe less.  I built on a server with 4cpu and 8GB of memory in 45 minutes.  This was on a virtual server under OpenStack though, so your mileage may vary.

The script will automatically clone https://github.com/zimbra/zm-build so you don't need to do this.  Then the script patches ```zimbra/zm-build/instructions/bundling-scripts/zimbra-store.sh``` because of a failure for non-existant directory ```convertd```.  This may not be needed in the future if Synacor fix their build script.  The patch fixes the script to create it before building.

After the patch has been applied, it builds Zimbra.

At the end, you will find the created Zimbra archive file under ```/home/git/zimbra/BUILDS/UBUNTU20_64-KEPLER-900-20201013092939-FOSS-0001/zcs-9.0.0_GA_1.UBUNTU20_64.20201013092939.tgz``` if building for Ubuntu 20.04.  The directory name and archive file name will vary if building for different distributions.

You can then unpack this archive file and install/upgrade Zimbra in the usual manner.

## Building with Docker/Podman

A ```Dockerfile``` is provided to build the *builder image*, which can later be used to create a release.

The default ```Dockerfile``` builds an image for ```Ubuntu 20.04```.  To build for other distributions, edit the ```Dockerfile``` and comment/uncomment the version you wish to build for.  An example is shown below:

```
# Uncomment the distro that you wish to build for
#ARG RELEASE=almalinux:8.9
#ARG RELEASE=oraclelinux:8.9
#ARG RELEASE=rockylinux:8.9
ARG RELEASE=ubuntu:20.04
```

for example to build for Rocky Linux 8.6 we comment the Ubuntu line, and uncomment the Rocky Linux line, so it looks like this:

```
# Uncomment the distro that you wish to build for
#ARG RELEASE=almalinux:8.9
#ARG RELEASE=oraclelinux:8.9
ARG RELEASE=rockylinux:8.9
#ARG RELEASE=ubuntu:20.04
```

Build support for CentOS is excluded due to it effectively being EOL.  RHEL is excluded due to requiring subscriptions for enabling repositories - this makes things difficult for the build process.  It may be offered in the future.  Ubuntu 16.04 and 18.04 are excluded due to it being EOL.

Just like when building normally, an SSH key is required to be uploaded to your account.  With the docker/podman commands, we are mounting the ```/root/.ssh``` directory to the docker/podman container - therefore you have to make sure that your SSH key has been generated, uploaded to your GitHub account and placed within this directory.  If not, then the build process within docker/podman will fail.  Follow the steps in the *Preparation* section at the beginning of this README.

To build the image (replace `docker` with `podman` if using the latter):

```
docker build -t zbs .
```

Now we can build Zimbra:

```
docker run --rm -v zbs:/home/git/zimbra/BUILDS -v /root/.ssh:/root/.ssh zbs
```

There are two bind mounts: one for the build output and one for the `~/.ssh` directory containing the key to access GitHub repos.  Since you are most likely using docker/podman as root, the path above should be fine.  Adapt where necessary.  For docker, using the above command will create the volume ```/var/lib/docker/volumes/zbs``` and the builds can be found here later.

Once the volume and build image is no longer needed, they can be removed:

```
docker volume rm zbs
docker image rm zbs
```

# Disclaimer

Please note I cannot be held responsible for misuse of this script or any adverse affects on your system. The script is provided as-is.

Zimbra is a Synacor copyright/trademark.  I am in no way associated or related with Zimbra or Synacor, I am just a long-time user of Zimbra who likes to support the community where I possibly can.
