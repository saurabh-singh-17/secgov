/*Successfully converted to SAS Server Format*/
*processbody;
/*%let completedTXTPath =  &output_path/TIMESERIES_ADVANCED_COMPLETED.txt;*/
options mprint mlogic symbolgen mfile;

/*proc printto log="&output_path/timeseries2_Log.log";*/
/*run;*/
/*quit;*/
proc printto;
run;

quit;

libname in "&input_path.";
libname out "&output_path.";

%macro timeseries2;
	FILENAME MyFile "&output_path./zero.txt";

	DATA _NULL_;
		rc = FDELETE('MyFile');
	RUN;

	FILENAME MyFile "&output_path./negative.txt";

	DATA _NULL_;
		rc = FDELETE('MyFile');
	RUN;

	FILENAME MyFile "&output_path./missing.txt";

	DATA _NULL_;
		rc = FDELETE('MyFile');
	RUN;

	FILENAME MyFile "&output_path./error.txt";

	DATA _NULL_;
		rc = FDELETE('MyFile');
	RUN;

	data temp;
		set in.dataworking;
	run;

	%macro missing_checker;

   proc sql;
           select count(*),count(&date_var.) into: nobs separated by "",:missing_nobs separated by "" from temp ;
           run;
           quit;

   %if &nobs. ^= &missing_nobs. %then %do;
        data _null_;
             file "&output_Path./missing_date.txt";
             put "Date variable has missing values. Cannot continue.";
             run;

             ABORT;
   %end;

   %mend;
   %missing_checker;

	proc sort data=temp;
		by &date_var.;
	run;

	/*===============================================================================================================================*/
	/*Macro to count the count the number of unique values in one variable from a dataset*/
	/*Returns a macro variable called uniqueCount*/
	/*===============================================================================================================================*/
%macro countUniqueValues(dataset,variable);
	%let currentVariable = &variable.;
	%global uniqueCount;

	proc sql noprint;
		select count(distinct(&currentVariable.)) into: uniqueCount from &dataset.;
	quit;

	%put The number of unique values in &variable. is &uniqueCount.;
%mend;

/*===============================================================================================================================*/
/* Error check: If a variable has only one unique value, then proc arima will fail*/
%countUniqueValues(dataset=in.dataworking,variable=&var_list.);
%let uniqueCount = %sysfunc(compress(&uniqueCount.));

%if &uniqueCount. = 1 %then
	%do;

		data _null_;
			v1= "The number of unique values in the variable &var_list. is 1. Kindly deselect it.";
			file "&output_path./error.txt";
			put v1;
		run;

		endsas;
	%end;

/*If log is selected, check for missing values & negative values & 0*/
/*If the above mentioned values are there in the variables, then write error txt and end execution*/
%MACRO time;
	%let current_variable = &var_list.;
	%put &current_variable.;

	%if "&flag_log_transform." = "true" %then
		%do;
			/*call SAS code for checking whether it is zero or negative or missing*/
			/*This code will return a variable 'indicator' which will have the value 1 if missing, negative values or 0 is found*/
			%include %unquote(%str(%'&genericCode_path./GenericCode _MissingNegativeZero.sas%'));

			%if &indicator. = 1 %then
				%do;

%macro delvars;

	data vars;
		set sashelp.vmacro;
	run;

	data _null_;
		set vars;

		if scope='GLOBAL' and substr(name,1,3) ne "SYS" and name ne "SASWORKLOCATION" and substr(name,1,1) ne "_" then
			call execute('%symdel '||trim(left(name))||';');
	run;

%mend delvars;

%delvars;
%abort;
%end;
%end;
%mend time;

%time;

/* 	when no transformation is selected	*/
%if (("&flag_log_transform."="false") && ("&flag_seasonal_adj."="false") && ("&flag_seasonal_index."="false")
&& ("&flag_differencing."="false") && ("&flag_seasonality."="false")) %then
	%do;

		data temp;
			set temp;
			newVar = &var_list.;
		run;

	%end;

/*	Calculating log transform of the variables			*/
%if "&flag_log_transform." = "true" %then
	%do;

		data temp;
			set temp;
			newVar = log(&var_list.);
		run;

	%end;

/*	Calculating Seasonal adjusted data and Seasonal Index */
%if "&flag_seasonal_adj." = "true" or "&flag_seasonal_index." = "true" %then
	%do;

		proc timeseries data=temp
			outdecomp=season
		;
			id &date_var. interval=&date_level. accumulate=total;
			var %if "&flag_log_transform." = "true" %then

				%do;
					newVar;
				%end;
%else
	%do;
		&var_list.;
	%end;
		run;


		data season;
		merge season(drop=&date_var.) temp(keep=&date_var.);
		run;
       	
		data temp(drop = %if "&flag_log_transform." = "true" %then %do;
			newVar
	%end;
	);
	merge temp season;
	by &date_var.;
		run;

		data temp(rename = SA = newVar);
			set temp;
		run;

%end;

		/*	Calculating Differencing */
		%if "&flag_differencing." = "true" %then
			%do;

				proc timeseries data=temp
					out=diff;
					id &date_var. interval=&date_level. accumulate=total;
					var %if "&flag_seasonal_adj." = "true" or "&flag_log_transform."="true" %then

						%do;
							newVar
						%end;
		%else
			%do;
				&var_list.
			%end;      
       	
		/
			%if "&order_differencing." ~= 0 %then
				%do;
					dif=(&order_differencing.)
				%end;

			%if ("flag_seasonality"="true" and "&order_seasonality." ~= 0) %then
				%do;
					sdif=(&order_seasonality.)
				%end;
			;
				run;
				data diff;
		merge diff(drop=&date_var.) temp(keep=&date_var.);
		run;

				%if "&flag_seasonal_adj." = "false" and "&flag_log_transform."="false" %then
					%do;

						data diff(rename = &var_list. = newVar);
							set diff;
						run;

					%end;

				data temp;
					merge temp diff;
					by &date_var.;
				run;

			%end;

		/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
		/*	TIME SERIES CODE	*/
		%if "&date_var." ~= "" %then
			%do;
				%do j = 1 %to %sysfunc(countw(&date_var.," "));
					%let var_date = %scan(&date_var,&j," ");

					proc sql;
						create table time as
							select &var_date. ,

							%if (("&flag_log_transform."="false") && ("&flag_seasonal_adj."="false") && ("&flag_seasonal_index."="false")
								&& ("&flag_differencing."="false") && ("&flag_seasonality."="false")) %then
								%do;
									newVar
								%end;
							%else
								%do;
									 &var_list.
								%end;

							from temp;
					quit;

					/*PNG GRAPH CREATOR-start*/
					%let dsid = %sysfunc(open(time));
					%let nobs =%sysfunc(attrn(&dsid,NOBS));
					%let rc = %sysfunc(close(&dsid));

					%if &nobs. > 5500 %then
						%do;
							ods graphics on/ width=20in  height=20in;
							ods listing;
							filename image "&output_path./timeseries.png";
							goptions reset=all device =  png300 Transparency gsfname=image gsfmode=replace;
							footnote1 h = .5 '  ';
							symbol1 interpol = join v=none c=orange w=2;

							proc gplot data=time;
								plot &var_list.* &var_date.;
							run;

							quit;

							ods listing close;
							ods graphics off;
						%end;

					/*	PNG GRAPH CREATOR-stop */
					data time(rename=(newVar=&var_list.));
						set time;
					run;

					/*Exporting csv for time series test*/
					PROC EXPORT DATA =  time
						OUTFILE="&output_path./timeseries.csv" 
						DBMS=CSV REPLACE;
					RUN;

				%end;
			%end;

		/*	ACF CODE	*/
		ods output AutoCorrGraph = acf(keep= lag Correlation StdErr);

		proc arima data = temp;
			identify var =

			%if (("&flag_log_transform."="false") && ("&flag_seasonal_adj."="false") && ("&flag_seasonal_index."="false")
				&& ("&flag_differencing."="false") && ("&flag_seasonality."="false")) %then
				%do;
					newVar
				%end;
			%else
				%do;
					&var_list.
				%end;
			;
		run;

		quit;

		data acf;
			set acf;

			/*			_NAME_=" ";*/
			StdErrX2 = StdErr * 1.96;
			Neg_StdErrX2 = StdErr * -1.96;
		run;

		proc sql;
			create table acf as
				select lag ,Correlation ,StdErr, StdErrX2 , Neg_StdErrX2
					from acf;
		quit;

		/*Exporting csv for auto correlation plot*/
		PROC EXPORT DATA =  acf
			OUTFILE="&output_path./AutoCorrelation_Plot_Sample.csv" 
			DBMS=CSV REPLACE;
		RUN;

		/*	PACF CODE	*/
		%let dsid=%sysfunc(open(temp,in));
		%let nobs=%sysfunc(attrn(&dsid,nobs));
		%let rc=%sysfunc(close(&dsid));
		%let sq=%sysfunc(sqrt(&nobs.));
		%put &sq.;
		%let diff=%sysfunc(round(1/&sq.,0.001));
		%put &diff.;
		ods output PACFGraph = pacf(keep = lag PACF);

		proc arima data = temp;
			identify var =

			%if (("&flag_log_transform."="false") && ("&flag_seasonal_adj."="false") && ("&flag_seasonal_index."="false")
				&& ("&flag_differencing."="false") && ("&flag_seasonality."="false")) %then
				%do;
					newVar
				%end;
			%else
				%do;
					&var_list.
				%end;
			;
		run;

		quit;

		data pacf(rename = (PACF = Correlation));
			set pacf;

			/*			_NAME_=" ";*/
			StdErr = &diff.;
			StdErrX2 = StdErr * 1.96;
			Neg_StdErrX2 = StdErr * -1.96;

			if lag = 0 then
				delete;
		run;

		proc sql;
			create table pacf as
				select lag ,Correlation ,StdErr, StdErrX2 , Neg_StdErrX2
					from pacf;
		quit;

		/*Exporting csv for partial auto correlation plott*/
		PROC EXPORT DATA =  pacf
			OUTFILE="&output_path./_Partial_ACF_Sample.csv" 
			DBMS=CSV REPLACE;
		RUN;

		/*	UNIT TEST	*/
		ods output StationarityTests = UnitRootTests;

		proc arima data =  temp;
			identify var =

			%if (("&flag_log_transform."="false") && ("&flag_seasonal_adj."="false") && ("&flag_seasonal_index."="false")
					&& ("&flag_differencing."="false") && ("&flag_seasonality."="false")) %then
				%do;
					newVar
				%end;
			%else
				%do;
					&var_list.
				%end;

			stationarity = (DICKEY = (0,1,2,3,4,5) );
		run;

		quit;

		proc sql;
			create table UnitRootTest as
				select Type,Lags,Tau,ProbTau
					from UnitRootTests
						where Type in ("Single Mean");
		quit;

		data UnitRootTest;
			set UnitRootTest;

			/*			_NAME_=" ";*/
			Significance_level = 0.05;
		run;

		proc sql;
			create table UnitRootTest as
				select Type ,Lags ,Tau,ProbTau,Significance_level
					from UnitRootTest;
		quit;

		/*Exporting csv for unit test*/
		proc export data =  UnitRootTest
			outfile = "&output_path./UnitRootTests.csv"
			dbms = CSV replace;
		run;

		/*	WHITE NOISE TEST	*/
		ods output ChiSqAuto = WhiteNoiseTest(keep = ToLags ProbChiSq);

		proc arima data =  temp;
			identify var =

			%if (("&flag_log_transform."="false") && ("&flag_seasonal_adj."="false") && ("&flag_seasonal_index."="false")
					&& ("&flag_differencing."="false") && ("&flag_seasonality."="false")) %then
				%do;
					newVar
				%end;
			%else
				%do;
					&var_list.
				%end;

			stationarity = (DICKEY = (0,1,2,3,4,5,6) );
		run;

		quit;

		data WhiteNoiseTest;
			set WhiteNoiseTest;

			/*			_NAME_=" ";*/
			Significance_level = 0.05;
		run;

		proc sql;
			create table WhiteNoiseTest as
				select ToLags ,ProbChiSq ,Significance_level
					from WhiteNoiseTest;
		quit;

		/*Exporting csv for white noise test*/
		proc export data =  WhiteNoiseTest
			outfile = "&output_path./WhiteNoiseTest.csv"
			dbms = CSV replace;
		run;

		/*	TIME DECOMPOSITION PLOT	*/
%macro temp;

	proc timeseries data=temp
		outdecomp=decomp
	;
		id &date_var. interval=&date_level. accumulate=total;
		var %if (("&flag_log_transform."="false") && ("&flag_seasonal_adj."="false") && ("&flag_seasonal_index."="false")
		&& ("&flag_differencing."="false") && ("&flag_seasonality."="false")) %then

			%do;
				newVar
			%end;
%else
	%do;
		&var_list
	%end;;
	run;

%mend;

%temp;

data decomp(rename = (TCC = Trend IC=Random SA = Seasonally_Adjust));
	set decomp;
run;

proc sql;
	create table decomp as
		select &date_var. as Date,Trend,Random,SC as Seasonality
			from decomp;
quit;

/*PNG GRAPH CREATOR FOR DECOMP-start*/
%let dsid = %sysfunc(open(decomp));
%let nobs =%sysfunc(attrn(&dsid,NOBS));
%let rc = %sysfunc(close(&dsid));

%if &nobs. > 5500 %then
	%do;
		

/* Specify style and graphics options */
ods graphics on/ width=20in  height=20in;
		ods listing; 
		filename psout "&output_path./DecompositionPlots.png";
		goptions reset=all device=png300 gsfname=psout gsfmode=replace ;
		footnote1 h = .5 '  ';
		symbol1 interpol = join v=none c=orange w=2;


/* Generate the graphs */
proc gplot data=decomp gout=w;
   plot Seasonality * Date;
   run;
   quit;
proc gplot data=decomp gout=w;
   plot Trend * Date;
   run;     
quit;
proc gplot data=decomp gout=w;
   plot Random * Date;
   run;
   quit;
 
/* Enable display, and then replay all of the graphs to psout */
goptions display;
proc greplay igout=w nofs TC=SASHELP.TEMPLT;
      tdef newtemp2 des="dF"
     1/llx=0   lly=0
       ulx=0   uly=33
       urx=100  ury=33
       lrx=100  lry=0
    color=white 

     2/llx=0   lly=33
       ulx=0   uly=66
       urx=100  ury=66
       lrx=100  lry=33  
    color=white

     3/llx=0 lly=66
       ulx=0 uly=99
       urx=100 ury=99
       lrx=100 lry=66
    color=white;
	 template newtemp2;
      treplay  1:1 2:2 3:3;
   run;
quit;
		ods listing close;
		ods graphics off;
	%end;

/*	PNG GRAPH CREATOR FOR DECOMP-stop */
data decomp(drop=&date_var. rename=datexxx=&date_var.);
	set decomp;
	format datexxx date9.;
	datexxx = &date_var.;
	run;



/*Exporting csv for time decomposition plot */
proc export data =  decomp
	outfile = "&output_path./decomp.csv"
	dbms = CSV replace;
run;
/*	enhancement	*/
%if "&flag_seasonal_index." = "true" %then
	%do;

		data out.savevar;
			set season(keep = SC);
		run;

	%end;

data out.savetsv %if (("&flag_log_transform."="false") && ("&flag_seasonal_adj."="false") && ("&flag_seasonal_index."="false")
	&& ("&flag_differencing."="false") && ("&flag_seasonality."="false")) %then %do;
		(rename = (&var_list. = newVar))
	%end;;

	set temp(keep = primary_key_1644

		%if %sysfunc(exist(out.savevar)) && ("&flag_seasonal_index."="true") %then
			%do;
				SC
			%end;

		%if (("&flag_log_transform."="false") && ("&flag_seasonal_adj."="false") && ("&flag_seasonal_index."="false")
		&& ("&flag_differencing."="false") && ("&flag_seasonality."="false")) %then
			%do;
				newVar
			%end;
		%else
			%do;
				&var_list.
			%end;
		);
run;

data _null_;
	v1= "&nobs.";
	file "&output_path./nobs.txt";
	put v1;
run;

%mend timeseries2;

%timeseries2;

/* Flex uses this file to test if the code has finished running */
data _null_;
	v1= "MODELING - TIMESERIES_ADVANCED_COMPLETED";
	file "&output_path/TIMESERIES_ADVANCED_COMPLETED.txt";
	PUT v1;
run;

/*ENDSAS;*/
%macro changes_made;
	/*	1.changed the column name from "newvar" into the "&var_list." in timeseries csv*/
	/*	2.implemented png for decomp and timeseries plots*/
	/*  3.removed "_name_" column from 4 csvs */
	/*  4.change 1 was causing problem so just before exporting,added a data step for renaming "newVar" into "&var_list."*/
%mend;
;