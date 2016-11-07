/*Sample Parameters*/
/*%let codePath=/product-development/murx///SasCodes//8.7;*/
/*%let c_path_out=/product-development/murx///projects/Nida_Clustering-17-Jul-2014-16-46-43/3/0/1_1_1/KMEANS/1/27;*/
/*%let c_path_iter=/product-development/murx///projects/Nida_Clustering-17-Jul-2014-16-46-43/3/0/1_1_1/KMEANS/1/27;*/
/*%let c_path_fetch=/product-development/murx///projects/Nida_Clustering-17-Jul-2014-16-46-43/3/0/1_1_1;*/
/*%let c_no_clusters=4;*/
/*%let c_add_observations=7 1;*/
/*%let c_fetch_variable=neg_channel_1;*/

*processbody;
options mlogic mprint symbolgen;

%macro segmentation_addobservations;
	/* workflow */
	%goto parameter_play;
	%wf_a_parameter_play:

	%goto delete_files;
	%wf_a_delete_files:

	%goto addobs;
	%wf_a_addobs:

	%goto output;
	%wf_a_output:

	%goto completed;
	%wf_a_completed:

	%goto the_end;

	/*	 workflow ends */
	%parameter_play:

	/* hardcoding */
	%let c_csv_CS              = ClusterMeans;
	%let c_data_CS             = CS;
	%let c_csv_fetch           = fetch;
	%let c_data_fetch          = fetch;
	%let c_file_log            = seg_km_addobs.log;
	%let c_txt_completed       = completed;
	%let c_txt_error           = error;
	%let c_txt_warning         = warning;
	%let c_var_cluster         = murx_n_cluster;
	%let c_var_key             = primary_key_1644;

	/* the play */
	%let c_add_observations    = %sysfunc(compbl(&c_add_observations.));
	%let c_file_delete		   =	&c_path_out./&c_txt_completed..txt#
		&c_path_out./&c_txt_error..txt#
		&c_path_out./&c_txt_warning..txt;

	/* libraries */
	libname in   "&c_path_in.";
	libname out  "&c_path_out.";
	libname iter "&c_path_iter.";
	libname fetch "&c_path_fetch.";

	proc printto log="&c_path_out./&c_file_log." new;
/*	proc printto;*/
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

	%addobs:

	proc import datafile="&c_path_iter./&c_csv_CS..csv" out=&c_data_CS. replace dbms=csv;
	quit;

	run;

	proc sql;
		select name into : col_names separated by " "
			from dictionary.columns
				where memname = "&c_data_CS.";
	quit;

	%put &col_names.;

	data &c_data_CS.;
		set &c_data_CS.(obs=&c_no_clusters.);
	run;

	proc import datafile="&c_path_fetch./&c_csv_fetch..csv" out=&c_data_fetch. replace dbms=csv;
	quit;

	run;

	data _null_;
		call symput("c_add_obs_1",tranwrd("&c_add_observations."," ",","));
	run;

	%put &c_add_obs_1.;

	proc sql;
		create table final as
			select &c_fetch_variable. as Cluster,* from &c_data_fetch. where &c_var_key. in (&c_add_obs_1.);
	run;
	quit;

	data final(drop=cluster rename=(muRx_temp=Cluster));
		set final(keep=&col_names.);
		muRx_temp = compress(vvalue(Cluster));
	run;

	data &c_data_CS.(drop=cluster rename=(muRx_temp=Cluster));
		set &c_data_CS.;
		muRx_temp = vvalue(Cluster);
	run;

	proc append base=&c_data_CS. data=final;
	run;
	quit;

	data &c_data_CS.;
		set &c_data_CS.;
		retain Cluster &col_names.;
		Cluster = left(Cluster);
	run;

	%goto wf_a_addobs;

	%output:

	proc export data=CS outfile="&c_path_out./&c_csv_CS..csv" dbms=csv replace;
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
%mend segmentation_addobservations;

%segmentation_addobservations;
