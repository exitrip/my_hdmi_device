#!/usr/bin/bash
# export PROJ=$1
# source ${XRAY_DIR}/utils/environment.sh

echo $NEXTPNR_XILINX_DIR #?= /snap/openxc7/current/opt/nextpnr-xilinx
echo $NEXTPNR_XILINX_PYTHON_DIR #?= ${NEXTPNR_XILINX_DIR}/python
echo $PRJXRAY_DB_DIR #?= ${NEXTPNR_XILINX_DIR}/external/prjxray-db

DBPART = $(shell echo ${PART} | sed -e 's/-[0-9]//g')
SPEEDGRADE = $(shell echo ${PART} | sed -e 's/.*\-\([0-9]\)/\1/g')

CHIPDB ?= ./chipdb/
PYPY3 ?= pypy3

${PYPY3} ${NEXTPNR_XILINX_PYTHON_DIR}/bbaexport.py --device ${PART} --bba ${DBPART}.bba
bbasm -l ${DBPART}.bba ${CHIPDB}/${DBPART}.bin

# ${XRAY_UTILS_DIR}/fasm2frames.py --part xc7a100tcsg324-1 --db-root ${XRAY_UTILS_DIR}/../database/artix7 ${PROJ}.fasm > ${PROJ}.frames
# ${XRAY_TOOLS_DIR}/xc7frames2bit --part_file ${XRAY_UTILS_DIR}/../database/artix7/xc7a100tcsg324-1/part.yaml --part_name xc7a100tcsg324-1  --frm_file ${PROJ}.frames --output_file ${PROJ}.bit

