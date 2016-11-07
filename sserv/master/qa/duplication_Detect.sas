/*====================================View duplicate part==============================*/
/*====================================parameters=======================================*/
/*%let input_path=*/
/*%let var_list = Store_Format geography;*/
/*%let output_path=;*/
options mlogic mprint symbolgen;
FILENAME MyFile "&outputPath./ERROR.TXT";

DATA _NULL_;
	rc = FDELETE('MyFile');
RUN;
/*proc printto file="&outputPath./DuplicateDetect.log";*/
/*run;*/
/*quit;*/
/*==============================setting the libraries====================================*/
/*libname in "/product-development/murx/testfolder";*/
libname in "&inputPath";
libname out "&outputPath.";
%let number=%sysfunc(countw(&var_list.," "));
%put &number.;
%let last_var=%scan(&var_list.,&number.," ");
%put &last_var.;
%let dsid = %sysfunc(open(in.dataworking));
%let nobs_dataworking=%sysfunc(attrn(&dsid,nobs));
%let rc = %sysfunc(close(&dsid));
%put &nobs_dataworking.;

%macro duplicates;
	/*=============getting the last var from the variable list=================================*/
	/*============================ Sorting the data============================== */
	proc sort data=in.dataworking(keep=&datasetVar. primary_key_1644);
		by &var_list.;
	run;

	/*==============This step finds the duplicates and gives a new data based on that============*/
	data dups;
		set in.dataworking;
		by &var_list.;

		if first.&last_var. and last.&last_var. then
			;
		else output dups;
	run;

	/*========In case there are no duplicates based on the selection giving error.txt=============*/
	%let dsid = %sysfunc(open(dups));
	%let nobs_dups=%sysfunc(attrn(&dsid,nobs));
	%let rc = %sysfunc(close(&dsid));
	%put &nobs_dups.;

	%if "&nobs_dups."="0" %then
		%do;

			data _null_;
				v1= "No duplicates detected for the current selection";
				file "&outputPath/ERROR.TXT";
				put v1;
			run;

		%end;

	/*============Flagging the dataset for automatic first occurence and last occurence selection====================*/
	data dups;
		set dups;
		by &var_list.;

		if first.&last_var. then
			do flag_F=1;
			end;
if last.&last_var. then 
do flag_L = 1;
end;
		murx_dp_levels+flag_F;
	run;
data _null_;
	V1= "&nobs_dups.";
	file "&outputPath/nobs.txt";
	put V1;
run;
%mend duplicates;

%duplicates;
;

data statistics;
	length Statistics $ 50. Value $ 350.;
	infile datalines delimiter=',';
	input Statistics $ Value $;
	datalines;
Number of Observations,
Number of Duplicates Detected,
Number of Duplicates Removed,
Keep Option,
;
run;

/*data work;*/
/*	set in.dataworking;*/
/*	by &var_list.;*/
/**/
/*	if first.&last_var. then*/
/*		do flag=1;*/
/*		end;*/
/*run;*/

proc sql;
	select count(*) into :nobs_duplicates from dups where missing(flag_F)=1;
quit;

data statistics;
	set statistics;

	if _n_ = 1 then
		Value = resolve('&nobs_dataworking.');

	if _n_ = 2 then
		Value = resolve('&nobs_duplicates.');

	/*		if _n_ = 3 then*/
	/*			value = resolve('&n_obs_a4.');*/
run;

data dups;
	retain murx_dp_levels &var_list.;
	set dups;
run;


/*=================================exporting the dataset to csv===================================*/
proc export data=dups outfile="&outputPath./duplicates.csv" dbms=CSV replace;
run;

quit;

proc export data=Statistics outfile="&outputPath./OBSERVATIONS.csv" dbms=CSV replace;
run;

quit;

/*============================Generating completed.txt============================================*/
data _null_;
	v1= "Completed";
	file "&outputPath/DUPLICATE_COMPLETED.TXT";
	put v1;
run;
