/*%let input_path=D:/data;*/
/*%let output_path=D:/temp;*/
/*%let group_path=D:/;*/
/*%let flag_bygrp_update=false;*/
/*%let grp_flag=1_1_1;*/
/*%let grp_no=0;*/
/*%let model_iteration=1;*/
/*%let dataset_name=lcadata;*/
/*%let var_lca=_item1 _item2 _item3 _item4 _item5 _item6 _item7 _item8 _item9;*/
/*%let count_var=;*/
/*%let nofclusters=3;*/
/*%let maxiter=1;*/
/*%let converge=0.01;*/
/*%let rerun=1;*/
/*%let seed=4678768;*/

FILENAME MyFile "&output_path./error.txt";

DATA _NULL_;
	rc = FDELETE('MyFile');
RUN;


FILENAME MyFile "&output_path./warning.txt";

DATA _NULL_;
	rc = FDELETE('MyFile');
RUN;

proc datasets lib = work kill;
run;
quit;

*processbody;
options mprint mlogic symbolgen;

proc printto log="&output_path./lca.log" new;
run;
quit;

/*proc printto;run;quit;*/

%let c_path_input = &input_path.;
%let c_path_output = &output_path.;
%let c_dataset_name = &dataset_name.;
%let c_var_lca = %sysfunc(compbl(&var_lca.));
%let n_var_lca = %sysfunc(countw(&c_var_lca., %str( )));
%let c_var_count=&count_var.;
%let n_cluster=&nofclusters.;
%let n_max_iter_em=&maxiter.;
%let n_rerun=&rerun.;
%let n_seed=&seed.;

%macro parameter_play;
	%global n_rerun n_seed n_ll_cutoff;

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
		
	%let n_ll_cutoff=&converge.;
	%if "&n_ll_cutoff." = "" %then %let n_ll_cutoff=0;
	
%mend parameter_play;
%parameter_play;

/*parameters : sample 1*/
/*%let n_var_lca=9;*/
/*%let n_cluster=3;*/
/*%let c_var_lca = _item1 _item2 _item3 _item4 _item5 _item6 _item7 _item8 _item9;*/
/*%let c_dataset_name = lcadata;*/
/*%let c_path_input = D:/;*/
/*%let c_path_output = D:/temp;*/
/*%let n_seed=4678768;*/
/*%let n_max_iter_em=3;*/
/*%let n_ll_cutoff=0.01;*/
/*%let c_var_count=;*/

/*parameters : sample 2*/
/*%let n_var_lca=7;*/
/*%let n_cluster=3;*/
/*%let c_var_lca = channel_1 channel_2 channel_3 channel_4 channel_5 geography store_format;*/
/*%let c_dataset_name = dataworking;*/
/*%let c_path_input = D:/;*/
/*%let n_seed=12345;*/
/*%let n_max_iter_em=5;*/
/*%let n_ll_cutoff=100;*/


/*macro : preLCA*/
%macro pre_lca(c_data, c_var_lca, c_var_count, n_var_lca);
	%global c_newvar_lca c_for_rename_oldtonew c_for_rename_newtoold;

	data lcavarname;
		length oldname $32 newname $32 oldtonew $65 newtoold $65;
		%do tempi = 1 %to %sysfunc(countw(&c_var_lca.));
			oldname="%scan(&c_var_lca., &tempi., %str( ))";
			newname="l_c_a_&tempi.";
			oldtonew=catx("=",oldname,newname);
			newtoold=catx("=",newname,oldname);
			output;
		%end;
		stop;
	run;

	proc sql noprint;
		select oldtonew into: c_for_rename_oldtonew separated by " " from work.lcavarname;
		select newtoold into: c_for_rename_newtoold separated by " " from work.lcavarname;
		select newname  into: c_newvar_lca          separated by " " from work.lcavarname;
	run;
	quit;

	data pre_lca(rename=(&c_for_rename_oldtonew. %if &c_var_count. ^= %str() %then &c_var_count. = count;));
		set &c_data.(keep=&c_var_lca. &c_var_count.);
	run;

	%if &c_var_count. = %str() %then
		%do;
			%let c_for_catx=%sysfunc(tranwrd(&c_newvar_lca.,%str( ),%str(,)));

			data pre_lca;
				set pre_lca;
				t_e_m_p = catx("_", &c_for_catx.);
			run;

			proc freq data=pre_lca noprint;
				tables t_e_m_p / out=freq;
			run;
			quit;

			proc sort data=pre_lca out=pre_lca nodupkey;
				by t_e_m_p;
			run;
			quit;

			data pre_lca(keep=&c_newvar_lca. count);
				merge pre_lca freq;
				by t_e_m_p;
			run;
		%end;

	%if &n_var_lca. > 1 %then
		%do;
			%do i = 1 %to %sysfunc(countw(&c_newvar_lca.));
				%let current_c_newvar_lca = %scan(&c_newvar_lca., &i., %str( ));

				%if &i. = 1 %then
					%do;
						proc sort data=pre_lca(keep=&current_c_newvar_lca.) out=one nodupkey;
							by &current_c_newvar_lca.;
						run;
						quit;
					%end;
				%else
					%do;
						proc sort data=pre_lca(keep=&current_c_newvar_lca.) out=two nodupkey;
							by &current_c_newvar_lca.;
						run;
						quit;

						proc sql;
							create table one as select * from one, two;
						run;
						quit;
					%end;
			%end;

			proc sort data=one out=one nodupkey;
				by &c_newvar_lca.;
			run;
			quit;
			
			proc sort data=pre_lca out=pre_lca nodupkey;
				by &c_newvar_lca.;
			run;
			quit;

			data pre_lca;
				merge one(in = a1) pre_lca(in = a2);
				by &c_newvar_lca.;
				if a1;
			run;
		%end;
%mend pre_lca;

/*macro : uvwd*/
%macro unique_value_weird_dataset(c_data, c_var_lca, c_newvar_lca, c_out);
	%do tempi = 1 %to %sysfunc(countw(&c_newvar_lca.));
		%let current_c_newvar_lca = %scan(&c_newvar_lca., &tempi, %str( ));
		%let current_c_var_lca = %scan(&c_var_lca., &tempi, %str( ));

		proc sort data=&c_data.(keep=&current_c_newvar_lca.) out=unique_value_two_columns_temp nodupkey;
			by &current_c_newvar_lca.;
		run;
		quit;
		
		data unique_value_two_columns_temp;
			length variable $32.;
			length var_lca $32.;
			set unique_value_two_columns_temp;
			variable = "&current_c_newvar_lca.";
			var_lca  = "&current_c_var_lca.";
		run;

		%if &tempi. = 1 %then
			%do;
				data &c_out.;
					set unique_value_two_columns_temp;
				run;
			%end;
		%else
			%do;
				data &c_out.;
					set &c_out. unique_value_two_columns_temp;
				run;
			%end;
	%end;
%mend unique_value_weird_dataset;

/*macro : convert the randomly generated numbers in uvwd into probabilities*/
%macro convert_rnum_into_prob_uvwd(uvwd);

%do tempi = 1 %to %eval(&n_cluster.+1);
	%if &tempi. = %eval(&n_cluster.+1) %then
		%do;
			proc sql noprint;
				select distinct(variable) into: c_variable separated by " "
					from &uvwd.
						group by variable;
			quit;

			%put &c_variable.;
		%end;
	%else
		%do;
			proc sql noprint;
				select sum(prob_cluster_&tempi.) into: sum_cluster_&tempi. separated by " "
					from &uvwd.
						group by variable;
			quit;

			%put &&&sum_cluster_&tempi.;
		%end;
%end;

%do tempi = 1 %to %sysfunc(countw(&c_variable., %str( )));
	%let c_current_variable = %scan(&c_variable., &tempi., %str( ));

	data &uvwd.;
		set &uvwd.;
		if variable = "l_c_a_&tempi." then
			do;
				%do tempj=1 %to &n_cluster.;
					%let sum_current_variable = %scan(&&&sum_cluster_&tempj.., &tempi., %str( ));
					prob_cluster_&tempj. = prob_cluster_&tempj. / &sum_current_variable.;
				%end;
			end;
	run;
%end;
%mend convert_rnum_into_prob_uvwd;

/*macro : dcbs*/
%macro divide_col_by_sum(c_data, c_var_divide, c_type_sum);
	%do tempi = 1 %to %sysfunc(countw(&c_var_divide.));
		%let current_c_var_divide = %scan(&c_var_divide., &tempi., %str( ));

		proc sql noprint;
			%if &c_type_sum. = "all" %then
				%do;
					select sum(&current_c_var_divide.) into: sum from &c_data.;
				%end;
			%else
				%do;
					select sum(distinct(&current_c_var_divide.)) into: sum from &c_data.;
				%end;
		run;
		quit;

		data &c_data.;
			set &c_data.;
			&current_c_var_divide. = &current_c_var_divide. / &sum.;
		run;
	%end;
%mend divide_col_by_sum;

/*macro : map probabilities*/
%macro map_probabilities(c_data_lca, c_data_prob, n_cluster, c_var_lca);
	%do i = 1 %to %sysfunc(countw(&c_var_lca.));

		%let current_c_var_lca = %scan(&c_var_lca., &i., %str( ));

		%let for_rename_map_prob = ;
		%let for_keep_map_prob = ;
		%let for_drop_map_prob = ;
		%do tempi = 1 %to &n_cluster.;
			%let for_drop_map_prob = &for_drop_map_prob. prob_&current_c_var_lca._cluster_&tempi.;
			%let for_keep_map_prob = &for_keep_map_prob. prob_cluster_&tempi.;
			%let for_rename_map_prob = &for_rename_map_prob. prob_cluster_&tempi. = prob_&current_c_var_lca._cluster_&tempi.;
		%end;

		%if &z. = 1 %then %let for_drop_map_prob = ;

		proc sort data = &c_data_lca. out = &c_data_lca.;
			by &current_c_var_lca.;
		run;
		quit;

		proc sort data = &c_data_prob. out = &c_data_prob.;
			by &current_c_var_lca.;
		run;
		quit;

		data data1;
			set &c_data_prob.(keep=&current_c_var_lca. &for_keep_map_prob.);
			if missing(&current_c_var_lca.) then delete;
		run;

		data &c_data_lca.(rename=(&for_rename_map_prob.));
			merge data1(in = a1) &c_data_lca.(in = a2 drop = &for_drop_map_prob.);
			by &current_c_var_lca.;
			if a1 and a2;
		run;

	%end;
%mend map_probabilities;

/*macro : map probabilities using sql*/
%macro map_probabilities_sql(c_data_lca, c_data_prob, n_cluster, c_var_lca);
	%do i = 1 %to %sysfunc(countw(&c_var_lca.));
	
		%let current_c_var_lca = %scan(&c_var_lca., &i., %str( ));

		%let for_rename_map_prob = ;
		%let for_keep_map_prob = ;
		%let for_drop_map_prob = ;
		%do tempi = 1 %to &n_cluster.;
			%let for_drop_map_prob = &for_drop_map_prob. prob_&current_c_var_lca._cluster_&tempi.;
			%let for_keep_map_prob = &for_keep_map_prob. prob_cluster_&tempi.;
			%let for_rename_map_prob = &for_rename_map_prob. prob_cluster_&tempi. = prob_&current_c_var_lca._cluster_&tempi.;
		%end;

		%if &z. = 1 %then %let for_drop_map_prob = ;

		proc sort data = &c_data_lca. out = &c_data_lca.;
			by &current_c_var_lca.;
		run;
		quit;

		proc sort data = &c_data_prob. out = &c_data_prob.;
			by &current_c_var_lca.;
		run;
		quit;

		data data1;
			set &c_data_prob.(keep=&current_c_var_lca. &for_keep_map_prob.);
			if missing(&current_c_var_lca.) then delete;
		run;

		proc sql;
			create table &c_data_lca. as
			select *
			from data1 a1
			inner join &c_data_lca. a2
			on a1.&current_c_var_lca. = a2.&current_c_var_lca.;
		run;
		quit;

		data &c_data_lca.(rename = (&for_rename_map_prob.));
			set &c_data_lca.;
		run;

	%end;
%mend map_probabilities_sql;

/*LCA workflow*/
%macro workflow_lca;

	/*------------------------------------------------------------------------------
	------------------------------------------------------------------------------*/
	/*----------------------------------------------------------------------------*/

	/*------------------------------------------------------------------------------
	the data step :)
	------------------------------------------------------------------------------*/
	libname in "&c_path_input.";

	%if &grp_no. = 0 %then
		%do;
			%let c_data=in.&c_dataset_name.;
		%end;
	%else
		%do;
			data temp(keep=&c_var_lca. &c_var_count.);
				set in.&c_dataset_name. (where=(grp&grp_no._flag = "&grp_flag."));
			run;

			%let c_data=temp;
		%end;
	/*----------------------------------------------------------------------------*/



	/*------------------------------------------------------------------------------
	error check 1
	------------------------------------------------------------------------------*/
/*	ods output nlevels=nlevels;*/
/**/
/*	proc freq data=&c_data.(keep=&c_var_lca.) nlevels;*/
/*	run;*/
/*	quit;*/
/**/
/*	proc sql noprint;*/
/*		select nlevels into: nlevels separated by "*"*/
/*			from nlevels*/
/*				where missing(nlevels) = 0;*/
/*	run;*/
/*	quit;*/
/**/
/*	%let dsid = %sysfunc(open(&c_data.));*/
/*	%let nobs_c_data=%sysfunc(attrn(&dsid.,nobs));*/
/*	%let rc = %sysfunc(close(&dsid.));*/
/**/
/*	%if %eval(&nlevels.) > &nobs_c_data. %then*/
/*		%do;*/
/*			data _null_;*/
/*				v1= "Too few observations or too many degrees of freedom. Please reduce the number of variables selected.";*/
/*				file "&c_path_output./error.txt";*/
/*				put v1;*/
/*			run;*/
/**/
/*			%abort;*/
/*		%end;*/
	/*----------------------------------------------------------------------------*/



	/*------------------------------------------------------------------------------
	error check 2 : check if theres any variable with only one level
	------------------------------------------------------------------------------*/
	%let b_error                          = 0;
	%let b_warning                        = 0;
	%let c_message                        = ;
	%let c_var_lca_gt1                    = ;
	%let c_var_lca_lteq1                  = ;
	%let n_var_lca_gt1                    = 0;
	%let n_var_lca_lteq1                  = 0;

	%do n_tempi = 1 %to %sysfunc(countw(&c_var_lca.));
		%let c_var_lca_now                = %scan(&c_var_lca., &n_tempi., %str( ));

		proc sql noprint;
			select count(distinct(&c_var_lca_now.)) into: n_distinct_now
				from &c_data.;
		run;
		quit;

		%if &n_distinct_now. > 1 %then
			%do;
				%let c_var_lca_gt1        = &c_var_lca_gt1. &c_var_lca_now.;
				%let n_var_lca_gt1        = %eval(&n_var_lca_gt1. + 1);
			%end;
		%if &n_distinct_now. <= 1 %then
			%do;
				%let c_var_lca_lteq1      = &c_var_lca_lteq1. &c_var_lca_now.;
				%let n_var_lca_lteq1      = %eval(&n_var_lca_lteq1. + 1);
			%end;
	%end;

	%if &n_var_lca_lteq1. > 0 %then
		%do;
			%let b_warning                = 1;
			%let c_var_lca_lteq1          = %sysfunc(tranwrd(%str(&c_var_lca_lteq1.), %str( ), %str(, )));
			%let c_message                = Eliminated variable(s) &c_var_lca_lteq1. with a single level.;
		%end;

	%if &n_var_lca_gt1. <= 1 %then
		%do;
			%let b_error                  = 1;
			%let c_message                = &c_message. Insufficient variables to proceed.;
		%end;

	%if &b_error. %then
		%do;
			data _null_;
				v1= "&c_message.";
				file "&c_path_output./error.txt";
				put v1;
			run;

			%abort;
		%end;

	%if &b_warning. %then
		%do;
			data _null_;
				v1= "&c_message.";
				file "&c_path_output./warning.txt";
				put v1;
			run;
		%end;

	%let c_var_lca                        = &c_var_lca_gt1.;
	%let n_var_lca                        = %sysfunc(countw(&c_var_lca.));
	/*----------------------------------------------------------------------------*/
	
	
	
	/*------------------------------------------------------------------------------
	preparing the data to perform lca
	------------------------------------------------------------------------------*/
	%pre_lca(c_data=&c_data., c_var_lca=&c_var_lca., c_var_count=&c_var_count., n_var_lca=&n_var_lca.);
	/*----------------------------------------------------------------------------*/



	/*------------------------------------------------------------------------------
	preparing the initial probabilities
	now they are just random numbers generated by the seed
	they'll be converted into probabilities later
	------------------------------------------------------------------------------*/
	%unique_value_weird_dataset(c_data=work.pre_lca, c_var_lca=&c_var_lca., c_newvar_lca=&c_newvar_lca., c_out=uvwd1);

	data uvwd1;
		set uvwd1;
		%do tempi = 1 %to &n_cluster.;
			prob_cluster_&tempi. = ranuni(&n_seed.);
		%end;
		output;
	run;
	/*----------------------------------------------------------------------------*/



	/*------------------------------------------------------------------------------
	creating a few macro variales to be used below in the loop
	------------------------------------------------------------------------------*/
	%global for_sum_measure for_pred_count_total;
	%let c_var_divide = ;
	%let for_sum_measure = 0;
	%let for_pred_count_total = 0;
	%let for_ll = 0;
	%do tempi = 1 %to %eval(&n_cluster.);
		%global for_measure_cluster_&tempi.;
		%let for_measure_cluster_&tempi. = 1 ;
		%let for_ll = &for_ll. + for_ll&tempi.;
		%do tempj = 1 %to %eval(&n_var_lca.);
			%let c_var_divide = &c_var_divide. prob_l_c_a_&tempj._cluster_&tempi.;
			%let for_measure_cluster_&tempi. = &&for_measure_cluster_&tempi.. * prob_l_c_a_&tempj._cluster_&tempi.;
		%end;
		%let for_sum_measure = &for_sum_measure., measure_cluster_&tempi.;
		%let for_pred_count_total = &for_pred_count_total. + pred_count_cluster_&tempi.;
	%end;
	%let n_ll_previous = 0;
	/*----------------------------------------------------------------------------*/



	/*------------------------------------------------------------------------------
	this loop will run &n_max_iter_em. no.of times
	step 1 : convert the random numbers generated into probabilities
	step 2 : map these probabilities to their resp variables and clusters
	step 3 : perform the necessary calculations for lca
	step 4 : get the ll value and compare with the previous iterations ll value
	step 5 : check for convergence
				if converged, go to output generating part of the code
				if not, prepare the numbers(probabilities) for the next iteration
	step 6 : getting the last successful iteration number
	------------------------------------------------------------------------------*/
	%do z = 1 %to %eval(&n_max_iter_em.);
		/*------------------------------------------------------------------------------
		step 1 : convert the random numbers generated into probabilities
		------------------------------------------------------------------------------*/
		%convert_rnum_into_prob_uvwd(uvwd=uvwd&z.);
		/*----------------------------------------------------------------------------*/



		/*------------------------------------------------------------------------------
		step 2 : map these probabilities to their resp variables and clusters
		------------------------------------------------------------------------------*/
		%map_probabilities_sql(c_data_lca=pre_lca, c_data_prob=uvwd&z., n_cluster=&n_cluster., c_var_lca=&c_newvar_lca.);
		/*----------------------------------------------------------------------------*/



		/*------------------------------------------------------------------------------
		step 3 : perform the necessary calculations for lca
		------------------------------------------------------------------------------*/
		data pre_lca;
			set pre_lca;
			%do tempi = 1 %to %eval(&n_cluster.);
				measure_cluster_&tempi. = &&for_measure_cluster_&tempi..;
			%end;
			%do tempi = 1 %to %eval(&n_cluster.);
				prob_cluster_&tempi. = measure_cluster_&tempi. / sum(&for_sum_measure.);
				if missing(prob_cluster_&tempi.) then prob_cluster_&tempi. = 0;
				count_cluster_&tempi. = prob_cluster_&tempi. * count;
			%end;
		run;

		proc sql noprint;
			%do tempi = 1 %to %eval(&n_cluster.);
				select sum(count_cluster_&tempi.) into: sum_count_cluster_&tempi. from pre_lca;
			%end;
		run;
		quit;

		data pre_lca;
			set pre_lca;
			%do tempi = 1 %to %eval(&n_cluster.);
				pred_count_cluster_&tempi. = measure_cluster_&tempi. * &&sum_count_cluster_&tempi..;
				for_ll&tempi. = pred_count_cluster_&tempi. * log(measure_cluster_&tempi.);
				if missing(for_ll&tempi.) then for_ll&tempi. = 0;
			%end;
			pred_count_total = &for_pred_count_total.;
			ll = &for_ll.;
		run;
		/*----------------------------------------------------------------------------*/



		/*------------------------------------------------------------------------------
		step 4 : get the ll value and compare with the previous iterations ll value
		------------------------------------------------------------------------------*/
		proc means data=pre_lca(keep = ll) noprint;
			output out=temp_ll_only sum=ll_now;
		run;

		proc append base=ll_only data=temp_ll_only force;
		run;
		quit;

		%let converged = 0;

		data ll;
			set ll_only(keep=ll_now);
			iteration=_n_;
			ll_previous = lag(ll_now);
			ll_difference = abs(ll_now - ll_previous);
			ll_cutoff = &n_ll_cutoff.;
			if missing(ll_difference) = 0 then call symput("converged", ll_difference < ll_cutoff);
		run;
		/*----------------------------------------------------------------------------*/



		/*------------------------------------------------------------------------------
		step 5 : check for convergence
					if converged, go out of this loop to output part of the code
					if not, prepare the numbers(probabilities) for the next iteration(if any)
		------------------------------------------------------------------------------*/
		%if &converged. = 1 %then
			%do;
				%goto outofthisloop;
			%end;
		%else %if &z. < &n_max_iter_em. %then
			%do;
				data uvwd%eval(&z. + 1);
					set uvwd&z.;
				run;

				%do tempi = 1 %to %eval(&n_cluster.);
					%do tempj = 1 %to %eval(&n_var_lca.);
						%let current_c_newvar_lca = %scan(&c_newvar_lca., &tempj., %str( ));

						proc sort data=pre_lca out=pre_lca;
							by &current_c_newvar_lca.;
						run;
						quit;

						proc sort data=uvwd%eval(&z. + 1) out=uvwd%eval(&z. + 1);
							by &current_c_newvar_lca.;
						run;
						quit;

						proc means data=pre_lca(keep = &current_c_newvar_lca. count_cluster_&tempi.) noprint;
							by &current_c_newvar_lca.;
							output out=means_out sum=prob_cluster_&tempi.;
						run;

						data uvwd%eval(&z. + 1);
							merge uvwd%eval(&z. + 1) means_out(keep = &current_c_newvar_lca. prob_cluster_&tempi.);
							by &current_c_newvar_lca.;
						run;
					%end;
				%end;
			%end;
			/*----------------------------------------------------------------------------*/



			/*------------------------------------------------------------------------------
			step 6 : getting the last successful iteration number
			------------------------------------------------------------------------------*/
			%let finalz=&z.;
			/*----------------------------------------------------------------------------*/
	%end;
	/*----------------------------------------------------------------------------*/
	


	/*------------------------------------------------------------------------------
	few messages for the log
	------------------------------------------------------------------------------*/
	%put do loop ran &n_max_iter_em. times. converged = &converged.;
	%outofthisloop: %put welcome to outofthisloop;
	/*----------------------------------------------------------------------------*/



	/*------------------------------------------------------------------------------
	creating a few macro variales to be used below in the output part of the code
	------------------------------------------------------------------------------*/
	%let for_coalesce = %sysfunc(tranwrd(&c_var_lca., %str( ), %str(,)));

	%let restofthevars = ;
	%do tempi = 1 %to &n_cluster.;
		%let restofthevars = &restofthevars., prob_cluster_&tempi.;
	%end;
	/*----------------------------------------------------------------------------*/



	/*------------------------------------------------------------------------------
	output 0 : cluster_probability.csv
	------------------------------------------------------------------------------*/
	%let murx_for_keep = ;
	%do tempi = 1 %to &n_cluster.;
		%let murx_for_keep = &murx_for_keep. prob_cluster_&tempi.;
	%end;
	
	data clusterprobability(rename=(&c_for_rename_newtoold.));
		length murx_cluster_variable $ 32;
		array list(*) &murx_for_keep.;
		set pre_lca(keep=&c_newvar_lca. &murx_for_keep. count rename=(count=murx_count_variable));
		murx_cluster_variable = vname(list[whichn(max(of list[*]), of list[*])]);
		murx_cluster_variable = tranwrd(murx_cluster_variable, "prob_cluster_", "");
		if missing(murx_count_variable) then murx_count_variable = 0;
	run;

	proc export data=clusterprobability outfile="&c_path_output./clusterprobability.csv"
		dbms=csv replace;
	run;
	quit;
	/*----------------------------------------------------------------------------*/



	/*------------------------------------------------------------------------------
	output 1 : initialseeds.csv
	------------------------------------------------------------------------------*/
	%let temp_for_rename = ;
	%let temp_for_length = ;
	%do tempi = 1 %to %sysfunc(countw(&c_newvar_lca., %str( )));
		%let c_current_newvar_lca = %scan(&c_newvar_lca., &tempi., %str( ));
		%let temp_for_rename = &temp_for_rename. char_&c_current_newvar_lca. = &c_current_newvar_lca. ;
		%let temp_for_length = &temp_for_length. char_&c_current_newvar_lca. $200;
	%end;
		
	data initialseedstemp(drop = &c_newvar_lca. rename = (&temp_for_rename.));
		set uvwd1;
		length &temp_for_length.;
		%do tempi = 1 %to %sysfunc(countw(&c_newvar_lca., %str( )));
			%let c_current_newvar_lca = %scan(&c_newvar_lca., &tempi., %str( ));
			if missing(&c_current_newvar_lca.) then char_&c_current_newvar_lca. = "";
			else char_&c_current_newvar_lca. = left(&c_current_newvar_lca.);
		%end;
	run;
	
	data initialseeds;
		set initialseedstemp(drop = variable rename = (&C_FOR_RENAME_NEWTOOLD. var_lca=variable));
	run;

	proc sql;
		create table initialseeds as
			select variable, coalesce(&for_coalesce.)as value &restofthevars.
				from initialseeds;
	run;
	quit;

	proc export data=initialseeds outfile="&c_path_output./initialseeds.csv" dbms=csv replace;
	run;
	quit;
	/*----------------------------------------------------------------------------*/



	/*------------------------------------------------------------------------------
	output 2 : finalseeds.csv
	------------------------------------------------------------------------------*/
	%let temp_for_rename = ;
	%let temp_for_length = ;
	%do tempi = 1 %to %sysfunc(countw(&c_newvar_lca., %str( )));
		%let c_current_newvar_lca = %scan(&c_newvar_lca., &tempi., %str( ));
		%let temp_for_rename = &temp_for_rename. char_&c_current_newvar_lca. = &c_current_newvar_lca. ;
		%let temp_for_length = &temp_for_length. char_&c_current_newvar_lca. $200;
	%end;
		
	data finalseedstemp(drop = &c_newvar_lca. rename = (&temp_for_rename.));
		set uvwd&finalz.;
		length &temp_for_length.;
		%do tempi = 1 %to %sysfunc(countw(&c_newvar_lca., %str( )));
			%let c_current_newvar_lca = %scan(&c_newvar_lca., &tempi., %str( ));
			if missing(&c_current_newvar_lca.) then char_&c_current_newvar_lca. = "";
			else char_&c_current_newvar_lca. = left(&c_current_newvar_lca.);
		%end;
	run;
		
	data finalseeds;
		set finalseedstemp(drop = variable rename = (&C_FOR_RENAME_NEWTOOLD. var_lca=variable));
	run;

	proc sql;
		create table finalseeds as
			select variable, coalesce(&for_coalesce.) as value &restofthevars.
				from finalseeds;
	run;
	quit;

	proc export data=finalseeds outfile="&c_path_output./finalseeds.csv" dbms=csv replace;
	run;
	quit;
	/*----------------------------------------------------------------------------*/



	/*------------------------------------------------------------------------------
	output 3 : clustersummary.csv
	output 4 : modelstats.csv
	------------------------------------------------------------------------------*/
	ods output nlevels=nlevels;

	proc freq data=&c_data.(keep=&c_var_lca.) nlevels;
	run;
	quit;

	proc sql noprint;
		select nlevels - 1 into: sumnlevelsm1 separated by "+"
			from nlevels
				where missing(nlevels) = 0;
	run;
	quit;
	
	%let dsid = %sysfunc(open(pre_lca));
	%let nobs_pre_lca=%sysfunc(attrn(&dsid.,nobs));
	%let rc = %sysfunc(close(&dsid.));
	
	%let n_model_param = %sysevalf(&n_cluster. - 1 + (&n_cluster. * (&sumnlevelsm1.)));
	%let DF = %sysevalf(&nobs_pre_lca. - &n_model_param. - 1);

	data pre_lca;
		set pre_lca;
		chi_squared = ((count - pred_count_total)**2)/pred_count_total;
		g_squared = count * log(count / pred_count_total);
		if missing(chi_squared) then chi_squared = 0;
		if missing(g_squared) then g_squared = 0;
	run;

	proc sql noprint;
		select sum(count) into: N from pre_lca;
		create table modelstats as
		select 
		2 * sum(g_squared) as g_squared,
		sum(chi_squared) as chi_squared
		from pre_lca;
	run;
	quit;

	data modelstats;
		set modelstats;
		DF = &DF.;
		pvalue_chisq = (0.5 ** (df / 2) / gamma(df / 2)) *
					   chi_squared ** ((df / 2) -1) * 
					   exp(-1 * (chi_squared / 2));
		if missing(pvalue_chisq) then pvalue_chisq = 0;
	run;

	%let q = %eval(&nobs_pre_lca. * &n_cluster. - 1);

	data modelstats2;
		set ll(keep=ll_now ll_difference rename=(ll_now=ll)) end=end;
		if end;
	run;

	data modelstats;
		merge modelstats modelstats2;
	run;



	/*------------------------------------------------------------------------------
	ll2 calculation
	------------------------------------------------------------------------------*/
	/*making a copy of pre_lca for safekeeping*/
	data copy_pre_lca;
		set pre_lca;
	run;

	%let for_max_measure_cluster = 0;
	%do tempi=1 %to &n_cluster.;
		%let for_max_measure_cluster = &for_max_measure_cluster. , measure_cluster_&tempi.;
	%end;

	data pre_lca;
		set pre_lca;
		max_measure_cluster = max(&for_max_measure_cluster.);
		%do tempi=1 %to &n_cluster.;
			measure_cluster_&tempi. = floor(measure_cluster_&tempi./max_measure_cluster);
		%end;
		%do tempi = 1 %to %eval(&n_cluster.);
			prob_cluster_&tempi. = measure_cluster_&tempi. / sum(&for_sum_measure.);
			if missing(prob_cluster_&tempi.) then prob_cluster_&tempi. = 0;
			count_cluster_&tempi. = prob_cluster_&tempi. * count;
		%end;
	run;

	/* copy of pre_lca with 0 1 probabilities */
	data temp_pre_lca;
		set pre_lca;
	run;

	proc sql noprint;
		%do tempi = 1 %to %eval(&n_cluster.);
			select sum(count_cluster_&tempi.) into: sum_count_cluster_&tempi. from pre_lca;
		%end;
	run;
	quit;



	/*------------------------------------------------------------------------------
	output 3 : clustersummary.csv
	------------------------------------------------------------------------------*/
	data nobs_in_clusters;
		%do tempi = 1 %to %eval(&n_cluster.);
			cluster = &tempi.;
			nobs =  &&sum_count_cluster_&tempi..;
			output;
		%end;
	run;

	proc export data=nobs_in_clusters outfile="&c_path_output./clustersummary.csv" dbms=csv replace;
	run;
	quit;
	/*----------------------------------------------------------------------------*/



	data uvwdll2;
		set uvwd&finalz.;
	run;

	%do tempi = 1 %to %eval(&n_cluster.);
		%do tempj = 1 %to %eval(&n_var_lca.);
			%let current_c_newvar_lca = %scan(&c_newvar_lca., &tempj., %str( ));

			proc sort data=pre_lca out=pre_lca;
				by &current_c_newvar_lca.;
			run;
			quit;

			proc sort data=uvwdll2 out=uvwdll2;
				by &current_c_newvar_lca.;
			run;
			quit;

			proc means data=pre_lca(keep = &current_c_newvar_lca. count_cluster_&tempi.) noprint;
				by &current_c_newvar_lca.;
				output out=means_out sum=prob_cluster_&tempi.;
			run;

			data uvwdll2;
				merge uvwdll2 means_out(keep = &current_c_newvar_lca. prob_cluster_&tempi.);
				by &current_c_newvar_lca.;
			run;
		%end;
	%end;

	%convert_rnum_into_prob_uvwd(uvwd=uvwdll2);

	%map_probabilities_sql(c_data_lca=pre_lca, c_data_prob=uvwdll2, n_cluster=&n_cluster., c_var_lca=&c_newvar_lca.);

	data pre_lca;
		set pre_lca;
		%do tempi = 1 %to %eval(&n_cluster.);
			measure_cluster_&tempi. = &&for_measure_cluster_&tempi..;
		%end;
		%do tempi = 1 %to %eval(&n_cluster.);
			prob_cluster_&tempi. = measure_cluster_&tempi. / sum(&for_sum_measure.);
			if missing(prob_cluster_&tempi.) then prob_cluster_&tempi. = 0;
			count_cluster_&tempi. = prob_cluster_&tempi. * count;
		%end;
	run;

	proc sql noprint;
		%do tempi = 1 %to %eval(&n_cluster.);
			select sum(count_cluster_&tempi.) into: sum_count_cluster_&tempi. from pre_lca;
		%end;
	run;
	quit;

	data pre_lca;
		set pre_lca;
		%do tempi = 1 %to %eval(&n_cluster.);
			pred_count_cluster_&tempi. = measure_cluster_&tempi. * &&sum_count_cluster_&tempi..;
			for_ll&tempi. = log((prob_cluster_&tempi. ** pred_count_cluster_&tempi.)
							* ((1 - prob_cluster_&tempi.) ** (count - pred_count_cluster_&tempi.)));
			if missing(for_ll&tempi.) then for_ll&tempi. = 0;
		%end;
		pred_count_total = &for_pred_count_total.;
		ll = &for_ll.;
	run;

	proc means data=pre_lca(keep = ll) noprint;
		output out=temp_ll2 sum=ll2;
	run;

	proc sql noprint;
		select ll2 into: ll2 from temp_ll2;
	run;
	quit;
	/*----------------------------------------------------------------------------*/

	data modelstats;
		set modelstats;
		seed = &n_seed.;
		ll2 = &ll2.;
		AIC = 2 * &q. - (2 * ll);
		BIC = &q. * log(&N.) - (2 * ll);
		if missing(AIC) then AIC = 0;
		if missing(BIC) then BIC = 0;
		em_iterations = &finalz.;
		converged = &converged.;
		convergence_cutoff = &n_ll_cutoff.;
	run;

	proc transpose data=modelstats out=modelstats;
	run;
	quit;

	data modelstats;
		set modelstats(rename=(_NAME_=label COL1=value));
	run;

	proc export data=modelstats outfile="&c_path_output./modelstats.csv" dbms=csv replace;
	run;
	quit;
	/*----------------------------------------------------------------------------*/



	/*------------------------------------------------------------------------------
	output 5 : variance.csv
	between group, within group & total variance
	------------------------------------------------------------------------------*/
	data variance;
		length variable $32;
		variable = "m_u_r_x";
		betweengroupvariance=0;
		withingroupvariance=0;
		totalvariance=betweengroupvariance + withingroupvariance;
	run;

	%do tempi = 1 %to %sysfunc(countw(&c_newvar_lca.));
		%let c_current_newvar_lca = %scan(&c_newvar_lca., &tempi., %str( ));
		%let c_current_var_lca = %scan(&c_var_lca., &tempi., %str( ));

		%do tempj = 1 %to &n_cluster.;
			
			%if &tempj. = 1 %then %let tempdatasetname=overallanova;
			%else %let tempdatasetname=temp;
			ods output overallanova=&tempdatasetname.;

			proc anova data=pre_lca(keep = &c_current_newvar_lca. prob_cluster_&tempj.);
				class &c_current_newvar_lca.;
				model prob_cluster_&tempj. = &c_current_newvar_lca.;
			run;
			quit;

			%if &tempj. ^= 1 %then
				%do;
					proc append base = overallanova data = temp force;
					run;
					quit;
				%end;
		%end;

		proc sql;
			select avg(ms) into: betweengroupvariance
				from overallanova
					where source = "Model";
			select avg(ms) into: withingroupvariance
				from overallanova
					where source = "Error";
		run;
		quit;

		data variance_temp;
			variable = "&c_current_var_lca.";
			betweengroupvariance=&betweengroupvariance.;
			withingroupvariance=&withingroupvariance.;
			totalvariance=betweengroupvariance + withingroupvariance;
		run;

		data variance;
			set variance variance_temp;
		run;

	%end;

	data variance;
		set variance;
		if variable = "m_u_r_x" then delete;
	run;

	proc export data=variance outfile="&c_path_output./variance.csv" dbms=csv replace;
	run;
	quit;
	/*----------------------------------------------------------------------------*/



	/*------------------------------------------------------------------------------
	error check 2
	&n_ll_cutoff.^=0 was added because warning should come if user has selected some 
		convergence in the front end
	------------------------------------------------------------------------------*/
	%if &converged. = 0 and  &n_ll_cutoff. ^= 0 %then
		%do;
			data _null_;
				v1= "Convergence criteria not met after &n_max_iter_em. iterations.";
				file "&c_path_output./warning.txt";
				put v1;
			run;
		%end;
	/*----------------------------------------------------------------------------*/
%mend workflow_lca;
%workflow_lca;



/*------------------------------------------------------------------------------
completed txt
------------------------------------------------------------------------------*/
data _null_;
	v1= "LCA completed";
	file "&c_path_output./LCA_COMPLETED.txt";
	put v1;
run;
/*----------------------------------------------------------------------------*/
