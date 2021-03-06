*processbody;
/*Mumix Contribution code*/
/*Date: 5/14/2013*/
/*Author: Ankesh*/
/*parameters required:*/
/*%let model_csv_path=model selected output path*/
/*%let output_path=output path for the csvs*/
/*%let group_path= input path of bygroupdata of that model*/
/*%let panel_level_name= south/supercentre/south#supercenter*/
/*%let panel_name=panel selected parameter*/
/*%let model_date_var=date variable chosen to publish*/
options mprint mlogic symbolgen mfile;

proc printto log="&output_path./contribution_Log.log";
run;
quit;

/*proc printto;*/
/*run;*/

/*proc printto print="&output_path./contribution_Output.out";*/
/*	run;*/
/*	quit;*/
/*Assigning libnames*/
libname group "&group_path.";
libname out "&output_path.";

%macro contribution;
	/*Importing the estimates csv*/
	proc import datafile="&model_csv_path./estimates.csv"
		out = estimate
		dbms = csv
		replace;
		getnames=yes;
		guessingrows=50;
	run;

	/*Importing the normal_chart csv for actual and predicted values*/
	%if %sysfunc(fileexist("&model_csv_path./transformed_chart.csv")) %then
		%do;
			%let csv = transformed_chart.csv;
		%end;
	%else
		%do;
			%let csv = normal_chart.csv;
		%end;

	proc import datafile="&model_csv_path./&csv."
		out = predicted
		dbms = csv
		replace;
		getnames=yes;
		guessingrows=50;
	run;

	data _null_;
		call symput("independentVariables" , tranwrd("&independentVariables.","|| ","||"));
	run;

	%put &independentVariables.;

	data _null_;
		call symput("independentTransformation" , tranwrd("&independentTransformation.","|| ","||"));
	run;

	%put &independentTransformation.;

	data _null_;
		call symput("fixedEquationVariables" , tranwrd("&fixedEquationVariables.","|| ","||"));
	run;

	%put &fixedEquationVariables.;

	/*Subsetting the dataset and renaming the columns*/
	data actual_pred(keep= pred actual rename=pred=pred_dep rename=actual=actual_dep);
		set predicted;
	run;

	/*Subsetting the dataset and deleting the row corresponding to the intercept*/
	data estimate_no_intercept;
		format original_variable $50.;
		set estimate (keep= original_variable original_estimate Iteration_transformation);

		if Iteration_transformation="log" then
			original_variable = cat("log_",original_variable);
		original_estimate = round(original_estimate , .000000000000001);

		if original_variable='Intercept' then
			delete;
	run;

	/*Creating macro variables*/
	%let intercept_estimate=;

	proc sql;
		select original_estimate into: intercept_estimate from estimate where (original_variable = "Intercept");
	quit;

	proc sql;
		select original_estimate into: var_estimates separated by " " from estimate_no_intercept;
	quit;

	proc sql;
		select original_variable into: var separated by " " from estimate_no_intercept;
	quit;

	%put &intercept_estimate.;

	/*Creating the macro variables from the input parameters*/
/*	data _null_;*/
/*		call symput("panel_level",translate("&panel_level_name.","   ","#||"));*/
/*	run;*/
/**/
/*	%put &panel_level.;*/
/**/
/*	data _null_;*/
/*		call symput("panel_level",tranwrd("&panel_level.","  "," "));*/
/*	run;*/
/**/
/*	%put &panel_level.;*/
/**/
/*	data _null_;*/
/*		call symput("panel",translate("&panel_name.","   ","#||"));*/
/*	run;*/
/**/
/*	%put &panel.;*/
/**/
/*	data _null_;*/
/*		call symput("panel",tranwrd("&panel.","  "," "));*/
/*	run;*/
/**/
/*	%put &panel.;*/

	/*Creating the union column*/
/*	%if (%index(&panel_name. , #)) > 0 %then*/
/*		%do;*/
/*			%let a = %scan(&panel_name.,1,"||");*/
/**/
/*			data _null_;*/
/*				call symputx("abc" , tranwrd("&a.","#"," , "));*/
/*			run;*/
/**/
/*			%put &abc.;*/
/**/
/*			data group.bygroupdata;*/
/*				set group.bygroupdata;*/
/*				union = catx("_",&abc.);*/
/*			run;*/
/**/
/*		%end;*/


/*modified by saurabh*/

	%let panel_name_copy=&panel_name.;
	data _null_;
	call symput("new_panel_name",tranwrd("&panel_name.","#",","));
	run;
	
	%let keep_panel=;
	%let old_name=;
	
/*Create panel&abc. column which has merged panel members in it*/	
	%do abc=1 %to %sysfunc(countw("&panel_name.","||"));
		%let curr_panel_name=%scan("&panel_name.",&abc.,"||");
		%let curr_new_panel_name=%scan("&new_panel_name.",&abc.,"||");
		%if %index("&curr_panel_name.",#) > 0 %then %do;
		data group.bygroupdata;
  			set group.bygroupdata;
			panel&abc.=catx("@",&curr_new_panel_name.);		
			run;
		
		data _null_;
		call symput("panel_name",tranwrd("&panel_name.","&curr_panel_name.","panel&abc."));
		run;
		
		%let keep_panel=&keep_panel panel&abc.;
		%let old_name=&old_name &curr_panel_name.;
		%end;
		%put keeeep &keep_panel.;
		%put oldddd &old_name.;
/*		%put &panel_name.;*/
	%end;	
%put here is the &panel_name.;


data _null_;
	call symput("panel",tranwrd("&panel_name.","||"," "));
	run;

data _null_;
	call symput("panel_level_name",tranwrd("&panel_level_name.","#","@"));
	run;


  %put hey there &panel_level_name.;

 /*modification ends here*/

/*Creating the contribution csv with estimates*var column*/
	data contribution;
		set group.bygroupdata (keep= &var. &panel. &model_date_var.);
			%do i=1 %to %sysfunc(countw(&var_estimates.," "));
				%let t = %scan(&var_estimates.,&i.," ");

				%scan(&var.,&i.) = %scan(&var.,&i.)*%sysevalf(&t.);
			%end;

			%if "&intercept_estimate."^="" %then
				%do;
					intercept = &intercept_estimate.;
				%end;

			&model_date_var.=&model_date_var.;
	run;

	/*Merging with actual_pred to get these two columns*/
	data contribution;
		merge contribution actual_pred;
	run;

	data contribution;
		set contribution;

		%if "&dependentTransformation."="log" %then
			%do;
				pred_antilog_var = exp(pred_dep);
			%end;
		%else
			%do;
				pred_antilog_var = pred_dep;
			%end;
	run;

	/*Creating the macro variables with _ instead of hash*/
	%if (%index(&panel_name. , #)) > 0 %then
		%do;

			data _null_;
				call symput("panel_level_hash",tranwrd("&panel_level_name.","#","_"));
				call symput("panel_mem_pipe",tranwrd("&panel_level_name.","#"," "));
			run;

			%put &panel_level_hash.;
			%put &panel_mem_pipe.;

			data _null_;
				call symput("panel_name_a",tranwrd("&panel_name.","#","_"));
				call symput("panel_var_pipe",tranwrd("&panel_name.","#"," "));
			run;

			%put &panel_name_a.;
			%put &panel_var_pipe.;
		%end;
	%else
		%do;
			%let panel_level_hash = &panel_level_name.;
			%let panel_name_a = &panel_name.;
		%end;

	%if %sysfunc(exist(contribution_combination)) %then
		%do;

			proc datasets library=work;
				delete contribution_combination;
			run;

		%end;

	/*susetting the dataset on the basis of combination of the vars*/
	%if (%index(&panel_name. , #)) > 0 %then
		%do;
			%do i=1 %to %sysfunc(countw(&panel_level_hash.,"||"));

				data contribution_combination&i.;
					length panel_level $50.;
					length panel_name $50.;
					set contribution;
					where union = "%scan(&panel_level_hash.,&i.,"||")";
					panel_level = "&panel_mem_pipe.";
					panel_name = "&panel_var_pipe.";
				run;

				/*Appending the combination var datasets*/
				%if &i = 1 %then
					%do;

						data contribution_combination;
							set contribution_combination&i.;
						run;

					%end;
				%else
					%do;

						proc append base=contribution_combination data=contribution_combination&i. force;
						run;

					%end;
			%end;
		%end;

	/*creating the macro variables from parameters*/
	data _null_;
		call symput("panel_level_ind",tranwrd("&panel_level_name.","||","#"));
	run;

	%put &panel_level_ind.;

	data _null_;
		call symput("panel_ind",tranwrd("&panel_name.","||","#"));
	run;

	%put &panel_ind.;

	/* creating a dataset having all the panel and its corresponding levels */
	data distinct;
		format panel_var $32.;
		format panel_lev $32.;

		%do i=1 %to %sysfunc(countw(&panel_level_ind.,"#"));
			panel_var= "%scan(&panel_ind.,&i.,"#")";
			panel_lev= "%scan(&panel_level_ind.,&i.,"#")";
			output;
		%end;
	run;

	/* now selecting only those rows which are distinct in both the columns.*/
	proc sql;
		create table distinct as
			select distinct * from distinct;
		select panel_var into:panel_ind separated by "#"
			from distinct;
		select panel_lev into:panel_level_ind separated by "#"
			from distinct;
	quit;

	%put &panel_ind.;
	%put &panel_level_ind.;


	/*Individual vars*/
	%do i=1 %to %sysfunc(countw(&panel_level_ind.,"#"));

		/*get vartype*/
		%let dsid = %sysfunc(open(contribution));
		%let varnum = %sysfunc(varnum(&dsid,%scan(&panel_ind., &i.,"#")));
		%let vartyp = %sysfunc(vartype(&dsid,&varnum)); /* variable type */
		%let rc = %sysfunc(close(&dsid));
		%put &vartyp;

		/*subsetting the dataset on the basis of individual vars*/
		data contribution&i.;
			length panel_level $50.;
			length panel_name $50.;
			set contribution;

			%if &vartyp. = N %then
				%do;
					where %scan(&panel_ind.,&i.,"#") = %scan(&panel_level_ind.,&i.,"#");
				%end;
			%else
				%do;
					where %scan(&panel_ind.,&i.,"#") = "%scan(&panel_level_ind.,&i.,"#")";
				%end;

			panel_level = "%scan(&panel_level_ind.,&i,"#")";
			panel_name = "%scan(&panel_ind.,&i.,"#")";
		run;

		/*Appending the individual var datasets*/
		%if &i = 1 %then
			%do;

				data contribution_individual;
					set contribution&i.;
				run;

			%end;
		%else
			%do;

				proc append base=contribution_individual data=contribution&i. force;
				run;

			%end;
	%end;

	/*deleting the temporary datasets*/
	%if (%index(&panel_name. , #)) > 0 %then
		%do;
			%do i=1 %to %sysfunc(countw(&panel_level_hash.,"||"));

				proc datasets library=work;
					delete contribution_combination&i.;
				run;

			%end;
		%end;

	%do i=1 %to %sysfunc(countw(&panel_level_ind.,"#"));

		proc datasets library=work;
			delete contribution&i.;
		run;

	%end;

	/*Appending all the datasets i.e. both combined and individual*/
	%if %sysfunc(exist(contribution_combination)) %then
		%do;

			proc append base=contribution_individual data = contribution_combination force;
			run;

		%end;

	data overall;
		set contribution;
		length panel_level $50.;
		length panel_name $50.;
		panel_name="Overall";
		panel_level = "All";
	run;

	/*Appending all the datasets i.e. both combined and individual and overall*/
	proc append base=contribution_individual data = overall force;
	run;

	/*Dropping the unrequired columns*/
	data contribution_final(drop = &panel. %if (%index(&panel_name. , #)) > 0 %then %do;
		union
		%end;
		);
		set contribution_individual;
	run;

	/*Making the macro variable for rearranging*/
	data _null_;
		call symput("vars",tranwrd("&var."," ",","));
	run;

	/*Manipulating the Baseline variables parameter if it has been logged while modeling*/
	%if "&baselineVariables."^="" %then
		%do;
			%let baselineVariable =;

			%do a=1 %to %sysfunc(countw(&baselineVariables.,"||"));
				%let baseline_var=%scan(&baselineVariables.,&a.,"||");
				%let baseline_trans=%scan(&baselineTransformation.,&a.,"||");

				%if "&baseline_trans."="none" %then
					%do;
						%let baselineVariable = &baselineVariable. &baseline_var.;
					%end;
				%else
					%do;
						%let baselineVariable = &baselineVariable. log_&baseline_var.;
					%end;
			%end;

			%put &baselineVariable.;
			%let baselineVariables = &baselineVariable.;
			%put &baselineVariables.;

			data _null_;
				call symput("baselineVariables",tranwrd("&baselineVariables."," ","||"));
			run;

		%end;

	/*Sum of the baseline variables*/
	%if "&baselineVariables."^="" %then
		%do;;

			data _null_;
				call symput("baseline_sum",tranwrd("&baselineVariables.","||","+"));
			run;

			%put &baseline_sum.;

			/*Calculating the intercept which includes both intercept,baseline and class variables*/
			data contribution_final;
				set contribution_final;
				intercept_baseline =

				%if "&intercept_estimate."^="" %then
					%do;
						intercept +
					%end;

				&baseline_sum.;
			run;

		%end;
	%else
		%do;
			%if "&intercept_estimate."^="" %then
				%do;

					data contribution_final;
						set contribution_final;
						intercept_baseline = intercept;
					run;

				%end;
		%end;

	data contribution_final;
		set contribution_final;
		baseline = exp(intercept_baseline);
	run;

	/*Manipulating the marketing variables parameter whether it has been logged or nor while modeling*/
	%if "&marketingVariables."^="" %then
		%do;
			%let marketingVariable =;

			%do a=1 %to %sysfunc(countw(&marketingVariables.,"||"));
				%let marketing_var=%scan(&marketingVariables.,&a.,"||");
				%let marketing_trans=%scan(&marketingTransformation.,&a.,"||");

				%if "&marketing_trans."="none" %then
					%do;
						%let marketingVariable = &marketingVariable. &marketing_var.;
					%end;
				%else
					%do;
						%let marketingVariable = &marketingVariable. log_&marketing_var.;
					%end;
			%end;

			%put &marketingVariable.;
			%let marketingVariables = &marketingVariable.;
			%put &marketingVariables.;

			data _null_;
				call symput("marketingVariables",tranwrd("&marketingVariables."," ","||"));
			run;

		%end;

	/*calculation of intermediate lift in the variable*/
	data contribution_intermediate_lift;
		set contribution_final;

		%do k = 1 %to %sysfunc(countw(&marketingVariables. , "||"));
			%if "&dependentTransformation." = "log" %then
				%do;
					%if "&intercept_estimate."="" and "&baselineVariables.."="" %then
						%do;
							%scan("&marketingVariables." , &k. , "||") = exp(%scan("&marketingVariables." , &k. , "||"));
						%end;
					%else
						%do;
							%scan("&marketingVariables." , &k. , "||") = exp(%scan("&marketingVariables." , &k. , "||") + intercept_baseline);
						%end;
				%end;
			%else
				%do;
					%scan("&marketingVariables." , &k. , "||") = %scan("&marketingVariables." , &k. , "||");
				%end;
		%end;
	run;

	/*Sum of marketing variables*/
	%if "&marketingVariables."^="" %then
		%do;;

			data _null_;
				call symput("marketing_sum",tranwrd("&marketingVariables.","||","+"));
			run;

		%end;

	%put &marketing_sum.;

	/*Calculation in the lift of the variable*/
	data contribution_lift;
		set contribution_intermediate_lift;

		%do k = 1 %to %sysfunc(countw(&marketingVariables. , "||"));
			%if "&dependentTransformation." = "log" %then
				%do;
					%if "&intercept_estimate."="" and "&baselineVariables.."="" %then
						%do;
							%scan("&marketingVariables." , &k. , "||") = %scan("&marketingVariables." , &k. , "||");
						%end;
					%else
						%do;
							%scan("&marketingVariables." , &k. , "||") = (%scan("&marketingVariables." , &k. , "||") - baseline);
						%end;
				%end;
			%else
				%do;
					%scan("&marketingVariables." , &k. , "||") = %scan("&marketingVariables." , &k. , "||");
				%end;
		%end;

		baseline = baseline - 1;
		overall_sum = (&marketing_sum. + baseline);
	run;

	data contribution_lift_splitting;
		set contribution_lift;

		%if "&dependentTransformation." = "log" %then
			%do;
				%do k = 1 %to %sysfunc(countw(&marketingVariables. , "||"));
					%scan("&marketingVariables." , &k. , "||") = (%scan("&marketingVariables." , &k. , "||")*pred_antilog_var)/overall_sum;
				%end;
			%end;

		baseline = (baseline*pred_antilog_var)/overall_sum;
	run;

	/*Splitting of contributions among the baseline variables*/
	data final_baseline_con;
		set contribution_lift_splitting;

		%if "&dependentTransformation." = "log" %then
			%do;
				%do z = 1 %to %sysfunc(countw(&baselineVariables.,"||"));
					%scan("&baselineVariables.",&z.,"||") = exp(%scan("&baselineVariables.",&z.,"||")+intercept) - exp(intercept);
				%end;

				intercept = exp(intercept) - 1;
			%end;
	run;

	data final_con;
		set final_baseline_con;

		%if "&baselineVariables."^="" %then
			%do;
				overall_bb = &baseline_sum. + intercept;
			%end;
		%else
			%do;
				overall_bb = intercept;
			%end;

		%if "&dependentTransformation." = "log" %then
			%do;
				%do z = 1 %to %sysfunc(countw(&baselineVariables.,"||"));
					%scan("&baselineVariables.",&z.,"||") = ((%scan("&baselineVariables.",&z.,"||"))*baseline)/overall_bb;
				%end;

				intercept = (intercept*baseline)/overall_bb;
			%end;
	run;

	/* calculation of absolute contribution values */
	/*data contribution_final1;*/
	/*	set contribution_final;*/
	/*	%do k = 1 %to %sysfunc(countw(&independentVariables. , "||"));*/
	/*		%let chk_transform = %scan("&independentTransformation." , &k. , "||");*/
	/*		%put &chk_transform.;*/
	/*		%if "&chk_transform." = "log" %then %do;*/
	/*			%if "&dependentTransformation." = "log" %then %do;*/
	/*				%if "&intercept_estimate."^="" %then %do;*/
	/*				log_%scan("&independentVariables." , &k. , "||") = (log_%scan("&independentVariables." , &k. , "||")*(pred_antilog_var-exp(intercept)))/(pred_dep-intercept);*/
	/*				%end;*/
	/*				%else %do;*/
	/*				log_%scan("&independentVariables." , &k. , "||") = (log_%scan("&independentVariables." , &k. , "||")*(pred_antilog_var))/(pred_dep);*/
	/*				%end;*/
	/*			%end;*/
	/*			%else %do;*/
	/*				log_%scan("&independentVariables." , &k. , "||") = log_%scan("&independentVariables." , &k. , "||");*/
	/*			%end;*/
	/*		%end;*/
	/*		%else %do;*/
	/*			%if "&dependentTransformation." = "log" %then %do;*/
	/*				%if "&intercept_estimate."^="" %then %do;*/
	/*				%scan("&independentVariables." , &k. , "||") = (%scan("&independentVariables." , &k. , "||")*(pred_antilog_var-exp(intercept)))/(pred_dep-intercept);*/
	/*				%end;*/
	/*				%else %do;*/
	/*				%scan("&independentVariables." , &k. , "||") = (%scan("&independentVariables." , &k. , "||")*(pred_antilog_var))/(pred_dep);*/
	/*				%end;*/
	/**/
	/*			%end;*/
	/*			%else %do;*/
	/*				%scan("&independentVariables." , &k. , "||") = %scan("&independentVariables." , &k. , "||");*/
	/*			%end;*/
	/*		%end;*/
	/*	%end;*/
	/**/
	/*		data contribution_final1;*/
	/*			set contribution_final1;*/
	/*			%if "&dependentTransformation." = "log" %then %do;*/
	/*					%if "&intercept_estimate."^="" %then %do;*/
	/*						intercept = exp(intercept);*/
	/*					%end;*/
	/*					*/
	/*			%end;*/
	/*			%else %do;*/
	/*				%if "&intercept_estimate."^="" %then %do;*/
	/*					intercept = intercept;*/
	/*				%end;*/
	/*			%end;*/
	/*			run;*/
	/*Rearranging the columns*/
	proc sql;
		create table contribution_final1 as
			select panel_name,panel_level,&model_date_var.,

			%if "&intercept_estimate."^="" %then
				%do;
					intercept,
				%end;

			&vars.,pred_dep,actual_dep,pred_antilog_var
			from final_con;
	quit;

%macro subset;

	proc sql;
		select distinct(panel_name) into: distinct_name separated by '$' from contribution_final1;
	quit;

	%put &distinct_name.;

	%do l=1 %to %sysfunc(countw(&distinct_name.,'$'));

		proc sql;
			select distinct(panel_level) into: distinct_level separated by '$' from contribution_final1
				where panel_name = "%scan(&distinct_name.,&l.,'$')";
		quit;

		%put &distinct_level.;

		%do n=1 %to %sysfunc(countw(&distinct_level.,'$'));

			data subset&l.&n.;
				set contribution_final1;
				where panel_level = "%scan(&distinct_level.,&n.,'$')" and panel_name = "%scan(&distinct_name.,&l.,'$')";
			run;

			/*Sorting it with date variable	*/
			proc sort data=subset&l.&n. out=subset&l.&n.;
				by &model_date_var.;
			run;

			/*Making the macro variable for rearranging*/
			data _null_;
				call symput("varss",tranwrd("&vars.",",","||"));
			run;

			/*Grouping by date variable to find the unique date value column*/
			proc sql;
				create table subsett&l.&n. as select distinct(&model_date_var.),panel_name,panel_level,

					%if "&intercept_estimate."^="" %then
						%do;
							sum(intercept) as intercept,
						%end;

					%do m=1 %to %sysfunc(countw(&varss.,'||'));
						sum(%scan(&varss.,&m.,'||')) as %scan(&varss.,&m.,'||') ,
					%end;

				sum(pred_dep) as pred_dep,sum(actual_dep) as actual_dep,sum(pred_antilog_var) as pred_antilog_var from subset&l.&n. group by &model_date_var.;
			quit;

			/*Appending the combination var datasets*/
			%if &n. = 1 %then
				%do;

					data contri&l.;
						set subsett&l.&n.;
					run;

				%end;
			%else
				%do;

					proc append base=contri&l. data=subsett&l.&n. force;
					run;

				%end;
		%end;

		%if &l. = 1 %then
			%do;

				data contri_final;
					set contri&l.;
				run;

			%end;
		%else
			%do;

				proc append base=contri_final data=contri&l. force;
				run;

			%end;
	%end;
%mend;

%subset;

%macro rename;
	/*Renaming the intercept column to unattributed*/
	%if "&intercept_estimate."^="" %then
		%do;

			data contri_final (rename = intercept = unattributed);
				set contri_final;
			run;

		%end;
	%else
		%do;

			data contri_final;
				set contri_final;
				unattributed = 0;
			run;

		%end;

	/*Manipulating the independent variable parameter*/
	%let independentVariable=;

	%do a=1 %to %sysfunc(countw(&independentVariables.,"||"));
		%let independent_var=%scan(&independentVariables.,&a.,"||");
		%let independent_trans=%scan(&independentTransformation.,&a.,"||");

		%if "&independent_trans."="none" %then
			%do;
				%let independentVariable = &independentVariable. &independent_var.;
			%end;
		%else
			%do;
				%let independentVariable = &independentVariable. log_&independent_var.;
			%end;
	%end;

	%put &independentVariable.;
	%let independentVariables = &independentVariable.;
	%put &independentVariables.;

	data _null_;
		call symput("independentVariables",tranwrd("&independentVariables."," ",","));
	run;

	%put &independentVariables.;

	/*Rearranging the columns*/
	proc sql;
		create table contri_final2 as
			select panel_name,panel_level,&model_date_var.,

			%if "&intercept_estimate."^="" %then
				%do;
					unattributed,
				%end;

			&independentVariables.,pred_dep,actual_dep,pred_antilog_var
			from contri_final;
	quit;

	data _null_;
		call symput("independentVariables",tranwrd("&independentVariables.",","," "));
	run;

	%put &independentVariables.;

	/*Renaming the columns*/
	%do i=1 %to %sysfunc(countw(&independentVariables.," "));

		data contri_final2 (rename=  %scan(&independentVariables.,&i.," ")=%scan(&fixedContribVariables.,&i.,"||"));
			set contri_final2;
		run;

				%end;

			
/*multiplying response values to the contribution values*/
%if "&panel_name." ne "" %then %do;
	%do z=1 %to %sysfunc(countw("&panel_level_name.","||"));
	%let cur_pan_name=%scan("&panel_level_name.",&z.,"||");
	%let cur_resp=%scan("&response.",&z.,"||");
	data contri_final2;
		set contri_final2;
		if panel_level="&cur_pan_name." then do;
			%do k=1 %to %sysfunc(countw("&independentVariables."," "));
			%scan("&independentVariables.",&k.," ")=&cur_resp*%scan("&independentVariables.",&k.," ");
			%end;
			unattributed=&cur_resp*unattributed;
		end;
		run;
	%end;
%end;
%else %do;
	data contri_final2;
		set contri_final2;
			%do k=1 %to %sysfunc(countw("&independentVariables."," "));
			%scan("&independentVariables.",&k.," ")=&response.*%scan("&independentVariables.",&k.," ");
			%end;
			unattributed=&response.*unattributed;
		run;
%end;


		data contri_final2;
			set contri_final2;
			%do cd=1 %to %sysfunc(countw("&keep_panel."," "));
			if panel_name = "%scan("&keep_panel.",&cd.," ")" then panel_name = "%scan("&old_name.",&cd.," ")";
			%end;
			panel_name=tranwrd(panel_name,"#"," "); 
			panel_level=tranwrd(panel_level,"@"," "); 
			run;
		

			data out.contribution;
				set contri_final2;
			run;
/*manipulation ends here*/

			/*Exporting the contribution csv*/
			proc export data = contri_final2
				outfile = "&output_path/contribution.csv"
				dbms = CSV replace;
			run;

			/*Exporting the bygroupdata csv to be used in optimization */
			proc export data = group.bygroupdata
				outfile = "&group_path/bygroupdata.csv"
				dbms = CSV replace;
			run;

%mend rename;

%rename;

/*---------------------------------------------------------------------------------------------------------------------*/
/*1) It gives the model equation for optimization i.e. splitting is done on the basis of class variables*/
/*2) It gives the model equation for response curve (no splitting is done)*/
/*3) It gives the parameter.csv for optimization which consists of the variables and their beta values*/
/*4) It gives the no_of_records for optimization which consists of the no of rows corresponding to the distinct class levels*/
%macro equation;
	/*Part-1: Creating the model equation for optimization (splitting done on the basis of the class variable)*/
	/*-------------------------------------------------------------------------------------------------------------*/
	data estimate_int;
		length original_variable $100.;
		format original_variable $100.;
		set estimate;

		if variable = 'Intercept';
	run;

	data estimate_withoutint;
		length original_variable $100.;
		format original_variable $100.;
		set estimate;

		if variable = 'Intercept' then
			delete;

		/* formula = original_variable;*/
	run;

	/*Sorting it with original variablke column*/
	proc sort data=estimate_withoutint out=estimate_withoutint;
		by original_variable;
	run;

	data formulas;
		length formula $100.;
		length ind $100.;
		%do f = 1 %to %sysfunc(countw(&fixedContribVariables.,'||'));
			formula = strip("%scan(&fixedContribVariables.,&f.,'||')");
/*			ind = strip("%scan(&independentVariables.,&f.,'||')");*/
			output;
		%end;		
	run;

/*	proc sort data=formulas out=formulas;*/
/*	by ind;*/
/*	quit;*/

	data estimate_withoutint;
		merge estimate_withoutint formulas;
	run;

	data estimate_withoutint(drop=original_variable rename=formula = original_Variable);
		set estimate_withoutint;
	run;

	proc append base=estimate_int data=estimate_withoutint FORCE;
	quit;

	data estimate_opt;
		format Dependent $100.;
		format original_variable $100.;
		set estimate_int;

		if Iteration_transformation="log" then
			Original_Variable = cats("log","(","1+",original_variable,"_&aliasmodelname.");
		else Original_Variable = cats(original_variable,"_&aliasmodelname.");
		brackets = repeat(")",countc(original_variable,"(")-1);

		if index(original_variable,")") ^=0 then
			original_variable = tranwrd(original_variable,")","");
		original_variable = compress(original_variable);

		if index(original_variable,"(") ^=0 then
			original_variable = cats(original_variable,brackets);

		if Original_Estimate>0 then
			paramestimat = cats(Original_Estimate,"*",Original_Variable);
		else paramestimat = cats("(",Original_Estimate,")","*",Original_Variable);
	run;

	%if "&intercept_estimate."^="" %then
		%do;

			proc sql;
				select paramestimat into:rhs2 separated by ' + ' from estimate_opt where Original_Variable = "Intercept_&aliasmodelname.";
			quit;

			%put &rhs2.;
			%let rhs3 = %sysfunc(tranwrd(&rhs2.,*Intercept_&aliasmodelname.,));
		%end;

	proc sql;
		select paramestimat into:rhs separated by ' + ' from estimate_opt where Original_Variable^= "Intercept_&aliasmodelname.";
	quit;

	%put &rhs.;

	%if "&intercept_estimate."^="" %then
		%do;
			%let final=&rhs3. + &rhs.;
			%put &final.;
		%end;
	%else
		%do;
			%let final=&rhs.;
			%put &final.;
		%end;

	data estimate;
		set estimate;
		Dependent = compress(Dependent);
	run;

	proc sql;
		select Dependent into:dep from estimate;
	quit;

	%put &dep.;

	data _null_;
		call symput("depen",tranwrd("&dep.","log_",""));
	run;

	%if "&dependentTransformation." = "log" %then
		%do;
			%let eqn=&depen. = {exp(&final.)-1};
		%end;
	%else
		%do;
			%let eqn=&depen. = {&final.};
		%end;

	%put &eqn;
	%let eqnn = %sysfunc(tranwrd(&eqn.,maof_,));
	%put &eqnn.;
	%let eqnnn = %sysfunc(tranwrd(&eqnn.,leadof_,));
	%let eqnnnn = %sysfunc(tranwrd(&eqnnn.,lagof_,));
	%let eqnnnnn = %sysfunc(tranwrd(&eqnnnn.,adsof_,));
	%let eqnnnnnn = %sysfunc(tranwrd(&eqnnnnn.,normalizeof_,));
	%put &eqnnnnnn.;

	data _NULL_;
		v1= "&eqnnnnnn.";
		file "&output_path./MODEL_EQUATION.txt";
		PUT v1;
	run;

	/*----------------------------------------------------------------------------------------------------------*/
	/*Part-2: Creating Model equation for response curve*/
	data estimate_response;
		set estimate_int;

		if Iteration_transformation="log" then
			Original_Variable = cats("log","(",original_variable);
		brackets = repeat(")",countc(original_variable,"(")-1);

		if index(original_variable,")") ^=0 then
			original_variable = tranwrd(original_variable,")","");
		original_variable = compress(original_variable);

		if index(original_variable,"(") ^=0 then
			original_variable = cats(original_variable,brackets);

		if Original_Estimate>0 then
			paramestimat = cats(Original_Estimate,"*",Original_Variable);
		else paramestimat = cats("(",Original_Estimate,")","*",Original_Variable);
	run;

	%if "&intercept_estimate."^="" %then
		%do;

			proc sql;
				select paramestimat into:rhs2_int_res separated by ' + ' from estimate_response where Original_Variable = "Intercept";
			quit;

			%put &rhs2_int_res.;
			%let rhs3 = %sysfunc(tranwrd(&rhs2_int_res.,*Intercept,));
		%end;

	proc sql;
		select paramestimat into:rhs_res separated by ' + ' from estimate_response where Original_Variable^= "Intercept";
	quit;

	%put &rhs_res.;

	%if "&intercept_estimate."^="" %then
		%do;
			%let final_res=&rhs3. + &rhs_res.;
			%put &final_res.;
		%end;
	%else
		%do;
			%let final_res=&rhs_res.;
			%put &final_res.;
		%end;

	%if "&dependentTransformation." = "log" %then
		%do;
			%let eqn_res=&depen. = {exp(&final_res.)-1};
		%end;
	%else
		%do;
			%let eqn_res=&depen. = {&final_res.};
		%end;

	%put &eqn_res;

	/*Replacing ads,lag,lead,ma,normalize*/
	%let eqnn_r = %sysfunc(tranwrd(&eqn_res.,maof_,));
	%put &eqnn_r.;
	%let eqnnn_r = %sysfunc(tranwrd(&eqnn_r.,leadof_,));
	%let eqnnnn_r = %sysfunc(tranwrd(&eqnnn_r.,lagof_,));
	%let eqnnnnn_r = %sysfunc(tranwrd(&eqnnnn_r.,adsof_,));
	%let eqnnnnnn_r = %sysfunc(tranwrd(&eqnnnnn_r.,normalizeof_,));
	%put &eqnnnnnn_r.;

	data _NULL_;
		v1= "&eqnnnnnn_r.";
		file "&output_path./RESPONSE_MODEL_EQUATION.txt";
		PUT v1;
	run;

	/*-----------------------------------------------------------------------------------------------------------*/
	/*Part-4: Creating beta estimates csv to be given to optimization*/
	data estimate_opt( rename= (original_variable = variable original_estimate= Estimate));
		set estimate_opt;
	run;

	proc export data = estimate_opt
		outfile = "&output_path/parameter.csv"
		dbms = CSV replace;
	run;

	/*-----------------------------------------------------------------------------------------------------------*/
	/*Part-5: creting the no_of_records.csv having the no of rows corresponding to the distinct levels*/
	%let dsid=%sysfunc(open(group.bygroupdata));
	%let num=%sysfunc(attrn(&dsid,nlobs));
	%let rc=%sysfunc(close(&dsid));

	data a;
		nobs = &num.;
		level = "   ";
	run;

	proc export data =a
		outfile = "&output_path./no_of_records.csv"
		dbms = CSV replace;
	run;

	/*-----------------------------------------------------------------------------------------------------------*/
%mend equation;

%equation;

proc export data = group.bygroupdata
		outfile = "&output_path/bygroupdata.csv"
		dbms = CSV replace;
	run;

%mend contribution;

%contribution;

/*Completed txt generated*/
data _NULL_;
	v1= "MUMIX-CONTRIBUTION_COMPLETED";
	file "&output_path./CONTRIBUTION_COMPLETED.txt";
	PUT v1;
run;