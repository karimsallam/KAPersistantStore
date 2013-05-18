#!/bin/sh

#  mogend.sh
#  KAPersistantStore
#
#  Created by Karim Mohamed Abdel Aziz Sallam on 18/05/13.
#  Copyright (c) 2013 K-Apps. All rights reserved.
#

BASE_CLASS=KAManagedObject

CURRENT_VERSION=`/usr/libexec/PlistBuddy "${INPUT_FILE_PATH}/.xccurrentversion" -c 'Print _XCCurrentVersionName'`

echo mogenerator --model \"${INPUT_FILE_PATH}/$CURRENT_VERSION\" --output-dir \"${INPUT_FILE_DIR}/\" --base-class $BASE_CLASS
mogenerator --model "${INPUT_FILE_PATH}/$CURRENT_VERSION" --output-dir "${INPUT_FILE_DIR}/" --base-class $BASE_CLASS --template-var arc=true

echo ${DEVELOPER_BIN_DIR}/momc -XD_MOMC_TARGET_VERSION=10.6 \"${INPUT_FILE_PATH}\" \"${TARGET_BUILD_DIR}/${EXECUTABLE_FOLDER_PATH}/${INPUT_FILE_BASE}.momd\"
${DEVELOPER_BIN_DIR}/momc -XD_MOMC_TARGET_VERSION=10.6 "${INPUT_FILE_PATH}" "${TARGET_BUILD_DIR}/${EXECUTABLE_FOLDER_PATH}/${INPUT_FILE_BASE}.momd"

echo "mogend.sh is done"