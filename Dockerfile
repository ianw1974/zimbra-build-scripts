FROM ubuntu:18.04

RUN apt update && apt -y install git lsb-release
RUN git clone https://github.com/ianw1974/zimbra-build-scripts /home/git/zimbra-build-scripts
# FIXME work as regular user instead of root?
WORKDIR /home/git/zimbra-build-scripts
# Docker image doesn't contain sudo, strip it away from the script
RUN sed -i 's/sudo\ //g' ./zimbra-build-helper.sh
RUN ./zimbra-build-helper.sh --install-deps

VOLUME /home/git/zimbra/BUILDS/

ENTRYPOINT ["/home/git/zimbra-build-scripts/zimbra-build-helper.sh", "--build-zimbra"]
