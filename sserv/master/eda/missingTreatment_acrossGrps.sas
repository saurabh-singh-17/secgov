/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/MISSING_TREATMENT_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;

FILENAME MyFile "&output_path/MISSING_TREATMENT_COMPLETED.txt" ;

  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;

proc printto log="&output_path/MissingTreatment_Log.log";
run;
quit;
/*proc printto print="&output_path/MissingTreatment_Output.out";*/

libname in "&input_path.";
libname out "&output_path.";


%MACRO missing_treatment_grpBy;
%if "&replacement_type." ^= "delete" %then %do;

	%if "flag_replace_missing." = "false" or "flag_replace_missing." = "rename" %then %do;
		%let i=1;
		%do %until (not %length(%scan(&var_list,&i)));

			data _null_;
				set in.dataworking;
				%if "&i." = "1" %then %do;
					%if %length(%scan(&var_list,&i)) < 27 %then %do;
						call symputx("mod_list", "%scan(&var_list,&i)");
					%end;
					%if %length(%scan(&var_list,&i)) >= 27 %then %do;
						call symputx("mod_list", substr("%scan(&var_list,&i)",1,27));
					%end;
				%end;
				%else %do;
					%if %length(%scan(&var_list,&i)) < 27 %then %do;
						call symput("mod_list", catx(" ", "&mod_list.", "%scan(&var_list,&i)"));
					%end;
					%if %length(%scan(&var_list,&i)) >= 27 %then %do;
						call symput("mod_list", catx(" ", "&mod_list.", substr("%scan(&var_list,&i)",1,27)));
					%end;
				%end;
				run;

			%let i=%eval(&i+1);	
		%end;
	%end;		


	data out.dataworking;
		set in.dataworking;
		run;

	data out.temp;
		retain primary_key_1644 &grpvar_list.;
		set out.dataworking(keep = primary_key_1644 &grpvar_list. &var_list.);
		run;

	proc sort data = out.temp out = out.temp;
		by &grpvar_list.;
		run;


	data _null_;
		set out.temp;
		call symputx("missing_values", compress(tranwrd("&missing_list." ," " ," ," )));
		call symputx("vars", compress(tranwrd("&var_list." ," " ," ," )));
		call symputx("grp_var", compress(tranwrd("&grpvar_list." ," " ," ," )));
		run;


	%let i =1 ;
	%do %until(NOT %length(%scan(&var_list,&i)));

		data _null_;
			set out.temp;
			call symputx("var_name", "%SCAN(&var_list,&i)");
			run;


		proc univariate data = out.temp noprint;
				class  &grpvar_list.;
				var &var_name.;
				output out = univ&i.
					mean = mean&i.
					median = median&i.
					mode = mode&i.
					pctlpts= 0 5 25 75 95 100
					pctlpre=p_ 
					;
					run;


		%if "&replacement_type." = "mean" or "&replacement_type." = "median" or "&replacement_type." = "mode" %then %do;
			data univ&i.;
				set univ&i. (keep = &grpvar_list. &replacement_type.&i.);
				attrib _all_ label=" ";
				run;
		%end;

		%if "&replacement_type." = "custom_type" %then %do;
			data univ&i.;
				set univ&i. (keep = &grpvar_list.);
				attrib _all_ label=" ";

				custom_type&i. = %sysevalf(&custom_value.);
				run;
		%end; 
		
		data _null_;
			set univ&i.;

			%if "&replacement_type." = "winsorized_mean" or "&replacement_type." = "trim_mean" %then %do;
					call symputx("lb", "p_5");
					call symputx("ub", "p_95");
			%end;
			%else %if "&replacement_type." = "mid_mean" %then %do;
					call symputx("lb", "p_25");
					call symputx("ub", "p_75");
			%end;
			run;

		%if "&replacement_type" = "winsorized_mean" %then %do;

			data univ&i.;
				merge out.temp(in=a) univ&i.(in=b keep = &grpvar_list. &lb. &ub.);
				by &grpvar_list.;
				if a;
				run;

			data win_subset;
				set univ&i.;
				if &var_name. > &ub. then &var_name. = &ub.;
				else if &var_name. < &lb. then &var_name. = &lb.;
				%if "&missing_list." ^= "" %then %do; 
					where &var_name. not in (&missing_list.);
				%end;
				run;

			proc sql;
				create table univ as
				select &grp_var., 
						avg(&var_name) as &replacement_type.&i.
				from win_subset
				group by &grp_var.
				;
				quit;

			proc sort data = univ out = univ&i. nodupkey;
				by &grpvar_list.;
				run;			

		%end;



		
		%if "&replacement_type." = "mid_mean" or "&replacement_type." = "trim_mean" %then %do;

			data univ&i.;
				merge out.temp(in=a) univ&i.(in=b keep = &grpvar_list. &lb. &ub.);
				by &grpvar_list.;
				if a;
				run;
				
				
			proc sql;
				create table univ as 
				select &grp_var., avg(&var_name.) as &replacement_type.&i.
				from univ&i. 
				%if "&missing_list." ^= "" %then %do; 
					where &lb. < &var_name. < &ub. and &var_name. not in (&missing_list.)
				%end;
				group by &grp_var.;
				quit;

			proc sort data = univ out = univ&i. nodupkey;
				by &grpvar_list.;
				run;
		%end;
		

		%if "&i." = "1" %then %do;
			data uni;
				set univ&i.;
				run;
		%end;
		%else %do;
			data uni;
				merge uni(in=a) univ&i.(in=b);
				by &grpvar_list.;
				if a;
				run;
		%end;

		%let i=%eval(&i+1);	
	%end;

	data out.temp;
		merge out.temp(in=a) uni(in=b);
		by &grpvar_list.;
		if a;
		run;


	data out.temp;
		set out.temp;

		%let j =1 ;
		%do %until(NOT %length(%scan(&var_list,&j))) ;
			%if "&flag_replace_missing." = "true" or "&flag_replace_missing." = "rename" %then %do;
				%if "&missing_list." ^= "" %then %do; 
					if %scan(&var_list,&j) = . or %scan(&var_list,&j) in (&missing_list.) then %scan(&var_list,&j) = &replacement_type.&j.;
				%end;
				%if "&missing_list." = "" %then %do; 
					if %scan(&var_list,&j) = . then %scan(&var_list,&j) = &replacement_type.&j.;
				%end;
			%end;
			%if "&flag_replace_missing." = "false" %then %do;
				%if "&missing_list." ^= "" %then %do; 
					if %scan(&var_list,&j) = . or %scan(&var_list,&j) in (&missing_list.) then &prefix._%scan(&mod_list,&j) = &replacement_type.&j.;
						else &prefix._%scan(&mod_list,&j) = %scan(&var_list,&j);
				%end;
				%if "&missing_list." = "" %then %do; 
					if %scan(&var_list,&j) = . then &prefix._%scan(&mod_list,&j) = &replacement_type.&j.;
						else &prefix._%scan(&mod_list,&j) = %scan(&var_list,&j);
				%end;
			%end;

			drop &replacement_type.&j.;
			%let j=%eval(&j+1);	
		%end;
		run;

	/*sorting by primary key*/
	proc sort data = out.temp out = out.temp;
		by primary_key_1644;
		run;


/*create output dataset*/
	data in.dataworking;
		merge  out.temp(in=a) out.dataworking(in=b drop = &var_list. &grpvar_list.);
		by primary_key_1644;
		if a or b;
		run;


/*deleting datasets from output library*/
	proc datasets library = out;
		delete dataworking temp;
		run;



	%if "&flag_replace_missing." = "rename" %then %do;
		data in.dataworking;
			set in.dataworking;

			%let i = 1;
				%do %until (not %length(%scan(&var_list, &i)));
					rename %scan(&var_list, &i) = &prefix._%scan(&mod_list, &i);
					%let i=%eval(&i+1);	
				%end;
			run;
	%end;
%end;

%if "&replacement_type" = "delete" %then %do;
	data in.dataworking;
		set in.dataworking;

		%LET i =1;
		%DO %UNTIL(NOT %LENGTH(%SCAN(&var_list,&i)));
		
		%if "&missing_list." ^= "" %then %do;
			if %SCAN(&var_list,&i) in (&missing_list.) or %SCAN(&var_list,&i) = . then delete;
		%end;
		%if "&missing_list." = "" %then %do;
			if %SCAN(&var_list,&i) = . then delete;
		%end;
			
		%let i = (&i.+1);
		%end;
%end;


%MEND missing_treatment_grpBy;
%missing_treatment_grpBy;





/* flex uses this file to test if the code has finished running */
	data _null_;
		v1= "EDA - MISSING_TREATMENT_COMPLETED";
		file "&output_path/MISSING_TREATMENT_COMPLETED.txt";
		put v1;
		run;


ENDSAS;





