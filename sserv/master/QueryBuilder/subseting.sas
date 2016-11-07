*PROCESSBODY;

options mprint mlogic symbolgen mfile;
dm log 'clear';
FILENAME MyFile "&output_path./No_observation.txt";

DATA _NULL_;
	rc = FDELETE('MyFile');
RUN;

proc printto log="&output_path./subset_Log.log";
run;
quit;
/*proc printto print="&output_path./subset_Output.out";*/
 
libname in "&input_path.";
libname out "&output_path.";

%macro subseting;
proc sql;
create table out.&new_Dataset_name. as
	select * from in.&dataset_name WHERE &condition.;
	quit;
%let new=out.&new_Dataset_name.;
	%let dsid = %sysfunc(open(&new.));
		%let nobs =%sysfunc(attrn(&dsid.,NOBS));
		%let rc = %sysfunc(close(&dsid));
		%put &NOBS.;
		%if &NOBS. = 0 %then %do;
			data _null_;
	      		v1= "There are zero oberservation satisfying the selected condition";
	      		file "&output_path./No_observation.txt";
	      		put v1;
				run;
				%end;
				
%mend subseting;
%subseting;

	proc export data = out.&new_Dataset_name.
		outfile = "&output_path./&new_Dataset_name..csv"
		dbms = csv replace;
		run;

	ods output members = properties(where=(lowcase(name)=lowcase("&new_Dataset_name.")) keep=name obs vars FileSize);
		proc datasets details library = out;
			run; 
			quit ;

		/*libname prop xml "&output_path./dataset_properties.xml";*/
		data properties;
			set properties(rename =(name=file_name obs=no_of_obs vars=no_of_vars fileSize = file_size));
			format file_size 12.4;
			file_size = file_size/(1024*1024);
			run;

		/*CSV export*/
		 proc export data = properties
			outfile="&output_path/dataset_properties.csv"
			dbms=CSV replace;
			run;

/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "SUBSETING_COMPLETED";
	file "&output_path/SUBSETING_COMPLETED.txt";
	put v1;
run;

