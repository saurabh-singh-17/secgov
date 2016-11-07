*processbody;
/*Mumix Contribution code for GLM*/
/*Date: 08/06/2013*/
/*Author:Ankesh*/

/*parameters required:*/

/*%let model_csv_path=C:\Users\ankesh.aggrawal\MRx\sas\cluster_no-27-Jun-2013-11-16-10\1\0\1_1_1\GLM\1\1;*/
/*%let output_path=C:\Users\ankesh.aggrawal\MRx\sas\cluster_no-27-Jun-2013-11-16-10\1\0\1_1_1\GLM\1\1\contribution;*/
/*%let group_path=C:\Users\ankesh.aggrawal\MRx\sas\cluster_no-27-Jun-2013-11-16-10\1\0\1_1_1;*/
/*%let panel_name= geography#store_format#channel_2||geography#store_format#channel_2;*/
/*%let panel_level_name = north#Supercenter#0||north#Supercenter#1;*/
/*%let classVariables =geography||Store_Format ;*/
/*%let dependentVariable=sales;*/
/*%let independentVariables=ACV||Chiller_flag||Date||HHs_55_64||*/
/*Hispanic_HHs_Index||P164_Demand_Index||P26_Demand_Index||Total_Selling_Area||*/
/*black_hispanic||channel_1||channel_2||channel_3||*/
/*channel_4||channel_5||cluster_flag||format||*/
/*sf1||sf2||sf3;*/
/*%let dependentTransformation=log;*/
/*%let independentTransformation=none||none||none||log||*/
/*log||log||log||log||*/
/*none||none||none||none||*/
/*none||none||none||none||*/
/*none||none||none;*/
/**/
/*%let model_date_var=date; */

options mprint mlogic symbolgen mfile;

proc printto log="&output_path./contribution_Log.log";
	run;
	quit;
/*proc printto print="&output_path.\contribution_Output.out";*/
/*	run;*/
/*	quit;*/

/*Assigning libnames*/
libname group "&group_path.";
libname out "&output_path.";

%macro GLM_contribution;
/*Importing the estimates csv*/
proc import datafile="&model_csv_path./ParameterEstimates.csv"
	out = estimate
	dbms = csv
	replace;
	getnames=yes;
	guessingrows=50;
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
	guessingrows=50;
run;
 %let ko =&classVariables.;
data _null_;
	call symput("independentVariables" , tranwrd("&independentVariables.","|| ","||"));
	run;
%put &independentVariables.;
data _null_;
	call symput("classVariables" , tranwrd("&classVariables.","|| ","||"));
	run;

%put &classVariables.;

data _null_;
	call symput("independentTransformation" , tranwrd("&independentTransformation.","|| ","||"));
	run;
%put &independentTransformation.;

/*Subsetting the dataset and renaming the columns*/
data actual_pred(keep= pred actual rename=pred=pred_dep rename=actual=actual_dep);
set predicted;
run;

%if "&ko."^= "" %then %do;

data estimate;
set estimate;
if countw(Variable) >1 then Class_Var_level=strip(Variable);
%do i=1 %to %sysfunc(countw(&classVariables.,"||"));
x&i.= index(Class_Var_level,"%scan(&classVariables.,&i.)");
%scan(&classVariables.,&i.)=strip(tranwrd(Class_Var_level,"%scan(&classVariables.,&i.)",""));
if x&i.=0 then %scan(&classVariables.,&i.)="" ;
%end;
run;
%end;

/*Subsetting the dataset and deleting the row corresponding to the intercept*/
data estimate_no_intercept;
set estimate (keep= Variable Estimate);
Estimate = round(Estimate , .000000000000001);
if Variable='Intercept' then delete;
if countw(Variable) >1 then delete;
run;

/*Creating macro variables*/
%let intercept_estimate=;
proc sql;
select Estimate into: intercept_estimate from estimate where (Variable = "Intercept");
quit;
proc sql;
select Estimate into: var_estimates separated by " " from estimate_no_intercept;
quit;
proc sql;
select Variable into: var separated by " " from estimate_no_intercept;
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
	set group.bygroupdata (keep= &var. %if (%index(&panel_name. , #)) > 0 %then %do; union %end; &panel. &model_date_var. &classVariables.);
		%do i=1 %to %sysfunc(countw(&var_estimates.," "));
		%let t = %scan(&var_estimates.,&i.," ");
		%scan(&var.,&i.) = %scan(&var.,&i.)*%sysevalf(&t.);
		%end;
	%if "&intercept_estimate."^="" %then %do;
	intercept = &intercept_estimate.;
	%end;
	&model_date_var.=&model_date_var.;
	run;
	
	/*Merging with actual_pred to get these two columns*/
	data contribution;
	merge contribution actual_pred;
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


/*	merging with the class variables*/

%if "&ko." ^= "" %then %do;
	%do i=1 %to %sysfunc(countw(&classVariables.,"||"));
	%let classes = %scan(&classVariables.,&i.,"||");
	data estimateso&i. (rename = Estimate = Estimate_&i.) ;
	set estimate (keep= %scan(&classVariables.,&i.) Estimate);
	if &classes. = "" then delete;
	run;
	proc sort data= estimateso&i.;
	by %scan(&classVariables.,&i.);
	quit;
	proc sort data= contribution;
	by %scan(&classVariables.,&i.);
	quit;
	
	data contribution;
	merge contribution estimateso&i.;
	by %scan(&classVariables.,&i.);
	run;
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

%if %sysfunc(exist(contribution_combination)) %then %do;
proc datasets library=work;
   delete contribution_combination;
run; 
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

	%if "&ko."^="" %then %do;
	%let name =;
	%let new_name=;
	%do t=1 %to %sysfunc(countw(&classVariables. , "||"));
		%let name = &name. Estimate_&t.;
		%let new_name = &new_name. %scan("&classVariables." , &t. , "||");
	%end;
	%put &name.;
	%put &new_name.;
	%if "&name."^= "" %then %do;
	data _null_;
		call symput("namess" , tranwrd("&name." , " " , ','));
		run;
		%put &namess.;
	%end;
	%end;

/* calculation of absolute contribution values */
data contribution_final1;
	set contribution_final;
	%do k = 1 %to %sysfunc(countw(&independentVariables. , "||"));
		%let chk_transform = %scan("&independentTransformation." , &k. , "||");
		%put &chk_transform.;
		%if "&chk_transform." = "log" %then %do;
			%if "&dependentTransformation." = "log" %then %do;
				%if "&intercept_estimate."^="" %then %do;
				log_%scan("&independentVariables." , &k. , "||") = (log_%scan("&independentVariables." , &k. , "||")*(pred_antilog_var-exp(intercept)))/(pred_dep-intercept);
				%end;
				%else %do;
				log_%scan("&independentVariables." , &k. , "||") = (log_%scan("&independentVariables." , &k. , "||")*(pred_antilog_var))/(pred_dep);
				%end;

			%end;
			%else %do;
				log_%scan("&independentVariables." , &k. , "||") = log_%scan("&independentVariables." , &k. , "||");
			%end;
		%end;
		%else %do;
			%if "&dependentTransformation." = "log" %then %do;
				%if "&intercept_estimate."^="" %then %do;
				%scan("&independentVariables." , &k. , "||") = (%scan("&independentVariables." , &k. , "||")*(pred_antilog_var-exp(intercept)))/(pred_dep-intercept);
				%end;
				%else %do;
				%scan("&independentVariables." , &k. , "||") = (%scan("&independentVariables." , &k. , "||")*(pred_antilog_var))/(pred_dep);
				%end;
			%end;
			%else %do;
				%scan("&independentVariables." , &k. , "||") = %scan("&independentVariables." , &k. , "||");
			%end;
		%end;
	%end;
run;

%if "&intercept_estimate."^="" or "&ko."^="" %then %do; 	
	
		data contribution_final2 (keep = %do w = 1 %to %sysfunc(countw(&classVariables. , "||"));Estimate_&w. %end; %if "&intercept_estimate."^="" %then %do; intercept %end;);
			set contribution_final;
			%if "&dependentTransformation." = "log" %then %do;
			%do w = 1 %to %sysfunc(countw(&classVariables. , "||"));
				%if "&intercept_estimate."^="" %then %do;
					Estimate_&w. = (Estimate_&w. * (pred_antilog_var-exp(intercept)))/(pred_dep-intercept);
				%end;
				%else %do;
					Estimate_&w. = (Estimate_&w. * (pred_antilog_var))/(pred_dep);
				%end;
				%end;
				%if "&intercept_estimate."^="" %then %do;
					intercept = exp(intercept);
				%end;
				
			%end;
			%else %do;
			%if "&intercept_estimate."^="" %then %do;
				intercept = intercept;
			%end;
			%do w = 1 %to %sysfunc(countw(&classVariables. , "||"));
				Estimate_&w. = Estimate_&w.;
				%end;
			%end;
		run;

	data contribution_final1;
	merge contribution_final1 contribution_final2;
	run;
%end;

/*Rearranging the columns*/
	proc sql;
    create table contribution_final1 as
    select panel_name,panel_level,%if "&intercept_estimate."^="" %then %do;intercept,%end;&vars.,pred_dep,actual_dep, &model_date_var.,%if "&ko." ^="" %then %do;&namess.,%end;pred_antilog_var
    from contribution_final1;
    quit;

		%if "&ko."^="" %then %do;
		data contribution_final1(rename = (%do q = 1 %to %sysfunc(countw(&classVariables. , "||"));  %scan(&name. , &q. , " ") = %scan(&new_name. , &q. , " "))%end; );
			set contribution_final1;
			run;
		%end;
	

	
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
			%if "&ko."^="" %then %do;
			data _null_;
			call symput("classs",tranwrd("&new_name."," ","||"));
			run;
			%end;
			/*Grouping by date variable to find the unique date value column*/
			%if "&intercept_estimate."^="" %then %do;
			proc sql;
			create table subsett&l.&n. as select distinct(&model_date_var.),panel_name,panel_level,sum(intercept) as intercept,%do m=1 %to %sysfunc(countw(&varss.,'||'));sum(%scan(&varss.,&m.,'||')) as %scan(&varss.,&m.,'||') ,%end; 
	%if "&ko."^="" %then %do;%do p=1 %to %sysfunc(countw(&new_name.,' '));sum(%scan(&new_name.,&p.,' ')) as %scan(&new_name.,&p.,' ') ,%end;%end; 
	sum(pred_dep) as pred_dep,sum(actual_dep) as actual_dep,sum(pred_antilog_var) as pred_antilog_var from subset&l.&n. group by &model_date_var.;
			quit;
			%end;
			%else %do;
			proc sql;
			create table subsett&l.&n. as select distinct(&model_date_var.),panel_name,panel_level,%do m=1 %to %sysfunc(countw(&varss.,'||'));sum(%scan(&varss.,&m.,'||')) as %scan(&varss.,&m.,'||') ,%end; 
	%if "&ko."^="" %then %do;%do p=1 %to %sysfunc(countw(&new_name.,' '));sum(%scan(&new_name.,&p.,' ')) as %scan(&new_name.,&p.,' ') ,%end;%end; 
	sum(pred_dep) as pred_dep,sum(actual_dep) as actual_dep,sum(pred_antilog_var) as pred_antilog_var from subset&l.&n. group by &model_date_var.;
			quit;
			%end;
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


/*Exporting the contribution csv*/
proc export data = contri_final
			outfile = "&output_path/contribution.csv"
			dbms = CSV replace;
			run;
	data out.contribution;
		set contri_final;
		run;

%macro equation;

%if "&k."^= "" %then %do;
data estimate;
format variable $32.;
set estimate;
if countw(Variable) >1 then Class_Var_level=strip(Variable);
%do i=1 %to %sysfunc(countw(&classVariables.,"||"));
x&i.= index(Class_Var_level,"%scan(&classVariables.,&i.)");
if x&i.^=0 then Class_Var_level= "%scan(&classVariables.,&i.)";
if x&i.^=0 then Variable= cats(Class_var_level,"_",%scan(&classVariables.,&i.));
%end;
run;
%end;

	data estimate;
	set estimate;
/*	%if "&per_group_by."^= "" %then %do;*/
/*	variable = cats(variable,"_","&per_group_by.");*/
/*	%end;*/
	if substr(Variable,1,4) = "log_" then variable = tranwrd(Variable,"log_","log(");
	if substr(Variable,1,4) = "log(" then variable = cats(Variable,"_&aliasmodelname.",")");
	else variable = cats(Variable,"_&aliasmodelname.");
	if Estimate>=0 then 
	paramestimat = cats(Estimate,"*",Variable);
	else paramestimat = cats("(",Estimate,")","*",Variable);
	run;
	
	%if "&intercept_estimate."^="" %then %do;
	proc sql;
	select paramestimat into:rhs2 separated by ' + ' from estimate where Variable = "Intercept_&aliasmodelname.";
	quit;
	%put &rhs2.;
	%let rhs3 = %sysfunc(tranwrd(&rhs2.,*Intercept_&aliasmodelname.,));
	%end;
	
	
	
	proc sql;
	select paramestimat into:rhs separated by ' + ' from estimate where Variable^= "Intercept_&aliasmodelname.";
	quit;
	%put &rhs.;
	

	data estimate;
	set estimate;
	if variable = "Intercept_&aliasmodelname." then
	paramestimat = estimate;
	run;

	%if "&intercept_estimate."^="" %then %do;
	%let final=&rhs3. + &rhs.;
	%put &final.;
	%end;
	%else %do;
	%let final=&rhs.;
	%put &final.;
	%end;

/*	proc sql;*/
/*	select Dependent into:dep from estimate;*/
/*	quit;*/
/*	%put &dep.;*/

	
	%let dep = &dependentVariable.;
	
	
	
	
	%if "&dependentTransformation." = "log" %then %do;
	%let eqn=&dep. = exp(&final.);
	%end;
	%else %do; 
	%let eqn=&dep. = &final.;
	%end;
	%put &eqn;
	
	data _NULL_;
		v1= "&eqn.";
		file "&output_path./MODEL_EQUATION.txt";
		PUT v1;
	run;
	/*Exporting the contribution csv*/
proc export data = estimate
			outfile = "&output_path/parameter.csv"
			dbms = CSV replace;
			run;
%mend equation;
%equation;
/*Completed txt generated*/
data _NULL_;
		v1= "MUMIX-CONTRIBUTION_COMPLETED";
		file "&output_path./CONTRIBUTION_COMPLETED.txt";
		PUT v1;
run;


%mend;
%GLM_contribution;


