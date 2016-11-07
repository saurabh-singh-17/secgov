/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/TREATMENT_COMPLETED.txt;
/* VERSION # 1.1.0 */
options mprint mlogic symbolgen mfile;
dm log 'clear';

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

data temp(drop=&grp_vars.);
	set in.Dataworking nobs=n;
	format grp_var $32.;
	call symput('frequency',n);
	grp_var=cat(&grp.);
	grp_var = compress(grp_var);
	run;
data temp1(keep=&var_list.);
	set in.Dataworking;
	run;
data temp;
	merge temp1 temp;
	run;

%put &frequency.;
proc sort data = temp;
	by grp_var;
	run;
		
%macro outlier_treatment4;

	%let upper =;
	%let lower =;
	        
	%do i=1 %to %sysfunc(countw(&var_list.));
		

		%let this_var=%scan(&var_list,&i);
		%put &this_var.;
			proc univariate data=temp;
			var &this_var.;
			by grp_var;
			output out=new&i
			mean=pre_mean
			median=pre_median
			mode=pre_mode
			%if &flag_outlier. = true %then qrange=iqr;
			pctlpts=%if &outlier_type.=iqr %then %do; 25,75 %end; 
						%else %if &outlier_type.=perc %then %do; &perc_upper., &perc_lower. %end;
			pctlpre=p_ 
			;
			run;
		
		data new&i;
			length variable $32.;
			set new&i;
			variable = "&this_var.";
			attrib _all_ label=' ';
			run;

		proc sql;
			create table b as select distinct grp_var from temp;
			quit;
		data new&i;
			set new&i;
			%if &outlier_type. = iqr %then %do;
				%let upper=true;
				call symput("iqr",iqr);
				upper_bound=p_75 + (&iqr_value. * iqr);
				%if &outlier_side. = two %then %do;
					lower_bound=p_25 - (&iqr_value. * iqr);
				%end;
			%end;
			%else %if &outlier_type. = perc %then %do;
				%if "&perc_lower." ^= "" %then %do;
					%let lower=true;
					lower_bound=p_%sysfunc(tranwrd(&perc_lower.,.,_));
				%end;
				%if "&perc_upper." ^= "" %then %do;
					%let upper=true;
					upper_bound=p_%sysfunc(tranwrd(&perc_upper.,.,_));
				%end;
			%end;
			run;

	data temp;
			merge temp (in=a) new&i.(keep=grp_var upper_bound %if &outlier_type.=perc or (&outlier_type.=iqr and &outlier_side. = two) %then lower_bound;);
			by grp_var;
			if a;
			run;

		%if &outlier_type. = iqr %then %do;
				%if &outlier_side. = two %then %do;
					proc sql;
						create table a as
						select count(&this_var.) as cnt,grp_var
						from temp
						where (&this_var. lt lower_bound) or (&this_var. gt upper_bound)
						group by grp_var;
						quit;
				%end;
				%else %if &outlier_side. = one %then %do;
					proc sql;
						create table a as
						select count(&this_var.) as cnt,grp_var
						from temp
						where &this_var. gt upper_bound
						group by grp_var;
						quit;
				%end;
			%end;
			%else %if &outlier_type. = perc %then %do;
				proc sql;
					create table a as
					select count(&this_var.) as cnt,grp_var
					from temp
					where (&this_var. lt lower_bound) or (&this_var. gt upper_bound)
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
				if cnt=. then cnt=0;
				run;
			proc sql;
				select cnt into: cnt separated by " "
				from a;
				quit;

			proc sql;
				select  grp_var into:grp_var separated by "!!"
				from a;
				quit;

			%do j=1 %to %sysfunc(countw(&cnt.));
				data n&j.;
					set new&i.;
				 	num_outlier=%scan(&cnt.,&j.," ");
					if grp_var="%scan(&grp_var.,&j.,'!!')";
				run;

				proc append base=all data=n&j. force;
				run;

			    proc datasets lib = work;
	           		delete n&j.;
	           		run;

			%end;
				data new&i.;
					set all;
					run;
				proc datasets lib =work;
					delete all;
					run;
/* end outlier calcultion */
			data new&i.;
				set new&i.;
				percentage_outlier = num_outlier/&frequency.;
				run;

			proc sort data=new&i.;
				 	by grp_var;
					run;
		%if &outlier_treatment.^=capping %then %do;
		data temp;
			merge temp(in=a) new&i(in=b keep=grp_var num_outlier percentage_outlier %if "&upper." ^= "" %then %do; upper_bound %end;
				%if "&lower." ^= "" %then %do; lower_bound %end;
				%if &outlier_treatment.=mean or &outlier_treatment.=mode &outlier_treatment.=median %then pre_&outlier_treatment.;
/*				%else %if &outlier_treatment.=capping %then p_%sysfunc(tranwrd(&outlier_treat_val.,.,_));*/);
			by grp_var;
			if a or b;
			run;	

		data temp;
			set temp;
			by grp_var;
	
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
					
					%else %if &outlier_treatment.=custom_type %then %do;
						%if &treatment_newVar.=new %then %do;
							&treatment_prefix._&this_var.=&outlier_treat_val.;
						%end;
						%else %if &treatment_newVar.=replace %then %do;
							&this_var.=&outlier_treat_val.;
						%end;
						%else %if &treatment_newVar.=rename %then %do;
							&this_var.=&outlier_treat_val.;
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

					%else %if &outlier_treatment.=delete %then %do;
						delete;
					%end;
				;
		drop %if "&upper." ^= "" %then %do; upper_bound %end; %if "&lower." ^= "" %then %do; lower_bound %end; 
			%if &outlier_treatment.=mean or &outlier_treatment.=mode &outlier_treatment.=median %then pre_&outlier_treatment.;;
			run;

%end;

 %if &outlier_treatment.=capping %then %do;	
 	data temp;
		merge temp(in=a) new&i(in=b keep=grp_var num_outlier percentage_outlier %if "&outlier_side." = "one" %then %do; upper_bound %end;
			%if "&outlier_side." = "two" %then %do; upper_bound lower_bound %end;);
		by grp_var;
		if a or b;
		run;

		data temp;
			set temp;
			 	if &this_var. < lower_bound then
						%if &treatment_newVar.=new %then %do;
							&treatment_prefix._&this_var.=lower_bound;
						%end;
						%else %if &treatment_newVar.=replace %then %do;
							&this_var.=lower_bound;
						%end;
				else if &this_var. > upper_bound then
						%if &treatment_newVar.=new %then %do;
							&treatment_prefix._&this_var.=upper_bound;
						%end;
						%else %if &treatment_newVar.=replace %then %do;
							&this_var.=upper_bound;
						%end;
				else
						%if &treatment_newVar.=new %then %do;
							&treatment_prefix._&this_var.=&this_var.;
						%end;
						%else %if &treatment_newVar.=replace %then %do;
							&this_var.=&this_var.;
						%end;
			run;
%end;

		%put &treatment_prefix._&this_var.; 
		%put &this_var.;

		proc univariate data=temp;
			var 
			%if &treatment_newVar = new %then %do;
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
			pctlpre=p_ pctlpts=0 to 0.8 by 0.2, 1 to 5 by 1,25,50,75,95 to 98 by 1,99 to 100 by 0.1;
			
			run;

		data new&i;
			merge new&i(drop=p_:) post_new&i.;
			by grp_var;
			attrib _all_ label=' ';
			perc_iqr="&iqr_value.";
			treatment="&outlier_treatment.";
			treat_value="&outlier_treat_val.";
			replace_type="&treatment_newVar.";
/*			num_outlier =&num_outlier.; */
/*			percentage_outlier = %sysevalf(&num_outlier./&frequency.);*/
			run;

		proc append base = outlier_output data =new&i force;
			run;

		proc sort data=temp;
			by primary_key_1644;
			run;

		data in.dataworking;
		set in.dataworking;
		primary_key_1644 = _n_;
		run;

		proc sort data=in.dataworking;
			by primary_key_1644;
			run;

		data in.dataworking;
			merge in.dataworking(in=a %if &treatment_newVar. = replace %then drop=&this_var.;) temp(in=b keep=primary_key_1644 %if &treatment_newVar. = new %then %do;
																																	&treatment_prefix._&this_var. 
																																%end;
																																%else %do; 
																																	&this_var.
																																%end;);
			by primary_key_1644;
			if a and b;
			run;
		proc sort data = temp;
			by grp_var;
			run;

	%end;
	proc export data = Outlier_output
    outfile = "&output_path./outlier_treatment.csv"
    dbms = csv replace;
    run;
%mend outlier_treatment4;
%outlier_treatment4;

data _null_;
    v1= "EDA - OUTLIER_TREATMENT_ACROSSGROUPBY_COMPLETED";
    file "&output_path/TREATMENT_COMPLETED.txt";
    put v1;
    run;



