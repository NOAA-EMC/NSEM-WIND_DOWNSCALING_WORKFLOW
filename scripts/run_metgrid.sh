#!/usr/bin/env bash

#
# The purpose of this script is to run metgrid for the pre-defined domains in
#   the geo_em* files found in $DOMAIN_DIR (defined in <config file>) 
#   beginning at <initial date> out to the forecast range specified in <config file> 
#   as $FCST_LEN
# The directory $RUN_DIR/<initial date>/metgrid will be created to hold the metgrid
#   output files, and the intermediate files required by metgrid are expected to be
#   in $RUN_DIR/<initial date>/ungrib
#

if [ "$#" -ne 2 ]; then
    echo " "
    echo " Usage: run_metgrid.sh <config file> <initial date>"
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
metgrid_dir=${RUN_DIR}/${initdate}/metgrid

logfile="${LOG_DIR}/${2}.run_metgrid.log"

echo "`date -u` Starting metgrid script" | tee $logfile


#
# Create a directory in which we will run metgrid.exe
#
if [ ! -d $metgrid_dir ]; then
    echo "`date -u` Directory $metgrid_dir does not exist... creating it now" | tee -a $logfile
    mkdir -p $metgrid_dir >> $logfile 2>&1
    if [ $? -ne 0 ]; then
        echo "`date -u` Error: Could not create directory $metgrid_dir" | tee -a $logfile
        exit 1
    fi
fi

cd $metgrid_dir


#
# Link geogrid (geo_em*) files from $DOMAINS_DIR into our working directory
#
echo "`date -u` Linking geogrid files from $DOMAINS_DIR/geo_em*" | tee -a $logfile
ln -sf $DOMAINS_DIR/geo_em* .

#MGD How would we set this up to work with nested domains?


#
# Link all intermediate files for this forecast cycle into our working directory
#
echo "`date -u` Linking intermediate files from $ungrib_dir/*:*" | tee -a $logfile
ln -sf $ungrib_dir/*:* .


#
# Set variables that will be needed in the namelist.wps file for metgrid
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
# Create a namelist.wps file for metgrid
#
echo "`date -u` Creating namelist.wps file for metgrid" | tee -a $logfile
cat > namelist.wps << EOF
&share
 wrf_core = 'ARW',
 max_dom = 1,
 start_date = '${start_date}',
 end_date   = '${end_date}',
 interval_seconds = $interval_seconds
/

&metgrid
 fg_name = 'FILE',
 opt_metgrid_tbl_path = './'
/
EOF


#
# Link the METGRID.TBL into our working directory
#
echo "`date -u` Linking METGRID.TBL file from $WPS_DIR/metgrid/METGRID.TBL" | tee -a $logfile
ln -sf $WPS_DIR/metgrid/METGRID.TBL .


#
# Run metgrid.exe
#
echo "`date -u` Running metgrid.exe" | tee -a $logfile
${WPS_DIR}/metgrid.exe >> $logfile 2>&1


#
# Check whether we have a success message from metgrid, and if not, return a
#   status code indicating that something may have gone wrong; we can also check
#   for the expected met_em files
#
grep "Successful completion" metgrid.log
if [ $? -ne 0 ]; then
    echo "`date -u` Error: Metgrid FAILED. Check metgrid.log in $metgrid_dir" | tee -a $logfile
    exit 1
fi

echo "`date -u` Finished metgrid script" | tee -a $logfile
