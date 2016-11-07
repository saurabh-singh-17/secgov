/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &input_path./datset_prop_completed_completed.txt;
/* VERSION 2.1 */

options mprint mlogic symbolgen mfile;

proc printto log="&output_path/dataset_prop_output.log";
run;
quit;
/*	*/
%macro propupdate;
data _null_;
%if %sysfunc(symexist(input_path)) %then %do;
	libname in "&input_path.";
%end;
%else %do;
%let input_path=&inputPath.; 
call symput("input_path","&inputPath.");
%end;
run;

libname out "&datasetinfo_path.";
%let dataset_name=dataworking;

ods output members = properties(where=(lowcase(name)=lowcase("&dataset_name.")) keep=name obs vars FileSize);
proc datasets details library = in;
	run; quit ;


/*proc export data = out.mmbr_details*/
/*	outfile = "&output_path./dataset_properties.csv"*/
/*	dbms = csv replace;*/
/*	run;*/

data properties;
set properties(rename =(name=FILE_NAME obs=NO_OF_OBS vars=NO_OF_VARS fileSize = FILE_SIZE));
format file_size 12.4;
file_size = file_size/(1024*1024);
run;

/*CSV export*/
 proc export data = properties
	outfile="&input_path/dataset_prop.csv"
	dbms=CSV replace;
	run;
/* flex uses this file to test if the code has finished running */
data _null_;
v1= "eda - datset_prop_completed_completed";
file "&input_path./datset_prop_completed_completed.txt";
put v1;
run;
%mend;
%propupdate;