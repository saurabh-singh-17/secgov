
*processbody;

proc datasets lib=work kill nolist memtype=data;
quit;

options mfile mprint mlogic symbolgen;
dm log 'clear';

proc printto log="&output_path./ARIMAX_Log.log";
quit;
/*proc printto print="&output_path./ARIMAX_Output.out";*/
/*run;*/
/*quit;*/

libname in "&input_path.";
libname group "&group_path.";
libname out "&output_path.";

%macro exportCsv1(libname=,dataset=,filename=);
	proc export data=&libname..&dataset.
    outfile="&output_path./&filename..csv"
    dbms=csv replace;
    run;
%mend;

data stats;
input Statistic $40.;
cards;
;
run;

data stats;
	set stats;
run;


/*%macro changeformat(dataname);*/
/*	data &dataname.;*/
/*		set &dataname.;*/
/*		format _numeric_ 15.2;*/
/*			run;*/
/*%mend;*/

%macro bygroup_treatment;
	%if "&model_iteration." = "1" %then %do;
		%if %sysfunc(exist(&dataset_name.)) %then %do;
			%put exists;
		%end;
		%else %do;
			%if "&grp_no" = "0" %then %do;
				data group.bygroupdata;
					set in.dataworking;
				run;
			%end;
			%else %do;
				data group.bygroupdata;
					set in.dataworking (where = (GRP&grp_no._flag = "&grp_flag."));
				run;
			%end;
		%end;
	%end;

	/*bygroupdata updation*/
	%if "&flag_bygrp_update." = "true" %then %do;
		proc sort data = in.dataworking out = in.dataworking;
			by primary_key_1644;
			run;

		proc sort data = &dataset_name. out = &dataset_name.;
			by primary_key_1644;
			run;

		data &dataset_name.;
			merge &dataset_name.(in=a) in.dataworking(in=b);
			by primary_key_1644;
			if a;
			run;
	%end;	
	%let dset= &dataset_name.;
	%let dsid = %sysfunc(open(&dset));
	%let nobs =%sysfunc(attrn(&dsid,NOBS));
	%let rc = %sysfunc(close(&dsid));
	%if &NOBS. < 7 %then %do;
		data _null_;
      		v1= "There are less than 7 observations in the subsetted dataset hence cannot perform modeling";
      		file "&output_path./ARIMAX_NOT_COMPLETED.txt";
      		put v1;
			run;
		endsas;
	%end;

%mend;
%bygroup_treatment;

%macro VIF1;
	ods output ParameterEstimates = vif_params(keep = Variable VarianceInflation rename = (VarianceInflation = VIF));
    proc reg data = &dataset_name.;
    	model &dependent_variable. = &estimate_variables./vif;
			/*checking if validation is being done*/
			%if "&validation_var" ^= "" %then %do;
			/* checking the type if build or validation*/
				%if "&type_arimax." = "build" %then %do;
					where &validation_var. = 1;
				%end;
				%if "&type_arimax." = "validation" %then %do;
					where &validation_var. = 0;
				%end;
			%end;
    	run;
		quit;
	%if ("&flag_only_vif." = "true") %then %do;
/*		%changeformat(vif_params);*/
		%exportCsv1(libname = work,dataset = vif_params,filename = ParameterEstimates);
	%end;
%mend;


%macro creating_numobs;
	%LET DSID = %SYSFUNC(OPEN(&dataset_name., IN));
	%global NOBS;
	%LET NOBS = %SYSFUNC(ATTRN(&DSID, NOBS));
	%LET RC = %SYSFUNC(CLOSE(&DSID));
	data num;
	_FREQ_ = &NOBS.;
	run;
/*	%changeformat(num);*/
	%exportCsv1(libname = work,dataset = num,filename = num_obs);
%mend;

%macro regression1;
	quit;
	ods output ParameterEstimates = ParameterEstimates(rename=(Probt=PValue));
	ods output DescStats=DescriptiveStats(drop=cValue1 rename=(Label1=Statistic nValue1=Value));
	ods output AutoCorrGraph=AutoCorrGraph;
	ods output PACFGraph=PartialACGraph(rename=(PACF=Correlation) drop = PACFGraph);
	ods output IACFGraph=InverseACGraph(rename=(IACF=Correlation) drop = IACFGraph);
	ods output InputDescStats=InputDescriptiveStats;
	ods output StationarityTests=StationarityTests;
	ods output FitStatistics=FitStatistics(drop=cValue1 rename=(Label1=Statistic nValue1=Value));
	ods output CorrB=Correlations_of_Param_Est(rename=(RowName=Variable_Parameter));
	ods output ChiSqAuto=AC_Check_of_Residuals(rename=(ChiSq=ChiSquare));
	proc arima data = &dataset_name.;
		identify var = &dependent_variable.(&value_order_differencing., &value_period_differencing.) nlag = &value_nlag.  stationarity = (&stationarity_variable.= (0,1,2,3,4,5,6)) 
						%if "&crossCorr_variables." ^= "" %then crosscorr=(&crossCorr_variables.) OUTCOV = cov;;
		%if "&subset" = "true" %then %do;
		estimate p = (&value_p.)(&Seasonality_ar.) 
				 q = (&value_q.)(&Seasonality_ma.) 
				 %if "&estimate_variables." ^= "" %then input = (&estimate_variables.);
				 method = &method_variable. outstat = model_statistics(drop = _TYPE_ rename = (_STAT_= Statistic _VALUE_= Value))
				 whitenoise = &whitenoise_variable.; 
		%end;
		%else %do;
		estimate p=%if &Seasonality_ar.=0 %then &value_p.;%else (&value_p.  &Seasonality_ar.);
				 q=%if &Seasonality_ma.=0 %then &value_q.; %else (&value_q.  &Seasonality_ma.); 
				 %if "&estimate_variables." ^= "" %then input = (&estimate_variables.);
				 method = &method_variable. outstat = model_statistics(drop = _TYPE_ rename = (_STAT_= Statistic _VALUE_= Value))
				 whitenoise = &whitenoise_variable.; 
		%end;
		forecast id = &id_variable. interval = &interval_variable.
				 lead = &value_lead. alpha = &value_alpha.  out = out.forecast;
				 
		%if "&validation_var" ^= "" %then %do;
			%if "&type_arimax." = "build" %then %do;
				where &validation_var. = 1;
			%end;
			%if "&type_arimax." = "validation" %then %do;
				where &validation_var. = 0;
			%end;
		%end;
	run;
	quit;
%mend;

%macro autocorr;
	/*AutoCorrelation Graph*/
	%if %sysfunc(exist(AutoCorrGraph)) %then %do;
		data _null_;
			set AutoCorrGraph nobs=num;
			call symput('numberobs',num);
		run;
		data AutoCorrGraph1;
			set AutoCorrGraph(rename=(StdErr=StandardError));
			Format Variable $40.;
			if _n_ le (&value_nlag.+1) then Variable = "&dependent_variable.";
		run;
		data AutoCorrGraph1;
			Retain Variable;
			set AutoCorrGraph1(drop = CorrGraph);
			where Variable = "&dependent_variable.";
		run;
/*		%changeformat(AutoCorrGraph1);*/
		%exportCsv1(libname = work,dataset = AutoCorrGraph1,filename = AutoCorrGraph);

		/*Cross Correlation*/						
		%if "&crossCorr_variables." ^= "" %then %do;
			%do k = 1 %to %sysfunc(countw("&crossCorr_variables.", ' '));
				%let var = %scan(&crossCorr_variables., &k.);
				data AutoCorrGraphxx;
					retain Variable;
					set cov(firstobs = %eval((&value_nlag. * 2 * &k.) + (&k.+ 1)) obs = %eval((&value_nlag. * 2 * &k.) + (&k.+ 1) + &value_nlag.)) ;
				run;
				proc append base = crosscorr data = AutoCorrGraphxx force;
				run;
			%end;

			data crosscorr;
			set crosscorr (rename=(LAG=Lag CROSSVAR=Variable COV=Covariance CORR=Correlation) drop= VAR N STDERR INVCORR PARTCORR);
			run;			
			proc sql;
			create table crosscorr as
			select Variable,Lag,Covariance,Correlation
			from crosscorr;
			quit;
/*			%changeformat(crosscorr);*/
			%exportCsv1(libname = work,dataset = crosscorr,filename = CrossCorrGraph);
		%end;
	%end;
%mend;

%macro modelstats;
	/*MAPE*/
	%if %sysfunc(exist(out.forecast)) %then %do;
		  data mape1;
		  	set out.forecast;
			if &dependent_variable. ^=0 then do;
	      		perc_err=abs(RESIDUAL)*100/&dependent_variable.;
			end;
			else do;
				perc_err=0;
			end;
			run;

	      proc sql;
            create table Mape as
                  select "MAPE" as Statistic, avg(perc_err) as Val
                  from mape1;
            quit;

		data Mape;
		    Length Statistic $40.;
		 	set Mape;
			%if &type_arimax.=build %then %do;
				Statistic="In Sample MAPE";
			%end;
			%else %if &type_arimax.=validation %then %do;
				Statistic="Out Sample MAPE";
			%end;
			run;
	      
	      data Mape(drop=Val);
	            set Mape;
	            format Value best12.;
	            Value=compress(Val);
	            run;
	%end;
	/*Model Statistics*/
	%if %sysfunc(exist(DescriptiveStats)) %then %do;
		data DescriptiveStats;
			format Statistic $40.;
			set DescriptiveStats;
			run;
		
		proc append base=DescriptiveStats data=stats force;
			run;
	
		proc append base=DescriptiveStats data=model_statistics force;
			run;

		%if %sysfunc(exist(FitStatistics)) %then %do;
				proc append base=DescriptiveStats data=FitStatistics force;
					run;
		%end;
		%if %sysfunc(exist(Mape)) %then %do;
				proc append base=DescriptiveStats data=Mape force;
					run;
		%end;

		proc sort data=DescriptiveStats out=model_stats nodupkey;
			by statistic;
			run;

		data model_stats;
			set model_stats;
			if Statistic not in ('ERRORVAR','NUMRESID');
			if Statistic='LOGLIK' then Statistic='LogLikelihood';
			if Statistic='CONV' then Statistic='Conv';
			run;
	%end;
/*	%changeformat(model_stats);*/
	%exportCsv1(libname = work,dataset = model_stats,filename = Model_Statistics);
%mend;


%macro partial;
	%if %sysfunc(exist(PartialACGraph)) %then %do;
		%if %sysfunc(exist(InverseACGraph)) %then %do;
			data _null_;
				set InverseACGraph nobs=num;
				call symput('numberobs',num);
				run;

			data InverseACGraph;
				set InverseACGraph;
				Format Variable $40.;
				if _n_ le (&value_nlag.) then do;
					Variable = "&dependent_variable." ;
					Autocorr = "InverseAutoCorrelation";
				end;
				run;

			data InverseACGraph;
				Retain Variable;
				set InverseACGraph;
				where Variable = "&dependent_variable." ;
			run;
		%end;

		data _null_;
			set PartialACGraph nobs=num;
			call symput('numberobs',num);
			run;

		data PartialACGraph(rename=(PACF=Correlation));
			set PartialACGraph;
			Format Variable $40.;
			if _n_ le (&value_nlag.) then do;
				Variable = "&dependent_variable."; 
				Autocorr = "PartialAutoCorrelation";
			end;
			run;

		data PCFGraph;
			Retain Variable;
			set PartialACGraph;
			where Variable = "&dependent_variable.";
		run;

		%if %sysfunc(exist(InverseACGraph)) %then %do;
				proc append base = PCFgraph data = InverseACGraph;
				run;
		%end;
/*		%changeformat(PCFGraph);*/
		%exportCsv1(libname = work,dataset = PCFGraph,filename = PartialAutoCorrGraph);
	%end;

%mend;


%macro corrparam;
	/*Correlations of Parameter Estimates*/
	%if %sysfunc(exist(Correlations_of_param_est)) %then %do;
		data Correlations_of_Param_Est;
		set Correlations_of_Param_Est;
		Variable_Parameter=tranwrd(Variable_Parameter,",","_");
		run;
/*		%changeformat(Correlations_of_param_est);*/
		%exportCsv1(libname = work,dataset = Correlations_of_Param_Est,filename = CorrelationofParameterEstimates);
	%end;
%mend;


%macro plots;
	%let dsid = %sysfunc(open(out.forecast));
	%let nobs =%sysfunc(attrn(&dsid,NOBS));
	%let rc = %sysfunc(close(&dsid));

	%if &nobs. > 5500 %then %do;	
		
		/*Predicted Vs Actual Plot*/
		data anno;
		   function='move'; 
		   xsys='1'; ysys='1'; 
		   x=0; y=0; 
		   output;

		   function='draw'; 
		   xsys='1'; ysys='1'; 
		   color='green'; 
		   x=100; y=100; 
		   output;
		run;

		ods graphics on/ width=20in height=20in;
		ods listing;
		filename image "&output_path./PredictedvsActual.png";
		goptions reset=all device =  png300 Transparency gsfname=image gsfmode=replace;
		footnote1 h = .5 '  ';
		
	
		symbol1 font = marker value=U height=.3 color=orange width=20;
		axis1 label=('Predicted');
		axis2 label=('Actual');
	
		proc gplot data= out.forecast;
			plot Forecast*Actual/anno=anno vaxis=axis2 haxis=axis1 ;
		run;

		ods listing close;
		ods graphics off;
		/*---------------------------------------------------------*/

		/*Predicted Vs Residual Plot*/
		ods graphics on/ width=20in height=20in;
		ods listing;
		filename image "&output_path./PredictedvsResidual.png";
		goptions reset=all device =  png300 Transparency gsfname=image gsfmode=replace;
		footnote1 h = .5 '  ';
	
		symbol1 font = marker value=U height=.3 color=orange;
		axis1 label=('Predicted');
		axis2 label=('Residual');
	
		proc gplot data= out.forecast;
			plot Forecast*Residual/vaxis=axis1 haxis=axis2 ;
		run;

		ods listing close;
		ods graphics off;
		/*---------------------------------------------------------*/

		/*Residual Vs Actual Plot*/
		ods graphics on/ width=20in height=20in;
		ods listing;
		filename image "&output_path./ResidualvsActual.png";
		goptions reset=all device =  png300 Transparency gsfname=image gsfmode=replace;
		footnote1 h = .5 '  ';
	
		symbol1 font = marker value=U height=.3 color=orange;
		axis1 label=('Residual');
		axis2 label=('Actual');
	
		proc gplot data= out.forecast;
			plot Actual*Residual/vaxis=axis2 haxis=axis1 ;
		run;

		ods listing close;
		ods graphics off;


		/*Forecast Vs Actual Plot*/
		ods graphics on/ width=20in height=20in;
		ods listing;
		filename image "&output_path./ActualAndForecast.png";
		goptions reset=all device =  png300 Transparency gsfname=image gsfmode=replace;
		footnote1 h = .5 '  ';
		symbol1 font = marker i=join value=U height=.3 color=orange;
		symbol2 font = marker i=join value=U height=.3 color=orange;
		axis1 label=('Date');
		axis2 label=('ActualAndForecast');
	
		proc gplot data= out.forecast;
			plot Actual*&id_variable. Forecast*&id_variable./vaxis=axis2 haxis=axis1 ;
		run;

		ods listing close;
		ods graphics off;
		/*---------------------------------------------------------*/
	%end; 
%mend;

%macro forecast;
	/*Forecast*/
	%if %sysfunc(exist(out.forecast)) %then %do;
		data out.forecast;
		set out.forecast(rename=(&dependent_variable.=Actual %if "&type_varselection."^="" %then forecast_org=Forecast_config; FORECAST=Forecast_original ));
		run;
		data out.forecast;
			set out.forecast(keep=&id_variable. Actual Forecast_original %if "&type_varselection."^="" %then newVar Forecast_config ; STD L: U: Residual);
		run;
		data out.forecast;
			set out.forecast;
			rename Forecast_original=FORECAST;
		run;
/*		%changeformat(out.forecast);*/
		%exportCsv1(libname = out,dataset = forecast,filename = Forecast_Values);
	%end;
%mend;


%macro test;
	/*Stationarity Tests*/
	%if %sysfunc(exist(Stationaritytests)) %then %do;
/*		%changeformat(Stationaritytests);*/
		%exportCsv1(libname = work,dataset = Stationaritytests, filename = StationarityTests);
	%end;
%mend;


%macro param;
	/*Parameter Estimates*/
	%if %sysfunc(exist(Parameterestimates)) %then %do;	
		data Parameterestimates(drop=Parameter);
		set Parameterestimates;
		Parameters=tranwrd(Parameter,",","_");
		%if "&estimate_variables." = "" %then %do; Variable = "&dependent_variable."; %end;
		run;
		proc sql;
		create table Parameterestimates as
		select Variable,Estimate,StdErr,tValue,PValue,Lag,Parameters
		from Parameterestimates;
		quit;
		%if "&estimate_variables." ^= "" %then %do;
			%if ("&flag_only_vif." = "true" or "&flag_vif."="true") %then %do;
				proc sort data= vif_params;
						by Variable;
						run;
				proc sql;
				create table Parameterestimates1 as
				select Variable,Estimate,StdErr,tValue,PValue,Lag,Parameters
				from Parameterestimates;
				quit;
				%if %sysfunc(exist(Parameterestimates1)) %then %do;	
					proc sort data= Parameterestimates1;
							by Variable;
							run;

					data Parameterestimates;
					merge Parameterestimates1 vif_params;
					by Variable;
					run;
				%end;
				%else %do;	
					proc sort data= Parameterestimates;
							by Variable;
							run;

					data Parameterestimates(keep = Variable Estimate StdErr tValue PValue Lag Parameters);
					merge Parameterestimates vif_params;
					by Variable;
					run;
				%end;
			%end;
		%end;
/*		%changeformat(Parameterestimates);*/
	%exportCsv1(libname = work,dataset = Parameterestimates, filename = ParameterEstimates);
	%end;
%mend;


%macro autoresid;
	/*AutoCorrelation Check of Residual*/	
	%if %sysfunc(exist(AC_Check_of_Residuals)) %then %do;	
/*		%changeformat(AC_Check_of_Residuals);	*/
		%exportCsv1(libname = work,dataset = AC_Check_of_Residuals,filename = AutoCorrelationCheckofResidual);	
	%end;
%mend;

%macro execute1;
	%if ("&flag_only_vif." = "true" or "&flag_vif." = "true") %then %do;
		%VIF1;
	%end;
	%creating_numobs;
	%if "&flag_run_arimax." = "true" %then %do;
		%regression1;
		%autocorr;
		%modelstats;
		%partial;
		%corrparam;
		%forecast;
		%plots;
		%test;
		%param;
		%autoresid;
	%end;
%mend;
%execute1;


/*Flex uses this file to test if the code has finished running*/
data _null_;
      v1= "ARIMAX_COMPLETED";
      file "&output_path/ARIMAX_COMPLETED.txt";
      put v1;
      run;

