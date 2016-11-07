/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/PROP_FREQ_COMPLETED.txt;
dm log 'clear';
dm output 'clear';
options mprint mlogic symbolgen mfile;

/*proc printto log="&output_path/freq_code_Log.log" new;*/
/*run;*/
/*quit;*/
	
proc printto;
run;
quit;

libname in "&input_path";
libname out "&output_path";

%MACRO prop_freq;

%if %str(&no_bins.) ^= %str() %then
	%do;
		/*if no of bins contains leading zero then it'll remove that zero's*/
		data _null_;
			call symput("no_bins",substr(&no_bins.,verify(&no_bins.,"0")));
		run;

	%end;

%if "&num_vars." ^= "" %then %do;
	/* FOR panel-wise and grp-var */
	%if "&bin_type." = "" %then %do;

	/* CREATING THE SUBSET */
	/* panel-wise */
		%if "&grp_vars." ^= "" %then %do;
			data _null_;
				call symput("cat_grp", tranwrd("&grp_vars.", " ", ","));
				run;quit;
			%put &cat_grp;

			data temp;
				set &dataset_name.(keep =&grp_vars. &num_vars. );
				grp_var = catx("_",&cat_grp.);
				run;quit;
		%end;
	/*---------------------------------------------------------------------*/
	/* time-var */
		%if "&time_var." ^= "" %then %do;
			data temp;
				set in.dataworking(keep = &time_var. &num_vars.);
				format grp_var &time_window.;
				grp_var = &time_var.;
				run;	
		%end;
	/*---------------------------------------------------------------------*/

	/*##############################################################################################################*/
	/* getting the num_obs for subset */
		%let dset=temp;
			%let dsid = %sysfunc(open(&dset));
			%let nobs_i =%sysfunc(attrn(&dsid,NOBS));
			%let rc = %sysfunc(close(&dsid));
		%put &nobs_i;

	/*##############################################################################################################*/
	/* FREQUENCY & PROPERTY PROCESSING */
		
		/*sorting the data grp-wise*/
		proc sort data = temp;	
			by grp_var;
			run;

		/*PROC SUMMARY - to get the reqd. metrics*/
		ods output summary = summary;
		proc means data=temp &prop_type. missing maxdec=3;
			var &num_vars.;
			by grp_var;
			output out = prop;
			run;

		%if %sysfunc(countw(&num_vars.)) = 1 %then %do;
			data summary;
				set summary;
				Vname_%substr(&num_vars., 1, 26) = lowcase("&num_vars.");
				run;
		%end;

		%if "&flag_freq." = "true" and %index("&freq_type.", unique) > 0 %then %do;
			ods output nlevels = nlevels(keep=grp_var TableVar nlevels rename=(TableVar=Variable nlevels=count_distinct));
			proc freq data = temp nlevels;
				tables &num_vars.;
				by grp_var;
				run;

			proc sql;
				select sum(count_distinct) into :sum_distinct  from nlevels;
				quit;
			%put &sum_distinct;

			data nlevels;
				set nlevels;
				variable = lowcase(variable);
				percent_distinct = (count_distinct/%eval(&sum_distinct.))*100;
				retain cumm_distinct cumm_perc_distinct 0;
				cumm_distinct = cumm_distinct+count_distinct;
				cumm_perc_distinct = cumm_perc_distinct+percent_distinct;
				run;

		%end;
			
		
		/*creating outputs for each variable*/
		%let var_cnt = 1;
		%do %until (not %length(%scan(&num_vars, &var_cnt)));
			data _null_;
				call symput("var_name", compbl("%scan(&num_vars, &var_cnt)"));
				run;
			
			data &var_name.;
				set summary(keep=grp_var VName_%substr(&var_name., 1, 26) 
					%if "&flag_freq." = "true" %then %do;	%substr(&var_name., 1, 28)_N %end;
					%if %index(&prop_type.,mean) >0 %then %do;	%substr(&var_name., 1, 25)_Mean %end;
					%if %index(&prop_type.,median) >0 %then %do; %substr(&var_name., 1, 23)_Median %end;
					%if %index(&prop_type.,stddev) >0 %then %do; %substr(&var_name., 1, 23)_stddev %end;
					%if %index(&prop_type.,range) >0 %then %do; %substr(&var_name., 1, 24)_range %end;);
				%if "&flag_freq." = "true" and %index("&freq_type.", total) > 0 %then %do;
					percent_obs = (%substr(&var_name., 1, 28)_N/%eval(&nobs_i.))*100;
					retain cumm_obs cumm_perc_obs 0;
					cumm_obs = cumm_obs+%substr(&var_name., 1, 28)_N;
					cumm_perc_obs = cumm_perc_obs+percent_obs;
				%end;
				rename VName_%substr(&var_name., 1, 26) = Variable 
					%if "&flag_freq." = "true" %then %do; %substr(&var_name., 1, 28)_N = NOBS %end;
					%if %index(&prop_type.,mean) >0 %then %do;	%substr(&var_name., 1, 25)_Mean = Mean %end;
					%if %index(&prop_type.,median) >0 %then %do; %substr(&var_name., 1, 23)_Median = Median %end;
					%if %index(&prop_type.,stddev) >0 %then %do; %substr(&var_name., 1, 23)_stddev = StdDev %end;
					%if %index(&prop_type.,range) >0 %then %do; %substr(&var_name., 1, 24)_range = Range %end;;
				run;

			%if "&flag_freq." = "true" and %index("&freq_type.", unique) > 0  %then %do;
/*				proc sort data = nlevels;*/
/*					by Variable grp_var;*/
/*					run;*/
				proc sort data = nlevels out=nlevels1;
					by  grp_var Variable;
					run;
				
				data %substr(&var_name.,1,31)2;
				length variable $27.;
				set &var_name.;
				format variable $27.;
				variable=lowcase(variable);
				run;

				data &var_name.;
					merge %substr(&var_name.,1,31)2(in=a) nlevels1(in=b);
					by  grp_var variable;
					if a;
/*					%if %index("&freq_type.", total) = 0 %then %do;*/
/*						drop NOBS;*/
/*					%end;*/
					run;
			%end;
			
			/*	To change column names*/
			
			data &var_name.(rename=(grp_var=Panel_Level count_distinct=Unique_Count percent_distinct=Unique_Percent 
            cumm_distinct=Cumulative_distinct cumm_perc_distinct=Cumulative_percent_distinct 
            NOBS=Total_Frequency percent_obs=Total_Frequency_Percent cumm_obs=Cumulative_Frequency 
            cumm_perc_obs=Cumulative_Percent StdDev=Standard_Deviation ));
			set &var_name. ;
			
			run;

			
			%let test = worked;
			%put &test.;

			%if "&flag_freq." = "true" and %index("&freq_type.", unique) > 0 %then %do;
			
			data &var_name.;
			set &var_name.(drop=variable);
			run;
			%end;

			proc export data = &var_name.
				outfile = "&output_path./continuous/&var_name..csv"
				dbms = CSV replace;
				run;


			%let var_cnt = %eval(&var_cnt.+1);
		%end;

	%end;

	/*##############################################################################################################*/
	/* for BINNING */
	%if "&bin_type." ^= "" %then %do;	

		/* getting the num_obs for subset */
		%let dset=in.dataworking;
			%let dsid = %sysfunc(open(&dset));
			%let nobs_a =%sysfunc(attrn(&dsid,NOBS));
			%let rc = %sysfunc(close(&dsid));
		%put &nobs_a;

		/*dataset-order*/
		%if "&bin_type." = "data_order" %then %do;
			data _null_;
			%do m = 1 %to %eval(&no_bins.);
				call symput("bin&m.", %sysevalf(%sysevalf(&nobs_a./&no_bins.)*%eval(&m.-1)));
			%end;
			run;

			data temp;	
				length bin_range $30.;
				set in.dataworking(keep=&num_vars. primary_key_1644);
				%do j = 1 %to %eval(&no_bins.);
					%let k = %eval(&j.+1);
					%if "&j." = "1" %then %do;
						if primary_key_1644 >= %sysevalf(&&bin&j.) and primary_key_1644 <= %sysevalf(&&bin&k.) then do;
							grp_var = %eval(&j.);
							bin_range = "%sysevalf(&&bin&j.) - %sysevalf(&&bin&k.)";
						end;
					%end;
					%else %if "&j." ^= "1" and "&j." ^= "%eval(&no_bins.)" %then %do;
						if primary_key_1644 > %sysevalf(&&bin&j.) and primary_key_1644 <= %sysevalf(&&bin&k.) then do;
							grp_var = %eval(&j.);
							bin_range = "%sysevalf(&&bin&j.) - %sysevalf(&&bin&k.)";
						end;
					%end;
					%else %if "&j." = "%eval(&no_bins.)" %then %do;
						if primary_key_1644 >= %sysevalf(&&bin&j.) and primary_key_1644 <= %sysevalf(&nobs_a.) then do;
							grp_var = %eval(&j.);
							bin_range = "%sysevalf(&&bin&j.) - %sysevalf(&nobs_a.)";
						end;
					%end;
				%end;
				run;

			proc sort data = temp;
				by grp_var bin_range;
				run;
		%end;
		
		%let i = 1;
		%do %until (not %length(%scan(&num_vars,&i)));

			data _null_;
				call symput("var_name", "%scan(&num_vars,&i)");
				run;
			%put &var_name;


			/*percentile*/
			%if "&bin_type." = "percentile" %then %do;
				proc univariate data = in.dataworking(keep=&var_name.);
					var &var_name.;
					output out = univ&i.
						pctlpts = 0 to 100 by %sysevalf(100/&no_bins.)
						pctlpre = p_;
						run;
		
				proc transpose data = univ&i. out = univ_&i.(drop=_label_ rename=(col1=perc_value));
					run;

				data _null_;
					set univ_&i.;
					call symput("pctl"||LEFT(PUT(_N_, 4.)), trim(perc_value));
					run;

				data temp;	
					length bin_range $30.;
					set in.dataworking(keep=&var_name. primary_key_1644);
					%do j = 1 %to %eval(&no_bins.);
					%let k = %eval(&j.+1);
						%if "&j." = "1" %then %do;
							if &var_name. >= %sysevalf(&&pctl&j.) and &var_name. <= %sysevalf(&&pctl&k.) then do;
								grp_var = %eval(&j.);
								bin_range = "%sysevalf(&&pctl&j.) - %sysevalf(&&pctl&k.)";
							end;
						%end;
						%else %do;
							if &var_name. > %sysevalf(&&pctl&j.) and &var_name. <= %sysevalf(&&pctl&k.) then do;
								grp_var = %eval(&j.);
								bin_range = "%sysevalf(&&pctl&j.) - %sysevalf(&&pctl&k.)";
							end;
						%end;
					%end;
					run;

				proc sort data = temp;
					by grp_var bin_range;
					run;
			%end;
		
			/*equal-range*/
			%if "&bin_type." = "equalsize" %then %do;
				proc sql;
				select unique(&var_name.) into :uniqueval seperated by " " from in.dataworking;
				run;
				data _null_;
					call symput("uniqueval",tranwrd("&uniqueval.",".",""));
				run;
				%if %sysfunc(countw(&uniqueval.," ")) < &no_bins. %then %do;
					data _null_;
						call symput("no_bins",%sysfunc(countw(&uniqueval.," ")));
					run;	
				%end;
				proc sql;
					select min(&var_name.) into :min&i. from in.dataworking;
					select max(&var_name.) into :max&i. from in.dataworking;
					select range(&var_name.)/%eval(&no_bins.) into :step&i. from in.dataworking;
					quit;
				%put &&min&i. &&step&i. &&max&i.;
		
				data temp;	
					length bin_range $30.;
					set in.dataworking(keep=&var_name. primary_key_1644);
					%do j = 1 %to %eval(&no_bins.);
						%if "&j." = "1" %then %do;
							if &var_name. >= %sysevalf(&&min&i..+%sysevalf(&&step&i..*%eval(&j.-1))) and
								&var_name. <= %sysevalf(&&min&i..+%sysevalf(&&step&i..*&j.)) then do;
								grp_var = %eval(&j.);
								bin_range = "%sysevalf(&&min&i..+%sysevalf(&&step&i..*%eval(&j.-1))) - %sysevalf(&&min&i..+%sysevalf(&&step&i..*&j.))";
							end;
						%end;
						%else %if "&j." ^= "1" and "&j." ^= "%eval(&no_bins.)" %then %do;
							if &var_name. > %sysevalf(&&min&i..+%sysevalf(&&step&i..*%eval(&j.-1))) and
								&var_name. <= %sysevalf(&&min&i..+%sysevalf(&&step&i..*&j.)) then do;
								grp_var = %eval(&j.);
								bin_range = "%sysevalf(&&min&i..+%sysevalf(&&step&i..*%eval(&j.-1))) - %sysevalf(&&min&i..+%sysevalf(&&step&i..*&j.))";
							end;
						%end;
						%else %if "&j." = "%eval(&no_bins.)" %then %do;
							if &var_name. > %sysevalf(&&min&i..+%sysevalf(&&step&i..*%eval(&j.-1))) and
								&var_name. <= %sysevalf(&&max&i..) then do;
								grp_var = %eval(&j.);
								bin_range = "%sysevalf(&&min&i..+%sysevalf(&&step&i..*%eval(&j.-1))) - %sysevalf(&&min&i..+%sysevalf(&&step&i..*&j.))";
							end;
						%end;
					%end;
					run;

				proc sort data = temp;
					by grp_var bin_range;
					run;
			%end;

			/* getting the num_obs for subset */
			%let dset=temp;
				%let dsid = %sysfunc(open(&dset));
				%let nobs_i =%sysfunc(attrn(&dsid,NOBS));
				%let rc = %sysfunc(close(&dsid));
			%put &nobs_i;

			ods output summary = summary&i.;
			proc means data=temp &prop_type. missing maxdec=3;
				var &var_name.;
				by grp_var bin_range;
				output out = prop;
				run;

			%if "&flag_freq." = "true" and %index("&freq_type.", unique) > 0  %then %do;
				ods output nlevels = nlevels&i.(keep=grp_var bin_range nlevels rename=(nlevels=count_distinct));
				proc freq data = temp nlevels;
					tables &var_name.;
					by grp_var bin_range;
					run;
				
				proc sql;
					select sum(count_distinct) into :sum_distinct  from nlevels&i.;
					quit;
				%put &sum_distinct;

				data nlevels&i.;
					set nlevels&i.;
					percent_distinct = (count_distinct/%eval(&sum_distinct.))*100;
					retain cumm_distinct cumm_perc_distinct 0;
					cumm_distinct = cumm_distinct+count_distinct;
					cumm_perc_distinct = cumm_perc_distinct+percent_distinct;
					run;

				proc sort data = nlevels&i.;
					by grp_var;
					run;
			%end;

			data &var_name.;
				set summary&i.; 
				%if "&flag_freq." = "true" and %index("&freq_type.", total) > 0 %then %do;
					percent_obs = (%substr(&var_name., 1, 28)_N/%eval(&nobs_i.))*100;
					retain cumm_obs cumm_perc_obs 0;
					cumm_obs = cumm_obs+%substr(&var_name., 1, 28)_N;
					cumm_perc_obs = cumm_perc_obs+percent_obs;
				%end;
				rename %if "&flag_freq." = "true" %then %do; %substr(&var_name., 1, 28)_N = NOBS %end;
					%if %index(&prop_type.,mean) >0 %then %do;	%substr(&var_name., 1, 25)_Mean = Mean %end;
					%if %index(&prop_type.,median) >0 %then %do; %substr(&var_name., 1, 23)_Median = Median %end;
					%if %index(&prop_type.,stddev) >0 %then %do; %substr(&var_name., 1, 23)_stddev = StdDev %end;
					%if %index(&prop_type.,range) >0 %then %do; %substr(&var_name., 1, 24)_range = Range %end;;
				run;

			%if "&flag_freq." = "true" and %index("&freq_type.", unique) > 0  %then %do;
				data &var_name.;
					merge &var_name.(in=a) nlevels&i.(in=b);
					by grp_var;
					where grp_var ^= .;
					if a;
					%if %index("&freq_type.", total) = 0 %then %do;
						drop NOBS;
					%end;
					run;
			%end;
/*================================================================*/
			/*	To change column names*/
			data &var_name.(rename=(bin_range=Panel_Level count_distinct=Unique_Count 
            percent_distinct=Unique_Percent cumm_distinct=Cumulative_distinct cumm_perc_distinct=Cumulative_percent_distinct 
			NOBS=Total_Frequency percent_obs=Total_Frequency_Percent cumm_obs=Cumulative_Frequency 
            cumm_perc_obs=Cumulative_Percent StdDev=Standard_Deviation));
			set &var_name.(drop=grp_var);
			run;
/*		==========================================================*/

			
			%let test = worked;
			%put &test.;


			proc export data = &var_name.
				outfile = "&output_path./continuous/&var_name..csv"
				dbms = CSV replace;
				run;
			%let i = %eval(&i.+1);
		%end;
	%end;
%end;

%if "&cat_vars." ^= "" %then %do;
	
	ods output OneWayFreqs = Freq;
	proc freq data = in.dataworking(keep=&cat_vars.);
		tables &cat_vars.;
		run;

	%do i = 1 %to %sysfunc(countw(&cat_vars.));
		%let this_var =%scan(&cat_vars,&i);

		data &this_var.;
			retain &this_var.;
			set freq(keep=&this_var. Frequency Percent CumFrequency CumPercent);
			if not(missing(&this_var.));
			rename &this_var.=grp_var Frequency=NOBS Percent=percent_obs CumFrequency=cumm_obs CumPercent=cumm_perc_obs;
			run;
		
				/*	To change column names*/
			data &this_var.(rename=(grp_var=Panel_Level count_distinct=Unique_Count percent_distinct=Unique_Percent 
            cumm_distinct=Cumulative_distinct cumm_perc_distinct=Cumulative_percent_distinct NOBS=Total_Frequency 
            percent_obs=Total_Frequency_Percent 
			cumm_obs=Cumulative_Frequency cumm_perc_obs=Cumulative_Percent StdDev=Standard_Deviation));
			set &this_var.;
			run;

			%let test = worked;
			%put &test.;

/**/
/*			%if "&flag_freq." = "true" and %index("&freq_type.", unique) > 0 %then %do;*/
/*			*/
/*			data &var_name.;*/
/*			set &var_name.(drop=variable);*/
/*			run;*/
/*			%end;*/

		proc export data = &this_var.
			outfile = "&output_path./categorical/&this_var..csv"
			dbms = CSV replace;
			run;
	%end;
%end;
%MEND prop_freq;
%prop_freq;


/* Flex uses this file to test if the code has finished running */
data _null_;
	v1= "EDA - FREQ_PROP_CODE_COMPLETED";
	file "&output_path/PROP_FREQ_COMPLETED.txt";
	put v1;
run;


/*ENDSAS;*/

%macro changesmade;
/*1.removed (drop=variable) #Thursday, July 10, 2014 12:18:32 PM*/
/*2.above change caused some error,so had to reposition the code line "(drop=variable)" */
/*3.included a data step just before export and also placed an IF condition before removing the column "variable" #Thursday, July 10, 2014 7:40:17 PM */
%mend;
