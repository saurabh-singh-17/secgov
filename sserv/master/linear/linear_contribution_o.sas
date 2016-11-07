*processbody;
/*author: Ankush Vishwanath and Geetika Gupta
date: 10th Feb, 2014*/

options mprint mlogic symbolgen mfile ;

libname in "&group_path.";
libname out "&output_path.";

%macro contribution;
proc printto log="&output_path./linear_contribution.log";
run;
quit;

/*proc printto;*/
/*run;*/

/*extract datasets bygroupdata,normal.csv or transformed.csv,estimates.csv*/
data bygroupdata;
set in.bygroupdata;
%do i=1 %to %sysfunc(countw(&independentVariables.,"||"));
	%if %scan(&independentVariables.,&i.," ") = . %then %do;
		%scan(&independentVariables.,&i.," ") = 0;
	%end;
%end;
run;

%if &dependentTransformation. = none %then %do;
	proc import datafile="&output_path./normal_chart.csv" dbms=csv out=actvspred replace;
	quit;
%end;

%if &dependentTransformation. = log %then %do;
	proc import datafile="&output_path./transformed_chart.csv" dbms=csv out=actvspred replace;
	quit;

%end;

proc import datafile="&output_path./estimates.csv" dbms=csv out=estimates replace;
quit;

/*remove intercept obs*/
data estimates_new;
set estimates (keep=dependent variable original_estimate original_variable);
if variable = "Intercept" then delete;
run;

/*change parameters*/

data _null_;
call symput("ind_var",tranwrd("&independentVariables.","||"," "));
run;

data _null_;
call symput("base_var",tranwrd("&baselineVariables.","||"," "));
run;

data _null_;
call symput("base_var_sum",tranwrd("&baselineVariables.","||","+"));
run;

data _null_;
call symput("mar_var",tranwrd("&marketingVariables.","||"," "));
run;

data _null_;
call symput("mar_var_sum",tranwrd("&marketingVariables.","||","+"));
run;

data _null_;
call symput("fixcon_var",tranwrd("&fixedContribVariables.","||"," "));
run;

data _null_;
call symput("convrate",tranwrd("&conversionrate.","||"," "));
run;

data _null_;
call symput("ind_trans",tranwrd("&independentTransformation.","||"," "));
run;

/* creating macro for fixedcontrib marketing variables*/
%let fixmar_var=;
%do i=1 %to %sysfunc(countw(&ind_var.));
	%if %index(&mar_var.,%scan(&ind_var.,&i.," ")) > 0 %then %do;
		%let first=%scan(&fixcon_var.,&i.," ");
		%let fixmar_var=&fixmar_var. &first.;
	%end;
%end;
%put &fixmar_var.;

/*creating macro for fixedcontrib baseline variables*/
%let fixbase_var=;
%do i=1 %to %sysfunc(countw(&ind_var.));
	%if %index(&base_var.,%scan(&ind_var.,&i.," ")) > 0 %then %do;
		%let second=%scan(&fixcon_var.,&i.," ");
		%let fixbase_var=&fixbase_var. &second.;
	%end;
%end;
%put &fixbase_var.;

/*creating a macro variable for synergy contribution calculaion*/
%let cont_synergy=unattributed;
%do i=1 %to %sysfunc(countw(&ind_var.));
	%let fifth=%scan(&ind_var.,&i.," ");
	%let cont_synergy=&cont_synergy.+&fifth.;
%end;

/*creating another macro variable for synergy contribution calculation to sum up all independent variables*/
%let cont_synergy1=%scan(&ind_var.,1," ");
%do i=2 %to %sysfunc(countw(&ind_var.));
	%let fifth=%scan(&ind_var.,&i.," ");
	%let cont_synergy1=&cont_synergy1.+&fifth.;
%end;

/*creating macro for using in select statement*/
%let cont_spends=;
%do i=1 %to %sysfunc(countw(&ind_var.));
	%let third=sum(%substr(%scan(&ind_var.,&i.," "),1,29)_c) as %substr(%scan(&ind_var.,&i.," "),1,29)_c;
	%let cont_spends=&cont_spends.,&third.;
%end;

%let cont_spends1=;
%do i=1 %to %sysfunc(countw(&mar_var.));
	%let fourth=sum(%substr(%scan(&mar_var.,&i.," "),1,29)_s) as %substr(%scan(&mar_var.,&i.," "),1,29)_s;
	%let cont_spends1=&cont_spends1.,&fourth.;
%end;
%put &cont_spends1.;

data _null_;
call symput("cont_spends2",cats("&cont_spends.","&cont_spends1."));
run;


/*creating macro for using in select statement for no date variable scenario*/
%let cont_spends3=;
%do i=1 %to %sysfunc(countw(&ind_var.));
	%let third=%substr(%scan(&ind_var.,&i.," "),1,29)_c;
	%let cont_spends3=&cont_spends3. &third.;
%end;

%let cont_spends4=;
%do i=1 %to %sysfunc(countw(&mar_var.));
	%let fourth=%substr(%scan(&mar_var.,&i.," "),1,29)_s;
	%let cont_spends4=&cont_spends4. &fourth.;
%end;

data _null_;
call symput("cont_spends5","&cont_spends3. &cont_spends4.");
run;


/*merging bygroup and actvspred*/
proc sort data = bygroupdata;
by primary_key_1644;
run;

proc sort data = actvspred;
by primary_key_1644;
run;
 
data bygroupdata_new(keep=&ind_var. primary_key_1644 &dependentVariable. &model_date_var. pred actual &fixcon_var.);
merge bygroupdata(in=a) actvspred(in=b) ;
by primary_key_1644;
if a or b;
run;

data bygroupdata_new1;
set bygroupdata_new;
%do i=1 %to %sysfunc(countw(&independentVariables.,"||"));
	%if %scan(&independentVariables.,&i.," ") = . %then %do;
		%scan(&independentVariables.,&i.," ") = 0;
	%end;
%end;
run;

/*calculate antilog pred when dependent transformation is log*/
%if &dependentTransformation. = log %then %do;
	data bygroupdata_new;
	set bygroupdata_new;
	antilog_pred = exp(pred)*&responsevalue.;
	antilog_actual=exp(actual);
	run;


/*sum up the exp_actual and store it in a macro*/
proc sql;
select sum(antilog_actual) into:actual_sum separated by " " from
bygroupdata_new
;
quit;
%end; 
/*get the estimates for independent variables and put it into a macro variable*/
proc sql;
select Original_Estimate into:beta_est separated by " " from
estimates_new
;
quit;

/*get the estimate for intercept and put it into a macro variable*/
proc sql outobs=1;
select Original_Estimate into:beta_est_int separated by " " from
estimates
;
quit;

/*contribution Calculations*/
data bygroupdata_new1(drop=intercept base overall_sum overall_baseline baseline);
set bygroupdata_new1;

/*if variable is transformed take log*/
%do i=1 %to %sysfunc(countw(&ind_trans.));
	%if %scan(&ind_trans.,&i.," ") = log %then %do;
		%scan(&ind_var.,&i.," ")=log((%scan(&ind_var.,&i.," "))+1);
	%end;
%end;

/*contribution calculatio for log-log model*/
%if &dependentTransformation. = log %then %do;

/*code for baseline methodology*/
	%if &contribution_methodology. = Baseline %then %do;

	/*marketing variable contribution*/
		%do i=1 %to %sysfunc(countw(&ind_var.));
			%scan(&ind_var.,&i.," ") =%scan(&ind_var.,&i.," ")*%scan(&beta_est.,&i.," ");
		%end;
		intercept = &beta_est_int.;
			%if "&base_var." ^= " " %then %do;
			base = exp(intercept + &base_var_sum.);
			%end;
			%if "&base_var." = " " %then %do;
			base = exp(intercept); 
			%end;
		
		%do i=1 %to %sysfunc(countw(&mar_var.));
			%if "&base_var." ^= " " %then %do;
			%scan(&mar_var.,&i.," ")=(exp(intercept+&base_var_sum.+%scan(&mar_var.,&i.," ")))-base;
			%end;
			%if "&base_var." = " " %then %do;
			%scan(&mar_var.,&i.," ")=(exp(intercept+%scan(&mar_var.,&i.," ")))-base;
			%end;
		%end;
		overall_sum = &mar_var_sum.+base;
		%do i=1 %to %sysfunc(countw(&mar_var.));
			%substr(%scan(&mar_var.,&i.," "),1,29)_c = (exp(pred)*&responsevalue.*%scan(&mar_var.,&i.," "))/overall_sum;
		%end;

		/*baseline variable contribution*/
		%if "&base_var." ^= " " %then %do;
			%do i=1 %to %sysfunc(countw(&base_var.));
				%scan(&base_var.,&i.," ")=(exp(intercept+%scan(&base_var.,&i.," ")))-(exp(intercept));
			%end;
			overall_baseline = &base_var_sum.+exp(intercept);
			baseline=(base*exp(pred)*&responsevalue.)/overall_sum;

			%do i=1 %to %sysfunc(countw(&base_var.));
				%substr(%scan(&base_var.,&i.," "),1,29)_c = %scan(&base_var.,&i.," ")*baseline/overall_baseline;
			%end;
		%end;
		%if "&base_var." = " " %then %do;
		overall_baseline = exp(intercept);
		baseline=(base*exp(pred)*&responsevalue.)/overall_sum;
		%end;
		unattributed = exp(intercept)*baseline/overall_baseline;
	%end;

	/*code for synergy methodology continued below from ###*/
	%if &contribution_methodology. = Synergy %then %do;
		%do i=1 %to %sysfunc(countw(&ind_var.));
			%scan(&ind_var.,&i.," ") =(%scan(&ind_var.,&i.," ") * %scan(&beta_est.,&i.," "))/actual;
		%end;			
	%end;	
%end;

	/*contribution calculation for simple linear model which will be same for both methodologies*/
	%if &dependentTransformation. = none %then %do;
		%do i=1 %to %sysfunc(countw(&ind_var.));
			%substr(%scan(&ind_var.,&i.," "),1,29)_c =%scan(&ind_var.,&i.," ")*%scan(&beta_est.,&i.," ")*&responsevalue.;
		%end;
		unattributed = &beta_est_int.*&responsevalue.;
	%end;	
run;

data bygroupdata_new1;
set bygroupdata_new1;
%do i=1 %to %sysfunc(countw(&independentVariables.,"||"));
		%if %scan(&independentVariables.,&i.," ") = . %then %do;
			%scan(&independentVariables.,&i.," ") = 0;
		%end;
	%end;
run;

/*getting the number of observation in dataset*/
%let dsid=%sysfunc(open(bygroupdata_new1));
%let num=%sysfunc(attrn(&dsid,nlobs));
%let rc=%sysfunc(close(&dsid));
%put &num.;

/*### Calculation of contribution synergy method*/
%if &contribution_methodology. = Synergy and &dependentTransformation. = log %then %do;
	%do i = 1 %to %sysfunc(countw(&ind_var.));
	proc sql;
	select sum(%scan(&ind_var.,&i.," ")) into:syn_sum&i. from bygroupdata_new1
	;
	quit;
	%end;

	%let sum_total=;
	%do f=1 %to %sysfunc(countw(&ind_var.," "));
		%let sum_total = &sum_total. &&syn_sum&f.;
	%end;
	%put &sum_total;

	data total;
	%do f = 1 %to %sysfunc(countw(&sum_total.,' '));
		variable_sum = %scan(&sum_total.,&f.,' ');
		output;
	%end;
	run; 

	proc sql;
	select sum(variable_sum) into:totall from total;
	quit;
	%put &totall.;

	data bygroupdata_new1;
	set bygroupdata_new1;
	unattributed = (&num.-(&totall.))/&num.;
	run;
	
	proc sql;
	select sum(unattributed) into:unatt_sum_syn from bygroupdata_new1
	;
	quit;

	%let sum_total1=&unatt_sum_syn.;
	%do f=1 %to %sysfunc(countw(&ind_var.," "));
		%let sum_total1 = &sum_total1. &&syn_sum&f.;
	%end;
	%put &sum_total1;

	data total1;
	%do i = 1 %to %sysfunc(countw(&sum_total1," "));
		variable_sum1 = %scan(&sum_total1,&i.," ");
		output;
	%end;
	run; 

	proc sql;
	select sum(variable_sum1) into:unatt_sum_syn_tot from total1
	;
	quit;

	data bygroupdata_new1;
	set bygroupdata_new1;
	%do i=1 %to %sysfunc(countw(&ind_var.));
		%substr(%scan(&ind_var.,&i.," "),1,29)_c =(%scan(&ind_var.,&i.," ")*&responsevalue.*&actual_sum.)/&unatt_sum_syn_tot.;
	%end;
	unattributed=(unattributed*&responsevalue.*&actual_sum.)/&unatt_sum_syn_tot.;
	run;
%end;

/*sum up the contributions for each independent variable and store it in a macro*/
%do i=1 %to %sysfunc(countw(&ind_var.));
	proc sql;
	select sum(%substr(%scan(&ind_var.,&i.," "),1,29)_c) into:varc&i. from
	bygroupdata_new1
	quit;
%end;

/*sum up the contributions for unattributed and store it in a macro*/
proc sql;
select sum(unattributed) into:unatt_sum from
bygroupdata_new1
quit;

/*spends calculation*/
data bygroupdata_new2;
set bygroupdata_new;
%do i=1 %to %sysfunc(countw(&mar_var.));
	%substr(%scan(&mar_var.,&i.," "),1,29)_s=%scan(&fixmar_var.,&i.," ")*%scan(&convrate.,&i.," ");
%end;	
run;

/*sum up the spends for each independent variable and store it in a macro*/
%do i=1 %to %sysfunc(countw(&mar_var.));
	proc sql;
	select sum(%substr(%scan(&mar_var.,&i.," "),1,29)_s) into:vars&i. from
	bygroupdata_new2
	quit;
%end;

/*creating the sas datasets in the required form*/
/*for each variable spends & contributions are calculated*/ 
data contvsspend(drop=Variable);
set estimates(keep=Variable);
length type $10.;
length Variables $100.;
	%do j=1 %to %sysfunc(countw(&ind_var.));
		%if %scan(&ind_trans.,&j.," ") = log %then %do;
		if Variable = "log_%scan(&ind_var.,&j.," ")" then do;
		Variables="%scan(&ind_var.,&j.," ")";
		contribution = &&varc&j.;
		end;
		%end;
		%else %do;
		if Variable = "%scan(&ind_var.,&j.," ")" then do;
		Variables="%scan(&ind_var.,&j.," ")";
		contribution = &&varc&j.;
		end;
		%end;
	%end;

	%do j=1 %to %sysfunc(countw(&mar_var.));
		if Variables="%scan(&mar_var.,&j.," ")" then do;
		type = "marketing";
		spends=&&vars&j.;
		end;
	%end;
	
	%if "&base_var." ^= " " %then %do;
	%do j=1 %to %sysfunc(countw(&base_var.));
		if Variables="%scan(&base_var.,&j.," ")" then do;
		type="baseline";
		end;
	%end;
	%end;
	if variable = "Intercept" then do;
	Variables="unattributed";
	type="baseline";
	contribution=&unatt_sum.;
	end;

ROI=contribution/spends;
business_scenario="&business_scenario.";
methodology="&contribution_methodology";
run;

/*sum up contributions for marketing variables and put it into a macro*/
proc sql;
select sum(contribution) into:totc from contvsspend
where type = "marketing";
quit;

/*sum up contributions for all variables and put it into a macro*/
proc sql;
select sum(contribution) into:tot from contvsspend;
quit;

/*sum up spends for all variables and put it into a macro*/
proc sql;
select sum(spends) into:tots from contvsspend
;
quit;

/*sum up ROI for all variables and put it into a macro*/
proc sql;
select sum(ROI) into:totr from contvsspend
;
quit;

/*calculating the percent contribution for each variable*/
data contvsspend_new;
set contvsspend;
percent_contribution = (contribution/&tot.)*100;
run;

/*creating the sas dataset having spends and contribution for each variable observation wise*/
data contvsspendtot(drop=&ind_var. actual pred primary_key_1644 cont_sum unattributed_syn);
merge bygroupdata_new1(in=a) bygroupdata_new2(in=b) ;
by primary_key_1644;
if a or b;
run;

%if "&model_date_var." ne  "" %then %do;
data contvsspendtot;
set contvsspendtot;
format &model_date_var. date9.;
run; 
%end;

%if &dependentTransformation. = log %then %do;
%if "&model_date_var." ne  "" %then %do;
/*rolling up the sas dataset on date variable*/
proc sql;
create table contvsspends1 as(
select &model_date_var.,sum(unattributed) as unattributed,
sum(&dependentVariable.) as &dependentVariable. ,
sum(antilog_pred) as antilog_pred &cont_spends2. from contvsspendtot
group by &model_date_var.)
;
quit;
%end;
%else %do;

data contvsspends1( keep=unattributed &dependentVariable. antilog_pred &cont_spends5.) ;
	set contvsspendtot;
	run;
%end;
data contvsspendtot_new;
set contvsspends1;
business_scenario="&business_scenario.";
methodology="&contribution_methodology";
primary_key= _n_;
run;
%end;

%if &dependentTransformation. = none %then %do;
%if "&model_date_var." ne  "" %then %do;
/*rolling up the sas dataset on date variable*/
proc sql;
create table contvsspends1 as(
select &model_date_var.,sum(unattributed) as unattributed,
sum(&dependentVariable.) as &dependentVariable. 
 &cont_spends2. from contvsspendtot
group by &model_date_var.)
;
quit;
%end;
%else %do;

data contvsspends1( keep=unattributed &dependentVariable. &cont_spends5.) ;
	set contvsspendtot;
	run;
%end;

data contvsspendtot_new;
set contvsspends1;
business_scenario="&business_scenario.";
methodology="&contribution_methodology";
primary_key= _n_;
run;
%end;



/*creating the sas dataset which has total spends and contribution*/
%let total_var = contribution spends ROI;

data overall;
length total $15.;
	%do i = 1 %to %sysfunc(countw(&total_var.));
		total="%scan(&total_var.,&i.," ")";
		output;
	%end;
run;

data overall_new;
set overall;
business_scenario="&business_scenario.";
methodology="&contribution_methodology";
if total = "contribution" then value = &tot.;
if total = "spends" then value = &tots.;
if total = "ROI" then value = &tot./&tots.;
run;

/*exporting the sas datasets*/
proc export data=overall_new outfile="&output_path/Overall_&business_scenario._&contribution_methodology..csv" dbms=csv replace;
quit;

proc export data=contvsspend_new outfile="&output_path/Business_Stats_&business_scenario._&contribution_methodology..csv" dbms=csv replace;
quit;

proc export data=contvsspendtot_new outfile="&output_path/Contribution_Vs_Spends_&business_scenario._&contribution_methodology..csv" dbms=csv replace;
quit;

/*proc datasets library=work kill;*/
/*run;*/
/*quit;*/

%mend contribution;

%contribution;
