# Uncomment the distro that you wish to build for
#ARG RELEASE=almalinux:8.8
#ARG RELEASE=oraclelinux:8.8
#ARG RELEASE=rockylinux:8.8
#ARG RELEASE=ubuntu:18.04
ARG RELEASE=ubuntu:20.04

# DO NOT EDIT BELOW THIS LINE

# Let's build for the version set above
FROM $RELEASE

# Install some necessary dependencies
RUN if [ -f "/usr/bin/apt-get" ]; then apt-get update && apt-get -y install git lsb-release; fi
RUN if [ -f "/usr/bin/dnf" ]; then dnf -y install dnf-plugins-core git redhat-lsb-core; fi

# Clone Zimbra Build Scripts
RUN git clone https://github.com/ianw1974/zimbra-build-scripts /home/git/zimbra-build-scripts
WORKDIR /home/git/zimbra-build-scripts

# Set Zimbra build version
#RUN cp config.build.9 config.build

# Remove sudo from build script
RUN sed -i 's/sudo\ //g' ./zimbra-build-helper.sh

# Install and pre-configure timezone (needed on Ubuntu 20.04)
RUN if [ -f "/usr/bin/apt-get" ]; then DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata ; fi

# Install dependencies
RUN ./zimbra-build-helper.sh --install-deps

# Volume to retrieve builds
VOLUME /home/git/zimbra/BUILDS/

# Build Zimbra
ENTRYPOINT ["/home/git/zimbra-build-scripts/zimbra-build-helper.sh", "--build-zimbra"]
