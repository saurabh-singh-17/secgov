/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/OUTLIER_TREATMENT_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;

/*%sysexec del "&output_path/OUTLIER_TREATMENT_COMPLETED.txt";*/

proc printto log="&output_path/OutlierTreatment_Log.log";
run;
quit;
/*proc printto print="&output_path/OutlierTreatment_Output.out";*/

libname in "&input_path.";
libname out "&output_path.";


data out.dataworking;
	set in.dataworking;
	run;

data temp_inter;
	retain primary_key_1644 &groupVar_list.;
	set out.dataworking (keep = primary_key_1644 &groupVar_list. &var_list ); 
	run;

proc sort data = temp_inter out = temp_inter;
	by  &groupVar_list.;
	run;


%MACRO grpBy_outlier_treatment;

	%if "&flag_replace_outliers." = "false" or "&flag_replace_outliers." = "rename" %then %do;
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

%let increment = 5;

/*for two-sided treatment*/
%if "&flag_two_sided." = "true" %then %do;

	%LET i =1 ;
		%DO %UNTIL(NOT %LENGTH(%SCAN(&var_list,&i))) ;
			
		/*define macro for var_name*/
			data _null_;
				set temp_inter;
				call symputx("var_name", "%SCAN(&var_list,&i)");
				run;

	/*for iqr*/
		%if "&flag_iqr." = "true" %then %do;
			%let lower = %sysevalf(25);
		    %let upper = %sysevalf(75);

			/*univariate treatment*/
				proc univariate data = temp_inter noprint;
					class  &groupVar_list.;
					var &var_name.;
					output out=  out_uni&i.
						mean = m_&var_name.
						median = n_&var_name.
						mode = mode 
						qrange = iqr 
						pctlpts= &lower. &upper.
						pctlpre=p_ ;
						run;
			
			/*determine outlier boundary*/
				data out_uni&i.;
					retain &groupVar_list. attributes l_&var_name. u_&var_name.;
					set out_uni&i.;
					attrib _all_ label=" ";

					format attributes $50.;
						attributes = "&var_name.";
						u_&var_name. = compress(p_&upper. + (&multiplier. * iqr));
						l_&var_name. = compress(p_&lower. - (&multiplier. * iqr));
						run;

		%end;

	/*for percentile*/
		%if "&flag_percentile." = "true" %then %do;
			%let lower = %sysevalf((100 - &percentile.)/2);
	      	%let upper = %sysevalf(100 - &lower.);

			/*univariate treatment*/
				proc univariate data = temp_inter noprint;
					class  &groupVar_list.;
					var &var_name.;
					output out=  out_uni&i.
						mean = m_&var_name.
						median = n_&var_name. 
						pctlpts= &lower. &upper.
						pctlpre=p_ ;
						run;

			/*determine outlier boundary*/
				data _null_;
						call symputx("odd" , modz(&percentile., 2));
						run;

				%if "&odd." = "1" %then %do;
				data _null_;
						call symputx("low", compress(tranwrd("&lower." ,"." ,"_" )));
						call symputx("upp", compress(tranwrd("&upper." ,"." ,"_" )));
						run;
				%end;

				data out_uni&i.;
					retain &groupVar_list. attributes l_&var_name. u_&var_name.;
					set out_uni&i.;
					attrib _all_ label=" ";

					format attributes $50.;
						attributes = "&var_name.";
			
						%if "&odd." = "0" %then %do;
						l_&var_name. = compress(p_&lower.);
						u_&var_name. = compress(p_&upper.);
						%end;
						%else %do;
						l_&var_name. = compress(p_&low.);
						u_&var_name. = compress(p_&upp.);
						%end;
						run;

		%end;

	/*merging all univariate outputs per variable*/
		%if "&i." = "1" %then %do;
			data out_uni;
				set out_uni&i. (keep = &groupVar_list. u_&var_name. l_&var_name. m_&var_name. n_&var_name.);
				run;
		%end;
		%else %do;
			data out_uni;
				merge out_uni(in=a)  out_uni&i. (in=b keep = &groupVar_list. u_&var_name. l_&var_name. m_&var_name. n_&var_name.);
				by &groupVar_list.;
				if a or b;
				run;
		%end;

		%LET i=%EVAL(&i+1);	
	%end;

/*merging univariate output with working dataset*/
	data temp_inter;
		merge temp_inter (in=a)  out_uni (in=b);
		by &groupVar_list.;
		if a;
		run;

/*outlier treatment!*/
	data temp_inter;
		set temp_inter;

		primary_key_1644 = _n_;
		%LET j =1 ;
			%DO %UNTIL(NOT %LENGTH(%SCAN(&var_list,&j)));

				%if "&replacement_type." ^= "delete" %then %do;
					if %SCAN(&var_list,&j) < l_%SCAN(&var_list,&j) or %SCAN(&var_list,&j) > u_%SCAN(&var_list,&j) then do;
						%if "&flag_replace_outliers." = "true" or "&flag_replace_outliers." = "rename" %then %do;
							%if "&replacement_type." = "mean" %then %do; %SCAN(&var_list,&j) = m_%SCAN(&var_list,&j);%end;
							%if "&replacement_type." = "median" %then %do; %SCAN(&var_list,&j) = n_%SCAN(&var_list,&j);%end;
							%if "&replacement_type." = "custom_type" %then %do; %SCAN(&var_list,&j) = %sysevalf(&custom_value.);%end;
							%if "&replacement_type." = "capping" %then %do; 
								if %SCAN(&var_list,&j) < l_%SCAN(&var_list,&j) then %SCAN(&var_list,&j) = l_%SCAN(&var_list,&j);
								else if %SCAN(&var_list,&j) > u_%SCAN(&var_list,&j) then %SCAN(&var_list,&j) = u_%SCAN(&var_list,&j);
							%end;
						%end;
						%if "&flag_replace_outliers." = "false" %then %do;
							%if "&replacement_type." = "mean" %then %do; &prefix._%SCAN(&var_list,&j) = m_%SCAN(&var_list,&j);%end;
							%if "&replacement_type." = "median" %then %do; &prefix._%SCAN(&var_list,&j) = n_%SCAN(&var_list,&j);%end;
							%if "&replacement_type." = "custom_type" %then %do; &prefix._%SCAN(&var_list,&j) = %sysevalf(&custom_value.);%end;
							%if "&replacement_type." = "capping" %then %do; 
								if %SCAN(&var_list,&j) < l_%SCAN(&var_list,&j) then &prefix._%SCAN(&var_list,&j) = l_%SCAN(&var_list,&j);
								else if %SCAN(&var_list,&j) > u_%SCAN(&var_list,&j) then &prefix._%SCAN(&var_list,&j) = u_%SCAN(&var_list,&j);
							%end;
						%end;
					end;
					
					else do;
						%if "&flag_replace_outliers." = "false" %then %do;
							&prefix._%SCAN(&var_list,&j) = %SCAN(&var_list,&j);
						%end;
					end;
				%end;

				%if "&replacement_type." = "delete" %then %do;
					if %SCAN(&var_list,&j) < l_%SCAN(&var_list,&j) or %SCAN(&var_list,&j) > u_%SCAN(&var_list,&j) then delete;
				%end;

				drop u_%SCAN(&var_list,&j) l_%SCAN(&var_list,&j) m_%SCAN(&var_list,&j) n_%SCAN(&var_list,&j);
				
			%LET j=%EVAL(&j+1);	
		%end;
	run;

%end;


/*for one-sided treatment*/
%if "&flag_one_sided." = "true" %then %do;

	%LET i =1 ;
		%DO %UNTIL(NOT %LENGTH(%SCAN(&var_list,&i))) ;
			
		/*define macro for var_name*/
			data _null_;
				set temp_inter;
				call symputx("var_name", "%SCAN(&var_list,&i)");
				run;

	/*for iqr*/
		%if "&flag_iqr." = "true" %then %do;
			%let upper = %sysevalf(75);

			/*univariate treatment*/
				proc univariate data = temp_inter noprint;
					class  &groupVar_list.;
					var &var_name.;
					output out=  out_uni&i.
						mean = m_&var_name.
						median = n_&var_name.
						mode = mode 
						qrange = iqr 
						pctlpts= &upper.
						pctlpre=p_ ;
						run;
			
			/*determine outlier boundary*/
				data out_uni&i.;
					retain &groupVar_list. attributes u_&var_name.;
					set out_uni&i.;
					attrib _all_ label=" ";

					format attributes $50.;
						attributes = "&var_name.";
						u_&var_name. = compress(p_&upper. + (&multiplier. * iqr));
						run;

		%end;

	/*for percentile*/
		%if "&flag_percentile." = "true" %then %do;
			%let upper = %sysevalf(&percentile.);

			/*univariate treatment*/
				proc univariate data = temp_inter noprint;
					class  &groupVar_list.;
					var &var_name.;
					output out=  out_uni&i.
						mean = m_&var_name.
						median = n_&var_name. 
						pctlpts= &upper.
						pctlpre=p_ ;
						run;

			/*determine outlier boundary*/
				data _null_;
						call symputx("odd" , modz(&percentile., 2));
						run;

				%if "&odd." = "1" %then %do;
				data _null_;
						call symputx("upp", compress(tranwrd("&upper." ,"." ,"_" )));
						run;
				%end;

				data out_uni&i.;
					retain &groupVar_list. attributes u_&var_name.;
					set out_uni&i.;
					attrib _all_ label=" ";

					format attributes $50.;
						attributes = "&var_name.";
			
						%if "&odd." = "0" %then %do;
						u_&var_name. = compress(p_&upper.);
						%end;
						%else %do;
						u_&var_name. = compress(p_&upp.);
						%end;
						run;

		%end;

	/*merging all univariate outputs per variable*/
		%if "&i." = "1" %then %do;
			data out_uni;
				set out_uni&i. (keep = &groupVar_list. u_&var_name. m_&var_name. n_&var_name.);
				run;
		%end;
		%else %do;
			data out_uni;
				merge out_uni(in=a)  out_uni&i. (in=b keep = &groupVar_list. u_&var_name. m_&var_name. n_&var_name.);
				by &groupVar_list.;
				if a or b;
				run;
		%end;

		%LET i=%EVAL(&i+1);	
	%end;

/*merging univariate output with working dataset*/
	data temp_inter;
		merge temp_inter (in=a)  out_uni (in=b);
		by &groupVar_list.;
		if a;
		run;

/*outlier treatment!*/
	data temp_inter;
		set temp_inter;

		%LET j =1 ;
			%DO %UNTIL(NOT %LENGTH(%SCAN(&var_list,&j)));

				%if "&replacement_type." ^= "delete" %then %do;
					if %SCAN(&var_list,&j) > u_%SCAN(&var_list,&j) then do;
						%if "&flag_replace_outliers." = "true" or "&flag_replace_outliers." = "rename" %then %do;
							%if "&replacement_type." = "mean" %then %do; %SCAN(&var_list,&j) = m_%SCAN(&var_list,&j);%end;
							%if "&replacement_type." = "median" %then %do; %SCAN(&var_list,&j) = n_%SCAN(&var_list,&j);%end;
							%if "&replacement_type." = "custom_type" %then %do; %SCAN(&var_list,&j) = %sysevalf(&custom_value.);%end;
							%if "&replacement_type." = "capping" %then %do; %SCAN(&var_list,&j) = u_%SCAN(&var_list,&j);%end;
						%end;
						%if "&flag_replace_outliers." = "false" %then %do;
							%if "&replacement_type." = "mean" %then %do; &prefix._%SCAN(&var_list,&j) = m_%SCAN(&var_list,&j);%end;
							%if "&replacement_type." = "median" %then %do; &prefix._%SCAN(&var_list,&j) = n_%SCAN(&var_list,&j);%end;
							%if "&replacement_type." = "custom_type" %then %do; &prefix._%SCAN(&var_list,&j) = %sysevalf(&custom_value.);%end;
							%if "&replacement_type." = "capping" %then %do; &prefix._%SCAN(&var_list,&j) = u_%SCAN(&var_list,&j);
							%end;
						%end;
					end;
					
					else do;
						%if "&flag_replace_outliers." = "false" %then %do;
							&prefix._%SCAN(&var_list,&j) = %SCAN(&var_list,&j);
						%end;
					end;
				%end;

				%if "&replacement_type." = "delete" %then %do;
					if %SCAN(&var_list,&j) > u_%SCAN(&var_list,&j) then delete;
				%end;

				drop u_%SCAN(&var_list,&j) m_%SCAN(&var_list,&j) n_%SCAN(&var_list,&j);

			%LET j=%EVAL(&j+1);	
		%end;
	run;
%end;	
	
	/*sorting by primary key*/
	proc sort data = temp_inter out = temp_inter;
		by primary_key_1644;
		run;


	/*create output dataset*/
	data in.dataworking;
		merge  temp_inter(in=a) out.dataworking(in=b drop = &var_list. &groupVar_list.);
		by primary_key_1644;
		if a and b;
		run;


	%if "&flag_replace_outliers." = "rename" %then %do;
		data in.dataworking;
			set in.dataworking;

			%let k = 1;
				%do %until (not %length(%scan(&var_list, &k)));
					rename %scan(&var_list, &k) = &prefix._%scan(&mod_list, &k);
					%let k=%eval(&k+1);	
				%end;
			run;
	%end;


			
%MEND grpBy_outlier_treatment;
%grpBy_outlier_treatment;


	/*deleting datasets from output library*/
	proc datasets library = out;
		delete dataworking;
		run;


/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "EDA - OUTLIER_TREATMENT_COMPLETED";
	file "&output_path/OUTLIER_TREATMENT_COMPLETED.txt";
	put v1;
	run;


ENDSAS;




