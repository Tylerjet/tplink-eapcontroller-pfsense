#!/bin/sh

# install-omada.sh
# Installs the Omada Controller software on a FreeBSD machine (presumably running pfSense).

# The latest version of Omada Controller:
OMADA_SOFTWARE_URL=`curl -s https://www.tp-link.com/us/support/download/eap225/v3/#Controller_Software | tr '"' '\n' | tr "'" '\n' | grep -e 'tar.gz$' -m 1`


JRE_HOME="/usr/local/openjdk8/jre"

# The rc script associated with this branch or fork:
RC_SCRIPT_URL="https://raw.githubusercontent.com/tylerjet/tplink-eapcontroller-pfsense/master/rc.d/eapcontroller.sh"

PATCHED_STARTCLASS_URL="https://raw.githubusercontent.com/tylerjet/tplink-eapcontroller-pfsense/master/modifications/OmadaLinuxMain.class"
PATCHED_ZCLASS_URL="https://raw.githubusercontent.com/tylerjet/tplink-eapcontroller-pfsense/master/modifications/z.class"
MODIFIED_DCLASS_URL="https://raw.githubusercontent.com/tylerjet/tplink-eapcontroller-pfsense/master/modifications/d.class"
MODIFIED_OMADAPROPERTIES_URL="https://raw.githubusercontent.com/Tylerjet/tplink-eapcontroller-pfsense/master/modifications/omada.properties"

# If pkg-ng is not yet installed, bootstrap it:
if ! /usr/sbin/pkg -N 2> /dev/null; then
  echo "FreeBSD pkgng not installed. Installing..."
  env ASSUME_ALWAYS_YES=YES /usr/sbin/pkg bootstrap
  echo " done."
fi

# If installation failed, exit:
if ! /usr/sbin/pkg -N 2> /dev/null; then
  echo "ERROR: pkgng installation failed. Exiting."
  exit 1
fi

# Determine this installation's Application Binary Interface
ABI=`/usr/sbin/pkg config abi`

# FreeBSD package source:
FREEBSD_PACKAGE_URL="https://pkg.freebsd.org/${ABI}/latest/All/"

# FreeBSD package list:
FREEBSD_PACKAGE_LIST_URL="https://pkg.freebsd.org/${ABI}/latest/packagesite.txz"

# Stop the controller if it's already running...
# First let's try the rc script if it exists:
if [ -f /usr/local/etc/rc.d/omadacontroller.sh ]; then
  echo "Stopping the OMADA Controller service..."
  /usr/sbin/service omadacontroller.sh stop
  echo " done."
fi

# Then to be doubly sure, let's make sure ace.jar isn't running for some other reason:
if [ $(ps ax | grep "eap.home=/opt/tplink/EAPController") -ne 0 ]; then
  echo "Killing ace.jar process..."
  /bin/kill -15 `ps ax | grep "eap.home=/opt/tplink/EAPController" | awk '{ print $1 }'`
  echo " done."
fi

# And then make sure mongodb doesn't have the db file open:
if [ $(ps ax | grep -c "/opt/tplink/EAPController/data/[d]b") -ne 0 ]; then
  echo "Killing mongod process..."
  /bin/kill -15 `ps ax | grep "/opt/tplink/EAPController/data/[d]b" | awk '{ print $1 }'`
  echo " done."
fi

# If an installation exists, we'll need to back up configuration:
#if [ -d /opt/tplink/EAPController/data ]; then
#  echo "Backing up OMADA Controller data..."
#  BACKUPFILE=/var/backups/eap-`date +"%Y%m%d_%H%M%S"`.tgz
#  /usr/bin/tar -vczf ${BACKUPFILE} /opt/tplink/EAPController/data
#fi

# Add the fstab entries apparently required for OpenJDKse:
#if [ $(grep -c fdesc /etc/fstab) -eq 0 ]; then
#  echo "Adding fdesc filesystem to /etc/fstab..."
#  echo -e "fdesc\t\t\t/dev/fd\t\tfdescfs\trw\t\t0\t0" >> /etc/fstab
#  echo " done."
#fi

#if [ $(grep -c proc /etc/fstab) -eq 0 ]; then
#  echo "Adding procfs filesystem to /etc/fstab..."
#  echo -e "proc\t\t\t/proc\t\tprocfs\trw\t\t0\t0" >> /etc/fstab
#  echo " done."
#fi

# Run mount to mount the two new filesystems:
#echo "Mounting new filesystems..."
#/sbin/mount -a
#echo " done."

# Install mongodb, OpenJDK, and unzip (required to unpack Ubiquiti's download):
# -F skips a package if it's already installed, without throwing an error.
echo "Installing required packages..."
tar xv -C / -f /usr/local/share/pfSense/base.txz ./usr/bin/install
#uncomment below for pfSense 2.2.x:
#env ASSUME_ALWAYS_YES=YES /usr/sbin/pkg install mongodb openjdk unzip pcre v8 snappy

fetch ${FREEBSD_PACKAGE_LIST_URL}
tar vfx packagesite.txz

AddPkg () {
     pkgname=$1
        pkg unlock -yq $pkgname
     pkginfo=`grep "\"name\":\"$pkgname\"" packagesite.yaml`
     pkgvers=`echo $pkginfo | pcregrep -o1 '"version":"(.*?)"' | head -1`

    # compare version for update/install
     if [ `pkg info | grep -c $pkgname-$pkgvers` -eq 1 ]; then
         echo "Package $pkgname-$pkgvers already installed."
    else
         env ASSUME_ALWAYS_YES=YES /usr/sbin/pkg add -f ${FREEBSD_PACKAGE_URL}${pkgname}-${pkgvers}.txz

         # if update openjdk8 then force delete snappyjava to reinstall for new version of openjdk
         #if [ "$pkgname" == "openjdk8" ]; then
         #     env ASSUME_ALWAYS_YES=YES /usr/sbin/pkg delete snappyjava
        #     fi
    fi
        pkg lock -yq $pkgname
}

AddPkg snappy
AddPkg apache-commons-daemon
AddPkg png
AddPkg freetype2
AddPkg fontconfig
AddPkg alsa-lib
AddPkg python37
AddPkg libfontenc
AddPkg mkfontscale
AddPkg dejavu
AddPkg giflib
AddPkg xorgproto
AddPkg libXdmcp
AddPkg libpthread-stubs
AddPkg libXau
AddPkg libxcb
AddPkg libICE
AddPkg libSM
AddPkg libX11
AddPkg libXfixes
AddPkg libXext
AddPkg libXi
AddPkg libXt
AddPkg libXtst
AddPkg libXrender
AddPkg libinotify
AddPkg javavmwrapper
AddPkg java-zoneinfo
AddPkg openjdk8
AddPkg cyrus-sasl
AddPkg icu
AddPkg boost-libs
AddPkg mongodb36
AddPkg unzip
AddPkg pcre

# Clean up downloaded package manifest:
rm packagesite.*

echo " done."

# Switch to a temp directory for the OMADA Controller download:
cd `mktemp -d -t tplink`

# Download OMADA Controller from TP-Link:
echo "Downloading the OMADA Controller software..."
/usr/bin/fetch ${OMADA_SOFTWARE_URL} -o Omada_Controller.tar.gz
echo " done."

cd '/'

# Unpack the archive into the /usr/local directory:
# (the -o option overwrites the existing files without complaining)
echo "Installing OMADA Controller in /opt/tplink/EAPController..."
mkdir -p  /tmp/omadac
tar -xvzC /tmp/omadac -f Omada_Controller.tar.gz --strip-components=1
mkdir -p  /opt/tplink/EAPController
cp -r /tmp/omadac/* /opt/tplink/EAPController
echo " done."

# Put modified properties into folder
echo "Updating omada.properties"
/usr/bin/fetch -o /opt/tplink/EAPController/properties/omada.properties ${MODIFIED_OMADAPROPERTIES_URL}

# Update OMADA's symbolic link for mongod to point to the version we just installed:
echo "Updating mongod link..."
/bin/ln -sf /usr/local/bin/mongod /opt/tplink/EAPController/bin/mongod
/bin/ln -sf /usr/local/bin/mongo /opt/tplink/EAPController/bin/mongo
touch /opt/tplink/EAPController/data/mongod.pid
echo " done."

# Update OMADA's symbolic link for Java to point to the version we just installed:
echo "Updating Java link..."
/bin/ln -sf ${JAVA_HOME} /opt/tplink/EAPController/jre
echo " done."

echo "Remove Omada [un]install scripts"
rm /opt/tplink/EAPController/install.sh
rm /opt/tplink/EAPController/uninstall.sh
echo " done."

echo "Patch omada-start.jar"
mkdir -p  /tmp/omada-start-jar
if [ ! -f /opt/tplink/EAPController/lib/omada-start.jar.bak ]; then
    cp "/opt/tplink/EAPController/lib/omada-start.jar" "/opt/tplink/EAPController/lib/omada-start.jar.bak"
fi
cp "/opt/tplink/EAPController/lib/omada-start.jar" "/tmp/omada-start-jar"
( cd /tmp/omada-start-jar/ && jar -xf omada-start.jar )
/usr/bin/fetch -o /tmp/omada-start-jar/com/tplink/omada/start/OmadaLinuxMain.class ${PATCHED_STARTCLASS_URL}
/usr/bin/fetch -o /tmp/omada-start-jar/com/tplink/omada/start/b/d.class ${MODIFIED_DCLASS_URL}
( cd /tmp/omada-start-jar/ && jar -cvf omada-start.jar * )
cp "/tmp/omada-start-jar/omada-start.jar" "/opt/tplink/EAPController/lib/omada-start.jar"
echo " done."

echo "Patch omada-common-4.4.4.jar"
mkdir -p  /tmp/omada-common-4.4.4-jar/
if [ ! -f /opt/tplink/EAPController/lib/omada-common-4.4.4.jar.bak ]; then
    cp "/opt/tplink/EAPController/lib/omada-common-4.4.4.jar" "/opt/tplink/EAPController/lib/omada-common-4.4.4.jar.bak"
fi
cp "/opt/tplink/EAPController/lib/omada-common-4.4.4.jar" "/tmp/omada-common-4.4.4-jar"
( cd /tmp/omada-common-4.4.4-jar/ && jar -xf omada-common-4.4.4.jar )
/usr/bin/fetch -o /tmp/omada-common-4.4.4-jar/com/tplink/omada/common/util/z.class ${PATCHED_ZCLASS_URL}
( cd /tmp/omada-common-4.4.4-jar/ && jar -cvf omada-common-4.4.4.jar * )
cp "/tmp/omada-common-4.4.4-jar/omada-common-4.4.4.jar" "/opt/tplink/EAPController/lib/omada-common-4.4.4.jar"
echo " done."

# If partition size is < 4GB, add smallfiles option to mongodb
# echo "Checking partition size..."
# if [ `df -k | awk '$NF=="/"{print $2}'` -le 4194302 ]; then
#     echo -e "\nunifi.db.extraargs=--smallfiles\n" >> /opt/tplink/EAPController/data/system.properties
# fi
# echo " done."



# Fetch the rc script from github:
echo "Installing rc script..."
/usr/bin/fetch -o /usr/local/etc/rc.d/eapcontroller.sh ${RC_SCRIPT_URL}
echo " done."

# Fix permissions so it'll run
chmod +x /usr/local/etc/rc.d/eapcontroller.sh

# Add the startup variable to rc.conf.local.
# Eventually, this step will need to be folded into pfSense, which manages the main rc.conf.
# In the following comparison, we expect the 'or' operator to short-circuit, to make sure the file exists and avoid grep throwing an error.
if [ ! -f /etc/rc.conf ] || [ $(grep -c eapcontroller_enable /etc/rc.conf) -eq 0 ]; then
  echo "Enabling the OMADA Controller service..."
  echo "eapcontroller_enable=YES" >> /etc/rc.conf
  echo " done."
fi

# Do some setup

DEST_DIR=/opt/tplink
DEST_FOLDER=EAPController
INSTALLDIR=${DEST_DIR}/${DEST_FOLDER}
DATA_DIR="${INSTALLDIR}/data"


BACKUP_DIR=${INSTALLDIR}/../eap_db_backup
DB_FILE_NAME=eap.db.tar.gz
MAP_FILE_NAME=eap.map.tar.gz


need_import_mongo_db() {
    while true
    do
        echo "${DESC} detects that you have backup previous setting before, will you import it (y/n): "
        read input
        confirm=`echo $input | tr '[a-z]' '[A-Z]'`

        if [ "$confirm" == "Y" -o "$confirm" == "YES" ]; then
            return 1
        elif [ "$confirm" == "N" -o "$confirm" == "NO" ]; then
            return 0
        fi
    done
}

import_mongo_db() {
    if test -f ${BACKUP_DIR}/${DB_FILE_NAME}; then
        need_import_mongo_db
        if [ 1 == $? ]; then
            cd  ${BACKUP_DIR}
            tar zxvf ${DB_FILE_NAME} -C ${DATA_DIR}

            #import map pictures
            if test -f ${MAP_FILE_NAME}; then
                tar zxvf ${MAP_FILE_NAME} -C ${DATA_DIR}
            fi
            
            rm -rf ${DB_FILE_NAME} > /dev/null 2>&1
            rm -rf ${MAP_FILE_NAME} > /dev/null 2>&1
            echo "Import previous setting seccess."
        fi
    fi
}

# Restore the backup:
if [ ! -z "${BACKUPFILE}" ] && [ -f ${BACKUPFILE} ]; then
  echo "Restoring OMADA Controller data..."
  mv "/opt/tplink/EAPController/data" "/opt/tplink/EAPController/data-`date +%Y%m%d-%H%M`"
  /usr/bin/tar -vxzf ${BACKUPFILE} -C /
fi

import_mongo_db

# Start it up:
echo "Starting the OMADA Controller service..."
/usr/sbin/service eapcontroller.sh start
echo " done."
