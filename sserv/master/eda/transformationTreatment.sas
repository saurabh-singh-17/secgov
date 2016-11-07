/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/TRANSFORMATION_TREATMENT_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;

/*%sysexec del "&output_path./TRANSFORMATION_TREATMENT_COMPLETED.txt";*/

proc printto log="&output_path./Transformation_Treatment_Log.log";
run;
quit;
/*proc printto print="&output_path./Transformation_Treatment_Output.out";*/

libname in "&input_path";
libname out "&output_path";


%MACRO transformationseda;

/*change the varnames for renaming and newvar*/
%if "&flag_replace." = "false" or "&flag_replace." = "rename" %then %do;
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

%if "&flag_procedure_selection." = "2" %then %do;
/*subsetting the input dataset*/
      data temp;
            retain primary_key_1644;
            set in.dataworking (keep = &var_list. primary_key_1644); 
            run;
%end; 

%if "&flag_procedure_selection." = "0" %then %do;
      %if "&grp_no" ^= "0" %then %do;
            data temp;
                  set in.dataworking (where = (GRP&grp_no._flag = "&grp_flag.") keep = GRP&grp_no._flag &var_list. primary_key_1644);
                  run;
      %end;
%end;

/*Transform*/
data temp;
      set temp;
      %LET i =1;
      %DO %UNTIL(NOT %LENGTH(%SCAN(&var_list,&i)));
      
            %if "&flag_replace." = "true" or "&flag_replace." = "rename" %then %do;
                  %if "&transformation." = "log" %then %do;
                        %SCAN(&var_list,&i) = log(%SCAN(&var_list,&i));
                  %end;

                  %if "&transformation." = "e_power" %then %do;
                        %SCAN(&var_list,&i) = exp(%SCAN(&var_list,&i));
                  %end;

                  %if "&transformation." = "square_root" %then %do;
                        %SCAN(&var_list,&i) = sqrt(%SCAN(&var_list,&i));
                  %end;

                  %if "&transformation." = "cube_root" %then %do;
                        %SCAN(&var_list,&i) = %SCAN(&var_list,&i)**(1/3);
                  %end;

                  %if "&transformation." = "square" %then %do;
                        %SCAN(&var_list,&i) = %SCAN(&var_list,&i)**2;
                  %end;

                  %if "&transformation." = "cube" %then %do;
                        %SCAN(&var_list,&i) = %SCAN(&var_list,&i)**3;
                  %end;

                  %if "&transformation." = "reciprocal" %then %do;
                        %SCAN(&var_list,&i) = 1/%SCAN(&var_list,&i);
                  %end;

                  %if "&transformation." = "reciprocal_sqrt" %then %do;
                        %SCAN(&var_list,&i) = 1/sqrt(%SCAN(&var_list,&i));
                  %end;

                  %if "&transformation." = "reciprocal_cube" %then %do;
                        %SCAN(&var_list,&i) = 1/(%SCAN(&var_list,&i)**3);
                  %end;

                  %if "&transformation." = "reciprocal_square" %then %do;
                        %SCAN(&var_list,&i) = 1/(%SCAN(&var_list,&i)**2);
                  %end;

                  %if "&transformation." = "multiplier" %then %do;
                        %SCAN(&var_list,&i) = (%SCAN(&var_list,&i)*%sysevalf(&multiplier.));
                  %end;

				  %if "&transformation." = "default" %then %do;
                        %SCAN(&var_list,&i) = %SCAN(&var_list,&i);
                  %end;
            %end;

            %if "&flag_replace." = "false" %then %do;
                  %if "&transformation." = "log" %then %do;
                        &prefix._%SCAN(&mod_list,&i) = log(%SCAN(&var_list,&i));
                  %end;

                  %if "&transformation." = "e_power" %then %do;
                        &prefix._%SCAN(&mod_list,&i) = exp(%SCAN(&var_list,&i));
                  %end;

                  %if "&transformation." = "square_root" %then %do;
                        &prefix._%SCAN(&mod_list,&i) = sqrt(%SCAN(&var_list,&i));
                  %end;

                  %if "&transformation." = "cube_root" %then %do;
                        &prefix._%SCAN(&mod_list,&i) = %SCAN(&var_list,&i)**(1/3);
                  %end;

                  %if "&transformation." = "square" %then %do;
                        &prefix._%SCAN(&mod_list,&i) = %SCAN(&var_list,&i)**2;
                  %end;

                  %if "&transformation." = "cube" %then %do;
                        &prefix._%SCAN(&mod_list,&i) = %SCAN(&var_list,&i)**3;
                  %end;

                  %if "&transformation." = "reciprocal" %then %do;
                        &prefix._%SCAN(&mod_list,&i) = 1/%SCAN(&var_list,&i);
                  %end;

                  %if "&transformation." = "reciprocal_sqrt" %then %do;
                        &prefix._%SCAN(&mod_list,&i) = 1/sqrt(%SCAN(&var_list,&i));
                  %end;

                  %if "&transformation." = "reciprocal_cube" %then %do;
                        &prefix._%SCAN(&mod_list,&i) = 1/(%SCAN(&var_list,&i)**3);
                  %end;

                  %if "&transformation." = "reciprocal_square" %then %do;
                        &prefix._%SCAN(&mod_list,&i) = 1/(%SCAN(&var_list,&i)**2);
                  %end;

                  %if "&transformation." = "multiplier" %then %do;
                        &prefix._%SCAN(&var_list,&i) = (%SCAN(&var_list,&i)*%sysevalf(&multiplier.));
                  %end;

				  %if "&transformation." = "default" %then %do;
                        &prefix._%SCAN(&var_list,&i) = %SCAN(&var_list,&i);
                  %end;
            %end;

            %LET i=%EVAL(&i+1);     
      %end;
      run;

      %if "&flag_procedure_selection." = "2" %then %do;
      /*create output dataset*/
            proc sort data = temp;
                  by primary_key_1644;
                  run;

            proc sort data = in.dataworking;
                  by primary_key_1644;
                  run;

            data in.dataworking (drop = primary_key_1644);
                  merge temp(in=a) in.dataworking(in=b drop = &var_list.);
                  by primary_key_1644;
                  if a and b;
                  run;
      %end;

      %if "&flag_procedure_selection." = "0" %then %do;
            proc sort data = temp;
                  by primary_key_1644;
                  run;

            proc sort data = in.dataworking;
                  by primary_key_1644;
                  run;

      /*create output dataset*/
            data in.dataworking;
                  merge temp(in=a) in.dataworking(in=b drop = &var_list.);
                  by primary_key_1644;
                  if b;
                  run;

            data in.dataworking;
                  set in.dataworking;
                  %if "&flag_replace." = "false" %then %do;
                        %LET j =1;
                        %DO %UNTIL(NOT %LENGTH(%SCAN(&var_list,&j)));

                              if &prefix._%SCAN(&mod_list,&j) = . and GRP&grp_no._flag ^= "&grp_flag." then &prefix._%SCAN(&mod_list,&j) = %SCAN(&var_list,&j);
                              
                        %LET j=%EVAL(&j+1);     
                        %end;
                  %end;
                  run;
      %end;

      %if "&flag_replace." = "rename" %then %do;
            data in.dataworking;
                  set in.dataworking;
                  %let i = 1;
	              %do %until (not %length(%scan(&var_list, &i)));
	                    rename %scan(&var_list, &i) = &prefix._%scan(&mod_list, &i);
	                    %let i=%eval(&i+1);     
	              %end;
                  run;
      %end;

%MEND transformationseda;
%transformationseda;

/* flex uses this file to test if the code has finished running */
data _null_;
      v1= "EDA - TRANSFORMATION_TREATMENT_COMPLETED";
      file "&output_path/TRANSFORMATION_TREATMENT_COMPLETED.txt";
      put v1;
      run;


/*ENDSAS;*/


