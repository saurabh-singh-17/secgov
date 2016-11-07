/*Sample Parameters*/

/*%let codePath=/product-development/murx///SasCodes//8.7;*/
/*%let c_path_in=/product-development/murx///projects/Nida_KMeans-5-Aug-2014-15-49-41/1;*/
/*%let c_path_out=/product-development/murx///projects/Nida_KMeans-5-Aug-2014-15-49-41/1/0/1_1_1/KMEANS/1/1;*/
/*%let c_path_iter=/product-development/murx///projects/Nida_KMeans-5-Aug-2014-15-49-41/1/0/1_1_1/KMEANS/1/1;*/
/*%let c_var_in_addvar=Chiller_flag HHs_55_64 HHs_Index_Income_75K_9999K Hispanic_HHs_Index */
/*P164_Demand_Index P26_Demand_Index Total_Selling_Area;*/

options mlogic mprint symbolgen;

%macro segmentation_addvariable;
	/* workflow */
	%goto parameter_play;
	%wf_a_parameter_play:

	%goto delete_files;
	%wf_a_delete_files:

	%goto addvar;
	%wf_a_addvar:

	%goto output;
	%wf_a_output:

	%goto completed;
	%wf_a_completed:

	%goto the_end;
/*	 workflow ends */

	%parameter_play:

	/* hardcoding */
	%let c_csv_addvar          = addvar;
	%let c_data_addvar         = addvar;
	%let c_data_newavgs        = new_avgs;
	%let c_csv_CS 			   = ClusterMeans_BasicProf;
	%let c_data_CS             = CS;
	%let c_data_iter           = final_cluster;
	%let c_data_in             = dataworking;
	%let c_file_log            = &c_path_out./seg_km_addvar.log;
	%let c_txt_completed       = completed;
	%let c_txt_error           = error;
	%let c_txt_warning         = warning;
	%let c_var_cluster         = murx_n_cluster;
	%let c_var_key             = primary_key_1644;

	/* the play */
	%let c_file_delete		   =	&c_path_out./&c_txt_completed..txt#
									&c_path_out./&c_txt_error..txt#
									&c_path_out./&c_txt_warning..txt#
									&c_path_out./&c_csv_addvar..csv;

	/* libraries */
	libname in   "&c_path_in.";
	libname out  "&c_path_out.";
	libname iter "&c_path_iter.";

	proc printto log="&c_file_log." new;
	run;
	quit;

/*	proc printto;*/
/*	run;*/
/*	quit;*/
	
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
%addvar:

data _null_;
	call symput("c_var_in_addvar",compbl("&c_var_in_addvar."));
	run;
	%put &c_var_in_addvar.;

data _null_;
	call symput("c_var_in_addvar_1",cat("a.","&c_var_in_addvar."));
	run;
	%put &c_var_in_addvar_1.;

	data _null_;
	call symput("c_var_in_addvar_1",tranwrd("&c_var_in_addvar_1."," ",",a."));
	run;
	%put &c_var_in_addvar_1.;


	proc sql;
	create table &c_data_addvar. as
	select &c_var_in_addvar_1.,&c_var_cluster. from in.&c_data_in. as a join iter.&c_data_iter. as b
	on a.&c_var_key.=b.&c_var_key.;
	run;
	quit;

	data _null_;
	call symput("avg_func","");
	run;
	
	%do i = 1 %to %sysfunc(countw("&c_var_in_addvar."," "));
		%if &i. > 1 %then %do;
		data _null_;
		call symput("avg_func",cat("&avg_func.",","));
		run;
		%end;	
		%put &avg_func.;
	%let var_i = %scan("&c_var_in_addvar.",&i.," ");
	data _null_;
	call symput("avg_func",cat("&avg_func.","avg(","&var_i.",")","as &var_i."));
	run;
	%put &avg_func.;
	%end;

	proc sql;
	create table final as
	select &c_var_cluster. as Cluster,&avg_func. from &c_data_addvar. group by &c_var_cluster.;
	run;
	quit;
	
	
	%goto wf_a_addvar;

	%output:

	proc export data=final outfile="&c_path_iter./&c_csv_CS..csv" dbms=csv replace;
	run;
	quit;

	proc export data=final outfile="&c_path_out./&c_csv_addvar..csv" dbms=csv replace;
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
%mend segmentation_addvariable;
%segmentation_addvariable;