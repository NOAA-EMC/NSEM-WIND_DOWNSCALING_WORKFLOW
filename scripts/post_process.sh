#!/usr/bin/env bash

#
# The script creates plots from the wrfout files in $RUN_DIR/wrf/; these plots are
#   created in the directory $PLOTS_DIR/<initial date>/.
#

if [ "$#" -ne 2 ]; then
    echo " "
    echo " Usage: post_process.sh <config file> <initial date>"
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

wrf_dir=${RUN_DIR}/${initdate}/wrf
plots_dir=${PLOTS_DIR}/${initdate}
ncl_dir=${CONFIG_DIR}/ncl

logfile="${LOG_DIR}/${2}.post_process.log"

echo "`date -u` Starting post-processing script" | tee $logfile


#
# Create a directory in which we will make plots
#
if [ ! -d $plots_dir ]; then
    echo "`date -u` Directory $plots_dir does not exist... creating it now" | tee -a $logfile
    mkdir -p $plots_dir >> $logfile 2>&1
    if [ $? -ne 0 ]; then
        echo "`date -u` Error: Could not create directory $plots_dir" | tee -a $logfile
        exit 1
    fi
fi

cd $plots_dir

#
# Link the WRF output files into our working plots directory
#
echo "`date -u` Linking wrfout* files from $wrf_dir to $plots_dir" | tee -a $logfile
ln -s $wrf_dir/wrfout* .


#
# Run post-processing scripts
#
for f in wrfout*; do
    export WRFNAME="${f}.nc"
    export PLOTNAME="`echo $f | cut -c12-24`"
    ncl $ncl_dir/wrf_Surface1.ncl
done

echo "`date -u` Finished post-processing script" | tee -a $logfile
