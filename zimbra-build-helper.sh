#!/bin/bash
#
##################################
# Zimbra Build Helper Script     #
# Prepared By: Ian Walker        #
# Version: 1.0.7                 #
#                                #
# Supports:                      #
#     AlmaLinux 8                #
#     CentOS 7/8                 #
#     Oracle Linux 8             #
#     RHEL Enterprise Server 7/8 #
#     Rocky Linux 8              #
#     Ubuntu 16.04/18.04         #
##################################

#############
# Variables #
#############
MAINDIR=/home/git
PROJECTDIR=zimbra

#########################################
# DON"T EDIT ANYTHING BELOW THESE LINES #
#########################################

# Supported distros variable
DISTROS="AlmaLinux 8, CentOS 7/8, Oracle Linux 8, RHEL 7/8, Rocky Linux 8, Ubuntu 16.04/18.04"

#############
# Functions #
#############

install_dependencies() {
  # Get DISTRIB_ID, install lsb_release package if necessary
  if [ -f "/usr/bin/lsb_release" ]
  then
    DISTRIB_ID=`lsb_release -i | awk '{print $3}'`
  else
    if [ -f "/etc/redhat-release" ]
    then
      sudo yum install -y redhat-lsb
    else
      sudo apt-get install -y lsb-release
    fi
    DISTRIB_ID=`lsb_release -i | awk '{print $3}'`
  fi

  # Start installing dependencies
  if [ ${DISTRIB_ID} == "Ubuntu" ]
  then
    # Get release information
    DISTRIB_RELEASE=`lsb_release -r | awk '{print $2}'`

    # Check if running supported version and install dependencies or inform user of unsupported version and exit
    if [ ${DISTRIB_RELEASE} == "16.04" ] || [ ${DISTRIB_RELEASE} == "18.04" ]
    then
      deb_pkg_install
    else
      echo "You are running an unsupported Ubuntu release!"
      exit 1
    fi
  elif [ ${DISTRIB_ID} == "CentOS" ] || [ ${DISTRIB_ID} == "OracleServer" ] || [ ${DISTRIB_ID} == "RedHatEnterpriseServer" ] || [ ${DISTRIB_ID} == "RedHatEnterprise" ] || [ ${DISTRIB_ID} == "Rocky" ] || [ ${DISTRIB_ID} == "AlmaLinux" ]
  then
    # Get release information
    DISTRIB_RELEASE=`lsb_release -r | awk '{print $2}' | cut -f1 -d "."`

    # Check if running supported version and install dependencies or inform user of unsupported version and exit
    if [ ${DISTRIB_RELEASE} == "7" ] && [ ${DISTRIB_ID} == "CentOS" ] || [ ${DISTRIB_ID} == "RedHatEnterpriseServer" ]
    then
      el7_pkg_install
    elif [ ${DISTRIB_RELEASE} == "8" ] && [ ${DISTRIB_ID} == "CentOS" ] || [ ${DISTRIB_ID} == "Rocky" ] || [ ${DISTRIB_ID} == "AlmaLinux" ]
    then
      el8_pkg_install
      is_ant_excluded
    # Check if running RHEL8
    elif [ ${DISTRIB_RELEASE} == "8" ] && [ ${DISTRIB_ID} == "RedHatEnterprise" ]
    then
      # Import Rocky Powertools - Rocky follows RHEL8 development - needed for javapackages-tools module + ant-junit
      # and create Rocky-PowerTools.repo of which RHEL8 doesn't have
      sudo curl -s http://dl.rockylinux.org/pub/rocky/RPM-GPG-KEY-rockyofficial -o /etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
      sudo echo "${ROCKY_POWERTOOLS}" > /etc/yum.repos.d/Rocky-PowerTools.repo
      sudo dnf update -y
      el8_pkg_install
      is_ant_excluded
    # Check if running Oracle Linux
    elif [ ${DISTRIB_RELEASE} == "8" ] && [ ${DISTRIB_ID} == "OracleServer" ]
    then
      oel8_pkg_install
    else
      echo "You are running an unsupported AlmaLinux/CentOS/Oracle/RHEL/Rocky release!"
      exit 1
    fi
  else
    echo "Unsupported distribution!"
    echo "This script only supports: ${DISTROS}"
    exit 1
  fi
}

# Installs dependencies for Ubuntu
deb_pkg_install() {
  sudo apt-get install -y software-properties-common openjdk-8-jdk ant ant-optional ant-contrib ruby git maven build-essential rsync wget debhelper
}

# Installs dependencies for EL7
el7_pkg_install() {
  sudo yum groupinstall -y 'Development Tools'
  sudo yum install -y java-1.8.0-openjdk ant ant-junit ruby git maven cpan wget perl-IPC-Cmd rpm-build createrepo
}

# Installs dependencies for EL8
el8_pkg_install() {
  sudo dnf group install -y "Development Tools"
  sudo dnf config-manager --set-enabled powertools
  sudo dnf module enable -y javapackages-tools
  sudo dnf install -y java-1.8.0-openjdk gcc-c++ ant-junit ruby git maven cpan wget rpm-build createrepo rsync
}

#Installs dependencies for OEL8
oel8_pkg_install() {
  sudo dnf group install -y "Development Tools"
  sudo dnf config-manager --set-enabled ol8_codeready_builder
  sudo dnf module enable -y javapackages-tools
  sudo dnf install -y java-1.8.0-openjdk gcc-c++ ant-junit ruby git maven cpan wget rpm-build createrepo rsync
}

# Fixes ant ant-lib dependency problem between packages and modules
is_ant_excluded() {
  IS_ANT_EXCLUDE=`cat /etc/dnf/dnf.conf | grep -c "exclude=ant ant-lib"`
  if [ ${IS_ANT_EXCLUDE} = 0 ]
  then
    sudo echo "exclude=ant ant-lib" >> /etc/dnf/dnf.conf
  fi
}

build_zimbra() {
  # Get current userid - we need this if using sudo to fix directory permissions
  USERID=`echo ${USER}`

  # Check if ${MAINDIR} exists, if not create it and set permissions
  if [ -d "${MAINDIR}" ]
  then
    echo "${MAINDIR} directory exists, continuing..."
  else
    sudo mkdir ${MAINDIR}
    sudo chown ${USERID}:${USERID} ${MAINDIR}
  fi

  # Check if ${MAINDIR}/${PROJECTDIR} exists and remove existing build in preparation for new build
  # or if it doesn't exist, then create it and set permissions
  if [ -d "${MAINDIR}/${PROJECTDIR}" ]
  then
    echo "${PROJECTDIR} directory exists, cleaning up existing content..."
    rm -rf ${MAINDIR}/${PROJECTDIR}/.staging
    for DIR in `ls ${MAINDIR}/${PROJECTDIR}`
    do
      rm -rf ${MAINDIR}/${PROJECTDIR}/$DIR
    done
  else
    sudo mkdir ${MAINDIR}/${PROJECTDIR}
    sudo chown ${USERID}:${USERID} ${MAINDIR}/${PROJECTDIR}
  fi

  # Start preparing for build
  cp config.build ${MAINDIR}/${PROJECTDIR}
  cp zimbra-store.patch ${MAINDIR}/${PROJECTDIR}
  cp zimbra-rocky.patch ${MAINDIR}/${PROJECTDIR}
  cp zimbra-alma.patch ${MAINDIR}/${PROJECTDIR}
  cp zimbra-repo.patch ${MAINDIR}/${PROJECTDIR}
  cd ${MAINDIR}/${PROJECTDIR}
  git clone https://github.com/zimbra/zm-build
  cp config.build ${MAINDIR}/${PROJECTDIR}/zm-build

  # Patch zimbra-store.sh to fix issue when convertd directory doesn't exist else build will fail
  patch ${MAINDIR}/${PROJECTDIR}/zm-build/instructions/bundling-scripts/zimbra-store.sh zimbra-store.patch

  # Patch get_plat_tag.sh to enable support for additional distros
  patch ${MAINDIR}/${PROJECTDIR}/zm-build/rpmconf/Build/get_plat_tag.sh zimbra-alma.patch

  # Change to build directory and build Zimbra
  cd ${MAINDIR}/${PROJECTDIR}/zm-build
  ./build.pl

  # Inform where archive can be found or error message if problem with build
  if [ $? == 0 ]
  then
    echo -e "\nZimbra archive file can be found under ${MAINDIR}/${PROJECTDIR}/BUILDS"
    echo -e "You can now unpack this and install/upgrade Zimbra\n"
  else
    echo -e "${YELLOW}\nThere was a problem with the build process, check output above!\n${NORMAL}"
  fi
}

# Config files
ROCKY_POWERTOOLS=$(cat << EOF
[powertools]
name=Rocky Linux $releasever - PowerTools
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=\$basearch&repo=PowerTools-\$releasever
#baseurl=http://dl.rockylinux.org/\$contentdir/\$releasever/PowerTools/\$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
EOF
)

# Help for using the script
help() {
  echo -e "\n${CYAN}Zimbra Build Helper script!\n"
  echo -e "${YELLOW}Valid parameters are as follows:${NORMAL}\n"
  echo -e "  ${GREEN}--install-deps${NORMAL}\t - Installs required dependencies"
  echo -e "  ${GREEN}--build-zimbra${NORMAL}\t - Builds Zimbra"
  echo -e "  ${GREEN}--help${NORMAL}\t\t - Shows this help screen\n"
  echo -e "${CYAN}At the beginning of the script these variables can be changed if you want:${NORMAL}"
  echo -e "${YELLOW}\nMAINDIR=${NORMAL}/home/git\n${YELLOW}PROJECTDIR=${NORMAL}zimbra\n"
  echo -e "${CYAN}Build summary step-by-step:\n${NORMAL}"
  echo -e "  ${YELLOW}1. Generate ssh key:${NORMAL} ssh-keygen -t rsa -b 4096 -C \"your_email@address\""
  echo -e "  ${YELLOW}2. Upload this to your github profile:${NORMAL} https://github.com/settings/keys"
  echo -e "  ${YELLOW}3. Only OpenJDK 8 can be installed on the build server, remove other versions${NORMAL}"
  echo -e "  ${YELLOW}4. Run:${NORMAL}./zimbra-build-helper.sh --install-deps"
  echo -e "  ${YELLOW}5. Run:${NORMAL}./zimbra-build-helper.sh --build-zimbra\n"
}

error() {
  echo -e "\nA parameter is required to run this script!"
  echo -e "Use --help for assistance\n"
}

# Colours
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
NORMAL="\e[0m"

# Set parameter from value provided
PARMS=$1
case ${PARMS} in
  --install-deps)
    install_dependencies
    ;;
  --build-zimbra)
    build_zimbra
    ;;
  --help)
    help
    ;;
  *)
    error
    ;;
esac
