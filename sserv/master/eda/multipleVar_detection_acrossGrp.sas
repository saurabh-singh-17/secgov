/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/MULTIVAR_DETECTION_COMPLETED.txt;
/* VERSION # 1.1.0 */

dm log 'clear';
options mprint mlogic symbolgen mfile;

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


%macro multiVar_acrossGrp;
 
	%do i=1 %to %sysfunc(countw(&var_list.));
		%let vars = %scan(&var_list,&i);
		proc univariate data=temp ;
			var &vars.;
			by grp_var;
			output out=new&i
			mean=mean
			median=median
			mode=mode
			%if &flag_missing. = true %then %do;
				nmiss=nmiss
			%end;
			range=range
			%if &flag_outlier. = true %then %do;
				qrange=iqr
			%end;
			pctlpre=p_ pctlpts=0 to 0.8 by 0.2, 1 to 5 by 1,25,50,75,95 to 98 by 1,99 to 100 by 0.1
			%if &flag_outlier. = true %then %do;
				%if "&perc_lower." ^= "" %then %do; ,&perc_lower. %end;
				%if "&perc_upper." ^= "" %then %do; ,&perc_upper. %end;
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
			variable = "%scan(&var_list,&i)";
			attrib _all_ label=' ';
			%if &flag_missing. = true %then %do;
/*				%if %length(&missing_spl.)^=0 %then %do;*/
/*					nmiss=nmiss+&mis;*/
/*				%end;*/
				missing_percetange=nmiss/&frequency.;
			%end;
			run;

			%let upper=;
			%let lower=;

		%if &flag_outlier. = true %then %do;
			
			data new&i;
				set new&i;
				%if &outlier_type. = iqr %then %do;
					%let upper = true;
					%if &outlier_side. = two %then %do;
						%let lower = true;
						upper_bound=p_75+&iqr_value.*iqr;
						lower_bound=p_25-&iqr_value.*iqr;
					%end;
					%else %if &outlier_type. = perc %then %do;
						upper_bound=p_75+&iqr_value.*iqr;
					%end;
					%else %if &outlier_side. = one %then %do;
						upper_bound=p_75+&iqr_value.*iqr;
					%end;
				%end;
				%else %if &outlier_type. = perc %then %do;
					%if "&perc_upper." ^= "" %then %do;
						%let upper = true;
						upper_bound=p_%sysfunc(tranwrd(&perc_upper.,.,_));
					%end;
					%if "&perc_upper." ^= "" %then %do;
						%let lower = true;
						lower_bound=p_%sysfunc(tranwrd(&perc_lower.,.,_));
					%end;
				%end;

				run;
			

		data cnt&i;
			merge temp(keep=%scan(&var_list,&i) grp_var) new&i(keep=grp_var %if "&upper." ^= "" %then %do; upper_bound %end;
				%if "&lower." ^= "" %then %do; lower_bound %end;);
			by grp_var;
			run;
		
		proc sql;
			create table cnt&i as 
			select grp_var,count(%scan(&var_list,&i)) as outlier_count, calculated outlier_count/&frequency. as outlier_percentage
			from cnt&i
			%if "&upper." ^= "" or "&lower." ^="" %then
			where ;
			%if "&upper." ^= "" and "&lower." ^= "" %then %do;
				%scan(&var_list,&i)>upper_bound or %scan(&var_list,&i)<lower_bound
			%end;
			%if "&upper." ^= "" and "&lower." = "" %then %do;
				%scan(&var_list,&i)>upper_bound
			%end;
			%if "&upper." = "" and "&lower." ^= "" %then %do;
				%scan(&var_list,&i)<lower_bound
			%end;
			group by grp_var;
			quit;		
		
		data new&i;
			merge new&i cnt&i;
			by grp_var;
			run;	

		
%end;
		proc append base = output data =new&i force;
			run;

%end;
		data output;
			set output;
			if outlier_count=. then outlier_count=0;
			if outlier_percentage=. then outlier_percentage=0;
			run;

		data output(rename=(nmiss=missing_count missing_percetange=missing_perc 
					outlier_percentage=outlier_perc upper_bound=upper_cutoff %if &outlier_side.=two %then lower_bound=lower_cutoff; ));
			set output;
			grp_var = compress(grp_var);
			run;

		proc export data = output
			outfile = "&output_path./multiVar_detection.csv"
			dbms = CSV replace;
			run;

%mend multiVar_acrossGrp;
%multiVar_acrossGrp;

data _null_;
	v1= "EDA - MULTIVAR_DETECTION_COMPLETED";
	file "&output_path/MULTIVAR_DETECTION_COMPLETED.txt";
	put v1;
	run;

/*endsas;*/


