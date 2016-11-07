/*Mixed Modeling Forecast*/
*processbody;
options mprint mlogic symbolgen mfile;

proc printto log="&outputPath./MixedModel_Log.log";
run;
quit;
/*proc printto print="&outputPath./GeneralLinearModel_output.out";*/
/*      quit;*/
/*proc printto;*/
/*run;*/
%let textToReport=;

%Macro plots(dataset, pngname, xaxis);
                %let dsid = %sysfunc(open(&dataset));
                %let nobs =%sysfunc(attrn(&dsid,NOBS));
                %let rc = %sysfunc(close(&dsid));

                %if &nobs. > 55 %then %do;       
                                
                                /*Forecast Plots*/
                                ods graphics on/ width=20in height=20in;
                                ods listing;
                                filename image "&output_path./&pngname.png";
                                goptions device = pngt gsfname=image gsfmode=replace;
                                footnote1 h = .5 '  ';
                
                                symbol1 font = marker i=join value=U height=.3 color=orange;
                                symbol2 font = marker i=join value=U height=.3 color=blue;
                                symbol3 font = marker i=join value=U height=.3 color=green;
                                axis1 label=('%xaxis');
                                axis2 label=('Dependent Variable');
                                
                                proc gplot data= &dataset;
                                plot actual*&xaxis pred*&xaxis forecast*&xaxis/vaxis=axis2 haxis=axis1 ;
                                run;

                                ods listing close;
                                ods graphics off;

                %end; 
%mend;

%Macro mixed;
libname in  "&inputPath.";
libname group "&groupPath.";
libname out "&outputPath.";

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
	proc mixed data = &datasetname. method = &method. maxiter = &maxiter. maxfunc = &maxfunc. ;
							/*Set Class Variables*/
							%if "&classVariables." ^= "" %then %do;
	                      			   class &classVariables.;
							%end;
							/*Model Statement*/
	                        model &dependentVariable. = &independentVariables./ outp = mixedout chisq &modelOptions.;
							/*Set Random Effect Variables*/
							%if "&RandomVariables." ^= "" %then %do;
								%if "&RandomOptions"^= "" %then %do;
	                                Random &RandomVariables./ %if "&subject" ne "" %then %do; subject=&subject. %end; &RandomOptions.;
	                            %end;
	                            %else %do;
	                                Random &RandomVariables.  %if "&subject" ne "" %then %do; subject=&subject. %end;;
	                            %end;
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
							where &validationVar. = 0 or &validationVar. = 1 or &validationVar.=2;
							run; quit;

							proc sql;
							create table mixedout1 as
							select * from mixedout 
							where &validationVar. = 0 or &validationVar. = 1;
							run; quit;

							data mixedout1;
							set mixedout1;
							actual = &dependentVariable.;
							run;


							proc sql;
							create table abc as
							select * from mixedout 
							where &validationVar. = 2;
							run; quit;

							data abc( rename =(pred=Forecast));
							set abc;
							actual = . ;
							run;


data mixedout;
   set mixedout1 abc;
   run;



	%let var=;
	%if "&var_type." = "time_var" %then %do;
	%let var = &var_name.;
	%end;
	%else %do;
	%let var = primary_key_1644;
	%end;
	%put &var.;


data out.forecast_charts(keep = &var. actual pred Forecast &subject.);
set mixedout;
run;

  %if "&subject." ^= "" %then %do;
	proc sql;
	select distinct(&subject.) into: unique_values_subject separated by "!!" from out.forecast_charts;
	run;
	quit;

				%do tempi = 1 %to %sysfunc(countw(&unique_values_subject.,"!!"));
					%let current_unique_level = %scan(&unique_values_subject.,&tempi.,"!!");

					data exportData;
						set out.forecast_charts;
						if &subject. = "&current_unique_level.";
						run;

					data _null_;
						call symput("current_unique_level",translate("&current_unique_level.","_____________________________","~@%^&*()+{}|:<>?`-=[]/,./; "));
						run;

					proc sql;
						create table exportData as
						select &var., actual, pred, Forecast, &subject. from exportData;
						run;

					
					%if "&var."="primary_key_1644" %then %do;
					   data exportData(rename= (&var.= Nobs));
					   set exportData;
					   run;
					%end;
	
					%if "&var_type." = "time_var" %then %do;
					proc sort data=exportData out=exportData;
					by &var.;
					run;
					%end;
					
					%if "&var_type." = "time_var" %then %do;
					%plots(exportData ,&current_unique_level.,&var.);
					%end;
					
					%else %do;
					%plots(exportData,&current_unique_level.,Nobs);
					%end;
					
					Option missing="-";
					proc export data = exportData
					outfile = "&outputPath/&current_unique_level..csv" 
					dbms = csv replace;
					run;
				%end;

				proc sql;
				create table out.unique as 
				select distinct(&subject.) as all from out.forecast_charts;
				run;
				quit;

					%let dsid = %sysfunc(open(&datasetname.));
					%let varnum = %sysfunc(varnum(&dsid,&subject.));
					%put &varnum;
					%let vartyp = %sysfunc(vartype(&dsid,&varnum)); /* variable type */
					%let rc = %sysfunc(close(&dsid));
					%put &vartyp;

                %if "&vartyp" = "C" %then %DO; 
				data out.unique;
				set out.unique;
				all=translate(trim(all),"_____________________________","~@%^&*()+{}|:<>?`-=[]\,./; ");
				run;
				%end;

				proc export data = out.unique
				outfile = "&outputPath./uniqueValues.csv"
				dbms=csv replace;
				run;


	%end;


	proc sql;
	create table out.forecast_charts as
	select &var., actual, pred, Forecast, &subject. from out.forecast_charts;
	run;
	
			%if "&var."="primary_key_1644" %then %do;
			   data out.forecast_charts(rename= (&var.= Nobs));
			   set out.forecast_charts;
			   run;
			%end;
	
			%if "&var_type." = "time_var" %then %do;
				proc sort data=out.forecast_charts out=out.forecast_charts;
				by &var.;
				run;
			%end;	

   	Option missing="-";
	proc export data = out.forecast_charts
		outfile = "&outputpath./all.csv"
		dbms=csv replace;
		run;
		
		%if "&var_type." = "time_var" %then %do;
					%plots(out.forecast_charts ,all,&var.);
					%end;
					
					%else %do;
					%plots(out.forecast_charts,all,Nobs);
					%end;

				

/**/
/*	ods listing close;*/
/*	ods results off;*/
/*	ODS CSV file= "&output_path./Forecast.csv";*/
/**/
/*	PROC PRINT data=out.forecast_charts noobs;*/
/*	RUN;*/
/**/
/*	ODS CSV CLOSE;*/
/*	ods results on;*/
/*	ods listing;*/



%Mend mixed; 
%mixed;


data _null_;
	v1= "Forecasted variable is created";
	file "&outputPath./MIXED_FORECAST_COMPLETED.txt";
	put v1;
	run;


