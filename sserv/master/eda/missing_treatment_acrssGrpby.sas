/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/TREATMENT_COMPLETED.txt;
/* VERSION # 1.1.0 */

options mprint mlogic symbolgen mfile;

proc printto log="&output_path/params_multipleVar_detection_acrossGrp_Log.log";
run;
quit;
/*	*/
/*proc printto print="&output_path/params_multipleVar_detection_acrossGrp_Output.out";*/
/*	*/
dm log 'clear';
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
	primary_key_1644=_n_;
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
%macro indicator_missing;
%do p=1 %to %sysfunc(countw("&var_list."," "));
%let this_var=%scan("&var_list.",&p.," ");
data in.dataworking;
	set in.dataworking;
			%if "&treatment_newVar." = "new" %then %do;
				%if "&missing_spl." ^= "" %then %do;
					&treatment_prefix._MissingInd_%substr(&this_var.,1,15)=0;
					%do i=1 %to %sysfunc(countw("&missing_spl."," ")); 
					if &this_var.=%eval(%scan(&missing_spl.,&i.," ")) then &treatment_prefix._MissingInd_%substr(&this_var.,1,15) = 1;
					%end;
					if &this_var.= . then &treatment_prefix._MissingInd_%substr(&this_var.,1,15) = 1; 
				%end;
				%else %do;
				if &this_var.='.' then &treatment_prefix._MissingInd_%substr(&this_var.,1,15) =1; 
				else &treatment_prefix._MissingInd_%substr(&this_var.,1,15)=0;
				%end;
			%end;
			%else %if "&treatment_newVar." = "replace" %then %do;
				%if "&missing_spl." ^= "" %then %do;
				MissingInd_%substr(&this_var.,1,15)=0;
					%do i=1 %to %sysfunc(countw("&missing_spl."," ")); 
					if &this_var.=%eval(%scan(&missing_spl.,&i.," ")) then MissingInd_%substr(&this_var.,1,15) =1;
					%end;
				if &this_var.='.' then MissingInd_%substr(&this_var.,1,15) =1;  
				%end;
				%else %do;
				if &this_var.='.' then MissingInd_%substr(&this_var.,1,15) =1; 
				else MissingInd_%substr(&this_var.,1,15)=0;
				%end;
			%end;
run;
%end;
%mend;
%macro ind;
%if "&Create_ind_flag."^="false" %then %do;
%indicator_missing;
%end;
%mend;
%ind;

%macro missing_treatment;
	 
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
			%if &flag_missing. = true %then %do;
				nmiss=nmiss;
			%end;
			%if &treatment_newVar=custom_type %then %do;
			pctlpre=p_ pctlpts=&missing_treat_val.
		 	%end;
			;
			run;
		

		%if %length(&missing_spl.)^=0 %then %do;
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
				if mis=. then mis=0;
				run;

			%put missing &mis.;
			proc sql;
				select mis into: mis separated by " "
				from a;
				quit;

			proc sql;
				select  grp_var into:grp_var separated by "!!"
				from a;
				quit;

			%do j=1 %to %sysfunc(countw(&mis.));
				data n&j.;
					set new&i.;
				 	nmiss=nmiss+%scan(&mis.,&j.," ");
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
				proc datasets lib = work;
	           		delete all;
	           		run;

		%end;
		data new&i;
			length variable $32.;
			set new&i;
			variable = "&this_var.";
			attrib _all_ label=' ';
			%if &flag_missing. = true %then %do;
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
							&treatment_prefix._%substr(&this_var.,1,25)=pre_&missing_treatment.;
					%end;
					%else %if &treatment_newVar.=replace %then %do;
						&this_var.=pre_&missing_treatment.;
					%end;
					%else %if &treatment_newVar.=rename %then %do;
						&this_var.=pre_&missing_treatment.;
						rename &this_var.=&treatment_prefix._%substr(&this_var.,1,25);
					%end;
				end;	
				else do;
					%if &treatment_newVar.=new %then %do;
							&treatment_prefix._%substr(&this_var.,1,25)=&this_var.;
					%end;
					%else %if &treatment_newVar.=rename %then %do;
						rename &this_var.=&treatment_prefix._%substr(&this_var.,1,25);
					%end;
				end;
			%end;

			%else %if &missing_treatment.=capping %then %do;
				if &this_var. = . %if "&missing_spl." ^= "" %then %do; or &this_var. in (&missing_spl.) %end; then do;
					%if &treatment_newVar.=new %then %do;
						&treatment_prefix._%substr(&this_var.,1,25)=p_&missing_treat_val.;
					%end;
					%else %if &treatment_newVar.=replace %then %do;
						&this_var.=p_&missing_treat_val.;
					%end;
					%else %if &treatment_newVar.=rename %then %do;
						&this_var.=p_&missing_treat_val.;
						rename &this_var.=&treatment_prefix._%substr(&this_var.,1,25);
					%end;	
				end;
				else do;
					%if &treatment_newVar.=new %then %do;
						&treatment_prefix._%substr(&this_var.,1,25)=&this_var.;
					%end;
					%else %if &treatment_newVar.=rename %then %do;
						rename &this_var.=&treatment_prefix._%substr(&this_var.,1,25);
					%end;
				end;	
			%end;
			
			%else %if &missing_treatment.=custom_type %then %do;
				if &this_var. = . %if "&missing_spl." ^= "" %then %do; or &this_var. in (&missing_spl.) %end; then do;
					%if &treatment_newVar.=new %then %do;
						&treatment_prefix._%substr(&this_var.,1,25)=&missing_treat_val.;
					%end;
					%else %if &treatment_newVar.=replace %then %do;
						&this_var.=&missing_treat_val.;
					%end;
					%else %if &treatment_newVar.=rename %then %do;
						&this_var.=&missing_treat_val.;
						rename &this_var.=&treatment_prefix._%substr(&this_var.,1,25);
					%end;	
				end;
				else do;
					%if &treatment_newVar.=new %then %do;
						&treatment_prefix._%substr(&this_var.,1,25)=&this_var.;
					%end;
					%else %if &treatment_newVar.=rename %then %do;
						rename &this_var.=&treatment_prefix._%substr(&this_var.,1,25);
					%end;
				end;	
			%end;

			%else %if &missing_treatment.=delete %then %do;
				if &this_var. = . %if "&missing_spl." ^= "" %then %do; or &this_var. in (&missing_spl.) %end; then delete;
			%end;

			%else %if &missing_treatment. = replace_with_existing %then %do;
       		 	%let misTreatVar= %scan(&var_list., &i.);
             	%let misReplaceVar= %scan(&missing_replacement_var., &i.);
       
        	 	%if "&treatment_newVar." = "replace" or "&treatment_newVar." = "rename" %then %do;
          				if &misTreatVar.=. then do;
							&misTreatVar.=&misReplaceVar.;
						end;
					%if "&missing_spl." ^= "" %then %do;
						if &misTreatVar. in (&missing_spl.) then &this_var.= &misReplaceVar.;
					%end;
        		%end;
              	%else %if "&treatment_newVar." = "new" %then %do;
				    if &misTreatVar.=.  then  &treatment_prefix._%substr(&this_var.,1,25)= &misReplaceVar.;
					else &treatment_prefix._%substr(&this_var.,1,25)=&misTreatVar.;
					%if "&missing_spl." ^= "" %then %do;
						if &misTreatVar. in (&missing_spl.) then &treatment_prefix._%substr(&this_var.,1,25)= &misReplaceVar.;
/*						else &treatment_prefix._%substr(&this_var.,1,25)=&misTreatVar.;*/
					%end;
              	%end;
       
      		%end;
			
			run;
		
		proc univariate data=temp;
			var 
			%if &treatment_newVar. = new %then %do;
				&treatment_prefix._%substr(&this_var.,1,25); 
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
																																	&treatment_prefix._%substr(&this_var.,1,25) 
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
	proc export data = Missing_output
    outfile = "&output_path./missing_treatment.csv"
    dbms = csv replace;
    run;

%mend missing_treatment;
%missing_treatment;

data _null_;
    v1= "EDA - MISSING_TREATMENT_ACROSS_GROUPBY_COMPLETED";
    file "&output_path/TREATMENT_COMPLETED.txt";
    put v1;
    run;

	/*ENDSAS;*/


