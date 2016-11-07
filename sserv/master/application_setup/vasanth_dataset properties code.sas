/*Successfully converted to SAS Server Format*/
*processbody; 
%let completedTXTPath =  &output_path./datset_prop_completed_completed.txt;
/* VERSION 2.1 */

libname in "&input_path.";

ods output members = properties(where=(lowcase(name)=lowcase("&dataset_name.")) keep=name obs vars FileSize);
proc datasets details library = in;
	run;
	quit;

data properties;
	set properties(rename =(name=file_name obs=no_of_obs vars=no_of_vars fileSize = file_size));
	format file_size 12.4;
	run;

/*CSV export*/
proc export data = properties outfile="&output_path./dataset_properties.csv" dbms=CSV replace;
	run;
	quit;

/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "eda - datset_prop_completed_completed";
	file "&output_path./datset_prop_completed_completed.txt";
	put v1;
	run;