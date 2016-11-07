/*Successfully converted to SAS Server Format*/
*processbody;

options mprint mlogic symbolgen;

proc printto log="&output_path/append.log" new;
/*proc printto;*/
run;
quit;

%macro a;
	%let c_data_verify            = muRx_verify;
	%let c_data_temp              = muRx_temp;
	%let c_file_csv_verify        = Verify.csv;
	%let c_file_txt_completed     = APPEND_VERIFY_COMPLETED.txt;
	%let c_lib_temp               = temp;
	%let c_path_in                = &input_path.;
	%let c_path_out               = &output_path.;
	%let c_var_name               = NAME;  
	%let c_var_selected           = Selected;
	%let c_var_temp               = muRx_temp;
	%let c_var_type               = Type;
	%let c_var_typecast           = Typecast;

	proc datasets lib=work kill nolist;
	run;
	quit;

	/* will contain the rhs for finding the mean of all the type variables */
	%let c_sep                    = ;
	%let c_temp                   = mean(;
	%do n_tempi = 1 %to %sysfunc(countw(&c_path_in., ||));
		%let c_path_in_now = %scan(&c_path_in, &n_tempi., ||);

		libname &c_lib_temp. "&c_path_in_now.";

		proc contents data=&c_lib_temp..dataworking out=&c_data_temp.(keep=name type rename=(name=&c_var_name. type=&c_var_type.&n_tempi.));
		run;
		quit;

		%if &n_tempi.= 1 %then
			%do;
				data &c_data_verify.;
					set &c_data_temp.;
				run;
			%end;
		%else
			%do;
				data &c_data_verify.;
					merge &c_data_verify. &c_data_temp.;
					by &c_var_name.;
				run;
			%end;

		proc sort data=&c_data_verify. out=&c_data_verify.;
			by &c_var_name.;
		run;
		quit;

		%let c_temp               = &c_temp.&c_sep.type&n_tempi.;
		%let c_sep                = ,;
	%end;
	%let c_temp                   = &c_temp.);

	%let c_var_all_selected       = &common_vars. &exclusive_vars.;
	%let c_var_all_selected       = %sysfunc(tranwrd(&c_var_all_selected., ||, %str( )));

	data &c_data_temp.;
		length &c_var_name. $32. &c_var_selected. $5.;
		%do n_tempi = 1 %to %sysfunc(countw(&c_var_all_selected., %str( )));
			&c_var_name. = "%scan(&c_var_all_selected., &n_tempi., %str( ))";
			&c_var_selected. = "TRUE";
			output;
		%end;
		%do n_tempi = 1 %to %sysfunc(countw(&unselected_variables., %str( )));
			&c_var_name. = "%scan(&unselected_variables., &n_tempi., %str( ))";
			&c_var_selected. = "FALSE";
			output;
		%end;
	run;

	proc sort data=&c_data_temp. out=&c_data_temp. nodupkey;
		by &c_var_name.;
	run;
	quit;

	data &c_data_verify.(keep=&c_var_name. &c_var_type. &c_var_typecast. &c_var_selected.);
		length &c_var_name. $32. &c_var_type. $9. &c_var_typecast. $5. &c_var_selected. $5.;
		merge &c_data_verify.(in=muRx_d1) &c_data_temp.(in=muRx_d2);
		by &c_var_name.;
		if muRx_d2;
		&c_var_temp. = &c_temp.;
		if &c_var_temp. = 1 then
			&c_var_type. = "Numeric";
		else
			&c_var_type. = "Character";
		if &c_var_temp. = 1 or &c_var_temp. = 2 then
			&c_var_typecast. = "FALSE";
		else
			&c_var_typecast. = "TRUE";
	run;

	proc sort data=&c_data_verify. out=&c_data_verify.;
		by descending &c_var_selected. &c_var_name.;
	run;
	quit;

	proc export data=&c_data_verify. outfile = "&c_path_out./&c_file_csv_verify." dbms=csv replace;
	run;
	quit;

	data _null_;
		v1= "&c_file_txt_completed.";
		file "&c_path_out./&c_file_txt_completed.";
		put v1;
	run;

	%abort;
%mend a;

%macro format_variables;
	%do i= 1 %to %sysfunc(countw(&datasets.,"||"));
  		libname in&i. "%scan(&input_path,&i,||)";
		proc contents data=in&i..%scan(&datasets.,&i.,"||") (keep=&common_vars.)  out=contents&i.;
			run;

		proc sort data=contents&i.(keep=name type);
			by name;
			run;
		data contents&i.;
			set contents&i.;
			rename type=type&i.;
			run;

		data all;
			merge %if %sysfunc(exist(all)) %then %do;
						all (in=a)
					%end; contents&i. (in=b);
			by name;
			run;
	%end;

	%let format_vars=;
	proc sql;
		select name into:format_vars separated by " " from all
		where 
		%do i= 2 %to %sysfunc(countw(&datasets.,"||"))-1;
			type1 <> type&i. or
		%end;
			type1 <> type%sysfunc(countw(&datasets.,"||"));
	quit;

	%do k=1 %to %sysfunc(countw(&datasets.,"||"));
		data in&k._%scan(&datasets.,&k.,"||");
			set in&k..%scan(&datasets.,&k.,"||");
			%if "&format_vars." ^="" %then
				%do f=1 %to %sysfunc(countw(&format_vars.," "));
					new&f.=put(%scan(&format_vars.,&f.," "),$10.);
					drop %scan(&format_vars.,&f.," ");
					rename new&f.=%scan(&format_vars.,&f.," ");
				%end;
		run;
	%end;

	%global formatted_vars;
	%let formatted_vars=&format_vars.;
%mend format_variables;

%macro append_datasets;
	proc delete data=out.&new_dataset.;
	run;
	quit;

	%do i= 1 %to %sysfunc(countw(&datasets.,"||"));
  		libname in&i. "%scan(&input_path,&i,||)";

		%if &extra_vars_flag. = false %then %do;
			proc append base=out.&new_dataset. 	data=in&i._%scan(&datasets.,&i.,"||") force;
			quit;
		%end; 
		%else %do;
			data out.&new_dataset.;
				set %if %sysfunc(exist(out.&new_dataset.)) %then %do;
						out.&new_dataset.
					%end; 
					in&i._%scan(&datasets.,&i.,"||");				
			run;
		%end;
	%end;

	data out.&new_dataset.;
		set out.&new_dataset.(keep=&common_vars. &excl_vars.);
	run;

	proc export data = out.&new_dataset.
		outfile = "&output_path./&new_Dataset..csv"
		dbms = csv replace;
		run;

	/* flex uses this file to test if the code has finished running */
	data _null_;
		v1= "APPEND_DATASETS_COMPLETED";
		file "&output_path/APPEND_DATASETS_COMPLETED.txt";
		put v1;
	run;

%mend append_datasets;

%macro workflow;
	%let datasets = %sysfunc(compress(&datasets.));
	%if &verify. = true %then
		%do;
			%a;
		%end;
	%else
		%do;
			libname out "&output_path.";

			data _null_;
				call symput("excl_vars", tranwrd("&exclusive_vars","||"," "));
			run;

			%format_variables;
			%append_datasets;
		%end;
%mend workflow;
%workflow;
