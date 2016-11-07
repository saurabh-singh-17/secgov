*processbody;
/*Mumix Contribution code*/
/*Date: 5/14/2013*/
/*Author: Ankesh*/

/*parameters required:*/

/*%let model_csv_path=model selected output path*/
/*%let output_path=output path for the csvs*/
/*%let group_path= input path of bygroupdata of that model*/
/*%let panel_level_name= south/supercentre/south#supercenter*/
/*%let panel_name=panel selected parameter*/
/*%let model_date_var=date variable chosen to publish*/

options mprint mlogic symbolgen mfile;

proc printto log="&output_path./contribution_Log.log";
	run;
	quit;
/*proc printto print="&output_path.\contribution_Output.out";*/
/*	run;*/
/*	quit;*/

/*Assigning libnames*/
libname group "&group_path.";

%macro contribution;
/*Importing the estimates csv*/
proc import datafile="&model_csv_path./estimates.csv"
	out = estimate
	dbms = csv
	replace;
	getnames=yes;
run;

/*Importing the normal_chart csv for actual and predicted values*/
%if %sysfunc(fileexist("&model_csv_path./transformed_chart.csv")) %then %do;
	%let csv = transformed_chart.csv;
%end;
%else %do;
	%let csv = normal_chart.csv;
%end;
proc import datafile="&model_csv_path./&csv."
	out = predicted
	dbms = csv
	replace;
	getnames=yes;
run;

/*Subsetting the dataset and renaming the columns*/
data actual_pred(keep= pred actual rename=pred=pred_dep rename=actual=actual_dep);
set predicted;
run;

/*Subsetting the dataset and deleting the row corresponding to the intercept*/
data estimate_no_intercept;
set estimate (keep= original_variable original_estimate);
original_estimate = round(original_estimate , .000000000000001);
if original_variable='Intercept' then delete;
run;

/*Creating macro variables*/
%let intercept_estimate=;
proc sql;
select original_estimate into: intercept_estimate from estimate where (original_variable = "Intercept");
quit;
proc sql;
select original_estimate into: var_estimates separated by " " from estimate_no_intercept;
quit;
proc sql;
select original_variable into: var separated by " " from estimate_no_intercept;
quit;

/*Creating the macro variables from the input parameters*/

data _null_;
call symput("panel_level",translate("&panel_level_name.","   ","#||"));
run;
%put &panel_level.;
data _null_;
call symput("panel_level",tranwrd("&panel_level.","  "," "));
run;
%put &panel_level.;

data _null_;
call symput("panel",translate("&panel_name.","   ","#||"));
run;
%put &panel.;
data _null_;
call symput("panel",tranwrd("&panel.","  "," "));
run;
%put &panel.;


/*Creating the union column*/
%if (%index(&panel_name. , #)) > 0 %then %do;
%let a = %scan(&panel_name.,1,"||");
data _null_;
 call symputx("abc" , tranwrd("&a.","#"," , "));
 run;
%put &abc.;

data group.bygroupdata;
 set group.bygroupdata;
 union = catx("_",&abc.);
 run;
%end;

/*Creating the contribution csv with estimates*var column*/
data contribution;
	set group.bygroupdata (keep= &var. %if (%index(&panel_name. , #)) > 0 %then %do; union %end; &panel. &model_date_var.);
		%do i=1 %to %sysfunc(countw(&var_estimates.," "));
		%let t = %scan(&var_estimates.,&i.," ");
		%scan(&var.,&i.) = %scan(&var.,&i.)*%sysevalf(&t.);
		%end;
	%if "&intercept_estimate."^="" %then %do;
	intercept = &intercept_estimate.;
	%end;
	date=&model_date_var.;
	run;

/*Merging with actual_pred to get these two columns*/
data contribution;
merge contribution actual_pred;
run;

/*Creating the macro variables with _ instead of hash*/
%if (%index(&panel_name. , #)) > 0 %then %do;
data _null_;
call symput("panel_level_hash",tranwrd("&panel_level_name.","#","_"));
run;
%put &panel_level_hash.;

data _null_;
call symput("panel_name_a",tranwrd("&panel_name.","#","_"));
run;
%put &panel_name_a.;
%end;

/*susetting the dataset on the basis of combination of the vars*/
%if (%index(&panel_name. , #)) > 0 %then %do;
%do i=1 %to %sysfunc(countw(&panel_level_hash.,"||"));
data contribution_combination&i.;
length panel_level $50.;
length panel_name $50.;
set contribution;
where union = "%scan(&panel_level_hash.,&i.,"||")";
panel_level = "%scan(&panel_level_hash.,&i,"||")";
panel_name = "%scan(&panel_name_a.,1,"||")";
run;

/*Appending the combination var datasets*/
	%if &i = 1 %then %do;
	data contribution_combination;
		set contribution_combination&i.;
		run;
	%end;
	%else %do;
	proc append base=contribution_combination data=contribution_combination&i. force;
	run;
	%end;
%end;
%end;


/*creating the macro variables from parameters*/
data _null_;
call symput("panel_level_ind",tranwrd("&panel_level_name.","||","#"));
run;
%put &panel_level_ind.;
data _null_;
call symput("panel_ind",tranwrd("&panel_name.","||","#"));
run;
%put &panel_ind.;

%macro m;
/* creating a dataset having all the panel and its corresponding levels */
data distinct;
	format panel_var $32.;
	format panel_lev $32.;
	%do i=1 %to %sysfunc(countw(&panel_level_ind.,"#"));
		panel_var= "%scan(&panel_ind.,&i.,"#")";
		panel_lev= "%scan(&panel_level_ind.,&i.,"#")";
		output;
	%end;
	run;
/* now seleting only those rows which are distinct in both the columns.*/
proc sql;
	create table distinct as
		select distinct * from distinct;

	select panel_var into:panel_ind separated by "#"
	from distinct;

	select panel_lev into:panel_level_ind separated by "#"
	from distinct;
	quit;
%put &panel_ind.;
%put &panel_level_ind.;

%mend;
%m;

/*Individual vars*/
%do i=1 %to %sysfunc(countw(&panel_level_ind.,"#"));
/*get vartype*/
		%let dsid = %sysfunc(open(contribution));
			%let varnum = %sysfunc(varnum(&dsid,%scan(&panel_ind., &i.,"#")));
			%let vartyp = %sysfunc(vartype(&dsid,&varnum)); /* variable type */
			%let rc = %sysfunc(close(&dsid));
		%put &vartyp;

/*subsetting the dataset on the basis of individual vars*/
data contribution&i.;
length panel_level $50.;
length panel_name $50.;
set contribution;
%if &vartyp. = N %then %do;
where %scan(&panel_ind.,&i.,"#") = %scan(&panel_level_ind.,&i.,"#");
%end;
%else %do;
where %scan(&panel_ind.,&i.,"#") = "%scan(&panel_level_ind.,&i.,"#")";
%end;
panel_level = "%scan(&panel_level_ind.,&i,"#")";
panel_name = "%scan(&panel_ind.,&i.,"#")";
run;

/*Appending the individual var datasets*/
%if &i = 1 %then %do;
data contribution_individual;
	set contribution&i.;
	run;
%end;

%else %do;
proc append base=contribution_individual data=contribution&i. force;
run;
%end;
%end;

/*deleting the temporary datasets*/
%if (%index(&panel_name. , #)) > 0 %then %do;
%do i=1 %to %sysfunc(countw(&panel_level_hash.,"||"));
proc datasets library=work;
   delete contribution_combination&i.;
run; 
%end;
%end;

%do i=1 %to %sysfunc(countw(&panel_level_ind.,"#"));
proc datasets library=work;
   delete contribution&i.;
run;
%end;

/*Appending all the datasets i.e. both combined and individual*/
%if %sysfunc(exist(contribution_combination)) %then %do;
proc append base=contribution_individual data = contribution_combination force;
run;
%end;

/*Dropping the unrequired columns*/
data contribution_final(drop = &panel. %if (%index(&panel_name. , #)) > 0 %then %do;union %end;);
	set contribution_individual;
	run;

/*Making the macro variable for rearranging*/
data _null_;
call symput("vars",tranwrd("&var."," ",","));
run;

libname out "&output_path.";

/*Rearranging the columns*/
	proc sql;
    create table out.contribution_final as
    select panel_name,panel_level,Date,intercept,&vars.,pred_dep,actual_dep
    from contribution_final;
    quit;


/*Exporting the contribution csv*/
proc export data = out.contribution_final
			outfile = "&output_path/contribution.csv"
			dbms = CSV replace;
			run;

%mend contribution;
%contribution;

/*Completed txt generated*/
data _NULL_;
		v1= "MUMIX-CONTRIBUTION_COMPLETED";
		file "&output_path./CONTRIBUTION_COMPLETED.txt";
		PUT v1;
run;