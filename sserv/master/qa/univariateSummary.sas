/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &outputPath./SUMMARY_COMPLETED.txt;
 /* VERSION 2.5.0 */
options mprint mlogic symbolgen  mfile;
proc printto log="&outputPath./univariate_summary_Log.log";
run;
quit;
	
/*proc printto print="&outputPath./univariate_summary_Output.out";*/
	
FILENAME MyFile "&outputPath./GENERATE_FILTER_FAILED.txt" ;

  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;
dm log 'clear';
libname in "&inputPath."; 
libname out "&outputPath.";
libname group "&inputPath."; 
%let dataset_name=in.dataworking;

data in.bygroupdata;
	set in.dataworking;
	run;

/********************************************************************************MACRO STARTS*************************************************************************************/

%MACRO univReport;
	/*DATASET PROPERTIES*/
proc sql;
	create table prop as
	select "&dataset_name." as file_name , nobs as n_obs , nvar as n_vars , (filesize/(1024*1024)) as file_size
	from dictionary.tables
	where libname = "IN" and memname = "DATAWORKING";
	quit;


proc transpose data = prop out = dataset_prop(keep=col1);
	var file_name n_obs n_vars file_size;
	run;
/* Export dataset properties to csv*/
proc export data = dataset_prop
	outfile = "&outputPath./dataset_properties.csv"
	dbms=CSV replace;
	run;
/*DYNAMIC FILTER*/
	%if "&flag_filter." = "true" %then %do;
		%let dataset_name=out.temporary;
		%let whr=;
	 	/*call SAS code for dynamic filtering*/
		%include %unquote(%str(%'&filterCode_path./dynamicFiltering.sas%')); 

		data _null_;
			call symput("entire_vars", cats(tranwrd("&continuous_varlist.", ", ", " "), tranwrd("&categorical_varlist.", ", ", " ")));
			run;
		%put &entire_vars;

	%if "&local_vars." ^= "" %then %do;
	   /*join local whr conditions to whr_filter*/
		%do i=1 %to %sysfunc(countw(&local_vars.));
			%let this_var = %scan(&local_vars,&i);
			%let this_vaar = %sysfunc(lowcase(%unquote(%str(%'&this_var.%'))));
			%put &this_vaar;

			%put &&whr_&this_Var.;

			%if %index(&entire_vars., &this_var) > 0 %then %do;
					%if "&whr_filter." = "" %then %do;
						%let whr_filter = &&whr_&this_Var.;
					%end;
					%if "&whr_filter." ^= "" %then %do;
						%let whr_filter = &whr_filter. and &&whr_&this_Var.;
					%end;
			%end;
		%end;
	%end;
		%put &whr_filter;
		%let whr=;
		/*join whr_filter to whr*/
		%if "&whr_filter." ^= "" %then %do;
			data _null_;
				%if "&whr." = "" %then %do;
					call symput("whr", "&whr_filter.");
				%end;
				%if "&whr." ^= "" %then %do;
					call symput("whr", cat("&whr.", " and ", "&whr_filter."));
				%end;
				run;
			%put &whr;
		%end;
	/*Creating the filtered dataset which will be used for regression*/
		data out.temporary;
			set in.bygroupdata;
			%if "&whr." ^="" %then %do;
				where &whr.;
			%end;
			run;
	%end;

/*#########################################################################################################################################################*/

	/*get total obs*/
	data &dataset_name.;
		set &dataset_name. nobs=num_obs;
		call symput("num_obs", num_obs);
		run;

	%if "&flag_contents" = "true" %then %do;
		/*contents*/
		proc contents data=&dataset_name. out=contents_vars(keep=name label type length rename=(name=variable)) varnum noprint;
			run;
		data contents_vars(drop=type);
			length var_type $9.;
			set contents_vars;
			attrib _all_ label="";
			if type = 1 then var_type = "Numeric";
			if type = 2 then var_type = "Character";
			comments = "";
			run;
		
		/*variable list*/

		%if "&continuous_varlist" = "" and "&categorical_varlist" = "" %then %do;
			proc sql;
				select(variable) into :gr separated by  " " from contents_vars where variable like 'grp%_flag';
				quit;
			data _null_;
				call symput ("unwanted_vars", cat("'", tranwrd("&gr.", " ", "', '"), "'"));
				run;
			proc sql;
				select(variable) into :var_list separated by " " from contents_vars where variable not in('primary_key_1644',&unwanted_vars.);
				quit;
		%end;	
		%else %if "&continuous_varlist" = "" %then %do;
			%let var_list = &categorical_varlist.;
		%end;
		%else %if "&categorical_varlist" = "" %then %do;
			%let var_list = &continuous_varlist.;
		%end;
		%else %do;
			%let var_list = &continuous_varlist. &categorical_varlist.;
		%end;
		
		data _null_;
			call symput ("var_quoted", cat("('", tranwrd("&var_list.", " ", "', '"), "')"));
			run;
		data contents_vars;
			set contents_vars;
			where variable in &var_quoted.;
			run;
		
		/*distinct values*/
		ods output NLevels=distinct_contents(rename=(tablevar=variable NLevels=distinct_values) drop=NMissLevels NNonMissLevels);
		proc freq data =&dataset_name. nlevels;

		tables &var_list.;
		run;



		%let i = 1;
		%do %until (not %length(%scan(&var_list, &i)));
			/*missing*/	
			proc sql;
				create table missing_pervar as
				select count(*) as missing_count
				from &dataset_name.
				where %scan(&var_list, &i) is missing
				;
				quit;

			/*get variable type*/
			%let dsid = %sysfunc(open(&dataset_name.));
				%let varnum = %sysfunc(varnum(&dsid,%scan(&var_list, &i)));
				%let vartype = %sysfunc(vartype(&dsid,&varnum)); /* variable type */
				%let rc = %sysfunc(close(&dsid));
			%put &vartype;
				

			/*count_zeros*/
			proc sql;
				create table zeros_pervar as
				select count(%scan(&var_list, &i)) as zeros_count
				from &dataset_name.
				%if &vartype. = N %then %do;
				where %scan(&var_list, &i) = 0
				;
				%end;
				%if &vartype. = C %then %do;
				where %scan(&var_list, &i) = "0"
				;
				%end;


			/*merge missing & zeros*/
			data miss_0_pervar;
				merge missing_pervar zeros_pervar;
				run;

			data miss_0_pervar;
				length variable $32.;
				set miss_0_pervar;
				variable="%scan(&var_list, &i)";
				missing_perc = (missing_count/&num_obs.)*100;
				zeros_perc = (zeros_count/&num_obs.)*100;
				run;

			/*append for each var*/
			proc append base = missing_zeros data = miss_0_pervar force;
				run;
			%let i = %eval(&i.+1);
		%end;

		/*sort and merge to form contents report*/
		proc sort data=distinct_contents;
			by variable;
			run;

		proc sort data=contents_vars;
			by variable;
			run;

		proc sort data=missing_zeros;
			by variable;
			run;

		data contents;
			retain variable label comments var_type length distinct_values missing_count missing_perc zeros_count zeros_perc;
			merge contents_vars(in=a) distinct_contents(in=b) missing_zeros(in=c);
			by variable;
			if a or b or c;
			run;
		data contents(rename=(label=labels));
			set contents;
		run;
		/*export to CSV*/
		proc export data = contents
			outfile = "&outputPath./contents_report.csv"
			dbms=CSV replace;
			run;
			

		/*export to XML*/
		libname crep xml "&outputPath./contents_report.xml";
		data crep.contents_report;
			set contents;
			run;
		
	%end;

/* UNIVARIATE */
%if "&continuous_varlist." ^= "" %then %do;
	data var_names(drop = i );
		array a(*) &continuous_varlist.;
		do i = 1 to dim(a);
			a(i) = 1;
		end;
		run;

	proc contents data = var_names out = variable_list(keep = name) noprint;
		run;

	data _null_;
		set variable_list end = eof;
		suffix = put(_n_,5.);
		call symput (cats("var",suffix),compress(name));
		if eof then call symput("var_cnt", compress(_n_));
		run;

	%do i = 1 %to &var_cnt.;
	
	%if "&grp_vars." ^= "" %then %do;
		/*sort on grp_vars*/
		proc sort data = &dataset_name.;
			by &grp_vars.;
			run;

		/*get comma separated grp_vars for sql steps*/
		data _null_;
			call symput("grpvars", tranwrd(compbl("&grp_vars."), " ", ", "));
			run;
		%put &grpvars;
	%end;

	/*get numobs of the var to initiate devolpm dataset*/
	proc sql;
		create table devolpm&i. as
		select "&&var&i" as variable length=32, %if "&grp_vars." ^= "" %then %do; &grpvars., %end; count(&&var&i) as count,
		max(&&var&i) as maximum, min(&&var&i) as minimum, sum(CASE WHEN &&var&i = 0 then 1 else 0 end) as num_of_zeros
		from &dataset_name.
		%if "&grp_vars." ^= "" %then %do;
			group by &grpvars.
		%end;
		;
		quit;

	/********************************************************************START OF MISSING DETECTION******************************************************************/

		/*get missing and perc. missing*/
		proc sql;
			create table missing&i. as
			select %if "&grp_vars." ^= "" %then %do; distinct &grpvars. ,%end; count(*) as missing_count,
			(calculated missing_count/&num_obs.)*100 as missing_percentage
			from &dataset_name.
			where (&&var&i. is missing)
			%if "&grp_vars." ^= "" %then %do;
				group by &grpvars.
			%end;
			;
			quit;

		/*check if missing dataset is empty*/
		%let dset=missing&i.;
			%let dsid = %sysfunc(open(&dset));
			%let nobs_miss =%sysfunc(attrn(&dsid,NOBS));
			%let rc = %sysfunc(close(&dsid));
		%put &nobs_miss;

		%if &nobs_miss. = 0 %then %do;
			proc sql;
				create table missing&i. as
				select %if "&grp_vars." ^= "" %then %do; distinct &grpvars. ,%end; 0 as missing_count,
				0 as missing_percentage
				from &dataset_name.
				%if "&grp_vars." ^= "" %then %do;
					group by &grpvars.
				%end;
				;
				quit;
		%end;

		data devolpm&i.;
			%if "&grp_vars." = "" %then %do;
				merge devolpm&i. missing&i.;
			%end;
			%if "&grp_vars." ^= "" %then %do;
				merge devolpm&i.(in=a) missing&i.(in=b);
				by &grp_vars.;
				if a or b;
			%end;
			run;

	/********************************************************************END OF MISSING DETECTION******************************************************************/
	/********************************************************************START OF OUTLIER DETECTION******************************************************************/

	proc univariate data = &dataset_name. noprint;
		%if "&grp_vars." ^= "" %then %do;
			by &grp_vars.;
		%end;
		%if "&flag_filter." = "true" %then %do;
			where &whr_filter.;
		%end;
		var &&var&i.;
		output out= out_univ&i. qrange = iqr pctlpts= 25 75 pctlpre=p_ ;
		run;

	%if "&grp_vars." = "" %then %do;
		data _null_;
			set out_univ&i;
			call symputx("iqrlb&i.", compress(p_25 - (3 * iqr)));
			call symputx("iqrub&i.", compress(p_75 + (3 * iqr)));
			call symputx("iqr&i.",compress(iqr));
			run;

		proc sql;
			select count(&&var&i.) into :iqr_outliers&i. from &dataset_name.
			where (&&var&i. < &&iqrlb&i. or &&var&i. > &&iqrub&i.)
			;
			quit;

		data devolpm&i.;
			set devolpm&i.;
			outliers_3iqr = &&iqr_outliers&i.;
			run;
	%end;
	%if "&grp_vars." ^= "" %then %do;
		data outlier;
			merge out_univ&i.(in=a) &dataset_name.(in=b keep=&&var&i. &grp_vars.);
			by &grp_vars.;
			if a or b;
			run;

		proc sql;
			create table outlier&i. as
			select &grpvars., count(&&var&i.) as outliers_3iqr from outlier
			where (&&var&i. < (p_25 - (3 * iqr)) or &&var&i. > (p_75 + (3 * iqr)))
			group by &grpvars.;
			quit;


		/*check if outlier dataset is empty*/
		%let dset=outlier&i.;
			%let dsid = %sysfunc(open(&dset));
			%let nobs_out =%sysfunc(attrn(&dsid,NOBS));
			%let rc = %sysfunc(close(&dsid));
		%put &nobs_out;

		%if &nobs_out. = 0 %then %do;
			proc sql;
				create table outlier&i. as
				select %if "&grp_vars." ^= "" %then %do; distinct &grpvars. ,%end; 0 as outliers_3iqr
				from &dataset_name.
				%if "&grp_vars." ^= "" %then %do;
					group by &grpvars.
				%end;
				;
				quit;
		%end;

		data devolpm&i.;
			merge devolpm&i.(in=a) outlier&i.(in=b);
			by &grp_vars.;
			if a or b;
			run;
	%end;

	/********************************************************************END OF OUTLIER DETECTION******************************************************************/

	/********************************************START OF MEASURES OF LOCATION********************************************************/

	%if "&measures_of_location" ^= "" or "&measures_of_dispersion" ^= "" %then %do;

		/*get measures: mean, mode, median, std.dev, iqr & range*/
		proc univariate data= &dataset_name. noprint;
			%if "&grp_vars." ^= "" %then %do;
				by &grp_vars.;
			%end;
			var &&var&i;
			output out= measures&i.
				%if %eval(%index(&measures_of_location.,Mean)) > 0 %then %do; mean = mean %end;
				%if %eval(%index(&measures_of_location.,Median)) > 0 %then %do; median = median %end; 
				%if %eval(%index(&measures_of_location.,Mode)) > 0 %then %do; mode = mode %end;
				%if %eval(%index(&measures_of_dispersion.,Standard Deviation)) > 0 %then %do; std = stddev %end;
			    %if %eval(%index(&measures_of_dispersion.,InterQuartile Range)) > 0 %then %do; qrange = iqr %end;
				%if %eval(%index(&measures_of_dispersion.,Range)) > 0 %then %do; range = range %end;
				;
			run;

		/*check if basic measures exist*/
		%let dset=measures&i.;
			%let dsid = %sysfunc(open(&dset));
			%let nobs =%sysfunc(attrn(&dsid,NOBS));
			%let rc = %sysfunc(close(&dsid));
		%put &nobs;


		/*merge measures*/
		%if &nobs. > 0 %then %do;
			data devolpm&i.;
				%if "&grp_vars." = "" %then %do;
					merge devolpm&i. measures&i.;
				%end;
				%if "&grp_vars." ^= "" %then %do;
					merge devolpm&i.(in=a) measures&i.(in=b);
					by &grp_vars.;
					if a or b;
				%end;
				run;
		%end;

		/*get special means*/
		%if %eval(%index(&measures_of_location.,Midmean)) > 0 
		 or %eval(%index(&measures_of_location.,TrimmedMean)) > 0
		 or %eval(%index(&measures_of_location.,WinsorizedMean)) > 0 %then %do;

		 	/*boundary values for special means*/
			proc univariate data= &dataset_name. noprint;
				%if "&grp_vars." ^= "" %then %do;
					by &grp_vars.;
				%end;
				var &&var&i;
				output out= univ&i. 	
					pctlpts = 5 25 75 95 
					pctlpre = p_ ;
				run;

		/**//*special means for across dataset*/
			%if "&grp_vars." = "" %then %do;
				data _null_;
					set univ&i.;
					call symputx("midmean_lb&i.",p_25);
					call symputx("midmean_ub&i.",p_75);
					call symputx("trim_win_lb&i.",p_5);
					call symputx("trim_win_ub&i.",p_95);
					run;


				/*midmean*/
				%if %eval(%index(&measures_of_location.,Midmean)) > 0 %then %do;
					proc sql;
						select avg(&&var&i.) into:midmean&i. from &dataset_name.
						where (&&midmean_lb&i. < &&var&i. < &&midmean_ub&i.)
						;
						quit;
				%end;

			   /*trimmed mean*/
				%if %eval(%index(&measures_of_location.,TrimmedMean)) > 0 %then %do;
					proc sql;
						select avg(&&var&i.) into:trimmedmean&i. from &dataset_name.
						where (&&trim_win_lb&i. < &&var&i. < &&trim_win_ub&i.)
						;
						quit;
				%end;

			   /*winsorized mean*/
				%if %eval(%index(&measures_of_location.,WinsorizedMean)) > 0 %then %do;
					data winsorized&i.;
					set &dataset_name.(keep = &&var&i.);
						if &&var&i. > &&trim_win_ub&i. then &&var&i. = &&trim_win_ub&i.;
						else if &&var&i. < &&trim_win_lb&i.  then &&var&i. = &&trim_win_lb&i. ;
						run;

					proc sql;
						select avg(&&var&i.) into :winsorizedmean&i. from winsorized&i.;
						quit;
				%end;

				/*get all the calculated special means into a dataset*/
				data univ&i.;
					set univ&i.(drop = p_:);
					%if %eval(%index(&measures_of_location.,Midmean)) > 0 %then %do;midmean = &&midmean&i.;%end;
					%if %eval(%index(&measures_of_location.,TrimmedMean)) > 0 %then %do;trimmedmean = &&trimmedmean&i.;%end;
					%if %eval(%index(&measures_of_location.,WinsorizedMean)) > 0 %then %do;
						winsorizedmean = &&winsorizedmean&i.;
					%end;
					run;


				/*merge special means with devlopm*/
				data devolpm&i.;
					merge devolpm&i. univ&i.;
					run;
			%end;

		/**//*special means for group by*/
			%if "&grp_vars." ^= "" %then %do;
				/*get the variable, grp vars and boundary values into a dataset*/
				data means;
					merge &dataset_name.(in=a keep=&&var&i. &grp_vars.) univ&i.(in=b keep=&grp_vars.
						%if %index(&measures_of_location.,Midmean) > 0 %then %do; p_25 p_75 %end;
						%if %index(&measures_of_location.,TrimmedMean) > 0 or %index(&measures_of_location.,WinsorizedMean) > 0 %then %do; p_5 p_95 %end;);
					by &grp_vars.;
					if a or b;
					run;

				/*midmean*/
				%if %eval(%index(&measures_of_location.,Midmean)) > 0 %then %do;
					proc sql;
					create table midmean as
					select &grpvars., avg(&&var&i.) as midmean from means
						where p_25 < &&var&i. < p_75
						group by &grpvars.;
						quit;

					data devolpm&i.;
						merge devolpm&i.(in=a) midmean(in=b);
						by &grp_vars.;
						if a or b;
						run;
				%end;

				/*trimmed mean*/
				%if %eval(%index(&measures_of_location.,TrimmedMean)) > 0 %then %do;
					proc sql;
					create table trimmedmean as
					select &grpvars., avg(&&var&i.) as trimmedmean from means
						where p_5 < &&var&i. < p_95
						group by &grpvars.;
						quit;

					data devolpm&i.;
						merge devolpm&i.(in=a) trimmedmean(in=b);
						by &grp_vars.;
						if a or b;
						run;
				%end;

				/*wisorized mean*/
				%if %eval(%index(&measures_of_location.,WinsorizedMean)) > 0 %then %do;
					data winsorized;
						set means(keep = &&var&i. &grp_vars. p_5 p_95);
						if &&var&i. > p_95 then &&var&i. = p_95;
						else if &&var&i. < p_5  then &&var&i. = p_5;
						run;

					proc sql;
					create table winsorized as
					select &grpvars., avg(&&var&i.) as winsorized from means
						group by &grpvars.;
						quit;

					data devolpm&i.;
						merge devolpm&i.(in=a) winsorized(in=b);
						by &grp_vars.;
						if a or b;
						run;
				%end; 	
			%end;
		%end;
	%end;

	/********************************************************************END OF MEASURES OF LOCATION******************************************************************/

	/********************************************************************START OF NORMALITY******************************************************************/
	%let normality_tests = ;
	%if "&normality" ^= "" %then %do;

		ods output Moments = moments&i. (where=(Label1="Skewness") rename=(nvalue1=skewness nvalue2=kurtosis));
		ods output TestsForNormality = normal&i. (keep = %if "&grp_vars." ^= "" %then %do; &grp_vars %end; test pvalue 
													rename =(test = normalitytest pvalue = value));
		%if %index(&normality.,Shapiro-Wilk) > 0 %then %do; %let normality_tests = &normality_tests. Shapiro-Wilk; %end;
		%if %index(&normality.,Kolmogorov-Smirnov) > 0 %then %do; %let normality_tests = &normality_tests. Kolmogorov-Smirnov; %end;
		%if %index(&normality.,Cramer-Von-Mises) > 0 %then %do; %let normality_tests = &normality_tests. Cramer-Von-Mises; %end;
		%if %index(&normality.,Anderson-Darling) > 0 %then %do; %let normality_tests = &normality_tests. Anderson-Darling; %end;
		%put &normality_tests.;
	         
		proc univariate data = &dataset_name. normal;
			var &&var&i;
			%if "&grp_vars." ^= "" %then %do;
				by &grp_vars.;
			%end;
			run;
			quit;

		proc transpose data = normal&i out = normal_t_&i.(drop = _name_);
			id normalitytest;
			%if "&grp_vars." ^= "" %then %do;
				by &grp_vars.;
			%end;
			run; quit;

		data normal_t_&i.;
		    set normal_t_&i.; 
		    if Shapiro_Wilk = . then Shapiro_Wilk = 0 ;
		run;

		
		data _null_;
			call symput("normality1", tranwrd("&normality","-","_"));
			run;
			%put &normality1.;
		data _null_;
			call symput("normality_tests", tranwrd("&normality_tests","-","_"));
			run;
%put &normality_tests.;

/*		data normal_t_&i.(keep = &normality_tests.);*/
/*			set normal_t_&i.;*/
/*			run;*/

		data norm_test;
			%if "&grp_vars." = "" and "&normality_tests." = "" %then %do;
				set moments&i.(keep=skewness kurtosis);
				run;
			%end;
			%if "&grp_vars." = "" and "&normality_tests." ^= "" %then %do;
				merge moments&i.(keep=skewness kurtosis) normal_t_&i.(keep = &normality_tests.);
				run;
			%end;
			%if "&grp_vars." ^= ""  %then %do;
				merge normal_t_&i.(in=a keep = &grp_vars. &normality_tests.) moments&i.(in=b keep=&grp_vars. skewness kurtosis);
				by &grp_vars.;
				if a or b;
			%end;
			%if "&grp_vars." ^= ""  %then %do;
			data norm_test(keep = &grp_vars. &normality1.);
			set norm_test;
			run;
			%end;
			%else %do;
			data norm_test(keep = &normality1.);
			set norm_test;
			run;
			%end;
		data devolpm&i.;
				merge devolpm&i. norm_test;
			%if "&grp_vars." ^= "" %then %do;
				by &grp_vars.;
			%end;
			run;

	%end;
	/********************************************************************END OF NORMALITY******************************************************************/

	/********************************************************************START OF PERCENTILE******************************************************************/
	%if "&percentile" = "true" %then %do;
		proc univariate data= &dataset_name. noprint;
			%if "&grp_vars." ^= "" %then %do;
				by &grp_vars.;
			%end;
			var &&var&i.;
			output out= percentile&i. 	
			pctlpts = %if "&flag_ninetynine." = "true" %then %do; 99.999 99.9999 %end; &percentile_value. pctlpre = p_ 
			%if "&flag_ninetynine." = "true" %then %do; pctlname = p99_999 p99_9999 %end;;
			;
			run;	

		data devolpm&i.;
			%if "&grp_vars." = "" %then %do;
				merge devolpm&i. percentile&i.;
			%end;
			%if "&grp_vars." ^= "" %then %do;
				merge devolpm&i.(in=a) percentile&i.(in=b);
				by &grp_vars.;
				if a or b;
			%end;
			run;
	%end;

	/********************************************************************END OF PERCENTILE******************************************************************/

	/********************************************************************START OF DISTRIBUTIONS***********************************************************************************/;

	%if "&distributions" = "true" %then %do;
		goptions device = gif;
		ODS output GoodnessOfFit = gof&i(where = (test = "Anderson-Darling")keep = %if "&grp_vars." ^= "" %then %do; &grp_vars %end; distribution test pvalue);
		proc univariate data = &dataset_name.;
	    	%if "&grp_vars." ^= "" %then %do;
				by &grp_vars.;
			%end;
			var &&var&i.;
	    	histogram /  normal lognormal beta gamma exponential weibull vaxis = axis1 name = 'MyHist';     			  
	   		run;

	    proc transpose data = gof&i. (keep = %if "&grp_vars." ^= "" %then %do; &grp_vars %end; distribution pvalue) out = gof_up&i. (drop = _name_ _label_);
			id distribution;
			var pvalue;
			%if "&grp_vars." ^= "" %then %do;
				by &grp_vars.;
			%end;
		   run;

		data devolpm&i.;
			%if "&grp_vars." = "" %then %do;
				merge devolpm&i. gof_up&i.;
			%end;
			%if "&grp_vars." ^= "" %then %do;
				merge devolpm&i.(in=a) gof_up&i.(in=b);
				by &grp_vars.;
				if a or b;
			%end;
			run;

	%end;

	/********************************************************************END OF DISTRIBUTIONS***********************************************************************************/

	/********************************************************************START OF CORRELATION CHECK***********************************************************************************/
	%if "&corrlation_chk" = "true" %then %do;
		ods output pearsoncorr = correlation&i.;
		proc corr data = &dataset_name.;
			%if "&grp_vars." ^= "" %then %do;
				by &grp_vars.;
			%end;
			var &&var&i.;
			with &continuous_varlist.;
			run; quit;

		proc transpose data = correlation&i. out = correlation_up&i.(drop=_name_);
			id variable;
			var &&var&i.;
			%if "&grp_vars." ^= "" %then %do;
				by &grp_vars.;
			%end;
			run;

		data correlation_up&i.;
			retain variable;
			length variable $32.;
			set correlation_up&i.;
			variable = "&&var&i.";
			run;

		%if &i = 1 %then %do;
			data out.corr_mat;
			 	set correlation_up&i.;
/*				variables=variable;*/
				run;
		%end;

		%else %do;
			data out.corr_mat;
				set out.corr_mat correlation_up&i.;
/*				variables=variable;*/
				run;
		%end;
			data out.corr_mat1;
			set out.corr_mat;
			rename variable=variables; 
			run;
	%end;
	

	/********************************************************************END OF CORRELATION CHECK***********************************************************************************/*/;

	%if &i = 1 %then %do;
		data out.uni_summary;
		set devolpm&i.;
		if missing_count = . then missing_count = 0;
		if missing_percentage = . then missing_percentage = 0;
		if outliers_3iqr = . then outliers_3iqr = 0;
		run;
	%end;

	%else %do;
		data out.uni_summary;
		set out.uni_summary devolpm&i.;
		if missing_count = . then missing_count = 0;
		if missing_percentage = . then missing_percentage = 0;
		if outliers_3iqr = . then outliers_3iqr = 0;
		run;
	%end;

/*		proc datasets lib = work nolist kill;*/
/*		run;*/
/*		quit;*/

	%end;

	

	proc export data = out.uni_summary
		outfile = "&outputPath./UnivariateSummary.csv"
		dbms = csv replace;
		run;

	libname uni_summ xml "&outputPath./univariate summary.xml";
		data uni_summ.uni_summary;
		set out.uni_summary;
		run; 

	%if "&corrlation_chk" = "true" %then %do;
		proc export data = out.corr_mat1
			outfile = "&outputPath./Correlation_Matrix.csv"
			dbms = csv replace;
			run;
	%end;
%end;


%if "&categorical_varlist." ^= "" %then %do;
	data temp;
		set &dataset_name.(keep = &categorical_varlist.);
		run;

	%let i = 1;
	%do %until (not %length(%scan(&categorical_varlist, &i)));
		%let dsid = %sysfunc(open(temp));
			%let nobs = %sysfunc(attrn(&dsid,NOBS));
			%let rc = %sysfunc(close(&dsid));
		%put &nobs;

		/*get vartype*/
		%let dsid = %sysfunc(open(temp));
			%let varnum = %sysfunc(varnum(&dsid,%scan(&categorical_varlist, &i)));
			%let vartyp = %sysfunc(vartype(&dsid,&varnum)); /* variable type */
			%let rc = %sysfunc(close(&dsid));
		%put &vartyp;

			/*prepare the table per var*/
		proc sql;
			create table summary&i. as
			select "%scan(&categorical_varlist, &i)" as variable length = 32,
				%scan(&categorical_varlist, &i) as levels  length= 15  %if &vartyp. = C %then %do; length = 32,%end; %if &vartyp. = N %then %do;length = 8,%end; 
				count(%scan(&categorical_varlist, &i)) as num_obs,
				(calculated num_obs/&nobs.)*100 as percent_obs
			from temp
			%if &vartyp. = N %then %do; 
				where %scan(&categorical_varlist, &i) ^= . 
			%end;
			%if &vartyp. = C %then %do; 
				where %scan(&categorical_varlist, &i) ^= ""
			%end;
			group by %scan(&categorical_varlist, &i);
			quit;


		/*calculate missing*/
		proc sql;
			create table missing&i. as
			select "%scan(&categorical_varlist, &i)" as variable length = 32, "MISSING" as levels, NMISS(%scan(&categorical_varlist, &i)) as num_obs,
			(calculated num_obs/&nobs.)*100 as percent_obs
			from temp
			quit;


		/*if levels is numeric, change it to character*/
		%if &vartyp. = N %then %do;
			data summary&i.;
				set summary&i.;
				char = put(left(levels), 8.); 
				drop levels; 
				rename char=levels;
				run;
		%end;

		/*calculate the cumm. percentage*/
		data summary&i.;
			retain variable;
			length levels $50.;
			set missing&i. summary&i.;
			retain cumm_per_obs 0;
			cumm_per_obs = percent_obs + cumm_per_obs;
			run;
    
		/*append per var*/
		%if "&i." = "1" %then %do;
			data out.cat_summary;
				retain variable levels;
				format levels $50.;
				set summary&i.;
				run;
		%end;
		%else %do;
			data out.cat_summary;
				retain variable levels;
				format levels $50.;
				set out.cat_summary summary&i.;
				run;
		%end;

		%let i = %eval(&i.+1);
	%end;

	
	proc export data = out.cat_summary
		outfile = "&outputPath./CategoricalSummary.csv"
		dbms = csv replace;
		run;

	libname output xml "&outputPath./categorical_summary.xml";
		data output.cat_summary;
		set out.cat_summary;
		run;
%end;

/*missing*/
	%if "&flag_contents." ^= "true" %then %do;
		%if "&categorical_varlist." ^= "" %then %do;
			data cat_missing(drop= levels);
				set out.cat_summary(keep=variable num_obs percent_obs levels );
				where levels="MISSING";
				rename num_obs=missing_count;
				rename percent_obs=missing_percentage;
				run;
		%end;
		%if "&continuous_varlist." ^= "" %then %do;
			data cont_missing;
				set out.uni_summary(keep=variable missing_count missing_percentage);
				run;
		%end;

		data out.allmissing;
			set %if "&categorical_varlist." ^= "" %then %do; cat_missing %end; %if "&continuous_varlist." ^= "" %then %do; cont_missing %end;;
			run;
	 %end;
	 %if "&flag_contents." = "true" %then %do;
	 	data out.allmissing;
			set contents(keep=variable missing_count missing_perc);
			rename missing_perc=missing_percentage;
			run;
	 %end;

	 proc export data = out.allmissing
		outfile = "&outputPath./appData_missing.csv"
		dbms = csv replace;
		run;

%MEND univReport;
%univReport;

data _NULL_;
		v1= "EDA - UNIVARIATE_SUMMMARY_COMPLETED";
		file "&outputPath./SUMMARY_COMPLETED.txt";
		PUT v1;
run;

