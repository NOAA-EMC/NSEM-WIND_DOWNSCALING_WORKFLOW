#!/usr/bin/env bash

#
# This is the main driver script for our real-time system.
# Its job is to invoke each of the major stages of the system in order.
#

if [ "$#" -ne 2 ]; then
    echo " "
    echo " Usage: driver.sh <config file> <cycle date>"
    echo " "
    echo "    where <config file> is the name of the configuration file to be used"
    echo "    and <cycle date> is the initial UTC date and hour for the forecast cycle"
    echo "    to be run in YYYYMMDDHH format."
    echo " "
    exit 1
fi

# Setup information from configuration file
if [ ! -e $1 ]; then
    echo "Error: Could not open configuration file $1"
    exit 1
else
    config=$1
    . $config
fi

initdate=$2

logfile="${LOG_DIR}/${2}.driver.log"

echo "`date -u` Starting main driver script for forecast cycle $initdate" | tee $logfile

echo "`date -u` Using WRF_DIR     = $WRF_DIR" | tee -a $logfile
echo "`date -u` Using WPS_DIR     = $WPS_DIR" | tee -a $logfile
echo "`date -u` Using ROOT_DIR    = $ROOT_DIR" | tee -a $logfile
echo "`date -u` Using CONFIG_DIR  = $CONFIG_DIR" | tee -a $logfile
echo "`date -u` Using SCRIPTS_DIR = $SCRIPTS_DIR" | tee -a $logfile
echo "`date -u` Using LOG_DIR     = $LOG_DIR" | tee -a $logfile
echo "`date -u` Using DATA_DIR    = $DATA_DIR" | tee -a $logfile
echo "`date -u` Using RUN_DIR     = $RUN_DIR" | tee -a $logfile
echo "`date -u` Using PLOTS_DIR   = $PLOTS_DIR" | tee -a $logfile


# 
#  Begin to download GRIB data to be used as initial and boundary conditions
#    for this forecast cycle
# 
echo "`date -u` *** Getting GRIB data ***"
${SCRIPTS_DIR}/get_grib_data.sh $config $initdate

if [ "$?" -ne 0 ]; then
    echo "*****"
    echo "`date -u` Error: Bad return error code from get_grib_data.sh" | tee -a $logfile
    echo "*****"
    exit 1
else
    echo "`date -u` Successfully acquired GRIB data" | tee -a $logfile
fi


# 
#  Run ungrib
# 
echo "`date -u` *** Running ungrib.exe ***"
${SCRIPTS_DIR}/run_ungrib.sh $config $initdate

if [ "$?" -ne 0 ]; then
    echo "*****"
    echo "`date -u` Error: Bad return error code from run_ungrib.sh" | tee -a $logfile
    echo "*****"
    exit 1
else
    echo "`date -u` Successfully ran ungrib.exe" | tee -a $logfile
fi


# 
#  Run metgrid
# 
echo "`date -u` *** Running metgrid.exe ***"
${SCRIPTS_DIR}/run_metgrid.sh $config $initdate

if [ "$?" -ne 0 ]; then
    echo "*****"
    echo "`date -u` Error: Bad return error code from run_metgrid.sh" | tee -a $logfile
    echo "*****"
    exit 1
else
    echo "`date -u` Successfully ran metgrid.exe" | tee -a $logfile
fi


# 
#  Run real
# 
echo "`date -u` *** Running real.exe ***"
${SCRIPTS_DIR}/run_real.sh $config $initdate

if [ "$?" -ne 0 ]; then
    echo "*****"
    echo "`date -u` Error: Bad return error code from run_real.sh" | tee -a $logfile
    echo "*****"
    exit 1
else
    echo "`date -u` Successfully ran real.exe" | tee -a $logfile
fi


# 
#  Run WRF
# 
echo "`date -u` *** Running wrf.exe ***"
${SCRIPTS_DIR}/run_wrf.sh $config $initdate

if [ "$?" -ne 0 ]; then
    echo "*****"
    echo "`date -u` Error: Bad return error code from run_wrf.sh" | tee -a $logfile
    echo "*****"
    exit 1
else
    echo "`date -u` Successfully ran wrf.exe" | tee -a $logfile
fi


# 
#  Make plots for this forecast
# 
echo "`date -u` *** Running post-processing/plotting ***"
${SCRIPTS_DIR}/post_process.sh $config $initdate

if [ "$?" -ne 0 ]; then
    echo "*****"
    echo "`date -u` Error: Bad return error code from post_process.sh" | tee -a $logfile
    echo "*****"
    exit 1
else
    echo "`date -u` Successfully ran post-processing" | tee -a $logfile
fi


echo "`date -u` Finished main driver script for forecast cycle $initdate" | tee -a $logfile
