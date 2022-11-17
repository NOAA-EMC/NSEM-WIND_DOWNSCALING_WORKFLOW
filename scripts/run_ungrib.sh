#!/usr/bin/env bash

#
# The purpose of this script is to ungrib the GRIB data acquired by the
#   get_grib_data.sh script. The directory $RUN_DIR/<initial date>/ungrib
#   will be created to hold the intermediate files created by ungrib.exe
#

if [ "$#" -ne 2 ]; then
    echo " "
    echo " Usage: run_ungrib.sh <config file> <initial date>"
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
fcst_range=$FCST_LEN
lbc_interval=$LBC_INTERVAL

ungrib_dir=${RUN_DIR}/${initdate}/ungrib
datdir=${DATA_DIR}/$initdate                       #MGD maybe GRIB data should be put in a subdirectory named grib?

logfile="${LOG_DIR}/${2}.run_ungrib.log"

echo "`date -u` Starting ungrib script" | tee $logfile


#
# Create a directory in which we will run ungrib.exe and create 
#
if [ ! -d $ungrib_dir ]; then
    echo "`date -u` Directory $ungrib_dir does not exist... creating it now" | tee -a $logfile
    mkdir -p $ungrib_dir >> $logfile 2>&1
    if [ $? -ne 0 ]; then
        echo "`date -u` Error: Could not create directory $ungrib_dir" | tee -a $logfile
        exit 1
    fi
fi

cd $ungrib_dir


#
# Link all GRIB files for this forecast cycle into our working directory
#
echo "`date -u` Linking GRIB files with link_grib.csh script from $datdir/*" | tee -a $logfile
${WPS_DIR}/link_grib.csh $datdir/*


#
# Set variables that will be needed in the namelist.wps file for ungrib
#
interval_seconds=$(($LBC_INTERVAL * 3600))
finaldate="`${SCRIPTS_DIR}/newtime.py --time=$initdate --delta=$fcst_range`"

start_year=`echo $initdate | cut -c1-4`
start_month=`echo $initdate | cut -c5-6`
start_day=`echo $initdate | cut -c7-8`
start_hour=`echo $initdate | cut -c9-10`
start_date="${start_year}-${start_month}-${start_day}_${start_hour}:00:00"

end_year=`echo $finaldate | cut -c1-4`
end_month=`echo $finaldate | cut -c5-6`
end_day=`echo $finaldate | cut -c7-8`
end_hour=`echo $finaldate | cut -c9-10`
end_date="${end_year}-${end_month}-${end_day}_${end_hour}:00:00"


#
# Create a namelist.wps file for ungrib
#
echo "`date -u` Creating namelist.wps file for ungrib" | tee -a $logfile
cat > namelist.wps << EOF
&share
 start_date = '${start_date}',
 end_date   = '${end_date}',
 interval_seconds = $interval_seconds
/

&ungrib
 out_format = 'WPS',
 prefix = 'FILE',
/
EOF


#
# Link in the Vtable for this GRIB data
#
echo "`date -u` Linking Vtable from ${CONFIG_DIR}/${VTABLE_NAME}" | tee -a $logfile
ln -sf ${CONFIG_DIR}/${VTABLE_NAME} Vtable


#
# Run ungrib.exe
#
echo "`date -u` Running ungrib.exe" | tee -a $logfile
${WPS_DIR}/ungrib.exe >> $logfile 2>&1


#
# Check whether we have a success message from ungrib, and if not, return a
#   status code indicating that something may have gone wrong; we can also check
#   for the expected intermediate files
#
grep "Successful completion" ungrib.log
if [ $? -ne 0 ]; then
    echo "`date -u` Error: Ungrib FAILED. Check ungrib.log in $ungrib_dir" | tee -a $logfile
    exit 1
fi


echo "`date -u` Finished ungrib script" | tee -a $logfile
