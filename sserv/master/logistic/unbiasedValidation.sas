proc printto log="&outputpath./unbiasedvalidation_Log.log";
	run;
	quit;


options mlogic symbolgen;

%macro log_sco_walpcor_exp_csv(libname=,dataset=,filename=);

	proc export data=&libname..&dataset.
		outfile="&outputPath./&filename..csv"
		dbms=csv replace;
	run;

%mend;

%macro log_sco_walpcor(params,
			data,
			wherecondition,
			out,
			out_keep);
	/*for all the continuous variables, create a macro variable with the name containing
	the value of the parameter estimates */
	data tempparams;
		set &params.(rename=(variable=Variable estimate=Estimate));

		%if &flagalphacorrection. = true %then
			%do;
				if variable = "Intercept" then
					Estimate = Estimate + log((&actual. * (1 - &oversample.))/(&oversample. * (1 - &actual.)));
			%end;

		if missing(classval0) then
			call symput(variable, estimate);
	run;

	/*create the text for the contribution due to the independent variables*/
	%let contribution_independent_part = &intercept.;

	%do tempi = 1 %to %sysfunc(countw(&independentvariables.));
		%let current_independentvariables = %scan(&independentvariables., &tempi.);
		%let contribution_independent_part = &contribution_independent_part. + (&current_independentvariables. * &&&current_independentvariables.);
	%end;

	/*calculate the contribution due to the independent variables*/
	data &out.;
		set &data. (keep = &validationvar. &out_keep. &dependentvariable. &independentvariables. &classvariables. &cond.);
		muRx_contribution = &contribution_independent_part.;
	run;

	/*create the text for the contribution due to the class variables
	and calculate the contribution due to the independent variables*/
	%let contribution_class_part = 0;

	%if &classvariables. ^= %str() %then
		%do tempi = 1 %to %sysfunc(countw(&classvariables.));
			%let current_classvariables = %scan(&classvariables., &tempi.);
			%let contribution_class_part = &contribution_class_part. + muRx_class&tempi.;

			proc sql;
				select a1.muRx_contribution + a2.estimate as muRx_contribution, a1.*
					from &out. a1 left join &params. a2
						on a1.&current_classvariables. = a2.classval0;
			quit;

		%end;

	/*calculate the probability of every observation being an event*/
	data &out.;
		set &out.;
		muRx_probevent = exp(muRx_contribution) / (1 + exp(muRx_contribution));
	run;

%mend log_sco_walpcor;

%macro log_sco_walpcor_pos_sco;
	%if %index("&dependentvariable.", /) = 0 and (&flaggains. = true or &flagkstest. = true or &flaglift. = true) %then
		%do;
			/*ks test*/
			proc rank data=scored(keep=muRx_probevent &dependentVariable. XXXind_logit YYYind_logit rename=(XXXind_logit=V_GOOD YYYind_logit=V_BAD))
				out=ks_rankpred groups=%eval(&numGrps.) descending;
				var muRx_probevent;
				ranks rank_pred;
			run;

			proc sort data = ks_rankpred;
				by rank_pred;
			run;

			proc means data=ks_rankpred noprint;
				var muRx_probevent V_BAD;
				by rank_pred;
				output out=ks_means mean=mean badrate min=minimum minbad max=maximum maxbad;
			run;

			proc freq data=ks_rankpred noprint;
				table rank_pred / out=ks_freq_weighted;
				weight V_BAD;
			run;

			proc freq data=ks_rankpred noprint;
				table rank_pred / out=ks_weightedFreq_good;
				weight V_GOOD;
			run;

			proc freq data=ks_rankpred noprint;
				table rank_pred / out=ks_Freq;
			run;

			data ks_freqs;
				merge ks_freq_weighted(rename=(percent=percent_bad count=count_bad))
					ks_weightedFreq_good(rename=(percent=percent_good count=count_good))
					ks_Freq(rename=(count=count_accts))
					ks_means(keep=rank_pred mean badrate minimum maximum);
				by rank_pred;
			run;

			data ks_freqs;
				set ks_freqs end = final;
				total_accts+count_accts;

				if final then
					call symput('sum_accts',total_accts);
			run;

			data ks_cumm;
				set ks_freqs;
				cumm_bad+count_bad;
				cumm_good+count_good;
				cumm_accts+count_accts;
				cumm_perc_bad+percent_bad;
				cumm_perc_good+percent_good;
				cumm_bad_rate=cumm_bad/cumm_accts;
				cumm_good_rate=cumm_good/cumm_accts;
				cumm_accts_rate=cumm_accts/&sum_accts;
				ks_mv=((count_bad-count_accts*mean) * (count_bad-count_accts*mean))/ (count_accts*mean*(1-mean));
				cumm_gof+ks_mv;
				ks_bdgd = ABS(cumm_perc_bad - cumm_perc_good);
				group=_n_;
			run;

			data ks_inter;
				set ks_cumm (keep = group rank_pred badrate mean minimum maximum cumm_bad cumm_perc_bad cumm_accts cumm_bad_rate cumm_gof ks_bdgd);
			run;

			proc transpose data = ks_inter out = ks_inter_trans;
			run;

			data ks (rename=(ks_bdgd = ks group = max_ks_dec));
				set ks_inter (keep = ks_bdgd group);
			run;

			proc sort data = ks;
				by descending ks;
			run;

			data ks;
				set ks (obs = 1);
				format ks 8.2;
			run;

			data ks_gof (rename=(cumm_gof = gof));
				set ks_inter (keep = cumm_gof);
			run;

			proc sort data = ks_gof;
				by descending gof;
			run;

			data ks_gof;
				set ks_gof (obs = 1);
				format gof 8.2;
			run;

			data ks_inter (keep = group rank_pred cumm_accts pred_resp act_resp minimum maximum cumm_respr cumresp pctresp ks gof);
				set ks_inter;
				pred_resp = mean*100;
				format pred_resp 8.2;
				act_resp = badrate*100;
				format act_resp 8.2;
				cumm_respr = cumm_bad_rate*100;
				format cumm_respr 8.2;
				format minimum 8.3 maximum 8.3 cumm_perc_bad 8.2 ks_bdgd 8.2 cumm_gof 8.2;
				rename cumm_bad = cumresp cumm_perc_bad = pctresp ks_bdgd = ks cumm_gof = gof;
			run;

			data ks_order (keep=_name_ order_flag ranking sat_rank rename=(_name_=attribute));
				set ks_inter_trans;
				where lowcase(_NAME_) = 'badrate';
				order_flag = 0;

				%do tempi = 1 %to &numGrps. - 1;
					%let tempj = %eval(&tempi. + 1);
					order_flag = order_flag + (col&tempi. lt col&tempj.);
				%end;

				if order_flag gt 0 then
					ranking = 'NOT SATISFACTORY';
				else ranking = 'SATISFACTORY';
				sat_rank = 'ALL';

				%do tempi = 1 %to &numGrps. - 1;
					%let tempj = %eval(&tempi. + 1);

					if ((col&tempi. lt col&tempj.) and (sat_rank = 'ALL')) then
						sat_rank = "&tempi.";
				%end;
			run;

			data out.ks_rep;
				merge ks_order ks ks_gof;
			run;

			data out.ks_out;
				merge ks_inter(in=a drop=group) ks_freqs(in=b drop=mean badrate minimum maximum total_accts);
				by rank_pred;

				if a or b;
			run;

			data out.ks_out(rename=(count_bad=count_events percent_bad=percent_events count_good=count_nonevents 
				percent_good=percent_nonevents));
				retain rank_pred count_bad percent_bad count_good percent_good count_accts percent_accts cumm_accts pred_resp act_resp
					minimum maximum cumm_respr cumresp pctresp ks gof;
				set out.ks_out(rename=(percent=percent_accts));
				attrib _all_ label="";
			run;

			data out.ks_out (drop = abcd);
				set out.ks_out;
				abcd = (pctresp + lag(pctresp))/100;

				if _n_ = 1 then
					abcd = pctresp/100;
				gini = (0.05*abcd);
			run;

			proc sql;
				create table gini as
					select (2*sum(gini) - 1) as gini from out.ks_out;
			quit;

			data out.ks_rep;
				merge out.ks_rep(in=a) gini(in=b);

				if a or b;
			run;

			proc sql;
				create table out.ks_rep as
					select attribute,order_flag,ranking,sat_rank, max_ks_dec,ks,gof
						from out.ks_rep;
			quit;

			%if &flagkstest. = true %then
				%do;
					%log_sco_walpcor_exp_csv(libname=out,dataset= ks_rep,filename= ks_rep);
					%log_sco_walpcor_exp_csv(libname=out,dataset= ks_out,filename= ks_out);
				%end;

			%if &flaglift. = true %then
				%do;

					data lift (keep = percent_customers base cumulative_lift individual_lift);
						retain percent_customers base cumulative_lift individual_lift;
						set out.ks_out;
						percent_customers = (rank_pred + 1)*10;
						base = 1;
						cumulative_lift = pctresp/percent_customers;
						individual_lift = percent_events/10;
					run;

					%log_sco_walpcor_exp_csv(libname=work,dataset= lift,filename=lift);
				%end;

			%if &flaglift. = true %then
				%do;

					data gains (keep = percent_customers random percent_positive_response);
						retain percent_customers random percent_positive_response;
						set out.ks_out;
						percent_customers = (rank_pred + 1)*10;
						random = percent_customers;
						rename pctresp = percent_positive_response;
					run;

					%log_sco_walpcor_exp_csv(libname=work,dataset= gains,filename=gains);
				%end;
		%end;

	%if "&flagactpred." = "true" %then
		%do;
			%if %index("&dependentvariable.", /) = 0 %then
				%do;

					proc rank data = scored
						out = testpred (keep =  deciles muRx_probevent &dependentvariable. 
						rename = (muRx_probevent = predicted))
						Groups = %sysevalf(&numGrps.) descending;
						var muRx_probevent;
						ranks deciles;
					run;

					proc sort data = testpred;
						by deciles;
					run;

					%let dsid = %sysfunc(open(testpred));
					%let varnum_dependent = %sysfunc(varnum(&dsid., &dependentvariable.));
					%let vartype_dependent = %sysfunc(vartype(&dsid., &varnum_dependent.));
					%let rc = %sysfunc(close(&dsid.));

					%if "&vartype_dependent." = "C" %then
						%let temp_event = "&event.";
					%else %let temp_event = &event.;

					proc sql;
						create table predicted_actual as
							select deciles,
								avg(predicted)*100 as predicted,
								(sum(CASE WHEN &dependentvariable= &temp_event.  THEN 1 ELSE 0 END)/count(*))*100 as actual
							from testpred
								group by deciles;
					quit;

					proc sql;
						create table predicted_actual as
							select deciles, predicted, actual, avg(actual) as average_rate, (predicted/actual) as pred_by_actual
								from predicted_actual
									quit;
				%end;

			%if %index("&dependentvariable.",/) ne 0 %then
				%do;

					proc rank data = scored 
					out = testpred (keep =  deciles muRx_probevent TRIALSind_logit 
					rename = (muRx_probevent = predicted))
					Groups = %sysevalf(&numGrps.) descending;
						var muRx_probevent;
						ranks deciles;
					run;

					proc sort data = testpred;
						by deciles;
					run;

					proc sql;
						create table predicted_actual as
							select deciles,
								avg(predicted)*100 as predicted,
								avg(TRIALSind_logit)*100  as actual
							from testpred
								group by deciles;
					quit;

					proc sql;
						create table predicted_actual as
							select deciles, predicted, actual, (predicted/actual) as pred_by_actual
								from predicted_actual
									quit;
				%end;

			%log_sco_walpcor_exp_csv(libname=work,dataset= predicted_actual,filename= predicted_actual);

			/*average churn rate*/
			proc sql;
				create table average_rate as
					select avg(actual) as average_rate
						from predicted_actual;
			quit;

			%log_sco_walpcor_exp_csv(libname=work,dataset=average_rate,filename= average_rate);
		%end;
%mend log_sco_walpcor_pos_sco;

%macro log_sco_walpcor_wrk;
	libname group "&grouppath.";
	%let originaloutputpath = &outputpath.;
	%let actual = %sysevalf(&actual./100);
	%let oversample = %sysevalf(&oversample./100);

	%if %index(&dependentvariable., /) = 0 %then
		%let out_keep = XXXind_logit YYYind_logit;
	%else %let out_keep = TRIALSind_logit;

	%do i = 1 %to 2;
		%if &i. = 1 %then
			%let current_betas = original;
		%if &i. = 2 %then
			%let current_betas = average;

		%let current_paramspath = &&&current_betas.betaspath.;
		
		%if &&&current_betas. ^= %str() %then 
			%do j = 1 %to %sysfunc(countw(&&&current_betas..));
				%let current_dataset_type = %scan(&&&current_betas.., &j.);

				%if &current_dataset_type. = dev %then
					%let cond = where = (&validationvar. = 1);

				%if &current_dataset_type. = validation %then
					%let cond = where = (&validationvar. = 0);

				%if &current_dataset_type. = dataset %then
					%let cond =;
				libname params "&current_paramspath.";

				%log_sco_walpcor(params=params.params,
					data=group.bygroupdata,
					wherecondition=&cond.,
					out=scored,
					out_keep=&out_keep.);

				%let outputpath = &originaloutputpath./&current_betas./&current_dataset_type.;
				libname out "&outputpath.";

				%log_sco_walpcor_pos_sco;

				proc export data = tempparams outfile="&outputpath./parameter_estimates.csv" replace;
				run;
				quit;

				data _null_;
					v1= "Logistic Regression - Scoring after alphacorrection for &current_betas./&current_dataset_type. completed.";
					file "&outputpath./unbiased_&current_betas._&current_dataset_type._completed.txt";
					put v1;
				run;
			%end;
	%end;

	/* Flex uses this file to test if the code has finished running */
	data _null_;
		v1= "Logistic Regression - Scoring after alphacorrection completed.";
		file "&originaloutputpath./UNBIASED_VALIDATION_COMPLETED.txt";
		put v1;
    run;

%mend log_sco_walpcor_wrk;

%log_sco_walpcor_wrk;