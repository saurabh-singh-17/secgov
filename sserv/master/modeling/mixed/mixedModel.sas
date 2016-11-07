/*Successfully converted to SAS Server Format*/
*processbody;




%macro mixed_subreptest;

	
	%global error;
	%let error=0;

	data temp;
		set in.dataworking(keep=&repeated_subject. &repeated_variable.);
	run;

	proc contents data=temp out=contents_temp;
	run;
	quit;

	proc sql;
		select sum(length) into: sum_length from contents_temp;
	quit;

	data temp;
		length muRx_temp_var $&sum_length.;
		set temp;
		muRx_temp_var=cat(&repeated_subject.,&repeated_variable.);
	run;

	proc sql;
		select count(distinct(muRx_temp_var)) into: count_distinct from temp;
		select count(*) into: count_star from temp;
	quit;

	%if &count_distinct. ^= &count_star. %then %let error=1;

%mend mixed_subreptest;

%let textToReport=;
%macro chk_constraint;
	%let zero = ;
	%do a = 1 %to %sysfunc(countw(&independentVariables.," "));
		%let ind=%scan(&independentVariables.,&a., " ");
		%let trans=%scan(&independentTransformation.,&a., " ");
			%if "&trans." = "log" %then %do;
				proc sql;
					select distinct &ind. into: uniqueval separated by " " from in.dataworking;
					quit;
				%if %index(&uniqueval. , 0) ^= 0 %then %do;
					%let zero = &zero. &ind. has 0 values. ;
				%end;
			%end;
	%end;
	%put &zero.;
%mend chk_constraint;

%macro transformations;

%let independent_variable = ;
%do i=1 %to %sysfunc(countw(&independentVariables.));
	%let independent_var=%scan(&independentVariables.,&i.);
	%let independent_trans=%scan(&independentTransformation.,&i.);
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
%let independentVariables = &independent_variable.;
%put &independentVariables.;

%if "&dependentTransformation."="log" %then %do;
	data group.bygroupdata;
		set group.bygroupdata;
		log_&dependentVariable.= log(&dependentVariable. + 1);
		run;

	%let dependentVariable =log_&dependentVariable.;
%end;
%mend transformations;

%Macro mixed;
	%if %index("&classVariables.","&subject.") = 0 %then %do;
		%let classVariables=&classVariables. &subject.;
	%end;
	%put &classVariables.;
	/* Assign dataset names for the respective outputs generated*/
	ods output ModelInfo = modelinfo;
	ods output Dimensions = dimensions;
	ods output Nobs = nob;
	ods output ClassLevels = classlvl;
	ods output IterHistory = iterhistory;
	ods output ConvergenceStatus = convstatus;
	ods output CovParms = covparamest(rename =(CovParm = CovarianceParameter));
	ods output FitStatistics = fit_stats;
	ods output LRT = lrt;
	ods output SolutionF = fixedeffect(rename =(StdErr=StandardError Effect = Variable Probt=PValue));
	ods output SolutionR = randomeffect(rename =(StdErr=StandardError Effect = Variable Probt=PValue));
	ods output Tests3 = type3(rename =(Effect = Variable));
	ods output Tests2 = type2(rename =(Effect = Variable));
	ods output Tests1 = type1(rename =(Effect = Variable));
	ods output Coef = LMatrixCoef(rename =(Effect = Variable));
	ods output LSMeans=LSMeans(rename =(StdErr=StandardError Effect = Variable Probt=PValue));
	ods output Diffs=diff(rename=(Effect=Variable));	
	/*Run Mixed Modeling*/ 
	proc mixed data = &datasetname. method = &method. maxiter = &maxiter. maxfunc = &maxfunc. namelen=150;
							/*Set Class Variables*/
							%if "&classVariables." ^= "" %then %do;
	                      			   class &classVariables.;
							%end;
							/*Model Statement*/
	                        model &dependentVariable. = &independentVariables./ outp = mixedout chisq &modelOptions.;
							/*Set Random Effect Variables*/
							%if "&RandomVariables." ^= "" %then %do;
								%if "&RandomVariables"^= "Intercept" %then %do;
									%if "&RandomOptions"^= "" %then %do;
		                                Random &RandomVariables./ &RandomOptions.;
		                            %end;
		                            %else %do;
		                                Random &RandomVariables.;
		                            %end;
								%end;
								%else %do;
									Random &RandomVariables./ &RandomOptions. subject=&subject.;
								%end;
							%end;
							%if "&repeated_variable." ^= "" %then %do;
	                                Repeated &repeated_variable./ subject=&repeated_subject. type = &repeated_type.;
							%end;
							/*Set LSMeans Variables*/
							%if "&lsMeansVariables." ^= "" %then %do;
							
								%if "&lsMeansOptions"^= "" %then %do;
	                                lsmeans &lsMeansVariables./ &lsMeansOptions.;
	                            %end;
	                            %else %do;
	                                lsmeans &lsMeansVariables. ;
	                            %end;
							%end;
							/*Check if validation is selected*/
		                    %if "&validationVar" ^= "" %then %do;
		                          %if "&validationType." = "build" %then %do;
		                                where &validationVar. = 1;
		                          %end;
		                          %if "&validationType." = "validation" %then %do;
		                                where &validationVar. = 0;
		                          %end;
		                    %end;

				run; 
				quit;

	%let textToReport=&textToReport. Mixed completed;
%Mend mixed; 

%Macro plots(dataset,pref);
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
		filename image "&outputpath./&pref.PredictedvsActual.png";
		goptions reset=all device =  png300 Transparency gsfname=image gsfmode=replace;
		footnote1 h = .5 '  ';
		
		symbol1 font = marker value=U height=.3 color=orange width=20;
		axis1 label=('Predicted');
		axis2 label=('Actual');
	
		proc gplot data= &dataset;
			plot predicted*actual/anno=anno vaxis=axis1 haxis=axis2 ;
		run;

		ods listing close;
		ods graphics off;
		/*---------------------------------------------------------*/

		/*Predicted Vs Residual Plot*/
		ods graphics on/ width=20in height=20in;
		ods listing;
		filename image "&outputpath./&pref.PredictedvsResidual.png";
		goptions reset=all device =  png300 Transparency gsfname=image gsfmode=replace;
		footnote1 h = .5 '  ';
	
		symbol1 font = marker value=U height=.3 color=orange;
		axis1 label=('Predicted');
		axis2 label=('Residual');
	
		proc gplot data= &dataset;
			plot predicted*residual/vaxis=axis1 haxis=axis2 ;
		run;

		ods listing close;
		ods graphics off;
		/*---------------------------------------------------------*/

		/*Residual Vs Actual Plot*/
		ods graphics on/ width=20in height=20in;
		ods listing;
		filename image "&outputpath./&pref.ResidualvsActual.png";
		goptions reset=all device =  png300 Transparency gsfname=image gsfmode=replace;
		footnote1 h = .5 '  ';
	
		symbol1 font = marker value=U height=.3 color=orange;
		axis1 label=('Residual');
		axis2 label=('Actual');
	
		proc gplot data= &dataset;
			plot residual*actual/vaxis=axis1 haxis=axis2 ;
		run;

		ods listing close;
		ods graphics off;
		/*---------------------------------------------------------*/

		/*Predicted Vs Actual Plot*/
		ods graphics on/ width=20in height=20in;
		ods listing;
		filename image "&outputpath./&pref.ActualvsPredicted.png";
		goptions reset=all device =  png300 Transparency gsfname=image gsfmode=replace;
		footnote1 h = .5 '  ';
	
		symbol1 font = marker i=join value=U height=.3 color=orange;
		symbol2 font = marker i=join value=U height=.3 color=green;
		axis1 label=('Dataset Order');
		axis2 label=('Actual and Predicted');
	
		proc gplot data= &dataset;
			plot (actual predicted)*primary_key_1644/overlay vaxis=axis1 haxis=axis2 ;
		run;

		ods listing close;
		ods graphics off;

	%end; 
%mend;

%Macro postMixed;
	/*Covariance Parameter Estimates*/
		data covparamest;
			set covparamest;
			if index(CovarianceParameter,",") >0 then
				CovarianceParameter = tranwrd(CovarianceParameter,",","|");
			run;
	/*Nob*/
	data nob(keep=Statistics Value);
		format Value $250.;
		set nob(rename=(label=Statistics));
		Value=compress(n);
		run;
	/*Class Level*/
	%if "&classVariables." ^= "" %then %do;
	      data classlvl1(rename=(Class1=Statistics) drop=values class levels);
	            set classlvl;
	            format Class1 $20.;
	            format Value $250.;
	            Value=compress(Levels);
	            Class1=trim(left(cat(trim(right(Class))," ",("Levels"))));
	            label Class1=Statistics;
	            run;

	      data classlvl2(rename=(Class1=Statistics ) drop=levels class values);
	            set classlvl;
	            format Class1 $20.;
	            format Value $250.;
	            Value=trim(left(Values));
	            Class1=trim(left(cat(trim(right(Class))," ",("Values"))));
	            label class1=Statistics;
	            run;

	      data classlvl3(keep=Statistics Value);
	            set classlvl1 classlvl2;
	            run;
	%end;
	/*Likelihood Ratio Test*/
	%if %sysfunc(exist(lrt)) %then %do;
    	%put exists;
   		proc transpose data=lrt out = lrt_trans(drop = _LABEL_ rename =( col1 = Value));
			run;
		data lrt(drop = _NAME_ value rename = (val=value));
			length Statistics $27.;
			format Statistics $27.;
			length Type $27.;
			format Type $27.;
			length val $250.;
			format val $250.;
			set lrt_trans;
			val=put(value,20.7);
			Type = 'Likelihood Ratio Test';
			if (_NAME_ = 'DF') then
				Statistics = 'Degrees of Freedom';
			else
				Statistics = _NAME_;
			run;
		data lrt;
			set lrt;
			value=compress(value);
			run;
	%end;
	/*FitStats*/
	data fit_stats_t(drop = value rename = (descr = Statistics val=value));
	    set fit_stats;
	    format descr $250.;
		format val $250.;
	    descr=compress(descr);
		val=put(value,20.7);
	    run;
	/*Model Output*/
	data out.mixedoutput;
	    set mixedout(keep= &dependentVariable. pred resid stderrpred);
		primary_key_1644=_n_;
	    perc_err=abs(resid)*100/&dependentVariable.;
	    Actual= &dependentVariable.;
	    run;
	/*MAPE*/
	proc sql;
	    create table Mape as
	          select "MAPE" as Statistics, avg(perc_err) as Val
	          from out.mixedoutput;
	    quit;

	data Mape(drop=Val);
	    set Mape;
	    format Value $250.;
	    Value=compress(Val);
	    run;
	data fit_stats_t;
		set fit_stats_t;
		value=compress(value);
		run;
	/*Model Statistics*/
	%if "&classVariables." ^= "" %then %do;
	data model_statistics(keep=Statistics Value);
	    format Statistics $50.;
		length Statistics $50.;
	    set classlvl3 nob fit_stats_t MAPE;
	    run;
	%end;
	%else %do;
	data model_statistics(keep=Statistics Value);
	     format Statistics $50.;
		length Statistics $50.;
	    set nob fit_stats_t MAPE;
	    run;
	%end;
	data model_statistics;
		set model_statistics;
		length Type $50.;
		format Type $50.;
		Type = 'Model Statistiscs';
		run;
	%if %sysfunc(exist(lrt)) %then %do;
                  
		data model_statistics;
			set model_statistics lrt;
			run;
	%end;

	/*Actual vs Predicted*/
	data actpred(rename = (pred = Predicted));
		set out.mixedoutput(keep = actual pred);
		Residual=actual-pred;
		primary_key_1644=_n_;
		run;
	
	/* Log - log transformation */
	%if "&dependentTransformation."="log" %then %do;
		data actpred1;
			set actpred;
			predicted= exp(predicted);
			actual = exp(actual);
			residual = exp(residual);
			run;

	  %exportCsv(libname=work,dataset=actpred1,filename=normal_chart);
      %plots(actpred1,);
	  %exportCsv(libname=work,dataset=actpred,filename=transformed_chart);
	  %plots(actpred,Log);
	%end;
	%else %do;
		%exportCsv(libname=work,dataset=actpred,filename=normal_chart);
		%plots(actpred,);
	%end;

	/*Merging Type3 and Type1 Test Results*/
	proc sort data= type1 out = type1(rename =(numdf=type1NumDF dendf = type1DenDF chisq = type1ChiSq fvalue=type1FValue ProbChiSq=type1PValueChiSq ProbF = type1PValueF));
		by variable;
		run;
	proc sort data= type3 out = type3(rename =(numdf=type3NumDF dendf = type3DenDF chisq = type3ChiSq fvalue=type3FValue ProbChiSq=type3PValueChiSq ProbF = type3PValueF));
		by variable;
		run;

	data type1;
		set type1;
		length Original_Variable $50.;
		if substr(Variable,1,4) = "log_" then Original_Variable = substr(Variable , 5 , length(Variable));
		else Original_Variable = Variable;
		run; 

	data type3;
		set type3;
		length Original_Variable $50.;
		if substr(Variable,1,4) = "log_" then Original_Variable = substr(Variable , 5 , length(Variable));
		else Original_Variable = Variable;
		run; 

	proc sort data = type1;
		by Original_Variable;
		quit;

	proc sort data = type3;
		by Original_Variable;
		quit;

	data model;
		merge type3 (in = a) type1 (in =b);
		by Original_Variable;
		if a or b;
		run;
	/*check if vif option is selected*/
	%if &flagVif=true %then %do;
		
		data vif_params(rename = Variable = Original_variable);
			set vif_params;
			run;
		proc sort data=vif_params;
			by original_variable;
			quit;
		data model;
			merge model(in=b) vif_params(in=a) ;
			by Original_variable;
			if a OR b;
			run;
	%end;

	data model;
	  set model;
	  length Iteration_transformation $10.;
	  length Original_Variable $50.;
	  if substr(Variable,1,4) = "log_" then Iteration_transformation = "log";
	  else if Original_Variable ^= "Intercept" then Iteration_transformation = "none";
	  else Iteration_transformation = " ";
	  run;
	
	data model(rename = Original_Variable = Variable);
		set model(drop = Variable);
		run;
	/*Export results*/
	%if ("&lsMeansVariables." ^= "") %then %do;
		%exportCsv(libname=work,dataset=lsmeans,filename=LSMeans);
		%if %index(&lsMeansOptions.,diff)>0 %then %do;
			%exportCsv(libname=work,dataset=diff,filename=DifferenceMatrix);
		%end;
	%end;
	%if ("&randomVariables." ^= "") %then %do;
	data randomeffect;
		set randomeffect;
		format estimate D17.16;
		run;		
		%exportCsv(libname=work,dataset=randomeffect,filename=RandomEffect);
	%end;
	%exportCsv(libname=work,dataset=Lmatrixcoef,filename=LMatrixcoefficients);
	%exportCsv(libname=work,dataset=model_statistics,filename=ModelStats);
	%exportCsv(libname=work,dataset=model,filename=model);
	data fixedeffect;
		set fixedeffect;
		format estimate D17.16;
		run;
	%exportCsv(libname=work,dataset=fixedeffect,filename=FixedEffect);
	%if %sysfunc(exist(convstatus)) %then %do;
    	%exportCsv(libname=work,dataset=convstatus,filename=ConvergenceStatus);
    %end;
	%exportCsv(libname=work,dataset=covparamest,filename=CovParamEstimates);
	%exportCsv(libname=work,dataset=modelinfo,filename=ModelInfo);
	%if %sysfunc(exist(iterhistory)) %then %do;
    	%exportCsv(libname=work,dataset=iterhistory,filename=IterationHistory);
    %end;
	%let textToReport=&textToReport. PostMixed completed;
%Mend postMixed;

%Macro result;
%let convstatus =;
	%if %sysfunc(exist(convstatus)) %then %do;
		proc sql;
			select reason into :convstatus separated by " " from convstatus;
			quit;
	%end;
	data _null_;
      v1= "&textToReport.";
	  conv = "&convstatus.";
      file "&outputPath/MIXED_COMPLETED.txt";
	  put conv;
	  put v1;
      run;

%Mend result;

%macro mixed_call_all_macros;
	/* Validation check */
	%if "&repeated_subject." ^= "" and "&repeated_variable." ^= "" %then
		%do;
			%mixed_subreptest;
			
			/* If the check fails then write error.txt and stop */
			%if &error. = 1 %then
				%do;
					data _null_;
						v1= "The levels of repeated measure was not unique for each subject level.";
						file "&outputpath./error.txt";
						put v1;
					run;

					%abort;
				%end;
		%end;
	/* All the other stuff */
	%chk_constraint;
	%transformations;
	%put &independentVariables.;
	%put &dependentVariable.;
	%mixed;
	%postMixed;
	%result;
%mend mixed_call_all_macros;
%mixed_call_all_macros;