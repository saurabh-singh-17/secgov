/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/VARIABLE_FREQ_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;

proc printto log="&output_path/freq_code_Log.log";
run;
quit;
/*proc printto print="&output_path/freq_code_Output.out";*/

/*%sysexec del "&output_path/VARIABLE_FREQ_COMPLETED.txt";*/

libname in "&input_path";
libname out "&output_path";

%macro binning;

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
/*%if "&missing_values" = "no" %then %do;*/
/*	data in.nonmissing out.missing;*/
/*		set in.&dataset_name;*/
/*		if &analysis_var. = . then do;*/
/*			format b_&analysis_var. $100.;*/
/*			b_&analysis_var. = "missing";*/
/*			output out.missing;*/
/*		end;*/
/*		else output in.nonmissing;*/
/*	run;*/
/**/
/*	%let input_data = nonmissing;*/
/*%end;*/
/**/
/*%else %do;*/
	%let input_data = &dataset_name;
/*%end;*/

/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/

	proc univariate data = in.&input_data(keep = &&var_name&m.);
		var &&var_name&m.;
		output out = uni_output mean = mu std = sigma min = min range = range;
		run;
		quit;

	data _null_;
		set uni_output;
		call symputx("min",min);
		call symputx("range",range);
	run;

	%put The min value of &analysis_var. is &min. ;
	%put The range value of &analysis_var. is &range. ;

/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
/*                                                                           EQUAL SIZE BINNING                                                                           */

/*1*/ %if "&bin_type"  = "equalsize" %then %do;

		data increment(keep = increment);
			retain increment &min.;
			do k = 1 to &no_bins;
				increment + %sysevalf(&range./&no_bins);
				output;
			end;
		run;

		data _null_;
			set increment nobs = no_obs;
			call symputx("increment"||left(input(put(_n_,3.),$3.)), increment);
			call symputx("no_obs",compress(no_obs));
		run;

		%let increment0 = &min.;
		%put &increment0 &increment1 &no_obs;

		data binned;
			format b_&&var_name&m. $100.;
			set in.&input_data(keep = &&var_name&m.);
				%do i = 0 %to %eval(&no_obs. - 1);
					%let j = %eval(&i. +1);
						%if &i = 0 %then %do;
							if &&increment&i <= &&var_name&m. <= &&increment&j then b_&&var_name&m. = "&&increment&i. - &&increment&j";
						%end;
						%else %do;
							else if &&increment&i < &&var_name&m. <= &&increment&j then b_&&var_name&m. = "&&increment&i. - &&increment&j";
						%end;

				%end;
			run;

		%end;

/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/

/*                                                                           PERCENTILE BINNING                                                                           */

/*2*/ %if "&bin_type"  = "percentile" %then %do;

		proc sort data = in.&input_data(keep = &&var_name&m.) out = per_temp;
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

	/*2*/%end;

/*                                                                           DATA ORDER BINNING                                                                           */

/*3*/ %if "&bin_type"  = "data_order" %then %do;

		data _null_;
			set in.&input_data nobs = total_obs;
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
			call symputx("increment"||left(input(put(_n_,8.),$8.)), round(increment));
			call symputx ("no_obs",compress(no_obs));
			run;

		%let increment0 = 1;
		%put &increment0 &increment1 &no_obs;

		data binned;
			format b_&&var_name&m. $100.;
			set in.&input_data (keep = &&var_name&m.);

				%do i = 0 %to %eval(&no_obs. - 1);
					%let j = %eval(&i. +1);
						%if &i = 0 %then %do;
							if &&increment&i <= _n_ <= &&increment&j then b_&&var_name&m. = "&&increment&i. - &&increment&j";
						%end;
						%else %do;
							else if &&increment&i < _n_ <= &&increment&j then b_&&var_name&m. = "&&increment&i. - &&increment&j";
						%end;
					%end;
			run;

	/*3*/%end;

/*                                                                           CUSTOM BINNING                                                                           */


/*/*4*/ %if "&bin_type"  = "custom" %then %do;*/
/**/
/*libname custom xml "&output_path/custom_values.xml";*/
/**/
/*data increment;*/
/*set custom.custom_values;*/
/*run;*/
/**/
/*	data _null_;*/
/*	set increment nobs = no_obs;*/
/*	suffix = put(_n_,8.);*/
/*	call symputx (cats("increment",suffix),custom_values);*/
/*	call symputx ("no_obs",no_obs);*/
/*	run;*/
/**/
/*%let increment0 = &min.;*/
/*%put &increment0 &increment1 &no_obs;*/
/**/
/*data out.binned;*/
/*	set in.&input_data (keep = &analysis_var.);*/
/*	format b_&analysis_var. $100.;*/
/*	%do i = 0 %to %eval(&no_obs.);*/
/**/
/*		%let j = %eval(&i. +1);*/
/**/
/*		%if &i = 0 %then %do;*/
/*			if &&increment&i <= &analysis_var. <= &&increment&j then b_&analysis_var. = "&&increment&i. - &&increment&j";*/
/*		%end;*/
/**/
/*		%else %if %eval(&i) > 0 and %eval(&i) < %eval(&no_obs.) %then %do;*/
/*			else if &&increment&i < &analysis_var.<= &&increment&j then b_&analysis_var. = "&&increment&i. - &&increment&j";*/
/*		%end;*/
/**/
/*		%else %if "&i" = "&no_obs." %then %do;*/
/*			else if &analysis_var. > &&increment&i. then b_&analysis_var. = " > &&increment&i. ";*/
/*		%end;*/
/* */
/*	%end;*/
/*run;*/
/**/
/*/*4*/%end;*/
/**/
/*/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/*/
/**/
/*%if "&missing_values" = "no" %then %do;*/
/*	data OUT.BINNED;*/
/*	set OUT.BINNED out.missing;*/
/*	run;*/
/*%end;*/;

%if "&grp_vars" = "" and "&time_var" = "" %then %do;

	%if "&freq_type" = "unique" %then %do;

			proc sort data = binned out = sorted_bin nodupkey;
				by b_&&var_name&m. &&var_name&m.;
				run;

			proc freq data = sorted_bin;
				tables b_&&var_name&m./missing out = freq_out(rename = (b_&&var_name&m. = variable));
				run;
			
	%end;

		%if "&freq_type" ^= "unique" %then %do;

			proc freq data = binned;
				tables b_&&var_name&m./missing out = freq_out(rename = (b_&&var_name&m. = variable));
			run;

		%end;
	
%end;

/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& Group Vars &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
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
					set temp;
							array aa(*) &grp_vars ;
							variable = catx("_" , of aa[*]);
					run;
	%end;

	%if %eval(&num_varcnt.) = 0 %then %do;
			data temp(drop = &grp_vars.);
			set in.&dataset_name(keep = &grp_vars. &analysis_var.);
				array aa(*) &grp_vars ;
				variable = catx("_" , of aa[*]);
			run;
	%end;

		%if "&freq_type" = "unique" %then %do;

				proc sort data = temp out = sorted_temp nodupkey;
					by variable &&var_name&m.;
					run;

				proc freq data = sorted_temp;
					tables variable/missing out = freq_out;
					run;
				
			%end;

			%if "&freq_type" ^= "unique" %then %do;

				proc freq data = temp;
					tables variable/missing out = freq_out;
					run;

			%end;
	
%end;

/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& Time Vars &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/

%if "&time_var" ^= "" %then %do;

	data temp (drop = &time_var.);
		length variable $100.;
		set in.&dataset_name(keep = &time_var. &analysis_var.);
		variable = put(&time_var.,&time_window..);
		run;

	%if "&freq_type" = "unique" %then %do;

		proc sort data = temp  out = sorted_data nodupkey;
			by variable &&var_name&m.;
			run;

		proc freq data = sorted_data;
			tables variable/missing out = freq_out;
			run;

	%end;

	%if "&freq_type" ^= "unique" %then %do;

		proc freq data = temp;
			tables variable/missing out = freq_out;
			run;

	%end;

%end;

data freq_out;
	retain variable	frequency cum_freq PERCENT cum_percent;
	format variable $100.;
	set freq_out (rename = (count = frequency));
	cum_freq+frequency;
	cum_percent+percent;
	if compress(variable) in ("",".") then variable = "missing";
	run;


proc export data = freq_out
	outfile = "&output_path/&&var_name&m...csv"
	dbms = csv replace;
	run;

/*libname freq xml "&output_path/&&var_name&m...xml";*/
/*	data freq.freq ;*/
/*	set freq_out;*/
/*	run;*/

%end;

%mend binning;
%binning

/* Flex uses this file to test if the code has finished running */
data _null_;
	v1= "EDA - FREQUENCY CODE_COMPLETED";
	file "&output_path/VARIABLE_FREQ_COMPLETED.txt";
	put v1;
run;

endsas;


