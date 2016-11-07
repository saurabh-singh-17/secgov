/***************************************** SAMPLE PARAMETERS ****************************************************/
/*%let codePath=/product-development/murx///SasCodes//8.7.1;*/
/*%let input_path=/product-development/nida.arif;*/
/*%let output_path=/product-development/nida.arif/Output;*/

/************************** Common across missing treatment and outlier treatment *******************************/
/*%let var_list=miss_acv sales chiller_flag;*/

/****************************************** If missing treatment ************************************************/
/*%let flag_missing=true;*/
/*%let missing_spl=1;*/

/****************************************** If outlier treatment ************************************************/
/*%let flag_outlier=false;*/
/*%let outlier_type_side=perc;*/
/*%let iqr_value =;*/
/*%let perc_lower=10;*/
/*%let perc_upper=90;*/

/******************************* Differentiate between across grp by and across dataset**************************/
/*%let grp_vars=geography;*/

/********************************************** Per group by ****************************************************/
/*%let n_grp=1;*/
/*%let grp_flag=1_1_1;*/

/********************************************* CODE BEGINS ************************************************/

proc datasets lib=work kill;
run;

%let completedTXTPath =  &output_path/MULTIVAR_DETECTION_COMPLETED.txt;
options mprint mlogic symbolgen mfile;

proc printto log="&output_path/MultiVar_Detection_Log.log";
run;

quit;

/*proc printto;*/
/*run;*/
libname in "&input_path.";
libname out "&output_path.";

%macro index_acrossGrp;
	/* MISSING VALUE - Get the count and indexes of the missing values and special characters */
	%if "&missing_spl." ^= "" %then
		%do;

			proc sql;
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
					set univ&i.;
					missing_count=missing_count+%scan(&mis.,&j.," ");

					if grp_var="%scan(&grp_var.,&j.,'!!')";
				run;

				proc append base=all data=n&j. force;
				run;

				proc datasets lib = work;
					delete n&j.;
				run;

			%end;

			data univ&i.;
				set all;
			run;

			proc datasets lib = work;
				delete all;
			run;

		%end;

	/*OUTLIERS - Check the cut offs, count and indexes of the outliers*/
	%if &flag_outlier. = true %then
		%do;
			%let upper = true;

			data univ&i;
				set univ&i;

				%if &outlier_type_side. = one %then
					%do;
						upper_cutoff=p_75+&iqr_value.*iqr;
					%end;
				%else %if &outlier_type_side. = two %then
					%do;
						%let lower = true;
						upper_cutoff=p_75+&iqr_value.*iqr;
						lower_cutoff=p_25-&iqr_value.*iqr;
					%end;
				%else %if &outlier_type_side. = perc %then
					%do;
						upper_cutoff=p_%sysfunc(tranwrd(&perc_upper.,.,_));
						%let lower = true;
						lower_cutoff=p_%sysfunc(tranwrd(&perc_lower.,.,_));
					%end;
			run;

			data cnt&i;
				merge temp(keep=%scan(&var_list,&i) grp_var &c_var_key.) univ&i(keep=grp_var upper_cutoff
				%if "&lower." ^= "" %then

					%do;
						lower_cutoff
					%end;
				);
				by grp_var;
			run;

			proc sql;
				create table cnt&i as 
					select grp_var,count(%scan(&var_list,&i)) as outlier_count
						from cnt&i

					%if "&lower." ^= "" %then
						%do;
							where %scan(&var_list,&i)>upper_cutoff or %scan(&var_list,&i)<lower_cutoff
						%end;

					%if "&lower." = "" %then
						%do;
							where %scan(&var_list,&i)>upper_cutoff
						%end;

					group by grp_var;
			quit;

			data univ&i;
				merge univ&i cnt&i;
				by grp_var;
			run;

		%end;

	data univ&i;
		length variable $32.;
		set univ&i;
		variable = "%scan(&var_list,&i)";
		attrib _all_ label=' ';

			%if &flag_missing. = true %then
				%do;
					missing_perc=missing_count/&frequency.;
				%end;

			%if &flag_outlier. = true %then
				%do;
					outlier_perc=outlier_count/&frequency.;
				%end;
	run;

%mend;

%macro index_acrossDataset;
	/*OUTLIERS - Check the cut offs, count and indexes of the outliers*/
	%if &flag_outlier. = true %then
		%do;
			%let upper=true;

			data _null_;
				set univ&i.;

				%if "&outlier_type_side." = "one" %then
					%do;
						call symputx("outlier_ub", compress(p_75 + (&iqr_value. * iqr)));
					%end;
				%else %if "&outlier_type_side." = "two" %then
					%do;
						%let lower=true;
						call symputx("outlier_lb", compress(p_25 - (&iqr_value. * iqr)));
						call symputx("outlier_ub", compress(p_75 + (&iqr_value. * iqr)));
					%end;
				%else %if "&outlier_type_side." = "perc" %then
					%do;
						%let lower=true;
						call symputx("outlier_lb", compress(p_%sysfunc(tranwrd(&perc_lower.,.,_))));
						call symputx("outlier_ub", compress(p_%sysfunc(tranwrd(&perc_upper.,.,_))));
					%end;
			run;

			proc sql noprint;
				%if "&lower." ^= "" %then
					%do;
						select count(&vars.) into :outlier_cnt from &dataset_use. where &vars. > %sysevalf(&outlier_ub.) or &vars. < %sysevalf(&outlier_lb.);
					%end;
				%else
					%do;
						select count(&vars.) into :outlier_cnt from &dataset_use. where &vars. > %sysevalf(&outlier_ub.);
					%end;
			quit;

		%end;

	/* MISSING VALUE - Get the count and indexes of the missing values and special characters */
	%if &flag_missing. = true %then
		%do;
			%if "&missing_spl." ^= "" %then
				%do;

					proc sql noprint;
						select count(&vars.) into :cnt_splChar from &dataset_use. where &vars. in (&missing_spl.);
					quit;

					%put &cnt_splChar.;
				%end;
		%end;

	/* Create the variable dataset with the outlier inputs and missing value inputs */
	data univ&i.;
		length variable $32.;
		set univ&i.;
		variable = "&vars.";

		%if "&flag_missing." = "true" %then
			%do;
				%if "&missing_spl." ^= "" %then
					%do;
						missing_count = missing_count+%eval(&cnt_splChar);
					%end;

				missing_perc = missing_count/%eval(&nobs.);
			%end;

		%if &flag_outlier. = true %then
			%do;
				upper_cutoff = %sysevalf(&outlier_ub.);

				%if "&lower." ^= "" %then
					%do;
						lower_cutoff = %sysevalf(&outlier_lb.);
					%end;

				outlier_count = %sysevalf(&outlier_cnt.);
				outlier_perc = %eval(&outlier_cnt.)/%eval(&nobs.);
			%end;
	run;

	%symdel cnt_splChar outlier_lb outlier_ub outlier_cnt;
%mend;

%macro multipleVar_detection;
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

	%if "&grp_vars." ^= "" %then
		%do;

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

			%let dataset_use = temp;
		%end;

	%do i=1 %to %sysfunc(countw(&var_list.));
		%let vars = %scan(&var_list,&i);

		proc univariate data=&dataset_use.(keep=&vars.
			%if "&grp_vars." ^= "" %then
				%do;
					grp_var
				%end;
			) noprint;
			var &vars.;

			%if "&grp_vars." ^= "" %then
				%do;
					by grp_var;
				%end;

			output out=univ&i
			mean=mean
			median=median
			mode=mode
			%if &flag_missing. = true %then

				%do;
					nmiss=missing_count
				%end;

			range=range

			%if &flag_outlier. = true %then
				%do;
					qrange=iqr
				%end;

			pctlpre=p_ pctlpts=0 to 0.8 by 0.2, 1 to 5 by 1,25,50,75,95 to 98 by 1,99 to 100 by 0.1

			%if &outlier_type_side. = perc %then
				%do;
					,&perc_lower.
					,&perc_upper.
				%end;
			;
		run;

		/*Calculate the missing indexes, missing count, outlier indexes and outlier count*/
		%if "&grp_vars." ^= "" %then
			%do;
				%index_acrossGrp;
			%end;
		%else
			%do;
				%index_acrossDataset;
			%end;

		proc append base=output data=univ&i. FORCE;
		run;

		proc datasets lib = work;
			delete univ&i.;
		run;

	%end;

	data output(drop=iqr);
		retain variable %if "&flag_missing." = "true" %then %do;
		missing_count missing_perc
		%end;

		%if &flag_outlier. = true %then
			%do;
				outlier_count outlier_perc upper_cutoff

				%if "&lower." ^= "" %then
					%do;
						lower_cutoff
					%end;
			%end;

		mean median mode;
		set output;
		attrib _all_ label="";

		%if "&flag_missing." = "true" %then
			%do;
				format missing_perc PERCENT8.2;
			%end;

		%if &flag_outlier. = true %then
			%do;
				format outlier_perc PERCENT8.2;
			%end;

		format p_: 12.3;
	run;

	proc export data = output
		outfile = "&output_path./multiVar_detection.csv"
		dbms = CSV replace;
	run;

	data _null_;
		v1= "EDA - MULTIVAR_DETECTION_COMPLETED";
		file "&output_path/MULTIVAR_DETECTION_COMPLETED.txt";
		put v1;
	run;

%mend;

%multipleVar_detection;