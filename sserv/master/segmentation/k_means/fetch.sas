/*------------------------------------------------------------------------------
sample parameters
------------------------------------------------------------------------------*/
/*%let c_path_in        = D:/data;*/
/*%let c_path_iter      = C:\Users\vasanth.mm\MRx\sas\vasanth_merge-27-May-2014-10-38-29\1\0\1_1_1\KMEANS\1\1;*/
/*%let c_path_out       = D:/temp;*/
/*%let c_var_in_fetch   = date acv sales;*/
/*----------------------------------------------------------------------------*/



*processbody;
options mlogic mprint symbolgen;

%macro seg_km_fetch;

	/* workflow */
	%goto parameter_play;
	%wf_a_parameter_play:

	%goto delete_files;
	%wf_a_delete_files:

	%goto fetch;
	%wf_a_fetch:

	%goto output;
	%wf_a_output:

	%goto completed;
	%wf_a_completed:

	%goto the_end;
	/* workflow ends */

	%parameter_play:

	/* hardcoding */
	%let c_csv_fetch           = fetch;
	%let c_data_fetch          = fetch;
	%let c_data_iter           = final_cluster;
	%let c_data_in             = dataworking;
	%let c_data_temp           = murx_temp;
	%let c_file_log            = &c_path_out./seg_km_fetch.log;
	%let c_txt_completed       = completed;
	%let c_txt_error           = error;
	%let c_txt_warning         = warning;
	%let c_var_cluster         = murx_n_cluster;
	%let c_var_key             = primary_key_1644;

	/* the play */
	%let c_file_delete		   =	&c_path_out./&c_txt_completed..txt#
									&c_path_out./&c_txt_error..txt#
									&c_path_out./&c_txt_warning..txt#
									&c_path_out./&c_csv_fetch..csv;

	/* libraries */
	libname in   "&c_path_in.";
	libname out  "&c_path_out.";
	libname iter "&c_path_iter.";

	proc printto log="&c_file_log." new;
	run;
	quit;

	%goto wf_a_parameter_play;

	%delete_files:

	%do tempi = 1 %to %sysfunc(countw(%str(&c_file_delete.), %str(#)));
		%let c_file_delete_now = %sysfunc(compress(%scan(%str(&c_file_delete.), &tempi., %str(#))));

		filename myfile "&c_file_delete_now.";

		data _null_;
			rc = fdelete('myfile');
		run;
	%end;

	%goto wf_a_delete_files;

	%fetch:

	data &c_data_fetch.;
		merge in.&c_data_in.(keep = &c_var_in_fetch. &c_var_key. firstobs=&n_obs_start. obs=&n_obs_stop.) iter.&c_data_iter.(keep = &c_var_cluster. firstobs=&n_obs_start. obs=&n_obs_stop.);
	run;

	%goto wf_a_fetch;

	%output:

	proc export data=&c_data_fetch. outfile="&c_path_out./&c_csv_fetch..csv" dbms=csv replace;
	run;
	quit;

	%goto wf_a_output;

	%completed:

	data _null_;
		v1= "&c_txt_completed.";
		file "&c_path_out./&c_txt_completed..txt";
		put v1;
	run;

	%goto wf_a_completed;

	%the_end:
%mend seg_km_fetch;
%seg_km_fetch;