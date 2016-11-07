
/*Successfully converted to SAS Server Format*/
*processbody;

%let completedTXTPath =  &outputPath/AUTOREG_COMPLETED.txt;
%let textToReport=;
%let output_path = &outputPath.;
FILENAME MyFile "&outputPath./error.txt";

DATA _NULL_;
  rc = FDELETE('MyFile');
RUN;
%macro check;
data dummydata;
	set &datasetName.;
	%if "&validationVar" ^= "" %then %do;
       %if "&validationType." = "build" %then %do;
             where &validationVar. = 1;
        %end;
       %if "&validationType." = "validation" %then %do;
             where &validationVar. = 0;
       %end;
	%end;
	run;
proc corr data=dummydata out=corrdata;
var &dependentVariable &independentVariables;
run;
data corrdata;
	set corrdata;
	if _type_ = "CORR";
	if _name_ ne "&dependentVariable.";
	run;
%let checkvar=;
proc sql;
select  &dependentVariable. into:checkvar separated by " " from corrdata where &dependentVariable. = 1;
quit;
proc sql;
select  _name_ into:checkvarname separated by " " from corrdata where &dependentVariable. = 1;
quit;
%if "&checkvar." ne "" %then %do;
data _null_;
      v1= "Following independent variable(s) :&checkvarname. have correlation of 1 with dependent variable. Please deselect to continue";
      file "&outputPath/error.txt";
      put v1;
      run;
%end;
%mend;
%check;
%macro autoreg;
	ods output ParameterEstimates=paraes;
	ods output FitSummary = FitSummary;
	%if "&stepwise."="true" %then %do;
		ods output Backstep = insignificant;
		ods output  ARParameterEstimates=significant;
	%end;
	%if "&numberOfLags." ^="" or "&customLags." ^= ""%then %do;
		ods output CorrGraph=autocorr;
	%end;
		proc autoreg data=&datasetName.(keep=&dependentVariable. &independentVariables. &validationVar.)  outest=out.out_betas;
			model &dependentVariable.= &independentVariables./
				%if "&autoregressiveLags."="true" %then %do;
					%if "&numberOfLags." ^="" %then %do;
						nlag=&numberOfLags.
					%end;
					%else %if "&customLags." ^= "" %then %do;
						nlag=(&customLags.)
					%end;
				%end;
				%if "&methodOfEstimation." ="false" %then %do;
					%let method = ml;
					method=&method./*removed semicolon*/
				%end; 
				%else %do; 
					method=&method.
				%end;
				%if "&laggedDependentVariable."="true" and "&laggedVariable" ^="" %then %do; 
					lagdep=&laggedVariable.
				%end; 
				;
			output out=out.outdata p=pred r=res;
			%if "&validationVar" ^= "" %then %do;
	             /* checking the type if build or validation*/
	                   %if "&validationType." = "build" %then %do;
	                         where &validationVar. = 1;
	                    %end;
	                   %if "&validationType." = "validation" %then %do;
	                         where &validationVar. = 0;
	                   %end;
	        %end;
			run;
		%let textToReport=&textToReport. Autoreg completed;
%mend autoreg;


%macro plots(dataset);
	%let dsid = %sysfunc(open(&dataset));
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
		filename image "&outputpath./PredictedvsActual.png";
		goptions device = pngt gsfname=image gsfmode=replace;
		footnote1 h = .5 '  ';
		
		symbol1 font = marker value=U height=.3 color=orange width=20;
		axis1 label=('Actual');
		axis2 label=('Predicted');
	
		proc gplot data= &dataset;
			plot pred*actual/anno=anno vaxis=axis2 haxis=axis1 ;
		run;

		ods listing close;
		ods graphics off;
		/*---------------------------------------------------------*/

		/*Predicted Vs Residual Plot*/
		ods graphics on/ width=20in height=20in;
		ods listing;
		filename image "&outputpath./PredictedvsResidual.png";
		goptions device = pngt gsfname=image gsfmode=replace;
		footnote1 h = .5 '  ';
	
		symbol1 font = marker value=U height=.3 color=orange;
		axis1 label=('Residual');
		axis2 label=('Predicted');
	
		proc gplot data= &dataset;
			plot pred*res/vaxis=axis2 haxis=axis1 ;
		run;

		ods listing close;
		ods graphics off;
		/*---------------------------------------------------------*/

		/*Residual Vs Actual Plot*/
		ods graphics on/ width=20in height=20in;
		ods listing;
		filename image "&outputpath./ResidualvsActual.png";
		goptions device = pngt gsfname=image gsfmode=replace;
		footnote1 h = .5 '  ';
	
		symbol1 font = marker value=U height=.3 color=orange;
		axis1 label=('Actual');
		axis2 label=('Residual');
	
		proc gplot data= &dataset;
			plot res*actual/vaxis=axis2 haxis=axis1 ;
		run;

		ods listing close;
		ods graphics off;
		/*---------------------------------------------------------*/
	%end; 
%mend;


%macro postautoreg;
	data out.outdata;
		set out.outdata;
		modres = abs(res);
		temp1 = abs(&dependentVariable.);
		mapeindi = (modres/temp1);
		run;

/*-----------------------------------------------------------------------------------------------------------------*/
/*DIAGNOSTIC CHARTS*/
	libname outch xml "&outputPath/charts.xml";
	data outch.chart;
		set out.outdata(keep = pred res &dependentVariable.);
		actual = &dependentVariable.;
		run; 
	data out.outdata;
		set out.outdata;
		actual = &dependentVariable.;
		run;
	%exportCsv(libname=out,dataset=outdata,filename=chart);
	%plots(out.outdata);
/* Separate the Parameter Estimates for OLS and Autoreg*/
	%let var_count=%sysfunc(countw(&independentVariables.));
	%put &var_count.;
	%let dsid = %sysfunc(open(paraes));
	%let nobs =%sysfunc(attrn(&dsid,NOBS));
	%let rc = %sysfunc(close(&dsid));
/*	calculating minus value*/
	%if "&numberOfLags" ne "" %then %do;
		%let minusvalue=&numberOfLags.;
	%end;
	%if "&customLags." ne "" %then %do;
		%let minusvalue=%sysfunc(countw("&customLags."," "));
	%end;
	data  out.paraes_ols out.paraes_autoreg;
		set paraes;
		%if "&method." = "yw" %then %do;
		if _n_ > %sysevalf(&nobs./2) then do;
		%end;
		%else %do;
		if _n_ > %sysevalf((&nobs.-&minusvalue.)/2) then do;
		%end;
			Dependent_variable="&dependentVariable.";
			output out.paraes_autoreg;
		end;
		else do;
			Dependent_variable="&dependentVariable.";
			output out.paraes_ols;
		end;
		run;

	 %if "&flagVif."="true" %then %do;
		 proc sort data=out.paraes_ols;
		       by Variable;
		       run;

		 proc sort data=vif_params;
		       by variable;
		       run;

		 data out.Paraes_ols;
		       merge out.Paraes_ols(in=a) vif_params(in=b);
		       by Variable;
		       if a;
		       run;
		
	%end; 
	%exportCsv(libname=out,dataset=Paraes_ols,filename=Paraes_ols);
	%if "&flagVif."="true" and "&autoregressiveLags."="true" %then %do;
		
	  	proc sort data=vif_params;
	        by variable;
	        run;
		%let dset=out.paraes_autoreg;
		%let dsid = %sysfunc(open(&dset));
		%let nobs =%sysfunc(attrn(&dsid,NOBS));
		%let rc = %sysfunc(close(&dsid));
		%if &NOBS. ^= 0 %then %do;
		  proc sort data=out.paraes_autoreg;
		        by Variable;
		        run;

		  data out.Paraes_autoreg(drop=StandardizedEst);
		        merge out.Paraes_autoreg(in=a) vif_params(in=b);
		        by Variable;
		        if a;
		        run;
		%end;
		%else %do;
			 data out.Paraes_autoreg;
		        set vif_params;
		        run;
		%end;
	%end;

	%exportCsv(libname=out,dataset=paraes_autoreg,filename=paraes_autoreg);

/* Separate the Summary stats for OLS and Autoreg*/

	%let dsid = %sysfunc(open(Fitsummary));
	%let nobs =%sysfunc(attrn(&dsid,NOBS));
	%let rc = %sysfunc(close(&dsid));

	data  stats_ols stats_autoreg;
		set Fitsummary;
		if _n_ <= %sysevalf(&nobs./2) then do;
			output stats_ols;
		end;
		else do;
			output stats_autoreg;
		end;
		run;
	%if "&autoregressiveLags."="true" %then %do;
		%let dataset=Stats_ols stats_autoreg;
	%end;
	%else %do;
		%let dataset=Stats_ols;
	%end;

	%let dataset_wid_obs = ;
	%let dset=Stats_ols;
		%let dsid = %sysfunc(open(&dset));
		%let nobs =%sysfunc(attrn(&dsid,NOBS));
		%let rc = %sysfunc(close(&dsid));
		%if &NOBS. ^= 0 %then %do;
			%let dataset_wid_obs = &dataset_wid_obs. Stats_ols;
		%end;
	%let dset=stats_autoreg;
		%let dsid = %sysfunc(open(&dset));
		%let nobs =%sysfunc(attrn(&dsid,NOBS));
		%let rc = %sysfunc(close(&dsid));
		%if &NOBS. ^= 0 %then %do;
			%let dataset_wid_obs = &dataset_wid_obs. stats_autoreg;
		%end;
	%put &dataset_wid_obs.;

/*.......................Model Stats....................................*/
	%do i=1 %to %sysfunc(countw(&dataset_wid_obs.));
		/* SSE and DFE*/
			data _NULL_;
				set %scan(&dataset_wid_obs.,&i.)(firstobs = 1 obs = 1);
				Call symput("SSE",nValue1);
				Call symput("DFE",nValue2);
				run;
		/* MSE and RootMSE*/
			data _NULL_;
				set %scan(&dataset_wid_obs.,&i.)(firstobs = 2 obs = 2);
				Call symput("MSE",nValue1);
				Call symput("RootMSE",nValue2);
				run;
		/* SBC and AIC*/
			data _NULL_;
				set %scan(&dataset_wid_obs.,&i.)(firstobs = 3 obs = 3);
				Call symput("SBC",nValue1);
				Call symput("AIC",nValue2);
				run;
		/*Regress RSquare and Total RSquare*/

			 proc sql;
			 select nValue2 into:Regress_RSq from %scan(&dataset_wid_obs.,&i.) where label2 = "Regress R-Square";
			 quit;
			 proc sql;
			 select nValue2 into:Total_RSq from %scan(&dataset_wid_obs.,&i.) where label2 = "Total R-Square";
			 quit;
/*			data _NULL_;*/
/*				set %scan(&dataset_wid_obs.,&i.)(firstobs = 4 obs = 4);*/
/*				Call symput("Regress_RSq",nValue1);*/
/*				Call symput("Total_RSq",nValue2);*/
/*				run;*/
		/*Durbin_Watson*/
			%if &laggedDependentVariable.=false or (&laggedDependentVariable.=true and %scan(&dataset_wid_obs.,&i.)=stats_autoreg) %then %do;
				proc sql;
				select label1 into:tempvalue separated by " " from %scan(&dataset_wid_obs.,&i.);
				quit;
				%if %index("&tempvalue.","Durbin-Watson") > 0 %then %do;
				proc sql;
			 	select nValue1 into:Durbin_Watson from %scan(&dataset_wid_obs.,&i.) where label1 = "Durbin-Watson";
			 	quit;
				%end;	
/*				data _NULL_;*/
/*					set %scan(&dataset_wid_obs.,&i.)(firstobs = 5 obs = 5);*/
/*					Call symput("Durbin_Watson",nValue1);*/
/*					run;*/
			%end;
		/*NO. OF VARIABLES and observations USED IN THE ITERATION*/
			%let op = %sysfunc(open(out.paraes_ols));
			%let variables_used = %sysfunc(attrn(&op,nobs));
			%let ol = %sysfunc(close(&op));

			%let op1 = %sysfunc(open(out.outdata));
			%let Observations_used = %sysfunc(attrn(&op1,nobs));
			%let ol = %sysfunc(close(&op1));
			%put &Observations_used;
		/* MAPE */
			proc sql;
				create table mapevalue as 
				select avg(mapeindi)*100 as mape 
				from out.outdata;
				quit;
			proc sql noprint;
				select mape into :mape from mapevalue;
				quit;
		/* mean of dependent */
			proc sql;
				select avg(&dependentVariable.) into: mean_dependent from &datasetName.;
				quit;
			data out.fitsummary_%scan(&dataset_wid_obs.,&i.);
				SSE=&SSE.;
				DFE=&DFE.;
				MSE=&MSE.;
				RootMSE=&RootMSE.;
				SBC=&SBC.;
				AIC=&AIC.;
				Regress_RSquare=&Regress_RSq.;
				Total_RSquare=&Total_RSq.;
				%if &laggedDependentVariable.=false or (&laggedDependentVariable.=true and %scan(&dataset.,&i.)=stats_autoreg) %then %do;
					%if %index("&tempvalue.","Durbin-Watson") > 0 %then %do;
					Durbin_Watson=&Durbin_watson.;
					%end;
					%else %do;
					Durbin_Watson="NA";
					%end;
				%end;
				mape=&mape.;
				mean_dependent=&mean_dependent.;
				variables_used=&variables_used.-1;
				Observations_used=&Observations_used.;
				run;
		%exportCsv(libname=out,dataset=fitsummary_%scan(&dataset_wid_obs.,&i.),filename=fitsummary_%scan(&dataset_wid_obs.,&i.));
		%end;
		/*	Stepwise */
		%if "&stepwise." = "true" %then %do;
			%if %sysfunc(exist(insignificant)) %then %do;
			data insignificant;
				set insignificant;
				significance="insignificant";
				run;
			%end;

			%if %sysfunc(exist(significant)) %then %do;
			data significant;
				set significant;
				significance="significant";
				run;
			%end;

			%if %sysfunc(exist(insignificant)) or %sysfunc(exist(significant)) %then %do;
				data stepwise;
					set  %if %sysfunc(exist(insignificant)) %then %do;
							insignificant 
						 %end; 
						 %if %sysfunc(exist(significant)) %then %do;
							significant
						 %end;
						 ;
					run;
				%exportCsv(libname=work,dataset=stepwise,filename=stepwise);
			 %end;
		%end;

		/* Autocorrelation */
			%if "&numberOfLags." ^="" or "&customLags." ^= ""%then %do;
				%if %sysfunc(exist(autocorr)) %then %do;
					data autocorr;
						set autocorr(keep=Autocorr lag);
						run;
				%exportCsv(libname=work,dataset=autocorr,filename=autocorr);
				%end;
			%end;
	%let textToReport=&textToReport. PostAutoreg completed;
%mend postautoreg;
%autoreg;
%postautoreg;
proc datasets lib=work;
delete dummydata;
run;

data _null_;
      v1= "&textToReport.";
      file "&outputPath/AUTOREG_COMPLETED.txt";
      put v1;
      run;
