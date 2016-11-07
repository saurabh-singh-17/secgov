/*varify and save*/
options mprint mlogic symbolgen;

/*%let input_path =*/
/*	%let keepOption=CUSTOM;*/
/*%let output_path =*/
/*	%let output_path =*/
/*	%let customized = */
/*	%let customKey=4,5,6,7,8;*/
/*%let var_list = ACV;*/
/*%let scenarioName = abcd;*/
/*libname check"/product-development/murx/testfolder/test";*/
libname in "&inputPath";
libname out "&outputPath.";
%let number=%sysfunc(countw(&var_list.," "));
%put &number.;
%let var_name = murx_&scenarioName.;
%put &var_name.;
%let last_var=%scan(&var_list.,&number.," ");
%put &last_var.;

/*%let customKey_count=%sysfunc(countw(&customKey.," "));*/
%macro verify_save;
	%global nobs_dataworking duplicates_detected duplicates_deleted;

	proc sort data=in.dataworking;
		by &var_list.;
	run;

	quit;

	data records;
		set in.dataworking;
		by &var_list.;

		if first.&last_var. then
			do detected=1;
			end;
	run;

	proc sql;
		select count(*) into :duplicates_detected from records where missing(detected)=1;
	quit;

	%if "&keepOption." = "FIRST" %then
		%do;

			data in.dataworking;
				set in.dataworking;
				by &var_list.;

				if first.&last_var. then
					do &var_name.=1;
					end;
			run;

		%end;

	%if "&keepOption." = "LAST" %then
		%do;

			data in.dataworking;
				set in.dataworking;
				by &var_list.;

				if last.&last_var. then
					do &var_name.=1;
					end;
			run;

		%end;

	%if "&keepOption." = "CUSTOM" %then
		%do;
			/*			%let customKey=1,5,6,8;*/
			/*		data nodups;*/
			/*		set in.dataworking;*/
			/*		by &var_list.;*/
			/**/
			/*		if first.&last_var. and last.&last_var. then*/
			/*			output nodups;*/
			/*			run;*/
			/**/
			/*			%let dsid = %sysfunc(open(nodups));*/
			/*	%let nobs_nodups=%sysfunc(attrn(&dsid,nobs));*/
			/*	%let rc = %sysfunc(close(&dsid));*/
			/*	*/
			/*		%if "&nobs_nodups." ^= "0" %then*/
			/*		%do;*/
			/**/
			/**/
			/*		*/
			/*			proc sql;*/
			/*	select primary_key_1644 into: unique_key separated by "," from nodups ;*/
			/*	run;*/
			/*	quit;*/
			data in.dataworking;
				set in.dataworking;
				by &var_list.;

				if first.&last_var. and last.&last_var. then
					do &var_name.=1;
					end;

				if primary_key_1644 in (&customKey.) then
					do &var_name.=1;
					end;
			run;

		%end;

	%let dsid = %sysfunc(open(in.dataworking));
	%let nobs_dataworking=%sysfunc(attrn(&dsid,nobs));
	%let rc = %sysfunc(close(&dsid));
	%put &nobs_dataworking.;

	proc sql;
		select count(*) into :duplicates_deleted from in.dataworking where missing(murx_&scenarioName.)=1;
	quit;

	run;

	proc sort data=in.dataworking;
		by primary_key_1644;
	run;

%mend verify_save;

%verify_save;

data Statistics;
	length Statistics $ 50. Value $ 350.;
	infile datalines delimiter=',';
	input Statistics $ Value $;
	datalines;
Number of Observations,0
Number of Duplicates Detected,0
Number of Duplicates Removed,0
Keep Option,0
;
run;

data statistics;
	set statistics;

	if _n_ = 1 then;
	Value = resolve('&nobs_dataworking.');

	if _n_ = 2 then
		Value = resolve('&duplicates_detected. ');

	if _n_ = 3 then
		Value = resolve('&duplicates_deleted.');

	if _n_= 4 then
		Value= resolve('&keepOption.');
run;

proc export data=Statistics outfile="&outputPath./OBSERVATIONS.csv" dbms=CSV replace;
run;

quit;

proc export data=Statistics outfile="&outputPath./OBSERVATIONS.csv" dbms=CSV replace;
run;

quit;

data _null_;
	v1= "Completed";
	file "&outputPath./SCENARIO_COMPLETED.TXT";
	put v1;
run;
;