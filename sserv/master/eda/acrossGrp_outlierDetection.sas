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

/*subset the input dataset*/
data out.temp;
	retain &groupVar_list.;
	set in.dataworking (keep = &groupVar_list. &var_list ); 
	run;

/*sort the subset*/
proc sort data = out.temp out = temp_inter;
	by  &groupVar_list.;
	run;


/*define macro for var_list to be used in counting no. of outliers*/
data _null_;
	set out.temp;
	call symputx("grp_forCount", compress(tranwrd("&groupVar_list." ," " ," ," )));
	run;

	%put &grp_forCount.;


%MACRO grpBy_outlier_detection;

%let increment = 5;

/*for two-sided outlier detection*/
%if "&flag_two_sided." = "true" %then %do;
	
	%LET i =1 ;
		%DO %UNTIL(NOT %LENGTH(%SCAN(&var_list,&i))) ;
			/*define macro for var_list*/
				data _null_;
					set out.temp;
					call symputx("var_name", "%SCAN(&var_list,&i)");
					run;

		/*for iqr*/
			%if "&flag_iqr." = "true" %then %do;
				%let lower = %sysevalf(25);
			    %let upper = %sysevalf(75);

				/*univariate treatment*/
					proc univariate data = out.temp noprint;
						class  &groupVar_list.;
						var &var_name.;
						output out=  out_uni&i.
							mean = mean
							median = median 
							mode = mode 
							qrange = iqr 
							pctlpts= 0 to 5 by 1 5 to 95 by &increment. 96 to 99 by 1 99.9 99.99 &lower. &upper. 
							pctlpre=p_ ;
							run;
				
				/*obtain outlier boundary*/
					data out_uni&i.;
						retain &groupVar_list. attributes lb_&var_name. ub_&var_name.;
						set out_uni&i.;
						attrib _all_ label=" ";

						format attributes $50.;
							attributes = "&var_name.";
							ub_&var_name. = compress(p_&upper. + (&multiplier. * iqr));
							lb_&var_name. = compress(p_&lower. - (&multiplier. * iqr));
							run;

				/*from univariate treatment, create intermediate dataset for output*/
					%if "&i." = "1" %then %do;
						data out.detect;
							retain &groupVar_list. attributes lower_cutoff upper_cutoff;
							set out_uni&i.(drop = lb_&var_name. ub_&var_name.);

							lower_cutoff = compress(p_&lower. - (&multiplier. * iqr));
							upper_cutoff = compress(p_&upper. + (&multiplier. * iqr));
							run;
					%end;
					%else %do;
						data out.detect;
							retain &groupVar_list. attributes lower_cutoff upper_cutoff;
							set out.detect out_uni&i.(drop = lb_&var_name. ub_&var_name.);

							lower_cutoff = compress(p_&lower. - (&multiplier. * iqr));
							upper_cutoff = compress(p_&upper. + (&multiplier. * iqr));
							run;
					%end;
			%end;

		/*for percentile*/
			%if "&flag_percentile." = "true" %then %do;
				%let lower = %sysevalf((100 - &percentile.)/2);
		      	%let upper = %sysevalf(100 - &lower.);

				/*univariate treatment*/
					proc univariate data = out.temp noprint;
						class  &groupVar_list.;
						var &var_name.;
						output out=  out_uni&i.
							mean = mean
							median = median 
							mode = mode 
							pctlpts= 0 to 5 by 1 5 to 95 by &increment. 96 to 99 by 1 99.9 99.99 &lower. &upper.
							pctlpre=p_ ;
							run;

				/*obtain outlier boundary*/
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
						retain &groupVar_list. attributes lb_&var_name. ub_&var_name.;
						set out_uni&i.;
						attrib _all_ label=" ";

						format attributes $50.;
							attributes = "&var_name.";
				
					
							%if "&odd." = "0" %then %do;
							lb_&var_name. = compress(p_&lower.);
							ub_&var_name. = compress(p_&upper.);
							%end;
							%else %do;
							lb_&var_name. = compress(p_&low.);
							ub_&var_name. = compress(p_&upp.);
							%end;
							run;

				/*from univariate treatment, create intermediate dataset for output*/
					%if "&i." = "1" %then %do;
						data out.detect;
							retain &groupVar_list. attributes lower_cutoff upper_cutoff;
							set out_uni&i.(drop = lb_&var_name. ub_&var_name.);

							%if "&odd." = "0" %then %do;
							lower_cutoff = compress(p_&lower.);
							upper_cutoff = compress(p_&upper.);
							%end;
							%else %do;
							lower_cutoff = compress(p_&low.);
							upper_cutoff = compress(p_&upp.);
							%end;
							run;
					%end;
					%else %do;
						data out.detect;
							retain &groupVar_list. attributes lower_cutoff upper_cutoff;
							set out.detect out_uni&i.(drop = lb_&var_name. ub_&var_name.);

							%if "&odd." = "0" %then %do;
							lower_cutoff = compress(p_&lower.);
							upper_cutoff = compress(p_&upper.);
							%end;
							%else %do;
							lower_cutoff = compress(p_&low.);
							upper_cutoff = compress(p_&upp.);
							%end;
							run;
					%end;
			%end;

		/*merge the outputs for each individual univariate treatment*/
			%if "&i." = "1" %then %do;
				data out_uni;
					set out_uni&i. (in=b keep = &groupVar_list. ub_&var_name. lb_&var_name.);
					run;	
			%end;
			%else %do;
			data out_uni;
					merge out_uni (in=a)  out_uni&i. (in=b keep = &groupVar_list. ub_&var_name. lb_&var_name.);
					by &groupVar_list.;
					if a;
					run;
			%end;

		%LET i=%EVAL(&i+1);	
	%end;

/*merge univariate output with working dataset*/
	data temp_inter;
		merge temp_inter (in=a)  out_uni (in=b);
		by &groupVar_list.;
		if a;
		run;

/*flagging the outliers*/
	data temp_inter;
		set temp_inter;
		%LET j =1 ;
			%DO %UNTIL(NOT %LENGTH(%SCAN(&var_list,&j))) ;

				if %SCAN(&var_list,&j) < lb_%SCAN(&var_list,&j) or %SCAN(&var_list,&j) > ub_%SCAN(&var_list,&j) then outlier_flag_&j. = 1;
						else outlier_flag_&j. = 0;
				
				%LET j=%EVAL(&j+1);	
			%end;

		run;
%end;


/*for one-sided outlier detection*/
%if "&flag_one_sided." = "true" %then %do;

%LET i =1 ;
	%DO %UNTIL(NOT %LENGTH(%SCAN(&var_list,&i))) ;
		/*define macro for var_list*/
			data _null_;
				set out.temp;
				call symputx("var_name", "%SCAN(&var_list,&i)");
				run;

	/*for iqr*/
		%if "&flag_iqr." = "true" %then %do;
			%let upper = %sysevalf(75);

			/*univariate treatment*/
				proc univariate data = out.temp noprint;
					class  &groupVar_list.;
					var &var_name.;
					output out=  out_uni&i.
						mean = mean
						median = median 
						mode = mode 
						qrange = iqr 
						pctlpts= 0 to 5 by 1 5 to 95 by &increment. 96 to 99 by 1 99.9 99.99 &upper. 
						pctlpre=p_ ;
						run;
			
			/*obtain outlier boundary*/
				data out_uni&i.;
					retain &groupVar_list. attributes ub_&var_name.;
					set out_uni&i.;
					attrib _all_ label=" ";

					format attributes $50.;
						attributes = "&var_name.";
						ub_&var_name. = compress(p_&upper. + (&multiplier. * iqr));
						run;

			/*from univariate treatment, create intermediate dataset for output*/
				%if "&i." = "1" %then %do;
					data out.detect;
						retain &groupVar_list. attributes upper_cutoff;
						set out_uni&i.(drop = ub_&var_name.);

						upper_cutoff = compress(p_&upper. + (&multiplier. * iqr));
						run;
				%end;
				%else %do;
					data out.detect;
						retain &groupVar_list. attributes upper_cutoff;
						set out.detect out_uni&i.(drop = ub_&var_name.);

						upper_cutoff = compress(p_&upper. + (&multiplier. * iqr));
						run;
				%end;
		%end;

	/*for percentile*/
		%if "&flag_percentile." = "true" %then %do;
			%let upper = %sysevalf(&percentile.);

			/*univariate treatment*/
				proc univariate data = out.temp noprint;
					class  &groupVar_list.;
					var &var_name.;
					output out=  out_uni&i.
						mean = mean
						median = median 
						mode = mode 
						pctlpts= 0 to 5 by 1 5 to 95 by &increment. 96 to 99 by 1 99.9 99.99 &upper.
						pctlpre=p_ ;
						run;

			/*obtain outlier boundary*/
				data _null_;
						call symputx("odd" , modz(&percentile., 2));
						run;

				%if "&odd." = "1" %then %do;
				data _null_;
						call symputx("upp", compress(tranwrd("&upper." ,"." ,"_" )));
						run;
				%end;

				data out_uni&i.;
					retain &groupVar_list. attributes ub_&var_name.;
					set out_uni&i.;
					attrib _all_ label=" ";

					format attributes $50.;
						attributes = "&var_name.";
			
				
						%if "&odd." = "0" %then %do;
						ub_&var_name. = compress(p_&upper.);
						%end;
						%else %do;
						ub_&var_name. = compress(p_&upp.);
						%end;
						run;

			/*from univariate treatment, create intermediate dataset for output*/
				%if "&i." = "1" %then %do;
					data out.detect;
						retain &groupVar_list. attributes upper_cutoff;
						set out_uni&i.(drop = ub_&var_name.);

						%if "&odd." = "0" %then %do;
						upper_cutoff = compress(p_&upper.);
						%end;
						%else %do;
						upper_cutoff = compress(p_&upp.);
						%end;
						run;
				%end;
				%else %do;
					data out.detect;
						retain &groupVar_list. attributes upper_cutoff;
						set out.detect out_uni&i.(drop = ub_&var_name.);

						%if "&odd." = "0" %then %do;
						upper_cutoff = compress(p_&upper.);
						%end;
						%else %do;
						upper_cutoff = compress(p_&upp.);
						%end;
						run;
				%end;
		%end;

	/*merge the outputs for each individual univariate treatment*/
		%if "&i." = "1" %then %do;
			data out_uni;
				set out_uni&i. (in=b keep = &groupVar_list. ub_&var_name.);
				run;	
		%end;
		%else %do;
		data out_uni;
				merge out_uni (in=a)  out_uni&i. (in=b keep = &groupVar_list. ub_&var_name.);
				by &groupVar_list.;
				if a;
				run;
		%end;

		%LET i=%EVAL(&i+1);	
	%end;

	/*merge univariate output with working dataset*/
		data temp_inter;
			merge temp_inter (in=a)  out_uni (in=b);
			by &groupVar_list.;
			if a;
			run;

	/*flagging the outliers*/
		data temp_inter;
			set temp_inter;
			%LET j =1 ;
				%DO %UNTIL(NOT %LENGTH(%SCAN(&var_list,&j))) ;

					if %SCAN(&var_list,&j) > ub_%SCAN(&var_list,&j) then outlier_flag_&j. = 1;
							else outlier_flag_&j. = 0;
					
					%LET j=%EVAL(&j+1);	
				%end;

			run;
	%end;

	


/*outliers_count*/
	%LET k =1 ;
		%DO %UNTIL(NOT %LENGTH(%SCAN(&var_list,&k)));

		
			proc sql;
				create table num_outliers&k.
					as	select &grp_forCount., "%SCAN(&var_list,&k)" as attributes format = $50. length = 50,
						count(%SCAN(&var_list,&k)) as count_outliers
						from temp_inter
						where outlier_flag_&k.=1
						group by &grp_forCount.;
						quit;

		/*merging count_outliers per var*/
			%if "&k" = "1" %then %do;
				data count_outliers;
					set num_outliers&k.;
					run;
			%end;
			%else %do;
				data count_outliers;
					set count_outliers num_outliers&k.;
					run;
			%end;

		%LET k=%EVAL(&k+1);	
	%end;



/*merge count_outliers with intermidiate output*/
	proc sort data = count_outliers out = count_outliers;
		by  &groupVar_list. attributes;
		run;

	proc sort data = out.detect out = out.detect;
		by  &groupVar_list. attributes;
		run;


	data out.detect;
			merge count_outliers (in=a) out.detect (in=b) ;
					by &groupVar_list. attributes;
					if b;
					run;

/*putting in outlier_count as zero where no. outliers observed*/
	data out.detect;
		set out.detect;
		if count_outliers = . then count_outliers = 0;
		run;

	data out.detect;
  		set out.detect;
   
		%LET l =1 ;
		%DO %UNTIL(NOT %LENGTH(%SCAN(&groupVar_list,&l)));
			rename %SCAN(&groupVar_list,&l) = by_group&l.;

			%LET l=%EVAL(&l+1);	
		%end;
		run;
			
%MEND grpBy_outlier_detection;
%grpBy_outlier_detection;


/*csv export*/
proc export data = out.detect
	outfile="&output_path/OutlierDetection.csv" 
	dbms=CSV replace; 
	run;


/*deleting the intermediate datasets from output lib*/
proc datasets library = out;
	delete detect temp;
	run;



/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "EDA - OUTLIER_DETECTION_COMPLETED";
	file "&output_path/OUTLIER_DETECTION_COMPLETED.txt";
	put v1;
run;

ENDSAS;



