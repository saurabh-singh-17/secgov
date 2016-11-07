/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/OUTLIER_DETECTION_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;

FILENAME MyFile "&output_path/OUTLIER_DETECTION_COMPLETED.txt" ;

  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;


proc printto log="&output_path/OutlierDetection_Log.log";
run;
quit;
/*proc printto print="&output_path/OutlierDetection_Output.out";*/


libname in "&input_path.";
libname out "&output_path.";



%MACRO outlier_detection;
%if "&flag_procedure_selection." = "2" %then %do;
	data out.temp;
		set in.dataworking (keep = &var_list); 
		run;	
%end;

%if "&flag_procedure_selection." = "0" %then %do;
	%if "&grp_no" = "0" %then %do;
	data dataworking;
		set in.dataworking;
		run;
	%end;
	%else %do;
	data dataworking;
		set in.dataworking (where = (GRP&grp_no._flag = "&grp_flag."));
		run;
	%end;

	data out.temp;
		set dataworking (keep = &var_list);
		run;	
%end;



%LET i =1 ;
	%DO %UNTIL(NOT %LENGTH(%SCAN(&var_list,&i))) ;   /*do loop to evaluate variables one-by-one*/
		%let increment = 5;

		/*for two-sided detection*/
			%if "&flag_two_sided." = "true" %then %do;

			/*for iqr*/
				%if "&flag_iqr." = "true" %then %do;
					%let lower = %sysevalf(25);
		      		%let upper = %sysevalf(75);

				/*univariate treatment*/
					proc univariate data = out.temp noprint;
						var %SCAN(&var_list,&i)  ;
						output out= outlier_uni&i.
							mean = mean 
							median = median 
							mode = mode 
							qrange = iqr 
							pctlpts= 0 to 5 by 1 5 to 95 by &increment. 96 to 99 by 1 99.9 99.99 &lower. &upper. 
							pctlpre=p_ ;
						run;
				/*determine the outlier boundaries*/
					data _null_;
						set outlier_uni&i.;
						call symputx("outlier_lb", compress(p_&lower. - (&multiplier. * iqr)));
						call symputx("outlier_ub", compress(p_&upper. + (&multiplier. * iqr)));
						call symputx("var_name", "%SCAN(&var_list,&i)");
						call symputx("lower_boundary", "p_&lower.");
						call symputx("upper_boundary", "p_&upper.");

						run;
				%end;

			/*for percentile*/
				%if "&flag_percentile." = "true" %then %do;

					%let lower = %sysevalf((100 - &percentile.)/2);
	      			%let upper = %sysevalf(100 - &lower.) ;

				/*univariate treatment*/
					proc univariate data = out.temp noprint;
						var %SCAN(&var_list,&i)  ;
						output out= outlier_uni&i.
							mean = mean 
							median = median 
							mode = mode 
							pctlpts= 0 to 5 by 1 5 to 95 by &increment. 96 to 99 by 1 99.9 99.99 &lower. &upper. 
							pctlpre=p_ ;
							run;
				
				/*determine the outlier boundaries*/
					data _null_;
						call symputx("odd" , modz(&percentile., 2));
						run;

					%if "&odd." = "0" %then %do;
						data _null_;
							set outlier_uni&i. ;
							call symputx("outlier_lb", compress(p_&lower.));
							call symputx("outlier_ub", compress(p_&upper.));	
							call symputx("var_name", "%SCAN(&var_list,&i)");
							call symputx("lower_boundary", "p_&lower.");
							call symputx("upper_boundary", "p_&upper.");	
							run;
					%end;

					%else %do;
						data _null_;
							call symputx("low", compress(cats("p_" , tranwrd("&lower." ,"." ,"_" ))));
							call symputx("upp", compress(cats("p_" , tranwrd("&upper." ,"." ,"_" ))));
							call symputx("lower_boundary", "&low.");
							call symputx("upper_boundary", "&upp.");
							run;

						data _null_;
							set outlier_uni&i. ;
							call symputx("outlier_lb" , &low.);
							call symput("outlier_ub" , &upp.);
							call symputx("var_name", "%SCAN(&var_list,&i)");
							run;
					%end;
				%end;
			
				%put &outlier_lb &outlier_ub &var_name;

			/*identify the outliers*/
				data out.temp;
					retain &var_name. outlier_flag_&i.;
					set out.temp;
					if %SCAN(&var_list,&i) < &outlier_lb. or %SCAN(&var_list,&i) > &outlier_ub. then outlier_flag_&i. = 1;
						else outlier_flag_&i. = 0;
					run;

			/*count outliers*/
				proc sql;
					select count(%SCAN(&var_list,&i)) into :noofoutliers from out.temp
					where outlier_flag_&i. = 1;
					quit;

			/*create a dataset having outlier details for a variable*/
				data outlier_uni&i.;
					retain attributes lower_cutoff upper_cutoff count_outliers;
					set outlier_uni&i.;
					
					format attributes $50.;
					attributes = "&var_name.";
					lower_cutoff = &outlier_lb.;
					upper_cutoff= &outlier_ub.;
					count_outliers = &noofoutliers.;
					run;

			/*append individual outlier-info datasets into single dataset*/
				%if "&i" ="1" %then %do;
					data out.details_var;
						format attributes $50.;
						set outlier_uni&i.;
						run;
				%end;

				%else %do;
					data out.details_var;
						format attributes $50.;
						set out.details_var outlier_uni&i.;
						run;
				%end;
			%end;
	
		/*for one-sided detection*/
			%if "&flag_one_sided." = "true" %then %do;

			/*for iqr*/
				%if "&flag_iqr." = "true" %then %do;
				%let upper = %sysevalf(75);

				/*univariate treatment*/
					proc univariate data = out.temp noprint;
						var %SCAN(&var_list,&i)  ;
						output out= outlier_uni&i.
							mean = mean 
							median = median 
							mode = mode 
							qrange = iqr 
							pctlpts= 0 to 5 by 1 5 to 95 by &increment. 96 to 99 by 1 99.9 99.99 &upper. 
							pctlpre=p_ ;
						run;
				/*determine outlier boundary*/
					data _null_;
						set outlier_uni&i.;
						call symputx("outlier_ub", compress(p_75 + (&multiplier. * iqr)));
						call symputx("var_name", "%SCAN(&var_list,&i)");
						call symputx("upper_boundary", "p_&upper.");
						run;
				%end;

			/*for percentile*/
				%if "&flag_percentile." = "true" %then %do;

	      			%let upper = %sysevalf(&percentile.);
					%put &upper.;

				/*univariate treatment*/
					proc univariate data = out.temp noprint;
						var %SCAN(&var_list,&i)  ;
						output out= outlier_uni&i.
							mean = mean
							median = median 
							mode = mode 
							qrange = iqr 
							pctlpts= 0 to 5 by 1 5 to 95 by &increment. 96 to 99 by 1 99.9 99.99 &upper.
							pctlpre=p_ ;
							run;

				/*determine outlier boundary*/	
					data _null_;
						call symputx("odd" , modz(&percentile., 2));
						run;

					%if "&odd." = "0" %then %do;
						data _null_;
							set outlier_uni&i. ;
							call symputx("outlier_ub", compress(p_&upper.));	
							call symputx("var_name", "%SCAN(&var_list,&i)");
							call symputx("upper_boundary", "p_&upper.");	
							run;
					%end;

					%else %do;
						data _null_;
							call symputx("upp", compress(cats("p_" , tranwrd("&upper." ,"." ,"_" ))));
							run;

						data _null_;
							set outlier_uni&i. ;
							call symput("outlier_ub" , &upp.);
							call symputx("upper_boundary", "&upp.");
							call symputx("var_name", "%SCAN(&var_list,&i)");
							run;
					%end;
				%end;
			
				%put &outlier_ub &var_name;

			/*identify outliers*/
				data out.temp;
					retain &var_name. outlier_flag_&i.;
					set out.temp;
					if %SCAN(&var_list,&i) > &outlier_ub. then outlier_flag_&i. = 1;
						else outlier_flag_&i. = 0;
					run;

			/*count outliers*/
				proc sql;
					select count(%SCAN(&var_list,&i)) into :noofoutliers from out.temp
					where outlier_flag_&i. = 1;
					quit;

			/*create dataset having outlier info for a variable*/
				data outlier_uni&i.;
					retain attributes upper_cutoff count_outliers;
					set outlier_uni&i.;
					
					format attributes $50.;
					attributes = "&var_name.";
					upper_cutoff= &outlier_ub.;
					count_outliers = &noofoutliers.;
					run;

			/*append individual outlier-info datasets into single dataset*/
				%if "&i" ="1" %then %do;
					data out.details_var;
						format attributes $50.;
						set outlier_uni&i.;
						run;
				%end;

				%else %do;
					data out.details_var;
						format attributes $50.;
						set out.details_var outlier_uni&i.;
						run;
				%end;
			%end;
					
		%LET i=%EVAL(&i+1);
	%end;
%MEND outlier_detection;
%outlier_detection;


/*csv export*/
PROC EXPORT DATA = out.details_var
	OUTFILE="&output_path/OutlierDetection.csv" 
	DBMS=CSV REPLACE; 
	RUN;


	proc datasets library = out;
	delete temp details_var;
	run;



/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "EDA - OUTLIER_DETECTION_COMPLETED";
	file "&output_path/OUTLIER_DETECTION_COMPLETED.txt";
	put v1;
run;

ENDSAS;





