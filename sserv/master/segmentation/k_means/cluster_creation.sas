/*------------------------------------------------------------------------------
sample parameters
------------------------------------------------------------------------------*/
/*%let c_path_in   = D:/data;*/
/*%let c_path_out  = D:/temp;*/
/*%let c_path_seed = ;*/
/**/
/*%let n_panel                 = 0;*/
/*%let c_val_subset_panel      = ;*/
/**/
/*%let c_var_in_cluster = acv black_hispanic sales chiller_flag sf1;*/
/**/
/*%let c_seed_replace_method = random;*/
/*%let n_radius              = 10;*/
/*%let n_seed                = 23456;*/
/**/
/*%let n_maxcluster = 10;*/
/*%let n_maxiter    = 10;*/
/*%let n_converge   = 0.02;*/
/*%let b_drift      = 0;*/
/*%let b_nomiss     = 0;*/
/*%let b_impute     = 0;*/
/*----------------------------------------------------------------------------*/

*processbody;
options mlogic mprint symbolgen;

proc printto log="&c_path_out./cluster_creation.log" new;
/*proc printto;*/
run;
quit;

%macro k_means;
	
	/*------------------------------------------------------------------------------
	preparing
	------------------------------------------------------------------------------*/
	/* deleting files */
	%let c_file_delete = 	&c_path_out./cluster_summary.csv#
							&c_path_out./ClusterMeans.csv#
							&c_path_out./completed.txt#
							&c_path_out./error.txt#
							&c_path_out./final_cluster.sas7bdat#
							&c_path_out./InitialSeeds.csv#
							&c_path_out./model_stats.csv#
							&c_path_out./outseed.sas7bdat#
							&c_path_out./VariableStats.csv#
							&c_path_out./warning.txt
							;

	%do tempi = 1 %to %sysfunc(countw(%str(&c_file_delete.), %str(#)));
		%let c_file_delete_now = %sysfunc(compress(%scan(%str(&c_file_delete.), &tempi., %str(#))));

		filename myfile "&c_file_delete_now.";

		data _null_;
			rc = fdelete('myfile');
		run;
	%end;

	/* clear the work library */
	proc datasets lib=work kill nolist;
	run;
	quit;

	/* assign library */
	libname in  "&c_path_in.";
	libname out "&c_path_out.";
	%if "&c_path_seed." ^= "" %then
		%do;
			libname seed "&c_path_seed.";
		%end;
		

	/* parameter play */
	%let c_data_seed = ;
	%let c_data_temp = murx_temp;
	%let c_var_subset_panel = ;
	%if &n_panel. > 0 %then %let c_var_subset_panel = grp&n_panel._flag;
	%let c_data = in.dataworking;
	%let c_data_prepared = dataworking_prepared;
	%let n_radius = 0;
	%let c_var_murx_key = primary_key_1644;

	/* preparing the data */
	data &c_data_prepared.(keep = &c_var_murx_key. &c_var_in_cluster.);
		set &c_data.;
		%if "&c_var_subset_panel." ^= "" %then %do;
			if &c_var_subset_panel. = "&c_val_subset_panel.";
		%end;
	run;
	
	%if &b_normalize. %then
		%do;
			proc stdize data=&c_data_prepared. out=&c_data_prepared. method=std;
				var &c_var_in_cluster.;
			run;
			quit;
		%end;

	%let c_data = &c_data_prepared.;
	/*----------------------------------------------------------------------------*/

	/*------------------------------------------------------------------------------
	selecting the seed source
	------------------------------------------------------------------------------*/
	%if &c_seed_source_type. = different %then
		%do;
			%let c_data_seed = seed.dataworking;
		%end;
	%if &c_seed_source_type. = kmeans %then
		%do;
			%let c_data_seed = seed.outseed;
		%end;
	%if &c_seed_source_type. = agglomerative %then
		%do;
			%if %sysfunc(exist(seed.outseed)) = 0 %then
				%do;
					proc import datafile="&c_path_seed./ClusterMeans.csv" out=&c_data_temp.;
					run;
					quit;

					proc transpose data=&c_data_temp. out=seed.outseed(drop=_NAME_ cluster);
						var mean;
						id variable;
						by cluster;
					run;
					quit;
				%end;

			%let c_data_seed = seed.outseed;
		%end;
	/*----------------------------------------------------------------------------*/
	
	/*------------------------------------------------------------------------------
	error check : nobs, seed dataset
	------------------------------------------------------------------------------*/
	%let n_dsid = %sysfunc(open(&c_data.));
    %let n_obs  = %sysfunc(attrn(&n_dsid., NOBS));
    %let n_rc   = %sysfunc(close(&n_dsid.));
	
	%if &n_obs. = 0 or &n_obs. = 1 %then %do;
		data _null_;
			v1= "The number of observations(N) is &n_obs. Hence cannot perform clustering. Expecting N >= 2";
			file "&c_path_out./error.txt";
			put v1;
		run;

		%goto the_end;
	%end;
	
	%if "&c_data_seed." ^= "" %then
		%do;
			%let n_dsid            = %sysfunc(open(&c_data_seed.));
			%let c_sep             = ;
			%let c_var_not_present = ;
			
			%do tempi = 1 %to %sysfunc(countw(%str(&c_var_in_cluster.), %str( )));
				%let c_var_in_cluster_now = %scan(%str(&c_var_in_cluster.), &tempi., %str( ));
				%let n_varnum = %sysfunc(varnum(&n_dsid., &c_var_in_cluster_now.));
				
				%if &n_varnum. = 0 %then
					%do;
						%let c_var_not_present = &c_var_not_present.&c_sep.&c_var_in_cluster_now.;
						%let c_sep = ,;
					%end;
			%end;
			
			%let rc       = %sysfunc(close(&n_dsid.));
			
			%if "&c_var_not_present." ^= "" %then
				%do;
					data _null_;
						v1 = "The variable(s) &c_var_not_present. are not present in the seed dataset.";
						file "&c_path_out./error.txt";
						put v1;
					run;
					
					%goto the_end;
				%end;
		%end;
	/*----------------------------------------------------------------------------*/
	
	/*------------------------------------------------------------------------------
	workflow : kmeans clustering
	------------------------------------------------------------------------------*/
	ods output ClusterSum          = cluster_summary;
	ods output InitialSeeds        = InitialSeeds;
	ods output MinDist             = MinDist;
	ods output VariableStat        = VariableStats;
	ods output ClusterCenters      = ClusterMeans;
	ods output CCC                 = ccc;

	proc fastclus
		data        = &c_data.
		out         = out.final_cluster
		cluster     = murx_n_cluster
		maxclusters = &n_maxcluster.
		maxiter     = &n_maxiter. 
		outseed     = out.outseed
		outstat     = outstat
		replace     = &c_seed_replace_method.
		%if "&c_seed_replace_method."  ^= "random" %then radius = &n_radius.;
		%if "&c_seed_replace_method."   = "random" && "&n_seed."      ^= "" %then random = &n_seed.;
		%if "&c_data_seed." ^= "" %then seed = &c_data_seed.;
		%if "&n_converge." ^= "" %then converge = &n_converge.;
		%if &b_drift.       = 1  %then drift;
		%if &b_nomiss.      = 1  %then nomiss;
		%if &b_impute.      = 1  %then impute;
		outiter
		;
		var &c_var_in_cluster.;
	run;
	quit;
	/*----------------------------------------------------------------------------*/

	/*------------------------------------------------------------------------------
	error check : n_cluster_formed
	------------------------------------------------------------------------------*/
	%let n_dsid = %sysfunc(open(InitialSeeds));
    %let n_obs  = %sysfunc(attrn(&n_dsid., NOBS));
    %let n_rc   = %sysfunc(close(&n_dsid.));
	
	%if &n_obs. = 1 %then %do;
		data _null_;
			v1= "The number of clusters formed is 1. Pls check the parameters given.";
			file "&c_path_out./error.txt";
			put v1;
		run;

		%goto the_end;
	%end;
	/*----------------------------------------------------------------------------*/
	
	/*------------------------------------------------------------------------------
	pre output
	------------------------------------------------------------------------------*/
	/*n_obs_available*/
	%let n_dsid           = %sysfunc(open(&c_data.));
    %let n_obs_available  = %sysfunc(attrn(&n_dsid., NOBS));
    %let n_rc             = %sysfunc(close(&n_dsid.));
	
	/*n_obs_used*/
	%if &b_nomiss. = 0 %then
		%do;
			%let n_obs_used = &n_obs_available.;
		%end;
	%if &b_nomiss. = 1 %then
		%do;
			%if &b_impute. = 0 %then
				%do;
					proc sql noprint;
						select count(murx_n_cluster) into: n_obs_used
							from out.final_cluster;
					run;
					quit;
				%end;
			%if &b_impute. = 1 %then
				%do;
					proc sql noprint;
						select count(murx_n_cluster) into: n_obs_used
							from out.final_cluster
								where _impute_ = 0;
					run;
					quit;
				%end;
		%end;
	
	/*n_iteration_run*/
	proc sql noprint;
		select (max(_iter_) - 1) into: n_iteration_run
			from out.outseed;
	run;
	quit;
	
	/*b_converge and taking only the last iterations cluster means from outseed*/
	data out.outseed;
		set out.outseed end=end;
		if _iter_ = &n_iteration_run. + 1;
		if end then 
			do;
				call symput("n_change", _change_);
				%if "&n_converge." ^= "" %then
					%do;
						call symput("b_converge", _change_ <= &n_converge.);
					%end;
			end;
	run;

/*	data yettobedecided;*/
/*		length label $100 value $50;*/
/*		label = "Number of Observations Available";*/
/*		value = compress("&n_obs_available.");*/
/*		output;*/
/*		label = "Number of Observations Used";*/
/*		value = compress("&n_obs_used.");*/
/*		output;*/
/*		label = "Number of Iterations Maximum";*/
/*		value = compress("&n_maxiter.");*/
/*		output;*/
/*		label = "Number of Iterations Run";*/
/*		value = compress("&n_iteration_run.");*/
/*		output;*/
/**/
/*		%if "&n_converge." ^= "" %then*/
/*			%do;*/
/*				label = "Convergence criterion";*/
/*				value = compress("&n_converge.");*/
/*				output;*/
/*				label = "Convergence criterion in iteration &n_iteration_run.";*/
/*				value = compress("&n_change.");*/
/*				output;*/
/*				label = "Convergence Status";*/
/*				%if &b_converge. = 1 %then*/
/*					%do;*/
/*						value = compbl("Convergence reached in &n_iteration_run. iterations");*/
/*					%end;*/
/*				%if &b_converge. = 0 %then*/
/*					%do;*/
/*						value = compbl("Convergence not reached in &n_iteration_run. iterations");*/
/*					%end;*/
/*				output;*/
/*			%end;*/
/**/
/*		label = "Initial Cluster Seed Selected From";*/
/*		%if %str(&c_initial_cluster_seed_selection.) = %str(Seed from Previous Iterations) %then*/
/*			%do;*/
/*				value = compbl("Final cluster means of muRx iteration*/
/*						%scan(%str(&c_path_seed.), -1, %str(/))");*/
/*			%end;*/
/*		%else*/
/*			%do;*/
/*				value = "Input dataset";*/
/*			%end;*/
/*		output;*/
/**/
/*		label = "Initial Cluster Seed Selection Method";*/
/*		%if %str(&c_initial_cluster_seed_selection.) = %str(Random Seeds) %then*/
/*			%do;*/
/*				value = "Random";*/
/*			%end;*/
/*		%if %str(&c_initial_cluster_seed_selection.) = %str(Sequential) %then*/
/*			%do;*/
/*				%if %str(&c_seed_replace_method.) = %str(None) %then*/
/*					%do;*/
/*						value = "Sequential with no replacement";*/
/*					%end;*/
/*				%else %if %str(&c_seed_replace_method.) = %str(Part) %then*/
/*					%do;*/
/*						value = "Sequential with partial replacement";*/
/*					%end;*/
/*				%else %if %str(&c_seed_replace_method.) = %str(Full) %then*/
/*					%do;*/
/*						value = "Sequential with full replacement";*/
/*					%end;*/
/*			%end;*/
/*		output;*/
/**/
/*		%if %str(&c_initial_cluster_seed_selection.) = %str(Sequential) %then*/
/*			%do;*/
/*				label = "Radius for Initial Cluster Seed Selection";*/
/*				value = "&n_radius.";*/
/*				output;*/
/*			%end;*/
/**/
/*		%if %str(&c_initial_cluster_seed_selection.) = %str(Random Seeds) %then*/
/*			%do;*/
/*				label = "Seed used for Random Number Generation for Initial Cluster Seed Selection";*/
/*				value = "&n_seed.";*/
/*				output;*/
/*			%end;*/
/*	run;*/
	/*----------------------------------------------------------------------------*/

	/*------------------------------------------------------------------------------
	output : model stats
	------------------------------------------------------------------------------*/
	data overall_rsqaure (rename =(Variable = Label RSquare = Value));
		set VariableStats ;
		where Variable = "OVER-ALL";
	run;

	proc transpose data=overall_rsqaure out=overall_rsquare1(drop=_name_ rename=(_label_=label col1=value));
	run;
	quit;

	data model_stats;
		set mindist overall_rsquare1 ccc;
		Label = tranwrd(Label,'=','');
		if Label="Total STD"  then call symput("n_total_sd",  value);
		if Label="Within STD" then call symput("n_within_sd", value);
		
	run; 

	data temp;
		length label $15;
		label = "Total_variance";
		value = &n_total_sd. * &n_total_sd.;
		output;
		label = "Within_variance";
		value = &n_within_sd. * &n_within_sd.;
		output;
	run;

	data model_stats;
		set model_stats temp;
	run;

	proc export data = model_stats outfile = "&c_path_out./model_stats.csv" dbms = CSV replace;
	run;
	quit;
	/*----------------------------------------------------------------------------*/

	/*------------------------------------------------------------------------------
	output : initial seeds
	------------------------------------------------------------------------------*/
	proc export data = InitialSeeds outfile = "&c_path_out./InitialSeeds.csv" dbms = CSV replace;
	run;
	quit;
	/*----------------------------------------------------------------------------*/

	/*------------------------------------------------------------------------------
	output : variable stats
	------------------------------------------------------------------------------*/
	proc export data = VariableStats outfile = "&c_path_out./VariableStats.csv" dbms = CSV replace;
	run;
	quit;
	/*----------------------------------------------------------------------------*/

	/*------------------------------------------------------------------------------
	output : cluster summary
	------------------------------------------------------------------------------*/
	data cluster_summary(drop = Flag);
		retain Cluster Freq cumulative_frequency StdDev Radius Nearest Gap;
		set cluster_summary;
		cumulative_frequency = sum(cumulative_frequency, freq);
	run;
		
	proc export data = cluster_summary outfile = "&c_path_out./cluster_summary.csv" dbms = CSV replace;
	run;
	quit;
	/*----------------------------------------------------------------------------*/

	/*------------------------------------------------------------------------------
	output : cluster means
	------------------------------------------------------------------------------*/
	proc export data = clustermeans outfile = "&c_path_out./ClusterMeans.csv" dbms = CSV replace;
	run;
	quit;
	/*----------------------------------------------------------------------------*/

	/*------------------------------------------------------------------------------
	output : cluster means csv for generating chart in the add observations tab
	------------------------------------------------------------------------------*/
	proc export data = clustermeans outfile = "&c_path_out./ClusterMeans_BasicProf.csv" dbms = CSV replace;
	run;
	quit;
	/*----------------------------------------------------------------------------*/

	/*------------------------------------------------------------------------------
	output : completed txt
	------------------------------------------------------------------------------*/
	data _null_;
		v1= "segmentation > k_means : completed ";
		file "&c_path_out./completed.txt";
		put v1;
	run;
	/*----------------------------------------------------------------------------*/

	%the_end:
%mend k_means;
%k_means;