/*Sample Parameters*/
/*%let c_path_in				= /product-development/murx///projects/Nida_Boxes-27-Aug-2014-12-16-57/1;*/
/*%let c_path_out				= /product-development/murx///projects/Nida_Boxes-27-Aug-2014-12-16-57/1/dynamicFilter;*/
/*%let c_var_in_categorical	= Store_Format geography;*/
/*%let c_var_in_continuous	= ACV sales;*/
/*%let c_var_in_date			= date_11 Date;*/
/*%let n_varid_in_categorical	= 9 26;*/
/*%let n_varid_in_continuous	= 1 33;*/
/*%let n_varid_in_date		= 18 3;*/
/**********************************************************************************************************************/

options mprint mlogic symbolgen mfile;
/*Libraries*/
libname in "&c_path_in.";
libname out "&c_path_out.";

%macro boxes;
	/*parameters*/
	%let catVars_list			= &c_var_in_categorical.;
	%let catVars_ids 			= &n_varid_in_categorical.;
	%let contVars_list			= &c_var_in_continuous.;
	%let contVars_ids 			= &n_varid_in_continuous.;
	%let dateVars_list 			= &c_var_in_date.;
	%let dateVars_ids 			= &n_varid_in_date.;
	%let dataset_name			= dataworking;
	%let c_file_csv_boxes		= filterData;
	%let c_file_txt_completed	= completed;
	%let c_file_log				= FilterData_Log;
	%let c_file_delete		    = &c_path_out./&c_file_txt_completed..txt#
		&c_path_out./&c_file_log..txt#
		&c_path_out./&c_file_csv_boxes..csv;

	/*Delete Files*/
	%do tempi = 1 %to %sysfunc(countw(%str(&c_file_delete.), %str(#)));
		%let c_file_delete_now = %sysfunc(compress(%scan(%str(&c_file_delete.), &tempi., %str(#))));
		filename myfile "&c_file_delete_now.";

		data _null_;
			rc = fdelete('myfile');
		run;

	%end;

	/*Log File*/
	proc printto log="&c_path_out./&c_file_log..log" new;
	run;

	/*For continuous variables*/
	%if "&contVars_list." ^= "" %then
		%do;
			/*		get min & max from proc tabulate*/
			proc tabulate data = in.&dataset_name out = tabulate missing;
				var &contVars_list.;
				table (&contVars_list.), min max;
			run;

			proc contents data=tabulate out=cont(keep=name);
			run;

			proc sql;
				select NAME into: vars separated by " " from cont
					where name like 'Min%';
			quit;

			%put &vars.;

			/*transpose to get the table in proper format*/
			proc transpose data = tabulate(drop=_page_ _table_ )
				out = table_cont(rename=(_name_=variable col1=value));
			run;

			data table_cont;
				length variable $100.;
				set table_cont;

				%do i = 1 %to %sysfunc(countw(&contVars_list.));
					%if %length(%scan(&contVars_list.,&i.))>28 %then
						%do;
							%do i=1 %to %sysfunc(countw(&vars.," "));
								%let j=%substr(%scan(&vars.,&i.," "),4,1);

								%if "&j."="" %then
									%do;
										if variable="Min" then
											variable=cat("%scan(&contVars_list.,1," ")","_min");

										if variable="Max" then
											variable=cat("%scan(&contVars_list.,1," ")","_max");
									%end;
								%else
									%do;
										if variable="Min&j." then
											variable=cat("%scan(&contVars_list.,&j.," ")","_min");

										if variable="Max&j." then
											variable=cat("%scan(&contVars_list.,&j.," ")","_max");
									%end;
							%end;
						%end;
				%end;
			run;

			/*condition the variable names*/
			data table_cont;
				set table_cont;
				variable=substr(variable, 1, (length(variable)-4));
			run;

			proc sort data = table_cont;
				by variable value;
			run;

			/*concatenate the min & max values for each variable*/
			data val_cn(drop=value);
				length values $1200.;
				set table_cont;
				retain values;
				by variable;

				if first.variable then
					values = "";

				if values = " " then
					values = strip(value);
				else values = strip(values)!!"!!"!!strip(value);

				if last.variable then
					output;
			run;

			data val_cn;
				set val_cn;

				%do i = 1 %to %sysfunc(countw(&contVars_list.));
					if strip(lowcase(variable)) = lowcase("%scan(&contVars_list,&i)") then
						ID = %scan(&contVars_ids,&i);
				%end;
			run;

		%end;

	/*for date variables*/
	%if "&dateVars_list" ^= "" %then
		%do;
			/*get min & max from proc tabulate*/
			proc tabulate data = in.&dataset_name out = tabulate missing;
				var &dateVars_list.;
				table (&dateVars_list.), min max;
			run;

			proc contents data=tabulate out=cont1(keep=name);
			run;

			proc sql;
				select name into: vars1 separated by " " from cont1
					where name like 'Min%';
			quit;

			proc transpose data = tabulate(drop=_page_ _table_) out = table_dt(rename=(_name_=variable col1=value));
			run;

			data table_dt;
				length variable $100.;
				set table_dt;

				%do i = 1 %to %sysfunc(countw(&dateVars_list.));
					%if %length(%scan(&datetVars_list.,&i.))>28 %then
						%do;
							%do i=1 %to %sysfunc(countw(&vars1.," "));
								%let j=%substr(%scan(&vars1.,&i.," "),4,1);

								%if "&j."="" %then
									%do;
										if variable="Min" then
											variable=cat("%scan(&dateVars_list.,1," ")","_min");

										if variable="Max" then
											variable=cat("%scan(&dateVars_list.,1," ")","_max");
									%end;
								%else
									%do;
										if variable="Min&j." then
											variable=cat("%scan(&dateVars_list.,&j.," ")","_min");

										if variable="Max&j." then
											variable=cat("%scan(&dateVars_list.,&j.," ")","_max");
									%end;
							%end;
						%end;
				%end;
			run;

			/*condition the variable names*/
			data table_dt;
				set table_dt;
				variable=substr(variable, 1, (length(variable)-4));
			run;

			proc sort data = table_dt;
				by variable value;
			run;

			/*concatenate the min & max values for each variable*/
			data val_dt(drop=value value1);
				length values $1200.;
				set table_dt;
				retain values;
				by variable;
				value1 = put(value,date9.);

				if first.variable then
					values = "";

				if values = " " then
					values = strip(value1);
				else values = strip(values)!!"!!"!!strip(value1);

				if last.variable then
					output;
			run;

			data val_dt;
				set val_dt;

				%do i = 1 %to %sysfunc(countw(&dateVars_list.));
					if strip(lowcase(variable)) = lowcase("%scan(&dateVars_list,&i)") then
						ID = %scan(&dateVars_ids,&i);
				%end;
			run;

		%end;

	/*for categorical variables*/
	%if "&catVars_list." ^= "" %then
		%do;
			%let cat_vars=;
			%let i = 1;

			%do %until (not %length(%scan(&catVars_list,&i)));
				%let cat_vars=&cat_vars. %substr(%scan(&catVars_list,&i),1,30);
				%let i = %eval(&i.+1);
			%end;

			/*get one-way freqs for distinct values*/
			ods output OneWayFreqs = freqs;

			proc freq data = in.&dataset_name.;
				table &catVars_list.;
			run;

			/*condition the one-way freqs two obtain desired format*/
			data freqs(keep=variable level);
				length level $32.;
				length variable $32.;
				set freqs;
				variable = tranwrd(strip(table), "Table ", "");
				%let i = 1;

				%do %until (not %length(%scan(&cat_vars,&i)));
					if F_%scan(&cat_vars,&i) ^= " " then
						level = strip(F_%scan(&cat_vars,&i));
					%let i = %eval(&i.+1);
				%end;
			run;

			proc sort data = freqs;
				by variable;
			run;

			/*concatenate the values per variable*/
			data val_ct(drop=level);
				length values $1200.;
				length variable $32.;
				set freqs;
				retain values;
				by variable;

				if first.variable then
					values = "";

				if values = " " then
					values = strip(level);
				else values = strip(values)!!"!!"!!strip(level);

				if last.variable then
					output;
			run;

			data val_ct;
				set val_ct;

				%do i = 1 %to %sysfunc(countw(&catVars_list.));
					if strip(lowcase(variable)) = lowcase("%scan(&catVars_list,&i)") then
						ID = %scan(&catVars_ids,&i);
				%end;
			run;

		%end;

	/*append the values for continuous and categorical*/
	data outdata;
		retain variable ID values;
		length variable $32.;
		set

			%if "&contVars_list." ^= "" %then
				%do;
					val_cn
				%end;

			%if "&catVars_list." ^= "" %then
				%do;
					val_ct
				%end;

			%if "&dateVars_list." ^= "" %then
				%do;
					val_dt
				%end;;
	run;

	proc export data = outdata
		outfile = "&c_path_out./&c_file_csv_boxes..csv"
		dbms = csv replace;
	run;

%mend boxes;

%boxes;

/* Completed TXT */
data _null_;
	v1= "EDA - FILTER_DATA_CREATION_COMPLETED";
	file "&c_path_out./completed.txt";
	put v1;
run;