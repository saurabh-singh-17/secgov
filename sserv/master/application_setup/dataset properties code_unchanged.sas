	/*Successfully converted to SAS Server Format*/ *processbody; %let completedTXTPath =  &output_path./datset_prop_completed_completed.txt;
 /* VERSION 2.1 */
 options mprint mlogic symbolgen mfile;
 FILENAME MyFile "&output_path/dataset_properties_completed.txt" ;  DATA _NULL_ ;    rc = FDELETE('MyFile') ;  RUN ;
 proc printto log="&output_path/dataset_prop_output.log";
run;
 quit;

 
 libname out "&output_path.";
 libname in "&input_path.";
 
 data &dataset_name.;
 	set in.&dataset_name.;
 	run;
 
 ods output members = properties(where=(lowcase(name)=lowcase("&dataset_name.")) keep=name obs vars FileSize);
 proc datasets details library = work;
 	run; 
 	quit ;
 
 /*libname prop xml "&output_path./dataset_properties.xml";*/
 data properties;
 set properties(rename =(name=file_name obs=no_of_obs vars=no_of_vars fileSize = file_size));
 format file_size 12.4;
 file_size = file_size;
 run;
 
 /*CSV export*/
  proc export data = properties
 	outfile="&output_path/dataset_properties.csv"
 	dbms=CSV replace;
 	run;
 

%macro cat_cont1;

proc datasets library = out nolist; 
	copy in=in out=out;
	select &dataset_name.; 
	change &dataset_name.=dataworking;
	run; quit; 

proc contents data = out.dataworking out = variable_list(keep = name type label format) noprint;
	run;

/*========================================================================================================*/
/*put primary_key and change ',' to '_'*/
proc sql;
	select name into :str_vars separated by " " from variable_list where type = 2;
	quit;
%put &str_vars;

data out.dataworking;
	set out.dataworking;
	primary_key_1644 = _n_;		%if %symexist(str_vars) %then %do;
		%do i = 1 %to %sysfunc(countw(&str_vars.));
			%scan(&str_vars,&i) = tranwrd(%scan(&str_vars,&i), ",", "_");
		%end;		%end;
	run;
/*=========================================================================================================*/

	/*=========================================================================================================*/
	/*Add a  column called tempvar(which contains the count of unique values) to variable_list*/
	/*=========================================================================================================*/
	proc sql noprint;
	select name into: all_variable_names separated by "!!" from variable_list;
	quit;

	%put &all_variable_names.;
	%let all_variable_distinct_count=;

	%let unique_count=;
	%do tempi = 1 %to %sysfunc(countw(&all_variable_names.,"!!"));
		%let current_variable = %scan(&all_variable_names.,&tempi.,"!!");

		proc sql noprint;
			select count(distinct(&current_variable.)) into: temp_unique_count from out.dataworking;
			quit;

		%let unique_count= &unique_count.!!&temp_unique_count.;
	%end;

	data dis;
		%do tempi = 1 %to %sysfunc(countw(&unique_count.,"!!"));
			tempvar=%scan(&unique_count.,&tempi.,"!!");
			output;
		%end;
		stop;
		run;

	data variable_list;
		merge variable_list dis;
		run;
	/*=========================================================================================================*/

	data char_var (drop = type format);
		length variable_type $50.;
		length num_str $10.;
		set variable_list;

		var_len = length(name);

		if type = 1 then do;
			num_str ="numeric";
			variable_type = "continuous" ;
		end;

		else if type = 2 then do;
			num_str ="string";
			variable_type = "categorical" ;
		end;

		if type = 1 and ((compress(format) ^= " ") and index(format,"BEST") = 0 and index(format,"COMMA") = 0 
			and index(format,"DOLLAR") = 0 and index(format,"FRACT") = 0 and index(format,"PERCENT") = 0 and index(format,"PVALUE") = 0 
			and index(format,"NEGPAREN") = 0 and index(format,"NUMEX") = 0) then num_str = "date";
		run;

	data char_var(rename=(name=variable tempvar=distinctvalues));
		retain name variable_type tempvar num_str var_len label; 
		set char_var;
		run;

	/*xml creation*/
	proc export data = char_var
		outfile = "&output_path./variable_categorization.csv"
		dbms = csv replace;
		run;
	
	/*Exporting dataworking.csv*/

	proc export data = out.dataworking
	outfile = "&output_path./dataworking.csv"
	dbms = csv replace;
	run;


	/*flex uses this file to test if the code has finished running*/ 
	data _null_;
		v1= "eda - base_categorical_gof_completed";
		file "&output_path./categorical_gof_completed.txt";
		put v1;
		run;

%mend cat_cont1;
%cat_cont1;
