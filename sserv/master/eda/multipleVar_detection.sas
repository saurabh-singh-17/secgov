/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/MULTIVAR_DETECTION_COMPLETED.txt;
/* VERSION # 1.1.1 */

options mprint mlogic symbolgen mfile ;

proc printto log="&output_path/MultiVar_Detection_Log.log";
run;
quit;
	
/*proc printto print="&output_path/MultiVar_Detection_Output.out";*/
	


libname in "&input_path.";
libname out "&output_path.";

%MACRO var_detection;

/* get NOBS to calculate missing & outlier percentage */
	%let dset=in.dataworking;
		%let dsid = %sysfunc(open(&dset));
		%let nobs =%sysfunc(attrn(&dsid,NOBS));
		%let rc = %sysfunc(close(&dsid));
	%put &nobs;
		%let lower =;
		%let upper =;


	/* OUTLIER - get the upper and lower values */
	%if "&flag_outlier." = "true" %then %do;
		
		%if "&outlier_type." = "perc" %then %do;
			%if "&perc_lower." ^= "" %then %do;
				%let lower = %sysevalf(&perc_lower.);
			%end;
			%if "&perc_upper." ^= "" %then %do;
				%let upper = %sysevalf(&perc_upper.);
			%end;
		%end;
		%else %if "&outlier_type." = "iqr" %then %do;
			%if "&outlier_side." = "two" %then %do;
				%let lower = %sysevalf(25);
		      	%let upper = %sysevalf(75);
			%end;
			%else %if "&outlier_side." = "one" %then %do;
				%let upper = %sysevalf(75);
			%end;
		%end;
	%end;

/* LOOP for each variable */
	%let i = 1;
	%do %until (not %length(%scan(&var_list,&i)));

		/* get name of the current variable */
		%let var = %scan(&var_list,&i);

			
		/* get statistic values - proc univariate */
		proc univariate data = in.dataworking(keep=&var.);
			var &var.;
			output out = univ&i.
				mean = mean
				median = median
				mode = mode
				qrange = iqr
				pctlpts = 0 to 0.8 by 0.2 1 to 5 by 1 25 75 95 to 99 by 1 99 to 100 by 0.1 
					%if "&upper." ^= "" %then %do; &upper. %end; %if "&lower." ^= "two" %then %do; &lower. %end;
				pctlpre = p_ 
				%if "&flag_missing." = "true" %then %do;
					nmiss = missing_count
				%end;
				;
			run;quit;


		/* OUTLIER - calculate outlier cut-offs */
		%if "&flag_outlier." = "true" %then %do;
			data _null_;
				set univ&i.;
				%if "&outlier_type." = "iqr" %then %do;
					%if "&outlier_side." = "two" %then %do;
						call symputx("outlier_lb", compress(p_25 - (&iqr_value. * iqr)));
					%end;
					call symputx("outlier_ub", compress(p_75 + (&iqr_value. * iqr)));
				%end;
				%else %if "&outlier_type." = "perc" %then %do;
					%if "&lower." ^= "" %then %do;
						call symputx("outlier_lb", compress(p_%sysfunc(tranwrd(&lower.,.,_))));
					%end;
					%if "&upper." ^= "" %then %do;
						call symputx("outlier_ub", compress(p_%sysfunc(tranwrd(&upper.,.,_))));
					%end;
				%end;
				run;
			%put &outlier_ub;
			%if "&outlier_side." = "two" %then %do; 
				%put &outlier_lb; 
			%end;
		%end;


		/* MISSING - get count of special characters */
		%if "&flag_missing." = "true" and "&missing_spl." ^= "" %then %do;
			proc sql;
				select count(&var.) into :cnt_splChar from in.dataworking where &var. in (&missing_spl.);
				quit;
			%put &cnt_splChar;
		%end;


		/* OUTLIER - calculate the number of outliers */
		%if "&flag_outlier." = "true" %then %do;
			proc sql;
				%if "&lower." ^= "" and "&upper." ^= "" %then %do;
					select count(&var.) into :outlier_cnt from in.dataworking where &var. > %sysevalf(&outlier_ub.) or &var. < %sysevalf(&outlier_lb.);
                %end;
				%else %if "&lower." = "" and "&upper." ^= "" %then %do;
					select count(&var.) into :outlier_cnt from in.dataworking where &var. > %sysevalf(&outlier_ub.);
                %end;
				%else %if "&lower." ^= "" and "&upper." = "" %then %do;
					select count(&var.) into :outlier_cnt from in.dataworking where &var. < %sysevalf(&outlier_lb.);
				%end;
				quit;
		%end;


		/* Putting varname, outlier values and missing values in the data */
		data univ&i.;
			length variable $32.;
			set univ&i.;
			variable = "&var.";
			%if "&flag_missing." = "true" %then %do;
				%if "&missing_spl." ^= "" %then %do;
					missing_count = missing_count+%eval(&cnt_splChar);
				%end;
				missing_perc = missing_count/%eval(&nobs.);
			%end;
			%if "&flag_outlier." = "true" %then %do;
				%if "&upper." ^= "" %then %do;
					upper_cutoff = %sysevalf(&outlier_ub.);
/*					drop p_%sysfunc(tranwrd(&upper.,.,_));*/
				%end;
				%if "&lower." ^= "" %then %do;
					lower_cutoff = %sysevalf(&outlier_lb.);
/*					drop p_%sysfunc(tranwrd(&lower.,.,_));*/
				%end;
				outlier_count = %sysevalf(&outlier_cnt.);
				outlier_perc = %eval(&outlier_cnt.)/%eval(&nobs.);
			%end;
			run; 
		
		%symdel cnt_splChar outlier_lb outlier_ub outlier_cnt;

		proc append base = output data = univ&i. force;
			run;

		proc datasets lib = work;
			delete univ&i.;
			run;

		%let i = %eval(&i.+1);
	%end;

	data output(drop=iqr);
		retain variable %if "&flag_missing." = "true" %then %do; missing_count missing_perc %end; 
			%if "&flag_outlier." = "true" %then %do; outlier_count outlier_perc
				%if "&upper." ^= "" %then %do; upper_cutoff %end;
				%if "&lower." ^= "" %then %do; lower_cutoff %end; 
			%end; 
			mean median mode;
		set output;
		attrib _all_ label="";
		%if "&flag_missing." = "true" %then %do;
			format missing_perc PERCENT8.2;
		%end;
		%if "&flag_outlier." = "true" %then %do;
			format outlier_perc PERCENT8.2;
		%end;
		format p_: 12.3;
		run;

	proc export data = output
		outfile = "&output_path./multiVar_detection.csv"
		dbms = csv replace;
		run;

%MEND var_detection;
%var_detection;


/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "EDA - MULTIVAR_DETECTION_COMPLETED";
	file "&output_path/MULTIVAR_DETECTION_COMPLETED.txt";
	put v1;
	run;

/*ENDSAS;*/


