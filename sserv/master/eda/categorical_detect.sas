/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/CATEGORICAL_DETECTION_COMPLETED.txt;
option mprint mlogic symbolgen mfile ;

proc printto log="&output_path/Categorical_VariableDetection_Log.log";
run;
quit;
/*proc printto print="&output_path./Categorical_VariableDetection_Output.out";*/

libname in "&input_path.";
libname out "&output_path.";
%let dataset_name=in.dataworking;

data in.bygroupdata;
	set in.dataworking;
	run;

%macro categorical_detect;
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
			select "%scan(&categorical_varlist, &i)" as variable length = 32,%scan(&categorical_varlist, &i) as levels, 
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
			format levels $25.;
			set missing&i. summary&i.;
			retain cumm_per_obs 0;
			cumm_per_obs = percent_obs + cumm_per_obs;
			run;
    
		/*append per var*/
		%if "&i." = "1" %then %do;
			data out.cat_summary;
				set summary&i.;
				run;
		%end;
		%else %do;
			data out.cat_summary;
				set out.cat_summary summary&i.;
				run;
		%end;

		%let i = %eval(&i.+1);
	%end;

	
	proc export data = out.cat_summary
		outfile = "&output_path./CategoricalSummary.csv"
		dbms = csv replace;
		run;

	libname output xml "&output_path./categorical_summary.xml";
		data output.cat_summary;
		set out.cat_summary;
		run;
%end;

%mend categorical_detect;
%categorical_detect;



/* Flex uses this file to test if the code has finished running */
data _null_;
	v1= "CATEGORICAL_DETECTION_COMPLETED";
	file "&output_path/CATEGORICAL_DETECTION_COMPLETED.txt";
	put v1;
run;


