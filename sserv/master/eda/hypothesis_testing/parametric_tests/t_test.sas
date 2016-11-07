*processbody;
options spool mlogic mprint symbolgen;

/*------------------------------------------------------------------------------
sample parameters
------------------------------------------------------------------------------*/
/*%let c_path_in             = /product-development/vasanth.mm;*/
/*%let c_path_out            = /product-development/vasanth.mm/temp;*/
/*%let grp_no                = 0;*/
/*%let grp_flag              = ;*/
/**/
/*%let b_cochran             = 0;*/
/*%let c_var_in_ttest        = acv black_hispanic sales total_selling_area;*/
/*%let c_var_in_class        = channel_1;*/
/*%let c_var_in_freq         = ;*/
/*%let c_var_in_weight       = ;*/
/**/
/*%let c_confidence_interval = UMPU;*/
/*%let c_type_ttest          = 2sample;*/
/*%let n_h0                  = 134e7 23 45 76;*/
/*%let n_alpha               = 0.05;*/
/*----------------------------------------------------------------------------*/

proc printto log="&c_path_out./ttests.log" new;
/*proc printto;*/
run;
quit;

%macro eda_tt;
	libname in "&c_path_in.";

	/*------------------------------------------------------------------------------
	parameter play
	------------------------------------------------------------------------------*/
	/* hardcoding */
	%let c_data_in                   = dataworking;
	%let c_st_class                  = ;
	%let c_st_freq                   = ;
	%let c_st_weight                 = ;
	%let c_data_temp                 = temp;
	%let c_data_variable_statistics  = variable_statistics;
	%let c_data_t_test_result        = t_test_result;
	%let c_data_equality_test_result = equality_test_result;
	%let c_csv_variable_statistics   = &c_data_variable_statistics.;
	%let c_csv_t_test_result         = &c_data_t_test_result.;
	%let c_csv_equality_test_result  = &c_data_equality_test_result.;
	%let c_txt_completed             = completed;
	%let c_txt_error                 = error;
	%let c_txt_warning               = warning;
	
	/* check and change */
	%if %str(&c_var_in_class.)  ^= %str()       %then %let c_st_class  = %str(class &c_var_in_class.;);
	%if %str(&c_var_in_freq.)   ^= %str()       %then %let c_st_freq   = %str(freq &c_var_in_freq.;);
	%if %str(&c_var_in_weight.) ^= %str()       %then %let c_st_weight = %str(weight &c_var_in_weight.;);

	%let c_file_delete = &c_path_out./&c_txt_completed..txt#
						 &c_path_out./&c_txt_error..txt#
						 &c_path_out./&c_txt_warning..txt;
	%do tempi = 1 %to %sysfunc(countw(%str(&c_var_in_ttest.), %str( )));

		%let c_var_in_ttest_now = %scan(%str(&c_var_in_ttest.), &tempi., %str( ));
		%let c_var_in_ttest_now = %sysfunc(tranwrd(%str(&c_var_in_ttest_now.), %str(*), %str(_murx_)));

		%let c_file_delete = &c_file_delete.#
						 	 &c_path_out./&c_var_in_ttest_now./&c_csv_variable_statistics..csv#
							 &c_path_out./&c_var_in_ttest_now./&c_csv_t_test_result..csv#
						 	 &c_path_out./&c_var_in_ttest_now./&c_csv_equality_test_result..csv;
	%end;
	/*----------------------------------------------------------------------------*/

	/*------------------------------------------------------------------------------
	delete files
	------------------------------------------------------------------------------*/
	%do tempi = 1 %to %sysfunc(countw(%str(&c_file_delete.), %str(#)));
		%let c_file_delete_now = %sysfunc(compress(%scan(%str(&c_file_delete.), &tempi., %str(#))));

		filename myfile "&c_file_delete_now.";

		data _null_;
			rc = fdelete('myfile');
		run;
	%end;
	/*----------------------------------------------------------------------------*/

	/*------------------------------------------------------------------------------
	preparing the data
	------------------------------------------------------------------------------*/
	%let c_data                           = in.&c_data_in.;
	%let c_st_where                       = ;
	%let c_sep                            = ;

	%if &grp_no. ^= 0 %then
		%do;
			%let c_st_where                       = &c_st_where. &c_sep. grp&grp_no._flag="&grp_flag.";
			%let c_sep                            = and;
		%end;
	%if %str(&c_var_in_freq.) ^= %str() %then
		%do;
			%let c_st_where                       = &c_st_where. &c_sep. &c_var_in_freq.>=1;
			%let c_sep                            = and;
		%end;
	%if %str(&c_var_in_weight.) ^= %str() %then
		%do;
			%let c_st_where                       = &c_st_where. &c_sep. &c_var_in_weight.>0;
			%let c_sep                            = and;
		%end;
	%if %str(&c_st_where) ^= %str() %then
		%do;
			%let c_st_where                       = where=(&c_st_where.);
			%let c_data                           = dataworking_subsetted;
			%let c_st_keep                        = %str(&c_var_in_ttest. &c_var_in_freq. &c_var_in_weight. &c_var_in_class.);
			%let c_st_keep                        = %sysfunc(tranwrd(%str(&c_st_keep.), %str(*), %str( )));
			%let c_st_keep                        = keep=&c_st_keep.;

			data &c_data.;
				set in.&c_data_in.(&c_st_where.);
			run;
		%end;
	/*----------------------------------------------------------------------------*/
	
	/*------------------------------------------------------------------------------
	input validation
	------------------------------------------------------------------------------*/
	%let dsid                             = %sysfunc(open(&c_data.));
	%let n_obs_temp                       = %sysfunc(attrn(&dsid., NOBS));
	%let rc                               = %sysfunc(close(&dsid.));

	%if &n_obs_temp.=0 or &n_obs_temp.=. %then
		%do;
			%let c_error = There are 0 observations in the dataset.;
			%if %str(&c_st_where.) ^= %str() %then
				%do;
					%let c_error = &c_st_where.;
					%let c_error = %sysfunc(translate(%str(&c_error.), %str(  ), %str(%(%))));
					%let c_error = %sysfunc(translate(%str(&c_error.), %str(%'), %str(%")));
					%let c_error = %sysfunc(tranwrd(%str(&c_error.), %str(where=), %str()));
					%let c_error = There are 0 observations in the dataset where &c_error..;
				%end;

			data _null_;
				v1 = "&c_error.";
				file "&c_path_out./&c_txt_error..txt";
				put v1;
			run;

			%goto the_end;
		%end;

	%if %str(&c_var_in_class.) ^= %str() %then
		%do;
			proc sql;
				select count(distinct(&c_var_in_class.)) into: n_val_class_unique
					from &c_data.;
			run;
			quit;

			%if &n_val_class_unique. ^= 2 %then
				%do;
					%let c_error = &c_var_in_class. is not binary. Hence report could not be generated.;
					%if &grp_no. ^= 0 %then
						%let c_error = &c_var_in_class. is not binary in one of the panel levels. Hence report could not be generated.;
/*					%let c_error = There are %sysfunc(compress(&n_val_class_unique.)) unique level(s) in &c_var_in_class.. There should be 2 and only 2 unique levels.;*/
/*					%if %str(&c_st_where.) ^= %str() %then*/
/*						%do;*/
/*							%let c_error = &c_st_where.;*/
/*							%let c_error = %sysfunc(translate(%str(&c_error.), %str(  ), %str(%(%))));*/
/*							%let c_error = %sysfunc(translate(%str(&c_error.), %str(%'), %str(%")));*/
/*							%let c_error = %sysfunc(tranwrd(%str(&c_error.), %str(where=), %str()));*/
/*							%let c_error = There are %sysfunc(compress(&n_val_class_unique.)) unique level(s) in &c_var_in_class. where &c_error.. There should be 2 and only 2 unique levels.;*/
/*						%end;*/

					data _null_;
						v1 = "&c_error.";
						file "&c_path_out./&c_txt_error..txt";
						put v1;
					run;

					%goto the_end;
				%end;
		%end;
	/*----------------------------------------------------------------------------*/

	/*------------------------------------------------------------------------------
	proc ttest
	------------------------------------------------------------------------------*/
	%do tempi = 1 %to %sysfunc(countw(%str(&c_var_in_ttest.), %str( )));

		%let c_var_in_ttest_now = %scan(%str(&c_var_in_ttest.), &tempi., %str( ));
		%let n_h0_now           = %scan(%str(&n_h0.), &tempi., %str( ));
		%let c_st_paired        = ;
		%let c_st_var           = ;

		%if %str(&c_type_ttest.)    =  %str(paired) %then %let c_st_paired = %str(paired &c_var_in_ttest_now.;);
		%if %str(&c_type_ttest.)    ^= %str(paired) %then %let c_st_var    = %str(var &c_var_in_ttest_now.;);

		ods output statistics = statistics;
		ods output ttests = ttests;
		%if %str(&c_type_ttest.) = %str(2sample) %then ods output equality = equality;;

		proc ttest data=&c_data. alpha=&n_alpha. h0=&n_h0_now. %if &b_cochran. = 1 %then %do; cochran %end; ;
			&c_st_class.
			&c_st_paired.
			&c_st_var.
			&c_st_freq.
			&c_st_weight.
		run;
		quit;

		%let c_var_in_ttest_now = %sysfunc(tranwrd(%str(&c_var_in_ttest_now.), %str(*), %str(_murx_)));

		/*------------------------------------------------------------------------------
		pre output : create folder
		------------------------------------------------------------------------------*/
		data _null_;
			rc = dcreate("&c_var_in_ttest_now.", "&c_path_out.");
		run;
		/*----------------------------------------------------------------------------*/

		/*------------------------------------------------------------------------------
		output : 01 : variable statistics
		------------------------------------------------------------------------------*/
		proc transpose data=statistics out=&c_data_variable_statistics.;
		var _all_;
		run;
		quit;

		%if %str(&c_type_ttest.) = %str(2sample) %then
			%do;

				data &c_data_variable_statistics.(keep=label col1_c col2_c col3_c rename=(col1_c=value_sample_1
						col2_c=value_sample_2 col3_c=value_difference));
					set &c_data_variable_statistics.;
					if _name_ = "Variable" then delete;
					label = _label_;
					if label = "" then label = _name_;
					col1_c = left(col1);
					col2_c = left(col2);
					col3_c = left(col3);
					%if &c_confidence_interval. = Equal %then
						%do;
							if label = "UMPU Lower Limit of Std Dev" then delete;
							if label = "UMPU Upper Limit of Std Dev" then delete;
						%end;
					%if &c_confidence_interval. = UMPU %then
						%do;
							if label = "Lower Limit of Std Dev" then delete;
							if label = "Upper Limit of Std Dev" then delete;
						%end;
					%if &c_confidence_interval. = None %then
						%do;
							if label = "UMPU Lower Limit of Std Dev" then delete;
							if label = "UMPU Upper Limit of Std Dev" then delete;
							if label = "Lower Limit of Std Dev" then delete;
							if label = "Upper Limit of Std Dev" then delete;
						%end;
					if label = "N" then label = "Number of Observations";
					if label = "Std Dev" then label = "Standard Deviation";
					if label = "Std Error" then label = "Standard Error";
					if label = "UMPU Lower Limit of Std Dev" then label = "UMPU Lower Limit of Standard Deviation";
					if label = "UMPU Upper Limit of Std Dev" then label = "UMPU Upper Limit of Standard Deviation";
					if label = "Lower Limit of Std Dev" then label = "Lower Limit of Standard Deviation";
					if label = "Upper Limit of Std Dev" then label = "Upper Limit of Standard Deviation";
				run;
				
				data &c_data_temp;
					length label $50 value_sample_1 $100 value_sample_2 $100 value_difference $100;
					label            = "Null Hypothesis Mean";
					value_sample_1   = "&n_h0_now.";
					value_sample_2   = "&n_h0_now.";
					value_difference = "&n_h0_now.";
				run;
				
				data &c_data_variable_statistics.;
					set &c_data_temp. &c_data_variable_statistics.;
				run;
			%end;
		%else
			%do;
				data &c_data_variable_statistics.(keep=label col1_c rename=(col1_c=value));
					set &c_data_variable_statistics.;
					if _name_ = "Variable" then delete;
					label = _label_;
					if label = "" then label = _name_;
					col1_c = left(col1);
					%if &c_confidence_interval. = Equal %then
						%do;
							if label = "UMPU Lower Limit of Std Dev" then delete;
							if label = "UMPU Upper Limit of Std Dev" then delete;
						%end;
					%if &c_confidence_interval. = UMPU %then
						%do;
							if label = "Lower Limit of Std Dev" then delete;
							if label = "Upper Limit of Std Dev" then delete;
						%end;
					%if &c_confidence_interval. = None %then
						%do;
							if label = "UMPU Lower Limit of Std Dev" then delete;
							if label = "UMPU Upper Limit of Std Dev" then delete;
							if label = "Lower Limit of Std Dev" then delete;
							if label = "Upper Limit of Std Dev" then delete;
						%end;
					if label = "N" then label = "Number of Observations";
					if label = "Std Dev" then label = "Standard Deviation";
					if label = "Std Error" then label = "Standard Error";
					if label = "UMPU Lower Limit of Std Dev" then label = "UMPU Lower Limit of Standard Deviation";
					if label = "UMPU Upper Limit of Std Dev" then label = "UMPU Upper Limit of Standard Deviation";
					if label = "Lower Limit of Std Dev" then label = "Lower Limit of Standard Deviation";
					if label = "Upper Limit of Std Dev" then label = "Upper Limit of Standard Deviation";
				run;
				
				data &c_data_temp;
					length label $50 value $100;
					label            = "Null Hypothesis Mean";
					value            = "&n_h0_now.";
				run;
				
				data &c_data_variable_statistics.;
					set &c_data_temp. &c_data_variable_statistics.;
				run;
			%end;
		
		proc export data=&c_data_variable_statistics.
			outfile="&c_path_out./&c_var_in_ttest_now./&c_csv_variable_statistics..csv" dbms=csv replace;
		run;
		quit;
		/*----------------------------------------------------------------------------*/

		/*------------------------------------------------------------------------------
		output : 02 : ttest result
		------------------------------------------------------------------------------*/
		proc transpose data=ttests out=&c_data_t_test_result.;
			var _all_;
		run;
		quit;
		
		%if %str(&c_type_ttest.) = %str(2sample) %then
			%do;
				data &c_data_t_test_result.(keep=label col1_c col2_c %if &b_cochran. = 1 %then %do; col3_c %end;
					rename=(col1_c=value_1 col2_c=value_2 %if &b_cochran. = 1 %then %do; col3_c=value_3 %end;));
					set &c_data_t_test_result.;
					label = _label_;
					if label = "" then label = _name_;
					if label = "DF" then label = "Degrees of Freedom";
					col1_c = left(col1);
					col2_c = left(col2);
					%if &b_cochran. = 1 %then %do; col3_c = left(col3); %end;
				run;
			%end;
		%else
			%do;
				data &c_data_t_test_result.(keep=label col1_c rename=(col1_c=value));
					set &c_data_t_test_result.;
					label = _label_;
					if label = "" then label = _name_;
					if label = "DF" then label = "Degrees of Freedom";
					col1_c = left(col1);
				run;
			%end;

		proc export data=&c_data_t_test_result. outfile="&c_path_out./&c_var_in_ttest_now./&c_csv_t_test_result..csv" dbms=csv replace;
		run;
		quit;
		/*----------------------------------------------------------------------------*/

		/*------------------------------------------------------------------------------
		output : 03 : equality test result
		------------------------------------------------------------------------------*/
		%if %str(&c_type_ttest.) = %str(2sample) %then
			%do;
				proc transpose data=equality out=&c_data_equality_test_result.;
					var _all_;
				run;
				quit;

				data &c_data_equality_test_result.(keep=label col1_c rename=(col1_c=value));
					set &c_data_equality_test_result.;
					label = _label_;
					if label = "" then label = _name_;
					if label = "Numerator Degrees Freedom" then label = "Numerator Degrees of Freedom";
					if label = "Denominator Degrees Freedom" then label = "Denominator Degrees of Freedom";
					col1_c = left(col1);
				run;

				proc export data=&c_data_equality_test_result. outfile="&c_path_out./&c_var_in_ttest_now./&c_csv_equality_test_result..csv" dbms=csv replace;
				run;
				quit;
			%end;
		/*----------------------------------------------------------------------------*/

	%end;
	/*----------------------------------------------------------------------------*/

	/*------------------------------------------------------------------------------
	output : completed txt
	------------------------------------------------------------------------------*/
	data _null_;
		v1= "eda > ttests : completed";
		file "&c_path_out./completed.txt";
		put v1;
	run;
	/*----------------------------------------------------------------------------*/

	%the_end:
%mend eda_tt;
%eda_tt;
