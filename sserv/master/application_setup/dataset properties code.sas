/*------------------------------------------------------------------------------
parameters needed
--------------------------------------------------------------------------------
%let c_data_in                        = name of the input dataset
%let c_path_code                      = path of the murx code repository
%let c_path_in                        = path of the inputs
%let c_path_out                       = path of the outputs
------------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------
sample parameters
------------------------------------------------------------------------------*/
/*%let c_data_in                        = walmartmini;*/
/*%let c_path_code                      = /product-development/murx//SasCodes//8.7.1;*/
/*%let c_path_in                        = /product-development/vasanth.mm/;*/
/*%let c_path_out                       = /product-development/vasanth.mm/temp;*/

%let c_data_in                        = &dataset_name.;
%let c_path_code                      = &codePath.;
%let c_path_in                        = &input_path.;
%let c_path_out                       = &output_path.;
/*----------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------
pre preparation
------------------------------------------------------------------------------*/
*processbody;
options mlogic mprint symbolgen;

proc printto log="&c_path_out./add_dataset.log" new;
run;
quit;
/*----------------------------------------------------------------------------*/


%macro ps_ad;
	/*libraries*/
	libname in       "&c_path_in.";
	libname out      "&c_path_out.";

	/* proc contents for variable categorization */
	proc contents data=in.&c_data_in. out=variable_categorization(keep=name type label format rename=(name=variable)) noprint;
	run;
	quit;

	/* name of the string variables */
	proc sql noprint;
		select variable into :str_vars separated by " "
			from variable_categorization
				where type = 2;
	quit;

	/* copy in.ds to out.dataworking, create the key variable and replace "," by "_" in string variables */
	data out.dataworking;
		set in.&c_data_in.;
		primary_key_1644 = _n_;

		%if %symexist(str_vars) %then
			%do tempi = 1 %to %sysfunc(countw(&str_vars.));
				%scan(&str_vars., &tempi.) = tranwrd(%scan(&str_vars., &tempi.), ",", "_");
			%end;
	run;

	/* output : dataset properties */
	ods output members = dataset_properties(keep=name obs vars filesize where=(name="DATAWORKING"));

	proc datasets details library=out;
	run;
	quit;

	data dataset_properties;
		length file_name $32.;
		set dataset_properties(rename=(name=file_name obs=no_of_obs vars=no_of_vars filesize=file_size));
		format file_size 12.4;
		file_size=file_size/1048576;
		file_name  = "&c_data_in.";
		no_of_vars = no_of_vars - 1;
	run;

	proc export data=dataset_properties outfile="&c_path_out./dataset_properties.csv" dbms=csv replace;
	run;
	quit;

	/* output : variable categorization */
	data variable_categorization(keep = variable variable_type distinctvalues num_str var_len label);
		retain variable variable_type num_str var_len label;
		length variable_type $11 num_str $7;
		set variable_categorization;
		var_len        = 0;
		distinctvalues = 0;
		if type = 1 then
			do;
				if compress(format) ^= " " and
					index(format,"BEST")     = 0 and
					index(format,"COMMA")    = 0 and 
		    		index(format,"DOLLAR")   = 0 and
					index(format,"FRACT")    = 0 and
					index(format,"PERCENT")  = 0 and
					index(format,"PVALUE")   = 0 and
		    		index(format,"NEGPAREN") = 0 and
					index(format,"NUMEX")    = 0 then
					do;
						num_str              = "date";
					end;
				else
					do;
						num_str              = "numeric";
					end;
				variable_type                = "continuous";
			end;
		else if type = 2 then
			do;
				num_str                      = "string";
				variable_type                = "categorical";
			end;
	run;
	
	proc export data=variable_categorization outfile="&c_path_out./variable_categorization.csv" dbms=csv replace;
	run;
	quit;

	/* completed txt */
	data _null_;
	   v1= "add_dataset_completed";
	   file "&c_path_out./categorical_gof_completed.txt";
	   put v1;
	run;
%mend ps_ad;
%ps_ad;