/*%let codePath=/data22/IDev/Mrx//SasCodes//S8.6.0.2;*/
/*%let input_path = /data22/IDev/Mrx/projects/PGD_anvita_ZipCheck-18-Feb-2014-11-12-26/4;*/
/*%let output_path = /data22/IDev/Mrx/projects/PGD_anvita_ZipCheck-18-Feb-2014-11-12-26/4/0;*/
/*%let dataset_name = dataworking;*/
/*%let dateVarName = IrNo;*/
/*%let grp_no = 0 1 1 2 2 2;*/
/*%let levels = acrossDataset!!north!!south!!Super Combo!!Supercentre!!Supermarket ;*/
/*%let panel_name = acrossdataset!!geography!!geography!!Store_Format!!Store_Format!!Store_Format;*/
/*%let grp_flag = 1_1_1 1_1_1 2_1_1 2_1_1 3_1_1 4_1_1 ;*/
/*%let levels = ;*/
/*%let grp_no = 0;  */
/*%let grp_flag = 1_1_1;*/
/*%let panel_name = acrossDataset;*/

/*	Description		: Date validation for correlation and transformation */
/*	Created Date	: 13FEB2014*/
/*	Author(s)		: Anvita Srivastava*/

options mprint mlogic symbolgen mfile;

libname in "&input_path.";
libname out "&output_path.";

dm log 'clear';

proc printto log="&output_path./date_validation_config.log";
run;

/*proc printto;*/
/*run;*/

/* log="&output_path./date_validation_config.log"*/

FILENAME MyFile "&output_path./DATE_VAL_WARNING.txt";

DATA _NULL_;
	rc = FDELETE('MyFile');
RUN;

FILENAME MyFile "&output_path./DATE_VAL_COMPLETED.txt";

DATA _NULL_;
	rc = FDELETE('MyFile');
RUN;

%macro lag_lead;

proc contents data=in.&dataset_name. out=contents(keep=name format formatl);
run;
quit;

proc sql;
select format,formatl into :format_date, :formatl_date from contents where name = "&dateVarName.";
run;
quit;

%let format_date = &format_date.&formatl_date..;

data _null_;
call symput("final_format",compress("&format_date."));
run;

%put &final_format.;
%let v1 =;
%let p1 =;
%let p2 =;
%let v2 =;
%do j = 1 %to %sysfunc(countw("&grp_no."," "));

	%let grpLevel = %scan("&grp_no.",&j.," ");
	%let grpLevel_flag = %scan("&grp_flag.",&j.," ");
	%let grpLevel_name = %scan("&levels.",&j.,"!!");
	%let panelLevel_name = %scan("&panel_name.",&j.,"!!");


		data temp(keep=&dateVarName.);
			set in.&dataset_name.;

			%if &grpLevel.^= 0 %then
				%do;
					where grp&grpLevel._flag = "&grpLevel_flag.";
				%end;
		run;

	proc sort data=temp out=temp;
	by &dateVarName.;
	run;
	quit;

	data temp;
	set temp;
	format lagDate &final_format.;
	lagDate = lag1(&dateVarName.);
	run;

	data temp;
	set temp;
	format intervalDate &final_format.;
	intervalDate = &dateVarName. - lagDate;
	run;

	data temp;
	set temp;
	date_final = put(&dateVarName.,&final_format.);
	run;

	proc sql ;
	select count(distinct date_final), count(date_final), count(distinct intervalDate)  into: unique_date , :total_date ,:interval_unique from temp;
	run;
	quit;

	%if "&unique_date." ^= "&total_date." %then %do;
/*		%let v1 = "Date variable is not unique";*/
		%let x1 = "Variable &dateVarName. is not unique ";
		%let p1 = &p1. / "&panelLevel_name. &grpLevel_name.";
	%end;
	
	%if &interval_unique. ^= 1 %then %do;
		%let p2 = &p2. / "&panelLevel_name. &grpLevel_name.";
		%let x2 =;
		%if %length(&v1.) ^= 0 %then %do;
/*			%let v1 = &v1. " and has no regular interval";*/
			%let x1 = &x1. " and has no regular interval";
		%end;
		%else %do;
/*			%let v1 = "Date variable has no regular interval";*/
			%let x1 = "Variable &dateVarName. has no regular interval";
			%let x2 =;
		%end;
	%end;
%end;

%if %length(&p1.) ^= 0 or %length(&p2.) ^= 0 %then %do;
	%if %length(&p2.) ^= 0  & "&levels." ^= "acrossDataset" %then  %do;
		%let v2 = "The following panels have irregular intervals of &dateVarName." &p2.;
	%end;
	%if %length(&v1.) ^= 0  & "&levels." ^= "acrossDataset" %then %do;
		%let v1 = "The following panels have non unique values of &dateVarName." &p1.;
	%end;

	%if "&levels." = "acrossDataset" %then %do;
		%if %length(&v1.) ^= 0 %then %do;
			%let v1 = "Variable &dateVarName. is not unique";
			%let x1 = "Variable &dateVarName. is not unique";
			%if %length(&v2.) ^= 0 %then %do;
				%let v1 = &v1. " and has no regular interval";
				%let x1 = &x1. " and has no regular interval";
			%end;
		%end;
		%else %do;
			%if %length(&v2.) ^= 0 %then %do;
				%let v2 =  "Date variable has no regular interval";
				%let x2 = "Variable &dateVarName. has no regular interval";
			%end;
		%end;

	%end;
	data _null_;
		file "&output_path./DATE_VAL_WARNING.txt";
		put &v1.;
		put &v2.;
		run;
	data _null_;
		file "&output_path./DATE_VAL_TRA_WARNING.txt";
		put &x1.;
		put &x2.;
		run;
%end;
%else %do;
	data _null_;
		file "&output_path./DATE_VAL_COMPLETED.txt";
		put "Date validation completed";
		run;
%end;

%mend;
%lag_lead;


proc datasets lib=work kill nolist;
quit;