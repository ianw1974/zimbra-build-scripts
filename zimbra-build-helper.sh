#!/bin/bash
#
##################################
# Zimbra Build Helper Script     #
# Prepared By: Ian Walker        #
# Version: 1.1.8                 #
#                                #
# Supports:                      #
#     AlmaLinux 8                #
#     CentOS 7/8                 #
#     Oracle Linux 8             #
#     RHEL Enterprise Server 7/8 #
#     Rocky Linux 8              #
#     Ubuntu 20.04               #
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
DISTROS="AlmaLinux 8, CentOS 7/8, Oracle Linux 8, RHEL 7/8, Rocky Linux 8, Ubuntu 20.04"

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
            EL_VER=`grep VERSION_ID /etc/os-release | cut -f2 -d "=" | sed 's/"//g'`
            if [[ "${EL_VER}" == "9"* ]]
            then
                sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
                sudo dnf install -y lsb_release
            else
                sudo yum install -y redhat-lsb
            fi
        else
            sudo apt-get install -y lsb-release
        fi
        DISTRIB_ID=`lsb_release -i | awk '{print $3}'`
    fi

    # Start installing dependencies
    if [ "${DISTRIB_ID}" == "Ubuntu" ]
    then
        # Get release information
        DISTRIB_RELEASE=`lsb_release -r | awk '{print $2}'`

        # Check if running supported version and install dependencies or inform user of unsupported version and exit
        if [ "${DISTRIB_RELEASE}" == "20.04" ] || [ "${DISTRIB_RELEASE}" == "22.04" ]
        then
            deb_pkg_install
        else
            echo "You are running an unsupported Ubuntu release!"
            exit 1
        fi
    elif [ "${DISTRIB_ID}" == "CentOS" ] || [ "${DISTRIB_ID}" == "OracleServer" ] || [ "${DISTRIB_ID}" == "RedHatEnterpriseServer" ] || [ "${DISTRIB_ID}" == "RedHatEnterprise" ] || [ "${DISTRIB_ID}" == "Rocky" ] || [ "${DISTRIB_ID}" == "AlmaLinux" ]
    then
        # Get release information
        DISTRIB_RELEASE=`lsb_release -r | awk '{print $2}' | cut -f1 -d "."`

        # Check if running supported version and install dependencies or inform user of unsupported version and exit
        if [ "${DISTRIB_RELEASE}" == "7" ] && [[ "${DISTRIB_ID}" == "CentOS" || "${DISTRIB_ID}" == "RedHatEnterpriseServer" ]]
        then
            el7_pkg_install
        elif [ "${DISTRIB_RELEASE}" == "8" ] && [[ "${DISTRIB_ID}" == "CentOS" || "${DISTRIB_ID}" == "RedHatEnterprise" || "${DISTRIB_ID}" == "Rocky" || "${DISTRIB_ID}" == "AlmaLinux" ]]
        then
            el8_pkg_install
            is_ant_excluded
        elif [ "${DISTRIB_RELEASE}" == "9" ] && [[ "${DISTRIB_ID}" == "CentOS" || "${DISTRIB_ID}" == "RedHatEnterprise" || "${DISTRIB_ID}" == "Rocky" || "${DISTRIB_ID}" == "AlmaLinux" ]]
        then
            el9_pkg_install
        # Check if running Oracle Linux
        elif [ "${DISTRIB_RELEASE}" == "8" ] && [ "${DISTRIB_ID}" == "OracleServer" ]
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
    sudo subscription-manager repos --enable rhel-7-server-extras-rpms
    sudo subscription-manager repos --enable rhel-7-server-supplementary-rpms
    sudo subscription-manager repos --enable rhel-7-server-optional-rpms
    sudo yum install -y java-1.8.0-openjdk ant ant-junit ruby git maven cpan wget perl-IPC-Cmd rpm-build createrepo
}

# Installs dependencies for EL8
el8_pkg_install() {
    if [ "${DISTRIB_RELEASE}" == "8" ] && [ "${DISTRIB_ID}" == "RedHatEnterprise" ]
    then
        sudo subscription-manager repos --enable codeready-builder-for-rhel-8-x86_64-rpms
    else
        sudo dnf install -y dnf-plugins-core
        sudo dnf config-manager --set-enabled powertools
    fi
    sudo dnf group install -y "Development Tools"
    sudo dnf module enable -y javapackages-tools
    sudo dnf install -y java-1.8.0-openjdk gcc-c++ ant-junit ruby git maven cpan wget rpm-build createrepo rsync
}

# Installs dependencies for EL9
el9_pkg_install() {
    echo -e "\nThis function is not ready/supported yet!"
    echo -e "It requires Zimbra supporting EL9 distros first!\n"
    exit 1

    #if [ "${DISTRIB_RELEASE}" == "9" ] && [ "${DISTRIB_ID}" == "RedHatEnterprise" ]
    #then
    #    sudo subscription-manager repos --enable codeready-builder-for-rhel-9-x86_64-rpms
    #else
    #    sudo dnf install -y dnf-plugins-core
    #    sudo dnf config-manager --set-enabled crb
    #fi
    #sudo dnf group install -y "Development Tools"
    #sudo dnf install -y javapackages-tools
    #sudo dnf install -y java-1.8.0-openjdk gcc-c++ ant-junit ruby git maven cpan wget rpm-build createrepo rsync
}

# Installs dependencies for OEL8
oel8_pkg_install() {
    sudo dnf group install -y "Development Tools"
    sudo dnf config-manager --set-enabled ol8_codeready_builder
    sudo dnf module enable -y javapackages-tools
    sudo dnf install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel
    sudo dnf install -y gcc-c++ ant-junit ruby git maven cpan wget rpm-build createrepo rsync
}

# Fixes ant ant-lib dependency problem between packages and modules
is_ant_excluded() {
    IS_ANT_EXCLUDE=`grep -c "exclude=ant ant-lib" /etc/dnf/dnf.conf`
    if [ ${IS_ANT_EXCLUDE} = 0 ]
    then
        sudo echo "exclude=ant ant-lib" >> /etc/dnf/dnf.conf
    fi
}

build_zimbra() {
    # Exit if no config.build file
    if [ ! -f config.build ]
    then
        echo -e "\n${RED}ERROR: No config.build file!\n"
        echo -e "${NORMAL}Depending on the version of Zimbra you wish to build, you will need to"
        echo -e "copy either config.build.9 or config.build.10 to config.build first.\n"
        echo -e "Eg: ${YELLOW}cp config.build.10 config.build${NORMAL}\n"
        echo -e "if you wish to build Zimbra 10.\n"
        exit 1
    fi

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
        echo "${PROJECTDIR} directory exists, cleaning up .staging content..."
        rm -rf ${MAINDIR}/${PROJECTDIR}/.staging
    else
        sudo mkdir ${MAINDIR}/${PROJECTDIR}
        sudo chown ${USERID}:${USERID} ${MAINDIR}/${PROJECTDIR}
    fi

    # Get current year and month number
    YEAR=`date '+%y'`
    MONTH=`date '+%m'`

    # Set quarter based on month number
    if [ ${MONTH} -ge 01 ] && [ ${MONTH} -le 03 ]
    then
        QUARTER=01
    elif [ ${MONTH} -ge 04 ] && [ ${MONTH} -le 06 ]
    then
        QUARTER=02
    elif [ ${MONTH} -ge 07 ] && [ ${MONTH} -le 09 ]
    then
        QUARTER=03
    elif [ ${MONTH} -ge 10 ] && [ ${MONTH} -le 12 ]
    then
        QUARTER=04
    fi

    # Concatenate quarter and year into BUILD_NO
    NEW_BUILD_NO=${QUARTER}${YEAR}

    # Update BUILD_NO in config.build file for Zimbra
    CURRENT_BUILD_NO=`grep BUILD_NO config.build | awk '{print $3}'`
    sed -i "s/${CURRENT_BUILD_NO}/${NEW_BUILD_NO}/" config.build

    # Start preparing for build
    cp config.build ${MAINDIR}/${PROJECTDIR}
    cp patches/zimbra-store.patch ${MAINDIR}/${PROJECTDIR}
    cp patches/zimbra-rocky.patch ${MAINDIR}/${PROJECTDIR}
    cp patches/zimbra-alma.patch ${MAINDIR}/${PROJECTDIR}
    cp patches/zimbra-repo.patch ${MAINDIR}/${PROJECTDIR}
    cp patches/zimbra-jetty.xml.production.patch ${MAINDIR}/${PROJECTDIR}
    cp patches/zimbra-nginx.conf.main.template.patch ${MAINDIR}/${PROJECTDIR}
    cp patches/zimbra-utilfunc.sh.patch ${MAINDIR}/${PROJECTDIR}
    cp patches/zimbra-aspell-httpd.conf.patch ${MAINDIR}/${PROJECTDIR}
    cd ${MAINDIR}/${PROJECTDIR}

    # Patch Zimbra 9 to remove onlyoffice and fix nginx config
    ZIMBRA_VER=`grep BUILD_RELEASE_NO config.build | awk '{print $3}'`
    if [ "${ZIMBRA_VER}" == "9.0.0" ]
    then
        git clone https://github.com/zimbra/zm-jetty-conf
        git clone https://github.com/zimbra/zm-nginx-conf
        patch ${MAINDIR}/${PROJECTDIR}/zm-jetty-conf/conf/jetty/jetty.xml.production zimbra-jetty.xml.production.patch
        patch ${MAINDIR}/${PROJECTDIR}/zm-nginx-conf/conf/nginx/nginx.conf.main.template zimbra-nginx.conf.main.template.patch
    fi

    # Patch Zimbra to remove libphp.so from zm-aspell/conf/httpd.conf for Zimbra 9.0.0 and Zimbra 10.0.x versions
    # as they do not include PHP.
    #if [ "${ZIMBRA_VER}" == "9.0.0" ] || [[ "${ZIMBRA_VER}" == "10.0"* ]]
    #then
    #    git clone https://github.com/zimbra/zm-aspell
    #    patch ${MAINDIR}/${PROJECTDIR}/zm-aspell/conf/httpd.conf zimbra-aspell-httpd.conf.patch
    #fi

    # Clone zm-build repository
    git clone https://github.com/zimbra/zm-build
    cp config.build ${MAINDIR}/${PROJECTDIR}/zm-build

    # Set repositories to use 90 instead of 1000
    if [ "${ZIMBRA_VER}" == "9.0.0" ]
    then
        sed -i 's/1000/90/g' ${MAINDIR}/${PROJECTDIR}/zm-build/rpmconf/Install/Util/utilfunc.sh
    fi

    # Patch utilfunc.sh to install net-tools dependency
    patch ${MAINDIR}/${PROJECTDIR}/zm-build/rpmconf/Install/Util/utilfunc.sh zimbra-utilfunc.sh.patch

    # Patch zimbra-store.sh to fix issue when convertd directory doesn't exist else build will fail
    patch ${MAINDIR}/${PROJECTDIR}/zm-build/instructions/bundling-scripts/zimbra-store.sh zimbra-store.patch

    # Patch get_plat_tag.sh to enable support for additional distros
    patch ${MAINDIR}/${PROJECTDIR}/zm-build/rpmconf/Build/get_plat_tag.sh zimbra-alma.patch

    # Fix for certain situation when building using CI/CD
    mkdir -p ~/.ivy2/cache

    # Change to build directory and build Zimbra
    cd ${MAINDIR}/${PROJECTDIR}/zm-build
    ./build.pl --ant-options -DskipTests=true

    # Inform where archive can be found or error message if problem with build
    if [ $? == 0 ]
    then
        echo -e "\nZimbra archive file can be found under ${MAINDIR}/${PROJECTDIR}/BUILDS"
        echo -e "You can now unpack this and install/upgrade Zimbra\n"
    else
        echo -e "${YELLOW}\nThere was a problem with the build process, check output above!\n${NORMAL}"
    fi
}

cleanup() {
    echo "Cleaning up previous attempted builds..."
    echo "${PROJECTDIR} directory exists, cleaning up .staging content..."
    rm -rf ${MAINDIR}/${PROJECTDIR}/.staging
    echo "Removing cloned Zimbra repositories..."
    for DIR in `ls ${MAINDIR}/${PROJECTDIR}`
    do
        rm -rf ${MAINDIR}/${PROJECTDIR}/$DIR
    done
}

# Help for using the script
help() {
    echo -e "\n${CYAN}Zimbra Build Helper script!\n"
    echo -e "${YELLOW}Valid parameters are as follows:${NORMAL}\n"
    echo -e "  ${GREEN}--install-deps${NORMAL}\t - Installs required dependencies"
    echo -e "  ${GREEN}--build-zimbra${NORMAL}\t - Builds Zimbra"
    echo -e "  ${GREEN}--cleanup${NORMAL}\t\t - Cleanup previous attempted builds"
    echo -e "  ${GREEN}--help${NORMAL}\t\t - Shows this help screen\n"
    echo -e "${CYAN}At the beginning of the script these variables can be changed if you want:${NORMAL}"
    echo -e "${YELLOW}\nMAINDIR=${NORMAL}/home/git\n${YELLOW}PROJECTDIR=${NORMAL}zimbra\n"
    echo -e "${CYAN}Build summary step-by-step:\n${NORMAL}"
    echo -e "  ${YELLOW}1. Generate ssh key:${NORMAL} ssh-keygen -t rsa -b 4096 -C \"your_email@address\""
    echo -e "  ${YELLOW}2. Upload this to your GitHub profile:${NORMAL} https://github.com/settings/keys"
    echo -e "  ${YELLOW}3. Only OpenJDK 8 can be installed on the build server, remove other versions"
    echo -e "  ${YELLOW}4. Run:${NORMAL}./zimbra-build-helper.sh --install-deps"
    echo -e "  ${YELLOW}5. Copy either config.build.9 or config.build.10 to config.build"
    echo -e "  ${YELLOW}6. Run:${NORMAL}./zimbra-build-helper.sh --build-zimbra\n"
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
    --cleanup)
        cleanup
        ;;
    --help)
        help
        ;;
    *)
        error
        ;;
esac
