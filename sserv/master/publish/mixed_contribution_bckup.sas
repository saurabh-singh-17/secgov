*processbody;
/*Mumix MIXED Contribution code*/
/*Date: 5th Aug 2013*/
/*Author: Ankesh*/


/*parameters required:*/

/*%let model_csv_path=C:\Users\ankesh.aggrawal\MRx\sas\cluster_no-27-Jun-2013-11-16-10\1\0\1_1_1\MIXED\1\;*/
/*%let output_path=C:\Users\ankesh.aggrawal\MRx\sas\cluster_no-27-Jun-2013-11-16-10\1\0\1_1_1\MIXED\1\contribution;*/
/*%let group_path= C:\Users\ankesh.aggrawal\MRx\sas\cluster_no-27-Jun-2013-11-16-10\1\0\1_1_1;*/
/*%let randomVariables=channel_1;*/
/*%let independentVariables=ACV||black_hispanic||Chiller_flag||channel_1||sales||geography||Store_Format;*/
/*%let classVariables=geography||Store_Format;*/
/*%let dependentVariable=total_selling_area;*/
/*%let panel_name= geography#store_format#channel_2||geography#store_format#channel_2;*/
/*%let panel_level_name = north#Supercenter#0||north#Supercenter#1;*/
/*%let dependentTransformation=none;*/
/*%let independentTransformation=none||log||none||none||log||none||none;*/
/*%let model_date_var=Date;*/
/*%let baselineVariables=apr_flag||aug_flag||avg_temp;*/
/*%let baselineTransformation=none||none||none;*/
/*%let marketingVariables=coupon_per_store||direct_mail_per_store||google_impressions_per_store||newspaper_ads_per_store;*/
/*%let marketingTransformation=none||none||none||none;*/



options mprint mlogic symbolgen mfile;

data _null_;
call symput("output" ,tranwrd("&output.", "/  " , "/"));
call symput("output" ,tranwrd("&output.", "/ " , "/"));
call symput("baselineVariables" ,compress("&baselineVariables."));
call symput("baselineTransformation" ,compress("&baselineTransformation."));
call symput("marketingVariables" ,compress("&marketingVariables."));
call symput("marketingTransformation" ,compress("&marketingTransformation."));
run;
%put &output.;
proc printto log="&output./mixed_contribution_Log.log";
	run;
	quit;
/*proc printto print="&output.\mixed_contribution_Output.out";
	/*run;*/
	/*quit;*/

/*Assigning libnames*/
libname group "&group_path.";
libname out "&output.";

%macro mixed_contribution;
/*Importing the fixed effect estimates csv*/
proc import datafile="&model_csv_path./FixedEffect.csv"
	out = fixedeffect
	dbms = csv
	replace;
	getnames=yes;
	guessingrows=50;
	run;

/*Importing the random effect estimates csv*/
	%let a = "&model_csv_path./RandomEffect.csv";
%if %sysfunc(fileexist(&a.)) %then %do;
proc import datafile="&model_csv_path./RandomEffect.csv"
	out = randomeffect
	dbms = csv
	replace;
	getnames=yes;
	guessingrows=50;
	run;
%end;

/*Importing the normal_chart csv for actual and predicted values*/
%if %sysfunc(fileexist("&model_csv_path./transformed_chart.csv")) %then %do;
	%let csv = transformed_chart.csv;
%end;
%else %do;
	%let csv = normal_chart.csv;
%end;
proc import datafile="&model_csv_path./&csv."
	out = actualvspredicted
	dbms = csv
	replace;
	getnames=yes;
	guessingrows=50;
	run;


data _null_;
	call symput("independentVariables" , tranwrd("&independentVariables.","|| ","||"));
	run;
%put &independentVariables.;
%if "&classVariables." ^= "" %then %do;
data _null_;
	call symput("classVariables" , tranwrd("&classVariables.","|| ","||"));
	run;
%put &classVariables.;
%end;
data _null_;
	call symput("independentTransformation" , tranwrd("&independentTransformation.","|| ","||"));
	run;
%put &independentTransformation.;
%if "&randomVariables." ^= "" %then %do;
data _null_;
	call symput("randomVariables" , tranwrd("&randomVariables.","|| ","||"));
	run;
%put &randomVariables.;
%end;

%let class_in_fixed =;
%do e = 1 %to %sysfunc(countw(&classVariables.,"||"));
	%if %sysfunc(index("&independentVariables." , %scan("&classVariables." , &e. , "||"))) > 0 %then %do;
		%let class_in_fixed = &class_in_fixed %scan("&classVariables." , &e. , "||");
	%end;
%end;
%put &class_in_fixed.;
%let classVariables =&class_in_fixed.;


data fixedeffect1;
format variable $50.;
informat variable $50.;
length variable $50.;
	set fixedeffect;
	run;

%do i =1 %to %sysfunc(countw(&classVariables.," "));
%let class = %scan(&classVariables. , &i. , " ");
%put &class.;
	%if &i. = 1 %then %do;
	data fixedeffect1;
		set fixedeffect;
		if Variable = "&class." then delete;
		run;
	%end;
	%else %do;
	data fixedeffect1;
		set fixedeffect1;
		if Variable = "&class." then delete;
		run;
	%end;
%end;

data fixedeffect1(keep = Variable estimate);
	set fixedeffect1;
	length Variable $50.;
	format Variable $50.;
	informat Variable $50.;
	run;

%if "&randomVariables." ^= "" %then %do;
%if "&subject." = "" %then %do;
proc sql;
	create table random as select Variable , sum(Estimate) as estimate from Randomeffect
	group by Variable;
	quit;

	data random(keep = Variable estimate);
	set random;
	length Variable $50.;
	format Variable $50.;
	run;

proc append base = fixedeffect1 data = random force;
run;
quit;
%end;
%end;

proc sql;
create table fixedeffect1 as select Variable , sum(Estimate) as estimate from fixedeffect1
	group by Variable;
	quit;
%let random_var =;
%if "&randomVariables." ^= "" %then %do;
%if "&subject." ^= "" %then %do;
	data random_intercept (keep= variable estimate);
	set Randomeffect;
	where variable = "Intercept";
	run;
	proc append base = fixedeffect1 data = random_intercept force;
	quit;
	proc sql;
	create table fixedeffect1 as select Variable , sum(Estimate) as estimate from fixedeffect1
	group by Variable;
	quit;

	data Randomeffect;
	set randomeffect;
	if Variable = "Intercept" then delete;
	run;
proc sql;
select distinct(variable) into: random_var separated by " " from Randomeffect;
quit;
%end;
%end;
/*Subsetting the dataset and renaming the columns*/
data actualvspredicted(keep= predicted actual rename=predicted=pred_dep rename=actual=actual_dep);
	set actualvspredicted;
	run;

/*Subsetting the dataset and deleting the row corresponding to the intercept*/
data estimate_no_intercept;
set fixedeffect1(keep= variable estimate);
if Variable='Intercept' then delete;
run;

%if "&classVariables." ^= "" %then %do;
data _null_;
call symput("classvar" , tranwrd("&classVariables." , " " , ','));
run;
%put &classvar.;
data fixedeffect;
	set fixedeffect;
	classvar = compress(cat(&classvar.));
	run;
data class2;
	set fixedeffect;
	if classvar = "" then delete;
	run;
%end;


%let intercept_estimate=;
proc sql;
select estimate into: intercept_estimate from fixedeffect1 where (variable = "Intercept");
quit;
proc sql;
select estimate into: var_estimates separated by " " from estimate_no_intercept;
quit;
proc sql;
select variable into: var separated by " " from estimate_no_intercept;
quit;
%put &intercept_estimate.;
%put &var_estimates.;
%put &var.;

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
	set group.bygroupdata (keep= &var. %if (%index(&panel_name. , #)) > 0 %then %do; union %end; %if "&classVariables." ^= "" %then %do; &classVariables. %end; &panel. &model_date_var. %if "&subject." ^= "" %then %do;&random_var. &subject. %end;);
		%do i=1 %to %sysfunc(countw(&var_estimates.," "));
		%let t = %scan(&var_estimates.,&i.," ");
		%scan(&var.,&i.) = %scan(&var.,&i.)*%sysevalf(&t.);
		%end;
		%if "&intercept_estimate."^="" %then %do;
		intercept = &intercept_estimate.;
		%end;
		&model_date_var. = &model_date_var.;
		
		run;

/*Merging with actual_pred to get these two columns*/
data contribution;
merge contribution actualvspredicted;
run;

data contribution;
set contribution;
%if "&dependentTransformation."="log" %then %do;
pred_antilog_var = exp(pred_dep);
%end;
%else %do;
pred_antilog_var = pred_dep;
%end;
run;


%do i = 1 %to %sysfunc(countw(&classVariables. , " "));
	%let class_level = %scan(&classVariables. , &i. , " ");
	data class2_&i.(rename = Estimate = Estimate_&i.);
		set class2(keep = &class_level. Estimate);
		if &class_level. = "" then delete;
		run;

	proc sort data = contribution;
		by &class_level.;
		quit;
	proc sort data = class2_&i.;
		by &class_level.;
		quit;
	data contribution;
		merge contribution class2_&i.;
		by &class_level.;
		run;
%end;



%let distinct_variables =;
%if "&subject." ^= "" %then %do;
%if "&randomVariables." ^= "" %then %do;
		
	proc sort data = contribution;
		by &subject.;
		quit;
	proc sql;
	select distinct(Variable) into: distinct_variables separated by '||' from Randomeffect;
	quit;
	%let distinct_variables = %sysfunc(compress(&distinct_variables.));
	%put aaa&distinct_variables.aaa;
	%put &distinct_variables.;
	%do m = 1 %to %sysfunc(countw(&distinct_variables.));
	data random&m. (rename = estimate = rv&m.);
	set Randomeffect (keep = variable &subject. estimate);
	where Variable = "%scan(&distinct_variables.,&m.)";
	run;
	data random&m. (drop= variable);
	set random&m.;
	run;
	
	proc sort data = random&m.;
		by &subject.;
		quit;
	data contribution;
		merge contribution random&m.;
		by &subject.;
		run;
	data contribution;
	set contribution;
	%scan(&distinct_variables.,&m.) = %scan(&distinct_variables.,&m.)*rv&m.;
	run;
	%end;
	
%end;
%end;
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

data overall;
set contribution;
length panel_level $50.;
length panel_name $50.;
panel_name="Overall";
panel_level = "All";
run;

/*Appending all the datasets i.e. both combined and individual and overall*/

proc append base=contribution_individual data = overall force;
run;
/*Dropping the unrequired columns*/
data contribution_final(drop = &panel. %if (%index(&panel_name. , #)) > 0 %then %do;union %end;);
	set contribution_individual;
	run;

/*Making the macro variable for rearranging*/
data _null_;
call symput("vars",tranwrd("&var."," ",","));
run;

data contribution %if "&classVariables." ^= "" %then %do;(drop = &classVariables.) %end; ;
set contribution;
run;
data contribution_final %if "&classVariables." ^= "" %then %do;(drop = &classVariables.) %end; ;
set contribution_final;
run;

	%let name =;
	%let new_name=;
	%do t=1 %to %sysfunc(countw(&classVariables. , " "));
		%let name = &name. Estimate_&t.;
		%let new_name = &new_name. %scan("&classVariables." , &t. , " ");
	%end;
	%put &name.;
	%put &new_name.;
	%do q = 1 %to %sysfunc(countw(&classVariables. , " "));
	data contribution_final(rename = ( %scan(&name. , &q. , " ") = %scan(&new_name. , &q. , " ")) );
		set contribution_final;
		run;
	%end;
%if "&baselineVariables."^="" %then %do;
	%let baselineVariable =;
%do a=1 %to %sysfunc(countw(&baselineVariables.,"||"));
	%let baseline_var=%scan(&baselineVariables.,&a.,"||");
	%let baseline_trans=%scan(&baselineTransformation.,&a.,"||");
		%if "&baseline_trans."="none" %then %do;
	    %let baselineVariable = &baselineVariable. &baseline_var.;
		%end;
		%else %do;
        %let baselineVariable = &baselineVariable. log_&baseline_var.;
		%end;
%end;
%put &baselineVariable.;
%let baselineVariables = &baselineVariable.;
%put &baselineVariables.;
data _null_;
call symput("baselineVariables",tranwrd("&baselineVariables."," ","||"));
run;
%end;



%if "&baselineVariables."^="" %then %do;;
data _null_;
call symput("baseline_sum",tranwrd("&baselineVariables.","||","+"));
run;
%put &baseline_sum.;
data contribution_final;
set contribution_final;
intercept_baseline = %if "&intercept_estimate."^="" %then %do;intercept + %end;&baseline_sum.%if "&classVariables."^= "" %then %do;+ &classVariables. %end;;
run;
%end;
%else %do;
	%if "&intercept_estimate."^="" %then %do;
		data contribution_final;
		set contribution_final;
		intercept_baseline = intercept %if "&classVariables."^= "" %then %do;+ &classVariables. %end;;
		run;
	%end;
%end;
%let allbaseline = &baselineVariables.||&classVariables.;

data contribution_final;
	set contribution_final;
	%if "&intercept_estimate."^="" %then %do;
	intercept = intercept/intercept_baseline;
	%end;
	%do h= 1 %to %sysfunc(countw(&allbaseline. , "||"));
	%scan("&allbaseline." , &h. , "||") = %scan("&allbaseline." , &h. , "||")/intercept_baseline;
	%end;
	run;
/* calculation of absolute contribution values */
data contribution_final1;
	set contribution_final;
	%do k = 1 %to %sysfunc(countw(&marketingVariables. , "||"));
		%let chk_transform = %scan("&marketingTransformation." , &k. , "||");
		%put &chk_transform.;
		%if "&chk_transform." = "log" %then %do;
			%if "&dependentTransformation." = "log" %then %do;
				%if "&intercept_estimate."="" and "&baselineVariables.."="" %then %do;
				log_%scan("&marketingVariables." , &k. , "||") = (log_%scan("&marketingVariables." , &k. , "||")*(pred_antilog_var))/(pred_dep);
				%end;
				%else %do;
				log_%scan("&marketingVariables." , &k. , "||") = (log_%scan("&marketingVariables." , &k. , "||")*(pred_antilog_var-exp(intercept_baseline)))/(pred_dep-intercept_baseline);
				%end;
			%end;
			%else %do;
				log_%scan("&marketingVariables." , &k. , "||") = log_%scan("&marketingVariables." , &k. , "||");
			%end;
		%end;
		%else %do;
			%if "&dependentTransformation." = "log" %then %do;
				%if "&intercept_estimate."="" and "&baselineVariables.."="" %then %do;
				%scan("&marketingVariables." , &k. , "||") = (%scan("&marketingVariables." , &k. , "||")*(pred_antilog_var))/(pred_dep);
				%end;
				%else %do;
				%scan("&marketingVariables." , &k. , "||") = (%scan("&marketingVariables." , &k. , "||")*(pred_antilog_var-exp(intercept_baseline)))/(pred_dep-intercept_baseline);
				%end;
			%end;
			%else %do;
				%scan("&marketingVariables." , &k. , "||") = %scan("&marketingVariables." , &k. , "||");
			%end;
		%end;
	%end;

/*	%do q = 1 %to %sysfunc(countw(&classVariables. , " "));*/
/*	data contribution_final1(rename = ( %scan(&new_name. , &q. , " ") = %scan(&name. , &q. , " ")) );*/
/*		set contribution_final1;*/
/*		run;*/
/*	%end;*/
	%if "&name."^= "" %then %do;
	data _null_;
		call symput("namess" , tranwrd("&new_name." , " " , ','));
		run;
		%put &namess.;
	%end;
	%let pp=;
	%if %sysfunc(fileexist(&a.)) %then %do;
	%if "&subject." = "" %then %do;
			proc sql;
			select variable into: pp separated by ' ' from randomeffect;
			quit;
	%end;
	%end;
	
		data contribution_final1;
			set contribution_final1;
			%if "&dependentTransformation." = "log" %then %do;
/*			%do w = 1 %to %sysfunc(countw(&classVariables. , " "));*/
/*					%if "&intercept_estimate."^="" %then %do;*/
/*					Estimate_&w. = (Estimate_&w. * (pred_antilog_var-exp(intercept)))/(pred_dep-intercept);*/
/*					%end;*/
/*					%else %do;*/
/*					Estimate_&w. = (Estimate_&w. * (pred_antilog_var))/(pred_dep);*/
/*					%end;*/
/*				%end;*/
			%if "&subject." ^= "" %then %do;
			%do c = 1 %to %sysfunc(countw(&distinct_variables.,"||"));
				%if "&intercept_estimate."^="" %then %do;
					%scan(&distinct_variables.,&c.,"||") = %scan(&distinct_variables.,&c.,"||")*(pred_antilog_var-exp(intercept))/(pred_dep-intercept);
				%end;
				%else %do;
					%scan(&distinct_variables.,&c.,"||") = %scan(&distinct_variables.,&c.,"||")*(pred_antilog_var)/(pred_dep);
				%end;	
			%end;
			%end;
			 
			%do a=1 %to %sysfunc(countw(&pp.,' '));
				%if "&intercept_estimate."^="" %then %do;
				%scan(&pp.,&a.," ") = %scan(&pp.,&a.," ")*(pred_antilog_var-exp(intercept))/(pred_dep-intercept);
				%end;
				%else %do;
				%scan(&pp.,&a.," ") = %scan(&pp.,&a.," ")*(pred_antilog_var)/(pred_dep);
				%end;
			%end;
			intercept_baseline = exp(intercept_baseline);
			%end;
			run;

			data contribution_final1;
				set contribution_final1;
				%if "&intercept_estimate."^="" %then %do;
				intercept = intercept * intercept_baseline;
				%end;
				%do t= 1 %to %sysfunc(countw(&allbaseline. , "||"));
					%scan("&allbaseline." , &t. , "||") = %scan("&allbaseline." , &t. , "||")*intercept_baseline;
				%end;
				run;

	%if "&subject." ^="" %then %do;
	
	data _null_;
	call symput("distinct_variabless",tranwrd("&distinct_variables.","||",","));
			run;
	%end;
	/*Rearranging the columns*/
	proc sql;
    create table contribution_final2 as
    select panel_name,panel_level,&model_date_var.,%if "&intercept_estimate."^="" %then %do;intercept,%end;&vars.,pred_dep,actual_dep,%if "&subject" ^= "" %then %do;%if "&randomVariables." ^= "" %then %do;&distinct_variabless., %end;%end;pred_antilog_var
    from contribution_final1;
    quit;

	
%if "&classVariables."^= "" %then %do;
	data contribution_final3 (keep = &namess.);
	set contribution_final1;
	run;
	data contribution_final1;
	merge contribution_final2 contribution_final3;
	run;
%end;
%else %do;
	
	data contribution_final1;
	set contribution_final2;
	run;
%end;


/*	%do q = 1 %to %sysfunc(countw(&classVariables. , " "));*/
/*		data contribution_final1(rename = ( %scan(&name. , &q. , " ") = %scan(&new_name. , &q. , " ")) );*/
/*			set contribution_final1;*/
/*			run;*/
/*	%end;*/

	%macro subset;
	proc sql;
	select distinct(panel_name) into: distinct_name separated by '||' from contribution_final1;
	quit;
	%put &distinct_name.;
	%do l=1 %to %sysfunc(countw(&distinct_name.,'||'));
		proc sql;
		select distinct(panel_level) into: distinct_level separated by '||' from contribution_final1
		where panel_name = "%scan(&distinct_name.,&l.,'||')";
		quit;
		
		%put &distinct_level.;
		%do n=1 %to %sysfunc(countw(&distinct_level.,'||'));
			data subset&l.&n.;
			set contribution_final1;
			where panel_level = "%scan(&distinct_level.,&n.,'||')" and panel_name = "%scan(&distinct_name.,&l.,'||')";
			run;
			/*Sorting it with date variable	*/
			proc sort data=subset&l.&n. out=subset&l.&n.;
			by &model_date_var.;
			run;

			/*Making the macro variable for rearranging*/
			data _null_;
			call symput("varss",tranwrd("&vars.",",","||"));
			run;
			%if "&classVariables."^="" %then %do;
			data _null_;
			call symput("classs",tranwrd("&new_name."," ","||"));
			run;
			%end;
			/*Grouping by date variable to find the unique date value column*/
			proc sql;
			create table subsett&l.&n. as select distinct(&model_date_var.),panel_name,panel_level,%if "&intercept_estimate."^="" %then %do;sum(intercept) as intercept,%end;
			%do m=1 %to %sysfunc(countw(&varss.,'||'));
				sum(%scan(&varss.,&m.,'||')) as %scan(&varss.,&m.,'||') ,
			%end; 
			%if "&classVariables."^="" %then %do;
				%do p=1 %to %sysfunc(countw(&classs.,'||'));
					sum(%scan(&classs.,&p.,'||')) as %scan(&classs.,&p.,'||') ,
				%end;
			%end; 
			%if "&subject."^= "" %then %do;
				%do m=1 %to %sysfunc(countw(&distinct_variables.,'||'));
					sum(%scan(&distinct_variables.,&m.,'||')) as %scan(&distinct_variables.,&m.,'||'),
				%end;
			%end;
			sum(pred_dep) as pred_dep,sum(actual_dep) as actual_dep,sum(pred_antilog_var) as pred_antilog_var from subset&l.&n. group by &model_date_var.;
			quit;
				/*Appending the combination var datasets*/
				%if &n. = 1 %then %do;
				data contri&l.;
					set subsett&l.&n.;
					run;
				%end;
				%else %do;
				proc append base=contri&l. data=subsett&l.&n. force;
				run;
				%end;
		%end;
			%if &l. = 1 %then %do;
				data contri_final;
					set contri&l.;
					run;
				%end;
				%else %do;
				proc append base=contri_final data=contri&l. force;
				run;
				%end;

	%end;
%mend;
%subset;
	%if "&intercept_estimate."^="" %then %do;
	data contri_final (rename= intercept = unattributed);
	set contri_final;
	run;
	%end;
	%else %do;
	data contri_final;
	set contri_final;
	unattributed = 0;
	run;
	%end;
	data out.contribution;
		set contri_final;
		run;

/*Exporting the contribution csv*/
	proc export data = contri_final
			outfile = "&output/contribution.csv"
			dbms = CSV replace;
			run;



%macro equation;

proc sql;
select distinct(&classVariables.) into: distinct_classs separated by '||' from group.bygroupdata;
quit;
%put &distinct_classs.;
/*data _null_;*/
/*call symput("distinct_classs",translate("&distinct_classss.","!@#$%^&*()/\ ","_____________"));*/
/*run;*/
/*%put &distinct_class.;*/
data _null_;
call symput("distinct_class",compress("&distinct_classs.","!@#$%^&*()/\ "));
run;
%put &distinct_class.;


data _NULL_;
		v1= "&distinct_class.";
		file "&output./DISTINCT_CLASSVAR.txt";
		PUT v1;
	run;
data fixedeffect1 (rename= (Variable = variable estimate = Estimate));
format variable $50.;
length variable $50.;
informat variable $50.;
set fixedeffect1;
%if "&classVariables." ^= "" %then %do;
%do f = 1 %to %sysfunc(countw(&distinct_class.,'||'));
variable&f. = cats(variable,'_',"%scan(&distinct_class.,&f.,'||')");
if substr(Variable&f.,1,4) = "log_" then variable&f. = tranwrd(Variable&f.,"log_","log(");
if substr(Variable&f.,1,4) = "log(" then variable&f. = cats(Variable&f.,"&aliasmodelname.",")");
else variable&f. = cats(variable&f.,"_&aliasmodelname.");
if Estimate>=0 then 
paramestimat&f. = cats(Estimate,"*",variable&f.);
else paramestimat&f. = cats("(",Estimate,")","*",Variable&f.);
%end;
%end;

if substr(Variable,1,4) = "log_" then variable = tranwrd(Variable,"log_","log(");
if substr(Variable,1,4) = "log(" then variable = cats(Variable,"_&aliasmodelname.",")");
else variable = cats(variable,"_&aliasmodelname.");
if Estimate>=0 then 
paramestimat = cats(Estimate,"*",variable);
else paramestimat = cats("(",Estimate,")","*",Variable);
run;

%if "&intercept_estimate."^="" %then %do;
proc sql;
	select paramestimat into:rhs_int separated by ' + ' from fixedeffect1 where Variable = "Intercept_&aliasmodelname.";
	quit;
	%put &rhs_int.;
	%let rhs_intercept = %sysfunc(tranwrd(&rhs_int.,*Intercept_&aliasmodelname.,));

%end;

	%if "&classVariables." ^= "" %then %do;
	%do b = 1 %to %sysfunc(countw(&distinct_class.,'||'));	
		proc sql;
		select paramestimat&b. into:rhs&b. separated by ' + ' from fixedeffect1 where Variable^= "Intercept_&aliasmodelname.";
		quit;
		%put &&rhs&b.;
			%if "&intercept_estimate."^="" %then %do;
			%let final&b.=&rhs_intercept. + &&rhs&b.;
			%put &&final&b.;
			%end;
			%else %do;
			%let final&b.=&&rhs&b.;
			%put &&final&b.;
			%end;
	%end;
	%end;
	%else %do;
		proc sql;
		select paramestimat into:rhs separated by ' + ' from fixedeffect1 where Variable^= "Intercept_&aliasmodelname.";
		quit;
		%put &rhs.;
			%if "&intercept_estimate."^="" %then %do;
			%let final=&rhs_intercept. + &rhs.;
			%put &final.;
			%end;
			%else %do;
			%let final=&rhs.;
			%put &final.;
			%end;
	%end;

/*%if %sysfunc(fileexist(&a.)) %then %do;*/
/*%if "&subject." ^= "" %then %do;*/
/*data randomeffect;*/
/*set randomeffect;*/
/*if substr(Variable,1,4) = "log_" then variable = tranwrd(Variable,"log_","log(");*/
/*if substr(Variable,1,4) = "log(" then variable = cats(Variable,")");*/
/*%if "&classVariables." ^= "" %then %do;*/
/*%do f = 1 %to %sysfunc(countw(&distinct_class.,'||'));*/
/*variable&f. = variable;*/
/*variable&f. = cats(variable,'_',"%scan(&distinct_class.,&f.,'||')");*/
/*if substr(Variable&f.,1,4) = "log_" then variable&f. = tranwrd(Variable&f.,"log_","log(");*/
/*if substr(Variable&f.,1,4) = "log(" then variable&f. = cats(Variable&f.,"&aliasmodelname.",")");*/
/*else variable&f. = cats(variable&f.,"_&aliasmodelname.");*/
/*if Estimate>=0 then */
/*paramestimat&f. = cats(Estimate,"*",variable&f.);*/
/*else paramestimat&f. = cats("(",Estimate,")","*",Variable&f.);*/
/*%end;*/
/*%end;*/
/*if substr(Variable,1,4) = "log_" then variable = tranwrd(Variable,"log_","log(");*/
/*if substr(Variable,1,4) = "log(" then variable = cats(Variable,")");*/
/*equation = cats(variable,'_',&subject.,'_',"&aliasmodelname.");*/
/*if Estimate>=0 then */
/*paramestimat = cats(Estimate,"*",equation);*/
/*else paramestimat = cats("(",Estimate,")","*",equation);*/
/*run;*/
/*%end;*/
/*%else %do;*/
/*data randomeffect;*/
/*set randomeffect;*/
/*if substr(Variable,1,4) = "log_" then variable = tranwrd(Variable,"log_","log(");*/
/*if substr(Variable,1,4) = "log(" then variable = cats(Variable,"_&aliasmodelname.",")");*/
/*equation = variable;*/
/*if Estimate>=0 then */
/*paramestimat = cats(Estimate,"*",equation);*/
/*else paramestimat = cats("(",Estimate,")","*",equation);*/
/*run;*/
/*%end;*/
/*proc sql;*/
/*select paramestimat into:rhs_random separated by ' + ' from randomeffect;*/
/*quit;*/
/*%put &rhs_random.;*/
/**/
/*%let final=&final. + &rhs_random.;*/
/*%put &final.;*/
/*%end;*/

	%if "&classVariables." ^= "" %then %do;
		data class2;
		set class2;
		equation = cats(variable,'_',classvar,'_',"&aliasmodelname.");
		if Estimate>=0 then 
		paramestimat = cats(Estimate,"*",equation);
		else paramestimat = cats("(",Estimate,")","*",equation);
		run;
		data class2;
		set class2;
		paramestimat = compress(paramestimat,"!@#/\ ");
		run;
		proc sql;
		select paramestimat into:rhs_class separated by ' + ' from class2;
		quit;
		%put &rhs_class.;
		%let eqn_final=;
/*		%let final=&final. + &rhs_class.;*/
/*		%put &final.;*/
		%let dep = &dependentVariable.;
			%do q = 1 %to %sysfunc(countw(&rhs_class.,'+'));
				%if "&dependentTransformation." = "log" %then %do;
				%let eqn&q.= (exp(&&final&q. + %scan(&rhs_class.,&q.,'+')));
				%end;
				%else %do; 
				%let eqn&q.= (&&final&q. + %scan(&rhs_class.,&q.,'+'));
				%end;
				%put &&eqn&q.;
				%let eqn_final = &eqn_final. + &&eqn&q.;
			%end;
			%let eqn=&dep. = &eqn_final;
			%put &eqn;
	%end;
	%else %do;
		%let dep = &dependentVariable.;
			%if "&dependentTransformation." = "log" %then %do;
			%let eqn=&dep. = exp(&final.);
			%end;
			%else %do; 
			%let eqn=&dep. = &final.;
			%end;
			%put &eqn;
	%end;
	
	data _NULL_;
		v1= "&eqn.";
		file "&output./MODEL_EQUATION.txt";
		PUT v1;
	run;
data fixedeffect_beta;
set fixedeffect1;
if variable = "Intercept_&aliasmodelname." then delete;
run;
data intercept_beta (keep= variable estimate);
length variable $200.;
set fixedeffect1;
if variable = "Intercept_&aliasmodelname." then output;
run;
%do f = 1 %to %sysfunc(countw(&distinct_class.,'||'));
	data fixedeffect%eval(&f. + 5) (keep=variable&f. Estimate);
	set fixedeffect_beta;
	run;
	data fixedeffect%eval(&f. + 5) (rename=variable&f. = variable);
	set fixedeffect%eval(&f. + 5);
	run;
proc append base=intercept_beta data=fixedeffect%eval(&f. + 5) force;
quit;
%end;

	data class2 (rename=(equation = variable));
	set class2 (drop= variable);
	run;
	data class2(keep=variable estimate);
	set class2;
	run;
	data class2;
	set class2;
	variable = compress(variable,"!@#$%^&\/");
	run;
/*	data randomeffect (rename=(equation = variable));*/
/*	set randomeffect (drop= variable);*/
/*	run;*/
/*	data randomeffect(keep=variable estimate);*/
/*	set randomeffect;*/
/*	run;*/
	proc append base=intercept_beta data=class2 force;
	quit;
/*	proc append base=fixedeffect1 data=randomeffect force;*/
/*	quit;*/

proc sort data=intercept_beta;
	by variable;
	run;
	quit;
	/*Exporting the contribution csv*/
	proc export data = intercept_beta
			outfile = "&output./parameter.csv"
			dbms = CSV replace;
			run;

proc freq data=group.bygroupdata;
tables &classVariables./out =  a;
quit;
data a (drop=percent rename=(&classVariables. =  level count = nobs));
set a;
run;
data a;
set a;
level = compress(level,"!@#$%^&*()/\ ");
run;
proc export data =a
			outfile = "&output./no_of_records.csv"
			dbms = CSV replace;
			run;




%mend equation;
%equation;


%mend mixed_contribution;
%mixed_contribution;

/*Completed txt generated*/
data _NULL_;
		v1= "MUMIX-CONTRIBUTION_COMPLETED";
		file "&output./CONTRIBUTION_COMPLETED.txt";
		PUT v1;
run;


