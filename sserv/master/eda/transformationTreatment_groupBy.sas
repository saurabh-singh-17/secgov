/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/TRANSFORMATION_TREATMENT_GROUPBY_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;

proc printto log="&output_path./Transformation_Treatment_GroupBy_Log.log";
run;
quit;
/*proc printto print="&output_path./Transformation_Treatment_GroupBy_Output.out";*/

libname in "&input_path";
libname out "&output_path";


%MACRO trans;
/*preparing modified var_list for renaming or creating new variable*/
%if "&flag_replace." = "false" or "&flag_replace." = "rename" %then %do;
	%let k=1;
	%do %until (not %length(%scan(&var_list,&k)));

		data _null_;
			set in.dataworking;
			%if "&k." = "1" %then %do;
				%if %length(%scan(&var_list,&k)) < 27 %then %do;
					call symputx("mod_list", "%scan(&var_list,&k)");
				%end;
				%if %length(%scan(&var_list,&k)) >= 27 %then %do;
					call symputx("mod_list", substr("%scan(&var_list,&k)",1,27));
				%end;
			%end;
			%else %do;
				%if %length(%scan(&var_list,&k)) < 27 %then %do;
					call symput("mod_list", catx(" ", "&mod_list.", "%scan(&var_list,&k)"));
				%end;
				%if %length(%scan(&var_list,&k)) >= 27 %then %do;
					call symput("mod_list", catx(" ", "&mod_list.", substr("%scan(&var_list,&k)",1,27)));
				%end;
			%end;
			run;
		%put &mod_list;

		%let k=%eval(&k+1);	
	%end;
%end;

/*macro var to concatenate the grp_vars*/
data _null_;
	call symput("catgrp", tranwrd("&grp_vars.", " ", ", '_',"));
	run;
%put &catgrp;

/*transform*/
data in.dataworking(drop=grp_var);
	length grp_var $32.;
	set in.dataworking;
	grp_var = cat(&catgrp.);

	%let j = 1;
	%do %until(not %length(%scan(%bquote(&grp_levels), &j, "!!")));
		if strip(grp_var) = "%scan(%bquote(&grp_levels), &j, "!!")" then do;
			
		%LET i =1;
		%DO %UNTIL(NOT %LENGTH(%SCAN(&var_list,&i)));
	
			%if "&flag_replace." = "true" or "&flag_replace." = "rename" %then %do;
				%if "%scan(%bquote(&transformation), &j, "!!")" = "log" %then %do;
					%SCAN(&var_list,&i) = log(%SCAN(&var_list,&i));
				%end;

				%if "%scan(%bquote(&transformation), &j, "!!")" = "e_power" %then %do;
					%SCAN(&var_list,&i) = exp(%SCAN(&var_list,&i));
				%end;

				%if "%scan(%bquote(&transformation), &j, "!!")" = "square_root" %then %do;
					%SCAN(&var_list,&i) = sqrt(%SCAN(&var_list,&i));
				%end;

				%if "%scan(%bquote(&transformation), &j, "!!")" = "cube_root" %then %do;
					%SCAN(&var_list,&i) = %SCAN(&var_list,&i)**(1/3);
				%end;

				%if "%scan(%bquote(&transformation), &j, "!!")" = "square" %then %do;
					%SCAN(&var_list,&i) = %SCAN(&var_list,&i)**2;
				%end;

				%if "%scan(%bquote(&transformation), &j, "!!")" = "cube" %then %do;
					%SCAN(&var_list,&i) = %SCAN(&var_list,&i)**3;
				%end;

				%if "%scan(%bquote(&transformation), &j, "!!")" = "reciprocal" %then %do;
					%SCAN(&var_list,&i) = 1/%SCAN(&var_list,&i);
				%end;

				%if "%scan(%bquote(&transformation), &j, "!!")" = "reciprocal_sqrt" %then %do;
					%SCAN(&var_list,&i) = 1/sqrt(%SCAN(&var_list,&i));
				%end;

				%if "%scan(%bquote(&transformation), &j, "!!")" = "reciprocal_cube" %then %do;
					%SCAN(&var_list,&i) = 1/(%SCAN(&var_list,&i)**3);
				%end;

				%if "%scan(%bquote(&transformation), &j, "!!")" = "reciprocal_square" %then %do;
					%SCAN(&var_list,&i) = 1/(%SCAN(&var_list,&i)**2);
				%end;
				%if "%scan(%bquote(&transformation), &j, "!!")" = "multiplier" %then %do;
					%SCAN(&var_list,&i) = %SCAN(&var_list,&i)*%sysevalf(%scan(%bquote(&multiplier), &j, "!!"));
				%end;
				%if "%scan(%bquote(&transformation), &j, "!!")" = "default" %then %do;
					%SCAN(&var_list,&i) = %SCAN(&var_list,&i);
				%end;
			%end;

			%if "&flag_replace." = "false" %then %do;
				%if "%scan(%bquote(&transformation), &j, "!!")" = "log" %then %do;
					&prefix._%SCAN(&mod_list,&i) = log(%SCAN(&var_list,&i));
				%end;

				%if "%scan(%bquote(&transformation), &j, "!!")" = "e_power" %then %do;
					&prefix._%SCAN(&mod_list,&i) = exp(%SCAN(&var_list,&i));
				%end;

				%if "%scan(%bquote(&transformation), &j, "!!")" = "square_root" %then %do;
					&prefix._%SCAN(&mod_list,&i) = sqrt(%SCAN(&var_list,&i));
				%end;

				%if "%scan(%bquote(&transformation), &j, "!!")" = "cube_root" %then %do;
					&prefix._%SCAN(&mod_list,&i) = %SCAN(&var_list,&i)**(1/3);
				%end;

				%if "%scan(%bquote(&transformation), &j, "!!")" = "square" %then %do;
					&prefix._%SCAN(&mod_list,&i) = %SCAN(&var_list,&i)**2;
				%end;

				%if "%scan(%bquote(&transformation), &j, "!!")" = "cube" %then %do;
					&prefix._%SCAN(&mod_list,&i) = %SCAN(&var_list,&i)**3;
				%end;

				%if "%scan(%bquote(&transformation), &j, "!!")" = "reciprocal" %then %do;
					&prefix._%SCAN(&mod_list,&i) = 1/%SCAN(&var_list,&i);
				%end;

				%if "%scan(%bquote(&transformation), &j, "!!")" = "reciprocal_sqrt" %then %do;
					&prefix._%SCAN(&mod_list,&i) = 1/sqrt(%SCAN(&var_list,&i));
				%end;

				%if "%scan(%bquote(&transformation), &j, "!!")" = "reciprocal_cube" %then %do;
					&prefix._%SCAN(&mod_list,&i) = 1/(%SCAN(&var_list,&i)**3);
				%end;

				%if "%scan(%bquote(&transformation), &j, "!!")" = "reciprocal_square" %then %do;
					&prefix._%SCAN(&mod_list,&i) = 1/(%SCAN(&var_list,&i)**2);
				%end;

				%if "%scan(%bquote(&transformation), &j, "!!")" = "multiplier" %then %do;
					&prefix._%SCAN(&var_list,&i) = %SCAN(&var_list,&i)*%sysevalf(%scan(%bquote(&multiplier), &j, "!!"));
				%end;

				%if "%scan(%bquote(&transformation), &j, "!!")" = "default" %then %do;
					&prefix._%SCAN(&var_list,&i) = %SCAN(&var_list,&i);
				%end;
			%end;

			%LET i=%EVAL(&i.+1);	
		%end;

		end;
		%let j = %eval(&j.+1);
	%end;

	run;

%MEND trans;
%trans;

/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "EDA - TRANSFORMATION_TREATMENT_GROUPBY_COMPLETED";
	file "&output_path/TRANSFORMATION_TREATMENT_GROUPBY_COMPLETED.txt";
	put v1;
	run;


ENDSAS;


