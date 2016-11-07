/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/MISSING_DETECTION_COMPLETED.txt;
options mprint mlogic symbolgen mfile;

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
	set in.dataworking (keep = &var_list.);
	run;


/*find total no. of obs*/
data _null_;
	set out.temp nobs = num_obs;
	call symputx("num_obs",num_obs);
	stop;
	run;
	

/*define macro to get comma separated list of variables*/
data _null_;
	set out.temp;
	call symputx("missing_values", compress(tranwrd("&missing_list." ," " ," ," )));
	call symputx("vars", compress(tranwrd("&var_list." ," " ," ," )));
	run;


%MACRO missing_detection;

%put &num_obs. &missing_values. &vars.;

%LET i =1;
	%DO %UNTIL(NOT %LENGTH(%SCAN(&var_list,&i))) ;

	/*macro for individual variable*/
		data _null_;
			set out.temp;
			call symputx("var_name", "%SCAN(&var_list,&i)");
			run;

	/*find no. of missing values*/
		
			%if "&missing_list." ^= "" %then %do;
				proc sql;
				create table missing_&i. as
				select count(*) as missing_count,
					calculated missing_count/&num_obs. as missing_percent
				from out.temp
				where &var_name. is missing or &var_name. in (&missing_list.)
				;
				quit;
			%end;
			%if "&missing_list." = "" %then %do;
				proc sql;
				create table missing_&i. as
				select count(*) as missing_count,
					calculated missing_count/&num_obs. as missing_percent
				from out.temp
				where &var_name. is missing
				;
				quit;
			%end;
		
		
	/*append the missing details for all variables*/
		data missing_&i.;
			retain attributes;
			set missing_&i.;
							
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
	
%MEND missing_detection;
%missing_detection;

/*sort for merging*/
proc sort data = missing out = missing;
	by attributes;
	run;
proc sort data = univ out = univ;
	by attributes;
	run;


/*merge the missing values details and univariate output*/
data out.missing_detection;
	merge missing (in=a) univ (in=b);
	by attributes;
	if a or b;
	run;

/*CSV export*/
proc export data = out.missing_detection
	outfile="&output_path/missingDetection.csv" 
	dbms=CSV replace; 
	run;

/*delete datasets(which are not reqd.) from 'out' lib.*/
proc datasets library = out;
	delete temp missing_detection;
	run;



/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "MISSING_DETECTION_COMPLETED";
	file "&output_path/MISSING_DETECTION_COMPLETED.txt";
	put v1;
run;


ENDSAS;









