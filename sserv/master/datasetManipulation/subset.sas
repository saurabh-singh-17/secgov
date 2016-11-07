/*Sample Parameters*/
/*%let c_path_in                      = /product-development/nida.arif/subset;*/
/*%let c_path_out                     = /product-development/nida.arif/subset/output;*/
/*%let c_var_in                       = ACV sales geography;*/
/*%let c_type_subset                  = Panel Selection;*/
/*%let c_data_subset                  = abc;*/

/*For Filter Scenario*/
/*%let c_path_param_filter            =/product-development/nida.arif/sort_and_filter/filter_scn2/param_sort_and_filter.sas;*/
/*%let c_path_code_filter             =/product-development/nida.arif/sort_and_filter/sort_and_filter.sas;*/

/*For Panel Selection*/
/*%let n_panel                        = 1;*/
/*%let c_val_panel                    = 1_1_1;*/

/*For Dataset Order Subset*/
/*%let c_ran_seq                      =random;*/
/*%let b_n_obs                        =0;*/
/*%let b_p_obs                        =1;*/
/*%let n_obs_from                     =100;*/
/*%let n_obs_to                       =200;*/
/*%let n_p_obs                        =50;*/
/*%let c_bottom_top                   =bottom;*/
/*%let n_obs_random                   =100;*/
/*%let n_seed                         =40;*/
/*%let n_p_obs_random                 =50;*/
/*********************************************************************************************************************/


options mlogic mprint symbolgen;
%let data_name_export = &c_data_subset.;


%macro subset;
	/*Paramer Play*/
	%let c_var_key      	                  = primary_key_1644;
	%let c_data_filter_and_sort				  = final_filter_sort;

	/*Files*/
	%let c_file_log							  = &c_path_out./subset.log;
	%let c_file_txt_completed      			  = completed;
	%let c_file_txt_error          			  = error;
	%let c_file_txt_warning        			  = warning;
	%let c_file_csv_subset					  = &c_data_subset.;
	%let c_file_delete		   				  =	&c_path_out./&c_file_txt_completed..txt#
		&c_path_out./&c_file_txt_error..txt#
		&c_path_out./&c_file_txt_warning..txt#
		&c_path_out./&c_file_log..txt#
		&c_path_out./&c_file_csv_subset..csv;

	/*Delete Files*/
	%do tempi = 1 %to %sysfunc(countw(%str(&c_file_delete.), %str(#)));
		%let c_file_delete_now = %sysfunc(compress(%scan(%str(&c_file_delete.), &tempi., %str(#))));
		filename myfile "&c_file_delete_now.";

		data _null_;
			rc = fdelete('myfile');
		run;

	%end;

	/*Log file*/
		proc printto log="&c_file_log." new;
		run;

	/*Libraries*/
	libname in   "&c_path_in.";
	libname out  "&c_path_out.";

	%let n_dsid   = %sysfunc(open(in.dataworking));
	%let n_obs_b4_1 = %sysfunc(attrn(&n_dsid., NOBS));
	%let n_rc     = %sysfunc(close(&n_dsid.));

	data &c_data_subset.;
		set in.dataworking;
	run;

	/*Based on Panel selected*/
	%if "&c_type_subset." = "Panel Selection" %then
		%do;
			%let c_var_panel = grp&n_panel._flag;
			%let c_st_where  = %str(%'&c_val_panel.%');
			data _null_;
				call symput("c_st_where", tranwrd("&c_st_where.", " ", "','"));
			run;
			%let c_st_where  = %str(where=(&c_var_panel. in (&c_st_where.)));

			data &c_data_subset.;
				set &c_data_subset.(&c_st_where.);
			run;

		%end;

	%if "&c_type_subset." = "Filter Scenario" %then
		%do;
			%let c_path_param_filter =  %str(%')&c_path_param_filter.%str(%');
			%put &c_path_param_filter.;
			%let c_path_code_filter =  %str(%')&c_path_code_filter.%str(%');
			%put &c_path_code_filter.;

			%include %unquote(&c_path_param_filter.);
			%include %unquote(&c_path_code_filter.);

			data &c_data_subset.;
				set &c_data_filter_and_sort.;
			run;

		%end;

	%if "&c_type_subset." = "Dataset Order Subset" %then
		%do;
			%if "&c_ran_seq." = "Random" %then
				%do;
					%if "&b_n_obs." = "1" %then
						%do;

							proc surveyselect data=&c_data_subset. out=&c_data_subset. method=SRS
								sampsize=&n_obs_random. seed=&n_seed.;
							run;

						%end;
					%else
						%do;
							%let p_select_obs = %sysevalf(%eval(&n_p_obs_random.*&n_obs_b4_1.)/100);
							%let p_select_obs = %sysfunc(round(&p_select_obs.));
							%put &p_select_obs.;

							proc surveyselect data=&c_data_subset. out=&c_data_subset. method=SRS
								sampsize=&p_select_obs. seed=&n_seed.;
							run;

						%end;
				%end;

			%if "&c_ran_seq." = "Sequential" %then
				%do;
					%if "&b_n_obs." = "1" %then
						/*Subsetting based on from and to indexes*/

						%do;

							data &c_data_subset.;
								set &c_data_subset.;

								if &c_var_key. >= &n_obs_from. and &c_var_key. <= &n_obs_to. then
									output;
							run;

						%end;
					%else /*Subsetting based on percentage split from top or bottom*/
					%do;
						%let p_select_obs = %sysevalf(%eval(&n_p_obs.*&n_obs_b4_1.)/100);
						%let p_select_obs = %sysfunc(round(&p_select_obs.));
						%put &p_select_obs.;

						data &c_data_subset.;
							set &c_data_subset.;

							%if "&c_bottom_top." = "Top" %then
								%do;
									if &c_var_key. <= &p_select_obs. then
										output;
								%end;
							%else
								%do;
									if &c_var_key. >= %eval(&n_obs_b4_1.-&p_select_obs.+1) then
										output;
								%end;
						run;

					%end;
				%end;
		%end;

	%let c_var_in = %sysfunc(compbl(&c_var_in.));
	%put &c_var_in.;

	data &c_data_subset. (keep=&c_var_in.);
		set &c_data_subset.;
	run;

	proc export data=&data_name_export. outfile="&c_path_out./&c_file_csv_subset..csv" dbms=csv replace;
	run;

	data out.&data_name_export.;
	set &c_data_subset.;
	run;

	data _null_;
		v1= "completed";
		file "&c_path_out./&c_file_txt_completed..txt";
		put v1;
	run;

	%the_end:
%mend;

%subset;
