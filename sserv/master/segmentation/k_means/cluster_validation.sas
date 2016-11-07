/*------------------------------------------------------------------------------
sample parameters
------------------------------------------------------------------------------*/
/*%let c_path_in      = D:/data;*/
/*%let c_path_out     = D:/temp/out;*/
/*%let c_path_cluster = D:/temp;*/
/**/
/*%let c_var_subset_validation = ;*/
/*%let n_val_subset_validation = ;*/
/**/
/*%let c_var_in_cluster  = acv black_hispanic chiller_flag sales sf1;*/
/*%let c_var_in_selected = acv black_hispanic chiller_flag sales sf1;*/
/**/
/*%let b_stepdisc  = 0;*/
/*%let n_canonical = 3;*/
/*%let c_x_axis    = can1;*/
/*%let c_y_axis    = can2;*/
/*----------------------------------------------------------------------------*/

*processbody;
options mlogic mprint symbolgen;

proc printto log="&c_path_out./k_means_validation.log" new;
run;
quit;

%macro cluster_validation;

	/*defining the libraries*/
	libname in      "&c_path_in.";
	libname out     "&c_path_out.";
	libname cluster "&c_path_cluster";
	
	%let c_var_murx_cluster               = murx_n_cluster;
	%let n_dsid                           = %sysfunc(open(cluster.final_cluster));
	%let n_varnum                         = %sysfunc(varnum(&n_dsid., &c_var_murx_cluster.));
	%let n_rc                             = %sysfunc(close(&n_dsid.));
	%if &n_varnum. = 0 %then
		%let c_var_murx_cluster           = cluster;
	
	data tempdata(keep=&c_var_in_cluster. &c_var_in_selected. &c_var_murx_cluster.);
		merge in.dataworking cluster.final_cluster(keep=&c_var_murx_cluster.);
		%if "&c_var_subset_validation." ^= "" %then %do;
		 	if &c_var_subset_validation. = &n_val_subset_validation.;
		%end;
	run;

	proc sql noprint;
		select count(distinct(&c_var_murx_cluster.)) into:temp from tempdata;
	quit;

	%if &temp. =  1 %then %do;
		data _null_;
	     	 v1= "Validation set has only one level for cluster variable, cannot proceed with cluster validation";
	     	 file "&c_path_out./error.txt";
	      	 put v1;
	     run;
	%end;

	%macro outputcsv(inputname,outputname);
		proc export data=&inputname. outfile= "&c_path_out/&outputname..csv" dbms=csv replace;
		run;
		quit;
	%mend;

	%if &b_stepdisc. = 1 %then %do;
		ods output summary   = stepwise_sel_summary;
		ods output Variables = Default_Selections;

		proc stepdisc data = tempdata;
			class &c_var_murx_cluster.;
			var &c_var_in_cluster.;
		run;
		quit;

		proc contents data= Default_selections out=contents;	
		run;
		quit;
		
		data Default_Selections(keep=NAME);
			set contents;
			if compress(NAME) ^= "Type";
			if compress(NAME) ^= "Step";
		run;

		%outputcsv(stepwise_sel_summary,Stepwise_Selection_Summary);
		%outputcsv(Default_Selections,Default_Selections);

		data _null_;
			v1= "VALIDATE_CLUSTER_COMPLETED";
			file "&c_path_out./VALIDATE_CLUSTER_COMPLETED.txt";
			put v1;
		run;
	%end;
	%else %do;

		ods output CanonicalMeans=class_means;
		ods output RCoef=Canonical_coefficients_raw;
		ods output PStruc=Canonical_coefficients_pooled;
		ods output TCoef=Canonical_coefficients_total;

		proc candisc data=tempdata ncan=&n_canonical. out=report;
			class &c_var_murx_cluster.;
			var &c_var_in_selected.;
		run;
		quit;

		ods output LinearDiscFunc=Linear_Discriminant_Function;
		ods output ErrorResub=Error_Count;
		ods output DistGeneralized=Generalized_Squared_Distance;
		ods output ClassifiedResub=Resubstitution_Summary;

		proc discrim data=tempdata out=report2;
			class &c_var_murx_cluster.;
			var &c_var_in_selected.;
		run;
		quit;

		ods listing close;
		filename odsout "&c_path_out.";
		goptions reset=all border device=gif;
		ods html path=odsout gpath=odsout body="clusterplots.html" nogtitle;

		proc gplot data=report;
			plot &c_y_axis.*&c_x_axis. = &c_var_murx_cluster.;
		run;
		quit;

		%outputcsv(class_means,Class_Means);
		%outputcsv(Canonical_coefficients_raw,Canonical_Coefficients_Raw);
		%outputcsv(Canonical_coefficients_pooled,Canonical_Coefficients_Pooled);
		%outputcsv(Canonical_coefficients_total,Canonical_Coefficients_Total);
		%outputcsv(Linear_Discriminant_Function,Linear_Discriminant_Function);
		%outputcsv(Error_Count,Error_Count);
		%outputcsv(Generalized_Squared_Distance,Generalized_Squared_Distance);
		%outputcsv(Resubstitution_Summary,Resubstitution_Summary);

		data _null_;
			v1= "VALIDATION_PROCEED_COMPLETED";
			file "&c_path_out/VALIDATION_PROCEED_COMPLETED.txt";
			put v1;
		run;
	%end;
%mend cluster_validation;
%cluster_validation;