*processbody;
options mprint mlogic symbolgen mfile;

proc printto log="&output_path./GeneralLinearModel_Log.log";
     run;
quit;
/*proc printto print="&output_path./GeneralLinearModel_output.out";*/
/*      quit;*/

dm log 'clear';
libname in "&input_path.";
libname group "&group_path.";
libname out "&output_path.";
%Macro plots(dataset, pngname, xaxis);
                %let dsid = %sysfunc(open(&dataset));
                %let nobs =%sysfunc(attrn(&dsid,NOBS));
                %let rc = %sysfunc(close(&dsid));

                %if &nobs. > 5500 %then %do;       
                                
                                /*Forecast Plots*/
                                ods graphics on/ width=20in height=20in;
                                ods listing;
                                filename image "&output_path./&pngname..png";
                                goptions device = png300 transparency gsfname=image ;
                                footnote1 h = .5 '  ';

                                symbol1 font = marker i=join value=U height=.3 color=orange;
                                symbol2 font = marker i=join value=U height=.3 color=blue;
                                symbol3 font = marker i=join value=U height=.3 color=green;
                                axis1 label=("&xaxis.");
                                axis2 label=('Dependent Variable');
                                
                                proc gplot data= &dataset;
                                plot (actual pred forecast)*&xaxis./overlay vaxis=axis1 haxis=axis2 ;
                                run;

                                ods listing close;
                                ods graphics off;

                %end; 
%mend;

%macro glmforecast;
ods output ParameterEstimates=params;
ods output classlevels =classlevels;
proc glm data = &dataset_name. namelen=32;
		%if "&class_variables." ^= "" %then %do;
                     class &class_variables.;
		%end;
	model &dependent_variable. = &independent_variables. &class_variables./ &regression_options.;
				
		%if "&ls_means_variables." ^= "" %then %do;
               %if "&flag_pdiff."="true" %then %do;
                     lsmeans &ls_means_variables./stderr pdiff;
               %end;
               %else %do;
                     lsmeans &ls_means_variables./stderr ;
               %end;
		%end;
     output out=glmout p=pred;
     where &validation_var. = 0 or &validation_var. = 1 ;
	 run;
	 quit;

					data glmout;
					set glmout;
					actual= &dependent_variable.;
					run;

proc glmselect data=&dataset_name. namelen=200;
%if "&class_variables." ^= "" %then %do;
	  class &class_variables.;
%end;
model &dependent_variable. = &independent_variables. &class_variables./selection=none;
score data=&dataset_name. out= out.RScoreP predicted= Forecast;
where &validation_var.=2;
run;
quit;


	data out.RScoreP;
	   set out.RScoreP;
	   actual= . ;
	   run;

 
	data glmout;
		set glmout out.RScoreP;
		run;

		%let var=;
	%if "&var_type." = "time_var" %then %do;
	%let var = &var_name.;
	%end;
	%else %do;
	%let var = primary_key_1644;
	%end;

	 
 
   data out.forecast_charts( keep =&var. actual pred Forecast);
   set glmout;
   run;
	
   proc sql;
   create table out.forecast_charts as
   select &var.,actual,pred,Forecast from out.forecast_charts;
   run;
   quit;
   
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

/*   */
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

	Option missing="-";
	proc export data = out.forecast_charts
		outfile = "&output_path./Forecast.csv"
		dbms=csv replace;
		run;

			%if "&var_type." = "time_var" %then %do;
					%plots(out.forecast_charts,Forecast,&var.);
					%end;
					
					%else %do;
					%plots(out.forecast_charts,Forecast,Nobs);
					%end;

	%mend;
	%glmforecast;

 data _null_;
 v1= "FORECASTING IS DONE";
 file "&output_path./GLM_FORECAST_COMPLETED.txt";
 put v1;
 run;