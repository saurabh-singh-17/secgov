/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &ex_output_path./unbiased_&beta._&data._completed.txt &outputpath./UNBIASED_VALIDATION_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;

proc printto log="&outputpath./UnbiasedValidation_Log.log";
run;
quit;

/*proc printto print="&outputpath./UnbiasedValidation_Output.out";*/

dm log 'clear';
%let datasetname=in.dataworking;
libname in "&inputpath.";
libname group "&grouppath.";
libname out "&outputpath.";

FILENAME MyFile "D:/proma.txt" ;

  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;
%MACRO regression7;
%if "&flagrunlogit." = "true" %then %do; 
	%if "&flagbygrpupdate." = "true" %then %do;
	/**This code is different from rest of the updation codes**/
		proc sort data = in.dataworking;
			by primary_key_1644;
			run;

		proc sort data = &datasetname.;
			by primary_key_1644;
			run;

		data &datasetname.;
			merge &datasetname.(in=a) in.dataworking(in=b);
			by primary_key_1644;
			if a;
			run;
	%end;
%end;
/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/**/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/;
/*TYPE of DEPENDENT VARIABLE*/
 %let dsid = %sysfunc(open(in.dataworking));
 %let varnum = %sysfunc(varnum(&dsid,&dependentvariable.));
 %let typ_dep = %sysfunc(vartype(&dsid,&varnum)); /* variable type */
 %let rc = %sysfunc(close(&dsid));
			%put &typ_dep;

	data &datasetname.;
			length XXXind_logit YYYind_logit 8.;
		set &datasetname.;
			%if &typ_dep. = N %then %do;
				if &dependentvariable. = &event. then XXXind_logit = 0; else XXXind_logit = 1;
			%end;
			%if &typ_dep. = C %then %do;
				if &dependentvariable. = "&event." then XXXind_logit = 0; else XXXind_logit = 1;
			%end;
			YYYind_logit = 1 - XXXind_logit;
		run;

%let num1 = 1;
%do %until (not %length(%scan(&betas, &num1)));
	
	data _null_;
		call symput("beta", "%scan(&betas, &num1)");
		run;

	%let datasets = &&&beta.;
	%put &datasets;

	%if "&flagrunlogit." = "true" %then %do; 
		%if "&beta" = "original" %then %do;
			%let beta_dataset = out_betas;
			libname betapath "&originalbetaspath.";
		%end;
		%if "&beta" = "average" %then %do;
			%let beta_dataset = outest_score;
			libname betapath "&averagebetaspath.";
		%end;

/*		libname betapath "&&&beta._betas_path.";*/
		data betas;
			set betapath.&beta_dataset;
			run;

		%if "&flagalphacorrection." = "true" %then %do;
			data betas;
		    	set betas;
		        Intercept = Intercept + log((&actual. * (1 - (&oversample./100)))/((&oversample./100) * (1 - &actual.)));
		        run;
		%end;
	%end;

	%let num2 = 1;
	%do %until (not %length(%scan(&datasets, &num2)));

		data _null_;
			call symput("data", "%scan(&datasets, &num2)");
			run;

		%let ex_output_path = &outputpath./&beta./&data.;
		libname out "&ex_output_path.";

		%if "&flagrunlogit." = "true" %then %do; 
			%if "&data." = "validation" %then %do;
				%let valid_var = &validationvar.;
				%let indflag_val = 0;
			%end;
			%if "&data." = "dev" %then %do;
				%let valid_var = &validationvar.;
				%let indflag_val = 1;
			%end;
			%if "&data." = "dataset" %then %do;
				%let valid_var =;
				%let indflag_val =;
			%end;
			
			/*subset bygroupdata according to validation scene*/
			data bygroupdata;
				set &datasetname.;
				%if "&valid_var" ^= "" %then %do;
					where &valid_var. = %eval(&indflag_val.);
				%end;
				run;


			/*preparing the independent variables list according to the inest dataset*/
			proc transpose data = betas(keep=&independentvariables.) out=betas_trans(rename=(_name_=indep_var col1=beta_value));
				run;
			proc sql;
				select indep_var into :indep_vars separated by " " from betas_trans where beta_value ^= .;
				quit;
			%put &indep_vars;

	
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
			ods output Classification = out.C_table;
			ods output CorrB = corr;
			ods output OddsRatios = odds;
			ods output ParameterEstimates = params;
			ods output Type3 = type3;
			ods output GoodnessOfFit = goodness_of_fit;
			ods output RSquare = rsquare(keep=cvalue1 cvalue2);

			proc logistic data = bygroupdata inest = betas;
				%if "&classvariables." ^= "" %then %do;
					%let i = 1;
					%do %until (not %length(%scan(&classvariables, &i)));
						%let ref_var=%scan(&pref, &i);
						class %scan(&classvariables, &i) (ref = "&ref_var.")/ param = %scan(&param, &i) order = &classordertype. &classorderseq.;
						%let i = %eval(&i.+1);
					%end;
					model XXXind_logit (Event='0') = &indep_vars. &classvariables./stb link = &modeltype.
					corrb details lackfit ctable pprob = (0 to 1 by 0.001) outroc = out.roc scale = &scaleoption.  aggregate &regressionoptions.;
				%end;
				%else %do;
					model XXXind_logit (Event='0') = &indep_vars./stb link = &modeltype.
					corrb details lackfit ctable pprob = (0 to 1 by 0.001) outroc = out.roc scale = &scaleoption.  aggregate  &regressionoptions.;
				%end;
			    output out=out.pred p=phat PREDPROBS=i;
				%if "&weightvar." ^= "" %then %do;
					weight &weightvar. %if "&weightoption." ^= "" %then %do; /&weightoption. %end;;
				%end; 
				run;
			%if %sysfunc(exist(goodness_of_fit)) %then %do;
			    libname output xml "&ex_output_path./goodness_of_fit.xml";
			    data output.goodness_of_fit;
			      	set goodness_of_fit;
			        run;
			%end;
			%if %sysfunc(exist(rsquare)) %then %do;
				data rsquare (drop = cvalue1 cvalue2);
			    	set rsquare;
			        format Rsquare MaxRescaled_Rsquare 8.4;
			        Rsquare = input(cvalue1, $6.);
			        MaxRescaled_Rsquare = input(cvalue2, $6.);
			        run;
			%end;

			proc transpose data = model_info(keep= value description) out = model_info (keep = number_of_response_levels);
			    var value;
			    id  description;
			    run;

			data model_info(drop = number_of_response_levels rename = (num=number_of_response_levels));
			    set model_info;
			    format num 8.;
			    num = input (number_of_response_levels, $17.);
			    run;

			proc transpose data = nob(keep= N label) out = nob (drop = _name_);
				var N;
				id label;
				run;


			data response_profile;
				set response_profile (drop = OrderedValue);
				Outcome = catx("_", "num", Outcome);
				run;

			proc transpose data = response_profile(keep= count outcome) out = response_profile (drop = _name_);
				var count;
				id outcome;
				run;


			proc transpose data = convergence_status(keep= status reason) out = convergence_status (drop = _name_);
			      var status;
			      id reason;
			      run;


			proc transpose data = fit_stats(keep= criterion InterceptOnly) out = fit_stats1(drop = _name_ _label_ rename = (AIC=AIC_intercept SC=SC_intercept _2_Log_L=_2_Log_L_intercept));
			      var InterceptOnly;
			      id criterion;
			      run;

			proc transpose data = fit_stats(keep= criterion InterceptAndCovariates) out = fit_stats2(drop = _name_ _label_ rename = (AIC=AIC_intercept_covariates SC=SC_intercept_covariates _2_Log_L=_2_Log_L_intercept_covariates));
			      var InterceptAndCovariates;
			      id criterion;
			      run;

			proc transpose data = global_tests(keep= test ProbChiSq) out = global_tests(drop = _name_ _label_);
			      var ProbChiSq;
			      id test;
			      run;

			data association(drop = cvalue1 cvalue2 rename=(cvalue1_num=cvalue1 cvalue2_num=cvalue2));
			      set association;
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

			data lackfit_chisq;
			      set lackfit_chisq;
			      attrib _all_ label = " ";
			      run;

			libname output xml "&ex_output_path./lackfit_chisq.xml";
			data output.lackfit_chisq;
			      set lackfit_chisq;
			      run;

			data lackfit_chisq (keep = ProbChiSq rename = (ProbChiSq = HL_ProbChiSq));
			      set lackfit_chisq;
			      attrib ProbChiSq label = " ";
			      run;

			data goodness_of_fit;
				length criterion $20.;
				set goodness_of_fit(keep=criterion ProbChiSq);
				criterion = cats("ProbChiSq_", criterion);
				run;

			proc transpose data = goodness_of_fit out = goodness_of_fit(drop=_name_ _label_);
				var ProbChiSq;
				id criterion;
				run;
				

			data overall_stats;
			      merge model_info nob response_profile convergence_status fit_stats1 fit_stats2 global_tests association1 association2 %if %sysfunc(exist(rsquare)) %then %do;rsquare %end; lackfit_chisq goodness_of_fit;
			      run;

			proc transpose data = overall_stats out = out.overall_stats (rename = (_name_ = test col1 = output_values));
			      run;

			libname output xml "&ex_output_path./overall_stats.xml";
			data output.overall_stats;
			      set out.overall_stats;
			      run;

			proc export data = output.overall_stats
			      outfile="&ex_output_path./overall_stats.csv"
				  dbms=csv replace;
				  run;

			data overallstats_final(rename=(GROUPING=Statistic OUTPUT_VALUES=Value));
			   set output.overall_stats;
			   run;

	 /*  Macro to create csv according to template */
		%macro names_overallstats;

		  %let dsid=%sysfunc(open(overallstats_final));
		  %let varlist=;
		  %do i=1 %to %sysfunc(min(20,%sysfunc(attrn(&dsid,nvars))));
		  		%let varlist=&varlist %sysfunc(varname(&dsid,&i));
		  %end;
		  %put varlist=&varlist;
		  %let template=Statistic Value;
		  %put template=&template;
		  %let final =;
          %do j=1 %to %sysfunc(countw("&template",' '));
				%let word=%scan(&template.,&j);
			    %do k=1 %to %sysfunc(countw("&varlist",' '));
				   	%let word2 = %scan(&varlist.,&k.);
				  	%if "&word."="&word2." %then %do; 
						%let final= &final. &word.;
						%put &final.;
				    %end;
				%end;
			%end;
	
    	data _null_;
	    	call symput("final1",tranwrd("&final.",' ',','));
		    run;
            %put &final1; 
   

	  proc sql;
	 	 create table overallstats_table as
	 	 select &final1. from overallstats_final;
         quit; 

 			proc export data = overallstats_table
	      outfile="&outputpath/overall_stats.csv"
		  dbms=csv replace;
		  run;

 %let ds=%sysfunc(close(&dsid.));
	 %mend names_overallstats;
	 %names_overallstats; 


			libname output xml "&ex_output_path./hl_partition_test.xml";
			data output.hl_partition_test;
			      set hl_partition_test;
			      run;


			%if %sysfunc(exist(type3)) %then %do;
				libname output xml "&ex_output_path./type3.xml";
			    data output.type3;
			    	set type3;
			        run;

			/*  Macro to create csv according to template */
				%macro names_type3;
				  %let dsid=%sysfunc(open(type3,i));
				  %let varlist=;
				  %do i=1 %to %sysfunc(min(20,%sysfunc(attrn(&dsid,nvars))));
				  		%let varlist=&varlist %sysfunc(varname(&dsid,&i));
				  %end;
				  %put varlist=&varlist;
				  %let template=Effect DF WaldChiSq ProbChiSq;
				  %put template=&template;
				  %let final =;
		          %do j=1 %to %sysfunc(countw("&template",' '));
						%let word=%scan(&template.,&j);
					    %do k=1 %to %sysfunc(countw("&varlist",' '));
						   	%let word2 = %scan(&varlist.,&k.);
						  	%if "&word."="&word2." %then %do; 
								%let final= &final. &word.;
								%put &final.;
						    %end;
						%end;
					%end;
			
			data _null_;
				call symput("final1",tranwrd("&final.",' ',','));
				run;
		         %put &final1; 


			  proc sql;
			 	 create table type3_table as
			 	 select &final1. from type3
		         quit; 
		 
			   proc export data = type3_table
			       outfile="&outputpath./type3.csv"
				   dbms=csv replace;
				   run; 
		      
		        %let ds=%sysfunc(close(&dsid.));

			 %mend names_type3;
			 %names_type3;

			%end;

			libname output xml "&ex_output_path./odds.xml";
			      data output.odds;
			            set odds;
			            run;  

			proc export data = output.odds
			    outfile="&ex_output_path./odds.csv"
			 	dbms=csv replace;
			 	run;

			/*  Macro to create csv according to template */
%macro names_odds;
		  %let dsid=%sysfunc(open(odds));
		  %let varlist=;
		  %do i=1 %to %sysfunc(min(20,%sysfunc(attrn(&dsid,nvars))));
		  		%let varlist=&varlist %sysfunc(varname(&dsid,&i));
		  %end;
		  %put varlist=&varlist;
		  %let template=Effect OddsRatioEst LowerCL UpperCL ;
		  %put template=&template;
		  %let final =;
          %do j=1 %to %sysfunc(countw("&template",' '));
				%let word=%scan(&template.,&j);
			    %do k=1 %to %sysfunc(countw("&varlist",' '));
				   	%let word2 = %scan(&varlist.,&k.);
				  	%if "&word."="&word2." %then %do; 
						%let final= &final. &word.;
						%put &final.;
				    %end;
				%end;
			%end;
	
	data _null_;
		call symput("final1",tranwrd("&final.",' ',','));
		run;
         %put &final1; 


	  proc sql;
	 	 create table odds_table as
	 	 select &final1. from odds;
         quit; 
 
	 proc export data = odds_table
		    outfile="&outputpath/odds.csv"
		 	dbms=csv replace;
		 	run;
 %let ds=%sysfunc(close(&dsid.));
	 %mend names_odds;
	 %names_odds; 
 

			proc export data = corr
			      outfile = "&ex_output_path./corr.csv"
			      dbms = CSV replace;
			      run;


			proc export data = out.C_table
			      outfile = "&ex_output_path./classification_table.csv"
			      dbms = CSV replace;
			      run;

		/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/* Flag for VIF */*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/;
			
			%if "&flagvif." = "true" %then %do;
				ods output ParameterEstimates = p_vif(keep= Variable VarianceInflation);
			  	proc reg data = &datasetname.;
			        model YYYind_logit = &indep_vars./vif;
			        run;

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
			%end;

			libname output xml "&ex_output_path./parameter_estimates.xml";
			data output.params;
			      set params;
			      run;

			proc export data = output.params
			      outfile = "&ex_output_path./parameter_estimates.csv"
			      dbms = CSV replace;
			      run;


			  /*  Macro to create csv according to template */
					%macro names1;
					  %let dsid=%sysfunc(open(params));
					  %let varlist=;
					  %do i=1 %to %sysfunc(min(20,%sysfunc(attrn(&dsid,nvars))));
					  		%let varlist=&varlist %sysfunc(varname(&dsid,&i));
					  %end;
					  %put varlist=&varlist;
					  %let template=Variable DF Estimate StdErr WaldChiSq ProbChiSq;
					  %put template=&template;
					  %let final =;
			          %do j=1 %to %sysfunc(countw("&template",' '));
							%let word=%scan(&template.,&j);
						    %do k=1 %to %sysfunc(countw("&varlist",' '));
							   	%let word2 = %scan(&varlist.,&k.);
							  	%if "&word."="&word2." %then %do; 
									%let final= &final. &word.;
									%put &final.;
							    %end;
							%end;
						%end;
				
				data _null_;
					call symput("final1",tranwrd("&final.",' ',','));
					run;
			         %put &final1; 


				  proc sql;
				 	 create table params_table as
				 	 select &final1. from params
			         quit; 
			 
				   proc export data = params_table
				       outfile="&outputpath/parameter_estimates.csv"
					   dbms=csv replace;
					   run; 
			  %let ds=%sysfunc(close(&dsid.));
			      
				 %mend names1;
				  %names1;

		%end;


		/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*end*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/;

		%if "&flagroc1." = "true" %then %do;
			data roc1 (drop = Specificity Sensitivity rename = (_SENSITIVITY_ = SENSITIVITY));
				set out.c_table (keep = Sensitivity Specificity);
				ONE_MINUS_SPECIFICITY = (1-(Specificity/100));
				_SENSITIVITY_ = (Sensitivity/100);
				run;

			proc export data = roc1
			      outfile = "&ex_output_path./roc1.csv"
			      dbms = CSV replace;
			      run;
		%end;

		%if "&flagrocs." = "true" %then %do;
			data roc_s (drop = Sensitivity Specificity rename = (ProbLevel = _PROB_ _SENSITIVITY_ = SENSITIVITY _SPECIFICITY_ = SPECIFICITY));
				set out.c_table (keep = ProbLevel Sensitivity Specificity);
				_SENSITIVITY_ = (Sensitivity/100);
				_SPECIFICITY_ = (Specificity/100);
				run;

			proc export data = roc_s
			    outfile = "&ex_output_path./roc_s.csv"
			    dbms = CSV replace;
			    run;
		%end;



	/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*Drawing Predicted v/s Actual curves*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/;
		%if "&flagactpred." = "true" %then %do;
			proc rank data = out.pred out = testpred (keep = deciles phat _FROM_) Groups = %sysevalf(&numgroups.) descending ;
			    var phat;
			    ranks deciles;
			    run;

			proc sort data = testpred;
			    by deciles;
			    run;

			proc sql;
			    create table predicted_actual as
			    select deciles, avg(phat)*100 as predicted, (sum(CASE WHEN _FROM_="0" THEN 1 ELSE 0 END)/count(*))*100 as actual
				from testpred
			    group by deciles;
				quit;
			proc sql;
			    create table predicted_actual as
			    select deciles, predicted, actual, avg(actual) as average_rate, (predicted/actual) as pred_by_actual
				from predicted_actual
			    quit;quit;

			proc export data = predicted_actual 
			    outfile = "&ex_output_path/predicted_actual.csv"
			    dbms = CSV replace;
			    run;

			/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*calculating average churn rate*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/;

			proc sql;
			      create table average_rate as
			      select avg(actual) as average_rate
			      from predicted_actual;
			      quit;

			libname output xml "&outputpath/average_rate.xml";
			data output.average_rate;
			      set average_rate;
			      run;
		%end;



/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*KS TEST*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/;
		%if "&flagkstest." = "true" or "&flaglift." = "true" or "&flaggains." = "true" %then %do;
			data ks_main;
				set out.pred (keep=phat XXXind_logit);
				V_GOOD=XXXind_logit;
				V_BAD=1-XXXind_logit;
				run;

			proc rank data=ks_main out=ks_rankpred groups=%eval(&numgrps.) descending;
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
				%do i = 1 %to %eval(&numgrps. - 1);
				%let j = %eval(&i + 1);
					order_flag = order_flag + (col&i lt col&j);
				%end ;
				if order_flag gt 0 then ranking = 'NOT SATISFACTORY'; 
					else ranking = 'SATISFACTORY';
				sat_rank = 'ALL';
				%do i = 1 %to %eval(&numgrps. - 1);
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
			
			libname overout xml "&ex_output_path./ks_rep.xml";
			data overout.ks_rep;
				set out.ks_rep;
				run;

			proc export data = overout.ks_rep
			      outfile="&ex_output_path./ks_rep.csv"
				  dbms=csv replace;
				  run;
		
			libname ksout xml "&ex_output_path./ks_out.xml";
			data ksout.ks_out;
				set out.ks_out;
				run;

			proc export data = ksout.ks_out
			      outfile="&ex_output_path./ks_out.csv"
				  dbms=csv replace;
				  run;


			 data out.ks_out1(rename=(rank_pred = Rank count_events=Count_Events percent_events=Percent_Events count_nonevents= Count_Nonevents percent_nonevents=Percent_Nonevents 
                                     count_accts=Count_Actual percent_accts=Percent_Actual cumm_accts=Cumulative_Actual pred_resp=Predicted_Respondents act_resp=Actual_Respondents 
                                     minimum=Minimum maximum=Maximum cumm_respr=Cumulative_Respondent_Rate cumresp=Cumulative_Respondents pctresp=Cumulative_Percent_Respondents ks=KS gof=GOF gini=Gini));
		   set out.ks_out;
		   run;


/*  Macro to create csv according to template */
		%macro names_ksout;

		  %let dsid=%sysfunc(open(out.ks_out1));
		  %let varlist=;
		  %do i=1 %to %sysfunc(min(20,%sysfunc(attrn(&dsid,nvars))));
		  		%let varlist=&varlist %sysfunc(varname(&dsid,&i));
		  %end;
		  %put varlist=&varlist;
		  %let template=Rank Count_Events Percent_Events Count_Nonevents Percent_Nonevents Count_Actual Percent_Actual Cumulative_Actual Predicted_Respondents Actual_Respondents 
                        Minimum Maximum Cumulative_Respondent_Rate Cumulative_Respondents Cumulative_Percent_Respondents KS GOF Gini;
		  %put template=&template;
		  %let final =;
          %do j=1 %to %sysfunc(countw("&template",' '));
				%let word=%scan(&template.,&j);
			    %do k=1 %to %sysfunc(countw("&varlist",' '));
				   	%let word2 = %scan(&varlist.,&k.);
				  	%if "&word."="&word2." %then %do; 
						%let final= &final. &word.;
						%put &final.;
				    %end;
				%end;
			%end;
	
	data _null_;
		call symput("final1",tranwrd("&final.",' ',','));
		run;
         %put &final1; 


	  proc sql;
	 	 create table ksout_table as
	 	 select &final1. from out.ks_out1;
         quit; 

 	proc export data = ksout_table
		    outfile="&outputpath./ks_out.csv"
		    dbms=csv replace;
		    run;

 %let ds=%sysfunc(close(&dsid.));
	 %mend names_ksout;
	 %names_ksout; 

			/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*drawing lift and gains charts*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/;

				data lift (keep = percent_customers base cumulative_lift individual_lift);
					retain percent_customers base cumulative_lift individual_lift;
					set out.ks_out;
					percent_customers = (rank_pred + 1)*10;
					base = 1;
					cumulative_lift = pctresp/percent_customers;
					individual_lift = percent_events/10;
					run;

				proc export data = lift
				    outfile = "&ex_output_path/lift.csv"
				    dbms = CSV replace;
				    run;
			
				data gains (keep = percent_customers random percent_positive_response);
					retain percent_customers random percent_positive_response;
					set out.ks_out;
					percent_customers = (rank_pred + 1)*10;
					random = percent_customers;
					rename pctresp = percent_positive_response;
					run;

				proc export data = gains 
					outfile = "&ex_output_path/gains.csv"
				    dbms = CSV replace;
				    run;

		%end;


		/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*end*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/;

		%if "&flagrunlogit." = "true" %then %do;
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

		   	 	/*Save the two datasets DependenceEquations & Null Values to the dataset*/
				FILENAME MyFile "&ex_output_path./validation_output" ;

				  DATA _NULL_ ;
				    rc = FDELETE('MyFile') ;
				  RUN ;
			    libname output xml "&ex_output_path./validation.xml";
			    data output.validation;
			        set dependence_equations_final;
			      run;

			%end;
		%end;

		data _NULL_;
			v1= "Logistic Regression - unbiased_&beta._&data._COMPLETED";
			file "&ex_output_path./unbiased_&beta._&data._completed.txt";
			PUT v1;
			run;

		%let num2 = %eval(&num2.+1);
	%end;

	%let num1 = %eval(&num1.+1);
%end; 
%MEND regression7;
%regression7;


/* Flex uses this file to test if the code has finished running */
data _NULL_;
      v1= "Logistic Regression - UNBIASED_VALIDATION_COMPLETED";
      file "&outputpath./UNBIASED_VALIDATION_COMPLETED.txt";
      PUT v1;
      run;

/*endsas;*/



