



# HWRF DATA DOWNLOAD FROM HPSS
module load hpss
 hsi get /NCEPDEV/emc-hwrf/5year/Zaizhong.Ma/coastal/hiresmasks/ida_2021/expens_ida/*.tar

# extract only specific files (for example ida09l.2021082818.hwrfprs.storm.0p015.f008.grb2 ) data from tar file with command

#tar -xf ida09l.202108*.tar --wildcards --no-anchored '*hwrfprs.storm*.grib2' // reading all tar files at once and extract the specific data input files

# we extracted 2 days data for Hurricane Ida
 # for example 
 tar -xf ida09l.2021082818.tar --wildcards --no-anchored '*hwrfprs.storm*.grb2'
 tar -xf ida09l.2021082900.tar --wildcards --no-anchored '*hwrfprs.storm*.grb2'

#_________________

# Move the extracted data to the WPS Directory

  mv *hwrfprs.storm* ../WPS/

  cd ../WPS
  
 # Download GFS data to provide land surface  datasets Note: HWRF model just provides 10-meters  hight and up data. 

 # data sourc https://rda.ucar.edu/datasets/ds083.2
 # create csh file to download data  get_gfsdata.csh
  chmod 777 get_gfsdata.csh 
  ./get_gfsdata.csh eHYViBlg   # eHYViBlg is password for rda ucar access data. anyone can create this

 # Once the data is downloaded - we have to go back to WPS folder
 cd ../WPS
 
 # FIRST STEP (GEOGRID.EXE)
 
 # Edit namelist.wps 
  Add high resolution elevaton dataset (10-meter)
  Add highh resolution landuse dataset (30-meter)
# for example 
  geog_data_res = 'nlcd2011_1s+3dep_ida+30s' # for all 3 domains


#  Create Domain using WRFDOMAIN WIZARD for landfall location
  Edit namelist.wps and add domain information  
# run command for geogrid.exe 
  sbatch job_geogrid.sh

# SECOND STEP (UNGRIB.exe)

 Link HWRF grib file and run ungrig.exe  (Vtable for HWRF)
 Link GFS_land file and run ungrib.exe (Vtable for GFS_land)

 sbatch ungrib.exe


$ THIRD STEP (METGRID.exe)
 
 sbatch metgrid.exe


**************************************************************

RUN REAL 

cd ../WRF/run

# Edit namelist.input 

sbatch job_real.exe


*************************************************************

RUN WRF

cd ../WRF/run

sbatch run_wrf.sh


*************************************************************

ADCRIC INUNDATION 

# High Water mark implementation is made with two steps:

1. ADCIRC High water mark is one dimensional dataset and unstructured. We have to map this data on to wrf grid. 
 We have deveopled ncl scripts

;This is an NCL/ESMF template file for regridding from an 
; unstructured grid to a rectilinear grid. It uses ESMF_regrid
; to do the regridding.

  ncl < ESMF_unstruct_to_rect.ncl
 

2. Now we have to map unstructured data on to wrf map and replace coastal land to  inundation. 

 ncl <  var_regrid_domain.ncl

3. Now replace land point to inundation grid points using ncl scripting

 ncl < change_wrfrst.ncl 

# Now WRF restart files can be used again to rerun the model with updated inundations. 
 

 



