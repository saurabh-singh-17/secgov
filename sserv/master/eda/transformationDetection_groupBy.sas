/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/TRANSFORMATION_DETECTION_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;

FILENAME MyFile "&output_path./TRANSFORMATION_DETECTION_COMPLETED.txt" ;

  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;

proc printto log="&output_path./TransformationDetection_Log.log";
run;
quit;
/*proc printto print="&output_path./TransformationDetection_Output.out";*/

libname in "&input_path.";
libname out "&output_path.";


data out.temp;
	set in.dataworking (keep = &grpvar_list. &var_list.);
	run;	


%MACRO transformationsDetection_grpBy;

%let i = 1;
	%do %until (not %length(%scan(&var_list, &i)));

		/*macro for variable name*/
		data _null_;
			set out.temp;
			call symputx ("var_name", "%scan(&var_list, &i)");
			run;


		/*univariate treatment*/
		proc univariate data = out.temp normal;
			class &grpvar_list.;
			var &var_name.;
		    output out = univ&i.
				mean = mean 
				mode = mode 
				median = median
				skewness = skewness
				kurtosis = kurtosis
				;
			run;


		/*modifying the basicMeasures output as required*/
		data univ&i.;
			retain attributes &grpvar_list. mean mode median;
			set univ&i.;
			attrib _all_ label=" ";

			length attributes $50.;
			attributes = "&var_name."; 
			run;


		/*appending the output for each variable*/
		%if "&i." = "1" %then %do;
			data out.output;
				set univ&i.;
				run;
		%end;
		%else %do;
			data out.output;
				set out.output univ&i.;
				run;
		%end;


		%let i = %eval(&i+1);
	%end;

	data out.output;
  		set out.output;
   
		%LET l =1 ;
		%DO %UNTIL(NOT %LENGTH(%SCAN(&grpvar_list,&l)));
			rename %SCAN(&grpvar_list,&l) = by_group&l.;

			%LET l=%EVAL(&l+1);	
		%end;
		run;

%MEND transformationsDetection_grpBy;
%transformationsDetection_grpBy;

/*CSV export*/
	proc export data = out.output
		outfile = "&output_path/TransformationDetection.csv" 
		dbms=CSV replace; 
		run;

/*delete datasets from output folder*/
	proc datasets library = out;
		delete temp output;
		run;


/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "EDA - TRANSFORMATION_DETECTION_COMPLETED";
	file "&output_path/TRANSFORMATION_DETECTION_COMPLETED.txt";
	put v1;
	run;


ENDSAS;



