# Uncomment the distro that you wish to build for
#ARG RELEASE=almalinux:8.6
#ARG RELEASE=oraclelinux:8.6
#ARG RELEASE=rockylinux:8.6
ARG RELEASE=ubuntu:18.04

# DO NOT EDIT BELOW THIS LINE

# Let's build for the version set above
FROM $RELEASE

# Install some necessary dependencies
RUN if [ -f "/usr/bin/apt-get" ]; then apt-get update && apt-get -y install git lsb-release; fi
RUN if [ -f "/usr/bin/dnf" ]; then dnf -y install dnf-plugins-core git redhat-lsb-core; fi

# Clone Zimbra Build Scripts
RUN git clone https://github.com/ianw1974/zimbra-build-scripts /home/git/zimbra-build-scripts
WORKDIR /home/git/zimbra-build-scripts

# Remove sudo from build script
RUN sed -i 's/sudo\ //g' ./zimbra-build-helper.sh

# Install dependencies
RUN ./zimbra-build-helper.sh --install-deps

# Volume to retrieve builds
VOLUME /home/git/zimbra/BUILDS/

# Build Zimbra
ENTRYPOINT ["/home/git/zimbra-build-scripts/zimbra-build-helper.sh", "--build-zimbra"]
