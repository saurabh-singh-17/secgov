/*------------------------------------------------------------------------------
-- info ------------------------------------------------------------------------
macro name                       : muRx_binning
written by                       : vasanth mm 4261
date first created               : 24nov2014 1653
date last edited                 : ****
SAS version                      : SAS 9.2 on UNIX
purpose                          : takes in a dataset
			  					   creates a new dataset with the variable to be binned
			  					   bins that variable
			  					   returns the new dataset with the newly created binned variable
			  					   optionally copies specified variables to the new dataset
format                           : %muRx_binning(c_data_in   = ,
			  									 c_data_out  = ,
			  									 c_type_bin  = ,
			  									 c_var_bin   = ,
			  									 c_var_copy  = ,
			  									 c_var_new   = ,
			  									 n_bin       = ,
			  									 n_cutpoints = );
sub-macros called                : none yet
dataset(s) created               : &c_data_out.
limitations                      : hv to see
notes                            : first bin  : lower_cutpoint >= x >= higher_cutpoint
			  					   other bins : lower_cutpoint >  x >= higher_cutpoint
history                          : just born
sample macro call                : %muRx_binning(c_data_in=in.dataworking,
											     c_data_out=muRx_out,
											     c_type_bin=c,
											     c_var_bin=acv,
											     c_var_copy=,
											     c_var_new=bin3,
											     n_bin=3,
											     n_cutpoints=10000000 100000000);
-- required parameters ---------------------------------------------------------
c_data_in                        : input dataset
c_data_out                       : output dataset
c_type_bin                       : type of binning
c_var_bin                        : name of the variable to be binned
c_var_copy                       : name of the variable(s) to be copied to the output dataset
c_var_new                        : name of the variable that will be newly created
n_bin                            : number of bins
n_cutpoints                      : cutpoints
-- sample parameters -----------------------------------------------------------
c_data_in                        : <library>.<dataset>
c_data_out                       : <library>.<dataset>
c_type_bin                       : custom|c  |  dataset order|d  |  equal range|e  |  percentile|p
c_var_bin                        : <variable>
c_var_copy                       : <variable> <variable> ...
c_var_new                        : <variable>
n_bin                            : <integer>
n_cutpoints                      : <number> <number> ...
Consider including sample data/output to fully demonstrate how the macro should work.
------------------------------------------------------------------------------*/
%macro muRx_binning(c_data_in              = /* input dataset */,
					c_data_out             = /* output dataset */,
					c_type_bin             = /* c<ustom> | d<ataset order> | e<qual range> | p<ercentile> */,
					c_var_bin              = /* the variable to be binned */,
					c_var_copy             = /* extra variables to be copied to the output dataset */,
					c_var_new              = /* name to be given to the new variable created */,
					n_bin                  = /* no of bins to be created */,
					n_cutpoints            = /* cutpoints for custom binning, separated by space */);

%local c_data_in c_type_bin
	   c_var_bin c_var_dataset_order c_var_new
	   n_bin n_cutpoints;

%let c_data_temp                      = muRx_temp;
%let c_var_dataset_order              = muRx_dataset_order;
%let c_var_temp                       = muRx_temp;
%let c_type_bin                       = %lowcase(%substr(&c_type_bin., 1, 1));

/* error check */
/* if &c_data_in. exists */
/* if &c_type_bin. exists and is valid*/
/* if &c_var_bin. exists in the dataset and is numeric*/
/* if &c_var_new. exists and refers to no variable in the dataset */
/* if &n_bin. exists and is a valid integer */
/* if &n_cutpoints. exists(conditionally) and contains &n_bin. - 1 valid numbers */
					
%let n_dsid                           = %sysfunc(open(&c_data_in.));
%let n_obs                            = %sysfunc(attrn(&n_dsid., NOBS));
%let n_rc                             = %sysfunc(close(&n_dsid.));

%if "&c_type_bin." = "d" %then
	%do;
		data &c_data_out.(keep=&c_var_copy. &c_var_dataset_order.);
			set &c_data_in.(keep=&c_var_bin. &c_var_copy.);
			&c_var_dataset_order. = _N_;
		run;

		%let c_var_bin                = &c_var_dataset_order.;
		%let n_count_unique_var_bin   = &n_obs.;
	%end;
%else
	%do;
		data &c_data_out.;
			set &c_data_in.(keep=&c_var_bin. &c_var_copy.);
		run;

		proc sql noprint;
			select count(distinct(&c_var_bin.)) into: n_count_unique_var_bin
				from &c_data_out.;
		run;
		quit;
	%end;

%let n_bin                            = %sysfunc(min(&n_bin., &n_count_unique_var_bin.));

%if "&c_type_bin." = "p" %then
	%do;
		proc rank data=&c_data_out. out=&c_data_out. ties=low groups=&n_bin.;
			var &c_var_bin.;
			ranks &c_var_temp.;
		run;
		quit;
	%end;
%else
	%do;
		 %if "&c_type_bin." = "e" or "&c_type_bin." = "c" %then
		 	%do;
				proc sql noprint;
					select min(&c_var_bin.), max(&c_var_bin.) into :n_min, :n_max
						from &c_data_out.;
				run;
				quit;
			%end;
		%if "&c_type_bin." = "d" %then
			%do;
				%let n_min            = 1;
				%let n_max            = &n_obs.;
			%end;

		%if "&c_type_bin." = "d" or "&c_type_bin." = "e" %then
			%do;
				%let n_cutpoints      = &n_min.;
				%let n_jump           = %sysevalf((&n_max. - &n_min.) / &n_bin.);
				%do n_tempi = 1 %to %eval(&n_bin. - 1);
					%let n_cutpoints  = &n_cutpoints. %sysevalf(&n_min. + (&n_jump. * &n_tempi.));			
				%end;
				%let n_cutpoints      = &n_cutpoints. &n_max.;
			%end;
		%else %if "&c_type_bin." = "c" %then
			%do;
				%let n_cutpoints      = &n_min. &n_cutpoints. &n_max.;
			%end;

		data &c_data_out.;
			set &c_data_out.;
			%do n_tempi = 1 %to &n_bin.;
				%let n_previous = %scan(&n_cutpoints., &n_tempi., %str( ));
				%let n_now      = %scan(&n_cutpoints., %eval(&n_tempi. + 1), %str( ));

				%if &n_tempi. = 1 %then
					%do;
						if &c_var_bin. => &n_previous. and &c_var_bin. <= &n_now. then &c_var_temp. = &n_tempi.;
					%end;
				%else
					%do;
						if &c_var_bin. > &n_previous. and &c_var_bin. <= &n_now. then &c_var_temp. = &n_tempi.;
					%end;
			%end;
		run;
	%end;

%let c_var_copy_sql                   = ;
%let c_sep                            = ,;
%do n_tempi = 1 %to %sysfunc(countw(&c_var_copy., %str( )));
	%let c_var_copy_now               = %scan(&c_var_copy., &n_tempi., %str( ));
	%let c_var_copy_sql               = &c_var_copy_sql. &c_sep. d1.&c_var_copy_now.;
%end;

proc sql noprint;
	create table &c_data_temp. as
		select &c_var_temp., catx(" - ", min(&c_var_bin.), max(&c_var_bin.)) as &c_var_new., count(*) as muRx_count
			from &c_data_out.
				group by &c_var_temp.;
	create table &c_data_out. as
		select d2.&c_var_new. &c_var_copy_sql.
			from &c_data_out. d1
				left join &c_data_temp. d2
					on d1.&c_var_temp. = d2.&c_var_temp.;
run;
quit;

%the_end:

%mend muRx_binning;

*processbody;
options mlogic mprint symbolgen;

/*------------------------------------------------------------------------------
sample parameters
------------------------------------------------------------------------------*/
/*%let b_debug = 1;*/
/*%let codePath=/product-development/murx///SasCodes//8.7.1;*/
/*%let input_path=/product-development/murx///projects/vasanth_871_ah-17-Nov-2014-13-17-48/1;*/
/*%let dataset_name=dataworking;*/
/*%let output_path=/product-development/murx///projects/vasanth_871_ah-17-Nov-2014-13-17-48/1/NewVariable/Binning/4;*/
/*%let no_bins=5;*/
/*%let bin_type =dataset order;*/
/*%let analysis_var=HHs_Index_Income_75K_9999K;*/
/*%let new_variable=bin4;*/
/*%let datasetinfo_path=/product-development/murx///projects/vasanth_871_ah-17-Nov-2014-13-17-48/1/NewVariable/Binning/4;*/
/*%let genericCode_path=/product-development/murx///SasCodes//8.7.1/common;*/
/*----------------------------------------------------------------------------*/

%macro dp_nvc_bin_0;

%if %symexist(b_debug) = 0 %then
	%let b_debug                      = 0;

%global /* parameters */
		c_path_in c_path_out
		c_data_in
		c_var_bin c_var_new
		c_type_bin
		n_bin

		/* hardcoding */
		c_data_new
		c_var_key
		c_file_csv_new c_file_log c_file_txt_completed c_file_txt_error c_file_txt_warning
		n_cutpoints
		;

/* parameter play */
%let c_data_in                        = &dataset_name.;
%let c_path_in                        = &input_path.;
%let c_path_out                       = &output_path.;
%let c_type_bin                       = &bin_type.;
%let c_var_bin                        = &analysis_var.;
%let c_var_new                        = &new_variable.;
%let n_bin                            = &no_bins.;

/* hardcoding */
%let c_data_new                       = muRx_new;
%let c_data_temp                      = muRx_temp;
%let c_var_key                        = primary_key_1644;
%let c_file_csv_new                   = binning_subsetViewpane.csv;
%let c_file_log                       = binning.log;
%let c_file_txt_completed             = VARIABLE_BINNING_COMPLETED.txt;
%let c_file_txt_error                 = error.txt;
%let c_file_txt_warning               = warning.txt;
%let n_cutpoints                      = ;

/* check and change */
%if "%lowcase(&c_type_bin.)" = "custom" %then
	%do;
		libname custom xml "&c_path_out./custom_values.xml";

		proc sql noprint;
			select custom_values into :n_cutpoints separated by " "
				from custom.custom_values;
		run;
		quit;
	%end;

/* debug mode */
%if &b_debug. %then
	%do;
		proc printto;run;quit;
	%end;
%else
	%do;
		proc printto log="&c_path_out./&c_file_log." new;
		run;
		quit;
	%end;

/* libraries */
libname in "&c_path_in.";

%mend dp_nvc_bin_0;
%dp_nvc_bin_0;

%macro dp_nvc_bin;

/* workflow begins here */
%workflow:

%goto delete_files;
%wf_a_delete_files:

%goto prepare_c_data_new;
%wf_a_prepare_c_data_new:

%goto merge_c_data_new_c_data_in;
%wf_a_merge_c_data_new_c_data_in:

%goto output;
%wf_a_output:

%include "&genericCode_path./datasetprop_update.sas";

%goto completed;
%wf_a_completed:

%goto the_end;
/* workflow ends here */

%delete_files:

%let c_file_delete                    = &c_path_out./&c_file_txt_completed.#
										&c_path_out./&c_file_txt_error.#
										&c_path_out./&c_file_txt_warning.#
										&c_path_out./&c_file_csv_new.
										;

%do n_tempi = 1 %to %sysfunc(countw(%str(&c_file_delete.), %str(#)));
	%let c_file_delete_now = %sysfunc(compress(%scan(%str(&c_file_delete.), &n_tempi., %str(#))));

	filename myfile "&c_file_delete_now.";

	data _null_;
		rc = fdelete('myfile');
	run;
%end;

%goto wf_a_delete_files;

%prepare_c_data_new:

%muRx_binning(c_data_in=in.&c_data_in.,
			  c_data_out=&c_data_new.,
			  c_type_bin=%substr(&c_type_bin., 1, 1),
			  c_var_bin=&c_var_bin.,
			  c_var_copy=&c_var_key.,
			  c_var_new=&c_var_new.,
			  n_bin=&n_bin.,
			  n_cutpoints=&n_cutpoints.);

%goto wf_a_prepare_c_data_new;

%merge_c_data_new_c_data_in:

proc sql noprint;
	create table in.dataworking as
		select d1.*, d2.&c_var_new
			from in.dataworking d1
				left join &c_data_new. d2
					on d1.&c_var_key. = d2.&c_var_key.;
run;
quit;

%goto wf_a_merge_c_data_new_c_data_in;

%output:

%let murx_dsid      = %sysfunc(open(&c_data_new.));
%let murx_n_obs_new = %sysfunc(attrn(&murx_dsid., nobs));	
%let murx_rc        = %sysfunc(close(&murx_dsid.));

%if &murx_n_obs_new. > 6000 %then
	%do;
		proc surveyselect data=&c_data_new. out=&c_data_new. method=SRS sampsize=6000 SEED=1234567;
		run;
		quit;
	%end;

proc export data=&c_data_new. outfile= "&c_path_out./&c_file_csv_new." dbms=csv replace;
run;
quit;

%goto wf_a_output;

%completed:

data _null_;
	v1= "&c_txt_completed.";
	file "&c_path_out./&c_file_txt_completed.";
	put v1;
run;

%goto wf_a_completed;

%the_end:

%mend dp_nvc_bin;
%dp_nvc_bin;

