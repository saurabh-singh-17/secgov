/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/MISSING_DETECTION_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;

FILENAME MyFile "&output_path/MISSING_DETECTION_COMPLETED.txt" ;

  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;


proc printto log="&output_path/MissingDetection_Log.log";
run;
quit;
/*proc printto print="&output_path/MissingDetection_Output.out";*/


libname in "&input_path.";
libname out "&output_path.";

/*subsetting the dataset*/
data out.temp;
	set in.dataworking (keep = &grpvar_list. &var_list.);
	run;

/*sort according to the group-by variables*/
proc sort data = out.temp out = out.temp;
	by  &grpvar_list.;
	run;


/*find total no. of obs*/
data _null_;
	set out.temp nobs = num_obs;
	call symputx("num_obs",num_obs);
	stop;
	run;
	



%MACRO missing_detection2;
/*define macro to get comma separated list of variables*/
data _null_;
	set out.temp;
	%if "&missing_list." ^= "" %then %do;
		call symputx("missing_values", compress(tranwrd("&missing_list." ," " ," ," )));
	%end;
	call symputx("vars", compress(tranwrd("&var_list." ," " ," ," )));
	call symputx("grp_vars", compress(tranwrd("&grpvar_list." ," " ," ," )));
	run;


%put &num_obs. &missing_values. &vars. &grp_vars.;

%LET i =1;
	%DO %UNTIL(NOT %LENGTH(%SCAN(&var_list,&i))) ;
	/*macro for individual variable*/	
		data _null_;
			set out.temp;
			call symputx("var_name", "%SCAN(&var_list,&i)");
			run;


		proc sql;
			select count(*) into :miss_count_&i. from out.temp
			where &var_name. is missing or &var_name. in (&missing_values.);
			quit;

		%put &&miss_count_&i.;

	%if &&miss_count_&i. ^= 0 %then %do;
	/*find no. of missing values*/
		%if "&missing_list." ^= "" %then %do;
			proc sql;
			create table missing_&i. as
			select "&var_name." as attributes length = 50, &grp_vars.,
				count(*) as missing_count,
				calculated missing_count/&num_obs. as missing_percent
			from out.temp
			where &var_name. is missing or &var_name. in (&missing_values.)
			group by &grp_vars.
			;
			quit;
		%end;
		%if "&missing_list." = "" %then %do;
			proc sql;
			create table missing_&i. as
			select "&var_name." as attributes length = 50, &grp_vars.,
				count(*) as missing_count,
				calculated missing_count/&num_obs. as missing_percent
			from out.temp
			where &var_name. is missing
			group by &grp_vars.
			;
			quit;
		%end;

	%end;
	%if &&miss_count_&i. = 0 %then %do;
		proc sql;
		create table missing_&i. as
		select "&var_name." as attributes length = 50, &grp_vars.,
			0 as missing_count,
			0 as missing_percent
		from out.temp
		group by &grp_vars.
		;
		quit;

		proc sort data = missing_&i. out = missing_&i. nodupkey;
			by &grpvar_list.;
			run;
	%end;
		

	/*append the missing details for all variables*/
		data missing_&i.;
			retain attributes;
			set missing_&i.;
			attrib _all_ label=" ";
				
			length attributes $50;
			attributes = "&var_name.";
			run;

		%if "&i" = "1" %then %do;
			data missing;
				set missing_&i.;
				run;
		%end;
		%else %do;
			data missing;
				set missing missing_&i.;
				run;
		%end;

	/*univariate treatment: excluding the missing values*/
		%if "&missing_list." ^= "" %then %do;
			proc univariate data = out.temp noprint;
				where &var_name. not in (&missing_list.);
				class &grpvar_list.;
				var &var_name.;
				output out = univ_&i.
					mean = mean
					mode = mode
					median = median
					skewness = skewness
					kurtosis = kurtosis
					pctlpts= 0 to 5 by 1 5 to 95 by 5 96 to 99 by 1 99.9 99.99
					pctlpre=p_ ;
					run;
		%end;
		%if "&missing_list." = "" %then %do;
			proc univariate data = out.temp noprint;
				class &grpvar_list.;
				var &var_name.;
				output out = univ_&i.
					mean = mean
					mode = mode
					median = median
					skewness = skewness
					kurtosis = kurtosis
					pctlpts= 0 to 5 by 1 5 to 95 by 5 96 to 99 by 1 99.9 99.99
					pctlpre=p_ ;
					run;
		%end;

	/*append the univariate output for each variable*/
		data univ_&i.;
			retain attributes;
			set univ_&i.;
			attrib _all_ label=" ";
				
			length attributes $50;
			attributes = "&var_name.";
			run;

		%if "&i" = "1" %then %do;
			data univ;
				set univ_&i.;
				run;
		%end;
		%else %do;
			data univ;
				set univ univ_&i.;
				run;
		%end;

	%LET i=%EVAL(&i+1);	
%end;
	

/*sort for merging*/
proc sort data = missing out = missing;
	by attributes &grpvar_list.;
	run;
proc sort data = univ out = univ;
	by attributes &grpvar_list.;
	run;

/*merge the missing values details and univariate output*/
data out.grpby_missing_detection;
	merge missing (in=a) univ (in=b);
	by attributes &grpvar_list.;
	if a or b;
	run;

/*rename the group-by variables*/
data out.grpby_missing_detection;
	set out.grpby_missing_detection;

	%LET j =1 ;
	%DO %UNTIL(NOT %LENGTH(%SCAN(&grpvar_list,&j)));
		rename %SCAN(&grpvar_list,&j) = by_group&j.;

		%LET j=%EVAL(&j+1);	
	%end;
	run;


%MEND missing_detection2;
%missing_detection2;

data out.grpby_missing_detection;
	set out.grpby_missing_detection;
	if missing_count = . then missing_count = 0;
	if missing_percent = . then missing_percent = 0;
	run;


/*CSV export*/
proc export data = out.grpby_missing_detection
	outfile="&output_path/missingDetection.csv" 
	dbms=CSV replace; 
	run;


/*delete datasets(which are not reqd.) from 'out' lib.*/
proc datasets library = out;
	delete temp grpby_missing_detection;
	run;



/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "MISSING_DETECTION_COMPLETED";
	file "&output_path/MISSING_DETECTION_COMPLETED.txt";
	put v1;
run;

ENDSAS;


