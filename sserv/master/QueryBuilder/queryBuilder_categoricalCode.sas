/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path./categorical_gof_completed.txt;

options mprint mlogic symbolgen mfile;

/*proc printto print="&output_path/categorical_output.out";*/
proc printto log="&output_path/categorical_Log.log";
run;
quit;

libname in "&input_path.";
libname out "&output_path.";


%macro cat_cont1;

proc datasets lib=work;
delete char_var;
run;

proc contents data = in.&dataset_name. out = variable_list(keep = name type label format) noprint;
	run;

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

	/*flex uses this file to test if the code has finished running*/ 
	data _null_;
		v1= "eda - base_categorical_gof_completed";
		file "&output_path./categorical_gof_completed.txt";
		put v1;
		run;

%mend cat_cont1;
%cat_cont1;





proc datasets lib=work kill nolist;
quit;

