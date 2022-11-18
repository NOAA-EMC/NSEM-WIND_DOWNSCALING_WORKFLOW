#!/usr/bin/env bash

#
# The purpose of this script is to run the real.exe program for the metgrid
#   output found in $RUN_DIR/<initial date>/metgrid/.
# The directory $RUN_DIR/<initial date>/wrf will be created to hold the wrfinput
#   and wrfbdy files that will be created by real.exe.
#

if [ "$#" -ne 2 ]; then
    echo " "
    echo " Usage: run_real.sh <config file> <initial date>"
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

metgrid_dir=${RUN_DIR}/${initdate}/metgrid
wrf_dir=${RUN_DIR}/${initdate}/wrf

logfile="${LOG_DIR}/${2}.run_real.log"

echo "`date -u` Starting real script" | tee $logfile


#
# Create a directory in which we will run real.exe
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
# Link metgrid (met_em*) files from $metgrid_dir into our working directory
#
echo "`date -u` Linking metgrid output files from $metgrid_dir/met_em*" | tee -a $logfile
ln -sf $metgrid_dir/met_em* .


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
# Create a namelist.input file for real.exe from $CONFIG_DIR/namelist.input.template
#
echo "`date -u` Creating namelist.input file for real.exe" | tee -a $logfile
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
# Run real.exe
#
rm -f rsl* > /dev/null 2>&1
echo "`date -u` Running real.exe" | tee -a $logfile
${WRF_DIR}/main/real.exe >> $logfile 2>&1
mkdir real_rsl
mv rsl* real_rsl > /dev/null 2>&1


#
# Check whether we have wrfinput_d01 and wrfbdy_d01 files from real.exe; we can also
#   check the rsl files if WRF were compiled with a dmpar option
#
if [ ! -e wrfinput_d01 ] || [ ! -e wrfbdy_d01 ]; then
    echo "`date -u` Error: Real FAILED. Check log files in in $wrf_dir and in $logfile" | tee -a $logfile
    exit 1
fi


echo "`date -u` Finished real script" | tee -a $logfile
