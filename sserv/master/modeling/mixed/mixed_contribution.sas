/*Successfully converted to SAS Server Format*/
*processbody;

/*--------------------------------------------------------------------------------------------------------*/
/*--                                                                                                  	--*/   
/*-- Functionality Name :  mixed modeling contribution        	--*/
/*-- Description  		:  generates diferent csvs for spends, contribution and overall contributions
/*-- Return type  		:  Creates CSV's at a location according to given inputs                        --*/
/*-- Author       		:  Saurabh vikash singh                         --*/                 
/*--------------------------------------------------------------------------------------------------------*/

/*%let codePath=/data22/IDev/Mrx//SasCodes//S8.6.1.3;*/
/*%let model_csv_path=/data22/IDev/Mrx/projects/pg_chk-31-Dec-2013-15-43-02/1/1/1_1_1/MIXED/1/3;*/
/*%let output_path=/data22/IDev/Mrx/projects/pg_chk-31-Dec-2013-15-43-02/1/1/1_1_1/MIXED/1/3;*/
/*%let group_path=/data22/IDev/Mrx/projects/pg_chk-31-Dec-2013-15-43-02/1/1/1_1_1;*/
/*%let model_date_var=week_start_date;*/
/*%let dependentVariable=sales_per_store;*/
/*%let dependentTransformation=log;*/
/*%let independentVariables=market||Coupon_per_store||Direct_mail_per_store||gdp||*/
/*income||newspaper_ads_per_store||search_impressions_per_store||tv_trps_per_store */
/*||unemp_rate;*/
/*%let independentTransformation=none||log||log||none||none||log||log||log||log;;*/
/*%let fixedContribVariables=market||Coupon_per_store||Direct_mail_per_store||gdp||*/
/*income||newspaper_ads_per_store||search_impressions_per_store||tv_trps_per_store */
/*||unemp_rate;*/
/*%let randomVariables=;*/
/*%let randomTransformation=;*/
/*%let randomContribVariables=;*/
/*%let classVariables=market;*/
/*%let subject=;*/
/*%let marketingVariables=Coupon_per_store||Direct_mail_per_store||newspaper_ads_per_store||search_impressions_per_store||tv_trps_per_store;*/
/*%let marketingTransformation=log||log||log||log||log;*/
/*%let conversionrate=19||10||43||54||16;*/
/*%let baselineVariables=gdp||income||unemp_rate;*/
/*%let baselineTransformation=none||none||none;*/
/*%let contribution_methodology=Baseline;*/
/*%let business_scenario=muMix;*/
/*%let market_stats=contribution||roi;*/
/*%let responsevalue=321;*/


options mprint mlogic symbolgen mfile;

proc printto log="&output_path./mixed_model_contribution.log";
run;
quit;

%macro mixed_contrib;
/*defining the libraries*/

libname in "&group_path.";
libname est "&model_csv_path.";
libname out "&output_path.";

/*making of different paramters*/
data _null_;
	call symput("fixed_var",tranwrd("&independentVariables.","||"," "));
	run;

data _null_;
	call symput("original_fixed_var",tranwrd("&fixedContribVariables.","||"," "));
	run;

data _null_;
	call symput("random_var",tranwrd("&randomVariables.","||"," "));
	run;

data _null_;
	call symput("original_random_var",tranwrd("&randomContribVariables.","||"," "));
	run;

data _null_;
	call symput("class_var",tranwrd("&classVariables.","||"," "));
	run;


/*making of only fixed var*/
%let only_fixed=&fixed_var.;
%let original_only_fixed=&original_fixed_var.;
%do i=1 %to %sysfunc(countw("&random_var."," "));
%let temp=%scan(&random_var.,&i.," ");
%let temp1=%scan(&original_random_var.,&i.," ");
	data _null_;
	 	call symput("only_fixed",tranwrd("&only_fixed.","&temp.",""));
		run;
	data _null_;
	 	call symput("original_only_fixed",tranwrd("&original_only_fixed.","&temp.",""));
		run;
%end;
%do i=1 %to %sysfunc(countw("&class_var."," "));
%let temp=%scan(&class_var.,&i.," ");
	data _null_;
	 	call symput("only_fixed",tranwrd("&only_fixed.","&temp.",""));
		run;
	data _null_;
	 	call symput("original_only_fixed",tranwrd("&original_only_fixed.","&temp.",""));
		run;
%end;
data _null_;
	call symput("only_fixed",tranwrd("&only_fixed.","||",""));
	run;

data _null_;
	call symput("only_fixed",strip("&only_fixed."));
	run;

data _null_;
	call symput("original_only_fixed",strip("&original_only_fixed."));
	run;

/*making of only fixed variables completed*/

/*making of only fixed transformations */
%let only_fixed_trans=;
%do k=1 %to %sysfunc(countw("&only_fixed."," "));
	%let temp=%scan("&only_fixed.",&k.," ");
	%do l=1 %to %sysfunc(countw("&fixed_var."," "));
		%let temp2=%scan("&fixed_var.",&l.," ");
		%let temp_trans=%scan("&independentTransformation.",&l.,"||");
		%if "&temp." = "&temp2." %then %do;
			%let only_fixed_trans=&only_fixed_trans. &temp_trans.;
		%end;
	%end;
%end;

%let all_vars_non_dep=&only_fixed. &random_var. &class_var.;
%let all_vars=&dependentVariable &only_fixed. &random_var. &class_var.;



/*adding the predicted column to the bygroupdata and creating a data for the further operations */

proc import datafile="&model_csv_path./FixedEffect.csv" dbms=csv out=fixedeffect(drop=StandardError DF tValue PValue) replace;
run;
%if "&randomContribVariables."  ne  "" %then %do;
proc import datafile="&model_csv_path./RandomEffect.csv" dbms=csv out=randomeffect(drop=StdErrPred DF tValue PValue rename=(&subject=ran_&subject. Estimate=ran_Estimate)) replace;
run;

proc sort data=fixedeffect;
by variable;
run;

data final_estimates;
	merge fixedeffect randomeffect;
	by Variable;
	run;

data final_estimates; 
	set final_estimates;
	array nums _numeric_;
	do over nums;
 	if nums=. then nums=0;
 	end;
	final_estimate=estimate+ran_estimate;
	if substr(Variable,1,4) = "log_" then variable=substr(Variable,5);
	run;

%end;
%else %do;
data final_estimates;
	merge fixedeffect;
	run;

data final_estimates; 
	set final_estimates;
	array nums _numeric_;
	do over nums;
 	if nums=. then nums=0;
 	end;
	final_estimate=estimate;
	if substr(Variable,1,4) = "log_" then variable=substr(Variable,5);
	run;

%end;

data workdata;
	set in.bygroupdata;
	primary_key=primary_key_1644;
	run;

proc sort data=workdata;
by primary_key_1644;
run;

proc sort data=est.mixedoutput;
by primary_key_1644;
run;


data workdata;
	merge workdata est.mixedoutput(keep=actual pred primary_key_1644);
	by primary_key_1644;
	run;


/*starting with the calculation of the contribution and spends*/
/*spends calculation*/
data _null_;
	call symput("mkt_var",tranwrd("&marketingVariables.","||"," "));
	run;
data _null_;
	call symput("base_var",tranwrd("&baselineVariables.","||"," "));
	run;

%let original_mkt_var=;
%do i=1 %to %sysfunc(countw("&mkt_var."," "));
	%let cur_mkt_var=%scan("&mkt_var.",&i.," ");
	%let counter=0;
	%do j=1 %to %sysfunc(countw("&fixed_var."," "));
		%let cur_fixed_var=%scan("&fixed_var.",&j," ");
		%if "&cur_mkt_var." = "&cur_fixed_var." %then %do;
			%let original_mkt_var=&original_mkt_var. %scan("&fixedContribVariables.",&j.,"||"); 
			%let counter=1;
		%end;
	%end;
	%if &counter. = 0 %then %do;
	%do k=1 %to %sysfunc(countw("&random_var."," "));
		%let cur_random_var=%scan("&random_var.",&k," ");
		%if "&cur_mkt_var." = "&cur_random_var." %then %do;
			%let original_mkt_var=&original_mkt_var. %scan("&randomContribVariables.",&k.,"||"); 
		%end;
	%end;
	%end;
%end;


%let original_base_var=;
%do i=1 %to %sysfunc(countw("&base_var."," "));
	%let cur_base_var=%scan("&base_var.",&i.," ");
	%let counter=0;
	%do j=1 %to %sysfunc(countw("&fixed_var."," "));
		%let cur_fixed_var=%scan("&fixed_var.",&j," ");
		%if "&cur_base_var." = "&cur_fixed_var." %then %do;
			%let original_base_var=&original_base_var. %scan("&fixedContribVariables.",&j.,"||"); 
			%let counter=1;
		%end;
	%end;
	%if &counter. = 0 %then %do;
	%do k=1 %to %sysfunc(countw("&random_var."," "));
		%let cur_random_var=%scan("&random_var.",&k," ");
		%if "&cur_base_var." = "&cur_random_var." %then %do;
			%let original_base_var=&original_base_var. %scan("&randomContribVariables.",&k.,"||"); 
		%end;
	%end;
	%end;
%end;


data workdata;
	set workdata;
	%do i=1 %to %sysfunc(countw("&mkt_var."," "));
		%scan("&mkt_var.",&i.," ")_s=%scan("&original_mkt_var.",&i.," ")*%scan("&conversionrate.",&i.,"||");
	%end;
	run;	


/*replacing all the values in the workdata by the appropriate value as per fixed variables and random variable and the class variable*/

/*multiplying betas for fixed variables*/
%do i= 1 %to %sysfunc(countw("&only_fixed"," "));
	%let curr=%scan("&only_fixed.",&i.," ");
	%let curr_trans=%scan("&only_fixed_trans.",&i.," ");
	proc sql;
		select final_estimate into: curr_beta from final_estimates where Variable="&curr.";
		quit;
	data workdata;
		set workdata;
		%if "&curr_trans." ne "none" %then %do;
		&curr= &curr_beta.*(log1px(&curr.));
		%end;
		%else %do;
		&curr= &curr_beta.*&curr.;
		%end;
		run;
%end;

/*multiplying betas for random variables*/
%if "&randomVariables." ne "" %then %do;
%do i=1 %to %sysfunc(countw("&random_var."," "));
	%let curr=%scan("&random_var.",&i.," ");
	%let curr_trans=%scan("&randomTransformation.",&i.," ");
	proc sql;
		select final_estimate into: curr_beta separated by "," from final_estimates where Variable="&curr.";
		quit;
	proc sql;
		select ran_&subject. into: curr_subject separated by "||" from final_estimates where Variable="&curr.";
		quit;
	data workdata;
		set workdata;
		%do k=1 %to %sysfunc(countw("&curr_subject","||"));
			if &subject. = "%scan("&curr_subject.",&k.,"||")" then do;
				%if "&curr_trans." ne "none" %then %do;
					&curr= %scan("&curr_beta.",&k.,",")*(log1px(&curr.));
				%end;
				%else %do;
					&curr= %scan("&curr_beta.",&k.,",")*&curr.;
				%end;
			end;
		%end;
		run;
%end;
%end;

%if "&class_var." ne  "" %then %do;
/*multiplying betas for class variables*/
%do i=1 %to %sysfunc(countw("&class_var."," "));
	%let curr=%scan("&class_var.",&i.," ");
	proc sql;
		select final_estimate into: curr_beta separated by "," from final_estimates where &curr. is not null;
		quit;
	proc sql;
		select &curr. into: curr_levels separated by "||" from final_estimates where &curr. is not null;
		quit;
	data workdata;
		set workdata;
		%do k=1 %to %sysfunc(countw("&curr_levels","||"));
			if &curr. = "%scan("&curr_levels.",&k.,"||")" then do;
				&curr= %scan("&curr_beta.",&k.,",");
			end;
		%end;
		&curr._temp=&curr.*1;
		drop &curr.;
		rename &curr._temp=&curr.;
		run;
%end;
%end;
proc sql;
select sum(estimate) into:inter_value  from final_estimates where variable  = "Intercept";
quit;

data workdata;
	set workdata;
	unattributed=&inter_value.;
	run;


/*making of the dataset for the contribution is complete */

/*starting the contribution calculation*/
/*method	: baseline ans synergy*/
/*type	: simple	*/
%let mkt_base_unattri=&mkt_var. &base_var unattributed;

%if "&dependentTransformation." = "none" %then %do;
data workdata;
	set workdata;
	%do i=1 %to %sysfunc(countw("&mkt_base_unattri."," "));
	%scan("&mkt_base_unattri.",&i.," ")_c=%scan("&mkt_base_unattri.",&i.," ")*%sysevalf(&responsevalue.);
	%end;
	run;
%end;

/*method	: baseline*/
/*type	: log-linear model or log log model	*/

%if "&contribution_methodology." = "Baseline" and "&dependentTransformation." = "log" %then %do;
data _null_;
call symput("base_var_plus",tranwrd("&base_var."," ","+"));
run;
data workdata;
	set workdata;
	denominator_mkt=0;
	denominator_base=0;
	run;

/*marketing variable contribution*/
data workdata;
	set workdata;
	colbase=exp(unattributed + &base_var_plus.);
	%do i=1 %to %sysfunc(countw("&mkt_var."," "));
	%let cur_mkt_var=%scan("&mkt_var.",&i," ");
		&cur_mkt_var.=exp(&cur_mkt_var. + unattributed + &base_var_plus.);
		&cur_mkt_var.=&cur_mkt_var.-colbase;
		denominator_mkt=denominator_mkt+&cur_mkt_var.;
	%end;
	colbase= colbase-1;
	denominator_mkt=denominator_mkt+colbase;
	%do i=1 %to %sysfunc(countw("&mkt_var."," "));
	%let cur_mkt_var=%scan("&mkt_var.",&i," ");
	&cur_mkt_var.=(&cur_mkt_var.*(exp(pred)-1))/denominator_mkt;
	rename &cur_mkt_var.=&cur_mkt_var._c;
	%end;
	run;


/*baseline contribution calculation*/
data workdata;
	set workdata;
	%do i=1 %to %sysfunc(countw("&base_var."," "));
	%let cur_base_var=%scan("&base_var.",&i," ");
		&cur_base_var.=exp(&cur_base_var. + unattributed);
		&cur_base_var.=&cur_base_var.-exp(unattributed);
		denominator_base=denominator_base+&cur_base_var.;
	%end;
	denominator_base=denominator_base + (exp(unattributed)-1);
	numerator_inter=(colbase*(exp(pred)-1))/denominator_mkt;
	%do i=1 %to %sysfunc(countw("&base_var."," "));
	%let cur_base_var=%scan("&base_var.",&i," ");
	&cur_base_var.=(&cur_base_var.*numerator_inter)/denominator_base;
	rename &cur_base_var. = &cur_base_var._c;
	%end;
	run;	

data workdata;
	set workdata;
	unattributed=((exp(unattributed)-1)*numerator_inter)/denominator_base;
	run;

%end;

/*method	: baseline*/
/*type	: log-linear model or log log model	*/

%if "&contribution_methodology." = "synergy" and "&dependentTransformation." = "log" %then %do;
%let dsid=%sysfunc(open(workdata));
%let num=%sysfunc(attrn(&dsid,nobs));
%let rc=%sysfunc(close(&dsid));

%let mkt_base=&mkt_var. &base_var;
	data workdata;
		set workdata;
		total_sum=0;
		%do i=1 %to %sysfunc(countw("&mkt_base."," "));
			%let cur_mkt_base=%scan("&mkt_base.",&i.," ");
			&cur_mkt_base._ab=&cur_mkt_base./actual;
			total_sum=total_sum+&cur_mkt_base._ab;
		%end;
		run;
	 proc sql;
	 select sum(total_sum) into:total from workdata;
	 quit;
	data workdata;
		set workdata;
		unattributed=(%sysevalf(&num.)-%sysevalf(&total.))/%sysevalf(&num.);
		total_sum=total_sum+unattributed;
		exp_actual=exp(actual);
		run;
	proc sql;
		select sum(total_sum) into:total from workdata;
	 	quit;
	proc sql;
		select sum(exp_actual) into:total_act from workdata;
	 	quit;
	data workdata;
		set workdata;	
		%do i=1 %to %sysfunc(countw("&mkt_base."," "));
			%let cur_mkt_base=%scan("&mkt_base.",&i.," ");
			&cur_mkt_base._c;=&cur_mkt_base.*%sysevalf(&total_act.)/%sysevalf(&total.);
		%end;
		run;
	
%end;
/*final columns to be kept in the contribution data*/
%let keepvar=unattributed;
%do i=1 %to %sysfunc(countw("&mkt_var."," "));
	%let keepvar=&keepvar. %scan("&mkt_var.",&i.," ")_s %scan("&mkt_var.",&i.," ")_c;
%end;
%do i=1 %to %sysfunc(countw("&base_var."," "));
	%let keepvar=&keepvar. %scan("&base_var.",&i.," ")_c;
%end;
%if "&model_date_var." ne "" %then %do;
	%let keepvar=&keepvar. &model_date_var.;
%end;
%else %do;
	%let keepvar=&keepvar. primary_key;
%end;
%if "&model_date_var." ne  "" %then %do;
proc contents data=workdata out=cont;
run;

proc sql;
select name into:colnames separated by " " from cont where type = 1 and name <> "&model_date_var.";
quit;

proc sort data=workdata;
by &model_date_var.;
run;

proc means data=workdata;
by &model_date_var.;
var &colnames.;
output out=workdata;
run;

data workdata(drop=_TYPE_);
    set workdata;
    if _STAT_ = "MEAN";
    run;
data workdata;
    set workdata;
%do tem=1 %to %sysfunc(countw("&colnames."," "));
     %scan("&colnames.",&tem.," ")= _FREQ_ *%scan("&colnames.",&tem.," ");
%end;
run;
%end;

data workdata(keep=&keepvar.);
		set workdata;
		run;	
/*making of contribution table for all the possible scenarios completed*/
/*making of business stats starts here*/
data business_stats;
length Variables $100.;
length type $20;
	Variables="unattributed";	
	type="baseline";
	output;
	%do i=1 %to %sysfunc(countw("&mkt_var."," "));
		Variables="%scan("&mkt_var.",&i.," ")";
		type="marketing";
		output;
	%end;
	%do i=1 %to %sysfunc(countw("&base_var."," "));
		Variables="%scan("&base_var.",&i.," ")";
		type="baseline";
		output;
	%end;
	run;
%let mkt_base_unattri=unattributed &mkt_var. &base_var;
%put &mkt_base_unattri.;

/*adding the contribution column*/
%do i=1 %to %sysfunc(countw("&mkt_base_unattri."," "));
	%if %scan("&mkt_base_unattri.",&i.," ") = unattributed %then %do;
	proc sql;
		select sum(%scan("&mkt_base_unattri.",&i.," ")) format = best32. into:tempsum from workdata;
		quit;
	%end;
	%else %do;
	proc sql;
		select sum(%scan("&mkt_base_unattri.",&i.," ")_c) format = best32. into:tempsum from workdata;
		quit;
	%end;
	data business_stats;
		set business_stats;
		if Variables="%scan("&mkt_base_unattri.",&i.," ")" then contribution=%sysevalf(&tempsum.);
		run;
%end;
%do i=1 %to %sysfunc(countw("&mkt_var."," "));
	proc sql;
		select sum(%scan("&mkt_var.",&i.," ")_s) format = best32. into:tempsum from workdata;
		quit;
	data business_stats;
		set business_stats;
		if Variables="%scan("&mkt_var.",&i.," ")" then spends=%sysevalf(&tempsum.);
		run;
%end;
proc sql;
	select sum(contribution) format = best32. into:sumcol from business_stats;
	quit;
data business_stats;
		set business_stats;
		ROI=contribution/spends;
		business_scenario="&business_scenario.";
		methodology="&contribution_methodology.";
		percent_contribution=(contribution/%sysevalf(&sumcol.))*100;
		run;

/*making of business stats completed*/

/*making of overall stats started*/
proc sql;
	select sum(spends) format = best32. into:sum_spends from business_stats;
	quit;

data overall;
	total="contribution";
	value=%sysevalf(&sumcol.);
	output;
	total="spends";
	value=%sysevalf(&sum_spends.);
	output;
	total="ROI";
	value=%sysevalf(&sumcol.)/%sysevalf(&sum_spends.);
	output;
	run;
data overall;
	set overall;
	business_scenario="&business_scenario.";
	methodology="&contribution_methodology.";
	run;
/*making of overall stats completed*/

/*exporting the sas datasets*/
proc export data=overall outfile="&output_path/Overall_&business_scenario._&contribution_methodology..csv" dbms=csv replace;
quit;

proc export data=workdata outfile="&output_path/Contribution_Vs_Spends_&business_scenario._&contribution_methodology..csv" dbms=csv replace;
quit;

proc export data=business_stats outfile="&output_path/Business_Stats_&business_scenario._&contribution_methodology..csv" dbms=csv replace;
quit;

data _null_;
	v1= "mixed_model_contribution_completed";
	file "&output_path./mixed_model_contribution_completed.txt";
	put v1;
run;

%mend;
%mixed_contrib;

