
/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/ARITHMETIC_EXPRESSION_COMPLETED.txt &output_path/ARITHMETIC_EXPRESSION_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;

libname in "&input_path.";
libname out "&output_path.";

proc printto log="&output_path./ArithmeticExpression_Log.log";
run;
quit;
	
/*proc printto print="&output_path./ArithmeticExpression_Output.out";*/
	

%MACRO arithmeticExpression;
/*new variable creation*/
	data _null_;
		call symputx("equation1", compress(tranwrd("&equation." ,"^" ,"**" )));
		run;
	data in.data;
		set in.dataworking;
		&new_varname. = &equation1.;
	run;

/*determine if the new variable is created*/
	data _null_;
		dset=open("in.data");
		call symput("chk_var",varnum(dset,"&new_varname."));
		run; 

	%put &chk_var;
/*create output text file*/
	%if &chk_var ^= 0 %then %do;
		proc sql;
			select sum(&new_varname.) into :sum_newvar from in.data;
			quit;
		%put &sum_newvar;

/*		%if %eval(&sum_newvar.) ^= . %then %do;*/
			data out.temp;
				set in.data (keep=&new_varname.);
				run;

			data in.dataworking;
				set in.data;
				run;
				/*restriction on the no of rows*/
				%let dsid = %sysfunc(open(out.temp));
				%let nobs=%sysfunc(attrn(&dsid,nobs));	
				%let rc = %sysfunc(close(&dsid));
				%put &nobs.;

				%if &nobs.>6000 %then %do;
				proc surveyselect data=out.temp out=out.temp method=SRS
					  sampsize=6000 SEED=1234567;
					  run;
				%end;

						proc export data = out.temp
							outfile = "&output_path./arithmeticExpression_subsetViewpane.csv"
							dbms=CSV replace;
							run;

						data _null_;
							v1= "VARIABLE_CREATION_COMPLETE";
							file "&output_path/ARITHMETIC_EXPRESSION_COMPLETED.txt";
							put v1;
							run;
/*		%end;*/
	%end;
	%if &chk_var. = 0 or &sum_newvar. = . %then %do;
		data _null_;
			v1= "ERROR_IN_VARIABLE_CREATION";
			file "&output_path/ARITHMETIC_EXPRESSION_COMPLETED.txt";
			put v1;
			run;
	%end;

%MEND arithmeticExpression;
%arithmeticExpression;
%include %unquote(%str(%'&genericCode_path./datasetprop_update.sas%'));

/*ENDSAS;*/



