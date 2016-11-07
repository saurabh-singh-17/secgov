/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/CATEGORICAL_TREATMENT_COMPLETED.txt;
option mprint mlogic symbolgen mfile;
dm log 'clear';

/**/
/*proc printto log="&output_path/categorical_treatment_Log.log";*/
/*run;*/
/*quit;*/
proc printto;
run;

quit;

/*proc printto print="&output_path./categorical_treatment_Output.out";*/
libname in "&input_path.";
libname out "&output_path.";

%MACRO categorical_treatment;
	%let dsid = %sysfunc(open(in.dataworking));
	%let nobs = %sysfunc(attrn(&dsid,NOBS));
	%let rc = %sysfunc(close(&dsid));

	%if "&var_list." ^= "" %then
		%do;

			data temp;
				set in.dataworking(keep = &var_list.);
			run;

		%end;

	%let i = 1;

	%do %until (not %length(%scan(&var_list, &i)));
		%let dsid = %sysfunc(open(temp));
		%let nobs = %sysfunc(attrn(&dsid,NOBS));
		%let rc = %sysfunc(close(&dsid));

		/*get vartype*/
		%let dsid = %sysfunc(open(temp));
		%let varnum = %sysfunc(varnum(&dsid,%scan(&var_list, &i)));
		%let vartyp = %sysfunc(vartype(&dsid,&varnum)); /* variable type */
		%let rc = %sysfunc(close(&dsid));
		%put &vartyp;

		/*prepare the table per var*/
		proc sql;
			create table summary&i. as
				select "%scan(&var_list, &i)" as variable length = 32,%scan(&var_list, &i) as levels, 
					count(%scan(&var_list, &i)) as num_obs,
					(calculated num_obs/&nobs.)*100 as percent_obs
				from temp

				%if &vartyp. = N %then
					%do;
						where %scan(&var_list, &i) ^= .
					%end;

				%if &vartyp. = C %then
					%do;
						where %scan(&var_list, &i) ^= ""
					%end;

				group by %scan(&var_list, &i);
		quit;

		proc sort data=summary&i.;
			by descending num_obs;
		run;

		proc sql;
			select levels into:mode&i.
				from summary&i. having num_obs=max(num_obs);
		quit;

		/*calculate missing*/
		proc sql;
			create table missing&i. as
				select "%scan(&var_list, &i)" as variable length = 32, "MISSING" as levels, NMISS(%scan(&var_list, &i)) as num_obs,
					(calculated num_obs/&nobs.)*100 as percent_obs
				from temp
					quit;

		proc sql;
			select num_obs into:num_affected&i.
				from missing&i.;
		quit;

		proc sql;
			select percent_obs into:percent_affected&i.
				from missing&i.;
		quit;

		%let i = %eval(&i.+1);
	%end;

	proc sql;
		create table post_summary	
			(
			variable varchar(255),
			pre_mode varchar(255),
			post_mode varchar(255),
			treatment_type varchar(255),
			treatment_value varchar(255),
			no_of_rows_affected integer,
			percent_rows_affected float

			);
	quit;

	proc sql;
		insert into post_summary(treatment_type)
			values("&treatment_type.");
	quit;

	%let j = 1;

	%do %until (not %length(%scan(&var_list,&j)));
		%let dsid = %sysfunc(open(temp));
		%let t_var = %scan(&var_list,&j);
		%let varnum = %sysfunc(varnum(&dsid,%scan(&var_list, &j)));
		%let vartyp = %sysfunc(vartype(&dsid,&varnum)); /* variable type */
		%let rc = %sysfunc(close(&dsid));

		%if "&treatment_type"= "mode" %then
			%do;
				/*for temp*/
				proc sql;
					alter table temp add &treatment_prefix._&t_var. %if &vartyp. = C %then

						%do;
							varchar(50);
						%end;

					%if &vartyp. = N %then
						%do;
							integer;
						%end;
				quit;

				/*for dataworking*/
				proc sql;
					alter table in.dataworking add &treatment_prefix._&t_var. %if &vartyp. = C %then

						%do;
							varchar(50);
						%end;

					%if &vartyp. = N %then
						%do;
							integer;
						%end;
				quit;

				/*for temp*/
				proc sql;
					update temp set &treatment_prefix._&t_var.=&t_var.;
				quit;

				/*for dataworking*/
				proc sql;
					update in.dataworking set &treatment_prefix._&t_var.=&t_var.;
				quit;

				/*for temp*/
				proc sql;
					update temp set %if &vartyp. = C %then

						%do;
							&treatment_prefix._&t_var.="&&mode&j."
						%end;
					%else
						%do;
							&treatment_prefix._&t_var.=&&mode&j.
						%end;

					where %if &vartyp. = N %then

						%do;
							&treatment_prefix._&t_var.=.;
						%end;
					%else
						%do;
							&treatment_prefix._&t_var.="";
						%end;
				quit;

				/*for dataworking*/
				proc sql;
					update in.dataworking set  %if &vartyp. = C %then

						%do;
							&treatment_prefix._&t_var.="&&mode&j."
						%end;
					%else
						%do;
							&treatment_prefix._&t_var.=&&mode&j.
						%end;

					where %if &vartyp. = N %then

						%do;
							&treatment_prefix._&t_var.=.;
						%end;
					%else
						%do;
							&treatment_prefix._&t_var.="";
						%end;
				quit;

				data Temp;
					set temp;
					primary_key_1644=_n_;
				run;

				proc sort data=temp;
					by primary_key_1644;
				run;

				proc sort data=in.dataworking;
					by primary_key_1644;
				run;

				data in.dataworking;
					merge temp in.dataworking;
					by primary_key_1644;
				run;

				%let treatment_val=&&mode&j.;
				%let post_mode= &&mode&j.;
			%end;
		%else %if "&treatment_type"= "custom_type" %then
			%do;
				/*%let custom = %scan(&custom_val.,&j);*/
				%let custom = &custom_val.;

				/*for temp*/
				proc sql;
					alter table temp add &treatment_prefix._&t_var. %if &vartyp. = C %then

						%do;
							varchar(50);
						%end;

					%if &vartyp. = N %then
						%do;
							integer;
						%end;
				quit;

				proc sql;
					update temp set &treatment_prefix._&t_var.=&t_var.;
				quit;

				proc sql;
					update temp set %if &vartyp. = C %then

						%do;
							&treatment_prefix._&t_var.="&custom."
						%end;
					%else
						%do;
							&treatment_prefix._&t_var.=%eval(&custom.)
						%end;

					where %if &vartyp. = N %then

						%do;
							&treatment_prefix._&t_var.=.;
						%end;
					%else
						%do;
							&treatment_prefix._&t_var.="";
						%end;
				quit;

				/*for dataworking*/
				proc sql;
					alter table in.dataworking add &treatment_prefix._&t_var. %if &vartyp. = C %then

						%do;
							varchar(50);
						%end;

					%if &vartyp. = N %then
						%do;
							integer;
						%end;
				quit;

				proc sql;
					update in.dataworking set &treatment_prefix._&t_var.=&t_var.;
				quit;

				proc sql;
					update in.dataworking set %if &vartyp. = C %then

						%do;
							&treatment_prefix._&t_var.="&custom."
						%end;
					%else
						%do;
							&treatment_prefix._&t_var.=%eval(&custom.)
						%end;

					where %if &vartyp. = N %then

						%do;
							&treatment_prefix._&t_var.=.;
						%end;
					%else
						%do;
							&treatment_prefix._&t_var.="";
						%end;
				quit;

				proc freq data=temp;
					tables &treatment_prefix._&t_var/out=&treatment_prefix._&t_var;
				run;

				%let treatment_val=&custom.;

				proc sql;
					select &treatment_prefix._&t_var into:post_mode
						from &treatment_prefix._&t_var having count=max(count);
				quit;

				proc sort data=in.dataworking;
					by primary_key_1644;
				run;

				data temp;
					set temp;
					primary_key_1644=_n_;
				run;

				proc sort data=temp;
					by primary_key_1644;
				run;

				data in.dataworking;
					merge temp in.dataworking;
					by primary_key_1644;
				run;

			%end;
		%else %if "&treatment_type"= "delete" %then
			%do;

				data in.dataworking;
					set in.dataworking;

					%if &vartyp. = N %then
						%do;
							if &t_var.=. then
								delete;
						%end;
					%else
						%do;
							if &t_var.="" then
								delete;
						%end;
				run;

				%let treatment_val=;
				%let post_mode= &&mode&j.;
			%end;
		%else %if "&treatment_type"= "replace_with_existing" %then
			%do;
				%let misTreatVar= %scan(&var_list., &j.);
				%let misReplaceVar= %scan(&missing_replacement_var., &j.);
				%let treatment_val=;

				data in.dataworking;
					set in.dataworking;

					%if &vartyp. = C %then
						%do;
							if &t_var. = "" then
								&treatment_prefix._%substr(&misTreatVar.,1,25) = &misReplaceVar.;
							else &treatment_prefix._%substr(&misTreatVar.,1,25) = &misTreatVar.;
						%end;
					%else
						%do;
							if &t_var. = . then
								&treatment_prefix._%substr(&misTreatVar.,1,25) = &misReplaceVar.;
							else &treatment_prefix._%substr(&misTreatVar.,1,25) = &misTreatVar.;
						%end;
				run;

				%let post_mode= &&mode&j.;
			%end;

		proc sql;
			insert into post_summary(variable,pre_mode,post_mode,treatment_type,treatment_value,no_of_rows_affected,percent_rows_affected)
				values("&t_var.","&&mode&j.","&post_mode.","&treatment_type.","&treatment_val.",&&num_affected&j.,&&percent_affected&j.);
		quit;

		%let j = %eval(&j.+1);
	%end;

	proc sql;
		delete from post_summary where variable="";
	quit;

	proc export data = post_summary
		outfile = "&output_path./categorical_treatment.csv"
		dbms = csv replace;
	run;

%MEND categorical_treatment;

%categorical_treatment;

data _null_;
	v1= "CATEGORICAL_TREATMENT_COMPLETED";
	file "&output_path/CATEGORICAL_TREATMENT_COMPLETED.txt";
	put v1;
run;
;