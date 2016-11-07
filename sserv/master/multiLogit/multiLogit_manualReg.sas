/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path./MANUAL_REGRESSION_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;
dm 'log' clear;

proc printto log="&output_path/MultiLogit_Log.log";
run;
quit;
	
/*proc printto print="&output_path./MultiLogit_Output.out";*/
	

libname in "&input_path.";
libname group "&group_path.";
libname out "&output_path.";

%macro regression6;

/*TYPE of DEPENDENT VARIABLE*/
%let dsid = %sysfunc(open(in.dataworking));
      %let varnum = %sysfunc(varnum(&dsid,&dependent_variable.));
      %let typ_dep = %sysfunc(vartype(&dsid,&varnum)); /* variable type */
      %let rc = %sysfunc(close(&dsid));
%put &typ_dep;

/*Checking if either of VIF or logisitc option is true*/
%if "&flag_only_vif." = "true" or "&flag_run_glogit." = "true"  %then %do;

	/*Checking if it is the first iteration if so then set dataworking as the bygroupdata*/
	%if "&model_iteration." = "1" %then %do;
		%if %sysfunc(exist(&dataset_name.)) %then %do;
			%put EXISTS! :-p;
		%end;
		%else %do;
			%if "&grp_no" = "0" %then %do;
		      	data group.bygroupdata;
					set in.dataworking;
					run;
		    %end;

	/*if the regression is to be performed on pergroupby keep only the required observations*/
			%else %do;
		    	data group.bygroupdata;
					set in.dataworking (where = (GRP&grp_no._flag = "&grp_flag."));
					run;
		    %end;
		%end;
	%end;

	/*updating the bygroupdata for new variable creation*/
	%if "&flag_bygrp_update." = "true" %then %do;
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
	%let dset=group.bygroupdata;
		%let dsid = %sysfunc(open(&dset));
		%let nobs =%sysfunc(attrn(&dsid,NOBS));
		%let rc = %sysfunc(close(&dsid));
		%if &NOBS. < 7 %then %do;
			data _null_;
	      		v1= "There are less than 7 observations in the subsetted dataset hence cannot perform modeling";
	      		file "&output_path./INSUFFICIENT_OBSERVATIONS_CONSTRAINT.txt";
	      		put v1;
				run;
			endsas;
		%end;
%end;

/*checking number of uniqur values in the dependent variable*/
%macro check;
	proc sql;
	select distinct(&dependent_variable) into:checkvar separated by "," from group.bygroupdata;
	quit;
		%if %sysfunc(countw("&checkvar",",")) = 1  %then %do;
			data _null_;
	      		v1= "Dependent variable has only one unique level, hence model cannot run";
	      		file "&output_path./ONLY_ONE_LEVEL_CONSTRAINT.txt";
	      		put v1;
				run;
				endsas;
		%end;
		%if "&validation_var" ^= "" %then %do;
				%if "&type_glogit." = "build" %then %do;
					data dummy(keep=&dependent_variable. &validation_var);
						set group.bygroupdata;
						where &validation_var. =1;
						run;
					proc sql;
						select distinct(&dependent_variable) into:checkvar separated by "," from dummy;
						quit;
					 %if %sysfunc(countw("&checkvar",",")) = 1  %then %do;
						data _null_;
	      					v1= "Dependent variable has only one unique level after validation scenario is applied for entire option, hence model cannot run";
	      					file "&output_path./ENTIRE_CONSTRAINT.txt";
	      					put v1;
							run;
							endsas;
					%end;
				%end;
				%if "&type_glogit." = "validation" %then %do;
					data dummy(keep=&dependent_variable. &validation_var);
						set group.bygroupdata;
						where &validation_var. =0;
						run;
					 proc sql;
						select distinct(&dependent_variable) into:checkvar separated by "," from dummy;
						quit;
					 %if %sysfunc(countw("&checkvar",",")) = 1  %then %do;
						data _null_;
	      					v1= "Dependent variable has only one unique level after validation scenario is applied for sample option, hence model cannot run";
	      					file "&output_path./SAMPLE_CONSTRAINT.txt";
	      					put v1;
							run;
							endsas;
					%end;
				%end;
		%end;
 %mend;
 %check;


/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/*MISSING INFO*/
%if "&flag_missing_perc." = "true" %then %do;

	%if "&class_variables." ^= "" %then %do;
		proc sort data=group.bygroupdata out=group.bygroupdata;
			by &class_variables.;
			run;
	%end;
	
	proc means data=group.bygroupdata nmiss;
	%if "&class_variables." ^= "" %then %do;
		class &class_variables.;
	%end;
		output out = means;
	%if "&class_variables." ^= "" %then %do;
		by &class_variables.;
	%end;
		var &dependent_variable. &independent_variables. ;
		run;

	proc transpose data=means out=means_trans (rename=_NAME_=variable rename=col1=nmiss drop= col2 col3 col4 col5);
		run;

	/*obtaining the total frequency */
	proc sql ;
		select nmiss into:freq from means_trans where variable='_FREQ_';
		quit;
		%put &freq.;

	/*calculating the missing count and missing percentage*/
	data missing;
		set means_trans;
		nmiss=&freq.-nmiss;
		miss_per=nmiss/&freq.;
		if variable="_TYPE_" or variable="_FREQ_" then delete;
		run;

	/* exporting the missing data*/
	proc export data = missing
		outfile = "&output_path./appData_missing.csv"
		dbms = CSV replace;
		run;
%end;

/*++++++++++++++++++++++++++++++++++++++++++++++++ ONLY VIF ++++++++++++++++++++++++++++++++++++++++++++++++*/
%if "&flag_only_vif." = "true" or "&flag_vif." = "true" %then %do;
	ods output ParameterEstimates = vif_params(keep= Variable VarianceInflation);
    proc reg data = &dataset_name.;
    	model &dependent_variable. = &independent_variables./vif %if "&var_elim." ^= "" %then %do; selection = &var_elim. Slentry = &slentry. slstay = &slstay. %end;;

		/*checking if validation is being done*/
			%if "&validation_var" ^= "" %then %do;

		/* checking the type if build or validation*/
				%if "&type_glogit." = "build" %then %do;
					where &validation_var = 1;
				%end;
				%if "&type_glogit." = "validation" %then %do;
					where &validation_var = 0;
				%end;
			%end;
    	run;
		quit;

	libname output xml "&output_path/parameter_estimates.xml";
	  data output.params;
		   set vif_params;
		   run;
%end;


%if "&flag_run_glogit." = "true" %then %do; 
	%put &event.;

/*obtaining the event value to give as input in logistic*/
	data _null_;
		call symput("event_exact", "(REFERENCE = '&event.')");
		run;
	%put &event_exact.;


	/*get type of class variable*/
	%if "&class_variables." ^= "" %then %do;
		data _null_;
			call symput("pref", tranwrd("&pref.", "!! ", "!!"));
			run;
		%put &pref;

		%let i = 1;
		%do %until (not %length(%scan(&class_variables, &i)));

	/*Formatting the class var as required*/
			data _null_;
				%if "&i." = "1" %then %do;
					%if %scan(&pref, &i, "!!") ^= first and %scan(&pref, &i, "!!") ^= last %then %do;
					call symput("pref_mod", "'%scan(&pref, &i, "!!")'");
					%end;
					%if %scan(&pref, &i, "!!") = first or %scan(&pref, &i, "!!") = last %then %do;
					call symput("pref_mod", "%scan(&pref, &i, "!!")");
					%end;
				%end;
				%else %do;
					%if %scan(&pref, &i, "!!") ^= first and %scan(&pref, &i, "!!") ^= last %then %do;
					call symput("pref_mod", cats("&pref_mod.", "!!", "'%scan(&pref, &i, "!!")'"));
					%end;
					%if %scan(&pref, &i, "!!") = first or %scan(&pref, &i, "!!") = last %then %do;
					call symput("pref_mod", cats("&pref_mod.", "!!", "%scan(&pref, &i, "!!")"));
					%end;
				%end;
				run;

			%let i = %eval(&i.+1);
		%end;

		%put &pref_mod;
	%end;
	ods output FitStatistics = fit_stats;
 	ods output GlobalTests = global_tests;
 	ods output NObs = nob;
 	ods output ConvergenceStatus = convergence_status;
 	ods output ResponseProfile = response_profile;
 	ods output RSquare = rsquare;
	ods output OddsRatios = odds;
	ods output ParameterEstimates = params;
	ods output Type3 = type3;

	/*running logistic regression*/
	proc logistic data = &dataset_name. outmodel = out.out_model namelen = 50;
		%if "&class_variables." ^= "" %then %do;
			%let i = 1;
			%do %until (not %length(%scan(&class_variables, &i)));
				class %scan(&class_variables, &i) (ref = %scan(&pref_mod, &i., "!!"))/ param = %scan(&param, &i) order = &class_order_type. &class_order_seq.;
				%let i = %eval(&i.+1);
			%end;
			model &dependent_variable. &event_exact. = &independent_variables. &class_variables./
				link = glogit corrb details ctable pprob = (0 to 1 by 0.001) aggregate &regression_options.
				%if "&var_elim." ^= "" %then %do; selection = &var_elim. Slentry = &slentry. slstay = &slstay. %end;
				stb;
		%end;
		%else %do;
			model &dependent_variable. &event_exact. = &independent_variables./
				link = glogit corrb details ctable pprob = (0 to 1 by 0.001) aggregate  &regression_options.
				%if "&var_elim." ^= "" %then %do; selection = &var_elim. Slentry = &slentry. slstay = &slstay. %end;
				stb;
		%end;

	    output out=out.pred p=phat PREDPROBS=i;
		%if "&validation_var" ^= "" %then %do;
			%if "&type_glogit." = "build" %then %do;
				where &validation_var. = 1;
			%end;
			%if "&type_glogit." = "validation" %then %do;
				where &validation_var. = 0;
			%end;
		%end;
		run;

data out.pred;
	set out.pred(drop = _level_ phat);
	run;

proc sql;
	create table out.pred as 
	select distinct * from out.pred;
quit;
		
	/*checking if confusion matrix is required*/
		%if "&flag_cMatrix." = "true" %then %do;
			ods output  CrossTabFreqs=conf(drop=percent rowpercent colpercent);
				proc freq data=out.pred;
					tables _from_*_into_;
					run;

	/*obtaining the total */
			data conf (drop=Table _TYPE_ _TABLE_ Missing);
				length _into_ $32.;
				set conf;
				if _from_=" "  then _from_="total";
				if _into_=" "  then _into_="total";
				if _into_ ^="total" then _into_=cat("Pred_",_into_);
				attrib _all_ label=" ";
				rename _from_=Actual;
				run;
			
			proc transpose data=conf out=confmat(drop=_name_ );
				by Actual;
				id _into_;
				run;

			proc export data = confmat
				outfile = "&output_path./Confusion_matrix.csv"
				dbms = CSV replace;
				run;
		%end;

	/*fit stats*/
	data fit_stats(keep=statistics value);
		length Criterion $32.;
		set fit_stats;
		Criterion=cat(Strip(Criterion),"_intercept");
		rename criterion=statistics;
		rename InterceptAndCovariates=value;
		run;

	/* global tests	*/
	data global_tests;
		set global_tests(keep=test ChiSq);
		rename test=statistics;
		rename ChiSq=value;
		run;

	/* nob */
	data nob;
		set nob(keep=label n);
		rename label=statistics;
		rename n=value;
		run;

	/*response profile	*/
	data Response_profile;
		length outcome $32.;
		set Response_profile(keep=Outcome count);
		outcome=cat("num_",outcome);
		rename outcome=statistics;
		rename count=value;
		run;
	
	/* convergence status*/
	data Convergence_status;
		set Convergence_status(keep=reason status);
		rename reason=statistics;
		rename status=value;
		run;

	/*Rsquare*/
	data rsq;
		length statistics $21.;
		set Rsquare(keep=label1 nvalue1 rename=(label1=statistics nvalue1=value))
			Rsquare(keep=label2 nvalue2 rename=(label2=statistics nvalue2=value));
		run;

	/*model stats*/
	data model_stats;
		attrib _all_ label=" ";
		set fit_stats global_tests nob response_profile rsq Convergence_status;
		run;

	/*export model stats*/
	proc export data = model_stats
		outfile = "&output_path./model_stats.csv"
		dbms = CSV replace;
		run;

	/* export odds*/
	proc export data = odds
		outfile = "&output_path./Odds.csv"
		dbms = CSV replace;
		run;
    /*Model Anova*/
      %if "&flag_vif."="true" %then %do;
                  proc sort data=params;
                              by Variable;
                        run;

                  proc sort data=vif_params;
                              by variable;
                        run;

                  data params;
                        merge params(in=a) vif_params(in=b);
                        by Variable;
                        if a;
                        run;

     %end;
	/*export params*/
	proc export data = params
		outfile = "&output_path./params.csv"
		dbms = CSV replace;
		run;

	/*export type3*/
	proc export data = type3
		outfile = "&output_path./type3.csv"
		dbms = CSV replace;
		run;
%end;
/*checking if confusion matrix is required*/
		%if "&flag_cMatrix." = "true" %then %do;
			ods output  CrossTabFreqs=conf(drop=percent rowpercent colpercent);
				proc freq data=out.pred;
					tables _from_*_into_;
					run;

	/*obtaining the total */
			data conf (drop=Table _TYPE_ _TABLE_ Missing);
				length _into_ $32.;
				set conf;
				if _from_=" "  then _from_="total";
				if _into_=" "  then _into_="total";
				if _into_ ^="total" then _into_=cat("Pred_",_into_);
				attrib _all_ label=" ";
				rename _from_=Actual;
				run;
			
			proc transpose data=conf out=confmat(drop=_name_ );
				by Actual;
				id _into_;
				run;

			proc export data = confmat
				outfile = "&output_path./Confusion_matrix.csv"
				dbms = CSV replace;
				run;
		%end;
%mend regression6;
%regression6;


/* Flex uses this file to test if the code has finished running */
data _NULL_;
      v1= "Logistic Regression - MANUAL_REGRESSION_COMPLETED";
      file "&output_path./MANUAL_REGRESSION_COMPLETED.txt";
      PUT v1;
      run;

/*endsas;*/



