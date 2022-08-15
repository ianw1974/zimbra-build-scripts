ARG RELEASE=ubuntu:18.04
FROM $RELEASE

RUN if [ -f "/usr/bin/apt" ]; then apt update && apt -y install git lsb-release; fi
RUN if [ -f "/usr/bin/yum" ]; then yum -y install git redhat-lsb-core; fi
ARG USER=zimbra
#ARG PASS="some password"
#RUN useradd -m -d /home/git -s /bin/bash $USER 
#USER $USER
RUN git clone https://github.com/ianw1974/zimbra-build-scripts /home/git/zimbra-build-scripts
WORKDIR /home/git/zimbra-build-scripts
RUN sed -i 's/sudo\ //g' ./zimbra-build-helper.sh
RUN ./zimbra-build-helper.sh --install-deps

VOLUME /home/git/zimbra/BUILDS/

ENTRYPOINT ["/home/git/zimbra-build-scripts/zimbra-build-helper.sh", "--build-zimbra"]
