/*Successfully converted to SAS Server Format*/
*processbody;
dm log 'clear';
%let chartfilepath = &output_path.;
options mprint mlogic symbolgen mfile;

/*proc printto log="&output_path./ManualRegression_Log.log";*/
/*run;*/
/*quit;*/
/*proc printto print="&output_path./ManualRegression_Output.out";*/
%Macro plots(dataset,xaxis);
	%let dsid = %sysfunc(open(&dataset));
	%let nobs =%sysfunc(attrn(&dsid,NOBS));
	%let rc = %sysfunc(close(&dsid));

	%if &nobs. > 5500 %then
		%do;
			/*Forecast Plots*/
			ods graphics on/ width=20in height=20in;
			ods listing;
			filename image "&output_path./Forecast.png";
			goptions device = pngt gsfname=image gsfmode=replace;
			footnote1 h = .5 '  ';
			symbol1 font = marker i=join value=U height=.3 color=green;
			symbol2 font = marker i=join value=U height=.3 color=blue;
			symbol3 font = marker i=join value=U height=.3 color=orange;
			%if "&var_type." = "time_var" %then %do;
				axis1 label=('Time Variable');
			%end;
			%else %do;
				axis1 label=('NObs');
			%end;
			axis2 label=('Dependent Variable');
			legend1 label=none value= (tick=1 "Actual vs &xaxis." tick = 2 "Predicted vs &xaxis." tick = 3 "Forecast vs &xaxis.");

			proc gplot data= &dataset;
				plot actual*&xaxis pred*&xaxis forecast*&xaxis/overlay vaxis=axis2 haxis=axis1 legend=legend1 ;
			run;

			ods listing close;
			ods graphics off;
		%end;
%mend;

%macro linearforecast;
	libname base "&base_path.";
	libname in  "&input_path.";
	libname group "&group_path.";
	libname out "&output_path.";

	/*data group.bygroupdata;*/
	/*set group.bygroupdata;*/
	/*_n_ = primary_key;*/
	/*run;*/
	proc reg data = group.bygroupdata outest = out.out_temp1 tableout edf;
		model &dependent_variable.= &independent_variables./vif stb dw aic acov &regression_options.;
		output out=out.outdata p=pred;
		where &validation_var. = 0 or &validation_var. = 1;
	run;

	quit;

	proc sql;
		create table out.forecastdata as select * from group.bygroupdata where &validation_var. = 2;
	run;

	quit;

	%if "&regression_options." = "selection=rsquare" %then
		%do;

			data out.out_temp1;
				set out.out_temp1 end=end;

				if
				end;
			run;

		%end;

	proc score data=out.forecastdata  score= out.out_temp1 out=out.RScoreP type=parms;
		var &independent_variables.;
	run;

	data out.RScoreP(rename = Model1= Forecast);
		set out.RScoreP;
		actual = .;
	run;

	data out.outdata;
		set out.outdata out.RScoreP;
	run;

	%let var=;

	%if "&var_type." = "time_var" %then
		%do;
			%let var = &var_name.;
		%end;
	%else
		%do;
			%let var = primary_key_1644;
		%end;

	data out.forecast_charts( keep =&var. actual pred Forecast);
		set out.outdata;
	run;

	%if "&var."="primary_key_1644" %then
		%do;

			data out.forecast_charts( rename= (&var.= Nobs));
				set out.forecast_charts;
			run;
			%plots(out.forecast_charts,Nobs);

		%end;

	%if "&var_type." = "time_var" %then
		%do;

			proc sort data=out.forecast_charts out=out.forecast_charts;
				by &var.;
			run;
			%plots(out.forecast_charts, &var);

		%end;

	Option missing="-";

	proc export data = out.forecast_charts
		outfile = "&chartfilepath./Forecast.csv"
		dbms=csv replace;
	run;

%mend;

%linearforecast;

/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "Forecasted variable is created";
	file "&output_path./LINEAR_REGRESSION_FORECAST_COMPLETED.txt";
	put v1;
run;
;