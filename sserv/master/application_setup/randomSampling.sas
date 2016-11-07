/*------------------------------------------------------------------------------------------------------------------------------------------*/
/*Parameters Required*/
/*------------------------------------------------------------------------------------------------------------------------------------------*/
/*%let codePath=/product-development/murx///SasCodes//8.7.1;*/
/*%let deactivated_var=ACV;*/
/*%let grp_flag=1_1_1;*/
/*%let n_grp=0;*/
/*%let input_path=/product-development/nida.arif;*/
/*%let output_path=/product-development/nida.arif/sample/sample_s1;*/
/*%let output_path_1=/product-development/nida.arif/sample/sample_s2;*/
/*%let n=60;*/
/*%let n_1=65;*/
/*%let seed=33;*/
/*%let out=output1;*/
/*%let out_1=output2;*/
/*%let indicatorvarname=1;*/
/*%let indicatorvarname_1=2;*/
/*%let strataVar=;*/
/*%let without_replacement=;*/
/*------------------------------------------------------------------------------------------------------------------------------------------*/
options mlogic mprint symbolgen;

%macro randomsampling;
	%let ind								  = &indicatorvarname.;
	%let c_var_key							  = primary_key_1644;
	%let flag_first=1;

	%without_replacement_twosamples:

		libname in "&input_path.";
	libname out "&output_path.";

	/*parameters*/
	%let c_file_log							  = &output_path./randomSampling_Log.log;
	%let indicatorvarname					  = in_&indicatorvarname.;
	%let c_file_txt_completed      			  = &output_path./randomsampling_completed.txt;
	%let c_file_txt_error          			  = ERROR;
	%let c_file_txt_warning        			  = warning;
	%let in_exist							  = 0;
	%let c_file_delete		   				  =	&c_file_txt_completed.#
		&output_path./&c_file_txt_error..txt#
		&output_path./&c_file_txt_warning..txt#
		&c_file_log.;

	/*Delete Files*/
	%do tempi = 1 %to %sysfunc(countw(%str(&c_file_delete.), %str(#)));
		%let c_file_delete_now = %sysfunc(compress(%scan(%str(&c_file_delete.), &tempi., %str(#))));
		filename myfile "&c_file_delete_now.";

		data _null_;
			rc = fdelete('myfile');
		run;

	%end;

	/*Log File*/
		proc printto log="&c_file_log." new;
		run;
	
		quit;
/*	proc printto;*/
/*	run;*/

	%let dsid = %sysfunc(open(in.dataworking));
	%let nobs =%sysfunc(attrn(&dsid,NOBS));

	/*	%let rc = %sysfunc(close(&dsid));*/
	/*		%let dsid=%sysfunc(open(in.dataworking));*/
	%if %sysfunc(varnum(&dsid,&indicatorvarname.)) > 0 %then
		%do;
			%let in_exist=1;

			data _null_;
				v1= "&indicatorvarname. already exists. Replacing it with the new sample data.";
				file "&output_path./&c_file_txt_warning..txt";
				put v1;
			run;

		%end;

	%let rc=%sysfunc(close(&dsid));

	data in.dataworking 
		%if &in_exist.=1 %then %do;
			(drop=&indicatorvarname.)
		%end;
	;
	set in.dataworking;
	run;

	%let c_sampsizesamprate = sampsize=&n.;
	%let c_strata_statement =;

	%if "&strataVar." ^= "" %then
		%do;
			%let strataVar = %sysfunc(compbl(&strataVar.));
		%end;

	data fin_dataset;
		set in.dataworking(keep=&c_var_key.

			%if "&strataVar." ^= "" %then
				%do;
					&strataVar.
				%end;

			%if "&n_grp" ^= "0" %then
				%do;
					grp&n_grp._flag
				%end;

			%if "&without_replacement." ^= "" %then
				%do;
					%let sampling_variables_keep=;
					%let sampling_variables_where=where;

					%do i=1 %to %sysfunc(countw("&without_replacement."," "));
						%let sampling_variable = %scan("&without_replacement.",&i," ");
						%let sampling_variables_keep=%sysfunc(compbl(&sampling_variables_keep. in_&sampling_variable.));

						%if &i. > 1 %then
							%do;
								%let sampling_variables_where=&sampling_variables_where. and;
							%end;

						%let sampling_variables_where=&sampling_variables_where. in_&sampling_variable.=0;
					%end;

					&sampling_variables_keep.
				%end;
			);
			%if "&n_grp" ^= "0" %then
				%do;
					where compress(grp&n_grp._flag) = "&grp_flag";
				%end;

			%if "&without_replacement." ^= "" %then
				%do;
					&sampling_variables_where.;
				%end;
	run;

	%let dsid = %sysfunc(open(work.fin_dataset));
	%let nobs_fin_dataset =%sysfunc(attrn(&dsid,NOBS));
	%let rc=%sysfunc(close(&dsid));

	%if &n. > &nobs_fin_dataset. %then
		%do;

			data _null_;
				v1= "Number of observations in the dataset for the current selection is lesser than the sample size provided";
				file "&output_path./&c_file_txt_error..txt";
				put v1;
			run;
			
			%goto the_end;
		%end;

	%random_sample_run:

	%if "&strataVar." ^= "" %then
		%do;
			%let c_sampsizesamprate = samprate=%sysevalf(&n./&nobs.);
			%let c_strata_statement = strata &strataVar./alloc=proportional%str(;);

			proc sort data=fin_dataset out=fin_dataset;
				by &strataVar.;
			run;

			quit;

			proc sort data=fin_dataset out=strata_levels nodupkey;
				by &strataVar.;
			run;

			quit;

			%let dsid = %sysfunc(open(work.strata_levels));
			%let nobs_strata =%sysfunc(attrn(&dsid,NOBS));
			%let rc = %sysfunc(close(&dsid));
			%put &nobs_strata.;

			%if &nobs_strata. > &n. %then
				%do;

					data _null_;
						v1= "Number of stratas are greater than the sample size";
						file "&output_path./&c_file_txt_error..txt";
						put v1;
					run;

					%goto the_end;
				%end;
		%end;

	proc surveyselect data=fin_dataset method=SRS &c_sampsizesamprate. SEED=&seed. out=temp_indicator;
		&c_strata_statement.
			run;
	quit;

	%let drop=;

	data temp_indicator;
		set temp_indicator

			%if "&strataVar." ^= "" %then
				%do;
					(drop=selectionprob samplingweight Total AllocProportion SampleSize ActualProportion)
				%end;
			;
			&indicatorvarname. = 1;
	run;

	proc sort data=temp_indicator out=temp_indicator;
		by &c_var_key.;
	run;

	quit;

	proc sort data=in.dataworking out=in.dataworking;
		by &c_var_key.;
	run;

	quit;

	data in.dataworking;
		merge in.dataworking temp_indicator;
		by &c_var_key.;

		if &indicatorvarname. ^= 1 then
			&indicatorvarname. = 0;
	run;

	data out.&out.;
		merge in.dataworking temp_indicator;
		by &c_var_key.;

		if &indicatorvarname. = 1 then
			output;
	run;

	%let drop=&c_var_key.;

	proc contents data=out.&out. out=out_contents(keep=name);
	run;

	quit;

	data out_contents_subset;
		set out_contents;

		if index(name,"grp") and index(name,"_flag");

		if index(name,"grp") and index(name,"_flag") then
			call symput("delleat",name);
	run;

	data contents_sample_indexes;
		set out_contents;

		if index(name,"in_");

		if index(name,"in_") then
			call symput("delleat",name);
	run;

	proc append base=out_contents_subset data=contents_sample_indexes force;
	run;

	%if %symexist(delleat) %then
		%do;

			proc sql;
				select name into: drop_temp separated by " " from out_contents_subset;
			run;

			quit;

			%let drop = &drop. &drop_temp.;
		%end;

	%if "&deactivated_var." ^= "" %then
		%do;
			%let drop = &drop. %sysfunc(compbl(&deactivated_var.));
		%end;

	data out.&out.(drop=&drop.);
		set out.&out.;
	run;

	data _null_;
		v1= "Random sampling completed successfully.";
		file "&c_file_txt_completed.";
		put v1;
	run;

	%if "&out_1." ^= "" and "&flag_first." = "1" %then
		%do;
			%let out=&out_1.;
			%let n=&n_1.;
			%let indicatorvarname=&indicatorvarname_1.;
			%let flag_first=0;
			%let output_path = &output_path_1.;
			%let seed=%eval(&seed.+10);
			%put &flag_first.;

			%if "&without_replacement." ^= "" %then
				%do;
					%let without_replacement = &without_replacement. &ind.;
				%end;
			%goto without_replacement_twosamples;
		%end;

	%the_end:
%mend;

%randomsampling;