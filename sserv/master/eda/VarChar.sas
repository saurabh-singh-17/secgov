*processbody;
%let completedTXTPath =  &output_path/VARIABLE_CHARACTERISTICS_COMPLETED.txt;
options mprint mlogic symbolgen mfile;
FILENAME MyFile "&output_path./GENERATE_FILTER_FAILED.txt";

DATA _NULL_;
	rc = FDELETE('MyFile');
RUN;

proc printto log="&output_path/VariableCharacteristics_Log.log";
run;
quit;

dm log 'clear';
libname in "&input_path.";
libname out "&output_path.";

%macro var_char;
	%if "&flag_filter." = "true" %then
		%do;
			%let dataset_name=out.temporary;
			%let whr=;

			/*call SAS code for dynamic filtering*/
			%include %unquote(%str(%'&filterCode_path./dynamicFiltering.sas%'));
		%end;
	%else
		%do;
			%let dataset_name=in.dataworking;
		%end;

	%if "&grp_no." = "0" %then
		%do;

			data subData;
				set &dataset_name. (keep = &var_list. primary_key_1644);
				primary_key_1644 = _n_;
			run;

		%end;
	%else
		%do;

			data subData (drop = grp&grp_no._flag);
				set &dataset_name. (keep = &var_list. grp&grp_no._flag primary_key_1644);
				primary_key_1644 = _n_;
				where compress(grp&grp_no._flag) = "&grp_flag";
			run;

		%end;

	/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
	data temp;
		set &dataset_name.;

		%if "&grp_no." ^= "0" %then
			%do;
				where grp&grp_no._flag = "&grp_flag.";
			%end;
	run;

	/* Checking number of observations in dataset	*/
	%let dset=temp;
	%let dsid = %sysfunc(open(&dset));
	%let nobs =%sysfunc(attrn(&dsid,NOBS));
	%let global_nobs = &nobs.;
	%let rc = %sysfunc(close(&dsid));

	%if &NOBS. =0 %then
		%do;

			data _null_;
				v1= "There are zero observations in the filtered dataset";
				file "&output_path./GENERATE_FILTER_FAILED.txt";
				put v1;
			run;

		%end;

	/* Check if every value is missing -- START */
	proc means data=temp NMISS N;
		var &var_list.;
		output out = nonmissing;
	run;

	data nonmissing(drop = _TYPE_ _FREQ_ _STAT_);
		set nonmissing;

		if _STAT_ ^= 'N' then
			delete;
	run;

	proc transpose data = nonmissing out = nonmissingt;
	run;

	proc sql;
		select min(COL1) into: minNonMissingCount from nonmissingt;
	run;

	quit;

	%put &minNonMissingCount.;

	%if &minNonMissingCount. = 0 %then
		%do;

			data nonmissingt;
				set nonmissingt;

				if COl1 ^= 0 then
					delete;
			run;

			proc sql;
				select _NAME_ into: missingVariables separated by ", " from nonmissingt;
			run;

			quit;

			%let text = All values are missing in the variable(s) '&missingVariables.'. Kindly deselect the variable(s).;

			data _null_;
				file "&output_path./error.txt";
				put "&text.";
			run;

			endsas;
		%end;

	/* Check if every value is missing -- END */
	%let var_no = 1;

	%do %until (not %length(%scan(&var_list,&var_no)));

		data _null_;
			call symput("var_name", "%scan(&var_list,&var_no)");
			call symput("v_id", "%scan(&var_id,&var_no)");
		run;

		%put &var_name &v_id;

		/*  BASIC CHARACTERSTICS CODE */
		proc univariate data = subData;
			var &var_name;
			output out = uni 
				mean = mean 
				median = median 
				mode = mode 
				std = stddev 
				nobs = observations_used 
				nmiss = number_of_missing 
				max = max 
				min = min
				qrange = iqr 
				range = range
				skewness = skewness
				kurtosis = kurtosis
				pctlpts = 25 75 pctlpre = p_;
		run;

		quit;

		data uni (drop = p_25 p_75);
			set uni;
			format variable $32.;
			variable = "&var_name.";
			call symputx("lb", (p_25 - 3*iqr));
			call symputx("ub", (p_75 + 3*iqr));
		run;

		%if "&flag_outliers." = "true" or "&flag_box_plot." = "true" %then
			%do;

				proc sql;
					create table outliers as
						select count(case when &var_name. = 0 then &var_name. end) as no_of_zeros,
							count(case when (&var_name. < &lb.) or  (&var_name. > &ub.) then &var_name. end) as noofoutliers
						from subData;
				quit;

				data uni;
					merge uni outliers;
				run;

			%end;

		proc transpose data = uni out = uniout(drop = _label_ rename = (_name_ = statistic col1 = estimate) );
			by variable;
		run;

		data univariate;
			length statistic $32.;
			format statistic $32.;
			set uniout;

			if strip(statistic) = "mean" then
				statistic = "Mean";

			if strip(statistic) = "stddev" then
				statistic = "Standard";

			if strip(statistic) = "kurtosis" then
				statistic = "Kurtosis";

			if strip(statistic) = "number_of_missing" then
				statistic = "Number of Missing";

			if strip(statistic) = "observations_used" then
				statistic = "Observations Used";

			if strip(statistic) = "max" then
				statistic = "Maximum";

			if strip(statistic) = "min" then
				statistic = "Minimum";

			if strip(statistic) = "range" then
				statistic = "Range";

			if strip(statistic) = "iqr" then
				statistic = "Inter-Quartile Range";

			if strip(statistic) = "mode" then
				statistic = "Mode";
		run;

		proc sql;
			create table univfinal as
				select STATISTIC, ESTIMATE, VARIABLE from univariate;
		quit;

		PROC EXPORT DATA =  univfinal
			OUTFILE="&output_path./&v_id./uni.csv" 
			DBMS=CSV REPLACE;
		RUN;

		/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
		/* BOXPLOT CODE  */
		%if "&flag_box_plot." = "true" %then
			%do;

				data outliers (rename = (&var_name. = outlier));
					set subData (drop = primary_key_1644);
					where (&var_name. < &lb.) or  (&var_name. > &ub.);
				run;

				proc univariate data = subData;
					var &var_name.;
					output out = box mean = box_mean pctlpts = 0 25 50 75 100 pctlpre=p_;
				run;

				data fivepoint;
					length variable $32.;
					set box;
					variable = "&var_name.";
				run;

				data boxplot;
					set fivepoint;
				run;

				proc transpose data=fivepoint out=boxplot;
				run;

				proc sort data=boxplot out=boxplot(drop=_Label_);
					by _NAME_;
				run;

				PROC EXPORT DATA =  fivepoint /*here was boxplot*/
					OUTFILE="&output_path./&v_id./boxplot.csv" 
						DBMS=CSV REPLACE;
				RUN;

			%end;

		%if "&flag_mean." = "true" or "&flag_std_dev." = "true" %then
			%do;
				%do z = 5 %to 100 %by 5;

					proc univariate data = subData noprint;
						var &var_name.;
						output out = uni_per&z. pctlpts= &z. pctlpre=p_;
					quit;

					data _null_;
						set uni_per&z.;
						call symput("u_per", p_&z.);
					run;

					proc means data = subData noprint;
						var &var_name.;
						where &var_name. < &u_per;
						output out = means_uni&z.(drop = _type_ _freq_) mean = mean stddev = stddev;
					run;

					quit;

					data means_uni&z.;
						set means_uni&z.;
						length variable $32;
						length percentile 8.;
						percentile = "&z.";
						variable = "&var_name.";
					run;

					%if "&z" = "5" %then
						%do;

							data percentiles;
								set means_uni&z.;
						%end;
					%else
						%do;

							data percentiles;
								set percentiles means_uni&z.;
							run;

						%end;

					proc delete data = means_uni&z. uni_per&z.;
					run;

					quit;

				%end;

				libname perctl xml "&output_path./&v_id./percentile.xml";

				data perctl.percentile;
					set percentiles;
				run;

			%end;

		/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
		/*	PROB PLOT CODE	*/
		%if "&flag_prob_plot." = "true" %then
			%do;

				proc univariate data = subData;
					var &var_name.;
					output out = prob mean = mu std = sigma;
				run;

				quit;

				data prob;
					set prob;

					%do x = 1 %to 99;
						percentile&x. = &x./100;
						Estimate&x. = mu + (sigma*probit(percentile&x.));
					%end;
				run;

				proc transpose data = prob(keep = percentile:) out = prob_per(drop = _name_ rename = (col1 = percentile));
				run;

				proc transpose data = prob(keep = estimate:) out = prob_est(drop = _name_ rename = (col1 = estimate));
				run;

				data probplot;
					merge prob_per  prob_est;
				run;

				PROC EXPORT DATA =  probplot
					OUTFILE="&output_path./&v_id./probplot.csv" 
					DBMS=CSV REPLACE;
				RUN;

			%end;

		/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
		/*	RUN SEQUENCE PLOT	*/
		%if "&flag_runseq_plot." = "true" %then
			%do;

				data runseq;
					set subData(rename = (&var_name. = actual));
				run;

				data runseq;
					set runseq(rename = (primary_key_1644 = primary_key));
				run;

				proc sort data=runseq out=runseq;
					by primary_key;
				run;

				quit;

				PROC EXPORT DATA =  runseq
					OUTFILE="&output_path./&v_id./runsequence.csv" 
					DBMS=CSV REPLACE;
				RUN;

				/*Runsequence*/
				%let dsid = %sysfunc(open(runseq));
				%let nobs =%sysfunc(attrn(&dsid,NOBS));
				%let rc = %sysfunc(close(&dsid));

				%if &nobs. > 5500 %then
					%do;
						ods graphics on/ width=20in height=20in;
						ods listing;
						filename image "&output_path./&v_id./runsequence.png";
						goptions reset=all device =  png300 Transparency gsfname=image gsfmode=replace;
						footnote1 h = .5 '  ';
						symbol1 font = marker value=U height=.3 color=orange;

						proc gplot data= runseq;
							plot Actual*Primary_key;
						run;

						ods listing close;
						ods graphics off;
					%end;
			%end;

		/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
		/*	HISTOGRAM CODE	*/
		%if "&flag_histogram." = "true" %then
			%do;

				proc univariate data = subData;
					var &var_name.;
					output out = hist mean = mu std = sigma min = min range = range;
				run;

				quit;

				data _NULL_;
					set hist;
					call symputx("min",min);
					call symputx("range",range);
				run;

				%put The min value of &var_name. is &min.;
				%put The range value of &var_name. is &range.;

				data something(keep = increment);
					retain increment &min.;

					do k = 1 to 18;
						increment + %sysevalf(&range./18);
						output;
					end;
				run;

				data _null_;
					set something nobs = no_obs;
					call symput("range"||left(input(put(_n_,3.),$3.)), increment);
					call symput ("no_obs",compress(no_obs));
				run;

				%let range0 = %sysevalf(&min.);
				%put &range0 &range10 &no_obs;

				data final;
					set subData;

					%do i = 0 %to %eval(&no_obs. - 1);
						%let j = %eval(&i. +1);

						%if "&j." = "1" %then
							%do;
								if &&range&i <= &var_name. <= &&range&j then
									increment = &&range&j;
							%end;
						%else
							%do;
								if &&range&i < &var_name. <= &&range&j then
									increment = &&range&j;
							%end;
					%end;
				run;

				ods output onewayfreqs = freq(keep = frequency increment rename = (Frequency = frequency));

				proc freq data = final;
					tables increment;
				run;

				/*adding code because in sas server the csv is showing Frequency instead of frequency*/
				data Freq;
					set Freq(rename=(frequency=frequency1));
				run;

				data Freq;
					set Freq(rename=(frequency1=frequency));
				run;

				proc sql;
					create table histogram as
						select a.increment,b.frequency
							from something as a left join freq as b
								on compress(put(a.increment,best.)) = compress(put(b.increment,best.));
				quit;

				data histogram;
					set histogram;

					if frequency = . then
						frequency = 0;
				run;

				proc sort nodup data = histogram out = histogram;
					by increment;
				run;

				PROC EXPORT DATA =  histogram
					OUTFILE="&output_path./&v_id./histogram.csv" 
					DBMS=CSV REPLACE;
				RUN;

				%let dsid = %sysfunc(open(histogram));
				%let nobs =%sysfunc(attrn(&dsid,NOBS));
				%let rc = %sysfunc(close(&dsid));

				%if &nobs. > 5500 %then
					%do;
						ods graphics on/ width=20in height=20in;
						ods listing;
						filename image "&output_path./&v_id./histogram.png";
						goptions reset=all device =  png300 Transparency gsfname=image gsfmode=replace;
						footnote1 h = .5 '  ';
						symbol1 i=needle v=none c=orange w=10;

						proc gplot data=histogram;
							plot frequency*increment;
						run;

						quit;

						ods listing close;
						ods graphics off;
					%end;
			%end;

		/*	TIME SERIES CODE	*/
%macro try;
	%if "&date_var." ~= "" %then
		%do;
			%if "&flag_timeSeries_plot." = "true" %then
				%do;
					%do j = 1 %to %sysfunc(countw(&date_var.," "));
						%do i = 1 %to %sysfunc(countw(&var_list.," "));
							%let var_num = %scan(&var_list,&i," ");
							%let var_num_id = %scan(&var_id,&i," ");
							%let var_date = %scan(&date_var,&j," ");

							data time(keep=&var_date. &var_num.);
								set temp;
							run;

							proc sort data=time out=time;
								by &var_date.;
							run;

							quit;

							PROC EXPORT DATA =  time
								OUTFILE="&output_path./&var_num_id./timeseries.csv" 
								DBMS=CSV REPLACE;
							RUN;

							%let dsid = %sysfunc(open(time));
							%let nobs =%sysfunc(attrn(&dsid,NOBS));
							%let rc = %sysfunc(close(&dsid));

							%if &nobs. > 5500 %then
								%do;
									ods graphics on/ width=20in height=20in;
									ods listing;
									filename image "&output_path./&var_num_id./timeseries.png";
									goptions reset=all device =  png300 Transparency gsfname=image gsfmode=replace;
									footnote1 h = .5 '  ';
									symbol1 interpol = join v=none c=orange w=2;

									proc gplot data=time;
										plot &var_num.* &var_date.;
									run;

									quit;

									ods listing close;
									ods graphics off;
								%end;
						%end;
					%end;
				%end;
		%end;
%mend try;

%try;

/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
/*	ACF CODE	*/
%macro acf;
	%if "&flag_acf_plot." = "true" %then
		%do;
			%do i = 1 %to %sysfunc(countw(&var_list.," "));
				%let var_num = %scan(&var_list,&i," ");
				%let var_num_id = %scan(&var_id,&i," ");
				ods output AutoCorrGraph = acf(keep= lag Correlation StdErr);

				proc arima data = temp;
					identify var = &var_num.;
				run;
				%if "&SYSERRORTEXT." ne "" %then %do;
				data _null_;
					v1="&SYSERRORTEXT.";
					file "&output_path./error.txt";
					put v1;
					run;
				%end;
				

				data acf;
					set acf;
					StdErrX2 = StdErr * 1.96;
					Neg_StdErrX2 = StdErr * -1.96;
				run;

				data acf;
					set acf;
					variable_name = "&var_num.";
				run;

				proc sql;
					create table acf as 
						select lag , correlation , variable_name , StdErr , StdErrX2 ,Neg_StdErrX2
							from acf;
				run;

				quit;

				PROC EXPORT DATA =  acf
					OUTFILE="&output_path./&var_num_id./AutoCorrelation_Plot_Sample.csv" 
					DBMS=CSV REPLACE;
				RUN;

			%end;
		%end;
%mend acf;

/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
/*	PACF CODE	*/
%macro pacf;
	%if "&flag_pacf_plot." = "true" %then
		%do;
			%let dsid=%sysfunc(open(temp,in));
			%let nobs=%sysfunc(attrn(&dsid,nobs));
			%let sq=%sysfunc(sqrt(&nobs.));
			%put &sq.;
			%let diff=%sysfunc(round(1/&sq.,0.001));
			%put &diff.;

			%do i = 1 %to %sysfunc(countw(&var_list.," "));
				%let var_num = %scan(&var_list,&i," ");
				%let var_num_id = %scan(&var_id,&i," ");
				ods output PACFGraph = pacf(keep = lag PACF);

				proc arima data = temp;
					identify var = &var_num.;
				run;
				%if "&SYSERRORTEXT." ne "" %then %do;
				data _null_;
					v1="&SYSERRORTEXT.";
					file "&output_path./error.txt";
					put v1;
					run;
				%end;

				data pacf(rename = (PACF = Correlation));
					set pacf;
					StdErr = &diff.;
					StdErrX2 = StdErr * 1.96;
					Neg_StdErrX2 = StdErr * -1.96;

					if lag = 0 then
						delete;
				run;

				PROC EXPORT DATA =  pacf
					OUTFILE="&output_path./&var_num_id./_Partial_ACF_Sample.csv" 
					DBMS=CSV REPLACE;
				RUN;

			%end;
		%end;
%mend pacf;

%if &global_nobs. > 5 %then
	%do;
		%acf;
		%pacf;
	%end;
%else
	%do;

		data tempabcd (drop = pbuttons);
			set sashelp.adsmsg (obs = 1 rename = (msgid = Lag mnemonic = Correlation lineno = StdErr level = StdErrX2 text = Neg_StdErrX2));
			Lag="";
			Correlation="";
			StdErr="";
			StdErrX2="";
			Neg_StdErrX2="";
		run;

		%do i = 1 %to %sysfunc(countw(&var_list.," "));
			%let var_num_id = %scan(&var_id,&i," ");

			proc export data = tempabcd outfile = "&output_path./&var_num_id./_Partial_ACF_Sample.csv" dbms = csv replace;
			run;

			proc export data = tempabcd outfile = "&output_path./&var_num_id./AutoCorrelation_Plot_Sample.csv" dbms = csv replace;
			run;

		%end;
	%end;

/*	UNIT TEST	*/
%if "&flag_unit_test." = "true" %then
	%do;
		%do i = 1 %to %sysfunc(countw(&var_list.," "));
			%let var_num = %scan(&var_list,&i," ");
			%let var_num_id = %scan(&var_id,&i," ");
			ods output StationarityTests = UnitRootTests;

			proc arima data =  temp;
				identify var = &var_num. stationarity = (DICKEY = (0,1,2) );
			run;

			quit;
			%if "&SYSERRORTEXT." ne "" %then %do;
				data _null_;
					v1="&SYSERRORTEXT.";
					file "&output_path./error.txt";
					put v1;
					run;
				%end;
			/*Exporting csv for unit test*/
			proc export data =  UnitRootTests
				outfile = "&output_path./&var_num_id./UnitRootTests.csv"
				dbms = CSV replace;
			run;

		%end;
	%end;

/*	SEASONALITY TEST	*/
%if "&flag_seasonality_test." = "true" %then
	%do;
		%do i = 1 %to %sysfunc(countw(&var_list.," "));
			%let var_num = %scan(&var_list,&i," ");
			%let var_num_id = %scan(&var_id,&i," ");

			proc arima data = temp;
				ods output StationarityTests = SeasonalityTests;
				identify var = &var_num. stationarity = (DICKEY = (0,1,2) DLAG = 12 );
			run;
			%if "&SYSERRORTEXT." ne "" %then %do;
				data _null_;
					v1="&SYSERRORTEXT.";
					file "&output_path./error.txt";
					put v1;
					run;
				%end;

			/*Exporting csv for Seasonality test*/
			proc export data =  SeasonalityTests
				outfile = "&output_path./&var_num_id./SeasonalityTests.csv"
				dbms = CSV replace;
			run;

		%end;
	%end;

/*	WHITE NOISE TEST	*/
%if "&flag_whiteNoise_test." = "true" %then
	%do;
		%do i = 1 %to %sysfunc(countw(&var_list.," "));
			%let var_num = %scan(&var_list,&i," ");
			%let var_num_id = %scan(&var_id,&i," ");
			ods output ChiSqAuto = WhiteNoiseTest;

			proc arima data =  temp;
				identify var = &var_num. stationarity = (DICKEY = (0,1,2) );
			run;
			
			quit;
			%if "&SYSERRORTEXT." ne "" %then %do;
				data _null_;
					v1="&SYSERRORTEXT.";
					file "&output_path./error.txt";
					put v1;
					run;
				%end;
			data whitenoisetest;
				set whitenoisetest;
				format One 6.5;
				format Two 6.5;
				format Three 6.5;
				format Four 6.5;
				format Five 6.5;
				format Six 6.5;
			run;

			/*Exporting csv for white noise test*/
			proc export data =  WhiteNoiseTest
				outfile = "&output_path./&var_num_id./WhiteNoiseTest.csv"
				dbms = CSV replace;
			run;

		%end;
	%end;

%let var_no = %eval(&var_no.+1);
%end;

%mend var_char;

%var_char;
/* Flex uses this file to test if the code has finished running */
data _null_;
	v1= "EDA - VARIABLE_CHARACTERISTICS_COMPLETED";
	file "&output_path/VARIABLE_CHARACTERISTICS_COMPLETED.txt";
	PUT v1;
run;