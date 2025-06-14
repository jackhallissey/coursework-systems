#!/usr/bin/bash

filename="$1"

#Check if a file with the name in the variable infile exists using -e. If not, display an error and exit the script.
if ! [ -e "$filename" ]; then
	echo "File '$filename' not found"
	exit
fi

#From 'man tail' : use -n +NUM to skip NUM-1 lines at the start.
#Use tail to output the contents of the file, but skip 2 - 1 lines (1 line) at the start to omit the header line. Store this in a variable called data.
data=$(tail -n +2 $filename)

#At each iteration of the while loop, read from data, separate the fields according to where the commas are, and store each field in the 4 variables given
#Continue as long as there are lines left to read.
while IFS=',' read -r ID time temp pressure ; do
	#Use date to convert the unix time found in the csv file to human-readable time. Store in readable_time.
	readable_time=$(date --date="@$time")
	echo "ID: $ID, Time: $readable_time, Temp: $temp, Pressure: $pressure"
done <<< "$data"
#Input the contents of data to the while using <<< (here-string).