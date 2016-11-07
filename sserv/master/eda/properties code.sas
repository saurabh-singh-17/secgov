/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/VARIABLE_PROPERTIES_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;

proc printto log="&output_path/VARIABLE_PROPERTIES.log";
run;
quit;
/*proc printto print="&output_path/VARIABLE_PROPERTIES.out";*/


libname in "&input_path";
libname out "&output_path";

%macro properties;

proc contents data = in.&dataset_name. (keep = &analysis_var.) out = contents (keep = name type);
	run;

data _null_;
	set contents;
	call symput('var_name' ||left(put(_N_,4.)), trim(name));
	run;

proc sql;
	select count(*) into :indep_varname from contents;
	quit;

%do m = 1 %to &indep_varname.;

/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
/****************************************************IF GRP_VARS AND TIME_VAR ARE BLANK**************************************************************************/
/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/

	%if "&grp_vars." = "" and "&time_var." = "" %then %do;

/*		%if "&missing_values" = "no" %then %do;*/
/*			data in.nonmissing out.missing;*/
/*				set in.&dataset_name;*/
/*				if &analysis_var. = . then do;*/
/*					format b_&analysis_var. $100.;*/
/*					b_&analysis_var. = "missing";*/
/*					output out.missing;*/
/*				end;*/
/*				else output in.nonmissing;*/
/*			run;*/
/**/
/*			%let input_data = nonmissing;*/
/*		%end;*/
/**/
/*		%else %do;*/
			%let input_data = &dataset_name;
/*		%end;*/


		/*                                                                           PERCENTILE BINNING                                                                           */

	proc sort data = in.&input_data(keep = PRIMARY_KEY_1644 &&var_name&m.) out = per_temp;
		by &&var_name&m.;
		run;

	data _null_;
		set per_temp nobs = total_obs;
		call symputx("total_obs",compress(total_obs));
		stop;
		run;

	data increment(keep = increment);
		retain increment 0;
		do k = 1 to &no_bins;
			increment + %sysevalf(&total_obs./&no_bins);
		output;
		end;
		run;

	data _null_;
		set increment nobs = no_obs;
		call symputx("increment"||left(input(put(_n_,8.),$8.)), increment);
		call symputx ("no_obs",compress(no_obs));
		run;

	%let increment0 = 1;
		%put &increment0 &increment1 &no_obs;

	data _null_;
		set per_temp;
		%do k = 0 %to &no_obs.;
			if _n_ = round(&&increment&k) then call symputx(cats("value","&k"), &&var_name&m.);
		%end;
		run;
		%put &value0 &value1 &value2 &value3 &value4;

	data binned;
		format b_&&var_name&m. $100.;
		set per_temp ;
			%do i = 0 %to %eval(&no_obs. - 1);
				%let j = %eval(&i. +1);
					%if &i = 0 %then %do;
						if &&increment&i <= _n_ <= &&increment&j then b_&&var_name&m. = "&&value&i. - &&value&j";
					%end;
					%else %do;
						else if &&increment&i < _n_ <= &&increment&j then b_&&var_name&m. = "&&value&i. - &&value&j";
				%end;
			%end;
		run;

/*	%if "&missing_values" = "no" %then %do;*/
/*		data OUT.BINNED(rename = (b_&analysis_var. = variable));*/
/*		set OUT.BINNED out.missing;*/
/*		run;*/
/*	%end;*/

	data binned(rename = (b_&&var_name&m. = variable));
		set binned;
		run;
		%let input_data = binned ;

	%end;

/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
/****************************************************IF GRP_VARS ARE GIVEN**************************************************************************/
/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
	%if "&grp_vars" ^= "" %then %do;

		proc contents data = in.&dataset_name(keep = &grp_vars.) out = contents_g(keep = name type);
			run;

		proc sql noprint;
			select count(*) into :num_varcnt from contents_g where type = 1;
			quit;

		%if %eval(&num_varcnt.) ^= 0 %then %do;
 			data _null_;
				set contents_g;
					suffix = put(_n_,8.);
					call symput (cats("num_var",suffix),compress(name));
					where type = 1;
				run;

			data temp;
				set in.&dataset_name(keep = &grp_vars. &analysis_var.);
					%do j = 1 %to &num_varcnt.;
						&&num_var&j..1 = put(&&num_var&j.,best.);
						drop  &&num_var&j.;
						rename &&num_var&j..1 = &&num_var&j.;
					%end;
				run;

			data temp(drop = &grp_vars.);
				length variable $100.;
				set temp;
					array aa(*) &grp_vars ;
					variable = catx("_" , of aa[*]);
				run;
		%end;

		%if %eval(&num_varcnt.) = 0 %then %do;
			data temp(drop = &grp_vars.);
				length variable $100.;
				set in.&dataset_name(keep = &grp_vars. &analysis_var.);
					array aa(*) &grp_vars ;
					variable = catx("_" , of aa[*]);
				run;
		%end;
		%let input_data = temp ;

	%end;

/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
/****************************************************IF GRP_VARS ARE GIVEN**************************************************************************/
/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/

	%if "&time_var." ^= "" %then %do;

		data temp (drop = &time_var.);
			length variable $100.;
				set in.&dataset_name(keep = &time_var. &analysis_var.);
				variable = put(&time_var.,&time_window..);
			run;

		%let input_data = temp;
	%end;

/************************************************************TO GET THE BASIC CHARACTERSTICS**********************************************************************/

	proc sort data = &input_data.;
		by variable;
		run;

	proc univariate data = &input_data.;
		by variable;
		var &&var_name&m.;
		output out = &&var_name&m. mean = mean median = median mode = mode std = stddev;
		run;

	data &&var_name&m.;	
		retain variable	mean median mode stddev;
		set &&var_name&m.;
		if compress(variable) in ("",".") then variable = "Missing";
		run;

	proc export data = &&var_name&m.
		outfile = "&output_path/&&var_name&m...csv"
		dbms = csv replace;
		run;

/*********************************************************TO GET THE NORMALITY**************************************************************/

/*ods output Moments = moments (where = (Label1 = "Skewness") rename = (nvalue1 = skewness nvalue2 = kurtosis)) ;*/
/*ods output TestsForNormality = normal (keep = variable test pvalue rename =(test = normalitytest pvalue = value));*/
/*proc univariate data = &input_data. normal;*/
/*	by variable;*/
/*	var &analysis_var.;*/
/*run;*/
/**/
/*proc transpose data = moments(keep = variable skewness kurtosis) out = skewness(rename = (_NAME_ = normalitytest COL1 = value));*/
/*by variable;*/
/*run; quit;*/
/**/
/*data out.normal_out;*/
/*length normalitytest $50.;*/
/*set normal skewness;*/
/*run;*/

/*	libname prop xml "&output_path/&&var_name&m...xml";*/
/*		data prop.&&var_name&m.;*/
/*		set &&var_name&m.;*/
/*		run;*/

/*libname prop1 xml "&output_path/properties2.xml";*/
/*data prop1.normality;*/
/*set out.normal_out;*/
/*if compress(variable) in ("",".") then variable = "Missing";*/
/*run;*/

%end;

%mend properties;
%properties;


/* Flex uses this file to test if the code has finished running */
data _null_;
	v1= "EDA - VARIABLE_PROPERTIES_COMPLETED";
	file "&output_path/VARIABLE_PROPERTIES_COMPLETED.txt ";
	PUT v1;
run;


endsas;


