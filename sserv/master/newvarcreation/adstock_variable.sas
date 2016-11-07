*processbody;
options mlogic mprint symbolgen;

%macro dp_nvc_ads_0;

	%if %symexist(b_debug) = 0 %then
		%let b_debug = 0;

	%global /* parameters */
			c_path_in c_path_out
			c_data_in
			c_var_in_adstock

			c_var_in_by c_var_in_date c_var_in_dependent c_var_in_selected
			c_mode
			c_type_eqn c_type_trn
			n_gamma n_lambda n_panel

			/* hardcoding */
			c_csv_corr  c_csv_new
			c_data_corr c_data_new c_data_temp c_data_temp2
			c_var_new c_var_key
			c_logfile
			c_txt_completed c_txt_error c_txt_warning
			;

	/* parameters */
	%let c_data_in		 = dataworking;
	%let c_var_in_by     = ;
	%let n_lambda        = &n_decay.;

	/* hardcoding */
	%let c_csv_corr       = correlation_table;
	%let c_csv_new        = adstockVarCreation_viewPane;
	%let c_csv_properties = dataset_prop;
	%let c_data_corr      = murx_corr;
	%let c_data_new       = murx_new;
	%let c_data_temp      = murx_temp;
	%let c_data_temp2     = murx_temp2;

	%let c_var_key       = primary_key_1644;
	%let c_var_new       = ;
	%let c_logfile       = adstock_variable;
	%let c_txt_completed = completed;
	%let c_txt_error     = error;
	%let c_txt_warning   = warning;	

	/* check and change */
	%if &n_panel. %then
		%let c_var_in_by = grp&n_panel._flag;
	%if &c_type_eqn. ^= exponential %then
		%let n_gamma = 1;

	%if &b_debug. %then
		%do;
			proc printto;run;quit;
		%end;
	%else
		%do;
			proc printto log="&c_path_out./&c_logfile..log" new;
			run;
			quit;
		%end;

	/* libraries */
	libname in "&c_path_in.";
	libname out "&c_path_out.";

%mend dp_nvc_ads_0;
%dp_nvc_ads_0;

%macro dp_nvc_ads;
	/* workflow */
	%workflow:

	%goto delete_files;
	%wf_a_delete_files:

	%if &c_mode. = check %then
		%do;
			%goto initialise_c_data_new;
			%wf_a_initialise_c_data_new:

			%goto error_check;
			%wf_a_error_check:

			%goto nvc;
			%wf_a_nvc:
			
			%goto output1;
			%wf_a_output1:
		%end;
	
	%if &c_mode. = confirm %then
		%do;
			%goto prepare_c_data_new;
			%wf_a_prepare_c_data_new:

			%goto cbind_c_data_new_c_data_in;
			%wf_a_cbind_c_data_new_c_data_in:

			%goto output2;
			%wf_a_output2:

			%include "&genericCode_path./datasetprop_update.sas";
		%end;

	%goto completed;
	%wf_a_completed:

	%goto the_end;
	/* workflow ends */
	
	%delete_files:

	%let c_file_delete = 	&c_path_out./&c_txt_completed..txt#
							&c_path_out./&c_txt_error..txt#
							&c_path_out./&c_txt_warning..txt#
							&c_path_out./&c_csv_new..csv#
							&c_path_out./&c_csv_corr..csv#
							;

	%do tempi = 1 %to %sysfunc(countw(%str(&c_file_delete.), %str(#)));
		%let c_file_delete_now = %sysfunc(compress(%scan(%str(&c_file_delete.), &tempi., %str(#))));

		filename myfile "&c_file_delete_now.";

		data _null_;
			rc = fdelete('myfile');
		run;
	%end;
		
	%do tempi = 1 %to %sysfunc(countw(%str(&c_var_in_adstock.), %str( )));
		%let c_file_delete_now = &c_path_out./%scan(%str(&c_var_in_adstock.), &tempi., %str( )).csv;

		filename myfile "&c_file_delete_now.";

		data _null_;
			rc = fdelete('myfile');
		run;
	%end;

	%goto wf_a_delete_files;

	%error_check:

	%include "&genericCode_path./macrodefn_checkFor.sas";
	%let found_status = 0;

	%if &c_type_eqn. = log %then %do;
		%checkFor(dataset=&c_data_new.,variables=&c_var_in_adstock.,checkFor=missing negative 0,outputFileName=&c_path_out./&c_txt_error..txt);
	%end;
	%if &found_status. = 1 %then %do;
		%goto the_end;
	%end;
	%if &c_type_eqn. = exponential %then %do;
		%checkFor(dataset=&c_data_new.,variables=&c_var_in_adstock.,checkFor=negative,outputFileName=&c_path_out./&c_txt_error..txt);
	%end;
	%if &found_status. = 1 %then %do;
		%goto the_end;
	%end;
	%if &c_type_trn. = log %then %do;
		%checkFor(dataset=&c_data_new.,variables=&c_var_in_adstock.,checkFor=missing negative,outputFileName=&c_path_out./&c_txt_error..txt);
	%end;
	%if &found_status. = 1 %then %do;
		%goto the_end;
	%end;
	
	%let dsid = %sysfunc(open(&c_data_new.));
	%let n_obs = %sysfunc(attrn(&dsid., NOBS));
	%let rc   = %sysfunc(close(&dsid));
	
	proc sql noprint;
		select count(distinct(&c_var_in_date.)) = count(&c_var_in_date.) into: b_unique
			separated by " "
				from &c_data_new.
					group by &c_var_in_by.;
	run;
	quit;
	
	%if %index(&b_unique., 0) > 0 %then
		%do;
			data _null_;
				v1= "The date variable does not have unique values.";
				file "&c_path_out./&c_txt_warning..txt";
				put v1;
			run;
			
		%end;
	
	%goto wf_a_error_check;

	%initialise_c_data_new:

	data &c_data_new.;
		set in.&c_data_in.(keep = &c_var_in_dependent. &c_var_in_adstock. &c_var_in_date. &c_var_in_by. &c_var_key.);
		%if "&c_var_in_by." = "" %then
			%do;
				%let c_var_in_by = murx_by;
				&c_var_in_by. = 0;
			%end;
	run;

	%goto wf_a_initialise_c_data_new;

	%nvc:

	%let murx_n_lambda_used  = ;
	%let murx_n_gamma_used   = ;
	%let murx_c_var_in_used  = ;
	%let murx_c_var_new_used = ;

	%let murx_l1 = a;
	%let murx_l2 = d;
	%let murx_l3 = s;
	%let murx_l4 =;

	%if &n_panel. %then
		%let murx_l2 = g;

	%if &c_type_eqn. = log %then
		%let murx_l3 = l;
	
	%if &c_type_eqn. = log %then
		%do;
			%if &c_type_trn. = simple %then
				%let murx_l4 = s;

			%if &c_type_trn. = log %then
				%let murx_l4 = l;
		%end;
	
	%let fourletterword = &murx_l1.&murx_l2.&murx_l3.&murx_l4.;

	proc sort data=&c_data_new. out=&c_data_new.;
		by &c_var_in_by. &c_var_in_date.;
	run;

	quit;

	
		%do murx_n_i = 1 %to %sysfunc(countw(&c_var_in_adstock., %str( )));
			%let murx_c_var_in_now = %scan(&c_var_in_adstock., &murx_n_i., %str( ));

			%do murx_n_j = 1 %to %sysfunc(countw(&n_lambda., %str(!!)));
				%let murx_n_lambda_now = %scan(&n_lambda., &murx_n_j., %str(!!));

				%do murx_n_k = 1 %to %sysfunc(countw(&n_gamma., %str(!!)));
					%let murx_n_gamma_now    = %scan(&n_gamma., &murx_n_k., %str(!!));
					
					%if &c_type_eqn. = exponential %then
						%do;
							%let murx_c_var_new_now  = &fourletterword.&murx_n_i._
													   %sysfunc(tranwrd(&murx_n_lambda_now., %str(.), %str(_)))_
													   %sysfunc(tranwrd(&murx_n_gamma_now.,  %str(.), %str(_)))_
													   %substr(&c_var_in_date., 1, 5)_
													   %substr(&murx_c_var_in_now., 1, 5);
						%end;
					%if &c_type_eqn. = simple or &c_type_eqn. = log %then
						%do;
							%let murx_c_var_new_now  = &fourletterword.&murx_n_i._
													   %substr(&murx_c_var_in_now., 1, 10)_
													   %sysfunc(tranwrd(&murx_n_lambda_now., %str(.), %str()));
						%end;
					
					%let murx_c_var_new_now  = %sysfunc(compress(&murx_c_var_new_now.));
					%let c_var_new           = &c_var_new. &murx_c_var_new_now.;
					%let murx_n_lambdam1_now = %sysevalf(1 - &murx_n_lambda_now.);
					%let murx_c_var_in_used  = &murx_c_var_in_used. &murx_c_var_in_now.;

					%let murx_n_lambda_used  = &murx_n_lambda_used. &murx_n_lambda_now.;
					%let murx_n_gamma_used   = &murx_n_gamma_used. &murx_n_gamma_now.;
					%let murx_c_var_new_used = &murx_c_var_new_used. &murx_c_var_new_now.;

					data &c_data_new.;
						set &c_data_new.;
						by &c_var_in_by.;
						retain &murx_c_var_new_now.;

						if first.&c_var_in_by. then
							&murx_c_var_new_now. = 0;

						%if &c_type_eqn. = simple %then
							%do;
								&murx_c_var_new_now. = (&murx_c_var_in_now. + (&murx_n_lambdam1_now. * &murx_c_var_new_now.)) ** &murx_n_gamma_now.;
							%end;

						%if &c_type_eqn. = log %then
							%do;
								&murx_c_var_new_now. = (log(&murx_c_var_in_now.) + (&murx_n_lambdam1_now. * &murx_c_var_new_now.)) ** &murx_n_gamma_now.;
							%end;
					run;

				%end;
			%end;
		%end;

	proc sort data=&c_data_new. out=&c_data_new.;
		by &c_var_key.;
	run;
	quit;

	%goto wf_a_nvc;

	%output1:

		data in.&c_data_new.;
			set &c_data_new.(keep = &c_var_in_adstock. &c_var_new.);
		run;
		
		%let murx_c_var_in_used  = &murx_c_var_in_used. &c_var_in_adstock.;
		%let murx_c_var_new_used = &murx_c_var_new_used. &c_var_in_adstock.;

		%do tempi = 1 %to %sysfunc(countw(&c_var_in_adstock.," "));
			%let murx_n_lambda_used = &murx_n_lambda_used. 1;
			%let murx_n_gamma_used  = &murx_n_gamma_used. 1;
		%end;

		data &c_data_temp.;
			length var_in_used $ 32 var_new_used $ 32 decay $ 8 gamma $ 8;
			%do tempi = 1 %to %sysfunc(countw(&murx_c_var_in_used., %str( )));
				var_in_used  = compress("%scan(&murx_c_var_in_used.,  &tempi., %str( ))");
				var_new_used = compress("%scan(&murx_c_var_new_used., &tempi., %str( ))");
				decay        = compress("%scan(&murx_n_lambda_used.,  &tempi., %str( ))");
				%if &c_type_eqn. = exponential %then
					%do;
						gamma = compress("%scan(&murx_n_gamma_used.,  &tempi., %str( ))");
					%end;
				output;
			%end;
		run;

		proc corr data = &c_data_new. out = &c_data_corr.(where = (_type_ = "CORR")
			rename = (&c_var_in_dependent. = correlation _name_ = actual_name)) noprint;
			var &c_var_in_dependent.;
			with &c_var_new. &c_var_in_adstock.;
		run;
		quit;

		proc sql;
			create table &c_data_corr. as
				select *
					from &c_data_corr. murx_1 inner join &c_data_temp. murx_2
						on murx_1.actual_name = murx_2.var_new_used;
		run;
		quit;

		%if &c_type_eqn. = exponential %then
			%do murx_n_i = 1 %to %sysfunc(countw(&c_var_in_adstock.," "));

				%let murx_c_var_in_now = %scan(&c_var_in_adstock., &murx_n_i., %str( ));

				proc sql;
					select correlation into: correlation_cutoff
						from &c_data_corr.
							where decay=&base_decay. and gamma = &base_gamma. and variables_used = "&murx_c_var_in_now.";
				run;
				quit;

				data &c_data_temp.;
					length significance $15;
					set &c_data_corr.;
					if variables_used = "&murx_c_var_in_now.";
					significance_flag = 3;
					significance = "Insignificant";
					if decay = &base_decay. & gamma = &base_gamma. then
						do;
							significance_flag = 2;
							significance = "Base";
						end;
					if correlation > %sysevalf(&correlation_cutoff. + &threshold.) then 
						do;
							significance_flag = 1;
							significance = "Significant";
						end;
				run;

				proc append base = &c_data_temp2. data = &c_data_temp. force;
				run;
				quit;

			%end;

		%if &c_type_eqn. = exponential %then
			%do;
				proc sort data = &c_data_temp2. out = &c_data_corr.;
					by variables_used descending significance_flag;
				run;
				quit;
			%end;

		data &c_data_temp.;
			set &c_data_corr.(keep = actual_name correlation decay var_in_used 
				%if c_type_eqn. = exponential %then gamma;
				rename=(var_in_used = variables_used));
		run;

		proc export data = &c_data_temp. outfile = "&c_path_out./&c_csv_corr..csv" dbms=csv replace;
		run;
		quit;

		%let murx_dsid      = %sysfunc(open(&c_data_new.));
		%let murx_n_obs_new = %sysfunc(attrn(&murx_dsid., nobs));	
		%let murx_rc        = %sysfunc(close(&murx_dsid.));

		%if &murx_n_obs_new. > 6000 %then
			%do;
				proc surveyselect data=&c_data_new. out=&c_data_new. method=SRS sampsize=6000 SEED=1234567;
				run;
				quit;
			%end;

		data &c_data_temp.;
			set &c_data_new.(keep = &c_var_in_adstock. &c_var_in_date. &c_var_new.);
		run;
		
		proc sort data=&c_data_temp. out=&c_data_temp.;
			by &c_var_in_date.;
		run;
		quit;
		
		proc export data=&c_data_temp. outfile= "&c_path_out./&c_csv_new..csv" dbms=csv replace;
		run;
		quit;

		%if &c_type_eqn. = exponential %then 
			%do murx_n_i = 1 %to %sysfunc(countw(&c_var_in_adstock., %str( )));

				%let murx_c_var_in_now = %scan(&c_var_in_adstock., &murx_n_i., %str( ));
				%let murx_temp         = &fourletterword.&murx_n_i.;
		
				data &c_data_temp.;
					set &c_data_new.(keep = &murx_c_var_in_now. &c_var_in_date. &murx_temp.:);
				run;
				
				proc sort data=&c_data_temp. out=&c_data_temp.;
					by &c_var_in_date.;
				run;
				quit;

				proc export data=&c_data_temp. outfile="&c_path_out./&murx_c_var_in_now..csv" dbms=csv replace;
				run;
				quit;
			%end;

	%goto wf_a_output1;

	%prepare_c_data_new:

		data &c_data_new.;
			set in.&c_data_new.(keep = &c_var_in_selected.);
		run;

	%goto wf_a_prepare_c_data_new;

	%cbind_c_data_new_c_data_in:

	data in.&c_data_in.;
		merge in.&c_data_in. &c_data_new.;
	run;

	%goto wf_a_cbind_c_data_new_c_data_in;

	%output2:
	
	proc export data=&c_data_new. outfile="&c_path_out./&c_csv_new..csv" dbms=csv replace;
	run;
	quit;

	%goto wf_a_output2;

	%completed:

	data _null_;
		v1= "&c_txt_completed.";
		file "&c_path_out./&c_txt_completed..txt";
		put v1;
	run;

	%goto wf_a_completed;

	%the_end:

%mend dp_nvc_ads;
%dp_nvc_ads;
