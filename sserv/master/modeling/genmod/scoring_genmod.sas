/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &outputPath/GENMOD_COMPLETED.txt;
/****************
Genmod v1.2 is modified for usage by Plymouth Rock. Modifications made:
	1. Convergence status, model information and Tweedie P value obtained and put in Model Statistics
	2. Implemented phi, weight and offset variables
	3. Implemented optimisation of Tweedie "p" using nlmix (optimizeCustomP)
	*4. Obtained deciled Actual vs. Predicted chart
	5. Changed Type 1 test to be optional (from front-end) and modified output files accordingly
	6. Provided option of providing scale parameter as deviance or none

Areas of code are denoted by the following: "Genmod v1.2 EDIT START" and ended by "Genmod v1.2 EDIT END"

NOTE: Output of model is required for these two operations:
	1. Export residuals
	2. Optimize tweedie P value
	As of this code update output is produced in every iteration - 
	if this is modified for space optimization later, please keep above note in mind
*****************/

%let textToReport=;
%let output_path = &outputPath.;

%macro genmod1;

	data bygroupdata;
		set &datasetName.;
		if &validationVar. = 1 then predicted_1 = &dependentVariable.; 
		else predicted_1 = .; 
		run;
	
	/* Genmod v1.2 EDIT START */
	ods output ModelInfo=model_info (rename=(Label1=Statistics cValue1=Value) keep=Label1 cValue1);
	ods output ConvergenceStatus=convergence_status;
	/* Genmod v1.2 EDIT END */

	/* ods output ModelInfo=model_info; */
	ods output NObs = nob;
	ods output ClassLevels=classlvl;
	ods output ModelFit = fit_stats;
	ods output type1=type1(rename=(ChiSq=Type1ChiSq ProbChiSq=Type1PValue Source=Variable));
	ods output type3=type3(rename=(ChiSq=Type3ChiSq ProbChiSq=Type3PValue Source=Variable));
	ods output ParameterEstimates=params(rename=(Parameter=Variable ProbChiSq=PValue));
    /* running genmod */
	
	proc genmod data = bygroupdata;
		/* Set class variables */
		%if "&classVariables." ^= "" %then %do;
			class &classVariables.;
		%end;
		/* Weight variable */
		%if "&weightVariable." ^= "" %then %do;
			weight &weightVariable.;
		%end;	
		/* Set mathematical distribution if tweedie distrubtion selected */
		%if &flagTweedieDistribution.=true %then %do;
			p=&tweedieP.;
			y=_resp_;
			a=_mean_;
			if (y gt 0) then
				d=2*(y*(y**(1-p)-a**(1-p))/(1-p)-(y**(2-p)-a**(2-p))/(2-p));
			else 
				d = 2*(a**(2-p))/(2-p);
			VARIANCE bar=a**p;
			DEVIANCE dev=d;
		%end;
		/* Model statement */
        model predicted_1 = &independentVariables./ &modelOptions. 
		/* Set tweedie distribution link function and scale */
			%if &flagTweedieDistribution.=true %then
			LINK=log %if &flagTweedieScale.=true %then SCALE=d; %else NOSCALE;
			/* Set auto distribution if tweedie distribution is false */
			%else %do;
				dist=&distribution.
			%end;
			/* Offset variable */
			%if "&offsetVariable."^="" %then %do;
				offset=&offsetVariable.
			%end;
		;
		/* Get output dataset with residuals */
    output out=genmodout pred=pred reschi=reschi resdev=resdev stdreschi=stdreschi stdresdev=stdresdev;
	run; quit;
	%let textToReport=&textToReport. Genmod completed;
%mend;

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
		goptions device =  png300 Transparency gsfname=image gsfmode=replace;
		footnote1 h = .5 '  ';
		
		symbol1 font = marker value=U height=.3 color=orange width=20;
		axis1 label=('Predicted');
		axis2 label=('Actual');
	
		proc gplot data= &dataset;
			plot Predicted*actual/anno=anno vaxis=axis1 haxis=axis2 ;
		run;

		ods listing close;
		ods graphics off;
		/*---------------------------------------------------------*/

		/*Predicted Vs Residual Plot*/
		ods graphics on/ width=20in height=20in;
		ods listing;
		filename image "&outputpath./PredictedvsResidual.png";
		goptions device =  png300 Transparency gsfname=image gsfmode=replace;
		footnote1 h = .5 '  ';
	
		symbol1 font = marker value=U height=.3 color=orange;
		axis1 label=('Predicted');
		axis2 label=('Residual');
	
		proc gplot data= &dataset;
			plot Predicted*Residual/vaxis=axis1 haxis=axis2 ;
		run;

		ods listing close;
		ods graphics off;
		/*---------------------------------------------------------*/

		/*Residual Vs Actual Plot*/
		ods graphics on/ width=20in height=20in;
		ods listing;
		filename image "&outputpath./ResidualvsActual.png";
		goptions device =  png300 Transparency gsfname=image gsfmode=replace;
		footnote1 h = .5 '  ';
	
		symbol1 font = marker value=U height=.3 color=orange;
		axis1 label=('Residual');
		axis2 label=('Actual');
	
		proc gplot data= &dataset;
			plot actual*Residual/vaxis=axis1 haxis=axis2 ;
		run;

		ods listing close;
		ods graphics off;
		/*---------------------------------------------------------*/
	%end; 
%mend;

%macro postgenmod1;

%if "&validationType." = "validation" %then %do;
 data genmodout;
 	set genmodout;
	where &validationVar.= 0;
%end;


	/*Nob*/
	data Nob(keep=Statistics Value);
	    format Value $200.;
	    set Nob(rename=(label=Statistics));
	    Value=compress(n);
	    run;

	/*Class Level*/
	%if "&classVariables." ^= "" %then %do;
	      data classlvl1(rename=(Class1=Statistics) drop=values class levels);
	            set classlvl;
	            format Class1 $20.;
	            format Value $200.;
	            Value=compress(Levels);
	            Class1=trim(left(cat(trim(right(Class))," ",("Levels"))));
	            label Class1=Statistics;
	            run;

	      data classlvl2(rename=(Class1=Statistics ) drop=levels class values);
	            set classlvl;
	            format Class1 $20.;
	            format Value $200.;
	            Value=trim(left(Values));
	            Class1=trim(left(cat(trim(right(Class))," ",("Values"))));
	            label class1=Statistics;
	            run;

	      data classlvl3(keep=Statistics Value);
	            set classlvl1 classlvl2;
	            run;
	%end;

	/*Model Output*/
	data out.genmodoutput;
		retain &actual. pred resid reschi resdev stdreschi;
	    set genmodout(keep= &actual. pred reschi resdev stdreschi stdresdev);
		resid=&actual.-pred;
	    run;

	/* MAPE */ 
	proc sql;
		create table mape as
			select "Mape" as statistics, (sum(absolute_resid)*100)/sum(pred) as value from
			(select case when resid<0 then -resid else resid end as absolute_resid, pred from out.genmodoutput);
	quit;
	data mape (drop=value_num);
		set mape (rename=(value=value_num));
		format value $20.;
		value=value_num;
	run;
	
    /*Model Statistics*/
	data fit_stats (keep=statistics value);
		set fit_stats(rename=(value=temp criterion=statistics));
		value=put(temp,20.0);
		run;

/*********************
Genmod v1.2 EDIT START
*********************/

	/* Convergence status */
	data convergence_status;
		set convergence_status(rename=(Reason=Value) drop=Status);
		format Statistics $18.;
		Statistics="Convergence status";
	run;
	/* Model information */
	proc sql;
		delete from model_info where Statistics="Data Set";
		%if &flagTweedieDistribution.=true %then insert into model_info values("Tweedie P value", "&tweedie_pvalue.");;
	quit;

	data model_statistics(keep=Statistics Value);
		format Statistics $27.;
		format Value $200.;
		set model_info convergence_status nob fit_stats mape %if "&classVariables." ^= "" %then %do; classlvl3 %end;;
		run;

/*********************
Genmod v1.2 EDIT END
*********************/

	/* Model information */
	/* Create temporary dataset containing individual variables in case both type1 and type3 are not created */
	proc sql;
		create table model_ as
			select distinct Variable from params;
		delete from model_ where Variable="Scale";
	quit;
	%if %sysfunc(exist(type1)) %then %do;
		proc sort data=type1;
			by Variable;
		quit;
	%end;
	%if %sysfunc(exist(type3)) %then %do;
		proc sort data=type3;
			by Variable;
		quit;
	%end;
	data model;
		/* Genmod v1.2 EDIT START - merge only if type1 exists */
		%if %sysfunc(exist(type1)) %then %do;
			merge type1(in=a) type3(in=b);
			by Variable;
			if a OR b;
		%end;
		%else %if %sysfunc(exist(type3)) %then %do;
			set type3;
		%end;
		%else %do;
			set model_;
		%end;
		/* Genmod v1.2 EDIT END */
	run;
	%if &flagVif=true %then %do;
		proc sort data=model;
			by Variable;
		quit;
		proc sort data=vif_params;
			by Variable;
		quit;
		data model;
			length Variable $50.;
			merge vif_params(in=a) model(in=b);
			by Variable;
			if a OR b;
		run;
	%end;

	/* Actual Predicted */
	data actual_predicted(rename=(&actual.=newactual pred=Predicted resid=Residual));
		set out.genmodoutput (keep=&actual. pred resid);
		run;
	data actual_predicted(rename=(newactual=Actual));
		set actual_predicted;
		run;	
	 data model_statistics;
		set model_statistics;
		if Value = "User" then Value = "Tweedie";
		run;
	  data params(rename=(Level1=Level));
		set params;
		if Estimate	 = 0 then delete;
		run;
	%plots(actual_predicted);
	%exportCsv(libname=work,dataset=model,filename=Model);
	%exportCsv(libname=work,dataset=actual_predicted,filename=ActualvsPredicted);
	%exportCsv(libname=work,dataset=model_statistics,filename=ModelStatistics);
	%exportCsv(libname=work,dataset=params,filename=ParameterEstimates);

	%let textToReport=&textToReport. PostGLM completed;
%mend;

%genmod1;
%postgenmod1;

%macro outputs1;
%if &flagRankOrderedOutput.=true %then %do;
	data outputs;
		set genmodout;
		%if &weightVariable.^= %then %do;
			weighted_pred=&weightVariable. * pred;
			weighted_&actual.=&weightVariable. * &actual.;
		%end;
	run;
	proc rank data = genmodout out = outputs (keep = Quantiles pred &actual. _FROM_ &weightVariable.) Groups = %sysevalf(&numberOfGroups.) descending ;
	    var pred;
	    ranks Quantiles;
	proc sort data = outputs;
	    by Quantiles;
	quit;

	/* Calculate average y and y` differently if weight specified */
	%if &weightVariable.^= %then %do;
		proc sql;
		    create table rank_ordered_chart as
			select Quantiles, Predicted, Actual, avg(actual) as Mean, (predicted/actual) as PredictedByActual, Weight
			from (select Quantiles, (sum(pred*&weightVariable.)*100)/sum(&weightVariable.) as Predicted, (sum(&actual. * &weightVariable.)*100)/sum(&weightVariable.) as Actual, sum(&weightVariable.) as Weight
				from outputs
			    group by Quantiles)
			;
		quit;
	%end;
	%else %do;
		proc sql;
		    create table rank_ordered_chart as
			/* select quantiles, avg(pred)*100 as predicted, (sum(CASE WHEN _FROM_="0" THEN 1 ELSE 0 END)/count(*))*100 as actual */
			select Quantiles, Predicted, Actual, avg(actual) as Mean, (predicted/actual) as PredictedByActual
			from (select Quantiles, avg(pred)*100 as Predicted, avg(&actual.)*100 as Actual
				from outputs
			    group by Quantiles)
			;
		quit;
	%end;
	%exportcsv(libname=work,dataset=rank_ordered_chart,filename=RankOrderedChart);
%end;
%mend;

%outputs1;

data _null_;
      v1= "&textToReport.";
      file "&outputPath/GENMOD_COMPLETED.txt";
      put v1;
      run;
 
