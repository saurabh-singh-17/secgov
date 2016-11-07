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
/*%let outlier_type_side=perc;*/
/*%let iqr_value =;*/
/*%let perc_lower=10;*/
/*%let perc_upper=90;*/

/******************************* Differentiate between across grp by and across dataset**************************/
/*%let grp_vars=geography;*/

/********************************************** Per group by ****************************************************/
/*%let n_grp=0;*/
/*%let grp_flag=1_1_1;*/

/********************************************* CODE BEGINS ************************************************/
%let completedTXTPath =  &output_path/completed.txt;
options mprint mlogic symbolgen mfile;

/**/
/*proc printto log="&output_path/MissingTreatment_Log.log";*/
/*run;*/
/**/
/*quit;*/
proc printto;
run;

quit;

dm log 'clear';
libname in "&input_path.";
libname out "&output_path.";

proc datasets lib=work kill;
run;

quit;

%macro indicator_missing;
	%do p=1 %to %sysfunc(countw("&var_list."," "));
		%let this_var=%scan("&var_list.",&p.," ");

		data &dataset_use.;
			set &dataset_use.;

			%if "&treatment_newVar." = "new" %then
				%do;
					%if "&missing_spl." ^= "" %then
						%do;
							&treatment_prefix._MI_%substr(&this_var.,1,15)=0;

							%do i=1 %to %sysfunc(countw("&missing_spl."," "));
								if &this_var.=%eval(%scan(&missing_spl.,&i.," ")) then
									&treatment_prefix._MI_%substr(&this_var.,1,15) = 1;
							%end;

							if &this_var.= . then
								&treatment_prefix._MI_%substr(&this_var.,1,15) = 1;
						%end;
					%else
						%do;
							if &this_var.='.' then
								&treatment_prefix._MI_%substr(&this_var.,1,15) =1;
							else &treatment_prefix._MI_%substr(&this_var.,1,15)=0;
						%end;
				%end;
			%else %if "&treatment_newVar." = "replace" %then
				%do;
					%if "&missing_spl." ^= "" %then
						%do;
							&treatment_prefix._MI_%substr(&this_var.,1,15)=0;

							%do i=1 %to %sysfunc(countw("&missing_spl."," "));
								if &this_var.=%eval(%scan(&missing_spl.,&i.," ")) then
									&treatment_prefix._MI_%substr(&this_var.,1,15) =1;
							%end;

							if &this_var.='.' then
								&treatment_prefix._MI_%substr(&this_var.,1,15) =1;
						%end;
					%else
						%do;
							if &this_var.='.' then
								&treatment_prefix._MI_%substr(&this_var.,1,15) =1;
							else &treatment_prefix._MI_%substr(&this_var.,1,15)=0;
						%end;
				%end;
		run;

	%end;
%mend;

%macro ind;
	%if "&Create_ind_flag."^="false" %then
		%do;
			%indicator_missing;
		%end;
%mend;

%macro variable_treatment_acrossGrpby;
	%let c_var_key = primary_key_1644;
	%let dataset_use = in.dataworking;
	%let dataset_final=temp;

	%ind;

	/*Subset the Dataset for Per Group By*/
	%let dsid = %sysfunc(open(&dataset_use.));
	%let nobs =%sysfunc(attrn(&dsid,NOBS));
	%let rc=%sysfunc(close(&dsid));
	%put &nobs;

	data _null_;
		call symput("grp", tranwrd("&grp_vars."," ",",'_',"));
	run;

	%put &grp;

	data temp;
		set &dataset_use. nobs=n;
		format grp_var $32.;
		call symput('frequency',n);
		grp_var=cat(&grp.);
		grp_var = compress(grp_var);
		primary_key_1644=_n_;
	run;

	data temp1(keep=&var_list.);
		set &dataset_use.;
	run;

	data temp;
		merge temp1 temp;
	run;

	%put &frequency.;

	proc sort data = temp;
		by grp_var;
	run;

	%let upper =;
	%let lower =;

	/*Get lower and upper percentiles for outliers*/
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

	%put &lower.;
	%put &upper.;

	%do i=1 %to %sysfunc(countw(&var_list.));
		%let vars = %scan(&var_list,&i);

		proc univariate data=temp noprint;
			var &vars.;
			by grp_var;
			output out=pre_univ&i
			mean=pre_mean
			median=pre_median
			mode=pre_mode
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

		/*calculate trimmed mean*/
		%if &treatment_option. = trimmedmean %then
			%do;

				data means;
					merge temp(in=a keep=&vars. grp_var) pre_univ&i.(in=b keep=grp_var p_5 p_95);
					by grp_var;

					if a or b;
				run;

				proc sql;
					create table trimmedmean as
						select grp_var, avg(&vars.) as trimmedmean from means
							where p_5 < &vars. < p_95
								group by grp_var;
				quit;

				data pre_univ&i.;
					merge pre_univ&i.(in=a) trimmedmean(in=b);
					by grp_var;

					if a or b;
				run;

			%end;

		%if %length(&missing_spl.)^=0 %then
			%do;

				proc sql noprint;
					create table a as
						select count(%scan(&var_list,&i)) as mis,grp_var
							from temp 
								where %scan(&var_list,&i) in (&missing_spl.)
									group by grp_var;
				quit;

				proc sql;
					create table b as 
						select distinct grp_var
							from temp;
				quit;

				data a;
					merge b(in=b) a(in=a);
					by grp_var;

					if b;
				run;

				data a;
					set a;

					if mis=. then
						mis=0;
				run;

				%put missing &mis.;

				proc sql noprint;
					select mis into: mis separated by " "
						from a;
				quit;

				proc sql noprint;
					select  grp_var into:grp_var separated by "!!"
						from a;
				quit;

				%do j=1 %to %sysfunc(countw(&mis.));

					data n&j.;
						set pre_univ&i.(keep=grp_var nmiss);
						nmiss=nmiss+%scan(&mis.,&j.," ");

						if grp_var="%scan(&grp_var.,&j.,'!!')";
					run;

					data pre_univ&i.;
						merge pre_univ&i. n&j.;
						by grp_var;
					run;

					proc datasets lib = work;
						delete n&j.;
					run;

				%end;
			%end;

		%if &treatment. = outlier %then
			%do;

				data pre_univ&i;
					set pre_univ&i;

					%if &outlier_type_side. = one %then
						%do;
							call symput("iqr",iqr);
							upper_bound=p_75 + (&iqr_value. * iqr);
						%end;
					%else %if &outlier_type_side. = two %then
						%do;
							call symput("iqr",iqr);
							upper_bound=p_75 + (&iqr_value. * iqr);
							lower_bound=p_25 - (&iqr_value. * iqr);
						%end;
					%else %if &outlier_type_side. = perc %then
						%do;
							lower_bound=p_%sysfunc(tranwrd(&perc_lower.,.,_));
							upper_bound=p_%sysfunc(tranwrd(&perc_upper.,.,_));
						%end;
				run;

				data temp;
					merge temp (in=a) pre_univ&i.(keep=grp_var upper_bound %if (&outlier_type_side.=perc or &outlier_type_side. = two) %then lower_bound;);
					by grp_var;

					if a;
				run;

				proc sql;
					create table b as select distinct grp_var from temp;
				quit;

				%if &outlier_type_side. = two %then
					%do;

						proc sql;
							create table a as
								select count(&vars.) as cnt,grp_var
									from temp
										where (&vars. lt lower_bound) or (&vars. gt upper_bound)
											group by grp_var;
						quit;

					%end;
				%else %if &outlier_type_side. = one %then
					%do;

						proc sql;
							create table a as
								select count(&vars.) as cnt,grp_var
									from temp
										where &vars. gt upper_bound
											group by grp_var;
						quit;

					%end;
				%else %if &outlier_type_side. = perc %then
					%do;

						proc sql;
							create table a as
								select count(&vars.) as cnt,grp_var
									from temp
										where (&vars. lt lower_bound) or (&vars. gt upper_bound)
											group by grp_var;
						quit;

					%end;

				/* calculating outlier across groups*/
				data a;
					merge b(in=b) a(in=a);
					by grp_var;

					if b;
				run;

				data a;
					set a;

					if cnt=. then
						cnt=0;
				run;

				proc sql noprint;
					select cnt into: cnt separated by " "
						from a;
				quit;

				proc sql noprint;
					select  grp_var into:grp_var separated by "!!"
						from a;
				quit;

				%do j=1 %to %sysfunc(countw(&cnt.));

					data n&j.;
						set pre_univ&i.(keep=grp_var);
						num_outlier=%scan(&cnt.,&j.," ");

						if grp_var="%scan(&grp_var.,&j.,'!!')";
					run;

					data pre_univ&i.;
						merge pre_univ&i. n&j.;
						by grp_var;
					run;

					proc datasets lib = work;
						delete n&j.;
					run;

				%end;
			%end;

		%if &treatment_option. = trimmedmean %then
			%do;

				data pre_univ&i.;
					set pre_univ&i.;
					rename trimmedmean=pre_trimmedmean;
				run;

			%end;

		data pre_univ&i.;
			length variable $32.;
			length treat_val $32.;
			set pre_univ&i.;
			variable = "&vars.";
			attrib _all_ label=' ';

			/*missing count including special characters*/
			%if &treatment. = missing %then
				%do;
					%if "&missing_spl." ^= "" %then
						%do;
							nmiss=nmiss;
						%end;

					format missing_percentage PERCENT8.2;
					missing_percentage=nmiss/&nobs.;
				%end;

			/*outlier upper bound and lower bounds*/
			%if &treatment. = outlier %then
				%do;
					format percentage_outlier PERCENT8.2;
					percentage_outlier=num_outlier/&nobs.;
					drop p_%sysfunc(tranwrd(&upper.,.,_));

					%if "&lower." ^= "" %then
						%do;
							drop p_%sysfunc(tranwrd(&lower.,.,_));
						%end;
					;
				%end;

			%if &treatment_option. = trimmedmean %then
				%do;
					drop p_95 p_5;
				%end;

			%if &treatment_option. = custom_type %then
				%do;
					treat_val=&custom_treat_val.;;
				%end;
			%else %if &treatment_option. = mean or &treatment_option. = median or &treatment_option. = mode or 
				&treatment_option. = trimmedmean
				%then
				%do;
					treat_val=pre_&treatment_option.;
				%end;
			%else
				%do;
					treat_val="NA";
				%end;
		run;

		/**/
		/*VARIABLE TREATMENT*/
		data temp;
			merge temp(in=a) pre_univ&i(in=b keep=grp_var %if "&upper." ^= "" %then

				%do;
					upper_bound
				%end;

			%if "&lower." ^= "" %then
				%do;
					lower_bound
				%end;

			%if &treatment_option.=mean or &treatment_option.=mode or 
				&treatment_option.=median or &treatment_option.=trimmedmean %then
				keep=pre_&treatment_option.;
			);
			by grp_var;

			if a or b;
		run;

		%if (&treatment_option.^=capping and &treatment. = outlier) or 
			(&treatment. = missing) %then
			%do;

				data temp;
					set temp;
					by grp_var;

					%if &treatment_newVar. = new %then
						%do;
							&treatment_prefix._%substr(&vars.,1,27) =&vars.;
						%end;

					%if &treatment. = outlier %then
						%do;
							%if "&upper." ^= "" and "&lower." ^= "" %then
								%do;
									if &vars.<lower_bound or &vars.> upper_bound then
								%end;

							%if "&upper." = "" and "&lower." ^= "" %then
								%do;
									if &vars. < lower_bound then
								%end;

							%if "&upper." ^= "" and "&lower." = "" %then
								%do;
									if &vars.> upper_bound then
								%end;
						%end;
					%else %if &treatment. = missing %then
						%do;
							if &vars. = . %if "&missing_spl." ^= "" %then
								%do;
									or &vars. in (&missing_spl.)
								%end;

							then
						%end;

					%if &treatment_option.=delete %then
						%do;
							delete;
						%end;
					%else %if (&treatment_option.=mean or &treatment_option.=mode or 
						&treatment_option.=trimmedmean or &treatment_option.=median) 
						%then
						%do;
							%if &treatment_newVar.=new %then
								%do;
									&treatment_prefix._&vars.=pre_&treatment_option.;
								%end;
							%else %if &treatment_newVar.=replace %then
								%do;
									&vars.=pre_&treatment_option.;
								%end;
							%else %if &treatment_newVar.=rename %then
								%do;
									&vars.=pre_&treatment_option.;
									rename &vars.=&treatment_prefix._&vars.;
								%end;
						%end;
					%else %if &treatment_option.=custom_type %then
						%do;
							%if &treatment_newVar.=new %then
								%do;
									&treatment_prefix._&vars.=%sysevalf(&custom_treat_val.);
								%end;
							%else %if &treatment_newVar.=replace %then
								%do;
									&vars.=%sysevalf(&custom_treat_val.);
								%end;
							%else %if &treatment_newVar.=rename %then
								%do;
									&vars.=%sysevalf(&custom_treat_val.);
									rename &vars.=&treatment_prefix._&vars.;
								%end;
						%end;
					%else %if &treatment_option. = replace_with_existing and &treatment. = missing %then
						%do;
							%let misTreatVar= %scan(&var_list., &i.);
							%let misReplaceVar= %scan(&missing_replacement_var., &i.);

							%if "&treatment_newVar." = "replace" or "&treatment_newVar." = "rename" %then
								%do;
									if &misTreatVar.=. then
										do;
											&misTreatVar.=&misReplaceVar.;
										end;

									%if "&missing_spl." ^= "" %then
										%do;
											if &misTreatVar. in (&missing_spl.) then
												&vars.= &misReplaceVar.;
										%end;
								%end;
							%else %if "&treatment_newVar." = "new" %then
								%do;
									if &misTreatVar.=. then
										&treatment_prefix._%substr(&vars.,1,25)= &misReplaceVar.;
									else &treatment_prefix._%substr(&vars.,1,25)=&misTreatVar.;

									%if "&missing_spl." ^= "" %then
										%do;
											if &misTreatVar. in (&missing_spl.) then
												&treatment_prefix._%substr(&vars.,1,25)= &misReplaceVar.;
										%end;
								%end;
						%end;
					;
					drop %if "&upper." ^= "" %then

						%do;
							upper_bound
						%end;

					%if "&lower." ^= "" %then
						%do;
							lower_bound
						%end;

					%if &treatment_option.=mean or &treatment_option.=mode or 
						&treatment_option.=median or &treatment_option.=trimmedmean %then
						pre_&treatment_option.;;
				run;

			%end;
		%else %if "&treatment_option." = "capping" %then
			%do;

				data temp;
					set temp;

					if &vars. < lower_bound then
					%if &treatment_newVar.=new %then
						%do;
							&treatment_prefix._&vars.=lower_bound;
						%end;
			%else %if &treatment_newVar.=replace %then
				%do;
					&vars.=lower_bound;
				%end;
					else if &vars. > upper_bound then

						%if &treatment_newVar.=new %then
							%do;
								&treatment_prefix._&vars.=upper_bound;
							%end;
						%else %if &treatment_newVar.=replace %then
							%do;
								&vars.=upper_bound;
							%end;
					else %if &treatment_newVar.=new %then
						%do;
						&treatment_prefix._&vars.=&vars.;
			%end;
		%else %if &treatment_newVar.=replace %then
			%do;
				&vars.=&vars.;
			%end;

		drop %if "&upper." ^= "" %then

			%do;
				upper_bound
			%end;

		%if "&lower." ^= "" %then
			%do;
				lower_bound
			%end;

		%if &treatment_option.=mean or &treatment_option.=mode or 
			&treatment_option.=median or &treatment_option.=trimmedmean %then
			pre_&treatment_option.;;
				run;

	%end;

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

	%if &treatment_option. = trimmedmean %then
		%do;

			data pre_univ&i.;
				set pre_univ&i.;
				rename pre_trimmedmean=trimmedmean;
			run;

		%end;

	/*POST TREATMENT UNIVARIATE VALUES*/
	proc univariate data = temp noprint;
		%if &treatment_newVar. = replace or &treatment_newVar. = rename %then
			%do;
				var &vars.;
			%end;
		%else %if &treatment_newVar. = new %then
			%do;
				var &treatment_prefix._%substr(&vars.,1,25);
			%end;

		by grp_var;
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

%end;

	data missing_treatment;
		retain variable grp_var
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

	data temp(drop=grp_var);
		set temp;
	run;

	/*CREATING THE OUTPUT DATA SET*/
	proc sort data=&dataset_final.;
		by &c_var_key.;
	run;

	data in.dataworking;
		set &dataset_final.;
		&c_var_key. = _n_;
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

%variable_treatment_acrossGrpby;
;