/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path./categorical_gof_completed.txt;
/* VERSION 2.5 */

options mprint mlogic symbolgen mfile ;

libname out "&output_path." ;

proc printto log="&output_path/categorical_log.log";
run;
quit;
/*proc printto print="&output_path/categorical_output.out";*/


%macro cat_cont;

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
	primary_key_1644 = _n_;
	%do i = 1 %to %sysfunc(countw(&str_vars.));
		%scan(&str_vars,&i) = tranwrd(%scan(&str_vars,&i), ",", "_");
	%end;
	run;

/*=========================================================================================================*/

data char_var (drop = type format);
	length variable_type $50.;
	length num_str $10.;
	set variable_list;

	var_len = length(name);

	if type = 1 then do;
		num_str ="numeric";
		frequency = 0 ; 
		variable_type = "continuous" ;
	end;

	else if type = 2 then do;
		num_str ="string";
		frequency = 0 ; 
		variable_type = "categorical" ;
	end;

if type = 1 and ((compress(format) ^= " ") and index(format,"BEST") = 0 and index(format,"COMMA") = 0 
	and index(format,"DOLLAR") = 0 and index(format,"FRACT") = 0 and index(format,"PERCENT") = 0 and index(format,"PVALUE") = 0 
	and index(format,"NEGPAREN") = 0 and index(format,"NUMEX") = 0) then num_str = "date";
run;

data char_var;
	retain name variable_type frequency num_str var_len label; 
	set char_var;
	run;

/*xml creation*/
libname outcat xml "&output_path./categorical.xml";
data outcat.categorical;
	set char_var;
	rename name = variable;
	rename frequency  = distinctvalues;
	run;

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


%mend cat_cont;
%cat_cont;







proc datasets lib=work kill nolist;
quit;

