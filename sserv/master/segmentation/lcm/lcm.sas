*processbody;

proc datasets lib = work kill;
run;
quit;

options mlogic symbolgen spool;

proc printto log="&output_path./lcm.log" new;run;quit;
/*proc printto;run;quit;*/

/*%let input_path=D:/data;                           	/* <path> */*/
/*%let output_path=D:/temp;							/* <path> */*/
/*%let grp_flag=1_1_1; 								/* <flag> */*/
/*%let grp_no=0; 										/* <number> */*/
/*%let group_path=D:/temp;							/* <path> */*/
/*%let model_iteration=1; 							/* <number> */*/
/*%let dataset_name=lcmdata2;		 					/* <dsn> */*/
/*%let nofclusters=3; 								/* <number> */*/
/*%let maxiter=25; 									/* <number> */*/
/*%let converge=0.01; 								/* <number> / <blank> */*/
/*%let rerun=1; 										/* <number> */*/
/*%let seed=46768; 									/* <number> / <blank> */*/
/**/
/*%let independent_var = x;						 	/* <var> */*/
/*%let dependent_var = y; 							/* <var> */*/
/*%let id_var = id; 									/* <var> / <blank> */*/
/*%let validation_var = ;								/* <var> / <blank> */*/
/**/
/*%let buildvalidation = build;						/* build / validation */*/
/*%let validationtype  = validation; 					/* validation / <blank> */*/;



/*------------------------------------------------------------------------------
parameter play
------------------------------------------------------------------------------*/
%macro lcm_parameter_play;

	%global n_seed n_ll_cutoff c_var_id c_path_input c_path_output c_path_group c_dataset_name
			n_cluster n_max_iter_em n_rerun n_seed c_var_validation
			c_var_independent c_var_dependent n_grp_no c_grp_flag b_validation
			c_validation_on c_path_finalprob;

	%let c_path_input   = &input_path.;
	%let c_path_output  = &output_path.;
	%let c_path_group   = &group_path.;
	%let c_dataset_name = &dataset_name.;
	%let n_cluster      = &nofclusters.;
	%let n_max_iter_em  = &maxiter.;
	%let n_rerun        = &rerun.;
	%let n_seed         = &seed.;
	%let n_ll_cutoff    = &converge.;
	%let n_grp_no       = &grp_no.;
	%let c_grp_flag     = &grp_flag.;

	%if "&validation_var." ^= "" %then
		%do;
			%let c_var_validation = %sysfunc(compbl(&validation_var.));
		%end;
	%else
		%do;
			%let c_var_validation = ;
		%end;
	%if "&id_var." ^= "" %then 
		%do;
			%let c_var_id = %sysfunc(compbl(&id_var.));
		%end;
	%else
		%do;
			%let c_var_id = ;
		%end;
	%let c_var_independent = %sysfunc(compbl(&independent_var.));
	%let c_var_dependent   = %sysfunc(compbl(&dependent_var.));
	%let b_validation      = 0;
	%if &buildvalidation. = validation %then
		%do;
			%let b_validation     = 1;
			%let n_max_iter_em    = 1;
			%if &validationtype. = validation %then %let c_validation_on  = validation;
			%else %let c_validation_on  = entire;
			%let c_path_finalprob = &finalprob_path.;
		%end;
	/*----------------------------------------------------------------------------*/

	%if &n_rerun. > 1 %then
		%do;
			data _null_;
				call symput("n_seed", ceil(rand("Uniform")*100000));
			run;
		%end;
	%else %if "&n_seed." = "" %then
		%do;
			data _null_;
				call symput("n_seed", ceil(rand("Uniform")*100000));
			run;
		%end;
		
	%if "&n_ll_cutoff." = "" %then %let n_ll_cutoff=0;

	%if "&c_var_id." = "" %then %let c_var_id = primary_key_1644;

%mend lcm_parameter_play;
/*----------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------
preparing the data to perform lcm
------------------------------------------------------------------------------*/
%macro lcm_pre_lcm(c_data_dataworking,
				   c_var_independent,
				   c_var_dependent,
			   	   c_var_id,
			   	   c_var_validation,
			   	   n_grp_no,
			   	   c_grp_flag);

	/*take only the necessary rows and columns*/
	/*create a columns i_d_v_a_r containing the values from &c_var_id.*/
	data lcm_pre_lcm(keep = &c_var_independent. &c_var_dependent. &c_var_validation. i_d_v_a_r);
		set &c_data_dataworking.;
		%if &n_grp_no. ^= 0 %then
			%do;
				if grp&n_grp_no._flag = "&c_grp_flag.";
			%end;
		%if &b_validation. = 0 %then
			%do;
				%if "&c_var_validation." ^= "" %then
					%do;
						if &c_var_validation. = 1;
					%end;
			%end;
		i_d_v_a_r = &c_var_id.;
	run;

%mend lcm_pre_lcm;
/*----------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------
generate initial probabilities
------------------------------------------------------------------------------*/
%macro lcm_initial_prob(c_data_lcm_pre_lcm,
						c_var_id,
						n_cluster,
						n_seed);

	/*get the distinct IDs*/
	proc sql noprint;
		create table lcm_initial_prob as
			select distinct(&c_var_id.) as &c_var_id.
				from &c_data_lcm_pre_lcm.;
	run;
	quit;

	/*for every ID, generate one random number per cluster*/
	data lcm_initial_prob;
		set lcm_initial_prob;
		%do tempi = 1 %to &n_cluster.;
			prob_cluster_&tempi. = ranuni(&n_seed.);
		%end;
		output;
	run;

	/*creating a temporary macro variable to be used in the below data step*/
	%let temp_for_sum = 0;
	%do tempi = 1 %to &n_cluster.;
		%let temp_for_sum = &temp_for_sum., prob_cluster_&tempi.;
	%end;

	/*for every ID, divide the random numbers by the sum of all the random numbers*/
	/*converting the random numbers into probabilities*/
	data lcm_initial_prob(drop = sum);
		set lcm_initial_prob;
		sum = sum(&temp_for_sum.);
		%do tempi = 1 %to &n_cluster.;
			prob_cluster_&tempi. = prob_cluster_&tempi. / sum;
		%end;
	run;

%mend lcm_initial_prob;
/*----------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------
map the probabilities of the previos iteration to pre_lcm data
------------------------------------------------------------------------------*/
%macro lcm_map_prob(c_data_lcm_pre_lcm,
		  		c_data_prob,
		 		c_var_by);

	proc sql noprint;
		create table &c_data_lcm_pre_lcm. as
			select coalesce(a1.i_d_v_a_r, a2.i_d_v_a_r) as i_d_v_a_r, *
				from &c_data_prob. a1 right join &c_data_lcm_pre_lcm. a2
					on a1.i_d_v_a_r = a2.i_d_v_a_r;
	run;
	quit;

%mend lcm_map_prob;
/*----------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------
for every cluster, create the weight variable
------------------------------------------------------------------------------*/
%macro lcm_weight_var(c_data_lcm_pre_lcm,
					  n_cluster);
	data &c_data_lcm_pre_lcm.;
		set &c_data_lcm_pre_lcm.;
		%do tempi = 1 %to &n_cluster.;
			if prob_cluster_&tempi. < 1E-128 then prob_cluster_&tempi. = 1E-128;
			weight_cluster_&tempi. = prob_cluster_&tempi.;
		%end;
	run;

%mend lcm_weight_var;
/*----------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------
build a model for each cluster with the reciprocal of the cluster probabilities as weight
	keep track of the residuals, ll, weightedmean(resid), weightedstd(resid) and the beta values
------------------------------------------------------------------------------*/
%macro lcm_proc_genmod(c_data_lcm_pre_lcm,
					   c_var_dependent,
					   c_var_independent,
					   c_var_weight,
					   c_data_out_parameterestimates,
					   c_data_out_out,
					   c_var_out_pred,
					   c_var_out_resraw);

	ods output modelfit = modelfit;
	ods output parameterestimates = &c_data_out_parameterestimates.;

	proc genmod data=&c_data_lcm_pre_lcm. namelen=32;
		weight &c_var_weight.;
		model &c_var_dependent. = &c_var_independent.;
		output out=&c_data_out_out.
			   pred=&c_var_out_pred.
			   resraw=&c_var_out_resraw.;
	run;
	quit;

%mend lcm_proc_genmod;
/*----------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------
generate probabilities
------------------------------------------------------------------------------*/
%macro lcm_calc_prob(c_data_lcm_pre_lcm,
					 c_data_out_prob,
					 n_cluster,
					 c_var_id);

	/*creating a temporary macro variable to be used in the below proc sql part*/
	%let temp_for_product = ;
	%let sep = ;
	%do tempi = 1 %to &n_cluster.;
		%let temp_for_product = &temp_for_product. &sep. exp(sum(log(pdf("NORMAL", resraw_&tempi., &&resraw_&tempi._mean., &&resraw_&tempi._stddev.)))) as prob_cluster_&tempi.;
		%let sep = ,;
	%end;

	/*calculating the measures that will give probabilities*/
	proc sql noprint;
		create table &c_data_out_prob. as
			select &temp_for_product., &c_var_id.
				from &c_data_lcm_pre_lcm.
					group by &c_var_id.;
	run;
	quit;

	
	%do tempi = 1 %to &n_cluster.;
		%let temp_sum_all = 0;
		proc sql noprint;
			select sum(prob_cluster_&tempi.) into: temp_sum_&tempi.
				from &c_data_out_prob.;
		run;
		quit;
		
		%let temp_sum_all = %sysevalf(&temp_sum_all. + &&temp_sum_&tempi..);
	%end;

	

	/*creating a temporary macro variable to be used in the below data step*/
	%let temp_for_sum = 0;
	%do tempi = 1 %to &n_cluster.;
		%let temp_for_sum = &temp_for_sum., prob_cluster_&tempi.;
		%let temp_sum_&tempi. = %sysevalf(&&temp_sum_&tempi.. / &temp_sum_all.);
	%end;

	/*for every ID, divide the random numbers by the sum of all the random numbers*/
	/*converting the random numbers into probabilities*/
	data &c_data_out_prob.(drop = sum);
		set &c_data_out_prob.;
		%do tempi = 1 %to &n_cluster.;
			prob_cluster_&tempi. = prob_cluster_&tempi. * &&temp_sum_&tempi..;
		%end;
		sum = sum(&temp_for_sum.);
		%do tempi = 1 %to &n_cluster.;
			prob_cluster_&tempi. = prob_cluster_&tempi. / sum;
		%end;
	run;

%mend lcm_calc_prob;
/*----------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------
create the cluster variable, predicted & residual in lcm_pre_lcm dataset
------------------------------------------------------------------------------*/
%macro lcm_cluster_var_creation(c_data_lcm_prob,
								c_data_lcm_pre_lcm,
								c_var_id,
								n_cluster,
								c_var_out_cluster,
								c_var_out_resid,
								c_var_out_predicted);

	/*creating a temporary macro variable to be used in the below data step*/
	%let temp_for_max = 0;
	%do tempi = 1 %to &n_cluster.;
		%let temp_for_max = &temp_for_max., prob_cluster_&tempi.;
	%end;

	/*finding out the maximum probability*/
	data temp;
		set &c_data_lcm_prob.;
		m_a_x = max(&temp_for_max.);
	run;

	/*merging this m_a_x with lcm_pre_lcm data*/
	proc sql noprint;
		create table &c_data_lcm_pre_lcm. as
			select *
				from temp a1 right join &c_data_lcm_pre_lcm. a2
					on a1.&c_var_id. = a2.&c_var_id.;
	run;
	quit;

	/*creating the cluster, predicted & residual columns*/
	data &c_data_lcm_pre_lcm.;
		set &c_data_lcm_pre_lcm.;
		%do tempi = 1 %to &n_cluster.;
			if m_a_x = prob_cluster_&tempi then
				do;
					&c_var_out_cluster.   = &tempi.;
					&c_var_out_resid.     = resraw_&tempi.;
					&c_var_out_predicted. = pred_&tempi.;
				end;
		%end;
	run;

%mend lcm_cluster_var_creation;
/*----------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------
output 3 : variablesummary.csv
------------------------------------------------------------------------------*/
%macro variablesummary(c_data_lcm_pre_lcm,
					   c_var_independent,
					   c_var_cluster);

	%let temp_for_mean = ;
	%let temp_for_stddev = ;
	%let sep = ;
	%do tempi = 1 %to %sysfunc(countw(&c_var_independent., %str( )));
		%let c_current_independent_var = %scan(&c_var_independent., &tempi., %str( ));

		%let temp_for_mean = &temp_for_mean. &sep. mean(&c_current_independent_var.) as &c_current_independent_var.;
		%let temp_for_stddev = &temp_for_stddev. &sep. std(&c_current_independent_var.) as &c_current_independent_var.;
		%let sep = , ;
	%end;

	proc sql noprint;
		create table temp as
			select &temp_for_mean., &c_var_cluster.
				from lcm_pre_lcm
					group by &c_var_cluster.;
	run;
	quit;

	proc transpose data = temp out = variablesummary_mean name = variable prefix = mean_cluster_;
		id &c_var_cluster.;
	run;
	quit;

	proc sql noprint;
		create table temp as
			select &temp_for_stddev., &c_var_cluster.
				from lcm_pre_lcm
					group by &c_var_cluster.;
	run;
	quit;

	proc transpose data = temp out = variablesummary_stddev name = variable prefix = std_cluster_;
		id &c_var_cluster.;
	run;
	quit;

	proc sql noprint;
		create table variablesummary as
			select *
				from variablesummary_mean a1 inner join variablesummary_stddev a2
					on a1.variable = a2.variable;
	run;
	quit;

%mend variablesummary;
/*----------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------
output 4 : clustersummary.csv
------------------------------------------------------------------------------*/
%macro clustersummary(c_data_lcm_pre_lcm,
					  c_var_cluster,
					  n_cluster);

	data clustersummary_meanresid;
		length label $100;
		label = "Mean of Residuals";
		%do tempi = 1 %to &n_cluster;
			cluster_&tempi. = &&resraw_&tempi._mean.;
		%end;
	run;

	data clustersummary_stddevresid;
		length label $100;
		label = "Standard Deviation of Residuals";
		%do tempi = 1 %to &n_cluster;
			cluster_&tempi. = &&resraw_&tempi._stddev.;
		%end;
	run;

	proc sql noprint;
		create table temp as
			select count(*) as nobs, &c_var_cluster.
				from &c_data_lcm_pre_lcm.
					group by &c_var_cluster.;
	run;
	quit;

	proc transpose data = temp out = clustersummary_nobs name = label prefix = cluster_;
		id &c_var_cluster.;
	run;
	quit;

	data clustersummary_nobs;
		length label $100;
		set clustersummary_nobs;
		label = "Number of Observations";
	run;

	%let temp_for_sum = 0;
	%let temp_for_format = ;
	%do tempi = 1 %to &n_cluster;
		%let temp_for_sum = &temp_for_sum., cluster_&tempi.;
		%let temp_for_format = &temp_for_format. cluster_&tempi.;
	%end;

	data clustersummary_percent(drop = sum);
		length label $100;
		set clustersummary_nobs;
		label = "Percentage of Observations";
		sum = sum(&temp_for_sum.);
		%do tempi = 1 %to &n_cluster;
			cluster_&tempi. = (cluster_&tempi. / sum) * 100;
		%end;
	run;

	%do tempi = 1 %to &n_cluster;

		data temp1(rename = (parameter = label estimate = cluster_&tempi.));
			length parameter $100;
			set parameterestimates_&tempi.(keep = parameter estimate);
			parameter = "Beta Estimate of "||parameter;
		run;

		data temp2(rename = (parameter = label stderr = cluster_&tempi.));
			length parameter $100;
			set parameterestimates_&tempi.(keep = parameter stderr);
			parameter = "Standard Error of "||parameter;
		run;

		data temp;
			set temp1 temp2;
		run;

		%if &tempi. = 1 %then
			%do;
				data clustersummary;
					set temp;
				run;
			%end;
		%else
			%do;
				proc sql noprint;
					create table clustersummary as
						select *
							from clustersummary a1 inner join temp a2
								on a1.label = a2.label;
				run;
				quit;
			%end;

	%end;

	data clustersummary;
		length label $100;
		format &temp_for_format. best12.;
		set clustersummary_nobs clustersummary_percent clustersummary_meanresid clustersummary_stddevresid clustersummary;
	run;

%mend clustersummary;
/*----------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------
output 5 : modelstats.csv
------------------------------------------------------------------------------*/
%macro modelstats(c_data_lcm_pre_lcm,
				  c_var_cluster,
				  c_var_dependent);

	ods output overallanova = overallanova;

	proc anova data = lcm_pre_lcm;
		class &c_var_cluster.;
		model &c_var_dependent. = &c_var_cluster.;
	run;
	quit;

	data _null_;
		set overallanova;
		if source = "Model" then call symput("betweengroupvariance",ms);
		if source = "Error" then call symput("withingroupvariance",ms);
	run;

	data _null_;
		call symput("totalvariance", &betweengroupvariance. + &withingroupvariance.);
		call symput("witbybetvariance", &withingroupvariance. / &betweengroupvariance.);
	run;

	data _null_;
		call symput("totalstddev", sqrt(&totalvariance.));
		call symput("withingroupstddev", sqrt(&withingroupvariance.));
	run;

	data _null_;
		set modelfit(obs = 1);
		call symput("DF", DF);
	run;

	data _null_;
		call symput("AIC", (-2 * &lcm_ll.) + (2 * &DF.));
		call symput("BIC", (-2 * &lcm_ll.) + (&DF. * log(&DF.)));
	run;

	%let temp_for_keep = ;
	%do tempi = 1 %to &n_cluster.;
		%let temp_for_keep = &temp_for_keep. prob_cluster_&tempi.;
	%end;

	data temp;
		set lcm_pre_lcm(keep = &temp_for_keep.);
		%do tempi = 1 %to &n_cluster.;
			log_prob_cluster_&tempi. = log(prob_cluster_&tempi.);
		%end;
	run;

	ods output summary = summary;

	proc means data = temp sum;
	run;
	quit;

	%let temp_for_sum_sum_log_prob = ;
	%let temp_for_sum_log_sum_prob = ;
	%let sep = ;
	%do tempi = 1 %to &n_cluster.;
		%let temp_for_sum_sum_log_prob = &temp_for_sum_sum_log_prob. &sep. log_prob_cluster_&tempi._sum;
		%let temp_for_sum_log_sum_prob = &temp_for_sum_log_sum_prob. &sep. log(prob_cluster_&tempi._sum);
		%let sep = +;
	%end;

	proc sql noprint;
		select &temp_for_sum_sum_log_prob. into: sum_sum_log_prob
			from summary;
		select &temp_for_sum_log_sum_prob. into: sum_log_sum_prob
			from summary;
	run;
	quit;

	data t_modelstats;
		AIC = &AIC.;
		BIC = &BIC.;
		G2 = &sum_sum_log_prob. + &sum_log_sum_prob.;
		LogLikelihood = &lcm_ll.;
		TotalVariance = &totalvariance.;
		WithinGroupVariance = &withingroupvariance.;
		BetweenGroupVariance = &betweengroupvariance.;
		WithinByBetweenVariance = &witbybetvariance.;
		TotalStddev = &totalstddev.;
		WithinGroupStddev = &withingroupstddev.;
	run;

	proc transpose data = t_modelstats out = modelstats name = label;
	run;
	quit;

	data modelstats(rename = (col1 = value));
		length label $ 32;
		set modelstats;
		if label = "LogLikelihood" then label = "Log Likelihood";
		if label = "TotalVariance" then label = "Total Variance";
		if label = "WithinGroupVariance" then label = "Within Variance";
		if label = "BetweenGroupVariance" then label = "Between Variance";
		if label = "WithinByBetweenVariance" then label = "Within/Between Variance";
		if label = "TotalStddev" then label = "Total Standard Deviation";
		if label = "WithinGroupStddev" then label = "Within Standard Deviation";
	run;

%mend modelstats;
/*----------------------------------------------------------------------------*/


/*------------------------------------------------------------------------------
LCM workflow
------------------------------------------------------------------------------*/
%macro lcm_workflow;
	%lcm_parameter_play;

	libname in "&c_path_input.";
	libname out "&c_path_output.";
	libname group "&c_path_group.";

	/* waste copy of data - should remove this ASAP */
	data group.bygroupdata;
		set in.&c_dataset_name.;
	run;

	%lcm_pre_lcm(c_data_dataworking=in.&c_dataset_name.,
		 	     c_var_independent=&c_var_independent.,
		     	 c_var_dependent=&c_var_dependent.,
		     	 c_var_id=&c_var_id.,
		     	 c_var_validation=&c_var_validation.,
		     	 n_grp_no=&n_grp_no.,
		     	 c_grp_flag=&c_grp_flag.);

	/* creating initial prob */
	%if &b_validation. = 1 %then
		%do;

			/* for the validation part of the sample, 
				substituting the values of dependent variable by missing values
				so the model wont consider those observations when building the model */
			data lcm_pre_lcm;
				set lcm_pre_lcm;
				murx_temp1 = &c_var_dependent.;
				if &c_var_validation. = 0 then
					do;
						&c_var_dependent. = .;
					end;

			run;

			libname temp "&c_path_finalprob.";

			%let c_data_prob = temp.finalprob;

			%lcm_map_prob(c_data_lcm_pre_lcm=lcm_pre_lcm,
					  c_data_prob=&c_data_prob.,
					  c_var_by=i_d_v_a_r);

			data copy_lcm_pre_lcm1;
				set lcm_pre_lcm;
			run;

			/* for every cluster, create the weight variable */
			%lcm_weight_var(c_data_lcm_pre_lcm=lcm_pre_lcm,
						n_cluster=&n_cluster.);

			/* build a model for each cluster with the reciprocal of the cluster probabilities as weight
			keep track of the residuals, ll, weightedmean(resid), weightedstd(resid) and the beta values */
			%do tempi = 1 %to &n_cluster.;
				
				%lcm_proc_genmod(c_data_lcm_pre_lcm=lcm_pre_lcm,
							     c_var_dependent=&c_var_dependent.,
								 c_var_independent=&c_var_independent.,
								 c_var_weight=weight_cluster_&tempi.,
								 c_data_out_parameterestimates=parameterestimates_&tempi.,
								 c_data_out_out=out_&tempi.,
								 c_var_out_pred=pred_&tempi.,
								 c_var_out_resraw=resraw_&tempi.);

				/*merging these two datasets to get the residuals and predicted in the lcm_pre_lcm data*/
				data lcm_pre_lcm;
					merge lcm_pre_lcm out_&tempi.;
				run;

				proc sql noprint;
					select value into: ll_cluster_&tempi.
						from modelfit
							where criterion = "Log Likelihood";
				run;
				quit;

				%let resraw_&tempi._mean = 0;

				data _null_;
					set parameterestimates_&tempi. end=end;
					if end then call symput("resraw_&tempi._stddev", estimate);
				run;

				%put &&resraw_&tempi._mean.;
				%put &&resraw_&tempi._stddev.;

			%end;

			/* calculating the residuals for the validation part of the sample */
			%let c_temp = ;
			%if &c_validation_on. = validation %then %let c_temp = if &c_var_validation. = 0%str(;) ;
			%put &c_temp.;

			data lcm_pre_lcm(drop = murx_temp1);
				set lcm_pre_lcm;
				if &c_var_validation. = 0 then
					do;
						%do tempi = 1 %to &n_cluster.;
							resraw_&tempi. = pred_&tempi. - murx_temp1;
							&c_var_dependent. = murx_temp1;
						%end;
					end;
				&c_temp.
			run;

			data copy_lcm_pre_lcm;
				set lcm_pre_lcm;
			run;

			/* calculate the probabilities for the next iteration */
			%lcm_calc_prob(c_data_lcm_pre_lcm=lcm_pre_lcm,
					   c_data_out_prob=lcm_initial_prob,
					   n_cluster=&n_cluster.,
					   c_var_id=i_d_v_a_r);

		%end;
	%else
		%do;
			%lcm_initial_prob(c_data_lcm_pre_lcm=lcm_pre_lcm,
					  c_var_id=i_d_v_a_r,
					  n_cluster=&n_cluster.,
					  n_seed=&n_seed.);
		%end;

	/*------------------------------------------------------------------------------
	em iterations
	------------------------------------------------------------------------------*/

	%let lcm_ll = 0;

	%do i = 1 %to &n_max_iter_em.;

		/* making sure only the needed variables are present in lcm_pre_lcm dataset */
		data lcm_pre_lcm;
			set lcm_pre_lcm(keep = &c_var_independent. &c_var_dependent. &c_var_validation. i_d_v_a_r);
		run;

		/* map the initial probabilities */
		%if &i. = 1 %then
			%do;
				%let c_data_prob = lcm_initial_prob;
			%end;
		%else
			%do;
				%let c_data_prob = lcm_prob_%eval(&i.-1);
			%end;

		%lcm_map_prob(c_data_lcm_pre_lcm=lcm_pre_lcm,
					  c_data_prob=&c_data_prob.,
					  c_var_by=i_d_v_a_r);

		/* for every cluster, create the weight variable */
		%lcm_weight_var(c_data_lcm_pre_lcm=lcm_pre_lcm,
					n_cluster=&n_cluster.);

		/* build a model for each cluster with the reciprocal of the cluster probabilities as weight
		keep track of the residuals, ll, weightedmean(resid), weightedstd(resid) and the beta values */
		%do tempi = 1 %to &n_cluster.;
/*			%global resraw_&tempi._mean resraw_&tempi._stddev;*/
			
			%lcm_proc_genmod(c_data_lcm_pre_lcm=lcm_pre_lcm,
						     c_var_dependent=&c_var_dependent.,
							 c_var_independent=&c_var_independent.,
							 c_var_weight=weight_cluster_&tempi.,
							 c_data_out_parameterestimates=parameterestimates_&tempi.,
							 c_data_out_out=out_&tempi.,
							 c_var_out_pred=pred_&tempi.,
							 c_var_out_resraw=resraw_&tempi.);

			/*merging these two datasets to get the residuals and predicted in the lcm_pre_lcm data*/
			data lcm_pre_lcm;
				merge lcm_pre_lcm out_&tempi.;
			run;

			proc sql noprint;
				select value into: ll_cluster_&tempi.
					from modelfit
						where criterion = "Log Likelihood";
			run;
			quit;

			%let resraw_&tempi._mean = 0;

			data _null_;
				set parameterestimates_&tempi. end=end;
				if end then call symput("resraw_&tempi._stddev", estimate);
			run;

			%put &&resraw_&tempi._mean.;
			%put &&resraw_&tempi._stddev.;

		%end;

		/* calculate ll for this iteration */
		%let lcm_ll_previous = &lcm_ll.;

		data lcm_pre_lcm;
			set lcm_pre_lcm;
			for_ll = 0;
			%do tempi = 1 %to &n_cluster.;
				if missing(prob_cluster_&tempi.) = 0 and prob_cluster_&tempi. > 1E-128 then for_ll = for_ll + log(prob_cluster_&tempi.);
			%end;
		run;

		proc sql noprint;
			select sum(for_ll) into: lcm_ll
				from lcm_pre_lcm;
		run;
		quit;

		%put &lcm_ll.;

		/* compare it with the previos iteration's ll and check for convergence */
		data _null_;
			call symput("converged", abs(&lcm_ll. - &lcm_ll_previous.) < &n_ll_cutoff.);
		run;

		/* calculate the probabilities for the next iteration */
		%lcm_calc_prob(c_data_lcm_pre_lcm=lcm_pre_lcm,
				   c_data_out_prob=lcm_prob_&i.,
				   n_cluster=&n_cluster.,
				   c_var_id=i_d_v_a_r);

		/* if converged, then go to outofthisloop */
		%let n_final_em_iteration = &i.;

		%if &converged. = 1 %then
			%do;
				%goto outofthisloop;
			%end;
	%end;
	/*----------------------------------------------------------------------------*/



	%outofthisloop: %put welcome to outofthisloop;



	/*------------------------------------------------------------------------------
	error check 1
	------------------------------------------------------------------------------*/
	%if &converged. = 0 %then
		%do;
			data _null_;
				v1= "Convergence criteria not met after &n_max_iter_em. iterations.";
				file "&c_path_output./warning.txt";
				put v1;
			run;
		%end;
	/*----------------------------------------------------------------------------*/



	/*------------------------------------------------------------------------------
	create the cluster variable, predicted & residual in lcm_pre_lcm dataset
	------------------------------------------------------------------------------*/
	%let c_var_cluster=c_l_u_s_t_e_r;
	%let c_var_resid=r_e_s_i_d;
	%let c_var_predicted=p_r_e_d_i_c_t_e_d;

	%lcm_cluster_var_creation(c_data_lcm_prob=lcm_prob_&n_final_em_iteration.,
							  c_data_lcm_pre_lcm=lcm_pre_lcm,
							  c_var_id=i_d_v_a_r,
							  n_cluster=&n_cluster.,
							  c_var_out_cluster=&c_var_cluster.,
							  c_var_out_resid=&c_var_resid.,
							  c_var_out_predicted=&c_var_predicted.);
	/*----------------------------------------------------------------------------*/



	/*------------------------------------------------------------------------------
	saving final seeds if model is built with validation variable
	------------------------------------------------------------------------------*/
	%if &c_var_validation. ^= %str() and &b_validation. = 0 %then
		%do;
			data out.finalprob;
				set lcm_prob_&n_final_em_iteration.;
			run;
		%end;
	/*----------------------------------------------------------------------------*/



	/*------------------------------------------------------------------------------
	output 1 : initialseeds.csv
	------------------------------------------------------------------------------*/
	data initialseeds(rename = (i_d_v_a_r = id));
		set lcm_initial_prob;
	run;

	proc export data=initialseeds outfile="&c_path_output./initialseeds.csv" dbms=csv replace;
	run;
	quit;
	/*----------------------------------------------------------------------------*/



	/*------------------------------------------------------------------------------
	output 2 : residual.csv
	------------------------------------------------------------------------------*/
	data residual(rename=(i_d_v_a_r=id &c_var_predicted.=predicted &c_var_resid.=residual &c_var_cluster.=cluster));
		set lcm_pre_lcm(keep=&c_var_dependent.  
							 i_d_v_a_r 
							 &c_var_predicted.
							 &c_var_resid.
							 &c_var_cluster.);
		&c_var_predicted. = round(&c_var_predicted., 0.00001);
		&c_var_resid. = round(&c_var_resid., 0.00001);
	run;

	proc export data = residual outfile="&c_path_output./residual.csv" dbms=csv replace;
	run;
	quit;
	/*----------------------------------------------------------------------------*/



	/*------------------------------------------------------------------------------
	output 3 : variablesummary.csv
	------------------------------------------------------------------------------*/
	%variablesummary(c_data_lcm_pre_lcm=lcm_pre_lcm,
					 c_var_independent=&c_var_independent.,
					 c_var_cluster=&c_var_cluster.);

	proc export data = variablesummary outfile="&c_path_output./variablesummary.csv" dbms=csv replace;
	run;
	quit;
	/*----------------------------------------------------------------------------*/



	/*------------------------------------------------------------------------------
	output 4 : clustersummary.csv
	------------------------------------------------------------------------------*/
	%clustersummary(c_data_lcm_pre_lcm=lcm_pre_lcm,
					c_var_cluster=&c_var_cluster.,
					n_cluster=&n_cluster.);

	proc export data = clustersummary outfile="&c_path_output./clustersummary.csv" dbms=csv replace;
	run;
	quit;
	/*----------------------------------------------------------------------------*/



	/*------------------------------------------------------------------------------
	output 5 : modelstats.csv
	------------------------------------------------------------------------------*/
	%modelstats(c_data_lcm_pre_lcm=lcm_pre_lcm,
				c_var_cluster=&c_var_cluster.,
				c_var_dependent=&c_var_dependent.);

	proc export data = modelstats outfile="&c_path_output./modelstats.csv" dbms=csv replace;
	run;
	quit;
	/*----------------------------------------------------------------------------*/



	/*------------------------------------------------------------------------------
	completed txt
	------------------------------------------------------------------------------*/
	data _null_;
		v1= "LCM completed";
		file "&c_path_output./LCM_COMPLETED.txt";
		put v1;
	run;
	/*----------------------------------------------------------------------------*/
%mend lcm_workflow;
%lcm_workflow;