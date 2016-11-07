/*Successfully converted to SAS Server Format*/
*processbody;
/* VERSION # 1.1.0 */

options mprint mlogic symbolgen mfile;

%let completedTXTPath = &output_path/params_multipleVar_detection_acrossGrp_Log.log;

proc printto log="&output_path/params_multipleVar_detection_acrossGrp_Log.log";
run;
quit;
	
/*proc printto print="&output_path/params_multipleVar_detection_acrossGrp_Output.out";*/
	

libname in "&input_path.";
libname out "&output_path.";


data _null_;
		call symput("grp", tranwrd("&grp_vars."," ",",'_',"));
		run;
%put &grp;

data temp(drop=&grp_vars. keep=&var_list. grp_var);
	set in.Dataworking nobs=n;
	format grp_var $32.;
	call symput('frequency',n);
	grp_var=cat(&grp.);
	run;
%put &frequency.;
proc sort data = temp;
	by grp_var;
	run;

%macro missing_treatment2;
	 
	%do i=1 %to %sysfunc(countw(&var_list.));
	%if &flag_outlier. = true and &flag_missing. = true and &treatment_newVar. = new and &pref. = outlier %then %do;
			%let this_var=&treatment_prefix._%scan(&var_list,&i);
			%put &this_var.;
			%let treatment_newVar = replace;
	%end;
	%else %do;
		%let this_var=%scan(&var_list,&i);
	%end;
		%put &this_var.;
		proc univariate data=temp;
			var &this_var.;
			by grp_var;
			output out=new&i
			mean=pre_mean
			median=pre_median
			mode=pre_mode
			%if &flag_missing. = true %then nmiss=nmiss;
			pctlpre=P_ pctlpts=&missing_treat_val.;
			run;
		

		%if "&missing_spl." ^= "" %then %do;
			proc sql;
				select count(&this_var.) into:mis
				from temp 
				where &this_var. in (&missing_spl.);
				quit;
		%end;

		data new&i;
			length variable $32.;
			set new&i;
			variable = "&this_var.";
			attrib _all_ label=' ';
			%if &flag_missing. = true %then %do;
				%if "&missing_spl." ^= "" %then %do;
					nmiss=nmiss+&mis;
				%end;
				missing_percetange=nmiss/&frequency.;
			%end;
			run;
	
		data temp;
			merge new&i temp;
			by grp_var;
			run;
	
		data temp;
			set temp;
						
			%if &missing_treatment.=mean or &missing_treatment.=mode or &missing_treatment.=median %then %do;
       			 
				if &this_var. = . %if "&missing_spl." ^= "" %then %do; or &this_var. in (&missing_spl.) %end; then do;
					%if &treatment_newVar.=new %then %do;
							&treatment_prefix._&this_var.=pre_&missing_treatment.;
					%end;
					%else %if &treatment_newVar.=replace %then %do;
						&this_var.=pre_&missing_treatment.;
					%end;
					%else %if &treatment_newVar.=rename %then %do;
						&this_var.=pre_&missing_treatment.;
						rename &this_var.=&treatment_prefix._&this_var.;
					%end;
				end;	
				else do;
					%if &treatment_newVar.=new %then %do;
							&treatment_prefix._&this_var.=&this_var.;
					%end;
					%else %if &treatment_newVar.=rename %then %do;
						rename &this_var.=&treatment_prefix._&this_var.;
					%end;
				end;
			%end;

			%else %if &missing_treatment.=capping %then %do;
				if &this_var. = . %if "&missing_spl." ^= "" %then %do; or &this_var. in (&missing_spl.) %end; then do;
					%if &treatment_newVar.=new %then %do;
						&treatment_prefix._&this_var.=p_&missing_treat_val.;
					%end;
					%else %if &treatment_newVar.=replace %then %do;
						&this_var.=p_&missing_treat_val.;
					%end;
					%else %if &treatment_newVar.=rename %then %do;
						&this_var.=p_&missing_treat_val.;
						rename &this_var.=&treatment_prefix._&this_var.;
					%end;	
				end;
				else do;
					%if &treatment_newVar.=new %then %do;
						&treatment_prefix._&this_var.=&this_var.;
					%end;
					%else %if &treatment_newVar.=rename %then %do;
						rename &this_var.=&treatment_prefix._&this_var.;
					%end;
				end;	
			%end;
			
			%else %if &missing_treatment.=custom_type %then %do;
				if &this_var. = . %if "&missing_spl." ^= "" %then %do; or &this_var. in (&missing_spl.) %end; then do;
					%if &treatment_newVar.=new %then %do;
						&treatment_prefix._&this_var.=&missing_treat_val.;
					%end;
					%else %if &treatment_newVar.=replace %then %do;
						&this_var.=&missing_treat_val.;
					%end;
					%else %if &treatment_newVar.=rename %then %do;
						&this_var.=&missing_treat_val.;
						rename &this_var.=&treatment_prefix._&this_var.;
					%end;	
				end;
				else do;
					%if &treatment_newVar.=new %then %do;
						&treatment_prefix._&this_var.=&this_var.;
					%end;
					%else %if &treatment_newVar.=rename %then %do;
						rename &this_var.=&treatment_prefix._&this_var.;
					%end;
				end;	
			%end;

			%else &missing_treatment.=delete %then %do;
				if &this_var. = . %if "&missing_spl." ^= "" %then %do; or &this_var. in (&missing_spl.) %end; then delete;
			%end;
			
		run;
		
		proc univariate data=temp;
			var 
			%if treatment_newVar = replace or treatment_newVar = new %then %do;
				&treatment_prefix._&this_var.; 
			%end;
			%else %do; 
				&this_var.;
			%end;
			by grp_var;
			output out=post_new&i
			mean=post_mean
			median=post_median
			mode=post_mode
			pctlpre=P_ pctlpts=0 to 0.8 by 0.2, 1 to 5 by 1,25,50,75,95 to 98 by 1,99 to 100 by 0.1;
			run;

		data new&i;
			length treatment $11.;
			length replace_type $7.;
			merge new&i post_new&i.;
			by grp_var;
			attrib _all_ label=' ';
			
			spl_chars="&missing_spl.";
			treatment="&missing_treatment.";
			treat_value="&missing_treat_val.";
			replace_type="&treatment_newVar.";
			run;

		proc append base = missing_output data =new&i force;
			run;

	%end;
%mend missing_treatment2;
		
%macro outlier_treatment3;

	%let upper =;
	%let lower =;
	        
	%do i=1 %to %sysfunc(countw(&var_list.));
	%if &flag_outlier. = true and &flag_missing. = true and &treatment_newVar. = new and &pref. = missing %then %do;
			%let this_var=&treatment_prefix._%scan(&var_list,&i);
			%let treatment_newVar = replace;
	%end;
	%else %do;
		%let this_var=%scan(&var_list,&i);
	%end;
		%put &this_var.;
			proc univariate data=temp;
			var &this_var.;
			by grp_var;
			output out=new&i
			mean=pre_mean
			median=pre_median
			mode=pre_mode
			%if &flag_outlier. = true %then qrange=iqr;
			pctlpts=&outlier_treat_val., %if &outlier_type.=iqr %then %do; 25,75 %end; 
						%else %if &outlier_type.=perc %then %do; &perc_upper., &perc_lower. %end;
			pctlpre=P_ 
			;
			run;
	
		data new&i;
			length variable $32.;
			set new&i;
			variable = "&this_var.";
			attrib _all_ label=' ';
			run;

		
		data new&i;
			set new&i;
			%if &outlier_type. = iqr %then %do;
				%let upper=true;
				%if &outlier_side. = two %then %do;
					%let lower=true;
					upper_bound=p_75+&iqr_value.*iqr;
					lower_bound=p_25-&iqr_value.*iqr;
				%end;
				%else %if &outlier_side. = one %then %do;
					upper_bound=p_75+&iqr_value.*iqr;
				%end;
			%end;
			%else %if &outlier_type. = perc %then %do;
				%if "&perc_lower." ^= "" %then %do;
					%let lower=true;
					lower_bound=p_%sysfunc(tranwrd(&perc_lower.,.,_));
				%end;
				%if "&perc_upper." = "" %then %do;
					%let upper=true;
					upper_bound=p_%sysfunc(tranwrd(&perc_upper.,.,_));
				%end;
			%end;

			run;

		data temp;
			merge temp(in=a) new&i(in=b keep=grp_var %if "&upper." ^= "" %then %do; upper_bound %end;
				%if "&lower." ^= "" %then %do; lower_bound %end;
				%if &outlier_treatment.=mean or &outlier_treatment.=mode &outlier_treatment.=median %then pre_&outlier_treatment.;
				%else %if &outlier_treatment.=capping %then p_%sysfunc(tranwrd(&outlier_treat_val.,.,_)););
			by grp_var;
			if a or b;
			run;	

		data temp;
			set temp;
	
				%if "&upper." ^= "" and "&lower." ^= "" %then %do;
					if &this_var.<lower_bound or &this_var.> upper_bound then
				%end;
				%if "&upper." = "" and "&lower." ^= "" %then %do;
					if &this_var. < lower_bound then
				%end;
				%if "&upper." ^= "" and "&lower." = "" %then %do;
					if &this_var.> upper_bound then
				%end;
					%if &outlier_treatment.=mean or &outlier_treatment.=mode or &outlier_treatment.=median %then %do;
						%if &treatment_newVar.=new %then %do;
							&treatment_prefix._&this_var.=pre_&outlier_treatment.;
						%end;
						%else %if &treatment_newVar.=replace %then %do;
							&this_var.=pre_&outlier_treatment.;
						%end;
						%else %if &treatment_newVar.=rename %then %do;
							&this_var.=pre_&outlier_treatment.;
							rename &this_var.=&treatment_prefix._&this_var.;
						%end;
					else
						%if &treatment_newVar.=new %then %do;
							&treatment_prefix._&this_var.=&this_var.;
						%end;
						%else %if &treatment_newVar.=replace %then %do;
							&this_var.=&this_var.;
						%end;
						%else %if &treatment_newVar.=rename %then %do;
							&this_var.=&this_var.;
							rename &this_var.=&treatment_prefix._&this_var.;
						%end;
					%end;
					%else %if &outlier_treatment.=capping %then %do;
						%if &treatment_newVar.=new %then %do;
							&treatment_prefix._&this_var.=p_%sysfunc(tranwrd(&outlier_treat_val.,.,_));
						%end;
						%else %if &treatment_newVar.=replace %then %do;
							&this_var.=p_%sysfunc(tranwrd(&outlier_treat_val.,.,_));
						%end;
						%else %if &treatment_newVar.=rename %then %do;
							&this_var.=p_%sysfunc(tranwrd(&outlier_treat_val.,.,_));
							rename &this_var.=&treatment_prefix._&this_var.;
						%end;
					else
						%if &treatment_newVar.=new %then %do;
							&treatment_prefix._&this_var.=&this_var.;;
						%end;
						%else %if &treatment_newVar.=replace %then %do;
							&this_var.=&this_var.;
						%end;
						%else %if &treatment_newVar.=rename %then %do;
							&this_var.=&this_var.;
							rename &this_var.=&treatment_prefix._&this_var.;
						%end;
					%end;
					%else %if &outlier_treatment.=delete %then %do;
						delete
						else &treatment_prefix._&this_var.=&this_var.;
					%end;
				;
		drop %if "&upper." ^= "" %then %do; upper_bound %end; %if "&upper." ^= "" %then %do; lower_bound %end; 
			%if &outlier_treatment.=mean or &outlier_treatment.=mode &outlier_treatment.=median %then pre_&outlier_treatment.;
				%else %if &outlier_treatment.=capping %then p_%sysfunc(tranwrd(&outlier_treat_val.,.,_));;
		run;


		proc univariate data=temp;
			var 
			%if treatment_newVar = replace or treatment_newVar = new %then %do;
				&treatment_prefix._&this_var.; 
			%end;
			%else %do; 
				&this_var.;
			%end;
			by grp_var;
			output out=post_new&i
			mean=post_mean
			median=post_median
			mode=post_mode
			pctlpre=P_ pctlpts=0 to 0.8 by 0.2, 1 to 5 by 1,25,50,75,95 to 98 by 1,99 to 100 by 0.1;
			
			run;

		data new&i;
			merge new&i(drop=p_:) post_new&i.;
			by grp_var;
			attrib _all_ label=' ';
			perc_iqr="&iqr_value.";
			treatment="&outlier_treatment.";
			treat_value="&outlier_treat_val.";
			replace_type="&treatment_newVar.";
			run;

		proc append base = outlier_output data =new&i force;
			run;
	%end;
%mend outlier_treatment3;

%macro main2;
	%if  &flag_outlier. = true and &flag_missing. = false %then %do;
		%outlier_treatment3;
	%end;
	%else %if &flag_outlier. = false and &flag_missing. = true %then %do;
		%missing_treatment2;
	%end;
	%else %if  &flag_outlier. = true and &flag_missing. = true %then %do;
		
		%if &pref. = missing %then %do;
				%missing_treatment2;
				%outlier_treatment3;
		%end;
		%else %if &pref. = outlier %then %do;
				%outlier_treatment3;
				%missing_treatment2;
		%end;
	%end;

%mend main2;
%main2;




