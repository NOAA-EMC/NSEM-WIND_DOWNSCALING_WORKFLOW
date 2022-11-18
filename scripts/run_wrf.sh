#!/usr/bin/env bash

#
# The script runs the WRF model in $RUN_DIR/wrf/ assuming that the real.exe program
#   has already created wrfinput and wrfbdy files in that directory.
#

if [ "$#" -ne 2 ]; then
    echo " "
    echo " Usage: run_wrf.sh <config file> <initial date>"
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

wrf_dir=${RUN_DIR}/${initdate}/wrf

logfile="${LOG_DIR}/${2}.run_wrf.log"

echo "`date -u` Starting wrf script" | tee $logfile


#
# Create a directory in which we will run wrf.exe
#
if [ ! -d $wrf_dir ]; then
    echo "`date -u` Directory $wrf_dir does not exist... creating it now" | tee -a $logfile
    mkdir -p $wrf_dir >> $logfile 2>&1
    if [ $? -ne 0 ]; then
        echo "`date -u` Error: Could not create directory $wrf_dir" | tee -a $logfile
        exit 1
    fi
fi

cd $wrf_dir


#
# Set variables that will be needed in the namelist.input file for real.exe
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
# Create a namelist.input file for wrf.exe from $CONFIG_DIR/namelist.input.template
#
echo "`date -u` Creating namelist.input file for wrf.exe" | tee -a $logfile
cat $CONFIG_DIR/namelist.input.template | cpp -C -P -traditional \
      -DSTART_YYYY=$start_year \
      -DSTART_MM=$start_month \
      -DSTART_DD=$start_day \
      -DSTART_HH=$start_hour \
      -DEND_YYYY=$end_year \
      -DEND_MM=$end_month \
      -DEND_DD=$end_day \
      -DEND_HH=$end_hour \
      -DLBC_INTERVAL=$interval_seconds \
> namelist.input



#
# Link the additional files needed by wrf.exe into our working directory
#
echo "`date -u` Linking *.TBL file from $WRF_DIR/test/em_real/*.TBL" | tee -a $logfile
ln -sf $WRF_DIR/test/em_real/*.TBL .
ln -sf $WRF_DIR/test/em_real/RRTM_DATA .


#
# Run wrf.exe
#
rm rsl* > /dev/null 2>&1
echo "`date -u` Running wrf.exe" | tee -a $logfile
${WRF_DIR}/main/wrf.exe >> $logfile 2>&1
mkdir wrf_rsl
mv rsl* wrf_rsl > /dev/null 2>&1


#
# Check whether we have any wrfout files
#
ls wrfout* > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "`date -u` Error: WRF FAILED. Check log files in $wrf_dir and in $logfile" | tee -a $logfile
    exit 1
fi



echo "`date -u` Finished wrf script" | tee -a $logfile
