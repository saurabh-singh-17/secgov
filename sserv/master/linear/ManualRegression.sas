
*processbody;
goptions reset=all;
options mprint mlogic symbolgen mfile;

proc printto log="&output_path./ManualRegression_Log.log";
	run;
	quit;

/* log="&output_path./ManualRegression_Log.log"*/
	
FILENAME MyFile "&output_path./No_valid_observations.txt" ;
  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;
  
FILENAME MyFile "&output_path./validation.xml" ;
  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;

FILENAME MyFile "&output_path./GENERATE_FILTER_FAILED.txt" ;
  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;

/* log="&output_path./ManualRegression_Log.log"*/
libname in "&input_path.";
libname group  "&group_path.";
libname out "&output_path.";

/*Macro to formal all values to have only 2 values after the decimal point*/
/*%macro changeformat(dataname);*/
/*	data &dataname.;*/
/*		set &dataname.;*/
/*		format _numeric_ 15.2;*/
/*			run;*/
/*%mend;*/

%let dataset_name=in.dataworking;
%let indep = &independent_variables.;
%let indeptrans = &independent_transformation.;

%let initial_indep_var=&independent_variables.;
%let initial_dep=&dependent_variable.;

%let filter_whr=;
%macro Filter_chk;
%if "&flag_filter." = "true" %then %do;
	%let whr=;
	%let super_cn = and;

	data filter;
    	infile "&filterCSV_path." delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
			retain name ID type classification values;
			length values $5000.;
			informat name $32.; informat ID best32.; informat type $12.; informat classification $8.; 
				informat values $5000.; informat condition $7.; informat scope $9.; informat select $5.;
    		format name $32.; format ID best12.; format type $12.; format classification $8.; format values $5000.; 
				format condition $7.; format scope $9.; format select $5.;
  			input name $ ID type $ classification $ values $ condition $ scope $ select $;
  			run;
	%let path = %substr(&filterCSV_path.,1,%length(&filterCSV_path.)-%length(%scan(&filterCSV_path.,-1,"/"))-1);
	data filter_data (rename= values = completed_values);
		infile "&path./filterData.csv" delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
			retain variable ID values;
			length values $5000.;
			informat variable $32.; informat ID best32.; informat values $5000.; 
    		format variable $32.; format ID best12.; format values $5000.; 
  			input variable $ ID values $;
  			run;

	data filter;
		length whr_var $5000.;
		set filter;
		where strip(lowcase(select)) = "true";
		if strip(lowcase(type)) = "categorical" and strip(lowcase(classification))="numeric" and strip(lowcase(condition))="in" and strip(values) = "" then do;
			values = 525263475374584641241;
		end;
/*		if strip(lowcase(type)) = "categorical" and (strip(lowcase(classification))="numeric" or strip(lowcase(classification))="string") and strip(lowcase(condition))="not in" then do;*/
/*			if values=completed_values then do;*/
/*			whr_var = cat("(", strip(name), " ", in, " (", "", ")", ")");*/
/*			end;*/
/*		end;*/
		if strip(lowcase(type)) = "categorical" and (strip(lowcase(classification))="numeric" or strip(lowcase(classification))="string") and strip(values) = "" and strip(lowcase(condition))="in" then do;
			whr_var = cat("(", strip(name), " ", strip(condition), " (", strip(values), ")", ")");
		end;
		if strip(lowcase(type)) = "categorical" and strip(lowcase(classification))="numeric" then do;
			whr_var = cat("(", strip(name), " ", strip(condition), " (", tranwrd(strip(values),"!!", ", "), ")", ")");
		end;
		if strip(lowcase(type)) = "categorical" and strip(lowcase(classification))="string" then do;
			whr_var = cat("(", strip(name), " ", strip(condition), " ('", tranwrd(strip(values), "!!", "','"), "')", ")");
		end;
		if strip(lowcase(type)) = "continuous" and strip(lowcase(classification))="numeric" and strip(lowcase(condition)="in") then do;
			whr_var = cat("(", strip(name), " >= ", scan(strip(values), 1, "!!"), " and ", strip(name), " <= ", scan(strip(values), 2, "!!"), ")");
		end;
		if strip(lowcase(type)) = "continuous" and strip(lowcase(classification))="numeric" and strip(lowcase(condition)="not in") then do;
			whr_var = cat("(", strip(name), " < ", scan(strip(values), 1, "!!"), " or ", strip(name), " > ", scan(strip(values), 2, "!!"), ")");
		end;
		if strip(lowcase(type)) = "continuous" and strip(lowcase(classification))="date" and strip(lowcase(condition)="in") then do;
			whr_var = cat("(", strip(name), " >= ", "'", scan(strip(values), 1, "!!"), "'d and ", strip(name), " <= ", "'", scan(strip(values), 2, "!!"), "'d)");
		end;
		if strip(lowcase(type)) = "continuous" and strip(lowcase(classification))="date" and strip(lowcase(condition)="not in") then do;
			whr_var = cat("(", strip(name), " < ", "'", scan(strip(values), 1, "!!"), "'d or ", strip(name), " > ", "'", scan(strip(values), 2, "!!"), "'d)");
		end;
	run;

	%let global_vars=;
	%let local_vars=;
	proc sql;
		select (name) into :global_vars separated by " " from filter where scope="dataset";
		select (name) into :local_vars separated by " " from filter where scope="variable";
		quit;

	%put &global_vars.;
	%put &local_vars.;
	data _null_;
		call symput("glob_vars", cats("'", tranwrd("&global_vars.", " ", "', '"),"'"));
		run;
	%put &glob_vars;
	
/*COLLATE ALL CONDITIONS TO CREATE WHERE STATEMENT*/
	%let whr_filter =; 
	proc sql;
		select (whr_var) into :whr_filter separated by " &super_cn. " from filter where name in (&glob_vars.);
		quit;
	%put &whr_filter;


%put &local_vars.;
	

	proc sql;
	%if "&local_vars." ^= "" %then %do;
		%do i=1 %to %sysfunc(countw(&local_vars.));
			%let this_var = %scan(&local_vars,&i);
			%global whr_&this_Var.;
			select (whr_var) into :whr_&this_Var. from filter where strip(name) ="&this_Var.";
		%end;
		quit;

		%do i=1 %to %sysfunc(countw(&local_vars.));
			%let this_var = %scan(&local_vars,&i);
			%put &&whr_&this_Var.;
		%end;
	%end;

	data _null_;
		call symput ("filter", cat("'", tranwrd(lowcase("&filter_vars."), " ", "', '"), "'"));
		run;

/* applying variable specific filters */
	%if "&local_vars." ^= "" %then %do;
	   		/*join local whr conditions to whr_filter*/
			%do i=1 %to %sysfunc(countw(&local_vars.));
				%let this_var = %scan(&local_vars,&i);
				%let this_vaar = %sysfunc(lowcase(%unquote(%str(%'&this_var.%'))));
				%put &this_vaar;

				%put &&whr_&this_Var.;

				%if %index("&filter.", &this_vaar) > 0 %then %do;
					%if "&whr_filter." = "" %then %do;
						%let whr_filter = &&whr_&this_Var.;
					%end;
					%if "&whr_filter." ^= "" %then %do;
						%let whr_filter = &whr_filter. and &&whr_&this_Var.;
					%end;
				%end;
			%end;
		%end;

		/*join whr_filter to whr*/
		%if "&whr_filter." ^= "" %then %do;
			data _null_;
				%if "&whr." = "" %then %do;
					call symput("whr", "&whr_filter.");
				%end;
				%if "&whr." ^= "" %then %do;
					call symput("whr", cat("&whr.", " and ", "&whr_filter."));
				%end;
				run;
			%put &whr;
		%end;
	%let filter_whr=&whr.;
%end;
%mend;
%Filter_chk;

%macro bygroupdata;
	%if "&model_iteration." = "1" %then %do;
		%if %sysfunc(exist(group.bygroupdata)) %then %do;
			data group.bygroupdata;
				set group.bygroupdata;
				actual = &dependent_variable.;
				run;
			%put exists;
		%end;
		%else %do;
			%if "&grp_no" = "0" %then %do;
		      	data group.bygroupdata;
		            set &dataset_name.;
					actual = &dependent_variable.;
		            run;	
		    %end;
			%else %do;
		    	data group.bygroupdata;
		      		set &dataset_name. (where = (GRP&grp_no._flag = "&grp_flag."));
					actual = &dependent_variable.;
					run;
		    %end;
		%end;
	%end;


	%if "&flag_bygrp_update." = "true" %then %do;
		proc sort data = &dataset_name. out = &dataset_name.;
			by primary_key_1644;
			run;

		proc sort data = group.bygroupdata out = group.bygroupdata;
			by primary_key_1644;
			run;

		data group.bygroupdata;
			merge group.bygroupdata(in=a) &dataset_name.(in=b);
			by primary_key_1644;
			if a;
			run;
	%end;
%mend;
%bygroupdata;

%macro transformations;

/*%let independent_dependent_var =&independent_variables. &dependent_variable.;*/
/*%let independent_dependent_trans = &independent_transformation. &dependent_transformation.;*/

%let independent_variable=;

data group.bygroupdata;
	set group.bygroupdata;
	%do i=1 %to %sysfunc(countw(&independent_variables.));
		%let independent_var=%scan(&independent_variables.,&i.);
		%let independent_trans=%scan(&independent_transformation.,&i.);
		%if "&independent_trans."="none" %then %do;
	   		%let independent_variable = &independent_variable. &independent_var.;
		%end;
		%else %do;
        	%let independent_variable = &independent_variable. log_&independent_var.;
			log_&independent_var.= log(&independent_var. + 1);
		%end;
	%end;
	run;
%put &independent_variable.;
%let independent_variables = &independent_variable.;
%put &independent_variables.;

%if "&dependent_transformation."="log" %then %do;
	data group.bygroupdata;
		set group.bygroupdata;
		log_&dependent_variable.= log(&dependent_variable. + 1);
		run;

%let dependent_variable =log_&dependent_variable.;
%end;

%mend transformations;
%transformations;
%put &independent_variables.;
%put &dependent_variable.;

%MACRO plots(dataset, flag);
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
			filename image %if &flag. = 0 %then
			%do;
				"&output_path./PredictedvsActual.png";
			%end;
			%else
			%do;
				"&output_path./PredictedvsActual_Transformed.png";
			%end;

			goptions device = pngt gsfname=image gsfmode=replace;
			footnote1 h = .5 '  ';
			symbol1 font = marker value=U height=.3 color=orange width=20;
			axis1 label=('Predicted');
			axis2 label=('Actual');

			proc gplot data= &dataset;
				plot pred*actual/anno=anno vaxis=axis1 haxis=axis2;
			run;

			ods listing close;
			ods graphics off;
			
			/*---------------------------------------------------------*/
			/*Residual Vs Predicted Plot*/
			ods graphics on/ width=20in height=20in;
			ods listing;
			filename image %if &flag. = 0 %then

			%do;
				"&output_path./ResidualvsPredicted.png";
			%end;
			%else
			%do;
			"&output_path./ResidualvsPredicted_Transformed.png";
			%end;

			goptions device = pngt transparency gsfname=image gsfmode=replace;
			footnote1 h = .5 '  ';
			symbol1 font = marker value=U height=.3 color=orange;
			axis1 label=('Residual');
			axis2 label=('Predicted');

			proc gplot data= &dataset;
			plot res*pred/vaxis=axis1 haxis=axis2;
			run;

			ods listing close;
			ods graphics off;

			/*Residual Vs Leverage*/
			ods graphics on/ width=20in height=20in;
			ods listing;
			filename image %if &flag. = 0 %then

			%do;
			"&output_path./ResidualvsLeverage.png";
			%end;
			%else
			%do;
			"&output_path./ResidualvsLeverage_Transformed.png";
			%end;;

			goptions device = pngt gsfname=image gsfmode=replace;
			footnote1 h = .5 '  ';
			symbol1 font = marker value=U height=.3 color=orange;
			axis1 label=('Residual');
			axis2 label=('Leverage');

			proc gplot data= &dataset;
			plot res*leverage/vaxis=axis1 haxis=axis2;
			run;

			ods listing close;
			ods graphics off;

			/*---------------------------------------------------------*/
			/*Actual Vs Predicted*/
			ods graphics on/ width=20in height=20in;
			ods listing;
			filename image %if &flag. = 0 %then
			%do;
			"&output_path./ActualvsPredicted.png";
			%end;
			%else
			%do;
			"&output_path./ActualvsPredicted_Transformed.png";
			%end;;

			goptions device = pngt gsfname=image gsfmode=replace;
			footnote1 h = .5 '  ';
			symbol1 interpol=join color=green font=marker value=U height=0.3 w=1;
			symbol2 interpol=join color=orange font=marker value=U height=0.3 w=1;
			axis1 label=('Actual & Predicted');
			axis2 label=('Dataset Order');

			proc gplot data= &dataset;
			plot (Actual Pred)*primary_key_1644/overlay vaxis=axis1 haxis=axis2;
			run;

			ods listing close;
			ods graphics off;

			/*---------------------------------------------------------*/
		%end;
%mend;
;



%macro regression;

data _null_;
	call symputx("sas_report_name", compress(tranwrd("&sas_report_name" ,"/" ,"_" )));
	run;
 data _null_;
  call symputx("outlier_var",tranwrd("&outlier_var",","," "));
  run;
data _null_;
		call symput ("independent_variables", compbl("&independent_variables."));
		run;
	%put &independent_variables;
	data _null_;
		call symput ("indep_list", cat("'", tranwrd(lowcase("&independent_variables."), " ", "', '"), "'"));
		run;
	%put &indep_list.;

%let whr =;

	%if "&validation_var" ^= "" %then %do;
		data _null_;
			call symput("whr", "&validation_var. = 1");
			run;
		%put &whr;
	%end;

	%if "&outlier_var" ^= "" %then %do;
		%let i = 1;
		%do %until (not %length(%scan(&outlier_var, &i)));
			%if "&i." = "1" %then %do;
				data _null_;
					call symput("whr_outlier", "%scan(&outlier_var, &i) = 0 ");
					run;
			%end;
			%else %do;
				data _null_;
					call symput("whr_outlier", cat("&whr_outlier.", " ", " and %scan(&outlier_var, &i) = 0 "));
					run;
			%end;

			%put &whr_outlier;
			%let i = %eval(&i.+1);
		%end;

		data _null_;
			%if "&whr." = "" %then %do;
				call symput("whr", "&whr_outlier.");
			%end;
			%if "&whr." ^= "" %then %do;
				call symput("whr", cat("&whr.", " and ", "&whr_outlier."));
			%end;
			run;
		%put &whr;
	%end;

%if "&flag_html." = "true" %then %do;
	%if "&grp_no." = "0" %then %do;
		data _null_;
			call symput("html_file", cats("&dependent_variable.", "-", "iteration=&model_iteration."));
			run; 
	%end;
	%else %do;
		libname keys xml "&input_path./&grp_no./byvar_keys.xml";
		data key_names;
			set keys.key_names;
			run;
/*		%changeformat(key_names);*/
		proc sql;
			select (key_name) into :html_file from key_names where flag = "&grp_flag.";
			quit;

		data _null_;
			call symput("html_file", cats("&dependent_variable.", "-", "&html_file.", "-", "iteration=&model_iteration."));
			run;
	%end;
	data _null_;
		call symputx("html_file", compress(tranwrd("&html_file" ,"/" ,"_" )));
		run;

	%put &html_file;
%end;

ods output DependenceEquations = dependenceequations;
%if &flagOnlyVif. = true %then %do;
ods output ParameterEstimates=out.paraes(drop= Estimate tValue Probt StdErr StandardizedEst Label);
%end;
%else %do;
ods output ParameterEstimates=out.paraes(drop= Label);
%end;
ods output NObs = nob;
ods output ANOVA = anova;
ods output FitStatistics = fitstatistics;
ods output ACovEst = acovest;
ods output DWStatistic = dwstatistic;
%if "&flag_html." = "true" %then %do;
ods html path = "&html_path." file = "reg_&html_file..xls" style = statdoc;
%end;
%if "&sas_report."="true" %then %do;
	ods html path = "&sas_report_path." file="sas_&sas_report_name..xls" style=statdoc;
%end;
	proc reg data = group.bygroupdata outest = out.out_betas tableout edf ;
			 	model &dependent_variable. = &independent_variables./vif influence stb dw aic acov &regression_options.
				%if %index("&regression_options", "selection=stepwise") %then %do; sls=&sls. sle=&sle. %end;
				%if %index("&regression_options", "selection=forward") %then %do; sls=&sls. sle=&sle. %end;
				%if %index("&regression_options", "selection=backward") %then %do; sls=&sls. sle=&sle. %end;
				%if %index("&regression_options", "selection=rsquare") %then %do; sls=&sls. sle=&sle. %end;
			  	;
			  	output out=out.outdata p=pred r=res h=leverage rstudent = r_student cookd = cooks_dis dffits = dffits;
			%if "&whr." ^= "" %then %do;
				where &whr.;
			%end;
			%if "&filter_whr." ^= "" %then %do;
				where &filter_whr.;
			%end;
			run;
			quit;
	%if "&flag_html." = "true" %then %do;
	ods html close;
	%end;
	%if "&sas_report."="true" %then %do;
	ods html close;
	%end;

	proc sql;
	select N into:Valid_obs from Nob where Label = "Number of Observations Used";
	quit;

	%put &Valid_obs.;

	%if &Valid_obs.=0 %then %do; 
		data _NULL_;
			v1= "No valid observations";
			file "&output_path./No_valid_observations.txt";
			PUT v1;
		run;
		endsas;
	%end;

%let op = %sysfunc(open(out.outdata));
%let chartcheck = %sysfunc(attrn(&op,nobs));
%let ol = %sysfunc(close(&op));

	data transform;
		length Original_Variable $50.;
		format Original_Variable $50.;
		length Iteration_transformation $50.;
		format Iteration_transformation $50.;
		length Variable $50.;
		format Variable $50.;
		%do tempi = 1 %to %sysfunc(countw(&indep.," "));
		   Original_Variable="%scan(&indep.,&tempi.," ")";
		   Iteration_transformation="%scan(&independent_transformation.,&tempi.," ")";
		   Variable = "%scan(&independent_variables.,&tempi.," ")";
		   output;
		%end;
		  run;

	data transform;
		set transform;
		if substr(Variable,1,4) = "log_" and Iteration_transformation = "log" then Original_Variable = substr(Variable,5);
		run;

	data out.paraes;
		set out.paraes;
		length Variable $50.;
		format Variable $50.;
		%if &flagOnlyVif. = false %then %do;
		Original_Estimate = Estimate;
		Original_Probt = Probt;
		Original_StdErr = StdErr;
		Original_StandardizedEst = StandardizedEst;
		Original_tValue = tValue; 
		%end;
		Original_VarianceInflation = VarianceInflation;
		Heteroskedastic_P_Value = 1;
/*		if substr(Variable,1,4) = "log_" then Original_Variable = substr(Variable,5);*/
		run;

	proc sort data=transform;
		by Variable;
		run;

	proc sort data=out.paraes;
		by Variable;
		run;

	data out.paraes;
		merge out.paraes transform;
		by Variable;
		run;

	data out.paraes;
		set out.paraes;
		if Variable = "Intercept" then Original_Variable = "Intercept";
		run;

	data estimate;
		length Dependent $30. ;
		set out.paraes(drop = varianceinflation);
		Dependent = "&dependent_variable." ;
		%if &flagOnlyVif. = false %then %do;
		drop estimate stderr standardizedest probt tvalue;
		%end;
		run;

/*	proc sort data=transform;*/
/*		by Original_Variable;*/
/*		run;*/
/*	proc sort data=estimate;*/
/*		by Original_Variable;*/
/*		run;*/
/**/
/*	data estimate;*/
/*		set estimate;*/
/*		merge estimate transform;*/
/*		by Original_Variable;*/
/*		run;*/

/*	data estimate;*/
/*		set estimate;*/
/*		length Iteration_transformation $10.;*/
/*		if substr(Original_Variable,1,8) = "log3972_" then Iteration_transformation = "log";*/
/*		else if original_variable ^= "Intercept" then Iteration_transformation = "none";*/
/*		else*/
/*		Iteration_transformation = " ";*/
/*		run;*/
/*	*/
/*		data estimate;*/
/*		set estimate;*/
/*		if substr(Original_Variable,1,8) = "log_" then Original_Variable = substr(Original_Variable,9);*/
/*		run;*/

/*	libname outes xml "&output_path./estimates.xml";*/
/*	data outes.estimate;*/
/*		set estimate;*/
/*		run;*/

/*		%changeformat(outes.estimate);*/

/*	%changeformat(estimate);*/

	data estimate;
		set estimate;
		%if &flagOnlyVif. = false %then %do;
		if Original_Estimate = . or Original_Estimate = 0 then delete;
		%end;
		run;

	%if("&no_intercept_model." ^= "true") %then %do;
		data estimate_int;
			set estimate;
			if Variable = "Intercept";
			run;
		
	   	data estimate_oth;
			set estimate;
			if Variable ^= "Intercept";
			run;

		data estimate;
			set estimate_int estimate_oth;
			run;
	%end;	

	proc export data = estimate
        outfile="&output_path./estimates.csv" 
        dbms=csv replace; 
        run;
		

	%let op = %sysfunc(open(out.paraes));
	%let variables_used = %sysfunc(attrn(&op,nobs));
	%let ol = %sysfunc(close(&op));

	data _NULL_;
		set anova(firstobs = 1 obs = 1);
		call symput("pvaluemodel",ProbF);
		call symput ("fvalue",FValue);
	run;
	data _NULL_;
		set out.out_betas(firstobs = 1 obs = 1);
		Call symput("rsquare",_RSQ_);
		Call symput("aic",_AIC_);
	run;

	%if("&no_intercept_model." = "true") %then %do;
		ods output pearsoncorr = corr;
		proc corr data = out.outdata;
			var pred ;
			with &dependent_variable.;
		run;
		data R_sq(keep = Rsquared);
			set corr;
			Rsquared = pred*pred;
		run;
		data _NULL_;
			set R_sq(firstobs = 1 obs = 1);
			Call symput("rsquare", Rsquared);
		run;
		%put The new R square is &rsquare. ;
	%end;

	data _NULL_;
		set fitstatistics (firstobs = 2 obs = 2);
		call symput ("adjrsquare",cValue2);
		call symput ("depmean",cValue1);
	run;
	data _NULL_;
		set fitstatistics (firstobs = 1 obs = 1);
		call symput ("rmse",cValue1);
	run;
	proc sql noprint;
		select NObsUsed into :number_of_obs_used
		from nob
		where Label = "Number of Observations Used";
	quit;
	data _NULL_;
		set dwstatistic (firstobs = 1 obs = 1);
		call symput ("dwstat", cValue1);
	run;
	data _NULL_;
		set dwstatistic (firstobs = 3 obs = 3);
		call symput ("firstordercorr", cValue1);
	run;

	data _NULL_;
		call symput("heteroskedastic_pvalue", 1 );	
	run;
	%put The heteroskedastic pvalue is &heteroskedastic_pvalue. ; 

	data _NULL_;
		if ((&dwstat. < 1) or (&dwstat. > 3)) then do;
			call symput("dw", "DW");
		end;
	run;
	%put DW value is &dw. ;

	data out.outdata;
		set out.outdata;
		modres = abs(res);
		&dependent_variable.1 = abs(&dependent_variable.);
		if &dependent_variable.1=0 then mapeindi=0;
		else mapeindi = (modres/&dependent_variable.1);
	run;

	proc sql;
		create table mapevalue as 
		select avg(mapeindi)*100 as mape 
		from out.outdata;
	quit;
	proc sql noprint;
		select mape into :mape from mapevalue;
	quit;

	data statestimates;
	 	rsquare = &rsquare.;
		aic = &aic.;
		observations_used = &number_of_obs_used. ;
        variables_used = %eval(&variables_used. - 1);
		adjrsq= &adjrsquare.;
		dwstatistic = &dwstat.;
		firstordercorrelation = &firstordercorr.;
		dependentmean = &depmean.;
	 	rmserror = &rmse.;
		pvaluemodel = &pvaluemodel.;
		fvalue = &fvalue.;
        mape = &mape.;
		heteroskedastic_pvalue = &heteroskedastic_pvalue.;     
	run;
/*	libname outst xml "&output_path./stats.xml"; */
/*	data outst.stats;*/
/*		set statestimates;*/
/*		run;*/
/*		%changeformat(outst.stats);*/
/*	 %changeformat(statestimates);*/

	%if &flagOnlyVif. = false %then %do;
	 proc export data = statestimates
            outfile="&output_path./stats.csv" 
            dbms=csv replace; 
            run;
			%end;
	
	data chart;
		set out.outdata(keep = primary_key_1644 pred res leverage &dependent_variable.);
		actual = &dependent_variable.;
		run; 

	  data chart1;
	  set chart;
	  run;


	data outdata(keep=primary_key_1644 actual pred res leverage);
		set out.outdata;
		run;
	
	%if "&dependent_transformation."="log" %then %do;
		data chart2;
		set chart1;
		pred= exp(pred);
		actual = exp(actual);
		res = exp(res);
		leverage = exp(leverage);
		&dependent_variable. = actual;
		run;

/*	libname outch xml "&output_path./charts.xml";*/
/*	data outch.chart2;*/
/*		set chart2;*/
/*		run;*/
/*		%changeformat(outch.chart2);*/

/*	 %changeformat(chart2);*/
		%if &flagOnlyVif. = false %then %do;
		 proc export data = chart2
	        outfile="&output_path./normal_chart.csv" 
	        dbms=csv replace; 
	        run;
	
	%plots(chart2,0);
		%end;
/*	libname outch xml "&output_path./transformed_charts.xml";*/
/*	data outch.chart1;*/
/*		set chart1;*/
/*		run; */
/*		%changeformat(outch.chart1);*/
/*	*/
/*      %changeformat(chart1);*/
	%if &flagOnlyVif. = false %then %do;
	  proc export data = chart1
            outfile="&output_path./transformed_chart.csv" 
            dbms=csv replace; 
            run;
		
	 
		%plots(chart1,1);
		%end;
	%end;
	%else %do;
/*		libname outch xml "&output_path./charts.xml";*/
/*		data outch.chart1;*/
/*			set chart1;*/
/*			run; */
/*			%changeformat(outch.chart1);*/
/*		 %changeformat(chart1);*/
	%if &flagOnlyVif. = false %then %do;
		 proc export data = chart1
            outfile="&output_path./normal_chart.csv" 
            dbms=csv replace; 
            run;
			
		%plots(outdata,0);
		%end;
	%end;

	
	%let flag_correlation_matrix = false;

	%if "&flag_correlation_matrix." = "true" %then %do;

		ods output &corr_name.corr = corr;
		proc corr data = &dataset_name &corr_name.;
			var &independent_variables.;
			run;

/*		%changeformat(corr);*/
		proc export data = corr
			outfile = "&output_path/corr.csv"
			dbms = CSV replace;
			run;
	%end;

	%if "&var_summary." = "true" %then %do;
			%if "&sas_report." ="true" %then %do;
				ods html file="&sas_report_path./var_summary_&sas_report_name..xls" style=statdoc;
			%end;
		%let vars=;
			proc sql;
				select variable into: vars separated by " " from out.paraes 
				where variable <> "Intercept";
				quit;
			%put &vars.;
					proc means data=group.bygroupdata n mean std max min;
						var &vars.;
						output out=mn;
						%if "&whr." ^= "" %then %do;
							where &whr.;
						%end;
						run;
					data mn;
						set mn(drop=_type_ _freq_);
						run;
			 
					proc transpose data=mn out=mn;
						run;

					data mn;
						length _name_ $32.;
						set mn;
						rename _name_=Variable;
						rename col1=Freq;
						rename col2=Min;
						rename col3=Max;
						rename col4=Mean;
						rename col5=StdDev;
						run;

					proc append base=var_summary data=mn force;
						run;

					proc delete data=mn;
			    	run; quit;

/*				%changeformat(var_summary);*/
				proc export data = var_summary
						outfile = "&output_path/var_summary.csv"
						dbms = CSV replace;
						run;
			%if "&sas_report." = "true"  %then %do;
					ods html close;
			%end;
	%end;

%if "&flag_missing_perc." = "true" %then %do;
	proc means data=group.bygroupdata nmiss;
		output out = means;
		var &initial_dep. &initial_indep_var.;
		%if "&whr." ^= "" %then %do;
		where &whr.;
		%end;
		%if "&grp_no" ^= "0" %then %do;
			where GRP&grp_no._flag = "&grp_flag.";	
		%end;		
		run;
	%if "&flag_means." = "true" %then %do;
/*		%changeformat(means);*/
		proc export data = means
			outfile = "&output_path./means.csv"
			dbms = CSV replace;
			run;
	%end;
%end;

%if "&flag_missing_perc." = "true" %then  %do;
	proc transpose data=means out=means_trans (rename=_NAME_=variable rename=col1=nmiss drop= col2 col3 col4 col5);
		run;

	proc sql ;
		select nmiss into:freq from means_trans where variable='_FREQ_';
		quit;
		%put &freq.;

	data missing(drop=_Label_);
		set means_trans;
		nmiss=&freq.-nmiss;
		miss_per=nmiss*100/&freq.;
		if variable="_TYPE_" or variable="_FREQ_" then delete;
		run;

/*	%changeformat(missing);*/
	proc export data = missing
		outfile = "&output_path./appData_missing.csv"
		dbms = CSV replace;
		run;
%end;
%mend regression;
%regression;


%macro dependence();
%if %sysfunc(exist(DependenceEquations)) %then %do ;
	proc sort data=DependenceEquations;
        by LeftHandSide;
        run;

    data dependence_equations_final (keep=details variable comments severity);
        length lhs $500.;
        length rhs $500.;
        length details $500.;
        length severity $7.;
        length comments $100.;
		length variable $64. ;
        retain lhs;
        retain rhs;
        set DependenceEquations;
        by LeftHandSide;
        if (first.LeftHandSide) then do;
            rhs = "";
            if strip(term) ^="" then do;
            	if strip(term)="Intercept" then do;
	                if (coefficient ^= 0) then rhs = strip(coefficient);
	                	else rhs = "";
	            end;
                else do;
                    rhs = strip(coefficient) || " * " ||strip(Term);
                end;
            end;
            lhs = LeftHandSide;
        end; 
		else do;
			if strip(rhs) ^= "" then do;
                if (coefficient>0) then do; /* Put + sign for positive */
                    rhs = strip(rhs) ||" +";
                end;
            end;
			if strip(term) ^="" then do;
            	if strip(term)="Intercept" then do;
                    if (coefficient ^= 0) then do;
                    	rhs = strip(rhs) || strip(coefficient);
                    end;
                end;
                else do;
                	rhs = strip(rhs) ||strip(coefficient)|| " * " || strip(Term);
                end;
            end;
        end;
        if (last.LeftHandSide) then do;
            details = strip(lhs) || " = " || strip(rhs);
            variable = lefthandside;
            comments = "The variable is a linear combination of other variables";
            severity = "ERROR";
            output;
        end;
    run;

    libname outvld xml "&output_path./validation.xml";
    data outvld.validation;
        set dependence_equations_final;
   		run;
/*	%changeformat(outvld.validation);*/
	proc delete data=dependence_equations_final;
    	run; quit;
%end;

data out.outdata(keep=primary_key_1644 actual pred res leverage r_student cooks_dis dffits hat_diag &dependent_variable.);
	set out.outdata;
	hat_diag = leverage;
	run;
%mend dependence;	


%dependence();

	data _NULL_;
		v1= "Linear Regression - MANUAL_REGRESSION_COMPLETED";
		file "&output_path./MANUAL_REGRESSION_COMPLETED.txt";
		PUT v1;
	run;


