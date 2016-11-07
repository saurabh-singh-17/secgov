/*Sample Parameters*/
/*%let c_text_filter_dc                	= date_monyy5 > ('01JAN2008'd)||sales > (10)||(Date >= ('01Jan2008'd)) and (Date < ('01Jan2009'd));*/
/*%let c_text_filter_vs                	= geography IN ('north')||black_hispanic > (10);*/
/*%let c_text_sort            	     	= (by geography asc top 100% obs)!!(by store_format asc top 50% obs)!!(by sales asc top 20% obs);*/
/*********************************************************************************************************************/
options mlogic mprint symbolgen;
%let data_name_filter				  = dataworking_filter;
%let data_name_sorted				  = dataworking_sorted;
%let data_name_final				  = final_filter_sort;

proc datasets lib=work;
	delete &data_name_sorted. &data_name_filter. &data_name_final.;
run;

quit;

%macro get_select_obs(master_string/*string which contains the paramaters*/,n_obs/*No of total observations*/);
	%let select_obs_type= %scan("&master_string.",6," ");
	%put &select_obs_type.;

	%if %index(&master_string.,%) > 0 %then
		%do;
/*			%let select_obs = %sysfunc(tranwrd(&select_obs_type.,%,));*/
			%let select_obs = %scan("&master_string.",5," ");
			%let select_obs = %sysevalf(%eval(&select_obs.*&n_obs.)/100);
			%let select_obs = %sysfunc(round(&select_obs.));
		%end;
	%else
		%do;
			%let select_obs = %scan("&master_string.",5," ");
		%end;

	&select_obs.
%mend;

%macro filter_sort;
	%put printing the values from sort Filter Code;
	%put &c_text_filter_dc.;
	%put &c_text_filter_vs.;
	%put &c_var_vs.;
	%put &c_text_sort.;

	/*Global Variables*/
	%global n_obs_a4;
	%global n_obs_b4;

	/*parameter play*/
	%let c_var_key                        = primary_key_1644;
	%let c_text_filter					  = &c_text_filter_dc.;
	%let c_txt_completed      			  = completed;
	%let c_txt_error          			  = error;
	%let c_txt_warning        			  = warning;
	%let min_obs						  = 10;
	%let filter_applicable				  = no;
	%let c_file_delete		   			  =	&c_path_out./&c_txt_completed..txt#
		&c_path_out./&c_txt_error..txt#
		&c_path_out./&c_txt_warning..txt;

	/*Libraries*/
	libname in   "&c_path_in.";
	libname out  "&c_path_out.";

	/*Delete Files*/
	%do tempi = 1 %to %sysfunc(countw(%str(&c_file_delete.), %str(#)));
		%let c_file_delete_now = %sysfunc(compress(%scan(%str(&c_file_delete.), &tempi., %str(#))));
		filename myfile "&c_file_delete_now.";

		data _null_;
			rc = fdelete('myfile');
		run;

	%end;

	/*Reading the number of observations before filtering*/
	%let dsid=%sysfunc(open(in.dataworking,in));
	%let n_obs_b4=%sysfunc(attrn(&dsid,nobs));

	%if &dsid > 0 %then
		%let rc=%sysfunc(close(&dsid));

	%if &n_obs_b4. < 1 %then
		%do;

			data _null_;
				v1= "The number of observations(N) in the data set is &n_obs. Hence cannot performing filtering and sorting.";
				file "&c_path_out./&c_txt_error..txt";
				put v1;
			run;

			%goto the_end;
		%end;
	%else
		%do;
			/*Sort and Filter*/
			/*First Filtering the dataset*/
			%if "&c_text_filter_vs." ^= "" and %symexist(c_var_required) and "&c_var_required." ^= "" %then
				%do;
					%put Contains Variable Specific Filter;
					%let apply_vs_filter = true;
					%let c_vars_selected = %sysfunc(compbl(&c_var_required.));
					%let c_var_vs = %sysfunc(compbl(&c_var_vs.));

					%do i=1 %to %sysfunc(countw("&c_var_vs."," "));
						%let variable_vs = %scan("&c_var_vs.",&i," ");

						%if %index(&c_vars_selected.,&variable_vs.) = 0 %then
							%do;
								%let apply_vs_filter = false;
							%end;
					%end;

					%if "&apply_vs_filter" = "true" %then
						%do;
							%if "&c_text_filter." ^= "" %then
								%do;
									%let c_text_filter=&c_text_filter. and &c_text_filter_vs.;
								%end;
							%else
								%do;
									%let c_text_filter=&c_text_filter_vs.;
								%end;
						%end;
				%end;

			%if "&c_text_filter_vs." ^= "" and ^%symexist(c_var_required) %then
				%do;
					%if "&c_text_filter." ^= "" %then
						%do;
							%let c_text_filter=&c_text_filter. and &c_text_filter_vs.;
						%end;
					%else
						%do;
							%let c_text_filter=&c_text_filter_vs.;
						%end;
				%end;

			%if "&c_text_filter." ^= "" %then
				%do;
					%let c_condition_filter = %sysfunc(compbl(&c_text_filter.));
					%put &c_condition_filter.;

					data _null_;
						call symput("c_condition_filter",tranwrd("&c_condition_filter.","||"," and "));
					run;

					%put &c_condition_filter.;

					/*Filtering the dataset*/
					data &data_name_filter.;
						set in.dataworking;

						where &c_condition_filter.;
						output;
					run;

					%let dsid=%sysfunc(open(work.&data_name_filter.,in));
					%let n_obs_a4=%sysfunc(attrn(&dsid,nobs));

					%if &dsid > 0 %then
						%let rc=%sysfunc(close(&dsid));
				%end;
			%else
				%do;

					data _null_;
						v1= "No Filter Condition Found.";
						file "&c_path_out./&c_txt_warning..txt";
						put v1;
					run;

					/*Directly go to sorting*/
					data &data_name_final.;
						set in.dataworking;
					run;

					%let n_obs_a4 = &n_obs_b4.;
					%goto sort_func;
				%end;

			/*Check if the no. of observations are > 0, if yes proceed forward, else end.*/
			%if &n_obs_a4. < 1 %then
				%do;

					data _null_;
						v1= "The number of observations(N) after filtering is &n_obs_a4.. Hence cannot proceed further.";
						file "&c_path_out./&c_txt_error..txt";
						put v1;
					run;
					%let c_data_filter_and_sort = &data_name_filter.;

					%goto the_end;
				%end;
			%else
				%do;
					/*Create final data set*/
					data &data_name_final.;
						set &data_name_filter.;
					run;

				%end;

			/*Performing Sort*/
			%sort_func:

			%if "&c_text_sort." ^= "" %then
				%do;
					%let c_text_sort = %sysfunc(compbl(&c_text_sort.));
					%put &c_text_sort.;

					%do k=1 %to %sysfunc(countw("&c_text_sort.","||"));
						%let sort_condition=%scan("&c_text_sort.",&k,"||");

						data &data_name_sorted.;
							set &data_name_final.;
						run;

						%let n_obs_sort = &n_obs_a4.;

						%do i=1 %to %sysfunc(countw("&sort_condition.","!!"));
							%let filter= %scan("&sort_condition.",&i,"!!");

							/*Get the variable name, sort type and number of selected records*/
							%let varname= %scan("&filter.",2," ");
							%let sort_type= %scan("&filter.",3," ");
							%let select_obs = %get_select_obs(&filter.,&n_obs_sort.);
							%put &select_obs.;
							%put &n_obs_sort.;

							%if (&select_obs.) <= (&n_obs_sort.) %then
								%do;
									%let f&i.=&varname. &sort_type.;
									%put f&i.= &&f&i..;

									/*Performing the sort*/
									proc sql outobs=&select_obs.;
										create table &data_name_sorted.  as
											select * from &data_name_sorted. order by

											%do j=1 %to &i.;
												%if &j. = 1 %then
													%do;
														%let ff=&&f&j..;
													%end;
												%else
													%do;
														%let ff=&ff.,&&f&j..;
													%end;
											%end;

										&ff.
										;

										/*Recalculating the number of observations in sorted and subsetted dataset*/
										%let dsid=%sysfunc(open(work.&data_name_sorted.,in));
										%let n_obs_sort=%sysfunc(attrn(&dsid,nobs));
										%let rc=%sysfunc(close(&dsid));
								%end;
							%else
								%do;

/*									data _null_;*/
/*										v1= "Selection criteria is &select_obs. which is greater than the subseted records &n_obs_sort.";*/
/*										file "&c_path_out./&c_txt_error..txt";*/
/*										put v1;*/
/*									run;*/

									%let n_obs_a4 = 0 ;
									%let min_obs = &select_obs.;
									%let c_data_filter_and_sort = &data_name_sorted.;
									%goto the_end;
								%end;
						%end;
					%end;
				%end;
			%else
				%do;

					data _null_;
						v1= "No Sort Condition Found.";
						file "&c_path_out./&c_txt_warning..txt";
						put v1;
					run;

					%goto the_end;
				%end;

			data &data_name_final.;
				set &data_name_sorted.;
			run;

			%let n_obs_a4 = &n_obs_sort.;
		%end;

	%the_end:
	%symdel c_var_required;
%mend;

%filter_sort;