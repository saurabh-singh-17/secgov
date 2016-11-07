*processbody;
options mprint mlogic symbolgen mfile;


libname in "&input_path";
libname out "&output_path";

proc printto log="&output_path./Binning_Log.log";
run;
quit;
/*proc printto print="&output_path./Binning_Output.out";*/
/*quit;*/


/*calculating the different levels (unique value count) in the numeric variable*/
ods output NLevels = dist_vals(keep=TableVar nlevels rename=(TableVar=name nlevels=freq));
proc freq data = in.dataworking nlevels;
	tables &var_names.;
	run;

/*classifying into categorical and continuous*/
data dist_vals;
	set dist_vals;
	length category $11;
		if freq > &frequency. then category = "continuous";
			else category = "categorical";
	run;


proc contents data = in.dataworking out = contents(keep = name type format) varnum;
	run;

data contents(keep=name num_str);
	length num_str $10.;
	set contents;
	if type = 1 then do;
		num_str ="numeric";
	end;
	else if type = 2 then do;
		num_str ="string";
	end;

	if type = 1 and ((compress(format) ^= " ") and index(format,"BEST") = 0 and index(format,"COMMA") = 0 
		and index(format,"DOLLAR") = 0 and index(format,"FRACT") = 0 and index(format,"PERCENT") = 0 and index(format,"PVALUE") = 0 
		and index(format,"NEGPAREN") = 0 and index(format,"NUMEX") = 0) then num_str = "date";
run;

proc sql;
	create table out.category as
	select * from dist_vals as a, contents as b
	where a.name = b.name;
	quit;

/*xml creation*/
libname outcat xml "&output_path./categorical_reconfig.xml";
data outcat.category;
	set out.category;
	run;
	
/*CSV export*/
 proc export data = outcat.category
	outfile="&output_path/categorical_reconfig.csv"
	dbms=CSV replace;
	run;

/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "categorical_completed";
	file "&output_path./categorical_completed.txt";
	put v1;
	run;

/**/


proc datasets lib=work kill nolist;
quit;

