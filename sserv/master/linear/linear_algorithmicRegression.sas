/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &folder_path./MANUAL_REGRESSION_COMPLETED.txt &output_path./&model_iteration./ALGORITHMIC_REGRESSION_COMPLETED.txt;

/*# VERSION : 1.2.1 #*/

options mprint mlogic symbolgen mfile ;

/*proc printto log="&output_path./&model_iteration./AlgorithmicRegression_Log.log";*/
/*run;*/
/*quit;*/

proc datasets;
delete jobs;
run;
/*proc printto print="&output_path./&model_iteration./AlgorithmicRegression_Output.out";*/
      

libname in "&input_path.";
libname out "&output_path.";
libname group  "&group_path.";
%let dataset_name=in.dataworking;
data in.bygroupdata;
      set &dataset_name.;
      run;
data _null_;
	call symputx("sas_report_name", compress(tranwrd("&sas_report_name" ,"/" ,"_" )));
	run;

%MACRO plots_lin_algo(dataset, flag);
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
				"&folder_path./PredictedvsActual.png";
			%end;
			%else
			%do;
				"&folder_path./PredictedvsActual_Transformed.png";
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
				"&folder_path./ResidualvsPredicted.png";
			%end;
			%else
			%do;
			"&folder_path./ResidualvsPredicted_Transformed.png";
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
			"&folder_path./ResidualvsLeverage.png";
			%end;
			%else
			%do;
			"&folder_path./ResidualvsLeverage_Transformed.png";
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
			"&folder_path./ActualvsPredicted.png";
			%end;
			%else
			%do;
			"&folder_path./ActualvsPredicted_Transformed.png";
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

%MACRO initial_setUp;
/*CHECK IF BYGORUPDATA EXISTS AND CREATE, IF REQUIRED*/
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


/*UPDATE BYROUPDATA*/
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
				log_&independent_var.= log(&independent_var. + 1);
				run;
		%end;
%end;
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
%put &dep_var.;
%mend transformations;
%transformations;

%put &independent_variables.;
%put &dependent_variable.;

/*CONDITIONING THE LIST OF INDEPENDENT VARIABLES*/
      data _null_;
            call symput ("independent_variables", compbl("&independent_variables."));
            %if "&important_variables." ^= "" %then %do;
                  call symput ("important_variables", compbl("&important_variables."));
            %end;
            run;
      %put &independent_variables;
      data _null_;
            call symput ("indep_list", cat("'", tranwrd("&independent_variables.", " ", "', '"), "'"));
            %if "&important_variables." ^= "" %then %do;
                  call symput ("imp_list", cat("'", tranwrd("&important_variables.", " ", "', '"), "'"));
            %end;
            %else %do;
                  call symput ("imp_list", "'XXX_dummyVar_XXX'");
            %end;
            run;
      %put &indep_list.;

/*================================================================================================================*/
/*PREPARE THE WHERE STATEMENT*/
%let whr =;

/*VALIDATION VAR CONDITION*/
      %if "&validation_var" ^= "" %then %do;
            data _null_;
                  call symput("whr", "&validation_var. = 1");
                  run;
            %put &whr;
      %end;

/*OUTLIER VARIABLE CONDITION*/
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

/*DYNAMIC FILTER*/
      %if "&flag_filter." = "true" %then %do;
		%let dataset_name=out.temporary;

		 /*call SAS code for dynamic filtering*/
		%include %unquote(%str(%'&filterCode_path./dynamicFiltering.sas%')); 
      %end;



%MEND initial_setUp;

%MACRO regression5;
/*GET NAMES FOR THE HTML OUTPUTS*/
%if "&flag_html." = "true" %then %do;
      %if "&grp_no." = "0" %then %do;
            data _null_;
                  call symput("html_file", cats("&dependent_variable.", "-", "iteration=&iter."));
                  run; 
      %end;
     %else %do;
		libname keys xml "&input_path./&grp_no./byvar_keys.xml";
		data key_names;
			set keys.key_names;
			run;

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

/*-----------------------------------------------------------------------------------------------------------------*/
/*MEANS and MISSING*/
/*	%if "&flag_html." = "true" %then %do;*/
/*		ods html path="&html_path." file="missing_&html_file..xls" style=statdoc;*/
/*	%end;*/
      proc means data=group.bygroupdata nmiss;
            output out = means;
            var &dependent_variable. &independent_vars.;
            %if "&whr." ^= "" %then %do;
            where &whr.;
            %end;
            run;
/*      %if "&flag_html." = "true" %then %do;*/
/*      ods html close;*/
/*      %end;*/
/*CREATE CSV FOR INFORMATION ABOUT MISSING DATA*/
      proc transpose data=means out=means_trans (rename=_NAME_=variable rename=col1=nmiss drop= col2 col3 col4 col5);
            run;

      proc sql ;
            select nmiss into:freq from means_trans where variable='_FREQ_';
            quit;
            %put &freq.;

	data missing;
		set means_trans;
		nmiss=&freq.-nmiss;
		miss_per=nmiss/&freq.;
		if variable="_TYPE_" or variable="_FREQ_" then delete;
		run;

      proc export data = missing
            outfile = "&folder_path./appData_missing.csv"
            dbms = CSV replace;
            run;
/*########################################################################################################################################################*/
/*PROC REG*/
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
	ods html path= "&sas_report_path." file="sas_&sas_report_name..xls" style=statdoc;
%end;
      proc reg data = group.bygroupdata outest = out.out_betas tableout edf ;
                        model &dependent_variable. = &independent_vars./vif stb dw aic acov &regression_options.
                        %if %index("&regression_options", "selection=stepwise") %then %do; sls=&sls. sle=&sle. %end;;
                        output out=out.outdata p=pred r=res h=leverage rstudent = r_student cookd = cooks_dis dffits = dffits;
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
/*#################################################################################################################*/
/*NOBS FOR THE ITERATION*/
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
		%do tempi = 1 %to %sysfunc(countw(&independent_vars.," "));
		   Original_Variable="%scan(&independent_vars.,&tempi.," ")";
		   Iteration_transformation="%scan(&independent_transformation.,&tempi.," ")";
		   Variable = "%scan(&independent_vars.,&tempi.," ")";
		   output;
		%end;
		  run;

	data transform;
		set transform;
		if substr(Variable,1,4) = "log_" and Iteration_transformation = "log" then Original_Variable = substr(Variable,5);
		run;
 	
/*VARIABLE STATISTICS OUTPUT*/
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

	proc sql;
	select Original_Variable into:independent_vars separated by " " from transform where  Original_Variable <> "Intercept";
	quit;
	proc sql;
	select Iteration_transformation into:independent_transformation separated by " " from transform where  Original_Variable <> "Intercept";
	quit;

     data estimate;
            length Dependent $30. ;
            set out.paraes(drop = variable estimate stderr varianceinflation standardizedest probt tvalue);
            Dependent = "&dependent_variable." ;
            run;

	data estimate;
		set estimate;
		if Original_Estimate = . or Original_Estimate = 0 then delete;
		run;

/*	data estimate;*/
/*		set estimate;*/
/*		length Iteration_transformation $10.;*/
/*		if substr(Original_Variable,1,4) = "log_" then Iteration_transformation = "log";*/
/*		else if original_variable ^= "Intercept" then Iteration_transformation = "none";*/
/*		else*/
/*		Iteration_transformation = " ";*/
/*		run;*/
/*	*/
/*		data estimate;*/
/*		set estimate;*/
/*		if substr(Original_Variable,1,4) = "log_" then Original_Variable = substr(Original_Variable,5);*/
/*		run;*/

	proc export data = estimate
        outfile="&folder_path./estimates.csv" 
        dbms=csv replace; 
        run;

/*	 libname outes xml "&folder_path./estimates.xml";*/
/*      data outes.estimates;*/
/*            length Dependent $30. ;*/
/*            set out.paraes(drop = variable estimate stderr varianceinflation standardizedest probt tvalue);*/
/*            Dependent = "&dependent_variable." ;*/
/*            run;*/
/*=================================================================================================================*/
%global rsquare;
/* MODEL STATISTICS */
%global rsquare;

/*NO. OF VARIABLES USED IN THE ITERATION*/
      %let op = %sysfunc(open(out.paraes));
      %let variables_used = %sysfunc(attrn(&op,nobs));
      %let ol = %sysfunc(close(&op));

/*GET PVALUEMODEL, F-VALUE, R-SQUARE & AIC*/
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

/*R-SQUARED CORRECTION FOR NO INTERCEPT MODEL*/
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
            %global rsquare;
            data _NULL_;
                  set R_sq(firstobs = 1 obs = 1);
                  Call symput("rsquare", Rsquared);
            run;
            %put The new R square is &rsquare. ;
      %end;

/*GET ADJ-RSQUARE, DEPMEAN, RMSE, NOBS and DWSTAT*/
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

/*AUTOCORRELATION CHECK*/
      data _NULL_;
            if ((&dwstat. < 1) or (&dwstat. > 3)) then do;
                  call symput("dw", "DW");
            end;
      run;
      %put DW value is &dw. ;

/*MAPE*/
      data out.outdata;
            set out.outdata;
            modres = abs(res);
            &dependent_variable.1 = abs(&dependent_variable.);
            mapeindi = (modres/&dependent_variable.1);
      run;

      proc sql;
            create table mapevalue as 
            select avg(mapeindi)*100 as mape 
            from out.outdata;
      quit;
      proc sql noprint;
            select mape into :mape from mapevalue;
      quit;
      
/*CREATE DATASET FOR MODEL STATS OUTPUT*/
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

    proc export data = statestimates
            outfile="&folder_path./stats.csv" 
            dbms=csv replace; 
            run;

/*	 libname outst xml "&folder_path./stats.xml"; */
/*      data outst.stats;*/
/*            set statestimates;*/
/*            run;*/

/*-----------------------------------------------------------------------------------------------------------------*/
/*DIAGNOSTIC CHARTS*/
       data chart;
		set out.outdata(keep = pred res leverage &dependent_variable.);
		actual = &dependent_variable.;
		run; 

	  data chart1;
	  set chart;
	  run;


	data outdata(keep=primary_key_1644 actual pred res leverage);
		set out.outdata;
		run;

	data out.outdata(keep=primary_key_1644 actual pred res leverage r_student cooks_dis dffits hat_diag &dependent_variable.);
		set out.outdata;
		hat_diag = leverage;
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
		%plots_lin_algo(outdata,0);
	 proc export data = chart2
        outfile="&folder_path./normal_chart.csv" 
        dbms=csv replace; 
        run;
      proc export data = chart1
            outfile="&folder_path./transformed_chart.csv" 
            dbms=csv replace; 
            run;
			%plots_lin_algo(chart2,1);
	%end;
	%else %do;
		 proc export data = chart1
            outfile="&folder_path./normal_chart.csv" 
            dbms=csv replace; 
            run;
			%plots_lin_algo(outdata,0);
	%end;



/*#################################################################################################################*/
/* CORRELATION MATRIX */

      /*false initiation for correlation matrix flag*/
      %let flag_correlation_matrix = false;

      /*diff. types of correlation matrix*/
      %if "&flag_correlation_matrix." = "true" %then %do;

            ods output &corr_name.corr = corr;
            proc corr data = &dataset_name. &corr_name.;
                  var &independent_vars.;
                  run;

            proc export data = corr
                  outfile = "&folder_path/corr.csv"
                  dbms = CSV replace;
                  run;
      %end;

/*==========================================================================================================*/
/* JOBS */
      data job&iter.;
            length VAR_REMOVED $32.;
/*            START_ITERATION = &start_iteration.;*/
            MODEL_ITERATION = &iter.;
            VARIABLES_USED = &variables_used.;
            OBSERVATIONS_USED = &number_of_obs_used.;
            RSQUARE = &rsquare.;
            MAPE = &mape.;
            ADJRSQ = &adjrsquare.;             
            AIC = &aic.;   
            %if %sysevalf(&model_iteration. = &iter.) %then %do;
                  VAR_REMOVED = "Nil";
            %end; 
            %else %do;
                  VAR_REMOVED = "&&rem_var%eval(&iter.-1)";
            %end; 
            run;

      proc append base = jobs data = job&iter. force;
            run; 

	/*VARIABLE SUMMARY*/
/* get the list of variables in the model*/

	%if "&var_summary." = "true" %then %do;
			%if "&sas_report." ="true" %then %do;
				ods html file="&sas_report_path./var_summary_&sas_report_name..xls" style=statdoc;
			%end;
		
			proc sql;
				select variable into: vars separated by " " from out.paraes 
				where variable <> "Intercept";
				quit;
			%put &vars.;
			/* loop to get all the variables */
					proc means data=group.bygroupdata n mean std max min;
						var &vars.;
						output out=mn;
						run;
			/* formatting */
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

			/* export the dataset*/
				proc export data = var_summary
						outfile = "&folder_path./var_summary.csv"
						dbms = CSV replace;
						run;

				proc datasets;
					delete var_summary;
					run;

			%if "&sas_report." = "true"  %then %do;
					ods html close;
			%end;
	%end;
            
%MEND regression5;

%macro transformations_new;

%let independent_variable=;
%do i=1 %to %sysfunc(countw(&independent_vars.));
	%let indep_var=%scan(&independent_vars.,&i.);
	%let independent_trans=%scan(&independent_transformation.,&i.);
		%if "&independent_trans."="none" %then %do;
		    %let independent_variable = &independent_variable. &indep_var.;
			%end;
		%else %do;
	        %let independent_variable = &independent_variable. log_&indep_var.;
			data group.bygroupdata;
				set group.bygroupdata;
				log_&indep_var.= log(&indep_var. + 1);
				run;
		%end;
%end;
%put &independent_variable.;
%let independent_vars = &independent_variable.;
%put &independent_variables.;

%mend transformations_new;


%MACRO algorithmicReg;

%global whr;
%let initial_indep_var=&independent_variables.;
%let initial_trans_var=&independent_transformation.;
%initial_setUp;

/*initiate the flag to run algo*/
%let signal_algo = green;

%if "&algorithm." ^= "pvalue" %then %do;
      %let signal_vif = green;
      %let signal_pvalue = red;
%end;
%else %if "&algorithm." = "pvalue" %then %do;
      %let signal_vif = red;
      %let signal_pvalue = green;
%end;
%if "&algorithm." = "pvalue_vif" %then %do;
      %let signal_vif = red;
      %let signal_pvalue = green;
%end;
/*create list of independent variables*/
%global independent_vars;
data _null_;
      call symput("independent_vars",compbl("&independent_variables."));
      run;
%put Independent Varaibles : &independent_vars;


/*loop through successive iterations*/
%let iter = %eval(&model_iteration.);
%do %until ("&signal_algo." = "red");

      /*create library & output path for the iteration*/
      %let folder_path = &output_path./&iter.;
      
	  /*create output folder for the iteration*/
	  data _null_;
      newDir = dcreate("&iter.","&output_path.");
	  run;

      libname out "&folder_path.";
	 	%if &iter. ne &&model_iteration. %then %do;
		%transformations_new;
		%end;
     	%regression5;

      /*check if the criteria for minimum number of variables is satisfied*/
      %if "&varnum_min." ^= "" %then %do;
            %if %sysevalf(%sysfunc(countw(&independent_vars.)) <= %eval(&varnum_min.)) %then %do;
                  %let signal_vif = red;
                  %let signal_pvalue = red;
                  %let signal_algo = red;
            %end;
      %end;
      %else %do;
            %if %sysevalf(%sysfunc(countw(&independent_vars.)) <= 1) %then %do;
                  %let signal_vif = red;
                  %let signal_pvalue = red;
                  %let signal_algo = red;
            %end;
      %end;

      /*check if the criteria for rsq_drop is satisfied*/
      %if "&rsq_maxDrop." ^= ""  and %sysevalf(&&iter. > &model_iteration.) %then %do;
            %if %sysevalf(%sysevalf(&prev_rsq. - &rsquare.) > %sysevalf(&rsq_maxDrop.)) %then %do;
                  %let signal_vif = red;
                  %let signal_pvalue = red;
                  %let signal_algo = red;
            %end;
      %end;

      /*assigning the value of rsq for current iteration for check during next iteration*/
      %let prev_rsq = %sysevalf(&rsquare.);

      /*elimination based on VIF*/
      %if ("&algorithm." = "vif_pvalue" or "&algorithm." = "vif") and ("&signal_vif" = "green") %then %do;
            proc sql;
                  select max(VarianceInflation) into :max_vif&iter. from out.paraes where strip(Original_Variable) not in ('intercept','Intercept', &imp_list.);
                  quit;
            %put max VIF for Iteration&iter. : &&max_vif&iter.;

            %if %sysevalf(&&max_vif&iter. > &vif_cutoff.) %then %do;
                  proc sql;
                        select Original_Variable into :rem_var&iter. from out.paraes where strip(Variable) not in ('intercept','Intercept', &imp_list.) having VarianceInflation = max(VarianceInflation);
                        quit;
                  %put variable to be removed from Iteration&iter. : &&rem_var&iter.;

            data _null_;
                  call symput("independent_vars", compbl(tranwrd(compbl(tranwrd(cats(",", tranwrd("&independent_vars", " ", ","),","), cats(",",strip("&&rem_var&iter."),","), " ")), ",", " ")));
                  run;
                  %put &independent_vars;
            %end;
            %else %do;
                  %if "&algorithm." = "vif_pvalue" %then %do;
                        %let signal_vif = red;
                        %let signal_pvalue = green;
                  %end;
                  %else %if "&algorithm." = "vif" %then %do;
                        %let signal_vif = red;
                        %let signal_pvalue = red;
                        %let signal_algo = red;
                  %end;
            %end;
      %end;
		
      /*elimination based on VIF-pvalue*/
      %if ("&algorithm." = "vif-pvalue_pvalue" or "&algorithm." = "vif-pvalue") and ("&signal_vif" = "green") %then %do;
            proc sql;
                  select max(VarianceInflation) into :max_vif&iter. from out.paraes where (strip(Original_Variable) not in ('intercept','Intercept', &imp_list.) and Probt>%sysevalf(&pvalue_cutoff.));
                  quit;
            %put max VIF for Iteration&iter. : &&max_vif&iter.;

            %if %sysevalf(&&max_vif&iter. > &vif_cutoff.) %then %do;
                  proc sql;
                        select Original_Variable into :rem_var&iter. from out.paraes where (strip(Original_Variable) not in ('intercept','Intercept', &imp_list.) and Probt>%sysevalf(&pvalue_cutoff.)) 
                              having VarianceInflation = max(VarianceInflation);
                        quit;
                  %put variable to be removed from Iteration&iter. : &&rem_var&iter.;

                  data _null_;
                        call symput("independent_vars", compbl(tranwrd(compbl(tranwrd(cats(",", tranwrd("&independent_vars", " ", ","),","), cats(",",strip("&&rem_var&iter."),","), " ")), ",", " ")));
                        run;
                  %put &independent_vars;
            %end;
            %else %do;
                  %if "&algorithm." = "vif-pvalue_pvalue" %then %do;
                        %let signal_vif = red;
                        %let signal_pvalue = green;
                  %end;
                  %else %if "&algorithm." = "vif-pvalue" %then %do;
                        %let signal_vif = red;
                        %let signal_pvalue = red;
                        %let signal_algo = red;
                  %end;
            %end;
      %end;

      /*elimination based on Pvalue*/
      %if "&signal_pvalue" = "green" %then %do;
            proc sql;
                  select max(Probt) into :max_pvalue&iter. from out.paraes where strip(Original_Variable) not in ('intercept','Intercept', &imp_list.);
                  quit;
            %put max Pvalue for Iteration&iter. : &&max_pvalue&iter.;

            %if %sysevalf(&&max_pvalue&iter. > &pvalue_cutoff.) %then %do;
                  proc sql;
                        select Original_Variable into :rem_var&iter. from out.paraes where strip(Original_Variable) not in ('intercept','Intercept', &imp_list.) having Probt = max(Probt);
                        quit;
                  %put variable to be removed from Iteration&iter. : &&rem_var&iter.;

            data _null_;
                  call symput("independent_vars", compbl(tranwrd(compbl(tranwrd(cats(",", tranwrd("&independent_vars", " ", ","),","), cats(",", strip("&&rem_var&iter."),","), " ")), ",", " ")));
                  run;
                  %put &independent_vars;
            %end;
            %else %do;
                  %let signal_pvalue = red;
                  %let signal_algo = red;
				  %if "&algorithm." = "pvalue_vif" %then %do;
						%let signal_algo = green;
						%let signal_vif = green;
				  %end;
            %end;
		%end;
		

/*changes done here*/

	  %if ("&algorithm." = "pvalue_vif") and ("&signal_vif" = "green") %then %do;
            proc sql;
                  select max(VarianceInflation) into :max_vif&iter. from out.paraes where strip(Original_Variable) not in ('intercept','Intercept', &imp_list.);
                  quit;
            %put max VIF for Iteration&iter. : &&max_vif&iter.;

            %if %sysevalf(&&max_vif&iter. > &vif_cutoff.) %then %do;
                  proc sql;
                        select Original_Variable into :rem_var&iter. from out.paraes where strip(Variable) not in ('intercept','Intercept', &imp_list.) having VarianceInflation = max(VarianceInflation);
                        quit;
                  %put variable to be removed from Iteration&iter. : &&rem_var&iter.;

            data _null_;
                  call symput("independent_vars", compbl(tranwrd(compbl(tranwrd(cats(",", tranwrd("&independent_vars", " ", ","),","), cats(",",strip("&&rem_var&iter."),","), " ")), ",", " ")));
                  run;
                  %put &independent_vars;
            %end;
            %else %do;
                  %let signal_algo = red;
				  %let signal_vif = red;
            %end;
      %end;
	
/*changes end here*/
 
	  	%let ini_indep_var=;
		%let ini_trans_var=;
		%do ab =1 %to %sysfunc(countw("&independent_vars."," "));
			%let temp_indep_var=%scan("&independent_vars.",&ab.," ");
			%do bc =1 %to %sysfunc(countw("&initial_indep_var."," "));
				%let temp_var=%scan("&initial_indep_var.",&bc.," ");
				%let temp_trans=%scan("&initial_trans_var.",&bc.," ");
				%if &temp_var. = &temp_indep_var. %then %do;
					%let ini_indep_var=&ini_indep_var. &temp_indep_var.; 
					%let ini_trans_var=&ini_trans_var. &temp_trans;
				%end;
			%end;
		%end;	
		%let independent_vars=&ini_indep_var.;
		%let independent_transformation=&ini_trans_var.;
      /* Flex uses this file to test if the iteration is done */
      data _NULL_;
            v1= "Algorithmic Regression - ITERATION_COMPLETED";
            file "&folder_path./MANUAL_REGRESSION_COMPLETED.txt";
            PUT v1;
      run;
		
      %let iter = %eval(&iter.+1);
%end;

proc export data=jobs outfile="&output_path./&model_iteration./jobs.csv" dbms=csv replace;
run;
quit;

/*libname outjb xml "&output_path./&model_iteration./jobs.xml";*/
/*data outjb.job;*/
/*	set jobs;*/
/*	run;*/

%MEND algorithmicReg;
%algorithmicReg;



/* Flex uses this file to test if the code has finished running */
data _NULL_;
      v1= "Linear Regression - ALGORITHMIC_REGRESSION_COMPLETED";
      file "&output_path./&model_iteration./ALGORITHMIC_REGRESSION_COMPLETED.txt";
      PUT v1;
	run;