/*Successfully converted to SAS Server Format*/
*processbody;




%let completedTXTPath =  &output_path./LINEAR_REGRESSION_VALIDATION_COMPLETED.txt;

%let n=4;
%let hetero= ;
%let dw=;
%let chartpopulate = true;
%let dateandtime = ;
 %let statsfilename = &output_path./stats.csv;
  %let statsfilename1 = &output_path./stats.xml;

 %let chartfilepath = &output_path.;
 %let estimatesfilename = &output_path./estimates.csv;
 %let estimatesfilename1 = &output_path./estimates.xml;

 %let estimatesfilename2 = &output_path./estimates_validation.csv;
 %let estimatesfilename3 = &output_path./estimates_validation.xml;

 %let validationoutputfile = &output_path./validation.xml;
 %let jobsfilename =  &output_path./jobs.csv;
%let validationrankfilename = &output_path./validation_rank.csv;
 %let all_independent_variables=&independent_variables. &all_important_variables.;
%put &all_independent_variables;



options mprint mlogic symbolgen mfile ;


proc printto log="&output_path./ManualRegression_Log.log";
run;
quit;
/*proc printto print="&output_path./ManualRegression_Output.out";*/
libname base "&base_path.";
libname in  "&input_path.";
libname group "&group_path.";
libname out "&output_path.";


	data gettingtime;
		 format final EURDFDT.; 
		 dd = "&sysdate."d;
		 tt = "&systime."t;
		 hourpart = hour(tt);
		 minpart = minute(tt);
		 final = dhms(dd,hourpart,minpart,0);
		 drop dd tt hourpart minpart;
		 call symput('dateandtime',put(final,eurdfdt.));
	run;
	%put &dateandtime.;

%let initial_indep_var=&independent_variables.;
%let initial_dep=&dependent_variable.;
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
		%end;
%end;
%put &independent_variable.;
%let independent_variables = &independent_variable.;
%put &independent_variables.;

%if "&dependent_transformation."="log" %then %do;
	%let dependent_variable =log_&dependent_variable.;
%end;
%put &dependent_variable.;
%mend transformations;
%transformations;

%put &independent_variables.;
%put &dependent_variable.;

%macro R_square2;
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
%mend R_square2;


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
			plot (actual pred)*primary_key_1644/overlay vaxis=axis1 haxis=axis2;
			run;

			ods listing close;
			ods graphics off;

			/*---------------------------------------------------------*/
		%end;
%mend;
;


%macro calling_Rsquare;
		%if("&no_intercept_model." = "true") %then %R_square2;
%mend calling_Rsquare;

%put Modelnumber is &modelnumber. ;

%let all_independent_variables=&independent_variables.;
%put &all_independent_variables;

%macro regression3;
	/*bygroupdata updation*/
		%if "&flag_bygrp_update." = "true" %then %do;
			proc sort data = base.dataworking;
				by primary_key_1644;
				run;

			proc sort data = group.bygroupdata out = group.bygroupdata;
				by primary_key_1644;
				run;

			data group.bygroupdata;
				merge group.bygroupdata(in=a) base.dataworking(in=b);
				by primary_key_1644;
				if a;
				run;
		%end;	
	%let whr =;
	%if "&validation_var" ^= "" %then %do;
		data _null_;
			call symput("whr", "&validation_var. = 0");
			run;
		%put &whr;
	%end;

	/*concatenate the outlier variable condition*/
	%if "&outlier_var" ^= "" %then %do;
		%let i = 1;
		%do %until (not %length(%scan(&outlier_var, &i)));
			%if "&i." = "1" %then %do;
				data _null_;
					call symput("whr", "%scan(&outlier_var, &i) = 0 ");
					run;
			%end;
			%else %do;
				data _null_;
					call symput("whr", cats("&whr.", " ", " and %scan(&outlier_var, &i) = 0 "));
					run;
			%end;

			%put &whr;
			%let i = %eval(&i.+1);
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

%global variables_used;
ods output DependenceEquations = dependenceequations;
ods output ParameterEstimates=paraes;
ods output NObs = nob;
ods output ANOVA = anova;
ods output FitStatistics = fitstatistics;
ods output ACovEst = acovest;
ods output DWStatistic = dwstatistic;

	proc reg data = group.bygroupdata outest = out.out_temp tableout edf ;
			 	model &dependent_variable.= &all_independent_variables./vif stb dw aic acov &regression_options.;
			  	output out=out.outdata p=pred r=res h=leverage;
		where &validation_var. = 0;
	run;
	quit;

	/*Sending number of variables in reg for each model*/
	%let op = %sysfunc(open(out.outdata));
	%let chartcheck = %sysfunc(attrn(&op,nobs));
	%let ol = %sysfunc(close(&op));

%put &chartcheck. ;

data transform;
		length Original_Variable $50.;
		format Original_Variable $50.;
		length Iteration_transformation $50.;
		format Iteration_transformation $50.;
		length Variable $50.;
		format Variable $50.;
		%do tempi = 1 %to %sysfunc(countw(&initial_indep_var.," "));
		   Original_Variable="%scan(&initial_indep_var.,&tempi.," ")";
		   Iteration_transformation="%scan(&independent_transformation.,&tempi.," ")";
		   Variable = "%scan(&independent_variables.,&tempi.," ")";
		   output;
		%end;
		  run;

	data transform;
		set transform;
		if substr(Variable,1,4) = "log_" and Iteration_transformation = "log" then Original_Variable = substr(Variable,5);
		run;

	/*Creating the diff variables for autoreg and hetero*/
		data paraes;
			set paraes;
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

	proc sort data=paraes;
		by Variable;
		run;

	data out.paraes;
		merge paraes transform;
		by Variable;
		run;

	data out.paraes;
		set out.paraes;
		if Variable = "Intercept" then Original_Variable = "Intercept";
		run;

	data paraes;
		set out.paraes;
		run;

/*Sending number of variables in reg for each model*/
	%let op = %sysfunc(open(paraes));
	%let variables_used = %sysfunc(attrn(&op,nobs));
	%let ol = %sysfunc(close(&op));



	data _NULL_;
		set anova(firstobs = 1 obs = 1);
		call symput("pvaluemodel",ProbF);
		call symput ("fvalue",FValue);
	run;
		
	data _NULL_;
		set out.out_temp(firstobs = 1 obs = 1);
		Call symput("rsquare",_RSQ_);
		Call symput("aic",_AIC_);
	run;

/*R SQUARED CORRECTION FOR NO INTERCEPT MODEL*/

%calling_Rsquare;
%global number_of_obs_used;
/*R SQUARED CHG ENDS*/

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
		%let number_of_obs_used = &number_of_obs_used;

		data _NULL_;
			set dwstatistic (firstobs = 1 obs = 1);
			call symput ("dwstat", cValue1);
		run;

/*Autocorrelation check*/
		data _NULL_;
			if ((&dwstat. < 1) or (&dwstat. > 3)) then do;
				call symput("dw", "DW");
			end;
		run;
%put DW value is &dw. ;

/*Autocorrelation check ends here*/
		
		data _NULL_;
			set dwstatistic (firstobs = 3 obs = 3);
			call symput ("firstordercorr", cValue1);
		run;

		data _NULL_;
			call symput("heteroskedastic_pvalue", 1 );	
		run;
	%put The heteroskedastic pvalue is &heteroskedastic_pvalue. ; 


		    
		data out.outdata;
			set out.outdata;
			modres = abs(res);
			actual1 = abs(&dependent_variable.);
			mapeindi = (modres/actual1);
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
            variables_used = %eval(&variables_used. - 1) ;
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

/*Creating missing values for the variables in manual regression*/
	
		data estimates;
			length Dependent $30. ;
			set paraes(drop = variable estimate stderr varianceinflation standardizedest probt tvalue);
			Dependent = "&dependent_variable." ;
		run;

		proc export data = estimates
        outfile="&estimatesfilename." 
        dbms=csv replace; 
        run;

/*		libname outes xml "&estimatesfilename1.";*/
/*		data outes.estimates;*/
/*			length Dependent $30. ;*/
/*			set paraes(drop = variable estimate stderr varianceinflation standardizedest probt tvalue);*/
/*			Dependent = "&dependent_variable." ;*/
		run;

	data _NULL_;
		if (&chartcheck. > 10000) then do;
		call symput("chartpopulate","false");
		end;
	run;

	%put &chartpopulate. ;


		data chart;
		set out.outdata(keep = pred res leverage &dependent_variable. primary_key_1644);
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
/*		libname outch xml "&chartfilepath./charts.xml";*/
/*	  	data outch.chart2;*/
/*			set chart2;*/
/*			run; */

	 proc export data = chart2
        outfile="&output_path./normal_chart.csv" 
        dbms=csv replace; 
        run;
	%plots(chart2,0);
/*		libname outch xml "&chartfilepath./transformed_charts.xml";*/
/*	  	data outch.chart1;*/
/*			set chart1;*/
/*			run; */
    proc export data = chart1
            outfile="&output_path./transformed_chart.csv" 
            dbms=csv replace; 
            run;
	%plots(chart1,1);
	%end;
	%else %do;
/*		libname outch xml "&chartfilepath./charts.xml";*/
/*	  	data outch.chart1;*/
/*			set chart1;*/
/*			run;*/
		 proc export data = chart1
            outfile="&output_path./normal_chart.csv" 
            dbms=csv replace; 
            run;
		%plots(outdata,0);
	%end;


		 proc export data = statestimates
            outfile="&statsfilename." 
            dbms=csv replace; 
            run;

/*		libname outst xml "&statsfilename1."; */
/*		 data outst.stats;*/
/*			 set statestimates;*/
/*		 run;*/


%mend regression3;

%regression3;

/*Save the iteration details into the job.xml file */
/*Creating the time variable using sysdate and systime*/
/*	%macro saveIterationInJobXML();*/
/**/
/*		libname outjb xml "&jobsfilename.";*/
/* create a job dataset with one row for the current job */
/*		data job;*/
/*			length jobtype $11;*/
/*			length time $22 ;*/
/*			length correctionsapplied $15 ; */
/*      		length validated $5;*/
/*			length chartpopulate $5;*/
/*			set statestimates;*/
/*			validated = "false";*/
/*			model_iteration = &model_iteration. ;		*/
/*			jobtype="Manual";*/
/*			time = "Time &dateandtime." ;*/
/*			start_iteration = &start_iteration. ;*/
/*			observations_used = &number_of_obs_used. ;*/
/*			variables_used = &variables_used. ;*/
/*			correctionsapplied = "&hetero. &dw.";*/
/*			correctionsapplied = strip(correctionsapplied);*/
/*			chartpopulate = "&chartpopulate." ;*/
/*		run;*/
/*	*/
      /* Delete the jobs_final dataset in case it already exists */
/*      %if %sysfunc(exist(jobs_final)) %then %do ;*/
/*            proc delete data=jobs_final;*/
/*            run; quit;*/
/*      %end;*/

		/* If the xml file already exists, load the iterations into jobs_final*/
/*		%if %sysfunc(fileexist("&jobsfilename.")) %then %do ;	*/
/*	      		data jobs_final;*/
/*					length jobtype $11;*/
/*					length time $22 ;*/
/*					length chartpopulate $5;*/
/*					length correctionsapplied $15 ; */
/*			      	length validated $5;*/
/*	         		set outjb.job;*/
/*	      		run;*/
/*		%end;*/
/*		proc append base=jobs_final data= job force;*/
/*		run;*/
/*		*/
/*		data outjb.job;*/
/*			set jobs_final;*/
/*		run;*/
/*	%mend;*/
/**/
/*	%saveIterationInJobXML();*/

%macro dependence1();
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
                                                if (coefficient ^= 0) then do;
                                                        rhs = strip(coefficient);
                                                end; else do;
                                                        rhs = "";
                                                end;
                        end; else do;
                            rhs = strip(coefficient) || " * " ||strip(Term);
                        end;
                                end;
                lhs = LeftHandSide;
            end; else do;

                                /*
                When adding to the rhs, put a + sign if it is not the first variable
                Put a + sign if the coefficient is positive;
                If it is negative, coefficient will carry the - sign                              */

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

        /*Save the two datasets DependenceEquations & Null Values to the dataset*/

      
        %sysexec del "&validationoutputfile";
        libname outvld xml "&validationoutputfile";
        data outvld.validation;
            set dependence_equations_final;
        run;
          proc delete data=dependence_equations_final;
        run; quit;
%end;
%mend dependence1;	



%dependence1();

/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
%macro mape(mape_dataset , output);
	data &mape_dataset. ;
		set &mape_dataset.;
		modres = abs(res);
		actual1 = abs(&dependent_variable.);
		mapeindi = (modres/actual1);
	run;

	proc sql;
		create table &output. as 
   		select avg(mapeindi)*100 as mapeval 
   		from &mape_dataset. ;
    quit;
       
%mend mape;

/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
%macro hit_rate (hitrate_dataset,output);
	proc rank data = &hitrate_dataset. out = out1 groups = 10;
	var actual pred;
	ranks rank_actual rank_pred;
	run;

	proc means data = out1 ;
		var actual pred;
		class rank_actual rank_pred;
		ods output summary =rank(keep = rank_actual rank_pred nobs);
	run;

	proc sql noprint;
		create table rank as
		select *, sum(nobs) as Nobs_Sum
		from rank;
	quit;

	data rank1;
		set rank;
		where rank_actual = rank_pred;
	run;

	proc sql noprint;
		create table rank1 as
		select *, sum(nobs) as hit
		from rank1;
	run;

	data &output(keep = hit_rate);
		set rank1;
		hit_rate = (hit*100)/nobs_sum ;
	run;

%mend hit_rate;

/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
%macro rankordering(rankordering_dataset,output);
	proc rank data = &rankordering_dataset. out = rank_out groups = 10 ;
		var actual;
		ranks rank_actual;
	run;

	proc means data = rank_out mean ;
		var pred actual;
		class rank_actual;
		ods output summary = rank1(keep = rank_actual pred_mean actual_mean);
	run;

/*Making ranks 1-to instead of 0-9*/
	data &output;
		set rank1;
		rank_actual = rank_actual+1;
	run;
	
%mend rankordering;

/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/

%macro model_stability();

	data _null_;
		set group.bygroupdata end = eof;
		if eof then do;
		call symputx("jump" , round((_n_/4)));
		call symputx("tot_rows" , _n_);
		end;
		where &validation_var. = 0; 
		run;
		%put &jump. &tot_rows;

%if "&sample_method" = "seq" %then %do;

		data bygroupdata;
		set group.bygroupdata (where = (&validation_var. = 0));
		if 1 <= _n_ <= &jump then sample_number = 1;
		else if %eval(&jump+1) <= _n_ <= %eval(&jump*2) then sample_number = 2;
		else if %eval((&jump*2)+1) <= _n_ <= %eval(&jump*3) then sample_number = 3;
		else sample_number = 4;
		run;

%end;

%if "&sample_method" = "random" %then %do;

	data bygroupdata;
	set group.bygroupdata(where = (&validation_var. = 0));
	if mod(_n_ , &jump) = 1 then sample_number = 1;
	else if mod(_n_ , &jump) = 2 then sample_number = 2;
	else if mod(_n_ , &jump) = 3 then sample_number = 3;
	else if mod(_n_ , &jump) = 0 then sample_number = 4;
	run;

%end;

%do j = 1 %to &n.;
		data inputreg;
			set bygroupdata;
			where sample_number = &j. ;
		run;
	
		ods output ParameterEstimates=paraes&j.;

		proc reg data = inputreg;
			model &dependent_variable. = &all_independent_variables./vif stb;
			output out=out.outdata p=pred r=res h=leverage;
		run; quit;
		data paraes&j.(keep = variable Sample&j.);
			set paraes&j. ;
			rename Estimate = Sample&j. ;
		run;

	proc sort data = in.paraes; by variable; quit;	
	proc sort data = paraes&j.; by variable; quit;	
	data in.paraes;
		merge in.paraes(in = a) paraes&j.(in = b) ;
		by variable;
		if a;
	run;
	data in.paraes;
		set in.paraes;
		nonconfirmingbetas = 0;
		if ((Sample&j.>(Estimate-stderr)) and (Sample&j.<(Estimate+stderr))) then do;
		flag&j. = 0;
		end;
		else flag&j. = 1;
		nonconfirmingbetas = nonconfirmingbetas + flag&j. ;
	run;
	data in.paraes;
		set in.paraes;
		drop flag&j. ;
	run;
%end; 
	
/*Creating XML to compare estimates*/

/*	libname outes xml "&estimatesfilename2."; */
	data estimates ;
		set in.paraes (keep = variable Estimate stderr sample1 sample2 sample3 sample4) ;
		rename variable = variablename;
		rename estimate = Original;
		rename stderr = standarddeviation;
	run;
	
	proc export data = estimates
            outfile="&estimatesfilename2." 
            dbms=csv replace; 
            run;

/*	libname outes xml "&estimatesfilename3."; */
/*	data outes.estimates ;*/
/*		set in.paraes (keep = variable Estimate stderr sample1 sample2 sample3 sample4) ;*/
/*		rename variable = variablename;*/
/*		rename estimate = Original;*/
/*		rename stderr = standarddeviation;*/
/*	run;*/
	
%mend model_stability;

%mape(in.outdata , out.mape1);
%mape(out.outdata , out.mape2);

%hit_rate(in.outdata , out.hit1);
%hit_rate(out.outdata , out.hit2);

%rankordering(in.outdata ,out.rank1);

%rankordering(out.outdata , out.rank2);

data out.rank_final;
merge out.rank1(in = a) out.rank2(in = b rename = (pred_Mean = v_pred_Mean actual_Mean = v_actual_Mean));
by rank_actual;
if a;
run;



proc sql;

select hit_rate into:hit_rate1 from out.hit1;
select hit_rate into:hit_rate2 from out.hit2;
select mapeval into:mape1 from out.mape1;
select mapeval into:mape2 from out.mape2;

quit;

%let metric1 = mape;
%let metric2 = hit_rate;
%put &hit_rate1 &hit_rate2 &mape1 &mape2;

%macro temp;
data mape1;
	format metric $10.;
%do i = 1 %to 1;
%let j = %eval(&i+1);
	metric = "&&metric&i";
	build = "&&mape&i";
	validation = "&&mape&j";
%end;
run;

data
mape2;
	format metric $10.;
%do i = 1 %to 1;
%let j = %eval(&i+1);
	metric = "&&metric&j";
	build = "&&hit_rate&i";
	validation = "&&hit_rate&j";
%end;
run;

data out.mape;
set mape1 mape2;
run;
%mend temp;

%temp;

/*libname outvrk xml "&output_path./rankorderfile.xml"; */
data rankordering;
	set out.rank_final;
run;
	proc export data = rankordering
            outfile="&output_path./rankorderfile.csv" 
            dbms=csv replace; 
            run;

/*libname mapehit xml "&output_path./mapehitfile.xml";*/
	data mapehit;
		set out.mape;
	run;
	proc export data = mapehit
            outfile="&output_path./mapehitfile.csv" 
            dbms=csv replace; 
            run;

/*libname outvrk xml "&output_path./rankorderfile.xml"; */
data rankordering;
	set out.rank_final;
run;

proc export data=rankordering dbms=csv outfile="&output_path./rankorderfile.csv" replace;
run;

/*libname mapehit xml "&output_path./mapehitfile.xml";*/
	data mapehit;
		set out.mape;
	run;

 proc export data=mapehit dbms=csv outfile="&output_path./mapehitfile.csv" replace;
run;


/*%model_stability;*/
/*%saveIterationInJobXML;*/

/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/

/* Flex uses this file to test if the code has finished running */
data _NULL_;
	v1= "Linear Regression - LINEAR_REGRESSION_VALIDATION_COMPLETED";
	file "&output_path./LINEAR_REGRESSION_VALIDATION_COMPLETED.txt";
	PUT v1;
run;

/*endsas;*/




