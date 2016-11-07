/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path./BIVARIATE_ANALYSIS_COMPLETED.txt;
%let append_yvar_counter = 0;

/* VERSION 2.1 */
dm log 'clear';
options mprint mlogic symbolgen mfile;

/*proc printto log="&output_path/BivariateAnalysis_Log.log";*/
/*run;*/
/*quit;*/
proc printto;
run;

quit;

/*proc printto print="&output_path/BivariateAnalysis_output.out";*/
libname in "&input_path.";
libname out "&output_path.";
libname group "&group_path.";

/*-----------------------------------------------------------------------------------------
Macro to round numeric variables in a dataset to two decimal places
Needs:
Input dataset with atleast one numeric variable
-----------------------------------------------------------------------------------------*/
%macro roundtotwodecimalplaces(in);

	proc contents data=&in. out=temp_out_contents;
	run;

	quit;

	data temp_out_contents(keep=newcol);
		set temp_out_contents(keep=name type);

		if type=1;
		newcol=compress(name)||"= round("||compress(name)||",0.01);";
	run;

	proc sql;
		select newcol into:roundstatement separated by " " from temp_out_contents;
	run;

	quit;

	data &in.;
		set &in.;
		&roundstatement.
			run;
%mend roundtotwodecimalplaces;

/*-----------------------------------------------------------------------------------------*/
%let grp=&groups.;

%MACRO bivariate;
	/* INITIAL STEPS */
	/*Create LIST OF VARIABLE NAMES*/
	data _null_;
		call symput("cont_vars", cats("'", tranwrd("&vars_cont."," ","','") ,"'"));
		call symput("cat_vars", cats("'", tranwrd("&vars_cat."," ","','") ,"'"));
		call symput("var_list", cat(compbl("&vars_cont."), " ", compbl("&vars_cat.")));
	run;

	%put &cont_vars;
	%put &cat_vars;
	%put &var_list;

	/*SUBSET the dataset for required variables*/
	data temp(keep = &dependent_variable. &vars_cont. &vars_cat. PRIMARY_KEY_1644 grp:);
		set in.dataworking;

		%if "&grp_no." ^= "0" %then
			%do;
				where compress(grp&grp_no._flag) = "&grp_flag";
			%end;
	run;

	%if %sysfunc(exist(group.bygroupdata)) %then
		%do;
			%put dataset exists;
		%end;
	%else
		%do;
			%if "&grp_no" = "0" %then
				%do;

					data group.bygroupdata;
						set temp;
					run;

				%end;
			%else
				%do;

					data group.bygroupdata;
						set temp(where = (GRP&grp_no._flag = "&grp_flag."));
					run;

				%end;
		%end;

	/*get total no. of observations to be read */
	%let dsid = %sysfunc(open(temp));
	%let nobs = %sysfunc(attrn(&dsid,NOBS));
	%let rc = %sysfunc(close(&dsid));
	%put &nobs;

	%if "&flag_categorical"="false" %then
		%do;
			/*get 'avg'/'count' of events for dependent var*/
			proc sql;
				%if "&flag_dep_bivariate." = "false" %then
					%do;
						select avg(&dependent_variable.) into :avg_depvar from temp;
					%end;

				%if "&flag_dep_bivariate." = "true" %then
					%do;
						select count(&dependent_variable.) into :total_events from temp where &dependent_variable. = &event.;
						select count(&dependent_variable.)/%sysevalf(&nobs.) into :mean_eventpercentage from temp where &dependent_variable. = &event.;
					%end;
			quit;

			%put avg_depvar = &avg_depvar;
			%put mean_event%age = &mean_eventpercentage;
			%put total_events = &total_events;

			/* loop across INDEPENDENT VARIABLES */
			%let i = 1;

			%do %until (not %length(%scan(&var_list,&i)));
				%let groups= &grp;
				%let this_var = %scan(&var_list,&i);

				/*PROC RANK - for continuous variables*/
				%if %index("&cont_vars.",&this_var.) > 0 %then
					%do;
						%if "&type_group" = "percentile" %then
							%do;
								/*==================================================== */
								/*	the below code snippet was added to rectify the logical error in percentile binning*/
								/*==================================================== */
								proc sql noprint;
									create table temp as
										select *
											from temp
												order by missing(&this_var.),&this_var.;
									;
								quit;

								proc rank data = temp (keep= &dependent_variable. &this_var. primary_key_1644) out = this_temp groups = &groups. ties=LOW;
									var &this_var.;
									ranks level;
								run;

								/*========================================================*/
							%end;
						%else
							%do;
								%if %index("&cont_vars.",&this_var.) > 0 %then
									%do;

										proc sql;
											select count(distinct &this_var.) into:count_level from temp;
										quit;

										%put &count_level;

										%if &count_level < &groups %then
											%let groups= &count_level;
									%end;

								proc univariate data = temp(keep = &dependent_variable. &this_var.);
									var &this_var.;
									output out = uni_output mean = mu std = sigma min = min range = range max = max;
								run;

								quit;

								data _null_;
									set uni_output;
									call symputx("min",min);
									call symputx("range",range);
									call symputx("max", max);
								run;

								data increment&i.(keep =increment);
									retain increment &min.;
									output;

									do k = 1 to &groups;
										increment + %sysevalf(&range./&groups);
										output;
									end;
								run;

								data _null_;
									set increment&i. nobs = no_obs;
									call symputx("increment_&i._"||left(input(put(_n_,3.),$3.)), increment);
									call symputx("no_obs",compress(no_obs));
								run;

								%put &increment_&i._1 &increment_&i._2 &no_obs;

								data this_temp;
									format level $200.;
									set temp(keep = PRIMARY_KEY_1644 &this_var. &dependent_variable.);

									%do k = 1 %to %eval(&no_obs.-1);
										%let j = %eval(&k. +1);

										%if &k. = 1 %then
											%do;
												if &&increment_&i._&k <= &this_var. then
													do;
														level = "&&increment_&i._&k. - &&increment_&i._&j";
													end;
											%end;
										%else
											%do;
												if &&increment_&i._&k < &this_var. <= &&increment_&i._&j then
													do;
														level = "&&increment_&i._&k. - &&increment_&i._&j";
													end;
											%end;

										%if k= %eval(&no_obs.-1) %then
											%do;
												%let j = %eval(&k. +1);

												if &this_var="." then
													do;
														level="&&increment_&i._&k. - &&increment_&i._&j";
													end;
											%end;
									%end;
								run;

							%end;
					%end;

				%if %index("&cont_vars.",&this_var.) > 0 %then
					%do;

						proc sql;
							create table temp2 as
								select *, min(&this_var.) as min_value, max(&this_var.) as max_value from this_temp
									group by level;
						quit;

						data this_temp;
						format level $200.;
							set temp2(drop=level);
							level=cat(min_value," - ",max_value);
						run;

					%end;

				%if (%index("&cont_vars.",&this_var.) > 0 ) %then
					%do;
						/*					===========================okokokk*/
						%let append_yvar_counter=%eval(&append_yvar_counter.+1);
						%put &append_yvar_counter.;

						data independenVar_binned (rename= (level=bin_&this_var.) );
							%if &append_yvar_counter. = 1 %then
								%do;
									set this_temp(keep=level primary_key_1644 );
								%end;
							%else
								%do;
									merge independenVar_binned this_temp(keep=level primary_key_1644);
								%end;
						run;

						data independenVar_binned;
							set independenVar_binned;
							format newtempvar $200.;
							newtempvar = bin_&this_var.;
							newtempvar = strip(newtempvar);
							drop bin_&this_var.;
							if(strip(newtempvar) in ("."," ",". - .",".-.")) then
								newtempvar = "NA";
							rename newtempvar = bin_&this_var.;
						run;

						/*				   ====================================okokoko*/
					%end;

				%if (%index("&cat_vars.",&this_var.) > 0 ) %then
					%do;
						/*					===========================okokokk*/
						%let append_yvar_counter=%eval(&append_yvar_counter.+1);
						%put &append_yvar_counter.;

						data independenVar_binned (rename= (&this_var.=bin_&this_var.) );
							%if &append_yvar_counter. = 1 %then
								%do;
									set temp(keep=&this_var. primary_key_1644 );
								%end;
							%else
								%do;
									merge independenVar_binned temp(keep=&this_var. primary_key_1644);
								%end;
						run;

						data independenVar_binned;
							set independenVar_binned;
							format newtempvar $200.;
							newtempvar = bin_&this_var.;
							newtempvar = strip(newtempvar);
							drop bin_&this_var.;
							if(strip(newtempvar) in ("."," ",". - .",".-.")) then
								newtempvar = "NA";
							rename newtempvar = bin_&this_var.;
						run;

						/*				   ====================================okokoko*/
					%end;

				/*get the required values*/
				proc sql;
					create table &this_var. as

						%if %index("&cont_vars.",&this_var.) > 0 %then
							%do;
								select level, min(&this_var.) as min_value, max(&this_var.) as max_value, avg(&this_var.) as mean_value,
							%end;
						%else %if %index("&cat_vars.",&this_var.) > 0 %then
							%do;
								select &this_var. as level,
							%end;

						count(*) as class_num_obs, &nobs. as total_num_obs,
						(calculated class_num_obs/%sysevalf(&nobs.))*100 as class_per_obs FORMAT=12.2,

						%if "&flag_dep_bivariate." = "true" %then
							%do;
								sum(CASE WHEN &dependent_variable. = &event. then 1 else 0 end) as num_event_class, 
								(count(*)- calculated num_event_class) as num_nonevent_class, 
								(calculated num_event_class/%eval(&total_events.))*100 as global_eventpercentage FORMAT=12.2,
								(calculated num_event_class/count(*))*100 as class_eventpercentage FORMAT=12.2, 
								(&mean_eventpercentage.*100) as mean_eventpercentage FORMAT=12.2,
								log(calculated num_event_class/((count(*))-(calculated num_event_class))) as plotvar FORMAT=12.2
							%end;

						%if "&flag_dep_bivariate." = "false" %then
							%do;
								avg(&dependent_variable.) as avg_dependent_variable FORMAT=12.2, (avg(&dependent_variable.)/%sysevalf(&avg_depvar.))*100 as Index FORMAT=12.2
							%end;

						%if %index("&cont_vars.",&this_var.) > 0 %then
							%do;
								from this_temp
							%end;
						%else %if %index("&cat_vars.",&this_var.) > 0 %then
							%do;
								from temp
							%end;

						group by level;
				quit;

				/*get Range & Std.dev of class event-%age : in case of binary dependent variable*/
				%if "&flag_dep_bivariate." = "true" %then
					%do;

						proc sql;
							create table &this_var. as
								select *, range(class_eventpercentage) as range FORMAT=12.2, std(class_eventpercentage) as stddev FORMAT=12.2
									from &this_var.;
						quit;

					%end;

				/*to sort levels in case independent variables is continous*/
				%if %index("&cont_vars.",&this_var.) >0 %then
					%do;

						proc sort data= &this_var.;
							by min_value;
						run;

					%end;

				%roundtotwodecimalplaces(in=&this_var.);

				/* if a variable is selected from continuous and categorical panel both it has to present in both the folders */
				%if (%index("&vars_cont.",&this_var.) >0 and %index("&vars_cat.",&this_var.) >0) %then
					%do;
						%let new_output_path = &output_path./Continuous;

						proc export data = &this_var.
							outfile = "&new_output_path./&this_var..csv"
							dbms = csv replace;
						run;

						quit;

						%let new_output_path = &output_path./Categorical;

						proc export data = &this_var.
							outfile = "&new_output_path./&this_var..csv"
							dbms = csv replace;
						run;

						quit;

					%end;
				%else
					%do;
						%if %index("&vars_cont.",&this_var.) > 0 %then
							%do;
								%let new_output_path = &output_path./Continuous;
							%end;

						%if %index("&vars_cat.",&this_var.) > 0 %then
							%do;
								%let new_output_path = &output_path./Categorical;
							%end;

						data &this_var.;
							retain level;
								set &this_var.;
								format newtempvar $100.;
								newtempvar = level;
								newtempvar = strip(newtempvar);
								drop level;
								if(strip(newtempvar) in ("."," ",". - .",".-.")) then
									newtempvar = "NA";
								rename newtempvar = level;


						run;


						data &this_var.;
							merge &this_var.(keep=level) &this_var.(drop=level);
							run;

						/*export to CSV*/
						proc export data = &this_var.
							outfile = "&new_output_path./&this_var..csv"
							dbms = csv replace;
						run;

						quit;

					%end;

				%let i = %eval(&i.+1);
			%end;
		%end;
	%else
		%do;
			/*get 'avg'/'count' of events for dependent var*/
			proc sql;
				select count(&dependent_variable.) into :total_events separated by " " from temp group by &dependent_variable.;
				select count(&dependent_variable.)/%sysevalf(&nobs.) into :mean_eventpercentage separated by " " from temp group by &dependent_variable.;
			quit;

			%put mean_event%age = &mean_eventpercentage;
			%put total_events = &total_events;

			/* loop across INDEPENDENT VARIABLES */
			%let i = 1;

			%do %until (not %length(%scan(&var_list,&i)));
				%let groups= &grp;
				%let this_var = %scan(&var_list,&i);

				proc sort data=temp out=temp_sort;
					by &dependent_variable.;
				run;

				/*PROC RANK - for continuous variables*/
				%if %index("&cont_vars.",&this_var.) > 0 %then
					%do;
						%if "&type_group"="percentile" %then
							%do;
								/*==================================================== */
								/*	the below code snippet was added to rectify the logical error in percentile binning*/
								/*==================================================== */
								proc sql noprint;
									create table temp as
										select *
											from temp
												order by missing(&this_var.),&this_var.;
									;
								quit;

								proc rank data = temp (keep= &dependent_variable. &this_var. primary_key_1644) out = this_temp groups = &groups. ties=low;
									var &this_var.;
									ranks level;
								run;

								/*========================================================*/
							%end;
						%else
							%do;
								%if %index("&cont_vars.",&this_var.) > 0 %then
									%do;

										proc sql;
											select count(distinct &this_var.) into:count_level from temp;
										quit;

										%put &count_level;

										%if &count_level < &groups %then
											%let groups= &count_level;
									%end;

								proc univariate data = temp(keep = &dependent_variable. &this_var.);
									var &this_var.;
									output out = uni_output mean = mu std = sigma min = min range = range max = max;
								run;

								quit;

								data _null_;
									set uni_output;
									call symputx("min",min);
									call symputx("range",range);
									call symputx("max", max);
								run;

								data increment&i.(keep =increment);
									retain increment &min.;
									output;

									do k = 1 to &groups;
										increment + %sysevalf(&range./&groups);
										output;
									end;
								run;

								data _null_;
									set increment&i. nobs = no_obs;
									call symputx("increment_&i._"||left(input(put(_n_,3.),$3.)), increment);
									call symputx("no_obs",compress(no_obs));
								run;

								%put &increment_&i._1 &increment_&i._2 &no_obs;

								data this_temp;
									format level $200.;
									set temp(keep = PRIMARY_KEY_1644 &this_var. &dependent_variable.);

									%do k = 1 %to %eval(&no_obs.-1);
										%let j = %eval(&k. +1);

										%if &k. = 1 %then
											%do;
												if &&increment_&i._&k <= &this_var. then
													do;
														level = "&&increment_&i._&k. - &&increment_&i._&j";
													end;
											%end;
										%else
											%do;
												if &&increment_&i._&k < &this_var. <= &&increment_&i._&j then
													do;
														level = "&&increment_&i._&k. - &&increment_&i._&j";
													end;
											%end;

										%if k= %eval(&no_obs.-1) %then
											%do;
												%let j = %eval(&k. +1);

												if &this_var="." then
													do;
														level="&&increment_&i._&k. - &&increment_&i._&j";
													end;
											%end;
									%end;
								run;

							%end;
					%end;

				%if %index("&cont_vars.",&this_var.) > 0 %then
					%do;

						proc sql;
							create table temp2 as
								select *, min(&this_var.) as min_value, max(&this_var.) as max_value from this_temp
									group by level;
						quit;

						data this_temp;
							format level $200.;
							set temp2(drop=level);
							level=cat(min_value," - ",max_value);
						run;

					%end;

				%if (%index("&cont_vars.",&this_var.) > 0 ) %then
					%do;
						/*					===========================okokokk*/
						%let append_yvar_counter=%eval(&append_yvar_counter.+1);
						%put &append_yvar_counter.;

						data independenVar_binned (rename= (level=bin_&this_var.) );
							%if &append_yvar_counter. = 1 %then
								%do;
									set this_temp(keep=level primary_key_1644);
								%end;
							%else
								%do;
									merge independenVar_binned this_temp(keep=level primary_key_1644);
								%end;
						run;

						data independenVar_binned;
							set independenVar_binned;
							format newtempvar $200.;
							newtempvar = bin_&this_var.;
							newtempvar = strip(newtempvar);
							drop bin_&this_var.;
							if(strip(newtempvar) in ("."," ",". - .",".-.")) then
								newtempvar = "NA";
							rename newtempvar = bin_&this_var.;
						run;

					%end;

				/*				   ====================================okokoko*/
				%if (%index("&cat_vars.",&this_var.) > 0 ) %then
					%do;
						/*					===========================okokokk*/
						%let append_yvar_counter=%eval(&append_yvar_counter.+1);
						%put &append_yvar_counter.;

						data independenVar_binned (rename= (&this_var.=bin_&this_var.) );
							%if &append_yvar_counter. = 1 %then
								%do;
									set temp(keep=&this_var. primary_key_1644 );
								%end;
							%else
								%do;
									merge independenVar_binned temp(keep=&this_var. primary_key_1644);
								%end;
						run;

						data independenVar_binned;
							set independenVar_binned;
							format newtempvar $200.;
							newtempvar = bin_&this_var.;
							newtempvar = strip(newtempvar);
							drop bin_&this_var.;
							if(strip(newtempvar) in ("."," ",". - .",".-.")) then
								newtempvar = "NA";
							rename newtempvar = bin_&this_var.;
						run;

						/* ====================================okokoko*/
					%end;

				/*get the required values*/
				proc sql;
					create table &this_var. as

						%if %index("&cont_vars.",&this_var.) > 0 %then
							%do;
								select level, min(&this_var.) as min_value, max(&this_var.) as max_value, avg(&this_var.) as mean_value,
							%end;
						%else %if %index("&cat_vars.",&this_var.) > 0 %then
							%do;
								select &this_var. as level,
							%end;

						count(*) as class_num_obs, &nobs. as total_num_obs,
						(calculated class_num_obs/%sysevalf(&nobs.))*100 as class_per_obs FORMAT=12.2

						%if %index("&cont_vars.",&this_var.) > 0 %then
							%do;
								from this_temp
							%end;
						%else %if %index("&cat_vars.",&this_var.) > 0 %then
							%do;
								from temp
							%end;

						group by level;
				quit;

				proc sql;
					create table &this_var.1 as

						%if %index("&cont_vars.",&this_var.) > 0 %then
							%do;
								select level,count(*) as class_num_obs, &dependent_variable.
							%end;
						%else %if %index("&cat_vars.",&this_var.) > 0 %then
							%do;
								select &this_var. as level,count(*) as class_num_obs, &dependent_variable.
							%end;

						%if %index("&cont_vars.",&this_var.) > 0 %then
							%do;
								from this_temp
							%end;
						%else %if %index("&cat_vars.",&this_var.) > 0 %then
							%do;
								from temp
							%end;

						group by &dependent_variable.,level;
				quit;

				proc sort data= &this_var.1;
					by level;
				run;

				proc sql;
					create table &this_var.1 as
						select level,class_num_obs, &dependent_variable., (class_num_obs/sum(class_num_obs))*100 as Perc FORMAT=12.2 from &this_var.1
							group by level;
				quit;

				proc transpose data=&this_var.1 out=&this_var.2(drop=_name_);
					by level;
					id &dependent_variable.;
					var class_num_obs;
				run;

				data &this_var.1;
					set &this_var.1;
					&dependent_variable.1=cat("Perc_",&dependent_variable.);
				run;

				proc transpose data=&this_var.1 out=&this_var.3(drop=_name_);
					by level;
					id &dependent_variable.1;
					var Perc;
				run;

				proc sql;
					create table &this_var.1 as
						select level,class_num_obs, &dependent_variable., (class_num_obs/sum(class_num_obs))*100 as global FORMAT=12.2 from &this_var.1
							group by &dependent_variable.;
				quit;

				data &this_var.1;
					set &this_var.1;
					&dependent_variable.1=cat("Global_",&dependent_variable.);
				run;

				proc sort data= &this_var.1;
					by level;
				run;

				proc transpose data=&this_var.1 out=&this_var.4(drop=_name_);
					by level;
					id &dependent_variable.1;
					var global;
				run;

				data &this_var.;
					merge &this_var.(drop=total_num_obs class_per_obs) &this_var.2  &this_var.3 &this_var.4;
					by level;
				run;

				/*to sort levels in case independent variables is continous*/
				%if %index("&cont_vars.",&this_var.) >0 %then
					%do;

						proc sort data= &this_var.;
							by min_value;
						run;

					%end;

				/*				%roundtotwodecimalplaces(in=&this_var.);*/
				/* if a variable is selected from continuous and categorical panel both it has to present in both the folders */
				%if (%index("&vars_cont.",&this_var.) >0 and %index("&vars_cat.",&this_var.) >0) %then
					%do;
						%let new_output_path = &output_path./Continuous;

						proc export data = &this_var.
							outfile = "&new_output_path./&this_var..csv"
							dbms = csv replace;
						run;

						quit;

						%let new_output_path = &output_path./Categorical;

						proc export data = &this_var.
							outfile = "&new_output_path./&this_var..csv"
							dbms = csv replace;
						run;

						quit;

					%end;
				%else
					%do;
						%if %index("&vars_cont.",&this_var.) >0 %then
							%do;
								%let new_output_path = &output_path./Continuous;
							%end;

						%if %index("&vars_cat.",&this_var.) >0 %then
							%do;
								%let new_output_path = &output_path./Categorical;
							%end;

						/*export to CSV*/
						data &this_var.;
							retain level;
								set &this_var.;
								format newtempvar $100.;
								newtempvar = level;
								newtempvar = strip(newtempvar);
								drop level;	
								if(strip(newtempvar) in ("."," ",". - .",".-.")) then
									newtempvar = "NA";
								rename newtempvar = level;
						run;

						data &this_var.;
							merge &this_var.(keep=level) &this_var.(drop=level);
							run;

						proc export data = &this_var.
							outfile = "&new_output_path./&this_var..csv"
							dbms = csv replace;
						run;

						quit;

					%end;

				%let i = %eval(&i.+1);
			%end;
		%end;

	/*=========================================================================*/
	/*	%if (&vars_cont. ne  ) %then*/
	/*		%do;*/
	proc sort data= independenVar_binned;
		by primary_key_1644;
	run;

	%if %sysfunc(exist(out.binned_data)) %then
		%do;

			data out.binned_data;
				merge out.binned_data independenVar_binned;
			run;

		%end;
	%else
		%do;

			data out.binned_data;
				set independenVar_binned;
			run;

		%end;

	/*		%end;*/
	/*		================================================================*/
%MEND bivariate;

%bivariate;

/* Flex uses this file to test if the code has finished running */
data _NULL_;
	v1= "EDA - BIVARIATE_ANALYSIS_COMPLETED";
	file "&output_path./BIVARIATE_ANALYSIS_COMPLETED.txt";
	PUT v1;
run;

/**/
/*proc datasets lib=work kill nolist;*/
/*quit;*/