/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &outputPath./MANUAL_REGRESSION_COMPLETED.txt &outputPath./MANUAL_REGRESSION_COMPLETED.txt;
/*Code: Logistic*/
/*Author: Aparna Joseph/ Subarna Rana */									

dm log 'clear';
dm output 'clear';
proc datasets lib=work kill nolist memtype=data;
quit;
%macro classcheck;
	%let v1=initial;
	%let finalclass=;
	%if "&classvariables." ne "" %then %do;
	%do p=1 %to %sysfunc(countw("&classvariables."," "));
			data _null_;
			call symput("classvar","%scan("&classvariables.",&p.," ")");
			run;
			%if "&validationVar"^="" %then %do;
			%if &validationType.=build %then %do;
			proc sql;
			    select distinct(&classvar.) into:nlvlclass separated by " " from &datasetname. where &validationVar.=1;
				quit;
				%if %sysfunc(countw("&nlvlclass.",",")) = 1 %then %do;					
				%let finalclass=&finalclass &classvar;
				%let v1="Selected class variable (&finalclass.) has only one level in build type, hence model can not run";
				%end;
			%end;
			%else %if &validationType.=validationSample %then %do;
			proc sql;
			    select distinct(&classvar.) into:nlvlclass separated by " " from &datasetname. where &validationVar.=0;
				quit;	
				%if %sysfunc(countw("&nlvlclass.",",")) = 1 %then %do;					
				%let finalclass=&finalclass &classvar;
				%let v1="Selected class variable (&finalclass.) has only one level in validation type, hence model can not run";
				%end;
			%end;
	%end;
	%else %do;
		proc sql;
			    select distinct(&classvar.) into:nlvlclass separated by "," from &datasetname.;
				quit;
		%if %sysfunc(countw("&nlvlclass.",",")) = 1 %then %do;						
		%let finalclass=&finalclass &classvar;
		%let v1="Selected class variable (&finalclass.) has only one level, hence model can not run";
		%end;
	%end;
	%end;
	%end;
	%if &v1. ne initial %then%do;
		data _null_;
	      		v1=&v1;;
	      		file "&outputpath./CLASS_CONSTRAINT.txt";
	      		put v1;
				run;
/*				endsas;*/
	%end;
	%if "&classvariables." ne "" and "&pref." = "" %then %do;
		data _null_;
	      		v1= "Selected level for class variable is blank, please select a valid level";
	      		file "&outputpath./CLASS_CONSTRAINT.txt";
	      		put v1;
				run;
/*			endsas;*/
	%end;
%mend;
%macro biascheck;
	%if "&biaseddatasetname." ne "" %then %do;
	 data _null_;
	 	call symput("datasetname","bias.&biaseddatasetname.");
	 run;
	 %end;
	 %put &datasetname.;
 %mend biascheck;
 %biascheck;
%let type1="";
%macro chcek_dep_char;
proc contents data=group.bygroupdata out=content;
run;

data content;
	set content;
	where name="&dependentvariable";
	run;
data _null_;
	set content;
	call symput("type1",type);
	run;
%put &type1;
%mend;
%chcek_dep_char;

%macro chk_obs;
	%let dset=&datasetname.;
		%let dsid = %sysfunc(open(&dset));
		%let nobs =%sysfunc(attrn(&dsid,NOBS));
		%let rc = %sysfunc(close(&dsid));
		%if "&validationVar" ne "" %then %do;
			%if "&validationType" = "build" %then %do;
				proc sql;
					select count(*) into:nobs from &datasetname where &validationVar = 1;
				quit;
			%end;
			%else %do;
				proc sql;
					select count(*) into:nobs from &datasetname where &validationVar = 0;
				quit;
			%end;
		 %end;
		%if &NOBS. < 7 %then %do;
			%put &NOBS;
			data _null_;
	      		v1= "There are less than 7 observations in the subsetted dataset hence cannot perform modeling";
	      		file "&outputpath./INSUFFICIENT_OBSERVATIONS_CONSTRAINT.txt";
	      		put v1;
				run;
/*			endsas;*/
		%end;
%mend chk_obs;

%macro ks_test_var;
		 /*TYPE of DEPENDENT VARIABLE*/
	

	 data &datasetname.;    
            %if "&logitform." = "single_trial" %then %do;
                  length XXXind_logit YYYind_logit 8.;
				  %let dsid = %sysfunc(open(in.dataworking));
				  %let varnum = %sysfunc(varnum(&dsid,&dependentvariable.));
				  %let typ_dep = %sysfunc(vartype(&dsid,&varnum)); /* variable type */
				  %let rc = %sysfunc(close(&dsid));
				  %put &typ_dep;
            %end;
            set &datasetname.;
            %if "&logitform." = "single_trial" %then %do;
                  %if &typ_dep. = N %then %do;
                        if &dependentvariable. = &event. then XXXind_logit = 0; else XXXind_logit = 1;
                  %end;
                  %if &typ_dep. = C %then %do;
                        if &dependentvariable. = "&event." then XXXind_logit = 0; else XXXind_logit = 1;
                  %end;
                  YYYind_logit = 1 - XXXind_logit;
            %end;
            %if "&logitform." = "events_trials" %then %do;
                  TRIALSind_logit = &dependentvariable.;
            %end;
      		run;
%mend ks_test_var;
%macro logistic;
%if &flagrunlogit. = true %then %do;
    %if &flagalphacorrection. = true %then %do;
          libname betas "&betas_path.";

          proc sql;
                select intercept into :orig_intercept from betas.out_betas;
                run;

          data betas;
          set betas.out_betas;
            Intercept = Intercept + log((&alpha. * (1 - (&oversample./100)))/((&oversample./100) * (1 - &alpha.)));
            run;

          proc sql;
                select intercept into :corrected_intercept from betas;
                run;
          data alpha_values;
                original_intercept = &orig_intercept.;
                corrected_intercept = &corrected_intercept.;
                run;
		%exportCsv(libname=work,dataset=alpha_values,filename=alpha_values);
    %end;
	quit;
	ods output ModelInfo = model_info;
    ods output NObs = nob;
    ods output ResponseProfile = response_profile;
    ods output ConvergenceStatus = convergence_status;
    ods output linear = DependenceEquations;
    ods output FitStatistics = fit_stats;
    ods output GlobalTests = global_tests;
    ods output Association =  association;
    ods output LackFitChiSq = lackFit_chiSq;
    ods output LackFitPartition = hl_partition_test;
    ods output Classification =C_table;
    ods output CorrB = corr;
    ods output OddsRatios = odds;
    ods output ParameterEstimates = params;
    ods output Type3 = type3;
    ods output GoodnessOfFit = goodness_of_fit;
    ods output RSquare = rsquare;
    proc logistic data = &datasetName.
        %if &flagAlphaCorrection. = true %then %do; inest = betas   %end;
        %else %do; outest = out.out_betas %end;
        outmodel = out.out_model namelen = 50;;
        %if "&classVariables." ^= "" %then %do;
              %do i=1 %to %sysfunc(countw("&classVariables.", ' '));
			  	%let ref =  %scan(&pref., &i., "!!"); 
				%let class&i. = %scan(&classVariables,&i.," ") (ref = "&ref")/ param = %scan(&param, &i) order = &classOrderType. &classOrderSeq.;
				class &&class&i;
              %end;
		%end;
               model &dependentVariable. %if &logitForm. = single_trial %then %do; (Event="&event.") %end; 
			   = &independentVariables. &classVariables./stb %if "&varElim." ^= "" %then %do; selection = &varElim. Slentry = &slentry. slstay = &slstay. %end;
               link = &modelType. corrb details lackfit ctable pprob = (0 to 1 by 0.001) outroc = roc scale = &scaleOption. aggregate &regressionOptions. %if "&maxiter." ^= "" %then %do; maxiter = %eval(&maxiter) %end;;          
	 	output out=out.pred p=phat PREDPROBS=i;
		%if "&weightVar." ^= "" %then %do;
          weight &weightVar. %if "&weightoption." ^= "" %then %do; /&weightoption. %end;;
        %end;
		%if "&validationVar"^="" %then %do;
			%if &validationType.=build %then %do;
			    where &validationVar.=1;
			%end;
			%else %if &validationType.=validationSample %then %do;
			    where &validationVar.=0;
			%end;
		%end;
         
        run;
		data pred;
			set out.pred;
		run;
%end;
%mend logistic;

%macro missing2;
	%if "&flagmissingperc." = "true" %then %do;
		%if "&logitform." = "events_trials" %then %do;
			%let dep_var = %scan("&dependentvariable." , 1 , "/");
		%end;
		
	      proc means data=&datasetname. nmiss;
	            output out = means;
				%if &type1 ne 2 %then %do;
					%if "&logitform." = "events_trials" %then %do;
		            var &dep_var. &independentvariables.;;
					%end;
					%else %do;
					var &dependentvariable. &independentvariables.;;
					%end;
				%end;
				%else %do;
				var &independentvariables.;;
				%end;
	            run;
		
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

		  %exportCsv(libname=work,dataset= missing,filename= appData_missing);
	%end;
%mend;

%macro varelim;
	/*Get max step size for Variable Elimination*/
	  %if "&varelim." ^= "" %then %do;
	        proc sql;
	              select step into :max_step from convergence_status having step = max(step);
	              quit;
	        %put &max_step;
	  %end;
%mend;
%global max_step;
%let max_step = &max_step.;
%macro association;
	/*....................ASSOICATION.......................*/
	%if %sysfunc(exist(association)) %then %do;
	      data association(drop = cvalue1 cvalue2 rename=(cvalue1_num=cvalue1 cvalue2_num=cvalue2));
	            set association;
	            %if "&varElim." ^= "" %then %do; 
					where step = .;
				%end;
	            format cvalue1_num cvalue2_num 8.2;
	            cvalue1_num = input(cvalue1, $8.);
	            cvalue2_num = input(cvalue2, $8.);
	            run;
	      
	      proc transpose data = association(keep=cvalue1 label1) out = association1(drop = _name_);
	            var cValue1;
	            id label1;
	            run;

	      proc transpose data = association(keep=cvalue2 label2) out = association2(drop = _name_);
	            var cValue2;
	            id label2;
	            run;
	%end;
%mend;

	

%macro lackfit;
	/*...............LACKFIT_CHISQ...........................*/
	%if %sysfunc(exist(lackfit_chisq)) %then %do;    
	      data lackfit_chisq;
	            set lackfit_chisq(keep=ProbChiSq);
	            rename ProbChiSq = HL_ProbChiSq;
	            run;
	%end;
%mend;


%macro rsq;
	/*....................RSQUARE...........................*/
	%if %sysfunc(exist(rsquare)) %then %do;
	     data rsquare (drop = cvalue1 cvalue2 %if "&varElim." ^= "" %then %do; step %end;);
	     set rsquare(keep=cvalue1 cvalue2 %if "&varElim." ^= "" %then %do; step %end;);
		     format Rsquare MaxRescaled_Rsquare 8.4;
		     Rsquare = input(cvalue1, $6.);
		     MaxRescaled_Rsquare = input(cvalue2, $6.);
		     %if "&varElim." ^= "" %then %do; 
				where step = &max_step;
			 %end;
		     run;
	%end;
%mend;


%macro modelinfo;
	/*...................MODEL INFO...........................*/
	proc transpose data = model_info(keep= value description) out = model_info (keep = number_of_response_levels);
	    var value;
	    id  description;
	    run;

	data model_info(drop = number_of_response_levels rename = (num=number_of_response_levels));
	    set model_info;
	    format num 8.;
	    num = input (number_of_response_levels, $17.);
	    run;
%mend;


%macro nob;
	/*........................NOB...............................*/
	proc transpose data = nob(keep= N label) out = nob (keep = Number_of_Observations_Read Number_of_Observations_Used);
	      var N;
	      id label;
	      run;
%mend;


%macro resprofile;
	/*................RESPONSE PROFILE...........................*/
	%if "&logitform." = "single_trial" %then %do;
	data response_profile;
	      length outcome $15;
	      set response_profile (drop = OrderedValue);
	      Outcome = catx("_", "num", Outcome);
	      if strip(outcome) = "num_&event." then outcome = "count_event";
	            else outcome = "count_non_event";
	      run;
	proc transpose data = response_profile(keep= count outcome) out = response_profile(drop = _name_);
	      var count;
	      id outcome;
	      run;
	%end;
	%else %do;
	data response_profile;
	      length outcome $15;
	      set response_profile (drop = OrderedValue);
	      if strip(outcome) = "Event" then outcome = "count_event";
	            else outcome = "count_non_event";
	      run;
	proc transpose data = response_profile(keep= count outcome) out = response_profile(drop = _name_);
	      var count;
	      id outcome;
	      run;
	%end;
%mend;


%macro covergence;
	/*....................CONVERGENCE STATUS......................*/
	proc transpose data = convergence_status(keep= %if "&varElim." ^= "" %then %do; step %end; status reason) out = convergence_status (drop = _name_);
	      var status;
	      id reason;
	      %if "&varElim." ^= "" %then %do; 
		  		where step = &max_step;
		  %end;
	      run;
%mend;


%macro fitstat;
	/*........................FIT STATS...........................*/
	proc transpose data = fit_stats(keep= criterion InterceptOnly %if "&varElim." ^= "" %then %do; step %end;) 
	            out = fit_stats1(drop = _name_ _label_ rename = (AIC=AIC_intercept SC=SC_intercept _2_Log_L=_2_Log_L_intercept));
	      var InterceptOnly;
	      id criterion;
	      %if "&varElim." ^= "" %then %do; 
				where step = &max_step.; 
		  %end;
	      run;

	proc transpose data = fit_stats(keep= criterion InterceptAndCovariates %if "&varElim." ^= "" %then %do; step %end;) 
	            out = fit_stats2(drop = _name_ _label_ rename = (AIC=AIC_intercept_covariates SC=SC_intercept_covariates _2_Log_L=_2_Log_L_intercept_covariates));
	      var InterceptAndCovariates;
	      id criterion;
	      %if "&varElim." ^= "" %then %do; 
				where step = &max_step; 
		  %end;
	      run;
%mend;


%macro globalstat;
	/*........................GLOBAL TESTS...........................*/
	proc transpose data = global_tests(keep= test ProbChiSq %if "&varElim." ^= "" %then %do; step %end;) out = global_tests(drop = _name_ _label_);
	      var ProbChiSq;
	      id test;
	         %if "&varElim." ^= "" %then %do; where step = &max_step; %end;
	      run;
%mend;


%macro goodfit;
	/*........................GOODNESS OF FIT...........................*/
	data goodness_of_fit;
	      length criterion $20.;
	      set goodness_of_fit(keep=criterion ProbChiSq);
	      criterion = cats("ProbChiSq_", criterion);
	      run;

	proc transpose data = goodness_of_fit out = goodness_of_fit(drop=_name_ _label_);
	      var ProbChiSq;
	      id criterion;
	      run;
%mend;


%macro overallstats;
	/*........................OVERALL STATS...........................*/
	data overall_stats;
	      merge model_info nob response_profile convergence_status fit_stats1 fit_stats2 global_tests 
	                %if %sysfunc(exist(association)) %then %do; association1 association2 %end; 
					%if %sysfunc(exist(rsquare)) %then %do; rsquare %end;
					%if %sysfunc(exist(lackfit_chisq))%then %do; lackfit_chisq %end; goodness_of_fit;
	      run;

	proc transpose data = overall_stats out = overall_stats (rename = (_name_ = test col1 = output_values));
	      run;
%mend;


%macro VIF2;
	/*------------------------------VIF-----------------------------------*/
%if &type1 ne 2 %then %do;
	%if "&logitform." = "single_trial" %then %do;
		%if &flagVif. = true OR &flagonlyvif. = true %then %do;
		     ods output ParameterEstimates = p_vif(keep= Variable VarianceInflation);
		     proc reg data = &datasetName. outest = out.lin_betas;
		                 model &dependentVariable. = &independentVariables./vif rsquare;

						  %if "&validationVar"^="" %then %do;
								%if &validationType.=build %then %do;
								    where &validationVar.=1;
								%end;
								%else %if &validationType.=validation %then %do;
								    where &validationVar.=0;
								%end;
						  %end;
		    	 run;
		         quit;

			%if ("&flagonlyvif." = "true") %then %do;
				%exportCsv(libname = work,dataset =  p_vif,filename = parameter_estimates);
				%endlog;
				endsas;
			%end;

		     proc sort data = p_vif;
			     by Variable;
			     run;

		     proc sort data = params;
			     by Variable;
			     run;

		     data params;
			     merge params(in = a) p_vif(in = b);
			     by Variable; 
			     if a or b ;
			     run;

		     data _null_;
		         set out.lin_betas(firstobs = 1 obs = 1);
		         call symput ("lin_rSQ", _RSQ_);
		         run;

		     data lin_rsq;
		         test = "lin_Rsquare";
		         output_values = %sysevalf(&lin_rSQ.);
		         run;
		%end;
	%end;
%end;
%else %do;
	%if &flagVif. = true OR &flagonlyvif. = true %then %do;
		data _null_;
      		v1= "VIF can not be calculated if dependent variable is of character type";
      		file "&outputpath./VIF_CONSTRAINT.txt";
      		put v1;
			run;
	%end;
%end;
%mend;


	
%macro export4;
	data overall_stats;
	      set overall_stats;
	      output_values = round(output_values, 0.0001);
	      run;

	 data overall_stats;
	       set overall_stats;
	       format grouping $70.;
		   if test = "Iteration_limit_reached_without" then grouping = "Maximum Iterations";
	       if test = "number_of_response_levels" or test = "Number_of_Observations_Read" or test = "Number_of_Observations_Used" then grouping = "model information";
	       if test = "num_0" or test = "num_1" then grouping = "response profile";
	       if test = "Convergence_criterion__GCONV_1E_" then grouping = "model convergence status";
	       if test = "AIC_intercept" or test = "SC_intercept" or test = "_2_Log_L_intercept" or test = "AIC_intercept_covariates" or test = "SC_intercept_covariates" 
	           or test = "_2_Log_L_intercept_covariates" or test = "Rsquare" or test = "lin_Rsquare" or test = "MaxRescaled_Rsquare" then grouping = "model fit stats";
	       if test = "Likelihood_Ratio" or test = "Score" or test = "Wald" then grouping = "global null hypothesis test";
	       if test = "Percent_Concordant" or test = "Percent_Discordant" or test = "Percent_Tied" or test = "Pairs" or test = "Somers__D" or test = "Gamma"
	           or test = "Tau_a" or test = "c" then grouping = "association of predicted prob and observed responses";
	       if test = "HL_ProbChiSq" then grouping = "hosmer lemeshow goodness of fit test";
	       if test = "ProbChiSq_Deviance" or test = "ProbChiSq_Pearson" then grouping = "deviance and pearson goodness of fit stats";
		   if test = "count_event" or test = "count_non_event" or test = "Quasi_complete_separation_of_dat" then grouping = "dependent variable";
	       run;
	/*...........................EXPORT OVERALL STATS....................................*/
		%exportCsv(libname=work,dataset=overall_stats,filename=overall_stats);

	/*..........................EXPORT HL_PARTITION_TEST.................................*/
	%if %sysfunc(exist(hl_partition_test)) %then %do;
	%exportCsv(libname=work,dataset=hl_partition_test,filename=hl_partition_test);
	%end;
	/*...............................EXPORT TYPE 3.....................................*/
	%if %sysfunc(exist(type3)) %then %do;
	    data type3;
	    	set type3;
	        %if "&varElim." ^= "" %then %do;
				where step = .; 
			%end;
	        run;
		%exportCsv(libname=work,dataset=type3,filename=type3);
	%end;
	/*...............................EXPORT ODDS.....................................*/
	%if &modelType.=logit or &modelType.=glogit %then %do;
		data odds;
			 set odds;
			 %if "&varElim." ^= "" %then %do; 
			 	where step = .; 
			 %end;
			 run;  

		  proc sql;
			  create table odds_final as
			  select Effect,OddsRatioEst,LowerCL,UpperCL from odds;
			  quit; 

		 %if %sysfunc(exist(odds_final)) %then %do;
			 %exportCsv(libname=work,dataset=odds_final,filename=odds);
		 %end;	
	%end;
	/*...............................EXPORT CORR.....................................*/
		%exportCsv(libname=work,dataset=corr,filename=corr);
	/*...............................EXPORT C_TABLE..................................*/
		%exportCsv(libname=work,dataset=C_table,filename=classification_table);
	/*........................EXPORT PARAMETER ESTIMATES..............................*/
	data params;
		set params;
		%if "&varElim." ^= "" %then %do; 
			where step = .; 
		%end;
		run;
	%if "&varElim." ^= "" %then %do;
		data params;
		set params(drop = Step);
		run;
	%end;
	
	/*Creating the model equation and writing it to a txt*/
/*	data temp_for_eqn;*/
/*		set params;*/
/*		equation = compress(estimate || "(" || variable || ")");*/
/*		run;*/
/**/
/*	proc sql noprint;*/
/*		select equation into: equation separated by " + " from temp_for_eqn;*/
/*		quit;*/
/**/
/*	%let equation =  &dependentvariable. = %sysfunc(tranwrd(&equation.,+ -,-));*/
/*	%put &equation.;*/
/**/
/*	filename myfile "&outputpath./MANUAL_REGRESSION_EQUATION.txt" lrecl = 2000;*/
/*	data _null_;*/
/*		file myfile;*/
/*		put "&equation.";*/
/*		run;*/
	%exportCsv(libname=work,dataset=params,filename=parameter_estimates);
%mend;

%macro roc1;
	/*............................ROC1...............................*/
	%if %sysfunc(exist(c_table)) %then %do;
		%if &flagRoc1. = true %then %do;
		      data roc1 (drop = Specificity Sensitivity rename = (_SENSITIVITY_ = SENSITIVITY));
		            set c_table (keep = Sensitivity Specificity);
		            ONE_MINUS_SPECIFICITY = 1-(Specificity/100);
		            _SENSITIVITY_ = Sensitivity/100;
		            run;

			  proc sort data = roc1;
	                by SENSITIVITY;
	                run;

			  proc sql;
				create table roc1 as
				select ONE_MINUS_SPECIFICITY,SENSITIVITY
				from roc1;
				quit;

			%exportCsv(libname=work,dataset=roc1,filename=roc1);
		%end;
	%end;
%mend;


%macro rocs;
	/*............................ROCS...............................*/
	%if %sysfunc(exist(c_table)) %then %do;
		%if &flagRocs. = true %then %do;
		      data roc_s (drop = Sensitivity Specificity rename = (ProbLevel = _PROB_ _SENSITIVITY_ = SENSITIVITY _SPECIFICITY_ = SPECIFICITY));
		            set c_table (keep = ProbLevel Sensitivity Specificity);
		            _SENSITIVITY_ = (Sensitivity/100);
		            _SPECIFICITY_ = (Specificity/100);
		            run;

			%exportCsv(libname=work,dataset=roc_s,filename=roc_s);
		%end;
	%end;
%mend;


%macro predact;
	/*............................. PREDICTED VS ACTUAL CURVES..........................*/;
	%if &flagActpred. = true %then %do;
	      %if &logitForm. = single_trial %then %do;
	            proc rank data = pred out = testpred (keep = deciles phat _FROM_) Groups = %sysevalf(&numGroups.) descending ;
	                var phat;
	                ranks deciles;
	                run;

	            proc sort data = testpred;
	                by deciles;
	                run;

	            proc sql;
	                create table predicted_actual as
	                select deciles, avg(phat)*100 as predicted, (sum(CASE WHEN _FROM_="&event." THEN 1 ELSE 0 END)/count(*))*100 as actual
	                from testpred
	                group by deciles;
	                quit;

	            proc sql;
	                create table predicted_actual as
	                select deciles, predicted, actual, avg(actual) as average_rate, (predicted/actual) as pred_by_actual
	                from predicted_actual
	                quit;

			%exportCsv(libname=work,dataset= predicted_actual,filename= predicted_actual);

	/*.......................... CALCULATING AVERAGE CHURN RATE..............................*/

	            proc sql;
	                  create table average_rate as
	                  select avg(actual) as average_rate
	                  from predicted_actual;
	                  quit;
			%exportCsv(libname=work,dataset=average_rate,filename= average_rate);

	      %end;
	      %if &logitForm. = events_trials %then %do;
	            proc rank data = pred(keep=phat TRIALSind_logit) out = testpred(keep = deciles phat TRIALSind_logit) groups = %sysevalf(&numGroups.) descending ;
	                var phat;
	                ranks deciles;
	                run;

	            proc sort data = testpred;
	                by deciles;
	                run;

	            proc sql;
	                create table predicted_actual as
	                select deciles, avg(phat)*100 as predicted,avg(TRIALSind_logit)*100  as actual
	                from testpred
	                group by deciles;
	                quit;
	            proc sql;
	                create table predicted_actual as
	                select deciles, predicted, actual, (predicted/actual) as pred_by_actual
	                from predicted_actual
	                quit;

			%exportCsv(libname=work,dataset= predicted_actual,filename= predicted_actual);
	      %end;
	%end;
%mend;


%macro ks;
	/*....................................KS TEST......................*/
	%if &logitForm. = single_trial %then %do;
	    %if &flagKstest. = true or &flagLift. = true or &flagGains. = true %then %do;

			data ks_main;
	              set pred (keep=phat &dependentVariable. XXXind_logit );
	              V_GOOD=XXXind_logit;
	              V_BAD=1-XXXind_logit;
	              run;

	        proc rank data=ks_main out=ks_rankpred groups=%eval(&numGrps.) descending;
	              var phat;
	              ranks rank_pred;
	              run;

	        proc sort data = ks_rankpred;
	              by rank_pred;
	              run;

	        proc means data=ks_rankpred noprint;
	              var phat V_BAD;
	              by rank_pred;
	              output out=ks_means mean=mean badrate min=minimum minbad max=maximum maxbad;
	              run;

	        proc freq data=ks_rankpred noprint;
	              table rank_pred / out=ks_freq_weighted;
	              weight V_BAD;
	              run;

	        proc freq data=ks_rankpred noprint;
	              table rank_pred / out=ks_weightedFreq_good;
	              weight V_GOOD;
	              run;

	        proc freq data=ks_rankpred noprint;
	              table rank_pred / out=ks_Freq;
	              run;

	        data ks_freqs;
	              merge ks_freq_weighted(rename=(percent=percent_bad count=count_bad))
	                    ks_weightedFreq_good(rename=(percent=percent_good count=count_good))
	                    ks_Freq(rename=(count=count_accts))
	                    ks_means(keep=rank_pred mean badrate minimum maximum);
	                    by rank_pred;
	                    run;

	        data ks_freqs;
	              set ks_freqs end = final;
	                    total_accts+count_accts;
	                    if final then call symput('sum_accts',total_accts);
	              		run;

	        data ks_cumm; 
	              set ks_freqs;
	              cumm_bad+count_bad;
	              cumm_good+count_good;
	              cumm_accts+count_accts;
	              cumm_perc_bad+percent_bad;
	              cumm_perc_good+percent_good;
	              cumm_bad_rate=cumm_bad/cumm_accts;
	              cumm_good_rate=cumm_good/cumm_accts;
	              cumm_accts_rate=cumm_accts/&sum_accts;
	              ks_mv=((count_bad-count_accts*mean) * (count_bad-count_accts*mean))/ (count_accts*mean*(1-mean));
	              cumm_gof+ks_mv;
	              ks_bdgd = ABS(cumm_perc_bad - cumm_perc_good) ;
	              group=_n_;
	              run;

	        data ks_inter; 
	              set ks_cumm (keep = group rank_pred badrate mean minimum maximum cumm_bad cumm_perc_bad cumm_accts cumm_bad_rate cumm_gof ks_bdgd);
	              run;

	        proc transpose data = ks_inter out = ks_inter_trans;
	              run;

	        data ks (rename=(ks_bdgd = ks group = max_ks_dec));
	              set ks_inter (keep = ks_bdgd group);
	              run;

	        proc sort data = ks ;
	              by descending ks;
	              run;

	        data ks; 
	              set ks (obs = 1);
	              format ks 8.2; 
	              run;

	        data ks_gof (rename=(cumm_gof = gof));
	              set ks_inter (keep = cumm_gof);
	              run;

	        proc sort data = ks_gof; 
	              by descending gof;
	              run;

	        data ks_gof;
	              set ks_gof (obs = 1);
	              format gof 8.2; 
	              run;

	        data ks_inter (keep = group rank_pred cumm_accts pred_resp act_resp minimum maximum cumm_respr cumresp pctresp ks gof);
	              set ks_inter;
	              pred_resp = mean*100; format pred_resp 8.2;
	              act_resp = badrate*100; format act_resp 8.2;
	              cumm_respr = cumm_bad_rate*100;format cumm_respr 8.2;
	              format minimum 8.3 maximum 8.3 cumm_perc_bad 8.2 ks_bdgd 8.2 cumm_gof 8.2;
	              rename cumm_bad = cumresp cumm_perc_bad = pctresp ks_bdgd = ks cumm_gof = gof;
	              run;


	        data ks_order (keep=_name_ order_flag ranking sat_rank rename=(_name_=attribute)); 
	              set ks_inter_trans; 
	              where lowcase(_NAME_) = 'badrate';
	              order_flag = 0;
	              %do i = 1 %to &numGrps. - 1;
		              %let j = %eval(&i + 1);
		                    order_flag = order_flag + (col&i lt col&j);
		          %end ;
	              if order_flag gt 0 then ranking = 'NOT SATISFACTORY'; 
	                    else ranking = 'SATISFACTORY';
	              sat_rank = 'ALL';
	              %do i = 1 %to &numGrps. - 1;
		              %let j = %eval(&i + 1);
	                    if ((col&i lt col&j) and (sat_rank = 'ALL')) then sat_rank = "&i";
	              %end;
	              run;

	        data out.ks_rep; 
	              merge ks_order ks ks_gof;
	              run;

	        data out.ks_out;
	              merge ks_inter(in=a drop=group) ks_freqs(in=b drop=mean badrate minimum maximum total_accts);
	              by rank_pred;
	              if a or b;
	              run;

	        data out.ks_out(rename=(count_bad=count_events percent_bad=percent_events count_good=count_nonevents 
	                                            percent_good=percent_nonevents));
	              retain rank_pred count_bad percent_bad count_good percent_good count_accts percent_accts cumm_accts pred_resp act_resp
	                          minimum maximum cumm_respr cumresp pctresp ks gof;
	              set out.ks_out(rename=(percent=percent_accts));
	              attrib _all_ label="";
	              run;
	        
	        data out.ks_out (drop = abcd);
	              set out.ks_out;
	              abcd = (pctresp + lag(pctresp))/100;
	              if _n_ = 1 then abcd = pctresp/100;
	              gini = (0.05*abcd);
	              run;

	        proc sql;
	              create table gini as
	              select (2*sum(gini) - 1) as gini from out.ks_out;
	              quit;

	        data out.ks_rep;
	              merge out.ks_rep(in=a) gini(in=b);
	              if a or b;
	              run;

			proc sql;
				create table out.ks_rep as
				select attribute,order_flag,ranking,sat_rank, max_ks_dec,ks,gof
				from out.ks_rep;
				quit;

			%exportCsv(libname=out,dataset= ks_rep,filename= ks_rep);
			%exportCsv(libname=out,dataset= ks_out,filename= ks_out);

	/*..............................LIFT AND GAINS CHART..............................*/

			data lift (keep = percent_customers base cumulative_lift individual_lift);
			      retain percent_customers base cumulative_lift individual_lift;
			      set out.ks_out;
			      percent_customers = (rank_pred + 1)*10;
			      base = 1;
			      cumulative_lift = pctresp/percent_customers;
			      individual_lift = percent_events/10;
			      run;

	    %exportCsv(libname=work,dataset= lift,filename=lift);
		
	          data gains (keep = percent_customers random percent_positive_response);
	               retain percent_customers random percent_positive_response;
	               set out.ks_out;
	               percent_customers = (rank_pred + 1)*10;
	               random = percent_customers;
	               rename pctresp = percent_positive_response;
	               run;

	    %exportCsv(libname=work,dataset= gains,filename=gains);
		%end;
	%end;
%mend;


%macro dependence3();
	%if &flagRunLogit. = true %then %do;
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
		                        end;
	                            else do;
	                              rhs = "";
	                         	end;
	                      	end; 
		                    else do;
		                    	  rhs = strip(coefficient) || " * " ||strip(Term);
		             		end;
		               end;
	                  lhs = LeftHandSide;
	              end;
	/* When adding to the rhs, put a + sign if it is not the first variable Put a + sign if the coefficient is positive;
	            If it is negative, coefficient will carry the - sign */
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
			  %exportCsv(libname=work,dataset= dependence_equations_final,filename= validation);
	      %end;
	%end;
%mend dependence3;

%macro endlog;
/* Flex uses this file to test if the code has finished running */
data _NULL_;
      v1= "Logistic Regression - MANUAL_REGRESSION_COMPLETED";
      file "&outputPath./MANUAL_REGRESSION_COMPLETED.txt";
      PUT v1;
      run;
%mend;

%macro execute2;
	%if &flagRunLogit. = true %then %do;
		%classcheck;
		%chk_obs;
		%ks_test_var;
		%logistic;
		%missing2;
		%varelim;
		%association;
		%lackfit;
		%rsq;
		dm output 'clear';
		%modelinfo;
		%nob;
		%resprofile;
		%covergence;
		%fitstat;
		%globalstat;
		%goodfit;
		%overallstats;
		%VIF2;
		%export4;
		%roc1;
		%rocs;
		%predact;
		%ks;
	%end;
	%VIF2;
	%dependence3();
	%endlog;
%mend;
%execute2;
