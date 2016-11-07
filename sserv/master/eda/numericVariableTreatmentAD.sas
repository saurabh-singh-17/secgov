/***************************************** SAMPLE PARAMETERS ****************************************************/
/*%let codePath=/product-development/murx///SasCodes//8.7.1;*/
/*%let input_path=/product-development/nida.arif;*/
/*%let output_path=/product-development/nida.arif/Output;*/

/************************** Common across missing treatment and outlier treatment *******************************/
/*%let var_list=miss_acv sales;*/
/*%let missing_replacement_var=;*/
/*%let create_ind_flag=true;*/
/*%let treatment_newVar=replace;*/
/*%let treatment_prefix=ab;*/
/*%let treatment=missing;*/
/*%let treatment_option=custom_type;*/
/*%let custom_treat_val=1234;*/

/****************************************** If missing treatment ************************************************/
/*%let missing_spl=1;*/

/****************************************** If outlier treatment ************************************************/
/*%let outlier_type_side=;*/
/*%let iqr_value =;*/
/*%let perc_lower=;*/
/*%let perc_upper=;*/

/******************************* Differentiate between across grp by and across dataset *************************/
/*%let grp_vars=;*/

/********************************************** Per group by ****************************************************/
/*%let n_grp=2;*/
/*%let grp_flag=5_2_1;*/

/********************************************* CODE BEGINS ************************************************/
%let completedTXTPath =  &output_path/completed.txt;
options mprint mlogic symbolgen mfile;


proc printto log="&output_path/MissingTreatment_Log.log";
run;

quit;
/*proc printto;*/
/*run;*/
/**/
/*quit;*/

dm log 'clear';
libname in "&input_path.";
libname out "&output_path.";

proc datasets lib=work kill;
run;

quit;

%macro variable_treatment;
	%let c_var_key = primary_key_1644;
	%let dataset_use = in.dataworking;

	%if "&n_grp." ^= "0" %then
		%do;

			data fin_dataset;
				set &dataset_use.;
				where compress(grp&n_grp._flag) = "&grp_flag";
			run;

			%let dataset_use =fin_dataset;
		%end;

	%let dsid = %sysfunc(open(&dataset_use.));
	%let nobs =%sysfunc(attrn(&dsid,NOBS));
	%let rc=%sysfunc(close(&dsid));
	%put &nobs;
	%let lower =;
	%let upper =;

	%if &treatment. = outlier %then
		%do;
			/* get the upper and lower values */
			%if &outlier_type_side. = perc %then
				%do;
					%let upper = %sysevalf(&perc_upper.);
					%let lower =%sysevalf(&perc_lower.);
				%end;
			%else %if &outlier_type_side. = one %then
				%do;
					%let upper = %sysevalf(75);
				%end;
			%else %if &outlier_type_side. = two %then
				%do;
					%let upper = %sysevalf(75);
					%let lower = %sysevalf(25);
				%end;
		%end;

	%do i=1 %to %sysfunc(countw(&var_list.));
		%let vars = %scan(&var_list,&i);

		/*PRE TREATMENT UNIVARIATE VALUES*/
		proc univariate data = &dataset_use.(keep=&vars.) noprint;
			var &vars.;
			output out = pre_univ&i.
			mean = pre_mean
			median = pre_median
			mode = pre_mode
			%if &treatment. = missing %then

				%do;
					nmiss=nmiss
				%end;

			%if &treatment. = outlier %then
				%do;
					qrange = iqr
				%end;

			%if &treatment. = outlier OR &treatment_option. = trimmedmean %then
				%do;
					pctlpre = p_
						pctlpts =

					%if &treatment. = outlier %then
						%do;
							&upper.

							%if "&lower." ^= "" %then
								%do;
									&lower.
								%end;
						%end;

					%if &treatment_option. = trimmedmean %then
						%do;
							5 95
						%end;
				%end;
			;
		run;

		/* calculate outlier cut-offs outlier_lb and outlier_ub */
		/* count number of outliers*/
		%if &treatment. = outlier %then
			%do;

				data _null_;
					set pre_univ&i.;

					%if &outlier_type_side. = one %then
						%do;
							call symputx("outlier_ub", compress(p_75 + (&iqr_value. * iqr)));
						%end;
					%else %if &outlier_type_side. = two %then
						%do;
							call symputx("outlier_ub", compress(p_75 + (&iqr_value. * iqr)));
							call symputx("outlier_lb", compress(p_25 - (&iqr_value. * iqr)));
						%end;
					%else %if &outlier_type_side. = perc %then
						%do;
							call symputx("outlier_lb", %sysfunc(compress(p_%sysfunc(tranwrd(&lower.,.,_)))));
							call symputx("outlier_ub", %sysfunc(compress(p_%sysfunc(tranwrd(&upper.,.,_)))));
						%end;
				run;

				%put outlier_lb: &outlier_lb.;
				%put outlier_ub: &outlier_ub.;

				proc sql noprint;
					%if &outlier_type_side.=one %then
						%do;
							select count(&vars.) into :num_outlier from &dataset_use. where &vars. > %sysevalf(&outlier_ub.);
						%end;

					%if &outlier_type_side.=two or &outlier_type_side. = perc %then
						%do;
							select count(&vars.) into :num_outlier from &dataset_use. where &vars. > %sysevalf(&outlier_ub.) or &vars. < %sysevalf(&outlier_lb.);
						%end;
				run;

				%put ................ &num_outlier;
			%end;

		/*count missing special characters*/
		%if "&missing_spl." ^= "" %then
			%do;

				proc sql noprint;
					select count(&vars.) into:mis
						from &dataset_use. 
							where &vars. in (&missing_spl.);
				quit;

			%end;

		/*Get the value to treat the missing values or outliers*/
		%let treat_val=NA;

		%if &treatment_option. = mean or &treatment_option. = trimmedmean or &treatment_option. = median or &treatment_option. = mode
			or &treatment_option. = capping %then
			%do;

				data _null_;
					set pre_univ&i.;

					%if &treatment_option. = mean %then
						%do;
							call symput ("treat_val", pre_mean);
						%end;
					%else %if &treatment_option. = median %then
						%do;
							call symput ("treat_val", pre_median);
						%end;
					%else %if &treatment_option. = mode %then
						%do;
							call symput ("treat_val", pre_mode);
						%end;
					%else %if &treatment_option. = capping %then
						%do;
							call symput ("treat_val", %sysfunc(tranwrd(&custom_treat_val.,.,_)));
						%end;
					%else %if &treatment_option. = trimmedmean %then
						%do;
							call symput ("trimmed_lb", p_5);
							call symput ("trimmed_ub", p_95);

				proc sql noprint;
					select avg(&vars.) into:treat_val from &dataset_use.
						where (&trimmed_lb. < &vars. < &trimmed_ub.);
				quit;

						%end;
					run;

			%end;
		%else %if &treatment_option. = custom_type %then
			%do;
				%let treat_val = %sysevalf(&custom_treat_val.);
			%end;
		%else %if &treatment_option. = delete  %then
			%do;
				%let treat_val =NA;
			%end;

		/*update the dataset with outlier values and missing/outlier percentage and count of missing values/count
		of outlier values*/
		data pre_univ&i.;
			length variable $32.;
			length treat_value $20.;
			set pre_univ&i.;
			variable = "&vars.";
			attrib _all_ label=' ';

				/*missing count including special characters*/
				%if &treatment. = missing %then
					%do;
						%if "&missing_spl." ^= "" %then
							%do;
								nmiss=nmiss+&mis;
							%end;

						format missing_percentage PERCENT8.2;
						missing_percentage=nmiss/&nobs.;
					%end;

				/*outlier upper bound and lower bounds*/
				%if &treatment. = outlier %then
					%do;
						num_outlier=&num_outlier.;
						format percentage_outlier PERCENT8.2;
						percentage_outlier=&num_outlier./&nobs.;
						drop p_%sysfunc(tranwrd(&upper.,.,_));

						%if "&lower." ^= "" %then
							%do;
								drop p_%sysfunc(tranwrd(&lower.,.,_));
								outlier_lb = %sysevalf(&outlier_lb.);
							%end;

						outlier_ub = %sysevalf(&outlier_ub.);
						;
					%end;

				%if &treatment_option. = trimmedmean %then
					%do;
						drop p_95 p_5;
					%end;

				treat_value="&treat_val.";
		run;

		/*VARIABLE TREATMENT FOR OUTLIERS AND MISSING VALUES BEGINS HERE*/
		/* OUTLIER TREATMENT */
		%let dataset_final=temp;

		data temp;
			set

				%if &i. = 1 %then
					%do;
						&dataset_use.
					%end;
				%else
					%do;
						temp
					%end;
				;
				/*If new variable is to be created*/
				%if &treatment_newVar. = new %then
					%do;
						&treatment_prefix._%substr(&vars.,1,27) =&vars.;
					%end;

				/*If indicator flag needs to be created for missing values*/
				%if &Create_ind_flag.= true %then
					%do;
						if missing(&vars.)=1 
						%if "&missing_spl." ^= "" %then
							%do;
								or &vars. in (&missing_spl.)
							%end;

						then 
							&treatment_prefix._MI_%substr(&vars.,1,15)=1;
						else &treatment_prefix._MI_%substr(&vars.,1,15)=0;
					%end;

				/*conditions for outlier treatment*/
				%if &treatment. = outlier %then
					%do;
						%if "&lower." ^= "" AND &treatment_option. ^= capping %then
							%do;
								if missing(&vars.) = 0 and (&vars. > %sysevalf(&outlier_ub.) or &vars. < %sysevalf(&outlier_lb.)) then
									do;
							%end;

						%if "&lower." = "" AND &treatment_option. ^= capping %then
							%do;
								if missing(&vars.)=0 and &vars. > %sysevalf(&outlier_ub.) then
									do;
							%end;
					%end;

				/*conditions for missing value treatment*/
				%if &treatment. = missing %then
					%do;
						if missing(&vars.)=1
						%if "&missing_spl." ^= "" %then
							%do;
								or &vars. in (&missing_spl.)
							%end;

						then

							do;
					%end;

				/*operation to be performmed*/
				%if &treatment_option. = delete %then
					%do;
						delete;
					%end;
				%else %if &treatment_option. = capping AND &treatment. = outlier %then
					%do;
						%if &treatment_newVar. = new %then
							%do;
								%if "&lower." ^= "" %then
									%do;
										if missing(&vars.) = 0 and (&vars. < %sysevalf(&outlier_lb.)) then
											do;
												&treatment_prefix._%substr(&vars.,1,27) = %sysevalf(&outlier_lb.);
											end;
									%end;

								if missing(&vars.)=0 and &vars. > %sysevalf(&outlier_ub.) then
									do;
										&treatment_prefix._%substr(&vars.,1,27) = %sysevalf(&outlier_ub.);
							%end;
						%else %if &treatment_newVar. = replace or &treatment_newVar. = rename %then
							%do;
								%if "&lower." ^= "" %then
									%do;
										if missing(&vars.) = 0 and (&vars. < %sysevalf(&outlier_lb.)) then
											do;
												&vars. = %sysevalf(&outlier_lb.);
											end;
									%end;

								if missing(&vars.)=0 and &vars. > %sysevalf(&outlier_ub.) then
									do;
										&vars. = %sysevalf(&outlier_ub.);
							%end;
					%end;
				%else %if &treatment_option. = replace_with_existing AND &treatment. = missing %then
					%do;
						%let misReplaceVar= %scan(&missing_replacement_var., &i.);

						%if &treatment_newVar. = replace or &treatment_newVar. = rename %then
							%do;
								if missing(&vars.)=1 
								%if "&missing_spl." ^= "" %then
									%do;
										or &vars. in (&missing_spl.)
									%end;

								then

									do;
										&vars.=&misReplaceVar.;
									end;
							%end;
						%else %if "&treatment_newVar." = "new" %then
							%do;
								if missing(&vars.)= 1  
								%if "&missing_spl." ^= "" %then
									%do;
										or &vars. in (&missing_spl.)
									%end;

								then  &treatment_prefix._%substr(&vars.,1,25)= &misReplaceVar.;
								else &treatment_prefix._%substr(&vars.,1,25)=&vars.;
							%end;
					%end;
				%else
					%do;
						%if &treatment_newVar. = new %then
							%do;
								&treatment_prefix._%substr(&vars.,1,27) =%sysevalf(&treat_val.);
							%end;
						%else %if &treatment_newVar. = replace OR &treatment_newVar. = rename %then
							%do;
								&vars. = %sysevalf(&treat_val.);
							%end;
					%end;
									end;
		run;

		/*calculate number of observations*/
		%let dataset_use_post = temp;

		%if &treatment. = delete %then
			%do;
				%let dsid=%sysfunc(open(&dataset_use_post.));
				%let post_nobs=%sysfunc(attrn(&dsid.,nobs));
				%let rc=%sysfunc(close(&dsid.));
				%put &post_nobs.;

				data _null_;
					v1= &nobs.;
					file "&output_path./noobs_refresh.txt";
					put v1;
				run;

			%end;

		/*POST TREATMENT UNIVARIATE VALUES*/
		proc univariate data = &dataset_use_post. noprint;
			%if &treatment_newVar. = replace or &treatment_newVar. = rename %then
				%do;
					var &vars.;
				%end;
			%else %if &treatment_newVar. = new %then
				%do;
					var &treatment_prefix._%substr(&vars.,1,25);
				%end;

			output out = post_univ&i.
				mean = post_mean
				median = post_median
				mode = post_mode
				pctlpts = 0 to 0.8 by 0.2 1 to 5 by 1 25 75 95 to 98 by 1 99 to 100 by 0.1 
				pctlpre = p_;
		run;

		data post_univ&i.;
			set post_univ&i.;
			length variable $32.;
			variable="&vars.";
		run;

		data pre_univ&i.;
			merge pre_univ&i. post_univ&i.;
			by variable;
		run;

		proc append base = missing_treatment data = pre_univ&i. force;
		run;

		proc datasets lib = work;
			delete pre_univ&i. post_univ&i.;
		run;

		%if "&n_grp." ^= "0" %then
			%do;
				%if &treatment_option. ^= delete %then
					%do;
						proc sort data=in.dataworking;
							by grp&n_grp._flag;
						run;

						proc sort data=temp;
							by grp&n_grp._flag;
						run;

						data t&i.;
							merge in.dataworking(in=b keep=grp&n_grp._flag &vars.)
							temp(in=a keep=grp&n_grp._flag &vars. 
							%if &treatment_newVar. = new %then

								%do;
									&treatment_prefix._&vars.
								%end;

							%if &Create_ind_flag. = true %then
								%do;
									&treatment_prefix._MI_%substr(&vars.,1,15)
								%end;
							);
							if a or b;
							by grp&n_grp._flag;
						run;

						%if &treatment_newVar. = new %then
							%do;

								data t&i.;
									set t&i.;

									if grp&n_grp._flag ^= "&grp_flag." then
										&treatment_prefix._&vars. = &vars.;
									keep &treatment_prefix._&vars. grp&n_grp._flag 
										%if &Create_ind_flag. = true %then
											%do;
									&treatment_prefix._MI_%substr(&vars.,1,15)
							%end;
						;
								run;

					%end;

				%if &i. = 1 %then
					%do;
						data final;
							merge in.dataworking t&i.;
							by grp&n_grp._flag;
						run;

					%end;
				%else
					%do;
						data final;
							merge final t&i.;
							by grp&n_grp._flag;
						run;

					%end;

				/*				proc datasets lib = work;*/
				/*					delete t&i.;*/
				/*				run;*/
				%let dataset_final=final;
			%end;
		%else
			%do;

				data final;
					set in.dataworking;
					where grp&n_grp._flag ^= "&grp_flag.";
				run;

				proc append base=final data=temp force;
				run;

				%let dataset_final=final;
			%end;
	%end;
%end;

	data missing_treatment;
		retain variable 
			%if &treatment. = missing %then
				%do;
		spl_chars
		%end;
%else
	%do;
		perc_iqr
	%end;

	treatment treat_value replace_type pre_mean pre_median pre_mode post_mean post_median;
	set missing_treatment;
	treatment = "&treatment_option.";

	%if "&missing_spl." ^= "" %then
		%do;
			spl_chars = "&missing_spl.";
		%end;
	%else %if "&missing_spl." = "" & "&treatment." = "missing" %then
		%do;
			spl_chars = "N.A.";
		%end;

	%if &treatment. = outlier and "&iqr_value." ^= "" %then
		%do;
			perc_iqr = "&iqr_value.";
		%end;

	%if &treatment. = outlier and "&iqr_value." = "" %then
		%do;
			perc_iqr = 0;
		%end;

	replace_type = "&treatment_newVar.";
	run;

	/*************************************VARIABLE TREATMENT ENDS HERE***********************/
	/*CREATING THE OUTPUT DATA SET*/
	proc sort data=&dataset_final.;
		by &c_var_key.;
	run;

	data in.dataworking;
		set &dataset_final.;

		%if &treatment_option. = delete %then
			%do;
				&c_var_key. = _n_;
			%end;
	run;

	proc export data = missing_treatment
		%if &treatment. = missing %then
			%do;
				outfile = "&output_path./missing_treatment.csv"
			%end;
		%else %if &treatment. = outlier %then
			%do;
				outfile = "&output_path./outlier_treatment.csv"
			%end;

		dbms = csv replace;
	run;

	/* flex uses this file to test if the code has finished running */
	data _null_;
		v1= "EDA - MISSING_TREATMENT_COMPLETED";
		file "&output_path/completed.txt";
		put v1;
	run;

%mend;
;
%variable_treatment;