/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/BINNING_MULTIPLE_COMPLETED.txt;
/* VERSION : 1.3.1 */

options mprint mlogic symbolgen mfile ;

proc printto log="&output_path./BinningMultiple_Log.log";
run;
quit;
	
/*proc printto print="&output_path./BinningMultiple_Output.out";*/
	

libname in "&input_path.";
libname prev "&preview_path.";
libname out "&output_path.";


%macro multipleBinning;

/* PREVIEW */
%if "&mode." = "preview" %then %do;
	data _null_;
		call symput ("test_vars", compbl("&test_vars."));
		run;
	%put &test_vars.;

	/*subset input dataset*/
	data temp;
		set in.dataworking(keep=primary_key_1644 &test_vars.);
		run;

	/*find the increment*/
	data _null_;
		call symput("increment", round((100/&num_grps.),.01));
		run;
	%put &increment;

	/*loop for each individual variable*/
	%let i = 1;
	%do %until (not %length(%scan(&test_vars, &i)));
		/*create macro variable for varname*/
		data _null_;
			call symput("var_name", "%scan(&test_vars, &i)");
			run;

		/*univariate procedure to find pctl points*/
		proc univariate data = temp;
			var &var_name.;
			output out= uni
				pctlpts= 0 to 100 by &increment. 100 
				pctlpre=p_ ;
			run;

		/*create sub-dataset per variable*/
		data uni;
			length attribute $32.;
			retain attribute;
			set uni;
			attribute = "&var_name.";
			run;

		/*append each sub-dataset to preview output*/
		%if "&i." = "1" %then %do;
			data uni_out;
				set uni;
				run;
		%end;
		%else %do;
			data uni_out;
				set uni_out uni;
				run;
		%end;
		%let i = %eval(&i.+1);
	%end;

	/*transpose the output into required form*/
	proc transpose data = uni_out out = out.out_preview(drop=_label_ rename=(_name_=pctls));
		id attribute;
		run;

	/*condition the output*/
	data out.out_preview(drop=pctls);
		retain percentile;
		format &test_vars. 10.2;
		set out.out_preview;
		pctls = substr(pctls, 3, 5);
		pctls = tranwrd(pctls, "_", ".");
		percentile = pctls*1;
		run;

	/*export the preview output into CSV*/
	proc export data = out.out_preview
		outfile = "&output_path./preview_percentiles.csv"
		dbms = csv replace;
		run;
%end;

/* CONFIRM */
%if "&mode." = "confirm" %then %do;
	data _null_;
		call symput ("percentiles", compbl("&percentiles."));
		call symput ("var_list", compbl("&var_list."));
		run;
	%put &percentiles;
	%put &var_list.;


	/*remove 0 & 100 form percentiles list*/
	%let pctls =;
	%do i = 1 %to %sysfunc(countw(&percentiles));
		%if %scan(&percentiles,&i) ^= 0 and %scan(&percentiles,&i) ^= 100 %then %do;
			data _null_;
				call symput("pctls", cat("&pctls.", " ", "%scan(&percentiles,&i)"));
				run;
		%end;
	%end;
	%put &pctls;


	/*subset input dataset*/
	data temp;
		set in.dataworking(keep=primary_key_1644 &var_list.);
		run;

	/*get comma-separated macro-variables for sql steps*/
	data _null_;
		call symput("vars", tranwrd("&var_list.", " ", " ,"));
		call symput("pctls", cats("0, ", tranwrd(compbl("&pctls."), " ", ", "), ", 100"));
		run;
	%put &vars;
	%put &pctls;

	/*keep only the required pctl points*/
	proc sql;
		create table pctl_points as
		select percentile, &vars. from prev.out_preview
		where percentile in (&pctls.);
		quit;
	
	/*count total number of pctl points*/
	proc sql;
		select count(*) into :num_points from pctl_points;
		quit;
	%put &num_points;

	
	/*loop for each variable*/
	%let i = 1;
	%do %until (not %length(%scan(&var_list, &i)));
		/*get the exact pctl points*/
		data _null_;
			set pctl_points;
			call symput("var", "%scan(&var_list, &i)");
			call symput("pctl"||left(input(put(_n_,8.),$8.)), strip(%scan(&var_list, &i)));
			run;

		/*binning!*/
		data temp;
			format &prefix._&var. $100.;
			set temp;
			%do j = 1 %to %eval(&num_points. - 1);
				%let k = %eval(&j.+1);
				if &&pctl&j. <= &var. <= &&pctl&k. then do;
						%if "&type_bin." = "range" %then %do;
							&prefix._&var. = "&&pctl&j. - &&pctl&k";
						%end;
						%if "&type_bin." = "grouping" %then %do;
							&prefix._&var. = "&j.";
						%end;
				end;
			%end;
			run;

		/*sub-dataset for new varname*/
		data newvar;
			length newvar $32.;
			newvar = "&prefix._&var.";
			%if "&type_bin." = "range" %then %do;
				type = "string";
			%end;
			%if "&type_bin." = "grouping" %then %do;
				type = "numeric";
			%end;
			category = "categorical";
			num_distinct = "&num_points.";
			run;

		/*append the new varnames*/
		proc append base = new_vars data = newvar force;
			run;
		
		%let i = %eval(&i.+1);
	%end;

	/*subset viewpane*/
	data temp;
		set temp(drop=primary_key_1644);
		run;
	proc export data = temp
		outfile = "&output_path./binning_subsetViewpane.csv"
		DBMS = CSV replace;
		run;quit;


	/*merge back the temp dataset with input dataset*/
	data in.dataworking;
		merge temp(in=a) in.dataworking(in=b);
		by primary_key_1644;
		if a or b;
		run;


	/*XML output for new variable names*/
	libname newvars xml "&output_path./new_variables.xml";
	data newvars.new_vars;
		set new_vars;
		run;	

%end;

%mend multipleBinning;
%multipleBinning;
%include %unquote(%str(%'&genericCode_path./datasetprop_update.sas%'));


/* Flex uses this file to test if the code has finished running */
data _null_;
	v1= "EDA - BINNING_MULTIPLE_COMPLETED";
	file "&output_path/BINNING_MULTIPLE_COMPLETED.txt ";
	PUT v1;
run;

/*ENDSAS;*/



