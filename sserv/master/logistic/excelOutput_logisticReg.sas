/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &model_path./&iteration./bootstrap/BOOTSTRAPPING_COMPLETED.txt &model_path./EXCEL_OUTPUT_LOGISTIC_REG_COMPLETED.txt;
Options mprint mlogic  noxsync symbolgen;


proc printto log="&model_path./ExcelOutput_LogisticReg_Log.log";
run;
quit;
/*proc printto print="&model_path./ExcelOutput_LogisticReg_Output.out";*/

FILENAME MyFile "&model_path./EXCEL_OUTPUT_LOGISTIC_REG_COMPLETED.txt" ;

  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;
%MACRO excelReport_logisticReg1;

%let i = 1;
%do %until (not %length(%scan(&out_iterations, &i)));

	data _null_;
		call symput("iteration", "%scan(&out_iterations, &i)");
		run;
	%put &iteration;

	data _null_;
		call symput("open_excelSheet", cats("put '[open(""&temp_excelSheet./output_logisticReg.xlsm"")]'"));
		call symput("save_excelSheet", cats("put '[save.as(""&output_excelSheet./output_logisticReg_&iteration..xlsm"")]'"));
		call symput("close_excelSheet", cats("put '[close(""&output_excelSheet./output_logisticReg_&iteration..xls"")]'"));
		call symput("finalSave_excelSheet", cats("put '[save.as(""&output_excelSheet./output_logisticReg_&iteration..xls"")]'"));
		run;
	%put &open_excelSheet; 
	%put &save_excelSheet;
	%put &close_excelSheet;


	/* INVOKE EXCEL */
	%if "&i." = "1" %then %do;
		x '"c:/program files/microsoft office/office12/excel.exe"';
		Data _null_;
			rc = sleep(7);
			Run;
	%end;

		/* open the workbook */
		Filename cmds dde 'excel|system';options xsync;
		Data _null_;
			file cmds;
			%if "&i." = "1" %then %do;
			put '[close("Book1")]';
			%end;
			&open_excelSheet.;
			&save_excelSheet.;
			Run;

	%let cases = build validation_val validation_entire unbiased_avg_val unbiased_avg_dev unbiased_avg_dat 
				unbiased_orig_val unbiased_orig_dev unbiased_orig_dat;
	%let del_no = 1;


	%let case_no = 1;
	%do %until (not %length(%scan(&cases, &case_no)));

		/*output_path*/
		%if "%scan(&cases, &case_no)" = "build" %then %do;
			%let in_path = &model_path./&iteration.;
			%let comp_txt = MANUAL_REGRESSION_COMPLETED.TXT;
		%end;
		%if "%scan(&cases, &case_no)" = "validation_val" %then %do;
			%let in_path = &model_path./&iteration./validation/validation;
			%let comp_txt = MANUAL_REGRESSION_COMPLETED.TXT;
		%end;
		%if "%scan(&cases, &case_no)" = "validation_entire" %then %do;
			%let in_path = &model_path./&iteration./validation/entire;
			%let comp_txt = MANUAL_REGRESSION_COMPLETED.TXT;
		%end;
		%if "%scan(&cases, &case_no)" = "unbiased_avg_val" %then %do;
			%let in_path = &model_path./&iteration./unbiased/average/validation;
			%let comp_txt = unbiased_average_validation_completed.txt;
		%end;
		%if "%scan(&cases, &case_no)" = "unbiased_avg_dat" %then %do;
			%let in_path = &model_path./&iteration./unbiased/average/dataset;
			%let comp_txt = unbiased_average_dataset_completed.txt;
		%end;
		%if "%scan(&cases, &case_no)" = "unbiased_avg_dev" %then %do;
			%let in_path = &model_path./&iteration./unbiased/average/dev;
			%let comp_txt = unbiased_average_dev_completed.txt;
		%end;
		%if "%scan(&cases, &case_no)" = "unbiased_orig_val" %then %do;
			%let in_path = &model_path./&iteration./unbiased/original/validation;
			%let comp_txt = unbiased_original_validation_completed.txt;
		%end;
		%if "%scan(&cases, &case_no)" = "unbiased_orig_dat" %then %do;
			%let in_path = &model_path./&iteration./unbiased/original/dataset;
			%let comp_txt = unbiased_original_dataset_completed.txt;
		%end;
		%if "%scan(&cases, &case_no)" = "unbiased_orig_dev" %then %do;
			%let in_path = &model_path./&iteration./unbiased/original/dev;
			%let comp_txt = unbiased_original_dev_completed.txt;
		%end;


		%if %sysfunc(fileexist(&in_path./&comp_txt.)) %then %do;

			Filename indfile dde 'excel|index!r1c1:r1c1' notab;
			data _null_;
				file indfile;
				put "%scan(&cases, &case_no)";
				run;


		/* STATISTICS */
			/* MODEL STATS */
				/*extract the data from XML into SAS dataset*/
				libname instats xml "&in_path./overall_stats.xml";
				data overall_stats;
					set instats.overall_stats;
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
	      outfile="&output_path/overall_stats.csv"
		  dbms=csv replace;
		  run;

 %let ds=%sysfunc(close(&dsid.));
	 %mend names_overallstats;
	 %names_overallstats; 





				data _null_;
			    	call symput ("fileref", "Filename statfile dde 'excel|%scan(&cases, &case_no)_model_stats!r4c2:r27c3' notab");
			        run;
			    %put &fileref;

				/* write to Excel workbook */
				&fileref.;
				data _null_;
					file statfile;
					set overall_stats;
					put test '09'x output_values;
					run;


			/* PARAMETER ESTIMATES */
				/*extract the data from XML into SAS dataset*/
				libname paraest xml "&in_path./parameter_estimates.xml";
				data para_est;
					set paraest.params;
					%if "&class_variables." = "" %then %do;
						classval0 = "-";
					%end;
					run;
				%macro names;
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
	       outfile="&output_path/parameter_estimates.csv"
		   dbms=csv replace;
		   run; 
  %let ds=%sysfunc(close(&dsid.));
      
	 %mend names;

	  %names;
				/*determine num_obs*/
				data _null_;
					set para_est nobs = num_obs;
					call symputx("para_obs",num_obs);
					stop;
					run;
				%put &para_obs;

				/*determine row & column limits*/
				%let ri = 4;	%let rf = %eval(&para_obs. + 3);	%let ci = 6;	%let cf = 12;
				data _null_;
			    	call symput ("fileref", "Filename parafile dde 'excel|%scan(&cases, &case_no)_model_stats!r&ri.c&ci.:r&rf.c&cf.' notab");
			        run;
			    %put &fileref;
				
				/* write to Excel workbook */
				&fileref.;
				data _null_;
					file parafile;
					set para_est;
					put variable '09'x classval0 '09'x DF '09'x estimate '09'x stderr '09'x waldchisq '09'x probchisq;
					run;


			/* TYPE-3 */
				%if "&class_variables." ^= "" %then %do;
				/*extract the data from XML into SAS dataset*/
					libname intype3 xml "&in_path./type3.xml";
					data type3;
						set intype3.type3;
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
	       outfile="&output_path./type3.csv"
		   dbms=csv replace;
		   run; 
      
        %let ds=%sysfunc(close(&dsid.));

	 %mend names_type3;
	 %names_type3;



				/*determine num_obs*/
					data _null_;
						set type3 nobs = num_obs;
						call symputx("type_obs",num_obs);
						stop;
						run;
					%put &type_obs;

				/*determine row & column limits*/
					%let ri = 33;	%let rf = %eval(&type_obs. + &ri.);	%let ci = 2;	%let cf = 5;
					
					data _null_;
				    	call symput ("fileref", "Filename typefile dde 'excel|%scan(&cases, &case_no)_model_stats!r&ri.c&ci.:r&rf.c&cf.' notab");
				        run;
				    %put &fileref;
					
				/* write to Excel workbook */
					&fileref;
					data _null_;
						file typefile;
						set type3;
						put effect '09'x DF '09'x waldchisq '09'x probchisq;
						run;
				%end;


			/* ODDS */
				/*extract the data from XML into SAS dataset*/
					libname inodds xml "&in_path./odds.xml";
					data odds;
						set inodds.odds;
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
		    outfile="&output_path/odds.csv"
		 	dbms=csv replace;
		 	run;
 %let ds=%sysfunc(close(&dsid.));
	 %mend names_odds;
	 %names_odds; 


				/*determine num_obs*/
					data _null_;
						set odds nobs = num_obs;
						call symputx("odds_obs",num_obs);
						stop;
						run;
					%put &odds_obs;

				/*determine row & column limits*/
					%let ri = 4;	%let rf = %eval(&odds_obs. + 3);	%let ci = 15;	%let cf = 18;
					
					data _null_;
				    	call symput ("fileref", "Filename oddsfile dde 'excel|%scan(&cases, &case_no)_model_stats!r&ri.c&ci.:r&rf.c&cf.' notab");
				        run;
				    %put &fileref;

				/* write to Excel workbook */
					&fileref;
					data _null_;
						file oddsfile;
						set odds;
						put effect '09'x oddsratioest '09'x lowercl '09'x uppercl;
						run;


			/* CLASSIFICAION TABLE */
				/*extract the data from XML into SAS dataset*/
					proc import datafile = "&in_path./classification_table.csv"
						out = c_table
						dbms = csv replace;
						run;

				/*determine num_obs*/
					data _null_;
						set c_table nobs = num_obs;
						call symputx("ctable_obs",num_obs);
						stop;
						run;
					%put &ctable_obs;

				/*determine row & column limits*/
					%let ri = 4;	%let rf = %eval(&ctable_obs. + 3);	%let ci = 21;	%let cf = 30;
					
					data _null_;
				    	call symput ("fileref", "Filename ctabfile dde 'excel|%scan(&cases, &case_no)_model_stats!r&ri.c&ci.:r&rf.c&cf.' notab");
				        run;
				    %put &fileref;

				/* write to Excel workbook */
					&fileref;
					data _null_;
						file ctabfile;
						set c_table;
						put ProbLevel '09'x CorrectEvents '09'x CorrectNonevents '09'x IncorrectEvents '09'x 
							IncorrectNonevents '09'x Correct '09'x Sensitivity '09'x Specificity '09'x FalsePositive '09'x FalseNegative;
						run;


			/* CORRELATION */
				/*extract data from csv into SAS dataset*/
					proc import datafile = "&in_path./corr.csv"
						out = corr
						dbms = csv replace;
						run;

				/*get number of variables*/
					proc contents data = corr out = contents_corr(keep=name varnum);
						run;
					proc sort data = contents_corr out = contents_corr;
						by varnum;
						run;
					proc sql;
						select name into :corr_varnames separated by " " from contents_corr;
						select count(name) into :corr_vars from contents_corr;
						quit;
					%put &corr_varnames &corr_vars;

				/*determine num_obs*/
					data _null_;
						set corr nobs = num_obs;
						call symputx("corr_obs",num_obs);
						stop;
						run;
					%put &corr_obs;

					data _null_;
				    	call symput ("cr_vars", tranwrd("&corr_vars.", " ", ""));
						run;
				    %put &cr_vars;

				/*put corr_vars into groups of 10*/
					%let k = 0;
					%let q = 1;
					%do %until (not %length(%scan(&corr_varnames., &q.)));

						data _null_;
							call symput("z", compress(ceil(&q./10)));
							run;

						%if "&z." ^= "&k." %then %do;
							data _null_;
								call symput("varlist&z.", "%scan(&corr_varnames., &q.)");
								run;
						%end;
						%else %do;
							data _null_;
								call symput("varlist&z.", cats("&&varlist&z..", ",", "%scan(&corr_varnames., &q.)"));
								run;
						%end;

						%let k = %eval(&z.);
						%let q = %eval(&q.+1);
					%end;

					/*put the corr_vars in excel*/
					%let q = 1;
					%do %until (%eval(&q.) > %eval(&z.));
						 data _null_;
						 	call symput("put_varsCorr", tranwrd("&&varlist&q..", ",", " '09'x "));
							call symput ("fileref", "Filename corrfile dde 'excel|%scan(&cases, &case_no)_model_stats!r4c%eval(33+%eval(10*%eval(&q.-1))):r%eval(&corr_obs.+3)c%eval(42+%eval(10*%eval(&q.-1)))' notab");
						    run;
						%put &put_varsCorr;
						%put &fileref;
						
						&fileref;
						data _null_;
						file corrfile;
							set corr;
							put &put_varsCorr.;
							run;
						%let q = %eval(&q.+1);
					%end;


				/*parameter file for excel*/	
					%let ri = 2;	%let rf = %eval(&corr_vars. + 1);	%let ci = 31;	%let cf = 31;
					data _null_;
				    	call symput ("fileref", "Filename crrfile dde 'excel|%scan(&cases, &case_no)_model_stats!r&ri.c&ci.:r&rf.c&cf.' notab");
						run;
				    %put &corr_putvars &fileref;

					&fileref;
					data _null_;
						file crrfile;
						set contents_corr;
						put name;
						run;

					%let ri = 1;	%let rf = 1;	%let ci = 31;	%let cf = 32;
					data _null_;
				    	call symput ("fileref", "Filename crfile dde 'excel|%scan(&cases, &case_no)_model_stats!r&ri.c&ci.:r&rf.c&cf.' notab");
						run;
				    %put &fileref;

					&fileref.;
					data _null_;
						file crfile;
						put "&cr_vars.";
						run;

				/*run Macro*/
				Filename cmds dde 'excel|system';options xsync;
				Data _null_;
					file cmds;
					put '[RUN("corr_label")]';
					run;
					
	/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
				
		/* OUTPUT */
			/* LIFT CHART */
				%if %sysfunc(fileexist(&in_path./lift.csv)) %then %do;
					proc import datafile = "&in_path./lift.csv"
						out = lift
						dbms = csv replace;
						run;

					/*determine num_obs*/
					data _null_;
						set lift nobs = num_obs;
						call symputx("lift_obs",num_obs);
						stop;
						run;
					%put &lift_obs;

					/*determine row & column limits*/
					%let ri = 4;	%let rf = %eval(&lift_obs. + 3);	%let ci = 2;	%let cf = 5;
						
					data _null_;
					   	call symput ("fileref", "Filename liftfile dde 'excel|%scan(&cases, &case_no)_output!r&ri.c&ci.:r&rf.c&cf.' notab");
						run;
					%put &fileref;

					/* write to Excel workbook */
					&fileref;
					data _null_;
						file liftfile;
						set lift;
						put percent_customers '09'x base '09'x cumulative_lift '09'x individual_lift;
						run;
				%end;


			/* GAINS CHART */
				%if %sysfunc(fileexist(&in_path./gains.csv)) %then %do;
					proc import datafile = "&in_path./gains.csv"
						out = gains
						dbms = csv replace;
						run;

					/*determine num_obs*/
					data _null_;
						set gains nobs = num_obs;
						call symputx("gain_obs",num_obs);
						stop;
						run;
					%put &lift_obs;

					/*determine row & column limits*/
					%let ri = 4;	%let rf = %eval(&gain_obs. + 3);	%let ci = 8;	%let cf = 10;
						
					data _null_;
					   	call symput ("fileref", "Filename gainfile dde 'excel|%scan(&cases, &case_no)_output!r&ri.c&ci.:r&rf.c&cf.' notab");
						run;
					%put &fileref;

					/* write to Excel workbook */
					&fileref;
					data _null_;
						file gainfile;
						set gains;
						put percent_customers '09'x random '09'x percent_positive_response;
						run;
				%end;


			/* ROC */
				%if %sysfunc(fileexist(&in_path./roc1.csv)) %then %do;
					proc import datafile = "&in_path./roc1.csv"
						out = roc1
						dbms = csv replace;
						run;

					/*determine num_obs*/
					data _null_;
						set roc1 nobs = num_obs;
						call symputx("roc1_obs",num_obs);
						stop;
						run;
					%put &roc1_obs;

					/*determine row & column limits*/
					%let ri = 4;	%let rf = %eval(&roc1_obs. + 3);	%let ci = 13;	%let cf = 14;
						
					data _null_;
					   	call symput ("fileref", "Filename roc1file dde 'excel|%scan(&cases, &case_no)_output!r&ri.c&ci.:r&rf.c&cf.' notab");
						run;
					%put &fileref;

					/* write to Excel workbook */
					&fileref;
					data _null_;
						file roc1file;
						set roc1;
						put one_minus_specificity '09'x sensitivity;
						run;
				%end;


			/* ROC_S */
				%if %sysfunc(fileexist(&in_path./roc_s.csv)) %then %do;
					proc import datafile = "&in_path./roc_s.csv"
						out = roc_s
						dbms = csv replace;
						run;

					/*determine num_obs*/
					data _null_;
						set roc_S nobs = num_obs;
						call symputx("rocs_obs",num_obs);
						stop;
						run;
					%put &rocs_obs;

					/*determine row & column limits*/
					%let ri = 4;	%let rf = %eval(&rocs_obs. + 3);	%let ci = 17;	%let cf = 19;
						
					data _null_;
					   	call symput ("fileref", "Filename rocsfile dde 'excel|%scan(&cases, &case_no)_output!r&ri.c&ci.:r&rf.c&cf.' notab");
						run;
					%put &fileref;

					/* write to Excel workbook */
					&fileref;
					data _null_;
						file rocsfile;
						set roc_s;
						put _prob_ '09'x sensitivity '09'x specificity;
						run;
				%end;


			/* ACTUAL vs PREDICTED */
				%if %sysfunc(fileexist(&in_path./predicted_actual.csv)) %then %do;
					proc import datafile = "&in_path./predicted_actual.csv"
						out = predact
						dbms = csv replace;
						run;

					/*determine num_obs*/
					data _null_;
						set predact nobs = num_obs;
						call symputx("pred_obs",num_obs);
						stop;
						run;
					%put &pred_obs;

					/*determine row & column limits*/
					%let ri = 4;	%let rf = %eval(&pred_obs. + 3);	%let ci = 22;	%let cf = 26;
						
					data _null_;
					   	call symput ("fileref", "Filename predfile dde 'excel|%scan(&cases, &case_no)_output!r&ri.c&ci.:r&rf.c&cf.' notab");
						run;
					%put &fileref;

					/* write to Excel workbook */
					&fileref;
					data _null_;
						file predfile;
						set predact;
						put deciles '09'x predicted '09'x actual '09'x average_rate '09'x pred_by_actual;
						run;
				%end;

				/*run Macro*/
					Filename cmds dde 'excel|system';options xsync;
					Data _null_;
						file cmds;
						put '[RUN("output_charts")]';
						run;

			/*KS TEST*/
				%if %sysfunc(fileexist(&in_path./ks_out.xml)) %then %do;
					libname ksin xml "&in_path./ks_out.xml";
					data ks_out;
						set ksin.ks_out;
						run;
					
						
	data out.ks_out1(rename=(rank_pred = Rank count_events=Count_Events percent_events=Percent_Events count_nonevents= Count_Nonevents percent_nonevents=Percent_Nonevents 
                                        count_accts=Count_Actual percent_accts=Percent_Actual cumm_accts=Cumulative_Actual pred_resp=Predicted_Respondents act_resp=Actual_Respondents minimum=Minimum 
                                        maximum=Maximum cumm_respr=Cumulative_Respondent_Rate cumresp=Cumulative_Respondents pctresp=Cumulative_Percent_Respondents ks=KS gof=GOF gini=Gini));
		 set out.ks_out;
		 run;


	%macro names_ksout;

		  %let dsid=%sysfunc(open(out.ks_out1));
		  %let varlist=;
		  %do i=1 %to %sysfunc(min(20,%sysfunc(attrn(&dsid,nvars))));
		  		%let varlist=&varlist %sysfunc(varname(&dsid,&i));
		  %end;
		  %put varlist=&varlist;
		  %let template=Rank Count_Events Percent_Events Count_Nonevents Percent_Nonevents Count_Actual Percent_Actual 
                        Cumulative_Actual Predicted_Respondents Actual_Respondents Minimum Maximum Cumulative_Respondent_Rate Cumulative_Respondents Cumulative_Percent_Respondents KS GOF Gini;
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

	/*Export file as csv*/
 	proc export data = ksout_table
		    outfile="&output_path./ks_out.csv"
		    dbms=csv replace;
		    run;
	 %let ds=%sysfunc(close(&dsid.));
	 %mend names_ksout;
	 %names_ksout; 

	
					/*determine num_obs*/
					data _null_;
						set ks_out nobs = num_obs;
						call symputx("ks_obs",num_obs);
						stop;
						run;
					%put &pred_obs;

					/*determine row & column limits*/
					%let ri = 4;	%let rf = %eval(&ks_obs. + 3);	%let ci = 29;	%let cf = 45;
						
					data _null_;
					   	call symput ("fileref", "Filename ksfile dde 'excel|%scan(&cases, &case_no)_output!r&ri.c&ci.:r&rf.c&cf.' notab");
						run;
					%put &fileref;

					/* write to Excel workbook */
					&fileref;
					data _null_;
						file ksfile;
						set ks_out;
						put RANK_PRED '09'x COUNT_NONEVENTS '09'x PERCENT_NONEVENTS '09'x COUNT_EVENTS '09'x PERCENT_EVENTS
							'09'x COUNT_ACCTS '09'x PERCENT_ACCTS '09'x CUMM_ACCTS '09'x PRED_RESP '09'x ACT_RESP '09'x 
							MINIMUM '09'x MAXIMUM '09'x CUMM_RESPR '09'x CUMRESP '09'x PCTRESP '09'x KS '09'x GOF;
						run;
				%end;
				

	/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

		/* BOOTSTRAPPING */
			%if "%scan(&cases, &case_no)" = "build" %then %do;
				%if %sysfunc(fileexist(&model_path./&iteration./bootstrap/BOOTSTRAPPING_COMPLETED.txt)) %then %do;
				/* ASSOCIATION REPORT */
					proc import datafile = "&in_path./bootstrap/association_report.csv"
						out = asso_report
						dbms = csv replace;
						run;

					/*determine num_obs*/
					data _null_;
						set asso_report nobs = num_obs;
						call symputx("asso_obs",num_obs);
						stop;
						run;
					%put &asso_obs;

					/*determine row & column limits*/
					%let ri = 4;	%let rf = %eval(&asso_obs. + 3);	%let ci = 2;	%let cf = 8;
						
					data _null_;
					   	call symput ("fileref", "Filename assofile dde 'excel|bootstrapping!r&ri.c&ci.:r&rf.c&cf.' notab");
						run;
					%put &fileref;

					/* write to Excel workbook */
					&fileref;
					data _null_;
						file assofile;
						set asso_report;
						put  iteration '09'x Label1 '09'x cValue1 '09'x nValue1 '09'x Label2 '09'x cValue2 '09'x nValue2;
						run;


				/* HOSMER REPORT */
					proc import datafile = "&in_path./bootstrap/hosmer_report.csv"
						out = hosmer_report
						dbms = csv replace;
						run;

					/*determine num_obs*/
					data _null_;
						set hosmer_report nobs = num_obs;
						call symputx("hosm_obs",num_obs);
						stop;
						run;
					%put &hosm_obs;

					/*determine row & column limits*/
					%let ri = 4;	%let rf = %eval(&hosm_obs. + 3);	%let ci =11;	%let cf = 14;
						
					data _null_;
					   	call symput ("fileref", "Filename hosmfile dde 'excel|bootstrapping!r&ri.c&ci.:r&rf.c&cf.' notab");
						run;
					%put &fileref;

					/* write to Excel workbook */
					&fileref;
					data _null_;
						file hosmfile;
						set hosmer_report;
						put iteration '09'x ChiSq '09'x DF '09'x ProbChiSq;
						run;


				/* PARAMS REPORT */
					proc import datafile = "&in_path./bootstrap/param_report.csv"
						out = param_report
						dbms = csv replace;
						run;

					%if "&class_variables." = "" %then %do;
						data param_report;
							set param_report;
							classval0 = "-";
							run;
					%end;

					/*determine num_obs*/
					data _null_;
						set param_report nobs = num_obs;
						call symputx("parm_obs",num_obs);
						stop;
						run;
					%put &parm_obs;

					/*determine row & column limits*/
					%let ri = 4;	%let rf = %eval(&parm_obs. + 3);	%let ci = 17;	%let cf = 29;
						
					data _null_;
					   	call symput ("fileref", "Filename parmfile dde 'excel|bootstrapping!r&ri.c&ci.:r&rf.c&cf.' notab");
						run;
					%put &fileref;

					/* write to Excel workbook */
					&fileref;
					data _null_;
						file parmfile;
						set param_report;
						put Variable '09'x ClassVal0 '09'x avg_Estimate '09'x num_neg_estimates '09'x num_pos_estimates '09'x max_estimate '09'x min_estimate '09'x stddev_estimate '09'x var_estimate '09'x max_lowercl '09'x max_uppercl '09'x min_lowercl '09'x min_uppercl;
						run;


					%let ri = 4;	%let rf = %eval(&parm_obs. + 3);	%let ci = 30;	%let cf = 40;
						
					data _null_;
					   	call symput ("fileref", "Filename parmfile dde 'excel|bootstrapping!r&ri.c&ci.:r&rf.c&cf.' notab");
						run;
					%put &fileref;

					/* write to Excel workbook */
					&fileref;
					data _null_;
						file parmfile;
						set param_report;
						put range_Estimate '09'x LowerCL '09'x UpperCL '09'x est_second_highest '09'x est_third_highest '09'x est_fourth_highest '09'x est_fifth_highest '09'x est_fourth_last '09'x est_third_last '09'x est_second_last '09'x est_last;
						run;
				%end;
				%else %do;
					Filename nbutfile dde 'excel|index!r3c2:r3c2' notab;
					data _null_;
						file nbutfile;
						put "NO";
						run;
				%end;
			%end;

	/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

		/* CATEGORIES */
			%if %sysfunc(fileexist(&in_path./category/1)) %then %do;
				%let cat_iter = 1;
				%do %until (%eval(&cat_iter.) = 0);
					
					%if %sysfunc(fileexist(&in_path./category/&cat_iter./predactual_Categories.csv)) %then %do;
						/* import dataset */
							proc import datafile = "&in_path./category/&cat_iter./predactual_Categories.csv"
								out = predact
								dbms = csv replace;
								run;

						%let dsid = %sysfunc(open(predact));
						%let varnum = %sysfunc(varnum(&dsid,grp_var));
						%let vartype = %sysfunc(vartype(&dsid,&varnum)); /* variable type */
						%let rc = %sysfunc(close(&dsid));
							%put &vartype;

						/* get distinct groups and count */
					        proc sql;
					            select distinct grp_var into :dist_grps separated by "!!" from predact;
					            select count(distinct grp_var) into :num_grps from predact;
								select count(distinct deciles) into :pred_obs from predact;
					            quit;
					        %put &dist_grps;
					        %put &num_grps &pred_obs;


						/* get distinct grp names into a dataset and pass as params to excel */
							proc sql;
								create table grp_names as
								select distinct grp_var from predact;
								quit;
							
							proc transpose data = grp_names out = grps(drop=_name_);
								var grp_var;
								run;

							proc contents data = grps out = grps_contents(keep=name);
								run;

							proc sql;
								select name into :grp_var separated by " '09'x " from grps_contents;
								run;
							%put &grp_var;
							
							%let ri = %eval(%eval(&cat_iter.*20)-19); %let rf = %eval(&ri); %let ci = 3; %let cf = %eval(&pred_obs.+&ci.);
							data _null_;
					        	call symput ("fileref", "Filename par1file dde 'excel|%scan(&cases, &case_no)_categories!r&ri.c&ci.:r&rf.c&cf.' notab");
					            run;
					        %put &fileref;

							&fileref.;
					        data _null_;
					            file par1file;
					            set grps;
					            put &grp_var.;
					            run;


						/* params dataset*/
					        data params;
					            num_grps = "&num_grps.";
					            dependent_var = "&dependent_variable.";
								num_rows = "&pred_obs.";
					            run;

					        proc transpose data = params out = params;
					            var num_grps dependent_var num_rows;
					            run;

							data _null_;
					        	call symput ("fileref", "Filename parrfile dde 'excel|%scan(&cases, &case_no)_categories!r%eval(%eval(&cat_iter.*20)-19)c1:r%eval(%eval(&cat_iter.*20)-17)c1' notab");
					            run;
					        %put &fileref;

							&fileref.;
					        data _null_;
					            file parrfile;
					            set params;
					            put col1;
					            run;

							%let k = 1;
					        %do %until (not %length(%scan(&dist_grps, &k, "!!")));

					            /* get no. of obs for group */
					            proc sql;
					                select count (grp_var) into :num_rows from predact 
									%if "&vartype." = "C" %then %do;
					                	where grp_var = "%scan(&dist_grps, &k, "!!")";
									%end;
									%if "&vartype." = "N" %then %do;
										where grp_var = %scan(&dist_grps, &k, "!!");
									%end;
					                quit;
					            %put &num_rows;


					           	/* define fileref using DDE access method */
					            %if "&k." = "1" %then %do;
					                %let ri = %eval(%eval(&cat_iter.*20)-17); %let rf = %eval(&num_rows.+&ri.); %let ci = 2; %let cf = 5;
					            %end;
					            %else %do;
					                %let ri = %eval(%eval(&cat_iter.*20)-17); %let rf = %eval(&num_rows.+&ri.); %let ci = %eval(&ci.+5); %let cf = %eval(&cf.+5);
					            %end;


					            data _null_;
					                call symput ("fileref", "Filename predfile dde 'excel|%scan(&cases, &case_no)_categories!r&ri.c&ci.:r&rf.c&cf.' notab");
					                run;
					                %put &fileref;

					            &fileref.;
					            /* write to Excel workbook */
					            Data _null_;
					                file predfile;
					                set predact;
									%if "&vartype." = "C" %then %do;
					                	where grp_var = "%scan(&dist_grps, &k, "!!")";
									%end;
									%if "&vartype." = "N" %then %do;
										where grp_var = %scan(&dist_grps, &k, "!!");
									%end;
					                put grp_var '09'x deciles '09'x predicted '09'x actual;
					                Run;

					            %let k = %eval(&k.+1);
					        %end;
						%let cat_iter = %eval(&cat_iter.+1);
					%end;

					%else %do;
						%let num_cats = %eval(&cat_iter.);
						%let cat_iter = %eval(0);
					%end;

				%end;

				/* put in number of categories */
				data _null_;
					call symput ("fileref", "Filename par2file dde 'excel|%scan(&cases, &case_no)_categories!r1c2:r1c2' notab");
				    run;
				%put &fileref;

				&fileref.;
				data _null_;
					file par2file;
					put "&num_cats.";
					run;	


				/*run MACRO*/
				Filename cmds dde 'excel|system';options xsync;
				data _null_;
				    file cmds;
				    put '[RUN("categories")]';
				    run;

			%end;
			%else %do;
				Filename ncatfile dde 'excel|index!r3c3:r3c3' notab;
				data _null_;
					file ncatfile;
					put "NO";
					run;

			%end;
		%end;
		/*delete sheets*/
		%else %do;
			data del;
				length del $20.;
				del = "%scan(&cases, &case_no)";
				run;

			proc append base = delete data = del force;
				run;
		%end;

		%let case_no = %eval(&case_no.+1);
	%end;

	Filename delfile dde 'excel|index!r3c1:r31c1' notab;
	data _null_;
		file delfile;
		set delete;
		put del;
		run;
		
	/*run MACRO*/
	Filename cmds dde 'excel|system';options xsync;
	data _null_;
	    file cmds;
	    put '[RUN("delete_sheets")]';
	    run;
	


/* save workbook and quit Excel */
	Filename cmds dde 'excel|system';options xsync;
	Data _null_;
		file cmds;
		put '[SAVE()]';
		&finalSave_excelSheet.;
		&close_excelSheet.;
		put '[QUIT()]';
		Run;

	filename MyFile "&output_excelSheet./output_logisticReg_&iteration..xlsm"  ;
	data _null_;
		rc = fdelete("MyFile");
		run;

	%let i = %eval(&i.+1);
%end;


%mend excelReport_logisticReg1;
%excelReport_logisticReg1;


/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "EXCEL_OUTPUT_LOGISTIC_REG_COMPLETED";
	file "&model_path./EXCEL_OUTPUT_LOGISTIC_REG_COMPLETED.txt";
	put v1;
	run;

ENDSAS;



