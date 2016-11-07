/*Successfully converted to SAS Server Format*/
*processbody;

/*VERSION # 1.2.0*/
options mprint mlogic symbolgen;

proc printto log="&output_path./seasonality_indicator.log" new;
/*proc printto;*/
run;
quit;

/*DEFINE LIBRARIES - input & output*/
libname in "&input_path.";
libname out "&output_path.";

/*CREATE MACRO VARIABLES for indicator varnames*/
%let month_list = jan feb mar apr may jun jul aug sep oct nov dec;
%let qtr_list = quarter1 quarter2 quarter3 quarter4;
%let weekday_list = sun mon tue wed thu fri sat;
%let day_list = week1 week2 week3 week4 week5;

%MACRO timeIndicator;
	/*SUBSET the input dataset and create a classification variable*/
	data temp;
		set in.dataworking (keep = &date_var. primary_key_1644);

		/* monthOfYear or quarterofYear or dayOfWeek */
		%if "&indicator." = "month" or "&indicator." = "qtr" or "&indicator." = "weekday" %then
			%do;
				value_&indicator. = &indicator.(&date_var.);
			%end;

		/* weekOfMonth - WTH day!?!? */
		%if "&indicator." = "day" %then
			%do;
				value_&indicator. = int((&indicator.(&date_var.))/7)+1;
			%end;
	run;

	/*BASE INDICATOR - create list of values for which indicators need to be created*/
	%if "&indicator_type." = "base" %then
		%do;
			%let specific_values = ;
			%do n_tempi = 1 %to %sysfunc(countw(&&&indicator._list.));
				%if &n_tempi. ^= &base_value. %then %let specific_values = &specific_values. &n_tempi.;
			%end;
		%end;

	/*CREATE LIST OF NEW VARIABLES to be created*/
	%let new_vars=;
	%let i = 1;

	%do %until (not %length(%scan(&specific_values, &i)));

		data _null_;
			call symput("new_vars", cats("&new_vars.", "!!", cats("&prefix.", substr("%scan(&&&indicator._list, %eval(%scan(&specific_values, &i)))",1,16), "_", substr("&date_var.",1,10))));
		run;

		%let i = %eval(&i.+1);
	%end;

	/*CREATE NEW VARIABLES*/
	data temp;
		set temp;
		%let i = 1;

		%do %until (not %length(%scan(&specific_values, &i)));
			if value_&indicator. = %scan(&specific_values, &i) then
				do;
					%scan(&new_vars, &i, "!!") = 1;
				end;
			else
				do;
					%scan(&new_vars, &i, "!!") = 0;
				end;

			%let i = %eval(&i.+1);
		%end;
	run;

	proc sort data=temp;
		by primary_key_1644;
	run;

	proc sort data=in.dataworking;
		by primary_key_1644;
	run;

	/*MERGE NEW VARAIBLES with input dataset*/
	data in.dataworking (drop = value_&indicator.);
		merge temp(in=a) in.dataworking(in=b drop=&date_var.);
		by primary_key_1644;

		if a or b;
	run;

	/*SUBSET VIEW-PANE*/
	/*create the subset for viewpane*/
	data temp;
		set temp(drop=primary_key_1644);
	run;

	%let dsid = %sysfunc(open(temp));
	%let nobs=%sysfunc(attrn(&dsid,nobs));
	%let rc = %sysfunc(close(&dsid));
	%put &nobs.;

	%if &nobs.>6000 %then
		%do;

			proc surveyselect data=temp out=temp method=SRS
				sampsize=6000 SEED=1234567;
			run;

		%end;

	/*export subset-viewpane into CSV*/
	proc export data = temp


		outfile = "&output_path./timeIndicatorVariable_subsetViewpane.csv"


		dbms = CSV replace;
	run;

	/*CREATE LIST of new variables*/
	/*get contents of the temporary dataset*/
	proc contents data = temp(drop=&date_var. value_&indicator.) out = contents_temp(keep=name rename=(name=new_varname));
	run;

	/*create XML output*/
	libname newvar xml "&output_path./timeIndicatorVariable_new_varname.xml";

	data newvar.new_varname;
		set contents_temp;
	run;

	%include %unquote(%str(%'&genericCode_path./datasetprop_update.sas%'));

	/* flex uses this file to test if the code has finished running */
	data _null_;
		v1= "TIME_INDICATOR_VARIABLE_COMPLETED";
		file "&output_path/TIME_INDICATOR_VARIABLE_COMPLETED.txt";
		put v1;
	run;

	/*ENDSAS;*/
%MEND timeIndicator;

%timeIndicator;
;
