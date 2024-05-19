#!/bin/bash
#####
# Disclaimer
# This script and binary are provided as-is, without any guarantees or warranty. 
# Although it was created for personal use, it is being shared in 
# good faith for others who may find it useful. The author is not 
# responsible for any issues, errors, or damages that may arise from 
# the use of this script. Users are advised to test and evaluate 
# the script in their own environment and use it at their own risk.
#

##### EDIT #####

TARGET_DEB_URL=https://github.com/nkallen/plasticity/releases/download/v24.1.5/plasticity_24.1.5_amd64.deb
APPIMAGE_TOOL_URL=https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
TEMP_DIR=/tmp/$( date +%s )

###############

set -e
# set -x # for debug

mkdir "${TEMP_DIR}"

sudo apt -y install\
    desktop-file-utils\
    fuse\
    file

# get plasticity deb
wget "${TARGET_DEB_URL}" -O "${TEMP_DIR}/plasticity.deb"
sudo apt install "${TEMP_DIR}/plasticity.deb"

# extract deb files
dpkg -x "${TEMP_DIR}/plasticity.deb" "${TEMP_DIR}/DebFiles"

# get appimagetool
wget "${APPIMAGE_TOOL_URL}" -O "${TEMP_DIR}/appimagetool.AppImage"
chmod +x "${TEMP_DIR}/appimagetool.AppImage"

# create the App directory
mkdir -p "${TEMP_DIR}/AppDir"

# get all the library objects
for objlink in $(ldd /usr/bin/plasticity | cut -d '>' -f 2 | awk '{print $1}')
do
	[ -f "${objlink}" ] && cp --verbose --parents "${objlink}" "${TEMP_DIR}/AppDir/"
done

# copy the deb files into the App directory
cp -a "${TEMP_DIR}/DebFiles/usr" "${TEMP_DIR}/AppDir/"

#create AppRun script
cat << 'EOF'> "${TEMP_DIR}/AppDir/AppRun"
#!/bin/sh
PWD="$(dirname "$(readlink -f "${0}")")"
exec "${PWD}/usr/bin/plasticity"
EOF
chmod +x "${TEMP_DIR}/AppDir/AppRun"

#create the destop file
cat << 'EOF' > "${TEMP_DIR}/AppDir/plasticity.desktop"
[Desktop Entry]
Name=Plasticity
Exec=plasticity
Type=Application
Icon=icon
Categories=Utility
EOF
chmod +x "${TEMP_DIR}/AppDir/plasticity.desktop"

#copy the icon
cp icon.png "${TEMP_DIR}/AppDir/"

#run appimagetool
${TEMP_DIR}/appimagetool.AppImage -n "${TEMP_DIR}/AppDir"

#ask about files
while true; do
    read -p "Do you want to cleaup ${TEMP_DIR}? (yes/no): " yn
    case $yn in
        [Yy]* ) 
            rm -r "${TEMP_DIR}"
            echo "Directory ${TEMP_DIR} deleted."
            break
            ;;
        [Nn]* ) 
            echo "Keeping directory ${TEMP_DIR}"
            break
            ;;
        * ) 
            echo "Please answer yes or no."
            ;;
    esac
done
