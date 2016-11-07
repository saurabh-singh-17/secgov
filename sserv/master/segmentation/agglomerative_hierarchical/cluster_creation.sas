*processbody;
option mlogic mprint symbolgen;

proc printto log="&c_path_out./cluster_creation.log" new;
/*proc printto;*/
run;
quit;

/*------------------------------------------------------------------------------
sample parameters
------------------------------------------------------------------------------*/
/*%let c_path_in                        = path of the inputs*/
/*%let c_path_out                       = path for the outputs*/
/**/
/*parameters for per group by*/
/*%let n_panel                          = no of the panel selected*/
/*%let c_val_subset_panel               = value of the panel selected*/
/**/
/*%let c_var_in_id                      = the id variable*/
/*%let c_var_in_freq                    = the frequency variable*/
/*%let c_var_in_rmsstd                  = the rmsstd variable*/
/*%let c_var_in_cluster                 = the clustering variables*/
/**/
/*%let c_clus_method                    = the method of clustering*/
/*%let b_dendrogram                     = indicator 1|0: dendrogram image*/
/*%let b_nosquare                       = indicator 1|0: nosquared euclidean distance*/
/*%let b_standardize                    = indicator 1|0: standardize the clustering variables*/
/*%let l_run_cluster                    = indicator true|false : run the clustering process*/
/**/
/*%let n_trim                           = trim option of proc cluster*/
/*%let n_k                              = k option of proc cluster*/
/*%let n_r                              = r option of proc cluster*/
/*%let n_penalty                        = penalty option of proc cluster*/
/*%let n_beta                           = beta option of proc cluster*/
/**/
/*%let n_last                           = if present, cluster history should be given for 1 to this no of clusters*/
/*%let n_cluster                        = if present, give the cluster summary and means for this no of clusters*/
/*----------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
sample parameters
------------------------------------------------------------------------------*/
/*%let c_path_in   = D:/data;*/
/*%let c_path_out  = D:/temp;*/
/**/
/*%let n_panel            = 0;*/
/*%let c_val_subset_panel = ;*/
/**/
/*%let c_var_in_id      = date;*/
/*%let c_var_in_freq    = ;*/
/*%let c_var_in_rmsstd  = ;*/
/*%let c_var_in_cluster = acv black_hispanic;*/
/**/
/*%let c_clus_method = average;*/
/*%let b_dendrogram  = 1;*/
/*%let b_nosquare    = 1;*/
/*%let b_standardize = 0;*/
/*%let l_run_cluster = true;*/
/**/
/*%let n_trim    = ;*/
/*%let n_k       = ;*/
/*%let n_r       = ;*/
/*%let n_penalty = ;*/
/*%let n_beta    = ;*/
/**/
/*%let n_last    = 10;*/
/*%let n_cluster = 2;*/
/*----------------------------------------------------------------------------*/

%macro agglomerative_hierarchical;	
	
	/*------------------------------------------------------------------------------
	preparing
	------------------------------------------------------------------------------*/
	/* clear the work library */
	proc datasets lib=work kill nolist;
	run;
	quit;

	/* assign library */
	libname in  "&c_path_in.";
	libname out "&c_path_out.";

	/* parameter play */
	%let c_data_in                    = in.dataworking;
	%let c_st_where                   =;
	%let c_var_key                    = primary_key_1644;
	%let c_var_subset_panel           =;

	/* creating the where statement in case of per group by */
	%if &n_panel. > 0 %then
		%do;
			%let c_var_subset_panel   = grp&n_panel._flag;
			%let c_st_where           = where = (&c_var_subset_panel. = "&c_val_subset_panel.");
		%end;
	%let c_st_keep                    = keep = &c_var_key. &c_var_in_id. &c_var_in_freq. &c_var_in_rmsstd. &c_var_in_cluster. &c_var_subset_panel.;

	/* if clustering doesnt need to be done, just go to the proc tree part to update some outputs */
	%if &l_run_cluster. = false %then
		%goto proc_tree;

	/* deleting the indicator files if they already exist*/
	FILENAME MyFile "&c_path_out./CLUSTER_MANUAL_REGRESSION_COMPLETED.txt";

	DATA _NULL_;
		rc = FDELETE('MyFile');
	RUN;

	FILENAME MyFile "&c_path_out./error.txt";

	DATA _NULL_;
		rc = FDELETE('MyFile');
	RUN;

	/*----------------------------------------------------------------------------*/

	/*------------------------------------------------------------------------------
	error check : nobs
	------------------------------------------------------------------------------*/
	%let n_dsid                       = %sysfunc(open(&c_data_in.));
	%let n_obs                        = %sysfunc(attrn(&n_dsid., NOBS));
	%let n_rc                         = %sysfunc(close(&n_dsid.));

	%if &n_obs. = 0 %then
		%do;

			data _null_;
				v1= "The number of observations(N) is 0. Hence cannot perform clustering. Expecting 6 <= N <= 65535";
				file "&c_path_out./error.txt";
				put v1;
			run;

			%goto the_end;
		%end;

	%if &n_obs. < 6 %then
		%do;

			data _null_;
				v1= "The number of observations(N) is less than 6. Hence cannot perform clustering. Expecting 6 <= N <= 65535";
				file "&c_path_out./error.txt";
				put v1;
			run;

			%goto the_end;
		%end;

	%if &n_obs. > 65535 %then
		%do;

			data _null_;
				v1= "The number of observations(N) is greater than 65535. Hence cannot perform clustering. Expecting 6 <= N <= 65535";
				file "&c_path_out./error.txt";
				put v1;
			run;

			%goto the_end;
		%end;

	/*----------------------------------------------------------------------------*/

	/*------------------------------------------------------------------------------
	workflow : agglomerative hierachical clustering
	------------------------------------------------------------------------------*/	
	ods output ClusterHistory = ClusterHistory;
	ods output SimpleStatistics = VariableStats;
	ods output rmsstd = rmsstd;
	ods output avdist = avdist;

	/* the procedure(proc) that does hierarchical clustering */
	proc cluster data = &c_data_in.(&c_st_keep. &c_st_where.) method = &c_clus_method. simple rsquare nonorm
		/* check the options the user has selected and use it in the proc  */
		%if &b_nosquare. = 1 %then
			%do;
				nosquare
			%end;

		%if &b_standardize       = 1 %then
			%do;
				std
			%end;

		%if "&c_clus_method."  ^= "single" %then
			%do;
				ccc pseudo
			%end;

		%if "&n_trim."          ^= "" %then
			%do;
				trim = &n_trim.
			%end;

		%if "&n_k."             ^= "" %then
			%do;
				K = &n_k.
			%end;

		%if "&n_r."             ^= "" %then
			%do;
				R = &n_r.
			%end;

		%if "&n_penalty."       ^= "" %then
			%do;
				penalty = &n_penalty.
			%end;

		%if "&n_beta."          ^= "" %then
			%do;
				beta = &n_beta.
			%end;
		/* the tree dataset is being output to get the dendrogram and cluster variable at a later stage */
		outtree = out.tree;

		/* if an id variable is selected */
		%if "&c_var_in_id."     ^= "" %then
			%do;
				id &c_var_in_id.;
			%end;

		/* if a frequency variable is selected */
		%if "&c_var_in_freq."   ^= "" %then
			%do;
				freq &c_var_in_freq.;
			%end;

		/* if a root mean square std variable is selected */
		%if "&c_var_in_rmsstd." ^= "" %then
			%do;
				rmsstd &c_var_in_rmsstd.;
			%end;

		/* the variables to be used for clustering */
		var &c_var_in_cluster.;

		/* extra variables to be copied to the output tree dataset */
		/* here we copy the key variable */
		/* to be used when a cluster variable is created */
		/* for merging it back to the original dataset */
		copy &c_var_key.;
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
	output : cluster history
	------------------------------------------------------------------------------*/
	%let n_dsid                       = %sysfunc(open(ClusterHistory));
	%let n_obs                        = %sysfunc(attrn(&n_dsid., NOBS));
	%let n_rc                         = %sysfunc(close(&n_dsid.));
	%let c_st_temp                    =;

	/* if the no of clusters are specified by the user, getting the cluster history only for those clusters */
	%if %str(&n_last.) ^= %str() %then
		%do;
			%let n_last               = %sysfunc(min(&n_last., &n_obs.));
			%let c_st_temp            = (obs=&n_obs. firstobs=%eval(&n_obs. - &n_last. + 1));
		%end;

	%if "&c_var_in_id." = "" %then
		%do;
			data ClusterHistory(drop=Idj1 Idj2 rename=(Idj111=ID1 Idj211=ID2));
				set ClusterHistory&c_st_temp.;
				if substr(compress(Idj1),1,1) in ("0","1","2","3","4","5","6","7","8","9") then
					Idj111=cat("OB", compress(Idj1));
				else Idj111=Idj1;

				if substr(compress(Idj2),1,1) in ("0","1","2","3","4","5","6","7","8","9") then
					Idj211=cat("OB", compress(Idj2));
				else Idj211=Idj2;
			run;
		%end;
	%else
		%do;
			data ClusterHistory(rename=(Idj1=ID1 Idj2=ID2));
				set ClusterHistory&c_st_temp.;
			run;
		%end;

	proc export data = ClusterHistory outfile = "&c_path_out/ClusterHistory.csv" dbms = CSV replace;
	run;
	quit;
	/*----------------------------------------------------------------------------*/

	/*------------------------------------------------------------------------------
	output : ccc pseudoF pseudoTSq
	------------------------------------------------------------------------------*/
	data ccc(keep = NumberOfClusters CubicClusCrit) PseudoF(keep = PseudoF NumberOfClusters) PseudoTSq(keep = PseudoTSq NumberOfClusters);
		set ClusterHistory;

		if CubicClusCrit ^= . then
			output ccc;

		if PseudoF ^= . then
			output PseudoF;

		if PseudoTSq ^= . then
			output PseudoTSq;
	run;

	proc export data = ccc outfile = "&c_path_out/ccc.csv" dbms = CSV replace;
	run;

	quit;

	proc export data = PseudoF outfile = "&c_path_out/PseudoF.csv" dbms = CSV replace;
	run;

	quit;

	proc export data = PseudoTSq outfile = "&c_path_out/PseudoTSq.csv" dbms = CSV replace;
	run;
	quit;
	/*----------------------------------------------------------------------------*/

	/*------------------------------------------------------------------------------
	output : proc tree
	------------------------------------------------------------------------------*/
	%proc_tree:

	/* if dendrogram option is not selected and if no of clusters is not given, skip the proc tree part */
	%if &b_dendrogram. = 0 and %str(&n_cluster.) = %str() %then
		%goto after_this;

	/* if dendrogram option is selected and if clustering was run, generate the dendrogram */
	%if &b_dendrogram. = 1 and &l_run_cluster. = true %then
		%do;
			ods graphics on;
			ods listing;
			filename grafout "&c_path_out./tree.jpeg";
			goptions reset=all device=jpeg gsfname=grafout gsfmode=replace;
		%end;
	
	proc tree data = out.tree dissimilar
		/* if no of clusters is given, output a dataset with the cluster variable */
		%if %str(&n_cluster.) ^= %str() %then
			%do;
				out = out.final_cluster nclusters = &n_cluster.
			%end;
		;
		/* if an id variable is selected */
		%if "&c_var_in_id." ^= "" %then
			%do;
				id &c_var_in_id.;
			%end;

		copy &c_var_key. &c_var_in_cluster.;
	run;
	quit;
	
	/* close the options enabled to generate the dendrogram */
	%if &b_dendrogram. = 1 and &l_run_cluster. = true %then
		%do;
			ods listing close;
			ods graphics off;
		%end;

	%after_this:

	/* if no of clusters is not given, consider the code completed */
	%if %str(&n_cluster.) = %str() %then
		%goto completed;
	/*----------------------------------------------------------------------------*/

	/*------------------------------------------------------------------------------
	output : cluster summary
	------------------------------------------------------------------------------*/
	ods output OneWayFreqs = cluster_freq (drop = Table F_CLUSTER);

	proc freq data = out.final_cluster;
		tables CLUSTER;
	run;
	quit;

	proc export data = cluster_freq outfile = "&c_path_out/cluster_summary.csv" dbms = CSV replace;
	run;
	quit;
	/*----------------------------------------------------------------------------*/

	/*------------------------------------------------------------------------------
	output : cluster means
	------------------------------------------------------------------------------*/
	proc means data=out.final_cluster missing noprint;
		class cluster;
		var &c_var_in_cluster.;
		output out=cluster_means;
	run;
	quit;

	proc transpose data=cluster_means out=trans_cluster_means(rename=(_name_=variable cluster=cluster n=n mean=mean std=std_dev min=minimum max=maximum));
		var &c_var_in_cluster.;
		by cluster _type_;
		id _stat_;
	run;
	quit;

	data trans_cluster_means(drop=_type_ _label_);
		retain variable cluster n mean std_dev minimum maximum;
		set trans_cluster_means;

		if _type_ ^= 0 and cluster ^= .;
	run;

	proc export data = trans_cluster_means outfile = "&c_path_out/ClusterMeans.csv" dbms = CSV replace;
	run;
	quit;
	/*----------------------------------------------------------------------------*/
	%completed:

	/*------------------------------------------------------------------------------
	output : completed txt
	------------------------------------------------------------------------------*/
	data _null_;
		v1= "segmentation > agglomerative_hierarchical : completed";
		file "&c_path_out./completed.txt";
		put v1;
	run;
	/*----------------------------------------------------------------------------*/

	%the_end:

%mend agglomerative_hierarchical;

%agglomerative_hierarchical;
