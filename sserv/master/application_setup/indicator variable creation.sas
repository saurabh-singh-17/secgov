/*/* Version 2.1 - Jan 6, 2011 */*/
*processbody;
options symbolgen Mprint mlogic mfile;
%let completedTXTPath = &output_path./indicator_var.txt;

/*proc printto log="&output_path/indicator_var.log";*/
/*run;*/
/*quit;*/
/*proc printto print="&output_path/indicator_var.out";*/
libname in "&input_path.";
libname group "&group_path.";
%let formdate;

%macro indicator_var;
	/*################################################################################################################*/
	/*	the following condition is checked for cases where by groupdata does not exist	*/
	/*	in case bygroupdata does not exist dataworking will be used directly	*/
	%if %sysfunc(exist(group.bygroupdata)) %then
		%do;
			%let dataset_name=group.bygroupdata;
		%end;
	%else
		%do;
			%let dataset_name = in.dataworking;
		%end;

	%if "&var_type." = "time_var" %then
		%do;
			%let new_var_name= &scenario_variable._&var_name.;

			data temp;
				set &dataset_name.(keep = primary_key_1644 &var_name.);
			run;

			proc sort data = temp out= temp;
				by &var_name.;
			run;

			quit;

			proc contents data=temp out=temp_contents;
			run;

			quit;

			proc sql noprint;
				select FORMAT into: dateformat from temp_contents where NAME = "&var_name.";
			quit;

			%put &dateformat.;

			data temp;
				set temp;

				%if &dateformat. = "DATETIME" %then
					%do;
						format tempdate datetime16.;
					%end;
				%else
					%do;
						format tempdate date9.;
					%end;

				tempdate = &var_name.;
			run;

			proc sql noprint;
				select distinct(tempdate) into : unique_values separated by ' ' from temp;
			run;

			quit;

			%put &unique_values.;

			%if &dateformat. = "DATETIME" %then
				%do;

					data temp;
						set temp;

						%do tempi = 1 %to %sysfunc(countw(&unique_values.," "));
							if &var_name. = "%scan(&unique_values.,&tempi.,' ')"dt then
								&new_var_name. = &tempi.;
						%end;
					run;

				%end;
			%else
				%do;

					data temp;
						set temp;

						%do tempi = 1 %to %sysfunc(countw(&unique_values.," "));
							if &var_name. = "%scan(&unique_values.,&tempi.,' ')"d then
								&new_var_name. = &tempi.;
						%end;
					run;

				%end;

			proc sort data = temp out= temp;
				by primary_key_1644;
			run;

			quit;

			proc sort data = &dataset_name. out= &dataset_name.;
				by primary_key_1644;
			run;

			quit;

			data &dataset_name.;
				merge &dataset_name. temp;
				by primary_key_1644;
			run;

			%if "&flag_forecast." = "true" %then
				%do;

					data &dataset_name.;
						set &dataset_name.;

						if  "&forecastStart_date." <= &new_var_name. <= "&forecastEnd_date." then
							&scenario_variable. = 2;
						else if   "&s_date." <= &new_var_name. <= "&e_date." then
							&scenario_variable. = 1;
						else if "&validateStart_date." <= &new_var_name. <= "&validateEnd_date." then
							&scenario_variable. = 0;
						else &scenario_variable. = .;
					run;

				%end;
			%else
				%do;

					data &dataset_name.;
						set &dataset_name.;

						if  "&s_date." <= &new_var_name. <= "&e_date." then
							&scenario_variable. = 1;
						else if "&validateStart_date." <= &new_var_name.<= "&validateEnd_date." then
							&scenario_variable. = 0;
						else &scenario_variable. = .;
					run;

				%end;

			/*	%if %length(&s_date.) < 13 %then %do;*/
			/*	%macro new;*/
			/*	proc contents data=&dataset_name out=cont;*/
			/*	run;*/
			/*	data cont;*/
			/*		set cont;*/
			/*		where name="&var_name.";*/
			/*		run;*/
			/*	data cont;*/
			/*		set cont;*/
			/*		form=cat(format,formatl);*/
			/*		run;*/
			/*	proc sql;*/
			/*		select form into:formdate separated by "," from cont;*/
			/*		quit;*/
			/*	data _null_;*/
			/*		call symput("formdate",compress("&formdate."));*/
			/*		run;*/
			/*	%if "&formdate." ne "DATE8" %then %do;*/
			/*	data tempdata;*/
			/*		format start DATE9.;*/
			/*		format end DATE9.;*/
			/*		format ValidateStart DATE9.;*/
			/*		format ValidateEnd DATE9.;*/
			/*		format ForecastStart DATE9.;*/
			/*		format ForecastEnd DATE9.;*/
			/*		start=input("&s_date",&formdate..);*/
			/*		end=input("&e_date",&formdate..);*/
			/*		ValidateStart=input("&validateStart_date",&formdate..);*/
			/*		ValidateEnd=input("&validateEnd_date",&formdate..);*/
			/*		ForecastStart=input("&forecastStart_date",&formdate..);*/
			/*		ForecastEnd=input("&forecastEnd_date",&formdate..);*/
			/*		run;*/
			/*	proc sql;*/
			/*		select start into:s_date separated by "," from tempdata;*/
			/*		quit;*/
			/*	proc sql;*/
			/*		select end into:e_date separated by "," from tempdata;*/
			/*		quit;*/
			/*	proc sql;*/
			/*		select ValidateStart into:validateStart_date separated by "," from tempdata;*/
			/*		quit;*/
			/*	proc sql;*/
			/*		select ValidateEnd into:validateEnd_date separated by "," from tempdata;*/
			/*		quit;*/
			/*	proc sql;*/
			/*		select ForecastStart into:forecastStart_date separated by "," from tempdata;*/
			/*		quit;*/
			/*	proc sql;*/
			/*		select ForecastEnd into:forecastEnd_date separated by "," from tempdata;*/
			/*		quit;*/
			/**/
			/*	data &dataset_name.;*/
			/*		format datexx DATE9.;*/
			/*		set &dataset_name.;*/
			/*		datexx=&var_name.;*/
			/*		run;*/
			/**/
			/**/
			/*	%end;*/
			/*	%else %do;*/
			/*	data &dataset_name.;*/
			/*		set &dataset_name.;*/
			/*		datexx=&var_name.;*/
			/*		run;*/
			/*	%end;*/
			/*	%mend;*/
			/*	%new;*/
			/*	%if "&flag_forecast." = "true" %then %do;*/
			/*  	data &dataset_name.;*/
			/*		set &dataset_name.;*/
			/*			if  "&forecastStart_date."d <= &var_name. <= "&forecastEnd_date."d then &scenario_variable. = 2;*/
			/*			else if   "&s_date."d <= &var_name. <= "&e_date."d then &scenario_variable. = 1;*/
			/*			else if "&validateStart_date."d <= &var_name. <= "&validateEnd_date."d then &scenario_variable. = 0;*/
			/*			else &scenario_variable. = . ;*/
			/*		run;*/
			/*		%end;*/
			/*		%else %do;*/
			/*	data &dataset_name.;*/
			/*		set &dataset_name.;*/
			/*			if  "&s_date."d <= &var_name. < "&e_date."d then &scenario_variable. = 1;*/
			/*			else if "&validateStart_date."d <= &var_name. <= "&validateEnd_date."d then &scenario_variable. = 0;*/
			/*			else &scenario_variable. = . ;*/
			/*		run;*/
			/*		%end;*/
			/*	 %end;*/
			/*	 %else %do;*/
			/*	%if "&flag_forecast." = "true" %then %do;*/
			/*  data &dataset_name.;*/
			/*		set &dataset_name.;*/
			/*			if  "&forecastStart_date."d <= &var_name. <= "&forecastEnd_date."d then &scenario_variable. = 2;*/
			/*			else if   "&s_date."d <= &var_name. <= "&e_date."d then &scenario_variable. = 1;*/
			/*			else if "&validateStart_date."d <= &var_name. <= "&validateEnd_date."d then &scenario_variable. = 0;*/
			/*			else &scenario_variable. = . ;*/
			/*		run;*/
			/*		%end;*/
			/*		%else %do;*/
			/*	data &dataset_name.;*/
			/*		set &dataset_name.;*/
			/*			if  "&s_date."d <= &var_name. < "&e_date."d then &scenario_variable. = 1;*/
			/*			else if "&validateStart_date."d <= &var_name. <= "&validateEnd_date."d then &scenario_variable. = 0;*/
			/*			else &scenario_variable. = . ;*/
			/*		run;*/
			/*		%end;*/
			/*	 %end;*/
		%end;

	/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
	%if "&var_type." = "per_var" %then
		%do;
			%if "&per_method" = "seq" %then
				%do;
					%let no_of_obs = %eval((&end_row. - &start_row.)+1);

					%if "&flag_forecast" = "true" %then
						%do;

							data _null_;
								call symputx("tot_rows" , &no_of_obs.);
								call symputx("s_row" , round((&no_of_obs. * &percent.)));
							run;

							%put &s_row.;

							data &dataset_name.;
								set &dataset_name.;

								if %eval(&forecaststart_row.)<= _n_ <= %eval(&forecastend_row.) then
									&scenario_variable. = 2;
								else if %eval(&start_row.) <= _n_ <= %eval(&start_row.+&s_row.)then &scenario_variable. = 1;
								else if %eval(&start_row.+&s_row.+1)<= _n_ <=%eval(&end_row.) then
									&scenario_variable. = 0;
								else &scenario_variable. = .;
							run;

						%end;
					%else
						%do;

							data _null_;
								set &dataset_name.;
								call symputx("tot_rows" , &no_of_obs.);
								call symputx("s_row" , round((&no_of_obs. * &percent.)));
								stop;
							run;

							%put &s_row.;

							data &dataset_name.;
								set &dataset_name.;

								if  %eval(&start_row.) <= _n_ <= %eval(&start_row.+&s_row.) then
									&scenario_variable. = 1;
								else if %eval(&start_row.+&s_row.+1)<= _n_ <=%eval(&end_row.) then
									&scenario_variable. = 0;
								else &scenario_variable. = .;
							run;

						%end;
				%end;

			%if "&per_method" = "random" %then
				%do;

					data subset_data;
						set &dataset_name.;

						if &start_row. <= _n_ <= &end_row. then
							output;
					run;

					%if "&strata." = "" %then
						%do;

							proc surveyselect data = subset_data 
								method=srs rate=&percent. seed = &seed.
								out=SampleControl(keep = primary_key_1644);
							run;

						%end;

					%if "&strata." ^= "" %then
						%do;

							proc sort data = subset_data;
								by &strata.;
							run;

							proc surveyselect data = subset_data 
								method=srs rate=&percent. seed = &seed.
								out=SampleControl(keep = primary_key_1644);
								strata &strata.;
							run;

						%end;

					data SampleControl;
						set SampleControl;
						&scenario_variable. = 1;
					run;

					proc sort data = SampleControl;
						by primary_key_1644;
					run;

					proc sort data = &dataset_name.;
						by primary_key_1644;
					run;

					data new;
						merge subset_data(in= a) SampleControl;
						by primary_key_1644;
						if a;
						if &scenario_variable. ^=1 then
							&scenario_variable. =0;
					run;

					data &dataset_name.;
						merge &dataset_name.(in = a) new;
						by primary_key_1644;
						if a;
					run;

				%end;
		%end;

	/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
	%if "&var_type." = "grp_var" %then
		%do;

			proc contents data = &dataset_name.(keep = &var_name.) out = contents(keep = name type);
			run;

			data _null_;
				set contents;
				call symputx("val_cnt" , countw("&grp_values" , "||"));
				call symputx("type",type);
			run;

			%put &val_cnt &type;

			data grp_values(drop = i);
				do i = 1 to &val_cnt.;
					%if "&type" = "1" %then
						%do;
							format &var_name. 8.;
						%end;
					%else %if "&type" = "2" %then
						%do;
							format &var_name. $50.;
						%end;

					&var_name. = scan("&grp_values",i,"||");
					output;
				end;
			run;

			proc sql;
				create table &dataset_name. as
					select *,
						case when &var_name. in (select distinct &var_name. from grp_values) then 1 else 0 end as &scenario_variable.
							from &dataset_name.;
			quit;

		%end;

	%if &scenario_variable. ^= %str() %then
		%do;
			%if "&dataset_name." = "group.bygroupdata" %then
				%do;

					data temp;
						set group.bygroupdata(keep = &scenario_variable. primary_key_1644);
					run;

					proc sql;
						create table in.dataworking as
							select *
								from in.dataworking a1 left join temp a2
									on a1.primary_key_1644 = a2.primary_key_1644;
					run;

					quit;

				%end;
		%end;
%mend indicator_var;

%indicator_var;

/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "indicator variable is created";
	file "&output_path./indicator_var.txt";
	put v1;
run;
;