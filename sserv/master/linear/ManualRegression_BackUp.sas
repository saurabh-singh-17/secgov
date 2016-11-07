
*processbody;
goptions reset=all;
options mprint mlogic symbolgen mfile;



FILENAME MyFile "&output_path./No_valid_observations.txt";

DATA _NULL_;
 rc = FDELETE('MyFile');
RUN;

%sysexec del "&output_path./GENERATE_FILTER_FAILED.txt";
proc printto log="&output_path./ManualRegression_Log.log";
	run;
	quit;

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

%let independent_variable = ;
%do i=1 %to %sysfunc(countw(&independent_variables.));
	%let independent_var=%scan(&independent_variables.,&i.);
	%let independent_trans=%scan(&independent_transformation.,&i.);
		%if "&independent_trans."="none" %then %do;
	    %let independent_variable = &independent_variable. &independent_var.;
		%end;
		%else %do;
        %let independent_variable = &independent_variable. log_&independent_var.;
		data group.bygroupdata;
			set group.bygroupdata;
			log_&independent_var.= log(1 + &independent_var.);
			run;
		%end;
%end;
%put &independent_variable.;
%let independent_variables = &independent_variable.;
%put &independent_variables.;

%if "&dependent_transformation."="log" %then %do;
	data group.bygroupdata;
		set group.bygroupdata;
		log_&dependent_variable.= log(1 + &dependent_variable.);
		run;

	%let dependent_variable =log_&dependent_variable.;
%end;
%put &dep_var.;
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
				plot pred*actual/anno=anno vaxis=axis2 haxis=axis1;
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
			plot res*pred/vaxis=axis2 haxis=axis1;
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
			plot res*leverage/vaxis=axis2 haxis=axis1;
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
			plot (Actual Pred)*primary_key_1644/overlay vaxis=axis2 haxis=axis1;
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

%if "&flag_missing_perc." = "true" %then %do;
	%if "&flag_html." = "true" %then %do;
	ods html path="&html_path." file="missing_&html_file..xls" style=statdoc;
	%end;

	proc means data=group.bygroupdata nmiss;
		output out = means;
		var &dependent_variable. &independent_variables.;
		%if "&whr." ^= "" %then %do;
		where &whr.;
		%end;
		%if "&grp_no" ^= "0" %then %do;
			where GRP&grp_no._flag = "&grp_flag.";	
		%end;		
		run;
	%if "&flag_html." = "true" %then %do;
	ods html close;
	%end;

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

	data missing;
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

ods output DependenceEquations = dependenceequations;
ods output ParameterEstimates=out.paraes;
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
			 	model &dependent_variable. = &independent_variables./vif stb dw aic acov &regression_options.
				%if %index("&regression_options", "selection=stepwise") %then %do; sls=&sls. sle=&sle. %end;
				%if %index("&regression_options", "selection=forward") %then %do; sls=&sls. sle=&sle. %end;
				%if %index("&regression_options", "selection=backward") %then %do; sls=&sls. sle=&sle. %end;
				%if %index("&regression_options", "selection=rsquare") %then %do; sls=&sls. sle=&sle. %end;
			  	;
			  	output out=out.outdata p=pred r=res h=leverage;
			%if "&whr." ^= "" %then %do;
				where &whr.;
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
	
	data out.paraes;
		set out.paraes;
		Original_Variable = Variable;
		Original_Estimate = Estimate;
		Original_Probt = Probt;
		Original_StdErr = StdErr;
		Original_StandardizedEst = StandardizedEst;
		Original_VarianceInflation = VarianceInflation;
		Original_tValue = tValue; 
		Heteroskedastic_P_Value = 1;
		run;

	data estimate;
		length Dependent $30. ;
		set out.paraes(drop = variable estimate stderr varianceinflation standardizedest probt tvalue);
		Dependent = "&dependent_variable." ;
		run;

	data estimate;
		set estimate;
		length Iteration_transformation $10.;
		if substr(Original_Variable,1,4) = "log_" then Iteration_transformation = "log";
		else if original_variable ^= "Intercept" then Iteration_transformation = "none";
		else
		Iteration_transformation = " ";
		run;
	
		data estimate;
		set estimate;
		if substr(Original_Variable,1,4) = "log_" then Original_Variable = substr(Original_Variable,5);
		run;
	libname outes xml "&output_path./estimates.xml";
	data outes.estimate;
		set estimate;
		run;
/*		%changeformat(outes.estimate);*/

/*	%changeformat(estimate);*/
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
        variables_used = &variables_used. ;
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
	libname outst xml "&output_path./stats.xml"; 
	data outst.stats;
		set statestimates;
		run;
/*		%changeformat(outst.stats);*/
/*	 %changeformat(statestimates);*/
	 proc export data = statestimates
            outfile="&output_path./stats.csv" 
            dbms=csv replace; 
            run;
	
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

	libname outch xml "&output_path./charts.xml";
	data outch.chart2;
		set chart2;
		run;
/*		%changeformat(outch.chart2);*/

/*	 %changeformat(chart2);*/
	 proc export data = chart2
        outfile="&output_path./normal_chart.csv" 
        dbms=csv replace; 
        run;
	%plots(chart2,0);
	libname outch xml "&output_path./transformed_charts.xml";
	data outch.chart1;
		set chart1;
		run; 
/*		%changeformat(outch.chart1);*/
/*	*/
/*      %changeformat(chart1);*/
	  proc export data = chart1
            outfile="&output_path./transformed_chart.csv" 
            dbms=csv replace; 
            run;
	 
	%plots(chart1,1);
	%end;
	%else %do;
		libname outch xml "&output_path./charts.xml";
		data outch.chart1;
			set chart1;
			run; 
/*			%changeformat(outch.chart1);*/
/*		 %changeformat(chart1);*/
		 proc export data = chart1
            outfile="&output_path./normal_chart.csv" 
            dbms=csv replace; 
            run;
		%plots(outdata,0);
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

    %sysexec del "&output_path./validation.xml";
    libname outvld xml "&output_path./validation.xml";
    data outvld.validation;
        set dependence_equations_final;
   		run;
/*	%changeformat(outvld.validation);*/
	proc delete data=dependence_equations_final;
    	run; quit;
%end;

%mend dependence;	
%dependence();


	data _NULL_;
		v1= "Linear Regression - MANUAL_REGRESSION_COMPLETED";
		file "&output_path./MANUAL_REGRESSION_COMPLETED.txt";
		PUT v1;
	run;


