#!/usr/bin/env python

import getopt, sys, datetime

def usage():
	print " "
	print "Usage: newtime.py --time=<date> --delta=<delta>"
	print " "
	sys.exit()

opts, args = getopt.getopt(sys.argv[1:], "t:d:", ["time=","delta="])

t = "NULL"
d = "NULL"

for o,a in opts:
	if o in ("-t", "--time"):
		t = a;
	if o in ("-d", "--delta"):
		d = a;

if (t == "NULL" or d == "NULL"):
	usage()

if len(t) == 10:    # YYYYMMDDHH
	tt = datetime.datetime(int(t[0:4]), int(t[4:6]), int(t[6:8]), int(t[8:10]))
	dd = datetime.timedelta(hours=int(d))
        tt = tt+dd
	print '{0:04d}{1:02d}{2:02d}{3:02d}'.format(tt.year, tt.month, tt.day, tt.hour)
