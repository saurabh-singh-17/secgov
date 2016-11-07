*processbody;
/*Mumix MIXED Contribution code*/
/*Date: 5th Aug 2013*/
/*Author: Ankesh*/


/*parameters required:*/

/*%let codePath=/data1/IDev/Mrx//SasCodes//G8.4.2;*/
/*%let model_csv_path=/data1/IDev/Mrx//projects/pg_abc-17-Oct-2013-11-26-20/4/0/1_1_1/MIXED/1/3;*/
/*%let output_path=/data1/IDev/Mrx//projects/pg_abc-17-Oct-2013-11-26-20/PublishedObjective/bo_with2class/sc_with2class/MixedModeling_Across Dataset__sales_per_store_It3;*/
/*%let group_path=/data1/IDev/Mrx//projects/pg_abc-17-Oct-2013-11-26-20/4/0/1_1_1;*/
/*%let panel_name=MARKET||MARKET;*/
/*%let panel_level_name=Florida||Georgia;*/
/*%let model_date_var=week_start_date;*/
/*%let classVariables=market||new_year_flag;*/
/*%let randomVariables=;*/
/*%let dependentVariable=sales_per_store;*/
/*%let independentVariables=coupon_per_store||direct_mail_per_store||gdp||google_impressions_per_store||*/
/*income||market||new_year_flag||tv_trps_per_store||*/
/*unemp_rate;*/
/*%let dependentTransformation=none;*/
/*%let independentTransformation=none||none||none||none||*/
/*none||none||none||none||*/
/*none;*/
/*%let subject=;*/
/*%let aliasmodelname=P1;*/
/*%let baselineVariables=gdp||income||market||new_year_flag||unemp_rate;*/
/*%let baselineTransformation=none||none||none||none||none;*/
/*%let marketingVariables=coupon_per_store||direct_mail_per_store||google_impressions_per_store||tv_trps_per_store;*/
/*%let marketingTransformation=none||none||none||none;*/
/*%let fixedEquationVariables=coupon_per_store||log(lead_direct_mail_per_store)||gdp||log(google_impressions_per_store)||*/
/*income||market||new_year_flag||tv_trps_per_store||unemp_rate;*/
/*%let fixedContribVariables=coupon_per_store||direct_mail_per_store||gdp||google_impressions_per_store||*/
/*income||market||new_year_flag||tv_trps_per_store||unemp_rate;*/
/*%let depEquationVariables=sales_per_store;*/
/*%let depContribVariables=sales_per_store;*/
/*%let randomEquationVariables=;*/
/*%let randomContribVariables=;*/


options mprint mlogic symbolgen mfile;

/*Truncating the extra spaces in the parameter*/
data _null_;
call symput("output_path" , tranwrd("&output_path." , "/  " , "/"));
call symput("output_path" , tranwrd("&output_path." , "/ " , "/"));
call symput("baselineVariables" , compress("&baselineVariables"));
call symput("baselineTransformation" , compress("&baselineTransformation."));
call symput("marketingVariables" , compress("&marketingVariables"));
call symput("
marketingTransformation" , compress("&marketingTransformation"));
run;

proc printto log="&output_path./mixed_contribution_Log.log";
	run;
	quit;
/*proc printto print="&output_path.\mixed_contribution_Output.out";
	/*run;*/
	/*quit;*/

/*Assigning libnames*/
libname group "&group_path.";
libname out "&output_path.";

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

/*Truncating the extra spaces in the parameter*/
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

/*Changing the class variable parameter according to the class variables choosen in fixed column*/
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

/*Incorporating the effect if the class variable has numeric integers*/
data fixedeffect;
set fixedeffect;
%do i = 1 %to %sysfunc(countw(&classVariables. , " "));
	%let dsid = %sysfunc(open(group.bygroupdata));
	%let varnum = %sysfunc(varnum(&dsid,%scan(&classVariables., &i.," ")));
	%let vartyp = %sysfunc(vartype(&dsid,&varnum)); /* variable type */
	%let rc = %sysfunc(close(&dsid));
	%put &vartyp;

	%if &vartyp. = N %then %do;
		if %scan(&classVariables., &i.," ")="_" then %scan(&classVariables., &i.," ")="";
		%scan(&classVariables., &i.," ")_new = input(%scan(&classVariables., &i.," "),10.);
		drop %scan(&classVariables., &i.," ");
		rename %scan(&classVariables., &i.," ")_new = %scan(&classVariables., &i.," ");
	%end;
%end;
run;

/*Concatenating the level of class variable with the variable*/
%if "&classVariables." ^= "" %then %do;
	data _null_;
	call symput("classvar" , tranwrd("&classVariables." , " " , ','));
	run;
	%put &classvar.;
	data fixedeffect;
		set fixedeffect;
		classvar = compress(cat(&classvar.));
		classvar = translate(classvar,' ','.');
		classvar = compress(classvar);
		run;
	data class2;
		set fixedeffect;
		if classvar = "" then delete;
		run;
%end;

/*Getting the beta estimate values of intercept and other variables in different macro variables*/
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
			&model_date_var. = &model_date_var.;
		%end;
		run;

/*Merging with actual_pred to get these two columns*/
data contribution;
merge contribution actualvspredicted;
run;

/*Creating the antilog of dependent variable if dep var is logged*/
data contribution;
set contribution;
%if "&dependentTransformation."="log" %then %do;
	pred_antilog_var = exp(pred_dep) -1;
%end;
%else %do;
	pred_antilog_var = pred_dep;
%end;
run;

/*Merging the beta estimates of the class variables in contribution dataset */
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

/*Considering the random variables and their beta estimates*/
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

/*Creating the new names for class variables column and renaming the column*/
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

/*Manipulating the Baseline variables parameter if it has been logged while modeling*/
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

/*Sum of the class variables*/
%if "&classVariables."^="" %then %do;;
	data _null_;
	call symput("class_sum",tranwrd("&classVariables."," ","+"));
	run;
%end;

/*Sum of the baseline variables*/
%if "&baselineVariables."^="" %then %do;;
	data _null_;
	call symput("baseline_sum",tranwrd("&baselineVariables.","||","+"));
	run;
	%put &baseline_sum.;

/*Calculating the intercept which includes both intercept,baseline and class variables*/
	data contribution_final;
	set contribution_final;
	intercept_baseline = %if "&intercept_estimate."^="" %then %do;intercept + %end;&baseline_sum.%if "&classVariables."^= "" %then %do;+ &class_sum. %end;;
	run;
%end;
%else %do;
	%if "&intercept_estimate."^="" %then %do;
		data contribution_final;
		set contribution_final;
		intercept_baseline = intercept %if "&classVariables."^= "" %then %do;+ &class_sum. %end;;
		run;
	%end;
%end;

%if "&classVariables."^="" %then %do;;
data _null_;
call symput("classVariables",tranwrd("&classVariables."," ","||"));
run;
%end;
%let allbaseline = &baselineVariables.||&classVariables.;

data contribution_final;
set contribution_final;
baseline = exp(intercept_baseline);
run; 

/*Manipulating the marketing variables parameter whether it has been logged or nor while modeling*/
%if "&marketingVariables."^="" %then %do;
	%let marketingVariable =;
	%do a=1 %to %sysfunc(countw(&marketingVariables.,"||"));
		%let marketing_var=%scan(&marketingVariables.,&a.,"||");
		%let marketing_trans=%scan(&marketingTransformation.,&a.,"||");
			%if "&marketing_trans."="none" %then %do;
		    %let marketingVariable = &marketingVariable. &marketing_var.;
			%end;
			%else %do;
	        %let marketingVariable = &marketingVariable. log_&marketing_var.;
			%end;
	%end;
	%put &marketingVariable.;
	%let marketingVariables = &marketingVariable.;
	%put &marketingVariables.;

	data _null_;
	call symput("marketingVariables",tranwrd("&marketingVariables."," ","||"));
	run;
%end;

/*calculation of intermediate lift in the variable*/
data contribution_intermediate_lift;
set contribution_final;
%do k = 1 %to %sysfunc(countw(&marketingVariables. , "||"));
	%if "&dependentTransformation." = "log" %then %do;
		%if "&intercept_estimate."="" and "&baselineVariables.."="" %then %do;
			%scan("&marketingVariables." , &k. , "||") = exp(%scan("&marketingVariables." , &k. , "||"));
		%end;
		%else %do;
			%scan("&marketingVariables." , &k. , "||") = exp(%scan("&marketingVariables." , &k. , "||") + intercept_baseline);
		%end;
	%end;
	%else %do;
		%scan("&marketingVariables." , &k. , "||") = %scan("&marketingVariables." , &k. , "||");
	%end;
%end;			
run;	

/*Sum of marketing variables*/
%if "&marketingVariables."^="" %then %do;;
data _null_;
call symput("marketing_sum",tranwrd("&marketingVariables.","||","+"));
run;
%end;
%put &marketing_sum.;

/*Calculation in the lift of the variable*/
data contribution_lift;
set contribution_intermediate_lift;
%do k = 1 %to %sysfunc(countw(&marketingVariables. , "||"));
	%if "&dependentTransformation." = "log" %then %do;
		%if "&intercept_estimate."="" and "&baselineVariables.."="" %then %do;
			%scan("&marketingVariables." , &k. , "||") = %scan("&marketingVariables." , &k. , "||");
		%end;
		%else %do;
			%scan("&marketingVariables." , &k. , "||") = (%scan("&marketingVariables." , &k. , "||") - baseline);
		%end;
	%end;
	%else %do;
		%scan("&marketingVariables." , &k. , "||") = %scan("&marketingVariables." , &k. , "||");
	%end;
%end;
baseline = baseline - 1;
overall_sum = (&marketing_sum. + baseline);
run;		

data contribution_lift_splitting;
set contribution_lift;
%if "&dependentTransformation." = "log" %then %do;
%do k = 1 %to %sysfunc(countw(&marketingVariables. , "||"));
	%scan("&marketingVariables." , &k. , "||") = (%scan("&marketingVariables." , &k. , "||")*pred_antilog_var)/overall_sum;
%end;
%end;
baseline = (baseline*pred_antilog_var)/overall_sum;
run;

/*Splitting of contributions among the baseline variables*/
data final_baseline_con;
set contribution_lift_splitting;
%if "&dependentTransformation." = "log" %then %do;
%do z = 1 %to %sysfunc(countw(&allbaseline.,"||"));
	%scan("&allbaseline.",&z.,"||") = exp(%scan("&allbaseline.",&z.,"||") + intercept) - exp(intercept);
%end;
intercept = exp(intercept) - 1;
%end;
run;

/*Sum of all the baseline variables*/
data _null_;
call symput("allbaseline_sum",tranwrd("&allbaseline.","||","+"));
run;

%put &allbaseline_sum.;

data final_con;
set final_baseline_con;
overall_bb = &allbaseline_sum. + intercept;
%if "&dependentTransformation." = "log" %then %do;
%do z = 1 %to %sysfunc(countw(&allbaseline.,"||"));
	%scan("&allbaseline.",&z.,"||") = ((%scan("&allbaseline.",&z.,"||"))*baseline)/overall_bb;
%end;
intercept = (intercept*baseline)/overall_bb;
%end;
run;


/*Splitting of the baseline contributions*/
/*data contribution_final;*/
/*	set contribution_final;*/
/*	%if "&intercept_estimate."^="" %then %do;*/
/*	intercept = intercept/intercept_baseline;*/
/*	%end;*/
/*	%do h= 1 %to %sysfunc(countw(&allbaseline. , "||"));*/
/*	%scan("&allbaseline." , &h. , "||") = %scan("&allbaseline." , &h. , "||")/intercept_baseline;*/
/*	%end;*/
/*	run;*/

/* calculation of absolute contribution values */
/*data contribution_final1;*/
/*	set contribution_final;*/
/*	%do k = 1 %to %sysfunc(countw(&marketingVariables. , "||"));*/
/*			%if "&dependentTransformation." = "log" %then %do;*/
/*				%if "&intercept_estimate."="" and "&baselineVariables.."="" %then %do;*/
/*				%scan("&marketingVariables." , &k. , "||") = (%scan("&marketingVariables." , &k. , "||")*(pred_antilog_var))/(pred_dep);*/
/*				%end;*/
/*				%else %do;*/
/*				%scan("&marketingVariables." , &k. , "||") = (%scan("&marketingVariables." , &k. , "||")*(pred_antilog_var-exp(intercept_baseline)))/(pred_dep-intercept_baseline);*/
/*				%end;*/
/*			%end;*/
/*			%else %do;*/
/*				%scan("&marketingVariables." , &k. , "||") = %scan("&marketingVariables." , &k. , "||");*/
/*			%end;*/
/*	%end;*/

/*Considering the random variables and their contributions*/
	%if "&name."^= "" %then %do;
	data _null_;
		call symput("namess" , tranwrd("&new_name." , " " , ','));
		run;
		%put &namess.;
	%end;
/*	%let pp=;*/
/*	%if %sysfunc(fileexist(&a.)) %then %do;*/
/*	%if "&subject." = "" %then %do;*/
/*			proc sql;*/
/*			select variable into: pp separated by ' ' from randomeffect;*/
/*			quit;*/
/*	%end;*/
/*	%end;*/
/*	*/
/*		data contribution_final1;*/
/*			set contribution_final1;*/
/*			%if "&dependentTransformation." = "log" %then %do;*/
/*			%if "&subject." ^= "" %then %do;*/
/*			%do c = 1 %to %sysfunc(countw(&distinct_variables.,"||"));*/
/*				%if "&intercept_estimate."^="" %then %do;*/
/*					%scan(&distinct_variables.,&c.,"||") = %scan(&distinct_variables.,&c.,"||")*(pred_antilog_var-exp(intercept))/(pred_dep-intercept);*/
/*				%end;*/
/*				%else %do;*/
/*					%scan(&distinct_variables.,&c.,"||") = %scan(&distinct_variables.,&c.,"||")*(pred_antilog_var)/(pred_dep);*/
/*				%end;	*/
/*			%end;*/
/*			%end;*/
/*			 */
/*			%do a=1 %to %sysfunc(countw(&pp.,' '));*/
/*				%if "&intercept_estimate."^="" %then %do;*/
/*				%scan(&pp.,&a.," ") = %scan(&pp.,&a.," ")*(pred_antilog_var-exp(intercept))/(pred_dep-intercept);*/
/*				%end;*/
/*				%else %do;*/
/*				%scan(&pp.,&a.," ") = %scan(&pp.,&a.," ")*(pred_antilog_var)/(pred_dep);*/
/*				%end;*/
/*			%end;*/
/*			intercept_baseline = exp(intercept_baseline);*/
/*			%end;*/
/*			run;*/
/**/
/*			data contribution_final1;*/
/*				set contribution_final1;*/
/*				%if "&intercept_estimate."^="" %then %do;*/
/*				intercept = intercept * intercept_baseline;*/
/*				%end;*/
/*				%do t= 1 %to %sysfunc(countw(&allbaseline. , "||"));*/
/*					%scan("&allbaseline." , &t. , "||") = %scan("&allbaseline." , &t. , "||")*intercept_baseline;*/
/*				%end;*/
/*				run;*/

	%if "&subject." ^="" %then %do;
	
	data _null_;
	call symput("distinct_variabless",tranwrd("&distinct_variables.","||",","));
			run;
	%end;
	/*Rearranging the columns*/
	proc sql;
    create table contribution_final2 as
    select panel_name,panel_level,&model_date_var.,%if "&intercept_estimate."^="" %then %do;intercept,%end;&vars.,pred_dep,actual_dep,%if "&subject" ^= "" %then %do;%if "&randomVariables." ^= "" %then %do;&distinct_variabless., %end;%end;pred_antilog_var
    from final_con;
    quit;

/*Merging the class variables in the final contribution table*/
%if "&classVariables."^= "" %then %do;
	data contribution_final3 (keep = &new_name.);
	set final_con;
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

/*Required for the rolling up on the unique date level*/
/*Subsetting on the basis of the panels seleceted across which the model needs to be published*/
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

/*Required for the remnaming of the column names of the contribution.csv*/
%macro rename;
/*Renaming the intercept column to unattributed*/
%if "&intercept_estimate."^="" %then %do;
	data contri_final (rename = intercept = unattributed);
	set contri_final;
	run;
%end;
%else %do;
	data contri_final;
	set contri_final;
	unattributed = 0;
	run;
%end;
/*Manipulating the independent variable parameter*/
%let independentVariable=;
%do a=1 %to %sysfunc(countw(&independentVariables.,"||"));
	%let independent_var=%scan(&independentVariables.,&a.,"||");
	%let independent_trans=%scan(&independentTransformation.,&a.,"||");
		%if "&independent_trans."="none" %then %do;
	    %let independentVariable = &independentVariable. &independent_var.;
		%end;
		%else %do;
        %let independentVariable = &independentVariable. log_&independent_var.;
		%end;
%end;
%put &independentVariable.;
%let independentVariables = &independentVariable.;
%put &independentVariables.;
data _null_;
call symput("independentVariables",tranwrd("&independentVariables."," ",","));
run;
%put &independentVariables.;

	/*Rearranging the columns*/
	proc sql;
    create table contri_final2 as
    select panel_name,panel_level,&model_date_var.,%if "&intercept_estimate."^="" %then %do;unattributed,%end;&independentVariables.,pred_dep,actual_dep,pred_antilog_var
    from contri_final;
    quit;
data _null_;
call symput("independentVariables",tranwrd("&independentVariables.",","," "));
run;
%put &independentVariables.;
	
	/*Renaming the columns*/
	%do i=1 %to %sysfunc(countw(&independentVariables.," "));
	data contri_final2 (rename=  %scan(&independentVariables.,&i.," ")=%scan(&fixedContribVariables.,&i.,"||"));
	set contri_final2;
	run;
	%end;
	data out.contribution;
		set contri_final2;
		run;

/*Exporting the contribution csv*/
	proc export data = contri_final2
			outfile = "&output_path/contribution.csv"
			dbms = CSV replace;
			run;
%mend rename;
%rename;
/*---------------------------------------------------------------------------------------------------------------------*/

/*1) It gives the model equation for optimization i.e. splitting is done on the basis of class variables*/
/*2) It gives the model equation for response curve (no splitting is done)*/
/*3) It gives the parameter.csv for optimization which consists of the variables and their beta values*/
/*4) It gives the no_of_records for optimization which consists of the no of rows corresponding to the distinct class levels*/
/*5) It gives the distinct_classvar.txt having distinct levels on which splitting needs to be done*/


%macro equation;
/*-----For generating Distinct_classvar.txt having distinct levels---------------------------------------------------*/

/*Replacing || by , in classVariables parameter*/
%if "&classVariables."^="" %then %do;
data _null_;
call symput("classVariables",tranwrd("&classVariables.","||",","));
run;

data abcd;
set group.bygroupdata;
aaa = cat(&classVariables.);
bbb = catx("||",&classVariables.);
run;

proc sql;
select distinct(bbb) into: distinct_classses separated by '#' from abcd;
quit;
%put &distinct_classses.;

proc sql;
select distinct(aaa) into: distinct_classs separated by '||' from abcd;
quit;
%put &distinct_classs.;

/*Removing the special characters from the levels of the class variables*/
data _null_;
call symput("distinct_class",compress("&distinct_classs.","!@#$%^&()*/\_ "));
run;
%put &distinct_class.;
data _NULL_;
		v1= "&distinct_class.";
		file "&output_path./DISTINCT_CLASSVAR.txt";
		PUT v1;
	run;
/*-----------------------------------------------------------------------------------------------------------*/
/*Part-2: Creating the model equation for optimization (splitting done on the basis of the class variable)*/

data class_combination;
  %do tempz = 1 %to %sysfunc(countw(&distinct_classses.,"#"));
   cvarr="%scan(&distinct_classses.,&tempz.,"#")";
   output;
  %end;
   run;
  
data _null_;
call symput("classVariables",tranwrd("&classVariables.",",","||"));
run;

data equation_class;
set class_combination;
%do i=1 %to %sysfunc(countw(&classVariables.,'||'));
%scan(&classVariables.,&i.,'||') = scan(cvarr,&i.,'||');
%end;
run;

data equation_class;
set equation_class;
%do i = 1 %to %sysfunc(countw(&classVariables. , "||"));
	%let dsid = %sysfunc(open(group.bygroupdata));
			%let varnum = %sysfunc(varnum(&dsid,%scan(&classVariables., &i.,"||")));
			%let vartyp = %sysfunc(vartype(&dsid,&varnum)); /* variable type */
			%let rc = %sysfunc(close(&dsid));
		%put &vartyp;

%if &vartyp. = N %then %do;

%scan(&classVariables., &i.,"||")_new = input(%scan(&classVariables., &i.,"||"),10.);
drop %scan(&classVariables., &i.,"||");
rename %scan(&classVariables., &i.,"||")_new = %scan(&classVariables., &i.,"||");
%end;
%end;
run;

%do i=1 %to %sysfunc(countw(&classVariables.,'||'));
	proc sort data=equation_class;
	by %scan(&classVariables.,&i.,'||');
	quit;

	proc sort data=class2_&i.;
	by %scan(&classVariables.,&i.,'||');
	quit;

	data equation_class;
	merge equation_class class2_&i.;
	by %scan(&classVariables.,&i.,'||');
	run;
%end;
 
%do i=1 %to %sysfunc(countw(&classVariables.,'||'));
data equation_class;
length %scan(&classVariables,&i.,'||')_new $100.;
set equation_class;
%scan(&classVariables,&i.,'||')_new = cats("%scan(&classVariables.,&i.,'||')","_",%scan(&classVariables,&i.,'||'),"_","&aliasmodelname.");
drop %scan(&classVariables,&i.,'||');
rename %scan(&classVariables,&i.,'||')_new = %scan(&classVariables,&i.,'||');
run;
%end;

data _null_;
call symput("classVariabless",tranwrd("&classVariables.","||"," "));
run;
data _null_;
call symput("fixedEquationVariabless",tranwrd("&fixedEquationVariables.","||"," "));
run;
%do j = 1 %to %sysfunc(countw(&classVariabless.," "));
  %let searchwhat = %scan(&classVariabless.,&j.," ");
  %let fixedEquationVariabless =%sysfunc(tranwrd(&fixedEquationVariabless.,&searchwhat.,));
%end; 
data _null_;
call symput("fixedEquationVariabless" , %sysfunc(compbl("&fixedEquationVariabless.")));
run;
%put &equationVariabless.;
data _null_;
call symput("fixedEquationVariabless",tranwrd("&fixedEquationVariabless."," ","||"));
run;
%put &fixedEquationVariabless.;
%end;
%else %do;
%let fixedEquationVariabless = &fixedEquationVariables.;
%end;
 data fixedeffect_int;
 length variable $100.;
 format variable $100.;
 set fixedeffect1;
 if _n_ = 1 then output;
 run;
 data fixedeffect_withoutint;
 length variable $100.;
 format variable $100.;
 set fixedeffect1;
 if _n_ =1 then delete;
 run;

 data formulas;
 length formula $100.;
  %do f = 1 %to %sysfunc(countw(&fixedEquationVariabless.,'||'));
 formula = "%scan(&fixedEquationVariabless.,&f.,'||')";
 output;
 %end;
 run; 
 data fixedeffect_withoutint;
 merge fixedeffect_withoutint formulas;
 run;
data fixedeffect_withoutint(drop=variable rename=formula = Variable);
set fixedeffect_withoutint;
run;
proc append base=fixedeffect_int data=fixedeffect_withoutint FORCE;
quit;

data fixedeffect_int (rename= (Variable = variable estimate = Estimate));
format variable $50.;
length variable $50.;
informat variable $50.;
set fixedeffect_int;
%if "&classVariables." ^= "" %then %do;
%do f = 1 %to %sysfunc(countw(&distinct_class.,'||'));
/*if substr(Variable,1,4) = "log(" then variable = tranwrd(Variable,")","");*/
variable&f. = cats(variable,'_',"%scan(&distinct_class.,&f.,'||')");
if substr(Variable&f.,1,4) = "log_" then variable&f. = tranwrd(Variable&f.,"log_","log(");
/*if substr(Variable&f.,1,4) = "log(" then variable&f. = cats(Variable&f.,"_","&aliasmodelname.");*/
variable&f. = cats(variable&f.,"_&aliasmodelname.");
/*%let count = %sysfunc(countc(variable&f.,"("));*/
/*%put &count.;*/
brackets = repeat(")",countc(variable&f.,"(")-1);
if index(variable&f.,")") ^=0 then variable&f. = tranwrd(variable&f.,")","");
variable&f. = compress(variable&f.);
if index(variable&f.,"(") ^=0 then variable&f. = cats(variable&f.,brackets);
if Estimate>=0 then 
paramestimat&f. = cats(Estimate,"*",variable&f.);
else paramestimat&f. = cats("(",Estimate,")","*",Variable&f.);
if Estimate>=0 then 
paramestimat = cats(Estimate,"*",variable);
else paramestimat = cats("(",Estimate,")","*",Variable);
%end;
%end;
%else %do;
if substr(Variable,1,4) = "log_" then variable = tranwrd(Variable,"log_","log(");
/*if substr(Variable,1,4) = "log(" then variable = cats(Variable,"_&aliasmodelname.",")");*/
variable = cats(variable,"_&aliasmodelname.");
brackets = repeat(")",countc(variable,"(")-1);
if index(variable,")") ^=0 then variable = tranwrd(variable,")","");
variable = compress(variable);
if index(variable,"(") ^=0 then variable = cats(variable,brackets);
if Estimate>=0 then 
paramestimat = cats(Estimate,"*",variable);
else paramestimat = cats("(",Estimate,")","*",Variable);
%end;
run;

%if "&intercept_estimate."^="" %then %do;
%if "&classVariables." ^= "" %then %do;
proc sql;
	select paramestimat into:rhs_int separated by ' + ' from fixedeffect_int where Variable = "Intercept";
	quit;
	%put &rhs_int.;
	%let rhs_intercept = %sysfunc(tranwrd(&rhs_int.,*Intercept,));
%end;
%else %do;
proc sql;
	select paramestimat into:rhs_int separated by ' + ' from fixedeffect_int where Variable = "Intercept_&aliasmodelname.";
	quit;
	%put &rhs_int.;
	%let rhs_intercept = %sysfunc(tranwrd(&rhs_int.,*Intercept_&aliasmodelname.,));
%end;

%end;

	%if "&classVariables." ^= "" %then %do;
	%do b = 1 %to %sysfunc(countw(&distinct_class.,'||'));	
		proc sql;
		select paramestimat&b. into:rhs&b. separated by ' + ' from fixedeffect_int where Variable^= "Intercept";
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
	data eqn_cls;
	%do m = 1 %to %sysfunc(countw(&distinct_class.,'||'));
	column = "&&final&m..";
	output;
	%end;
	run; 
	%end;
	%else %do;
		proc sql;
		select paramestimat into:rhs separated by ' + ' from fixedeffect_int where Variable^= "Intercept_&aliasmodelname.";
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
%if "&classVariables." ^= "" %then %do;
data equation_class;
	merge equation_class eqn_cls;
	run;
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
		data equation_class;
		set equation_class;
		%do i=1 %to %sysfunc(countw(&classVariables.,'||')); 
		if Estimate_&i.>=0 then 
		paramestimat&i. = cats(Estimate_&i.,"*",%scan(&classVariables.,&i.,'||'));
		else paramestimat&i. = cats("(",Estimate_&i.,")","*",%scan(&classVariables.,&i.,'||'));
		paramestimat&i. = compress(paramestimat&i.,"!@#/\ ");
		%end;
		run;

		data _null_;
		call symput("classVariables",tranwrd("&classVariables.","||"," "));
		run;
		
		proc sort data=equation_class;
		key &classVariables.;
		quit;
		
		proc sql;
		select column into:basiceqn separated by ' + ' from equation_class;
		quit;
		%let eqn_final=;
		%let dep = &dependentVariable.;
			
		data final_eqn;
		set equation_class;
		drop &classVariables.;
		%do i=1 %to %sysfunc(countw(&classVariables.,' '));
		rename paramestimat&i. = %scan(&classVariables.,&i.,' ');
		%end;
		run;
		data _null_;
		call symput("classVariables",tranwrd("&classVariables."," ",","));
		run;
		data final_eqn;
		length column_final $500.;
		set final_eqn;
		column_final = catx(" + ",column,&classVariables.);
		run;
		proc sql;
		select column_final into:finall separated by '||' from final_eqn;
		quit;
		%put &finall.;
			%do q = 1 %to %sysfunc(countw(&finall.,'||'));
				%if "&dependentTransformation." = "log" %then %do;
				%let eqn&q.= {(exp(%scan(&finall.,&q.,'||') ))};
				%end;
				%else %do; 
				%let eqn&q.= {(%scan(&finall.,&q.,'||') )};
				%end;
				%put &&eqn&q.;
				
			
				%let eqn_final = &eqn_final. + &&eqn&q.;
			%end;
			%let eqn=&dep. = &eqn_final;
			%put &eqn;
	%end;
	%else %do;
		%let dep = &depEquationVariables.;
			%if "&dependentTransformation." = "log" %then %do;
			%let eqn=&dep. = {exp(&final.)};
			%end;
			%else %do; 
			%let eqn=&dep. = {&final.};
			%end;
			%put &eqn.;
	%end;

%let eqnn = %sysfunc(tranwrd(&eqn.,maof_,));
%put &eqnn.;
%let eqnnn = %sysfunc(tranwrd(&eqnn.,leadof_,));
%let eqnnnn = %sysfunc(tranwrd(&eqnnn.,lagof_,));
%let eqnnnnn = %sysfunc(tranwrd(&eqnnnn.,adsof_,));
%let eqnnnnnn = %sysfunc(tranwrd(&eqnnnnn.,normalizeof_,));
%put &eqnnnnnn.;
	
	data _NULL_;
		v1= "&eqnnnnnn.";
		file "&output_path./MODEL_EQUATION.txt";
		PUT v1;
	run;
/*-----------------------------------------------------------------------------------------------------------------*/
/*Part-3: Creating Model equation for response curve*/

/*crating a dataset without intercept to merge the equation formulas*/
data rs_noint;
set fixedeffect;
if variable = "Intercept" then delete;
run;
/*Keeping the intercept row to append later*/
data rs_int;
length variable $200.;
set fixedeffect;
if variable = "Intercept" then output;
run;
/*If more than 1 class variable, then need to change the fixed equation variable parameter to merge the formulas*/
%if "&classVariables." ^= "" %then %do; 
	/*replacing the class variable in the parameter to the number of levels of that class variable*/
	data _null_;
	call symput("fixedEquationVariablesss",tranwrd("&fixedEquationVariables.","||"," "));
	run;
		%do j = 1 %to %sysfunc(countw(&classVariabless.," "));
		%let searchwhat = %scan(&classVariabless.,&j.," ");
		proc sql;
		select count(distinct(&searchwhat.)) into: no_of_level from group.bygroupdata;
		quit;
		%put &no_of_level.;
			  %if %sysfunc(index(&fixedEquationVariablesss.,&searchwhat.)) ^=0 %then %do;
					%let fixedEquationVariablesss =%sysfunc(tranwrd(&fixedEquationVariablesss.,&searchwhat.,%sysfunc(repeat(&searchwhat.#,&no_of_level.-1))));
					data _null_;
					call symput("fixedEquationVariablesss",tranwrd("&fixedEquationVariablesss.","#"," "));
					run;
					data _null_;
					call symput("fixedEquationVariablesss",compbl("&fixedEquationVariablesss."));
					run;
					%put &fixedEquationVariablesss.;
			  %end;
		%end;

data _null_;
call symput("fixedEquationVariablesss" , tranwrd("&fixedEquationVariablesss."," ","||"));
run;
%end;
%else %do;
	%let fixedEquationVariablesss = &fixedEquationVariabless.;
%end;

/*Creating a dataset of the changed parameter*/
data formulas_response;
length formula_res $100.;
%do f = 1 %to %sysfunc(countw(&fixedEquationVariablesss.,'||'));
	 formula_res = "%scan(&fixedEquationVariablesss.,&f.,'||')";
	 output;
%end;
run; 

/*Merging the datasets to get the formulas corresponding to the variables*/
data rs_noint;
merge formulas_response rs_noint;
run;
data rs_noint (drop=variable rename=formula_res=variable);
set rs_noint;
run;
/*Appending the intercept row*/
proc append base=rs_int data=rs_noint;
quit;

/*Creating the dataset for the response curve equation*/
data response_curve;
set rs_int;
if substr(Variable,1,4) = "log_" then variable = tranwrd(Variable&f.,"log_","log(");
brackets = repeat(")",countc(variable,"(")-1);
if index(variable,")") ^=0 then variable = tranwrd(variable,")","");
variable = compress(variable);
%if "&classVariables." ^= "" %then %do;
	if classvar ^= "" then variable = cats(variable,"_",classvar);
%end;
/*variable = cats(variable,"_","&aliasmodelname.");*/
if index(variable,"(") ^=0 then variable = cats(variable,brackets);
if Estimate>=0 then 
paramestimat = cats(Estimate,"*",variable);
else paramestimat = cats("(",Estimate,")","*",Variable);
run;

/*Getting the intercept into a macro variable*/
%if "&intercept_estimate."^="" %then %do;
proc sql;
	select paramestimat into:rhs_int_response separated by ' + ' from response_curve where Variable = "Intercept";
	quit;
	%put &rhs_int_response.;
	%let rhs_intercept_response = %sysfunc(tranwrd(&rhs_int_response.,*Intercept,));
%end;
/*Getting rest of the variables along with beta values in a macro variable*/
proc sql;
		select paramestimat into:rhs_response separated by ' + ' from response_curve where Variable^= "Intercept";
		quit;
		%put &rhs_response.;
			%if "&intercept_estimate."^="" %then %do;
				%let final_response=&rhs_intercept_response. + &rhs_response.;
				%put &final_response.;
			%end;
			%else %do;
				%let final_response=&rhs_response.;
				%put &final_response.;
			%end;
%let dep = &depEquationVariables.;
			%if "&dependentTransformation." = "log" %then %do;
			%let eqn_response=&dep. = exp(&final_response.);
			%end;
			%else %do; 
			%let eqn_response=&dep. = &final_response.;
			%end;
			%put &eqn_response.;

/*Replacing ads,lag,lead,ma,normalize*/
%let eqnn_r = %sysfunc(tranwrd(&eqn_response.,maof_,));
%put &eqnn_r.;
%let eqnnn_r = %sysfunc(tranwrd(&eqnn_r.,leadof_,));
%let eqnnnn_r = %sysfunc(tranwrd(&eqnnn_r.,lagof_,));
%let eqnnnnn_r = %sysfunc(tranwrd(&eqnnnn_r.,adsof_,));
%let eqnnnnnn_r = %sysfunc(tranwrd(&eqnnnnn_r.,normalizeof_,));
%put &eqnnnnnn_r.;
	
	data _NULL_;
		v1= "&eqnnnnnn_r.";
		file "&output_path./RESPONSE_MODEL_EQUATION.txt";
		PUT v1;
	run;
/*-------------------------------------------------------------------------------------------------------------------*/
/*Part-4: Creating beta estimates csv to be given to optimization*/

%if "&classVariables." ^= "" %then %do; 
data fixedeffect_beta;
set fixedeffect_int;
if variable = "Intercept" then delete;
run;
data intercept_beta (keep= variable estimate);
length variable $200.;
set fixedeffect_int;
if variable = "Intercept" then output;
run;
/*%if "&classVariables." ^= "" %then %do;*/
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

data class2;
set class2;
variable = catx('_',variable,classvar,"&aliasmodelname.");
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
%end;
%else %do;
data intercept_beta (keep=variable estimate);
set fixedeffect_int;
run;
%end;
	/*Exporting the contribution csv*/
	proc export data = intercept_beta
			outfile = "&output_path./parameter.csv"
			dbms = CSV replace;
			run;
/*---------------------------------------------------------------------------------------------------------------*/
/*Part-5: creting the no_of_records.csv having the no of rows corresponding to the distinct levels*/

%if "&classVariables." ^= "" %then %do;
data group.bygroupdata;
set group.bygroupdata;
classvarr = cat(&classVariables.);
run;
proc freq data=group.bygroupdata;
tables classvarr/out =  a;
quit;
data a (drop=percent rename=(classvarr =  level count = nobs));
set a;
run;


/*proc sql;*/
/*select count(distinct cct_id) into: number from group.bygroupdata;*/
/*quit;*/
/*%put &number.;*/
/*data a;*/
/*nobs=&number.;*/
/*run;*/
proc export data =a
			outfile = "&output_path./no_of_records.csv"
			dbms = CSV replace;
			run;
%end;
%else %do;

%let dsid=%sysfunc(open(group.bygroupdata));
%let num=%sysfunc(attrn(&dsid,nlobs));
%let rc=%sysfunc(close(&dsid));

data a;
count = &num.;
level = "";
run;

proc export data =a
			outfile = "&output_path./no_of_records.csv"
			dbms = CSV replace;
			run;
%end;
%mend equation;
%equation;
/*-------------------------------------------------------------------------------------------------------------------*/

%mend mixed_contribution;
%mixed_contribution;

/*Completed txt generated*/
data _NULL_;
		v1= "MUMIX-CONTRIBUTION_COMPLETED";
		file "&output_path./CONTRIBUTION_COMPLETED.txt";
		PUT v1;
run;


