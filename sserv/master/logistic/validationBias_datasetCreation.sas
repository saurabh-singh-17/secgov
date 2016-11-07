/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path./VALIDATION_BIAS_DATASET_CREATION_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;

proc printto log="&output_path/ValidationBias_DatasetCreation_Log.log";
run;
quit;
/*proc printto print="&output_path./ValidationBias_DatasetCreation_output.out";*/

libname in "&input_path.";
libname group "&group_path.";
libname out "&output_path.";

%macro surveyselect;

	%if "&model_iteration." = "1" %then %do;
		%if %sysfunc(exist(group.bygroupdata)) %then %do;
			%put exists;
		%end;
		%else %do;
			%if "&grp_no" = "0" %then %do;
				data group.bygroupdata;
					set in.dataworking;
				run;
			%end;
			%else %do;
				data group.bygroupdata;
					set in.dataworking (where = (GRP&grp_no._flag = "&grp_flag."));
					run;
			%end;
		%end;
	%end;

%if "&strata." ^= "" %then %do;

	proc sort data = group.bygroupdata;
		by &strata.;
		run;

	proc surveyselect data = group.bygroupdata 
		method = srs samprate = %eval(&sample_rate.) seed = %eval(&seed.)
		out = dataworking_&sample_rate;
		strata &strata.;
		run;

%end;
%else %do;

	proc surveyselect data = group.bygroupdata 
		method = srs samprate = %eval(&sample_rate.) seed = %eval(&seed.)
		out = dataworking_&sample_rate;
		run;

%end;

data dataworking_&sample_rate;
	set dataworking_&sample_rate;
	&flag_name. = 1;
	run;

proc sort data = dataworking_&sample_rate;
	by primary_key_1644;
	run;
proc sort data = group.bygroupdata;
	by primary_key_1644;
	run;

data group.bygroupdata;
	merge group.bygroupdata(in=a) dataworking_&sample_rate(in=b);
	by primary_key_1644;
	if a or b;
	run;


data group.bygroupdata;
	set group.bygroupdata;
	if &flag_name. = . then &flag_name. = 0;
	run;

%mend surveyselect;
%surveyselect;

/* Flex uses this file to test if the code has finished running */
data _NULL_;
      v1= "Logistic Regression - VALIDATION_BIAS_DATASET_CREATION_COMPLETED";
      file "&output_path./VALIDATION_BIAS_DATASET_CREATION_COMPLETED.txt";
      PUT v1;
      run;

endsas;


