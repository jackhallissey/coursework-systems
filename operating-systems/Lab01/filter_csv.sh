#!/usr/bin/bash

infile="$1"
outfile="$2"

#Check if a file with the name in the variable infile exists using -e. If not, display an error and exit the script.
if ! [ -e "$infile" ]; then
	echo "File '$infile' not found"
	exit
fi

#Check if an output file name has been given as a command line argument, i.e. check if outfile is null using -z. If it is, display an error and exit the script.
if [ -z "$outfile" ]; then
	echo "Provide name for output file"
	exit
fi

#Check if a file with the name in the variable outfile exists using -e. If it does, display an error and exit the script, as we don't want to overwrite an existing file.
if [ -e "$outfile" ]; then
	echo "File '$outfile' already exists"
	exit
fi

#We want to preserve the header line as-is in the output file, so we read the first line of infile using head, and then output this to outfile.
#-n1 to read the first line
head -n1 $infile > $outfile

#Use tail to output the contents of infile with the first line (the header) skipped. Use a pipe to feed the output from tail into awk.
#Using awk: use -F to set the field delimeter to a comma. For each line, only print the line if the third field (the temperature) is less than or equal to 50.
#Output the result to outfile. Use >> to add to the end of the file and avoid overwriting the header line that was written to the file in the previous line.
tail -n +2 $infile | awk -F "," '{ if ($3 <= 50) print }' >> $outfile