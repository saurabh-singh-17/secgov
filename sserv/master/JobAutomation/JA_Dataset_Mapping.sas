
*processbody;
%let completedTXTPath =  &output_path./NEWVAR_TRANSFORMATION_COMPLETED.txt;
/*	Description		: A macro to provide the contents of dataset and provide unique values for categorical variables*/
/*	Created Date	: 25Nov2013*/
/*	Author(s)		: Payal Gupta*/


options mprint mlogic symbolgen mfile ;

%macro job_automation;
%do i=1 %to %sysfunc(countw(&input_path.,"##"));
	%let current_input_path = %scan(&input_path., &i., "##");
	%let current_output_path = %scan(&output_path., &i., "##");
	%let current_dataset_name = %scan(&dataset_name., &i., "##");
	%let current_categorical_vars= %scan(&categorical_vars., &i., "##");
 
	%do j=1 %to %sysfunc(countw(&current_input_path.,"!!"));

		%let data= %scan(&current_dataset_name.,&j.);
		%let lib= %scan(&current_input_path.,&j.,"!!");
		%let lib_out= %scan(&current_output_path.,&j.,"!!");
		
		libname in&j. "&lib.";
		libname out&j. "&lib_out.";
		
		proc contents data = in&j..&data. out=contents(keep=NAME TYPE);
	 	run;
		
		data contents(keep= NAME var_type);
		length NAME $50.var_type $10.;
		set contents;
		if type =1 then var_type="num";
		else var_type="char";
		run;


		proc export data=contents
		outfile= "&lib_out./contents.csv"
		dbms=csv replace;
		run;

%let new_cat_var=%scan(&current_categorical_vars.,&j.,"!!");

	%do k=1 %to %sysfunc(countw(&new_cat_var.," "));
			%let cat_vars=%scan(&new_cat_var.,&k.);
			proc sql;
			create table  &cat_vars. as 
			select distinct(&cat_vars.) as unique_values from in&j..&data.;
			run;
			quit;

			proc export data=&cat_vars.
			outfile= "&lib_out./&cat_vars..csv"
			dbms=csv replace;
			run;
	%end;

			data _null_;
				v1= " Job_Automation_Compeleted";
				file "&lib_out./Job_Automation_Compeleted.txt";
				put v1;
				run;
	%end;

%end;

%mend;
%job_automation;
