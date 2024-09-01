#!/bin/sh -
#
# Build the CoPicoVersion if the pico9918 firmware.
#

FIRMWARE_DIR=$PWD
PICO9918_CONFIG="${FIRMWARE_DIR}/CoPicoVision_pico9918_config.cmake"
PICO9918_DIR="${FIRMWARE_DIR}/../../submodules/pico9918"

rm -rf ${FIRMWARE_DIR}/build || exit 1
mkdir ${FIRMWARE_DIR}/build
cd ${FIRMWARE_DIR}/build || exit 1
cmake -DPICO9918_CONFIG="${PICO9918_CONFIG}" ${PICO9918_DIR} || exit 1
cmake --build . || exit 1
mv ${FIRMWARE_DIR}/build/src/pico9918.uf2 \
    ${FIRMWARE_DIR}/CoPicoVision_pico9918.uf2 || exit 1
cd ${FIRMWARE_DIR} || exit 1
rm -rf ${FIRMWARE_DIR}/build || exit 1

exit 0
