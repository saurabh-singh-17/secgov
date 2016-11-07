/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &input_path./datset_prop_completed_completed.txt;

/* VERSION 2.1 */
options mprint mlogic symbolgen;

proc printto log="&input_path./dataset_prop_output.log" new;
run;
quit;

%macro propupdate;
	%if %sysfunc(symexist(inputPath)) %then
		%do;
			%let input_path=&inputPath.;
		%end;
	%else %if %sysfunc(symexist(c_path_in)) %then
		%do;
			%let input_path=&c_path_in.;
		%end;

	libname in "&input_path.";
	%let dataset_name=dataworking;
	ods output members = properties(where=(lowcase(name)=lowcase("&dataset_name.")) keep=name obs vars FileSize);

	proc datasets details library = in;
	run;
	quit;

	data properties;
		set properties(rename =(name=file_name obs=no_of_obs vars=no_of_vars fileSize = file_size));
		format file_size 12.4;
		file_size = file_size/(1024*1024);
	run;

	/*CSV export*/
	proc export data = properties
		outfile="&input_path./dataset_prop.csv"
		dbms=CSV replace;
	run;

	/* flex uses this file to test if the code has finished running */
	data _null_;
		v1= "dataset_prop_completed_completed";
		file "&input_path./datset_prop_completed_completed.txt";
		put v1;
	run;

%mend;

%propupdate;
