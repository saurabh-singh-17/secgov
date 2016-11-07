*processbody;
options mprint mlogic symbolgen mfile;

FILENAME MyFile "&output_path./ERROR.txt";

DATA _NULL_;
	rc = FDELETE('MyFile');
RUN;

proc datasets lib=work kill nolist;
quit;

dm log 'clear';
proc printto log="&output_path./GeneralLinearModel_Log.log";
run;
quit;


FILENAME MyFile "&output_path./WARNING.txt";

DATA _NULL_;
	rc = FDELETE('MyFile');
RUN;

/* log="&output_path./GeneralLinearModel_Log.log"*/



/*dm log 'clear';*/
libname in "&input_path.";
libname group "&group_path.";
libname out "&output_path.";
%let indep_var=;

%MACRO plots(dataset,pref);
	%let dsid = %sysfunc(open(&dataset));
	%let nobs =%sysfunc(attrn(&dsid,NOBS));
	%let rc = %sysfunc(close(&dsid));

	%if &nobs. > 5500 %then
		%do;
			/*Predicted Vs Actual Plot*/
			data anno;
				function='move';
				xsys='1';
				ysys='1';
				x=0;
				y=0;
				output;
				function='draw';
				xsys='1';
				ysys='1';
				color='green';
				x=100;
				y=100;
				output;
			run;

			ods graphics on/ width=20in height=20in;
			ods listing;
			filename image "&output_path./&pref.PredictedvsActual.png";
			goptions reset=all device =  png300 Transparency gsfname=image gsfmode=replace;
			footnote1 h = .5 '  ';
			symbol1 font = marker value=U height=.3 color=orange width=20;
			axis1 label=('Predicted');
			axis2 label=('Actual');

			proc gplot data= &dataset;
				plot pred*actual/anno=anno vaxis=axis2 haxis=axis1;
			run;

			ods listing close;
			ods graphics off;

			/*---------------------------------------------------------*/
			/*Predicted Vs Residual Plot*/
			ods graphics on/ width=20in height=20in;
			ods listing;
			filename image "&output_path./&pref.PredictedvsResidual.png";
			goptions reset=all device =  png300 Transparency gsfname=image gsfmode=replace;
			footnote1 h = .5 '  ';
			symbol1 font = marker value=U height=.3 color=orange;
			axis1 label=('Predicted');
			axis2 label=('Residual');

			proc gplot data= &dataset;
				plot pred*resid/vaxis=axis2 haxis=axis1;
			run;

			ods listing close;
			ods graphics off;

			/*---------------------------------------------------------*/
			/*Residual Vs Actual Plot*/
			ods graphics on/ width=20in height=20in;
			ods listing;
			filename image "&output_path./&pref.ResidualvsActual.png";
			goptions reset=all device =  png300 Transparency gsfname=image gsfmode=replace;
			footnote1 h = .5 '  ';
			symbol1 font = marker value=U height=.3 color=orange;
			axis1 label=('Residual');
			axis2 label=('Actual');

			proc gplot data= &dataset;
				plot actual*resid/vaxis=axis2 haxis=axis1;
			run;

			ods listing close;
			ods graphics off;

			/*---------------------------------------------------------*/
			/*Residual Vs Leverage*/
			ods graphics on/ width=20in height=20in;
			ods listing;
			filename image "&output_path./&pref.ResidualvsLeverage.png";
			goptions reset=all device =  png300 Transparency gsfname=image gsfmode=replace;
			footnote1 h = .5 '  ';
			symbol1 font = marker value=U height=.3 color=orange;
			axis1 label=('Residual');
			axis2 label=('Leverage');

			proc gplot data= &dataset;
				plot resid*leverage/vaxis=axis2 haxis=axis1;
			run;

			ods listing close;
			ods graphics off;

			/*---------------------------------------------------------*/
		%end;
%mend;

%macro regressionn;

	proc datasets library=work kill memtype=data;
	run;

	quit;

	%if "&model_iteration." = "1" %then
		%do;
			%if %sysfunc(exist(&dataset_name.)) %then
				%do;
					%put EXISTS! :-p;
				%end;
			%else
				%do;
					%if "&grp_no" = "0" %then
						%do;

							data group.bygroupdata;
								set in.dataworking;
							run;

						%end;

					/*if the regression is to be performed on pergroupby keep only the required observations*/
					%else
						%do;

							data group.bygroupdata;
								set in.dataworking (where = (GRP&grp_no._flag = "&grp_flag."));
							run;

						%end;
				%end;
		%end;

	proc sort data = in.dataworking out = in.dataworking;
		by primary_key_1644;
	run;

	/*bygroupdata updation*/
	/*updating the bygroupdata for new variable creation*/
	%if "&flag_bygrp_update." = "true" %then
		%do;

			proc sort data = in.dataworking out = in.dataworking;
				by primary_key_1644;
			run;

			proc sort data = group.bygroupdata out = group.bygroupdata;
				by primary_key_1644;
			run;

			data group.bygroupdata;
				merge group.bygroupdata(in=a) in.dataworking(in=b);
				by primary_key_1644;

				if a;
			run;

		%end;

%macro transformations;
	%let independent_variable =;
	%global log_variables;
	%let log_variables =;

	%do i=1 %to %sysfunc(countw("&independent_variables."," "));
		%let independent_var=%scan(&independent_variables.,&i.," ");
		%let independent_trans=%scan(&independent_transformation.,&i.," ");

		%if "&independent_trans."="none" %then
			%do;
				%let independent_variable = &independent_variable. &independent_var.;
			%end;
		%else
			%do;
				%let log_variables = &log_variables. &independent_var.;
				%let independent_variable = &independent_variable. log_&independent_var.;

				data group.bygroupdata;
					set group.bygroupdata;
					log_&independent_var.= log(&independent_var. + 1);
				run;

			%end;
	%end;

	%put &independent_variable.;
	%let independent_variables = &independent_variable.;
	%put &independent_variables.;

	%if "&dependent_transformation."="log" %then
		%do;
			%let log_variables = &log_variables. &dependent_variable.;
			
			data group.bygroupdata;
				set group.bygroupdata;
				log_&dependent_variable.= log(&dependent_variable. +1);
			run;

			%let dependent_variable =log_&dependent_variable.;
		%end;

/*check for log transformation variables*/

	%if "&log_variables." ^= "" %then %do;

		data _null_;
			call symput("log_variables1",cat(tranwrd("&log_variables."," "," = 0 or ")," = 0"));
		run;
	
		data group.bygroupdata;
			set group.bygroupdata;;
			if &log_variables1. then log_variable=0;
			else log_variable =1;
			run;

		proc sql;
			select count(log_variable) into: log_count from group.bygroupdata where log_variable=0;
			run;
			quit;

		%let dsid = %sysfunc(open(group.bygroupdata));
		%let nobs =%sysfunc(attrn(&dsid,NOBS));
		%let rc = %sysfunc(close(&dsid));

		%if &log_count. < &nobs. & &log_count.>0 %then %do; 

			data _null_;
				v1= cat(&log_count.," observations which have value as zero are removed due to log transformation");
				file "&output_path/WARNING.txt";
				put v1;
			run;

		%end;
		%if &log_count. = &nobs. %then %do;

			data _null_;
				v1= "No observations after subsetting the dataset";
				file "&output_path/ERROR.txt";
				put v1;
			run;

			%abort;

		%end;

	%end;
%mend transformations;

%transformations;

/*#########################################################################################################################################################*/
/*PREPARE THE WHERE STATEMENT*/
%let whr =;

/*VALIDATION VAR CONDITION*/
%if "&validation_var" ^= "" %then
	%do;
		%if "&type_glm." = "build" %then
			%do;

				data _null_;
					call symput("whr", "&validation_var. = 1");
				run;

			%end;
		%else
			%do;

				data _null_;
					call symput("whr", "&validation_var. = 0");
				run;

			%end;

		%put &whr;
	%end;

/* check the for log transformation variables having level as 0*/

	%if "&log_variables." ^= "" %then %do;

		%if "&whr." ^= "" %then %do;
			data _null_;
				call symput("whr",cat("&whr."," and log_variable = 1"));
			run;
			%end;
		%else %do;
			data _null_;
				call symput("whr","log_variable = 1");
			run;
			%end;

	%end;

/*OUTLIER VARIABLE CONDITION*/
%if "&outlier_var" ^= "" %then
	%do;
		%let i = 1;

		%do %until (not %length(%scan(&outlier_var, &i)));
			%if "&i." = "1" %then
				%do;

					data _null_;
						call symput("whr_outlier", "%scan(&outlier_var, &i) = 0 ");
					run;

				%end;
			%else
				%do;

					data _null_;
						call symput("whr_outlier", cat("&whr_outlier.", " ", " and %scan(&outlier_var, &i) = 0 "));
					run;

				%end;

			%put &whr_outlier;
			%let i = %eval(&i.+1);
		%end;

		data _null_;
			%if "&whr." = "" %then
				%do;
					call symput("whr", "&whr_outlier.");
				%end;

			%if "&whr." ^= "" %then
				%do;
					call symput("whr", cat("&whr.", " and ", "&whr_outlier."));
				%end;
		run;

		%put &whr;
	%end;

%if "&outlier_var." = "" and "&validation_var." = "" and "&log_variables."="" %then
	%do;

		data bygroupdata;
			set &dataset_name.;
		run;

	%end;
%else
	%do;

		data bygroupdata;
			set &dataset_name.;
			where &whr.;
		run;

	%end;

%let dataset_name = bygroupdata;
/*#CHECKING FOR COUNT OF OBSERVATIONS#*/
%let dsid = %sysfunc(open(&dataset_name.));
%let nobs =%sysfunc(attrn(&dsid,NOBS));
%let rc = %sysfunc(close(&dsid));

%if &nobs. < 10 %then
	%do;

		data _null_;
			v1= "Number of observations used are lesser than 10. Cannot continue.";
			file "&output_path/ERROR.txt";
			put v1;
		run;

		ENDSAS;
	%end;

data _null_;
call symput("independent_variables_1",tranwrd("&independent_variables.","*"," "));
run;
data temp(drop=i j);                                                    
	set &dataset_name.(keep=&independent_variables_1. &class_variables. &dependent_variable.);                                                            
	array nummiss(*) _numeric_;     
	array charmiss(*) _character_;     
	do i = 1 to dim(nummiss);                                              
	  if missing(nummiss(i)) then delete;                                    
	end; 
	do j=1 to dim(charmiss);
	  if missing(charmiss(j)) then delete;
	end; 
	run; 

%let dsid = %sysfunc(open(temp));
%let nobs = %sysfunc(attrn(&dsid.,nobs));
%let rc = %sysfunc(close(&dsid.));

%if &nobs. = 0 %then %do ;
	data _null_;
		v1= "No observations after eliminating missing values from the dataset";
		file "&output_path/ERROR.txt";
		put v1;
		run;
		
		ENDSAS;
%end;

/*#########################################################################################################################################################*/
/*MISSING INFO*/
proc means data=&dataset_name. nmiss;
	output out=means;
	var &dependent_variable. &indep_var.;
run;

proc transpose data=means out=means_trans(rename=(_NAME_=variable col1=nmiss) drop=col2 col3 col4 col5);
run;

/*obtaining the total frequency */
proc sql;
	select nmiss into:freq from means_trans where variable='_FREQ_';
quit;

%put &freq.;

/*calculating the missing count and missing percentage*/
data missing;
	set means_trans;
	nmiss=&freq.-nmiss;
	miss_per=nmiss/&freq.;

	if variable="_TYPE_" or variable="_FREQ_" then
		delete;
run;

/* exporting the missing data*/
proc export data = missing
	outfile = "&output_path./appData_missing.csv"
	dbms = CSV replace;
run;

/*++++++++++++++++++++++++++++++++++++++++++++++++  VIF ++++++++++++++++++++++++++++++++++++++++++++++++*/
%if ("&flag_only_vif." = "true" or "&flag_vif."="true") %then
	%do;
		ods output ParameterEstimates = vif_params(keep= Variable VarianceInflation rename=(VarianceInflation=VIF));

		proc reg data = &dataset_name.;
			model &dependent_variable. = &vif_variables./vif;

			/*                        checking if validation is being done*/
			%if "&validation_var" ^= "" %then
				%do;
					/*                         checking the type if build or validation*/
					%if "&type_glm." = "build" %then
						%do;
							where &validation_var. = 1;
							%put &type_glm. &validation_var.;
						%end;

					%if "&type_glm." = "validation" %then
						%do;
							where &validation_var. = 0;
						%end;
				%end;
		run;

		quit;

		data vif_params;
			length Variable $50.;
			format Variable $50.;
			set vif_params;
			if Variable = "Intercept" then delete;
		run;

		%if ("&flag_only_vif." = "true") %then
			%do;

				proc export data=vif_params
					outfile="&output_path./ModelAnova.csv"
					dbms=csv replace;
				run;

			%end;
	%end;

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
%if "&flag_run_glm."="true" %then
	%do;
		ods output overallanova=anova;
		ods output FitStatistics = fit_stats;
		ods output NObs = nob;
		ods output ModelANOVA=ModelA(rename=(ProbF=PValue Source=Variable ss=SS) drop=Dependent);
		ods output Diff=diff(rename=(Effect=Variable));
		ods output LSMeans=LSMeans(rename=(StdErr=StandardError Probt=PValue Effect=Variable));
		ods output ParameterEstimates = params(drop=Dependent Biased rename=(Parameter=Variable Probt=PValue));
		ods output ClassLevels=classlvl;

		/*running glm regression*/
		proc glm data = &dataset_name. namelen=150;
			%if "&class_variables." ^= "" %then
				%do;
					class &class_variables.;
				%end;

			model &dependent_variable. = &independent_variables. &class_variables. &interaction_var./ &regression_options.;

			%if "&ls_means_variables." ^= "" %then
				%do;
					%if "&flag_pdiff."="true" %then
						%do;
							lsmeans &ls_means_variables./stderr pdiff;
						%end;
					%else
						%do;
							lsmeans &ls_means_variables./stderr;
						%end;
				%end;

			output out=glmout p=pred r=resid stdr=std_error_resid h=leverage rstudent = r_student cookd = cooks_dis dffits = dffits;	;
			%if "&validation_var" ^= "" %then
				%do;
					%if "&type_glm." = "build" %then
						%do;
							where &validation_var. = 1;
						%end;

					%if "&type_glm." = "validation" %then
						%do;
							where &validation_var. = 0;
						%end;
				%end;
		run;

		quit;

		%if   %index(&regression_options.,solution)>0 %then
			%do;

				data params;
/*					format PValue 15.2 StdErr 15.2 tValue 15.2 Estimate 15.2;*/
					set params;
					variable = compbl(variable);
				run;

			%end;

		/*Nob*/
		data Nob(keep=Statistics Value);
			format Value $40.;
			set Nob(rename=(label=Statistics));
			Value=compress(n);
		run;

		/*Anova*/
		proc transpose data=anova out=anovat(drop=Uncorrected_Total _name_);
			id source;
			var SS MS FValue ProbF;
		run;

		data anovat1(rename=(_LABEL_=Statistics) drop=error model);
			set anovat;
			format Value $40.;
			Value=compress(Model);

			if _LABEL_='F Value' then
				_label_='Model F Statistic';

			if _LABEL_='Pr > F' then
				_label_='P Value Model';
			label _LABEL_=Statistics;
		run;

		data anovat2(rename=(_LABEL_=Statistics ) drop=model error);
			set anovat;
			format Value $40.;
			Value=compress(error);

			if _LABEL_='F Value' then
				delete;

			if _LABEL_='Pr > F' then
				delete;
			_label_=trim(left(cat(trim(right(_label_))," ",("Error"))));
			label _LABEL_=Statistics;
		run;

		data anovat3;
			set anovat1 anovat2;
		run;

		/*Class Level*/
		%if "&class_variables." ^= "" %then
			%do;

				data classlvl1(rename=(Class1=Statistics) drop=values class levels);
					set classlvl;
					format Class1 $50.;
					format Value $40.;
					Value=compress(Levels);
					Class1=trim(left(cat(trim(right(Class))," ",("Levels"))));
					label Class1=Statistics;
				run;

				data classlvl2(rename=(Class1=Statistics ) drop=levels class values);
					set classlvl;
					format Class1 $50.;
					format Value $40.;
					Value=trim(left(Values));
					Class1=trim(left(cat(trim(right(Class))," ",("Values"))));
					label class1=Statistics;
				run;

				data classlvl3(keep=Statistics Value);
					set classlvl1 classlvl2;
				run;

			%end;

		/*FitStats*/
		proc transpose data=fit_stats out=fit_stats_t1(drop=_name_ rename=(_LABEL_=Statistics));
		run;

		proc transpose data=fit_stats out=fit_stats_t1(drop=_name_ rename=(_LABEL_=Statistics));
		run;

		data fit_stats_t(drop=col1);
			set fit_stats_t1;
			format Value $40.;
			value=compress(Col1);
		run;

		/*Model Output*/
		data out.glmoutput;
			set glmout(keep= &dependent_variable. pred resid std_error_resid leverage primary_key_1644);
			perc_err=abs(resid)*100/&dependent_variable.;
			actual= &dependent_variable.;
		run;

		data actualvspredicted (drop = &dependent_variable.);
			format pred 15.2 actual 15.2 resid 15.2 leverage 15.2;
			set out.glmoutput(keep= &dependent_variable. actual pred resid leverage);
			actual = &dependent_variable;
		run;

		%if "&dependent_transformation."="log" %then
			%do;

				data actpred;
					format pred 15.2 actual 15.2 resid 15.2 leverage 15.2;
					set actualvspredicted;
					pred= exp(pred);
					actual = exp(actual);
					resid = exp(resid);
				run;

				proc export data=actpred
					outfile="&output_path./normal_chart.csv"
					dbms=csv replace;
				run;

				%plots(actpred,);

				proc export data=actualvspredicted
					outfile="&output_path./transformed_chart.csv"
					dbms=csv replace;
				run;

				%plots(actualvspredicted,Log);
			%end;
		%else
			%do;

				proc export data=actualvspredicted
					outfile="&output_path./normal_chart.csv"
					dbms=csv replace;
				run;

				%plots(actualvspredicted,);
			%end;

		/*MAPE*/
		proc sql;
			create table Mape as
				select "MAPE" as Statistics, avg(perc_err) as Val
					from out.glmoutput;
		quit;

		data Mape(drop=Val);
			set Mape;
			format Value $40.;
			Value=compress(Val);
		run;

		/*Model Statistics*/
		%if "&class_variables." ^= "" %then
			%do;

				data model_statistics(keep=Statistics Value);
					format Statistics $40.;
					set classlvl3 nob fit_stats_t anovat3 MAPE;
				run;

			%end;
		%else
			%do;

				data model_statistics(keep=Statistics Value);
					format Statistics $40.;
					set nob fit_stats_t anovat3 MAPE;
				run;

			%end;

		%if &interaction_type. ^= %str() %then
			%do;

				data model_statistics_temp;
					format Statistics $100. Value $500.;
					Statistics = "Selected Interaction Variables";
					Value = tranwrd("&interaction_var."," "," | ");
				run;

				data model_statistics;
					format Statistics $100. Value $500.;
					set model_statistics model_statistics_temp;
				run;

			%end;

		/*Output CSV*/
		proc export data=model_statistics
			outfile="&output_path./Model_Statistics.csv" 
			dbms=csv replace;
		run;

		data modela;
			set modela;
			length Iteration_transformation $10.;

			if substr(Variable,1,4) = "log_" then
				Iteration_transformation = "log";
			else if Variable ^= "Intercept" then
				Iteration_transformation = "none";
			else Iteration_transformation = "";
		run;

		data modela;
			length original_variable $50.;
			set modela;

			if Iteration_transformation = "log" then
				Original_Variable = substr(Variable , 5 , length(Variable));
			else Original_Variable = Variable;
		run;

		/*Model Anova*/
		%if "&flag_vif."="true" %then
			%do;

				data vif_params(rename = Variable = Original_variable);
					set vif_params;
				run;

				proc sort data=Modela;
					by Original_Variable;
				run;

				proc sort data=vif_params;
					by original_variable;
				run;

				data Modela_vif;
					merge Modela(in=a) vif_params(in=b);
					by original_Variable;

					if a or b;
				run;

				/* if the variable name is more than 20 char length. it doesnt include interaction variables */
				%if (%index("&independent_variables.",*)= 0 and %index("&independent_variables.",|) = 0) %then
					%do;

						data modela_vif;
							length Variable $50.;
							format Variable $50.;
							set modela_vif;
						run;

						%let var_length =;
						%let small_var =;

						%do i=1 %to %sysfunc(countw(&independent_variables. , " "));
							%let var = %scan(&independent_variables. ,&i., " ");
							%let var_len = %sysfunc(length(&var.));
							%let var_length = &var_length. &var_len.;
							%let small = %substr(&var. , 1 , 20);
							%let small_var =&small_var. &small.;
							%put &var_len.;

							data modela_vif;
								set modela_vif;

								if Variable = "&small." then
									Variable = "&var.";
							run;

						%end;

						%put &independent_variables.;
						%put &var_length.;
						%put &small_var.;
					%end;

				data modela_vif;
					format Variable $50. VIF 15.2;
					set modela_vif;
				run;

				/*  to handle the truncation of the interaction variables. If the variables used for interaction have length more
								 than 10 then the 1st var gets truncated to 9 letters and the 2nd var gets truncated to 10 letters 
								and the interaction symbol (* or |)`.so no matter what the interaction variable has length of 20.*/
				%let newvar=;

				%do i=1 %to %sysfunc(countw(&independent_variables.," "));
					%let testvar=%scan("&independent_variables.",&i.," ");

					%if (%index("&testvar.",*)>0 or %index("&testvar.",|)>0) %then
						%do;
							%let newvar= &newvar &testvar.;
						%end;
				%end;

				%put &newvar.;

				%do j=1 %to %sysfunc(countw(&newvar.," "));
					%let testvar=%scan("&newvar.",&j.," ");

					data modela_vif;
						length Variable $70.;
						set Modela;

						if (index("&testvar.",compress(substr(Variable,1,9)))>0 && index("&testvar.",compress(substr(Variable,11,20)))>0 and (index(Variable,"*")>0 or index(Variable,"|")>0)) then
							do;
								Variable="&testvar.";
							end;
					run;

				%end;

				data Modela(rename = variable = Variable);
					format SS 15.2 MS 15.2 FValue 15.2;
					set modela_vif;
				run;

			%end;

		data modela(rename = original_variable = Variable);
			format SS 15.2 MS 15.2 FValue 15.2;
			set modela(drop = Variable);
			if original_variable = "Intercept" then delete;
		run;

		proc export data=Modela
			outfile="&output_path./ModelAnova.csv"
			dbms=csv replace;
		run;

		/*Only if pdiff is selected*/
		%if "&flag_pdiff."="true" %then
			%do;
				%if %sysfunc(exist(diff)) %then
					%do;
						%put diff exists;

						proc export data=diff
							outfile="&output_path./Pdiff.csv"
							dbms=csv replace;
						run;

					%end;
			%end;

		/*Only if Lsmeans variabke is not blank is selected*/
		%if "&ls_means_variables." ^= "" %then
			%do;

				data lsmeans(drop= dependent ProbtDiff);
					set lsmeans;
					Level=compress(&ls_means_levels.);
				run;

				data lsmeans;
					format LSMean 15.2 StandardError 15.2;
					set lsmeans;
				run;

				proc sql;
					create table lsmeans1 as
						select      Variable, Level, 
							/*                                                                LSMeanNumber,*/
							LSMean,      StandardError,    PValue
						from lsmeans;
				quit;

				%if %sysfunc(exist(lsmeans1)) %then
					%do;
						%put lsmeans1 exists;

						proc export data=lsmeans1
							outfile="&output_path./Lsmeans.csv"
							dbms=csv replace;
						run;

					%end;
				%else
					%do;

						proc export data=lsmeans
							outfile="&output_path./Lsmeans.csv"
							dbms=csv replace;
						run;

					%end;
			%end;

		/*Only if solution is selected*/
		%if   %index(&regression_options.,solution)>0 %then
			%do;

				proc export data=params
					outfile="&output_path./ParameterEstimates.csv"
					dbms=csv replace;
				run;

			%end;

		/*	exporting outdata for modeling outlier treatment*/

		data out.outdata(keep=&dependent_variable. primary_key_1644 actual pred resid cooks_dis leverage r_student dffits);
			set glmout;
			run;

		data out.outdata(rename=(resid=res));
			set out.outdata;
			hat_diag=leverage;
			run;

	%end;



%MEND;

%macro glm_ancova;
	/*
	ancova
	--
	will get two parameters interaction_var and interaction_type
	if interaction_type has cont_cate (or) cate_cont, then have to calculate ancova
		*/
	%let glm_ancova_done = no;
	%let c_data_ancova = &dataset_name.;

	%if "&validation_var" ^= "" %then
		%do;
			%let c_data_ancova = murx_ancova;

			data &c_data_ancova.;
				set &dataset_name.;
				%if "&type_glm." = "build"      %then if &validation_var. = 1;;
				%if "&type_glm." = "validation" %then if &validation_var. = 0;;
			run;
		%end;

	%do i = 1 %to %sysfunc(countw(&interaction_type.));
		%let current_interaction_type = %scan(&interaction_type., &i., %str( ));
		%let current_interaction_var  = %scan(&interaction_var.,  &i., %str( ));

		%if %index(&current_interaction_type., cate_cont) or %index(&current_interaction_type., cont_cate) %then
			%do;
				%let glm_ancova_done = yes;

				%if &current_interaction_type. = cate_cont %then
					%do;
						%let current_cont_var = %scan(&current_interaction_var., 2, %str(*));
						%let current_cate_var  = %scan(&current_interaction_var., 1, %str(*));
					%end;

				%if &current_interaction_type. = cont_cate %then
					%do;
						%let current_cont_var = %scan(&current_interaction_var., 1, %str(*));
						%let current_cate_var  = %scan(&current_interaction_var., 2, %str(*));
					%end;

				ods output parameterestimates = parameterestimates;

				proc glm data=&c_data_ancova. namelen=100;
					class &current_cate_var.;
					model &dependent_variable. = &current_cont_var. &current_cate_var. &current_cont_var.*&current_cate_var./ solution;
					output predicted=pred out=ancova_out_temp(keep = &dependent_variable. &current_cont_var. &current_cate_var. pred);
				run;

				quit;

				%let dsid = %sysfunc(open(ancova_out_temp));
				%let varnum_class= %sysfunc(varnum(&dsid., class));
				%let vartype_class= %sysfunc(vartype(&dsid., &varnum_class.));
				%let rc = %sysfunc(close(&dsid.));

				%if &vartype_class. = N %then
						%let class_var = class_item = put(left(trim(&current_cate_var.)), 32.)%str(;);
				%else %let class_var = class_item = &current_cate_var.%str(;);

				data ancova_out_temp(drop = &current_cate_var. rename=(class_item=&current_cate_var.));
					format class_item $100.;
					set ancova_out_temp;
					&class_var.
				run;

				%let dsid = %sysfunc(open(ancova_out_temp));
				%let nobs= %sysfunc(attrn(&dsid., nobs));
				%let rc = %sysfunc(close(&dsid.));
				%let c_temp = %sysfunc(tranwrd(%str(&current_interaction_var.), %str(*) , %str(_)));
				%let c_temp = %sysfunc(lowcase(&c_temp.));
				
				%if &nobs. > 6000 %then
					%do;
						ods graphics on;
						ods listing;
						filename grafout "&output_path./&c_temp..png";
						goptions reset=all device=png gsfname=grafout xpixels=800 ypixels=600;

						symbol1 interpol=reg value=diamond width=3;

						proc gplot data=&c_data_ancova.;
							plot &dependent_variable. * &current_cont_var. = &current_cate_var.;
						run;
						quit;
						ods listing close;
						ods graphics off;
					%end;

						data ancova_out_temp;
							set ancova_out_temp(rename=(&dependent_variable. = y &current_cont_var. = x &current_cate_var. = class_item));
						run;
						
						proc export data=ancova_out_temp outfile="&output_path./ancova.csv" dbms=csv replace;
						run;
						quit;

			%end;
	%end;

%mend glm_ancova;

%macro glm_workflow;
	%regressionn;

	%if &interaction_type. ^= %str() %then
		%glm_ancova;
%mend glm_workflow;

%glm_workflow;

/*Flex uses this file to test if the code has finished running*/
data _null_;
	v1= "GENERAL_LINEAR_MODEL_COMPLETED";
	file "&output_path/GENERAL_LINEAR_MODEL_COMPLETED.txt";
	put v1;
run;

