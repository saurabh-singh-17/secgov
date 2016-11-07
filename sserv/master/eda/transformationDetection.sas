/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/TRANSFORMATION_DETECTION_COMPLETED.txt;
options mprint mlogic symbolgen mfile;

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


%MACRO transformationsDetection;
/*across dataset*/
%if "&flag_procedure_selection." = "2" %then %do;

/*subsetting the input dataset*/
	data out.temp;
		set in.dataworking (keep = &var_list.); 
		run;
%end;	

/*per group by*/
%if "&flag_procedure_selection." = "0" %then %do;

	%if "&grp_no" = "0" %then %do;
		data out.temp;
			set in.dataworking (keep = &var_list.);
			run;
	%end;
	%else %do;
		data out.temp;
			set in.dataworking (where = (GRP&grp_no._flag = "&grp_flag.") keep = &var_list. GRP&grp_no._flag);
			run;
	%end;

%end;

%let i = 1;
	%do %until (not %length(%scan(&var_list, &i)));

	/*macro for variable name*/
		data _null_;
			set out.temp;
			call symputx ("var_name", "%scan(&var_list, &i)");
			run;

	/*univariate treatment*/
		ODS OUTPUT BasicMeasures = univ&i.;
		ODS output TestsForNormality = normal&i.;
		ODS output GoodnessOfFit = gof&i. (where = (test = "Anderson-Darling")keep = distribution test pvalue);
		goptions device = gif;
		proc univariate data = out.temp normal;
			var &var_name.;
		    histogram /  lognormal weibull gamma  exponential normal;     			  
			run;

	/*transforming the basicMeasures output as required*/
		proc transpose data = univ&i.(keep = LocMeasure LocValue) out = univ&i. (drop = _name_);;
			id LocMeasure;
			var LocValue;
			run;

		data univ&i.;
			retain attributes;
			set univ&i.;
			attrib _all_ label=" ";

			length attributes $50.;
			attributes = "&var_name."; 
			run;

	/*transforming the normality output as required*/
		data normal&i.;
			set normal&i.;
			length testn $30.;
			testn = catx("_", tranwrd (test, "-", "_"), "normality");
			run;

		proc transpose data = normal&i.(keep = testn pvalue) out = normal&i. (drop = _name_);
			id testn;
			var pvalue;
			run;

	/*transforming the distributions output as required*/
		data gof&i.;
			set gof&i.;
			length distr $50.;
			distr = catx("_", distribution, tranwrd (test, "-", "_"));
			run;

		proc transpose data = gof&i. (keep = distr pvalue) out = gof&i. (drop = _name_ _label_);
			id distr;
			var pvalue ;
			run;

	/*merging the output for univariate, normality and distributions*/
		data out&i.;
			merge univ&i. normal&i. gof&i.;
			run;

	/*appending the output for each variable*/
		%if "&i." = "1" %then %do;
			data out.output;
				set out&i.;
				run;
		%end;
		%else %do;
			data out.output;
				set out.output out&i.;
				run;
		%end;

		%let i = %eval(&i+1);
	%end;

%MEND transformationsDetection;
%transformationsDetection;

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





