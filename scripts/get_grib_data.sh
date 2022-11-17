#!/usr/bin/env bash

#
# The purpose of this script is to download GRIB data to initialize the forecast. 
#

if [ "$#" -ne 2 ]; then
    echo " "
    echo " Usage: get_grib_data.sh <config file> <initial date>"
    echo " "
    echo "    where <config file> is the name of the configuration file to be used,"
    echo "    <initial file> is the initial UTC date and hour for the forecast cycle"
    echo " "
    exit 1
fi


#
# Set up information from configuration file
#
if [ ! -e $1 ]; then
    echo "Error: Could not open configuration file $1"
    exit 1
else
    config=$1
    . $config
fi

initdate=$2
grib_range=$FCST_LEN
grib_interval=$LBC_INTERVAL

datdir=${DATA_DIR}/$initdate

logfile="${LOG_DIR}/${2}.get_grib_data.log"

echo "`date -u` Starting GRIB data downloading script" | tee $logfile

echo "`date -u` Downloading data beginning at $initdate to $datdir" | tee -a $logfile


#
# Create a directory in which we will download GRIB data for this forecast cycle
#
if [ ! -d $datdir ]; then
    echo "`date -u` Directory $datdir does not exist... creating it now" | tee -a $logfile
    mkdir -p $datdir >> $logfile 2>&1
    if [ $? -ne 0 ]; then
        echo "`date -u` Error: Could not create directory $datdir" | tee -a $logfile
        exit 1
    fi
fi

cd $datdir


#
# Main loop to acquire GRIB data beginning at the initial date every <interval>
#   hours through the specified <range>
#
cycle=`echo $initdate | cut -c9-10`
grib_offset=0
while [ $grib_offset -le $grib_range ]; do

    grib_time="`${SCRIPTS_DIR}/newtime.py --time=$initdate --delta=$grib_offset`"
    echo "`date -u` Downloading data for $initdate + $grib_offset = $grib_time" | tee -a $logfile

    if [ $grib_offset -lt 100 ]; then
        fchr=`printf "%2.2i" $grib_offset`
    else 
        fchr=`printf "%3.3i" $grib_offset`
    fi

    # Example:
    # curl ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.${initdate}/gfs.t${cycle}z.pgrb2f${fchr} -o gfs.t${cycle}z.pgrb2f${fchr}

    grib_offset=$(( $grib_offset + $grib_interval ))
done


#
# For our classroom, we will just copy grib files from another directory, rather
#   than downloading them from an FTP server
#
ln -sf ${HOME}/WRF/DATA/fnl_* .

echo "`date -u` Finished GRIB data downloading script" | tee -a $logfile
