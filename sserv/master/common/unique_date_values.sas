/*Successfully converted to SAS Server Format*/
*processbody;
/*------------------------------------------------------------------------------------------------------------------------------*/
/*Parameters required*/
/*------------------------------------------------------------------------------------------------------------------------------*/
/*%let codePath=C:/Program Files/muRx;*/
/*%let input_path=C:/Users/vasanth.mm/MRx/sas/logistic-20-Jun-2013-12-14-46/1;*/
/*%let output_path=C:/Users/vasanth.mm/MRx/sas/logistic-20-Jun-2013-12-14-46/1/NewVariable/EventVariable;*/
/*%let var_list=Date date_11 date_date9 date_datetime16 */
/*date_ddmmyy6 date_mmddyy8 date_monyy5 date_yymmdd8;*/
/*------------------------------------------------------------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------------------------------------------------------*/
%let completedTXTPath =  &output_path/UNIQUE_VALUES_COMPLETED.txt;
options mlogic mprint symbolgen;

proc printto log="&output_path/unique_date_values_log.log" new;
/*proc printto;*/
run;
quit;
	
	

libname in "&input_path.";
libname out "&output_path.";
/*------------------------------------------------------------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------------------------------------------------------*/
/*Macro to get the min & max of date values in mmddyy10. format*/
/*------------------------------------------------------------------------------------------------------------------------------*/
%macro min_max_date_values;
	/*Deleting the completed txt*/
	filename myfile "&output_path/UNIQUE_VALUES_COMPLETED.txt";

	data _null_;
		rc = fdelete('myfile');
		run;

	/*Removing extra spaces in &var_list.*/
	%let var_list = %sysfunc(compbl(&var_list.));
	%let rename_statement=;
	%let min=;
	%let max=;
	%do i = 1 %to %sysfunc(countw(&var_list.," "));
		%let current_var_list = %scan(&var_list.,&i.," ");
		%let rename_statement = &rename_statement. COL&i. = &current_var_list.;

		proc sql noprint;
			select min(&current_var_list.) into: temp_min from in.dataworking;
			select max(&current_var_list.) into: temp_max from in.dataworking;
		run;
		quit;

		%let min=&min.!!&temp_min.;
		%let max=&max.!!&temp_max.;
	%end;

	data unique_date;
		format min mmddyy10. max mmddyy10.;
		%do tempi = 1 %to %sysfunc(countw(&min.,"!!"));
			min=%scan(&min.,&tempi.,"!!");
			max=%scan(&max.,&tempi.,"!!");
			output;
		%end;
		stop;
		run;

	proc transpose data = unique_date out = unique_date_transposed;
		var min max;
		run;

	data unique_date_transposed(drop = _NAME_);
		set unique_date_transposed(rename = (&rename_statement.));
		run;

	/*Export the CSV*/
	proc export data = unique_date_transposed outfile="&output_path/uniqueValues.csv" dbms=CSV replace;
		run;

	/*flex uses this file to test if the code has finished running */
	data _null_;
		v1= "UNIQUE_VALUES_COMPLETED";
		file "&output_path/UNIQUE_VALUES_COMPLETED.txt";
		put v1;
		run;
%mend;
%min_max_date_values;