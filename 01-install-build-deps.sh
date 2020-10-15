#!/bin/bash
#
# Install build dependencies based on distro
#
# Supports:
#     Ubuntu 18.04
#     Ubuntu 16.04
#     CentOS 8
#     CentOS 7
#
# Required dependencies: lsb-release

# Check if running as root
if [ "$UID" == "0" ]
then
  echo "Running as root, all looking good."
else
  echo "Please run this script as root!."
  exit 1
fi

# Get DISTRIB_ID, install lsb_release package
# if necessary
if [ -f "/usr/bin/lsb_release" ]
then
  DISTRIB_ID=`lsb_release -i | awk '{print $3}'`
else
  if [ -f "/etc/redhat-release" ]
  then
    yum install -y redhat-lsb
  else
    apt-get install -y lsb-release
  fi
  DISTRIB_ID=`lsb_release -i | awk '{print $3}'`
fi

# Start installing dependencies

if [ $DISTRIB_ID == "Ubuntu" ]
then
  # Get release information
  DISTRIB_RELEASE=`lsb_release -r | awk '{print $2}'`

  # Check if running supported version and install dependencies
  # or inform user of unsupported version and exit
  if [ $DISTRIB_RELEASE == "16.04" ] || [ $DISTRIB_RELEASE == "18.04" ]
  then
    apt-get install -y software-properties-common openjdk-8-jdk ant ant-optional ant-contrib ruby git maven build-essential debhelper
  else
    echo "You are running an unsupported Ubuntu release!"
    exit 1
  fi
elif [ $DISTRIB_ID == "CentOS" ]
then
  # Get release information
  DISTRIB_RELEASE=`lsb_release -r | awk '{print $2}' | cut -f1 -d "."`

  # Check if running supported version and install dependencies
  # or inform user of unsupported version and exit
  if [ $DISTRIB_RELEASE == "7" ]
  then
    yum groupinstall -y 'Development Tools'
    yum install -y java-1.8.0-openjdk ant ant-junit ruby git maven cpan wget perl-IPC-Cmd rpm-build createrepo
  elif [ $DISTRIB_RELEASE == "8" ]
  then
    dnf group install -y "Development Tools"
    dnf module enable -y javapackages-tools
    dnf install -y java-1.8.0-openjdk gcc-c++ ant-junit ruby git maven cpan wget rpm-build createrepo
  else
    echo "You are running an unsupported CentOS release!"
    exit 1
  fi
else
  echo "Unsupported distribution!"
  echo "This script only supports CentOS 7/8 and Ubuntu 16.04/18.04"
  exit 1
fi

# Dependencies completed
echo "Dependencies installed.  Copy config.build to zm-build directory."
echo "Edit config.build with appropriate parameters for your build!"
