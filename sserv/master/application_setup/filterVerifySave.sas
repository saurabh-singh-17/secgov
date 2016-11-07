/*Sample Parameters*/
/*%let c_path_in                          = /product-development/nida.arif/;*/
/*%let c_path_out                         = /product-development/nida.arif/Test;*/
/*%let c_path_filter_param		 	  = /product-development/nida.arif/sort_and_filter/filter_scn2/param_sort_and_filter.sas;*/
/*%let c_path_filter_code				  = /product-development/nida.arif/sort_and_filter/sort_and_filter.sas;*/

/**********************************************************************************************************************/
options mlogic mprint symbolgen;

/*Data set to be exported*/
%let data_name_export = export_this;

data &data_name_export.;
	length label $ 50. value $ 350.;
	infile datalines delimiter=',';
	input label $ value $;
	datalines;
Is the filter applicable,No
Number of observations in the original data,0
Number of observations in the filtered data,0
Number of observations lost,0
Filter Conditions,-
Sort Conditions,-
;
run;

%macro verify_and_save;
	/*parameter play*/
	%let c_data_sort_and_filter			  = dataworking;
	%let min_obs					      = 10;
	%let filter_applicable				  = no;

	/*	Global Variables*/
	%global c_text_filter;

	/*Files*/
	%let c_txt_completed      			  = completed;
	%let c_txt_error          			  = error;
	%let c_txt_warning        			  = warning;
	%let c_csv_filter_sort				  = verify_and_save;
	%let c_file_log						  = &c_path_out./verify_and_save.log;
	%let c_file_delete		   			  =	&c_path_out./&c_txt_completed..txt#
		&c_path_out./&c_txt_error..txt#
		&c_path_out./&c_txt_warning..txt#
		&c_path_out./verify_and_save.log#
		&c_path_out./&c_csv_filter_sort..csv;

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

	dm log 'clear' output;

	/*	Log file*/
	proc printto log="&c_file_log." new;
	run;
	quit;

/*	proc printto;*/
/*	run;*/
/*	quit;*/

	%put printing the values from verify and save (1);
	%put &c_text_filter_dc.; 
	%put &c_text_filter_vs.;
	%put &c_var_vs.;
	%put &c_text_sort.;

	/*Calling the Sort and Filter Code*/
	%put deleting the variables: ;
	%symdel c_var_required c_text_filter_dc c_text_filter_vs c_text_sort;

	%let c_path_filter_param =  %str(%')&c_path_filter_param.%str(%');
	%put printing the values from verify and save(2);
	%put &c_text_filter_dc.;
	%put &c_text_filter_vs.;
	%put &c_var_vs.;
	%put &c_text_sort.;

	%let c_path_filter_code	 =  %str(%')&c_path_filter_code.%str(%');

	%include %unquote(&c_path_filter_param.);
	%include %unquote(&c_path_filter_code.);

	/*Populating the output dataset which must be exported*/
	%if &n_obs_a4. > &min_obs. %then
		%let filter_applicable = yes;

	data &data_name_export.;
		set &data_name_export.;
		call symput("c_text_filter",tranwrd("&c_text_filter","||"," and "));
		call symput("c_text_sort",tranwrd("&c_text_sort","!!"," then "));

		if _n_ = 1 then
			value = resolve('&filter_applicable.');

		if _n_ = 2 then
			value = resolve('&n_obs_b4.');

		if _n_ = 3 then
			value = resolve('&n_obs_a4.');

		if _n_ = 4 then
			value = resolve('%eval(&n_obs_b4.-&n_obs_a4.)');

		if _n_ = 5 then
			value = resolve('&c_text_filter.');

		if _n_ = 6 then value = resolve('%sysfunc(tranwrd(&c_text_sort.,!!, then
			))');
	run;
	
	proc export data=&data_name_export. outfile="&c_path_out./&c_csv_filter_sort..csv" dbms=csv replace;
	run;

	%if ^%sysfunc(fileexist(&c_path_out./&c_txt_error..txt)) %then
		%do;
			data _null_;
				v1= "completed";
				file "&c_path_out./&c_txt_completed..txt";
				put v1;
			run;

		%end;

	%the_end:
%mend;


%verify_and_save;