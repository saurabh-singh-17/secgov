/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &outputPath./VARMAX_NOT_COMPLETED.txt &outputPath./VARMAX_COMPLETED.txt;
/*Code: Varmax*/
/*Author: Kinnari Shah/ Subarna Rana */									
/*Last Edited on: 11:30 PM 1/22/2012 by Subarna Rana */
proc datasets lib=work kill nolist memtype=data;
quit;

%let output_path = &outputPath.;

%macro creatingdata_prevarmax;
	%if "&validationVar." = "" %then %do;
		data sanitydata;
		set &datasetName.;
		run;
	%end;
	%else %if "&validationVar." ^= "" %then %do;
	/* checking the type if build or validation*/
		data sanitydata;
			set &datasetName.;
		run;
		%if "&validationType." = "build" %then %do;
			data sanitydata;
				set &datasetName.;
				where &validationVar. = 1;
			run;
		%end;
		%else %if "&validationType." = "validation" %then %do;
			data sanitydata;
				set &datasetName.;
				where &validationVar. = 0;
			run;
		%end;
	%end;
%mend;


%macro missingv(parm=,val=);
	%do k = 1 %to %sysfunc(countw("&&&parm.", ' '));
		proc sql noprint inobs = &&&val;
			select nmiss(%scan(&&&parm.., &k.)) into:nm from sanitydata;
		quit;
		%put &nm.;
		%if(&nm > 0) %then %do;
			%global tot;
			%let tot = &nm.;
			%return;
		%end; 
		%else %do;
			%global tot;
			%let tot = 0;
		%end;
	%end;
	%put tot;
%mend;

%macro prevarmax_check_nos;
/* Checking number of observations in dataset	*/
	%LET DSID = %SYSFUNC(OPEN(sanitydata, IN));
	%global NOBS;
	%LET NOBS = %SYSFUNC(ATTRN(&DSID, NOBS));
	%LET RC = %SYSFUNC(CLOSE(&DSID));
	%if &NOBS. < 15 %then %do;
		data checknos;
	  		check = "Selected data contains less than 15 observations. VARMAX modeling was not initialised";
		run;
	%end;
%mend;
%macro prevarmax_check_miss;
	%if &NOBS. >= 15 %then %do;
		%let depnos = %eval(&NOBS. - &lead_value.);
		%missingv(parm = dependentvariable, val = depnos);
		%if &tot > 0 %then %do;
			data checkdep;
				check = "Missing Value Error in dependent variables. VARMAX modeling was not initialised. Treat Missing Values?'";
			run;
		%end;
		%else %do;
		%missingv(parm = independentVariables, val = NOBS);
			%if &tot > 0 %then %do;
				data checkindep;
					check = "Missing Value Error in independent variables. VARMAX modeling was not initialised. Treat Missing Values?";
				run;
			%end;
		%end;
	%end;
%mend;

%macro end_varmax_not_completed;
	data _null_;
      		v1= "VARMAX_NOT_COMPLETED";
      		file "&outputPath./VARMAX_NOT_COMPLETED.txt";
      		put v1;
	run;
%mend;

%macro end_varmax_check;
	%if %sysfunc(exist(checknos))%then %do;
		%end_varmax_not_completed;
		%exportCsv(libname=work,dataset=checknos,filename=Check_Varmax);
		proc datasets;
		delete checknos;
		run;
	Endsas;
	%end;
	%else %if %sysfunc(exist(checkdep)) %then %do;
		%if("&remove_miss." = "false") %then %do;
			%end_varmax_not_completed;
			%exportCsv(libname=work,dataset=checkdep,filename=Check_Varmax_Miss);
			proc datasets;
			delete checkdep;
			run;
		Endsas;
		%end;
	%end;
	%else %if %sysfunc(exist(checkindep)) %then %do;
		%if("&remove_miss." = "false") %then %do;
			%end_varmax_not_completed;
			%exportCsv(libname=work,dataset=checkindep,filename=Check_Varmax_Miss);
			proc datasets;
			delete checkindep;
			run;
		Endsas;
		%end;
	%end;
%mend;

%creatingdata_prevarmax;
%prevarmax_check_nos;
%prevarmax_check_miss;
%end_varmax_check;

%macro remove_miss;
%if("&remove_miss." = "true") %then %do;
	%if %sysfunc(exist(Checkdep)) OR %sysfunc(exist(Checkindep))  %then %do;
		%do k = 1 %to %sysfunc(countw("&dependentvariable.", ' '));
		%let mvar = %scan(&dependentvariable., &k.);
			data sanitydata;
			set sanitydata;
			if missing(&mvar.) then do;
			delete;
			end;
			run;
		%end;
		proc datasets;
		delete checkdep;
		run;

		%do k = 1 %to %sysfunc(countw("&independentVariables.", ' '));
		%let mvar = %scan(&independentVariables., &k.);
			data sanitydata;
			set sanitydata;
			if missing(&mvar.) then do;
			delete;
			end;
			run;
		%end;
		%if %sysfunc(exist(Checkindep))  %then %do;
		proc datasets;
		delete checkindep;
		run;
		%end;
	%end;	
%end;
%mend;
%remove_miss;
%prevarmax_check_nos;
%end_varmax_check;
	

%macro vif4;
%if ("&flagVifVarmax." = "true") %then %do;
	%do k = 1 %to %sysfunc(countw("&dependentvariable.", ' '));
		%let var = %scan(&dependentvariable., &k.);
		ods output ParameterEstimates = &var.(keep = Variable VarianceInflation rename = (VarianceInflation = VIF Variable = Var));
		proc reg data = &datasetName.;
			model &var. = &independentVariables./vif;
			/* checking if validation is being done*/
			%if "&validationVar." ^= "" %then %do;
			/* checking the type if build or validation*/
				%if "&validationType." = "build" %then %do;
				    where &validationVar. = 1;
					%put &validationType. &validationVar.;
				%end;
				%else %if "&validationType." = "validation" %then %do;
				    where &validationVar. = 0;
				%end;
			%end;
		run;
		quit;

		data &var.;
			set &var.;
			format Variable $50.;
			Variable="&var.";
		run;
	%end;

	data vif_params;
		set &dependentvariable.;
	run;

	proc datasets;
		delete &dependentvariable.;
	run;

		%if "&flagRunVarmax." = "false" %then %do;
			data vif_params;
				set vif_params;
				format selected $10.;
				selected="true";
			run;

			data temp(drop= &validationVar. primary_key_1644 );
				set &datasetname.;
				if _n_<10;
			run;

			proc contents data=temp out=columns_2(keep=name rename=(name=Var));
				run;
			
			data columns_2;
				set columns_2;
				format selected $10.;
				selected="false";
				run;
				
			%do k=1 %to %sysfunc(countw(&dependentvariable.));
				%let var=%scan(&dependentvariable.,&k.);
				data &var.;
					format selected $10.;
					set columns_2;
					selected="false";
					format Variable $50.;
					Variable="&var.";
					run;
			%end;
			data columns;
					set &dependentvariable.;
					run;

			proc sort data= vif_params;
				by Variable var;
				run;

			proc sort data=columns;
				by Variable var;
				run;

			data columns_1;
				merge vif_params(in=a) columns(in=b);
				by Variable var;
				if b and not a;
				run;

			data vif_params;
				set vif_params columns_1;
				run;
		%end;
		%exportCsv(libname=work,dataset=vif_params,filename=ParameterEstimates);
%end;
%mend; 
%vif4;

%macro run_varmax;
%if "&flagRunVarmax."="true" %then %do;

		proc sort data = sanitydata out = sanitydata;
		by &date_var.;
		run;
		data depvardata;
		set sanitydata (firstobs = %eval(&NOBS. - &lead_value. + 1));
		run;
		%do k = 1 %to %sysfunc(countw("&dependentvariable.", ' '));
			%let var = %scan(&dependentvariable., &k.);
			data depvardata;
			set depvardata;			
			if _n_ ^= "." then &var = ".";
			&var = &var * 1;
			run;
		%end;
		data tmpdate;
		set sanitydata (keep = &date_var.);
		run;
		proc expand data = tmpdate out = tmpdate;
		run;	
		data Varmaxx;
		merge sanitydata tmpdate depvardata;
		by &date_var.;
		run;
		data depvardata;
		set Varmaxx (firstobs = %eval(&NOBS. - &lead_value. + 1));
		run;

		/*Model Statistics*/
		ods output NObs = NObs (rename=(Label1=Statistic cValue1=Value) drop=nValue1);
		ods output Summary = Summary;
		ods output InfoCriteria = InfoCriteria (rename=(Label1=Statistic cValue1=Value) drop=nValue1);
		ods output ModelType = ModelType(rename=(Label1=Statistic cValue1=Value) drop=nValue1);
		ods output CovInnovation = CovInnovation;

		/*DF and Cointegration Test*/

		%if ("%scan(&tests_var.,1)"= "dftest") %then %do;
			ods output DFTest = DFTest(rename=(Tau=TStats Rho=RhoStats));
		%end;
		%if %sysfunc(countw("&dependentvariable."))>1 %then %do;
			%if ("%scan(&tests_var.,1)" = "cointtest") %then %do;
				%put co-int test id being done;
				ods output TraceTest = TraceTest;
				ods output RestrictTraceTest = RestrictTraceTest;
			%end;
		%end;
		%else %do;
			%if ("%scan(&tests_var.,1)" = "dftest") %then %do;
				%let tests_var=dftest;
			%end;
			%else %do;
				%let tests_var=;
			%end;
		%end;
		%if ("%scan(&tests_var.,1)" = "cointtest") AND ("%scan(&tests_var.,2)" = "dftest") %then %do;
			ods output DFTest = DFTest(rename=(Tau=TStats Rho=RhoStats));
			ods output TraceTest = TraceTest;
			ods output RestrictTraceTest = RestrictTraceTest;
		%end;

		/*PACF*/
		ods output PartialAR = PartialAR;
		
		/*Parameter Estimates*/
		ods output ParameterEstimates = ParameterEstimates(rename=(Variable=ExtraInfo));

		%if "&restrict_option."="true" %then %do;
			ods output Restrict = Restrict;
		%end;

		/*Residual Analysis*/
		ods output CovResiduals = CovResiduals;
		ods output CorrResiduals = CorrResiduals;
		ods output PortmanteauTest = PortmanteauTest;

		/*Univariate Model Diagnostics*/
		ods output ANOVA = ANOVA;
		ods output DiagnostWN = DiagnostWN;
		ods output DiagnostAR = DiagnostAR;

		/*Forecasts*/
		%if ("&lead_var." = "true" and &lead_value. > 0) %then %do;
			ods output Forecasts = Forecasts;
		%end;

		/*ods trace on;*/
					
		proc varmax data = Varmaxx;
			id TIME interval = day;
			model &dependentvariable. 
			%if "&independentvariables." ^= "" %then %do ; = &independentvariables. %end;/
			%if "&p_var." = "true" %then %do; p = &p_value. %end;
			%if "&q_var." = "true" %then %do; q = &q_value.  %end;
			%if "&lag_var." = "true" %then %do; lagmax = &lag_value.  %end;
			%if ("&xlag_var." = "true" and "&independentvariables." ^= "") %then %do; xlag= &xlag_value.   %end;
			&tests_var. print=(parcoef);
			%if "&restrict_option." = "true" %then %do;
				restrict &restrictoptions.;
			%end;
			output out = out.forecast lead = &lead_value. ;
		run;
		quit;

		data out.forecast;
			merge out.forecast tmpdate;
			by TIME;
		run;

		data out.forecast;
			set out.forecast(drop = TIME);
		run;

		proc datasets;
			delete tmpdate varmaxx;
		run;

		proc append base = depvardata
		data = depvardata force;
		run;

		data depvardata;
		set depvardata (Keep = &date_var.);
		run;

		%if %sysfunc(exist(forecasts)) %then %do;
		data forecasts;
			merge forecasts depvardata;
		run;
		data forecasts;
			set forecasts(drop = TIME);
		run;

		%end;
		%else %do;
		data forecasts;
			set depvardata;
		run;
		%end;
							
%end;
%mend;
%run_varmax;

%macro post_varmax;
%if "&flagRunVarmax." = "true" %then %do; 
		/*Model Statistics*/
		proc sort data=WORK.SUMMARY;
			by Variable;
		run;

		proc transpose data=WORK.SUMMARY(where = (type='Dependent')) out=WORK.SUMMARY_t(drop=_NAME_ rename=(_LABEL_=Statistic));
			id Variable;
		run;

		data Covinnovation(drop=Variable);
			set CovInnovation;
			format Statistic $100.;
			Statistic="Covariance of Innovation " || Variable;
		run;
				
		data Model_Stats;
			format Statistic $100.;
			set 
			%if %sysfunc(exist(work.nobs)) %then %do;WORK.NOBS %end;
			%if %sysfunc(exist(work.infocriteria)) %then %do;WORK.INFOCRITERIA %end;
			%if %sysfunc(exist(WORK.SUMMARY_T)) %then %do;WORK.SUMMARY_T %end;
			%if %sysfunc(exist(WORK.COVINNOVATION)) %then %do; WORK.COVINNOVATION %end;
			;
		run;

		data Model_Stats_1(drop=Value);
			set Model_Stats;
			%do k=1 %to %sysfunc(countw("&dependentvariable.",' '));
				%let word = %scan(&dependentvariable.,&k.);
				if &word.=. then &word.=value*1;
			%end;
		run;
				
		data ModelType;
			set Modeltype;
			Value=tranwrd(value,",","_");
		run;

				data Model_Stats_2(drop=Value);
					set Modeltype;
					%do k=1 %to %sysfunc(countw("&dependentvariable.",' '));
						%let word = %scan(&dependentvariable.,&k.);
						&word.=value;
					%end;
					run;

				proc datasets;
					delete SUMMARY SUMMARY_t Covinnovation Model_Stats ;
					run;

			/*DF and Coint Test*/
				%if %sysfunc(exist(DFTest)) %then %do;
					%exportCsv(libname=Work,dataset=DFTest,filename=DFTest);
				%end;

				%if %sysfunc(exist(TraceTest)) %then %do;
					data TraceTest;
						format Type $100.;
						set TraceTest;
						Type='Cointegration Rank Test Using Trace';
						run;
				%end;
				%if %sysfunc(exist(RestrictTraceTest)) %then %do;
					data RestrictTraceTest;
						format Type $100.;
						set RestrictTraceTest;
						Type='Cointegration Rank Test Using Trace Under Restriction';
						run;
					%if %sysfunc(exist(TraceTest)) %then %do;
						data Trace;
							set  TraceTest RestrictTraceTest;
							run;

						%do k=1 %to %sysfunc(countw("&dependentvariable.",' '));
							%let word = %scan(&dependentvariable.,&k.);
							data Trace_&k.;
							format Variable $50.;
								set Trace;
								Variable="&word.";
								run;
							data Trace; 
								set Trace Trace_&k.;
								run;
						%end;
						data Trace;
							set Trace;
							if Variable='' then delete;
							run;
						%exportCsv(libname=work, dataset=Trace, filename=CointTest);
					%end;
				%end;
				
				proc datasets;
					delete TraceTest Trace RestrictTraceTest DFTest;
					run;

			/*PACF*/
				%if %sysfunc(exist(PartialAR)) %then %do;
					%if %sysfunc(countw(&dependentvariable.))=1 %then %do;
						data PartialAR;
							set PartialAR;
							Variable="&dependentvariable.";
							run;
					%end;
					%exportCsv(libname=work, dataset=PartialAR, filename=PACF);
				%end;

			/*Parameter Estimates*/
				%if %sysfunc(exist(WORK.PARAMETERESTIMATES)) %then %do;
					data WORK.PARAMETERESTIMATES;
							set WORK.PARAMETERESTIMATES(rename=(Equation=Variable));
							run;

					data ParameterEstimates_1;
							format Var $50.;
							format Extra $7.;
							set ParameterEstimates;
							Var=scan(ExtraInfo,1,"(");
							If Var='1' then var="Constant";
							Extra=substrn(Parameter,1,2) || '(' || substrn(Parameter,3,1) || "_" || substrn(Parameter,5,1) || "_";
							If Extra="CO(N,T," then Extra="Const(" || substrn(Parameter,6,1);
							run;
					
					proc sql;
						create table columns_1 as
						select distinct Var from ParameterEstimates_1
						order by Var;
						quit;

					data temp(drop= &validationVar. primary_key_1644 );
						set &datasetname.;
						if _n_<10;
						run;

					proc contents data=temp out=columns_2(keep=name rename=(name=Var));
						run;

					proc sort data=columns_2;
						by Var;
						run;
					
					data columns_12;
						merge columns_1(in=a) columns_2(in=b);
						by var;
						if b and not a;
						run;

					%let var=%scan(&dependentvariable.,1);
					%put &var.;

					data columns_121;
						format selected $10.;
						set columns_12;
						selected="false";
						format Variable $50.;
						Variable="&var.";
						run;
				
					%do k=2 %to %sysfunc(countw(&dependentvariable.));
						%let var=%scan(&dependentvariable.,&k.);
						data columns_12&k.;
							format selected $10.;
							set columns_12;
							selected="false";
							format Variable $50.;
							Variable="&var.";
							run;
						data columns_121;
							set columns_121 columns_12&k.;
							run;
					%end;

					data ParameterEstimates_2;
						format Variable $50.;
						format selected $10.;
						set ParameterEstimates_1 columns_121;
						if selected="" then selected="true";
						run;
					
					%if (%sysfunc(exist(vif_params))) %then %do;
						proc sort data=vif_params;
							by Variable Var;
							run;
						
						proc sort data=ParameterEstimates_2;
							by Variable Var;
							run;

						data ParameterEstimates_1;
							merge ParameterEstimates_2(in=a) vif_params(in=b);
							by Variable Var;
							if a ;
							run;
						data ParameterEstimates_2;
							set ParameterEstimates_1;
							run;
					%end;

					%exportCsv(libname=work,dataset=ParameterEstimates_2,filename=ParameterEstimates);
				%end;
				%if %sysfunc(exist(Retrict)) %then %do;
					%exportCsv(libname=work,dataset=restrict,filename=Restrict);
				%end;

			/*Residual Analysis*/
				%if %sysfunc(exist(COVRESIDUALS)) %then %do;
				data WORK.COVRESIDUALS;
					set WORK.COVRESIDUALS;
					Format Statistic $40.;
					Statistic="Cross Covariance of Residuals ";
					run;

				data WORK.CORRRESIDUALS;
					set WORK.CORRRESIDUALS;
					Format Statistic $40.;
					Statistic="Cross Correlation of Residuals ";
					run;
				
				proc append base=WORK.COVRESIDUALS data=WORK.CORRRESIDUALS;
					run;
				
				proc sql;
					create table ResiDualAnalysis as
					select Statistic,* from WORK.COVRESIDUALS;
					quit;
				
				%if %sysfunc(exist(work.PortmanteauTest)) %then %do;
					data Portmanteautest;
						set Portmanteautest;
						format Statistic $100.;
						Statistic="Portmanteau Test for Cross Correlations of Residuals";
						run;
					
					proc sql;
						create table Portmanteautest_1 as
						select Statistic, * from Portmanteautest;
						quit;

				%exportCsv(libname=work,dataset=Portmanteautest_1,filename=PortmanteautestResid);
				%end;
				%if %sysfunc(countw(&dependentvariable.))=1 %then %do;
					data ResidualAnalysis;
						set ResidualAnalysis;
						Variable="&dependentvariable.";
						run;
				%end;
				%exportCsv(libname=work,dataset=ResidualAnalysis,filename=ResidualAnalysis);

				proc datasets;
					delete COVRESIDUALS CORRRESIDUALS ResidualAnalysis PortmanteautestResid;
					run;
				%end;
			/*Univariate Model Diagnostics*/
				proc sort data=ANOVA;
					by Variable;
					run;
				proc sort data=Diagnostwn;
					by Variable;
					run;
				proc sort data=Diagnostar;
					by Variable;
					run;

				proc transpose data=anova out=anova_t;
					by Variable;
					run;
				proc transpose data=Diagnostwn out=Diagnostwn_t;
					by Variable;
					run;
				proc transpose data=Diagnostar out=Diagnostar_t;
					by Variable;
					run;

				data anova_t;
					set anova_t(rename=(_name_=Statistic _LABEL_=Description COL1=Value));
					Diagnostic="Univariate Model ANOVA Diagnostics";
					run;
				data Diagnostwn_t;
					set Diagnostwn_t(rename=(_name_=Statistic _LABEL_=Description COL1=Value));
					Diagnostic="Univariate Model White Noise Diagnostics";
					run;
				data Diagnostar_t;
					set Diagnostar_t(rename=(_name_=Statistic _LABEL_=Description COL1=Value));
					Diagnostic="Univariate Model AR Diagnostics";
					run;

				data Diagnostic;
					format Diagnostic $100.;
					format Variable $50.;
					format Statistic $50.;
					format Description $100.;
					set Anova_t Diagnostar_t Diagnostwn_t;
					run;
				proc sql;
					create table Diagnostics as
					select Diagnostic,Variable, Statistic, Description, Value from Diagnostic ;
					quit;

				%exportCsv(libname=work,dataset=Diagnostics,filename=Diagnostics);

				proc datasets;
					delete Diagnostics Diagnostic Diagnostar_t Diagnostar Diagnostwn Diagnostwn_t anova anova_t;
					run;

			/*Forecasts*/
			%if %sysfunc(exist(out.forecast)) and %sysfunc(exist(forecasts)) %then %do;
				proc sort data=out.forecast;
					BY &date_var.;
					run;

				%exportCsv(libname=work,dataset=Forecasts,filename=Forecasts);

				%do k=1 %to %sysfunc(countw(&dependentvariable.));
					%let var=%scan(&dependentvariable.,&k.);
					data &var.(rename=(&var.=Actual for&k.=Pred res&k.=Resid ));
						format Variable $100.;
						set out.forecast(keep= &var. for&k. res&k.);
						Variable="&var.";
						run;	
			/*Mape*/	
					data mape_&var.;
						  	set &var.;
					      	perc_err=abs(Resid)*100/Actual;
							run;

					      proc sql;
					            create table Mape_&var._1 as
					                  select "MAPE" as Statistic, avg(perc_err) as &var.
					                  from Mape_&var.;
					            quit;

						proc sort data=Model_stats_1;
							by Statistic;
							run;

						data Model_stats_1;
							merge model_stats_1(in=a) Mape_&var._1(in=b);
							by Statistic;
							if a or b;
							run;
				%end;
			%end;
			
				data ActualVsPred_1;
					set &dependentvariable.;
					if Pred ne . and Resid ne .;
					run;

				%exportCsv(libname=work,dataset=ActualVsPred_1,filename=ActualVsPred);

			%if %sysfunc(exist(Model_Stats_1)) %then %do;
				%exportCsv(libname=Work,dataset=Model_Stats_1,filename=Model_Statistics_1);
			%end;
			%if %sysfunc(exist(Model_Stats_2)) %then %do;
				%exportCsv(libname=Work,dataset=Model_Stats_2,filename=Model_Statistics_2);
			%end;
%end;
%mend;
%post_varmax;

/*Flex uses this file to test if the code has finished running*/
 data _null_;
      v1= "VARMAX_COMPLETED";
      file "&outputPath./VARMAX_COMPLETED.txt";
      put v1;
 run;
/*endsas;*/
