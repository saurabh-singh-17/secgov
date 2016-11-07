/*Successfully converted to SAS Server Format*/
*processbody;
libname output "&outputFolder.";
options mprint mlogic symbolgen mfile;
%let filename = &datasetName;

%macro checkFileForexist;
%let i = 1;
%let tempfilename = &filename;
%do %while(%sysfunc(exist(output.&tempfilename))) ;
	%let tempfilename = &filename.&i;
	%let i = %eval(&i + 1);
%end;t
%let filename = &tempfilename;
%mend checkFileForexist;

%macro csvtodataset; 

proc import datafile= "&inputPath."
     out=output.&filename.	
     dbms=csv
     replace;
    getnames=yes;
run;

%mend csvtodataset;

%csvtodataset;

FILENAME MyFile "&inputPath";

DATA _NULL_ ;
	rc = FDELETE('MyFile') ;
	RUN ;

data _null_;
	V1="&filename.";
	file "&resultPath./IMPORT_COMPLETED.txt";
	put V1;
	run;


proc datasets lib=work kill nolist;
quit;