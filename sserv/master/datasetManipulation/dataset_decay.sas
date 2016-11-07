/*------------------------------------------------------------------------------
info : sample parameters
------------------------------------------------------------------------------*/
/*%let input_path                       = /product-development/vasanth.mm/;*/
/*%let output_path                      = /product-development/vasanth.mm/temp/;*/
/*%let decay_var                        = acv sales;*/
/*%let date_var                         = date_missing;*/
/*%let id_var                           = ;*/
/*%let decay_value                      = 2.34 1.23;*/
/*%let namecsv                          = decayed;*/
/*%let calculate_decay_rate             = true;*/
/*%let create_dataset                   = false;*/

%let c_data_in                        = dataworking;
%let c_data_out_decay_rate            = decay_value;
%let c_data_new                       = &namecsv.;
%let c_path_in                        = &input_path.;
%let c_path_out                       = &output_path.;
%let n_val_in_decay                   = &decay_value.;
%let c_var_in_date                    = &date_var.;
%let c_var_in_decay                   = ;
%let c_var_in_id                      = &id_var.;
%let l_calc_decay_rate                = &calculate_decay_rate.;
%let l_create_dataset                 = &create_dataset.;
/*----------------------------------------------------------------------------*/

proc printto log="&c_path_out./mta.log" new;
/*proc printto;*/
run;
quit;

options mlogic mprint symbolgen;
libname in "&c_path_in.";
libname out "&c_path_out.";

proc datasets lib=work kill nolist;
run;
quit;

%macro dp_dataset_decay;

	%if &l_calc_decay_rate. = true %then
		%let c_var_in_decay               = &decay_var1.;
	%if &l_create_dataset. = true %then
		%let c_var_in_decay               = &decay_var2.;

	%if &l_calc_decay_rate. = true %then
		%do;
			%goto prepare_the_dataset;
			%wf_a_prepare_the_dataset:

			%goto calc_decay_rate;
			%wf_a_calc_decay_rate:

			%goto export_decay_rate;
			%wf_a_export_decay_rate:

			%goto completed_txt;
			%wf_a_completed_txt:

			%goto the_end;
		%end;

	%if &l_create_dataset. = true %then
		%do;
			%goto create_dataset;
			%wf_a_create_dataset:

			%goto completed_txt;
			%wf_a_completed_txt:

			%goto the_end;
		%end;

	%prepare_the_dataset:

	proc sort data=in.&c_data_in.(keep=&c_var_in_date. &c_var_in_decay. &c_var_in_id.) out=murx_temp;
		by &c_var_in_date.;
	run;
	quit;

	%let c_for_drop                    = &c_var_in_date.;
	%let c_for_rename                  = murx_numbers = &c_var_in_date.;
	%do i = 1 %to %sysfunc(countw(&c_var_in_decay.));
		%let c_for_drop                = &c_for_drop. murx_csum_&i.;
		%let c_for_rename              = &c_for_rename. murx_log_&i.=%scan(&c_var_in_decay., &i.);
	%end;

	data murx_temp(drop=&c_var_in_decay. &c_for_drop. rename=(&c_for_rename.));
		set murx_temp;
		where &c_var_in_date. ^= .;
		murx_numbers + 1;
		%do i = 1 %to %sysfunc(countw(&c_var_in_decay.));
			murx_csum_&i. + %scan(&c_var_in_decay., &i.);
			murx_log_&i. = log(murx_csum_&i.);
		%end;
	run;

	%goto wf_a_prepare_the_dataset;

	%calc_decay_rate:

	%do i = 1 %to %sysfunc(countw(&c_var_in_decay.));
		%let c_var_in_decay_now        = %scan(&c_var_in_decay.,&i.);

		ods output ParameterEstimates=murx_parest_&i.(keep=variable estimate where=(variable="&c_var_in_decay_now.") rename=(estimate=decay_value));
		proc reg data=murx_temp;
			model &c_var_in_date. = &c_var_in_decay_now.;
		run;
		quit;
	%end;

	data murx_&c_data_out_decay_rate.;
		length variable $32;
		set %do i = 1 %to %sysfunc(countw(&c_var_in_decay.));
				murx_parest_&i.
			%end;
		;
	run;

	%goto wf_a_calc_decay_rate;

	%create_dataset:

	%let c_for_select                  = ;
	%do i = 1 %to %sysfunc(countw(&c_var_in_decay.));
		%let c_for_select              = &c_for_select. count(%scan(&c_var_in_decay., &i.)) * %scan(&n_val_in_decay., &i., %str( )) as %scan(&c_var_in_decay., &i.),;
	%end;

	proc sql noprint;
		create table out.&c_data_new. as
			select &c_for_select. &c_var_in_id.
				from in.&c_data_in.
					group by &c_var_in_id.;
	run;
	quit;

	%goto wf_a_create_dataset;

	%completed_txt:

	data _null_;
		n1 = "dataset_decay";
		file "&output_path./completed.txt";
		put n1;
	run;

	%goto wf_a_completed_txt;

	%export_decay_rate:

	proc export data=murx_&c_data_out_decay_rate. outfile="&c_path_out./&c_data_out_decay_rate..csv" dbms=csv replace;
	run;
	quit;

	%goto wf_a_export_decay_rate;

	%the_end:
%mend dp_dataset_decay;

%dp_dataset_decay;
