/*Successfully converted to SAS Server Format*/
*processbody;

/*--------------------------------------------------------------------------------------------------------*/
/*--                                                                                                  	--*/   
/*-- Functionality Name :  aggregated contribution        	--*/
/*-- Description  		:  generates 4 diferent csvs for different models in a scenario
/*-- Return type  		:  Creates CSV's at a location according to given inputs                        --*/
/*-- Author       		:  Saurabh vikash singh                         --*/                 
/*--------------------------------------------------------------------------------------------------------*/

/*%let codePath=/data20/UHG/murx///SasCodes//S8.5.1.1;*/
/*%let output_path= /data20/UHG/murx///projects/mmx21-20-Jan-2014-10-51-27/PublishedObjective/UHG_final_demo/sc;*/
/*			(the output path where the results will be placed);*/
/*%let input_path=/data20/UHG/murx///projects/mmx21-20-Jan-2014-10-51-27/1; */
/*			(the input path of in.dataworking on which the models have been built )*/
/*%let model_date_var=start_date; */
/*			(the date variable used while publishing)*/
/*%let date_range=from date||to date; */
/*			(the date range selected in the date filter)*/
/*%let fixedContribVariables=brand_atm||brand_tv||ntm_wd||..........; */
/*			(all the unique fixedContrib variables from all the iterations in the scenario);*/
/*%let depContribVariables=brand_tv_enrollmnt||ntm_wd_enrollment||brand_atm_enrollment||...........*/
/*			(the dependent variables of all the iterations in the scenario and this parameter should be linked to the model csv path parameter)*/
/*%let model_csv_path=/data20/UHG/murx///projects/mmx21-20-Jan-2014-10-51-27/PublishedObjective/UHG_final_demo/sc/LinearReg_CHANNELS_ndtc_unknown_enrollmnt_It1||/data20/UHG/murx///projects/mmx21-20-Jan-2014-10-51-27/PublishedObjective/UHG_final_demo/sc/LinearReg_CHANNELS_ndtc_SBU_others_enrollmnt_It1||.......;*/
/*			(the paths of the location where the result csvs are present of publish code)*/



options mprint mlogic symbolgen mfile;
dm log 'clear';

	
%macro agg_contri;

proc printto log="&output_path./aggregated_contribution.log";
run;
quit;

libname in "&input_path.";
libname out "&output_path.";

/*defining different csv path*/

data _null_;
call symput("model_csv_path",compress("&model_csv_path"));
run;
data _null_;
call symput("model_csv_path",tranwrd("&model_csv_path","AcrossDataset","Across Dataset"));
run;


%do i=1 %to %sysfunc(countw("&model_csv_path.","||"));
	%let cur_path=%scan("&model_csv_path.",&i.,"||");
	libname contri&i. "&cur_path.";
%end;

/*making the initial dataset rolling up the data for the same by date variable given*/

data _null_;
call symput("Date_start","%scan(&date_range.,1,"||")");
run;

data _null_;
call symput("Date_end","%scan(&date_range.,2,"||")");
run;

data dataworking;
	set in.dataworking;
	if "&Date_start."d <= &model_date_var. <= "&Date_end."d;
	run;


proc sort data=dataworking;
by &model_date_var.;
run;

proc contents data=dataworking out=cont;
run;

proc sql;
select name into:colnames separated by " " from cont where type = 1 and name <> "&model_date_var.";
quit;

proc means data=dataworking;
by &model_date_var.;
var &colnames.;
output out=dataworking;
run;

data dataworking(drop=_TYPE_);
    set dataworking;
    if _STAT_ = "MEAN";
    run;
data dataworking;
    set dataworking;
%do tem=1 %to %sysfunc(countw("&colnames."," "));
     %scan("&colnames.",&tem.," ")= _FREQ_ *%scan("&colnames.",&tem.," ");
%end;
run;

/*making the spends csv*/
data _null_;
call symput("fixedvar",tranwrd("&fixedContribVariables.","||"," "));
run;
data out.spends(keep=&fixedvar. &model_date_var.);
	set dataworking;
	run;	

/*making of spends csv ends here*/

/*making of contribution csv starts here*/
data contribution (keep=&model_date_var.);
	set dataworking;
	run;
proc sort data=contribution;
	by &model_date_var;
	run;
%let fixedContribVar=unattributed||&fixedContribVariables.;
%do k=1 %to %sysfunc(countw("&fixedContribVar.","||"));
%let cur_var=%scan("&fixedContribVar.",&k.,"||");
%let all_vars=;
%let mergedata=;
	%do l=1 %to %sysfunc(countw("&model_csv_path.","||"));
		proc contents data=contri&l..contribution out=cont;
		run;
		proc sql;
		select name into:colnames separated by "," from cont;
		quit;
		%do m=1 %to %sysfunc(countw("&colnames.",","));
			%let cur_match= %scan("&colnames.",&m.,",");
			%if "&cur_var." = "&cur_match." %then %do;
			%let all_vars=&all_vars. &cur_var&l.;
			data cur_contribution&l.(keep= &cur_var. &model_date_var. rename=(&cur_var=&cur_var&l.));
				set contri&l..contribution;
				run;
			%let mergedata=&mergedata. cur_contribution&l.;
			%end;
		%end;
	%end;
	data contribution;
		merge contribution &mergedata.;
		by &model_date_var.;
		run;	
	data _null_;
	call symput("all_vars1",tranwrd("&all_vars."," ",","));
	run;
	data contribution(drop=&all_vars.);
		set contribution;
		&cur_var.=sum(&all_vars1.);
		run;
	%end;

/*	replacing all missing with zeros*/

	data contribution; 
		set contribution;
		array nums _numeric_;
		do over nums;
 		if nums=. then nums=0;
 		end;
		run;

	data out.contribution;
		set contribution;
		run;
/*contribution csv calculation ends here*/

/*pre enrollment csv calculations starts here */

data pre_enrollment;
	set dataworking;
	run;
proc contents data=in.dataworking out=cont;
	run;
proc sql;
	select name into:colnames separated by "," from cont;
	quit;
%let keep_var=;
%do k=1 %to %sysfunc(countw("&fixedContribVariables.","||"));
	%let cur_var=%scan("&fixedContribVariables.",&k.,"||");
	%let counter=false;
	%do m=1 %to %sysfunc(countw("&colnames.",","));
		%let cur_match= %scan("&colnames.",&m.,",");
		%let keep_var=&keep_var &cur_var.; 
		%if &cur_match. = e_&cur_var. %then %do;
		data pre_enrollment(drop=&cur_var. rename=(&cur_match.=&cur_var.));
			set pre_enrollment;
			run;
		%let counter=true;
		%end;
	%end;
	%if "&counter." ne "true" %then %do;
		data pre_enrollment;
			set pre_enrollment;
			&cur_var.=0;
			run;
	%end;	
%end;
data out.pre_enrollment(keep=&keep_var. &model_date_var.);
	set pre_enrollment;
	run;
/*pre enrollment csv calculations ends here */

/* halo effect calculation starts here*/
%do k=1 %to %sysfunc(countw("&fixedContribVariables.","||"));
	%let cur_var=%scan("&fixedContribVariables.",&k.,"||");
	proc sql;
		select sum(&cur_var.) into: value from pre_enrollment;
		quit;
	data &cur_var.;
		format dependent_variables $32.;
		dependent_variables="pre modeling &cur_var.";
		&cur_var.=&value.;
		output;
		run;
	%do l=1 %to %sysfunc(countw("&depContribVariables.","||"));
		%let cur_dep_var=%scan("&depContribVariables.",&l.,"||");
		%if %index(&cur_dep_var.,&cur_var.) > 0 %then %do;
			%let elim_val=&l.;
			data cur_contri;
				set contri&l..contribution;
				run;	
			proc contents data=cur_contri out=cont;
			run;
			proc sql;
			select name into:cur_names separated by "," from cont where name not in ("panel_name","panel_level","&model_date_var.","unattributed","pred_dep",
			"actual_dep","pred_antilog_var","&cur_var.");
			quit;
			
			%do ab=1 %to %sysfunc(countw("&cur_names.",","));
				%let cur_variable=%scan("&cur_names.",&ab.,",");
				proc sql;
				select sum(&cur_variable.) into:sum_value from cur_contri;
				quit;
				data dummy;
					dependent_variables="&cur_variable.";
					&cur_var.=-&sum_value.;
					output;
					run;
				data &cur_var.;
					set &cur_var. dummy;
					run;
			%end;
		%end;
	%end;

	%do cd=1 %to %sysfunc(countw("&model_csv_path.","||"));
		%if "&cd." ne "&elim_val." %then %do;
			%let cur_dep_variable=%scan("&depContribVariables.",&cd.,"||");
			data cur_contri;
				set contri&cd..contribution;
				run;	
			proc contents data=cur_contri out=cont;
			run;
			proc sql;
			select name into:colnames separated by "," from cont;
			quit;
			%do mn =1 %to %sysfunc(countw("&colnames.",","));
			%if &cur_var. = %scan("&colnames.",&mn.,",") %then %do;
			proc sql;
				select sum(&cur_var.) into:value from cur_contri;
				quit;
			data dummy;
					dependent_variables="&cur_dep_variable.";
					&cur_var.=&value.;
					output;
					run;
				data &cur_var.;
					set &cur_var. dummy;
					run;
			%end;
			%end;
		%end;
	%end;

/*	proc sql;*/
/*		select sum(&cur_var.) into:value_final from &cur_var.;*/
/*		quit;*/
/**/
/*	proc sql;*/
/*		insert into &cur_var.*/
/*		set dependent_variables="post modeling &cur_var.",*/
/*			&cur_var. = &value_final.;*/

	data out.&cur_var.;
			set &cur_var.;
			run;
%end;
/* halo effect calculation ends here*/
%mend;

%agg_contri;