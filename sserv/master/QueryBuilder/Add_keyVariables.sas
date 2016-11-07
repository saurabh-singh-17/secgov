/*Parameters Required*/
/*%let input_path=E:\datasets C:\data E:\datasets;*/
/*%let output_path=E:\corr;*/
/*%let dataset_name = dataworking_linear_1 dataworking_new data12345; */
*processbody;
options mprint mlogic symbolgen mfile;
dm log 'clear';
FILENAME MyFile "&output_path./KeyVariable_SucessfullyAdded.txt";

DATA _NULL_;
	rc = FDELETE('MyFile');
RUN;

FILENAME MyFile1 "&output_path./Different_Values.txt";

DATA _NULL_;
	rc = FDELETE('MyFile1');
RUN;

FILENAME MyFile2 "&output_path./typecasting_error.txt";

DATA _NULL_;
	rc = FDELETE('MyFile2');
RUN;


proc printto log="&output_path./check_Log.log";
run;

quit;

libname out"&output_path.";

%macro Add_keyVariables;
	/*proc datasets lib = out;*/
	/*delete all_colnames key_variables;*/
	/*run;*/
	%global indicator;
	%let indicator = 1;

	%do i = 1 %to %sysfunc(countw(&dataset_name.));
		%let data= %scan(&dataset_name.,&i.);
		%let lib= %scan(&input_path.,&i.," ");
		libname in&i. "&lib.";
		%let var_name=%scan(&var_list.,&i.," ");
		%let dsid = %sysfunc(open(in&i..&data.));
		%let varnum = %sysfunc(varnum(&dsid,&var_name.));
		%put &varnum;
		%let current_vartype = %sysfunc(vartype(&dsid,&varnum)); /* variable type */
		%let rc = %sysfunc(close(&dsid));

		%if &i. > 1 %then
			%do;
				%if &current_vartype. ^= &previous_vartype. %then
					%let indicator = 0;
			%end;

		%let previous_vartype=&current_vartype.;
	%end;

	%put &indicator.;

%if &indicator.= 1 %then %do;
	%do i = 1 %to %sysfunc(countw(&dataset_name.));
		%let data= %scan(&dataset_name.,&i.);
		%let lib= %scan(&input_path.,&i.," ");
		libname in&i. "&lib.";
		%let var_name=%scan(&var_list.,&i.," ");

		data temp&i.(keep=&var_name. rename=(&var_name.=name&i.));
			set in&i..&data.;
		run;

	%end;

	data join;
		merge
			%do k = 1 %to %sysfunc(countw(&dataset_name.));
		temp&k.(in=a&k.)
		%end;;
	run;

	data join_check;
		set join;

		if %do m = 1 %to %eval(%sysfunc(countw(&dataset_name.))-1);
		name&m. =
		%end;

		name&m. then ind=1;
		else ind=0;

		if ind=0 then
			delete;
	run;

	%let new=join_check;
	%let dsid = %sysfunc(open(&new.));
	%let nobs =%sysfunc(attrn(&dsid.,NOBS));
	%let rc = %sysfunc(close(&dsid));
	%put &NOBS.;

	%if &NOBS. = . or &NOBS.=0 %then
		%do;

			data _null_;
				v1= "There are zero oberservation satisfying the selected condition";
				file "&output_path./Different_Values.txt";
				put v1;
			run;

		%end;
	%else
		%do;

			data _null_;
				v1= "key variables added sucessfully";
				file "&output_path./KeyVariable_SucessfullyAdded.txt";
				put v1;
			run;

		%end;
	 %end;
	  %else %do;
				data _null_;
				v1= "variable type are not matching";
				file "&output_path./typecasting_error.txt";
				put v1;
			run;
		%end;
%mend;

%Add_keyVariables;

/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "SUBSETING_COMPLETED";
	file "&output_path/COLNAMES_DATASET_COMPLETED.txt";
	put v1;
run;