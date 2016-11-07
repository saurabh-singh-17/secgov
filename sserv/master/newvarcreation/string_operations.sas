/*-----------------------------------------------------------------------------------------
Parameters Required
-----------------------------------------------------------------------------------------*/
/*%let codePath=/data22/IDev/Mrx//SasCodes//G8.4.1;*/
/*%let datasetinfo_path=/data22/IDev/Mrx//projects/disappear2-16-Sep-2013-13-31-19/1/NewVariable/StringOperation/3;*/
/*%let genericCode_path=/data22/IDev/Mrx//SasCodes//G8.4.1/common;*/

/*%let input_path=/data22/IDev/Mrx//projects/disappear2-16-Sep-2013-13-31-19/1;*/
/*%let output_path=/data22/IDev/Mrx//projects/disappear2-16-Sep-2013-13-31-19/1/NewVariable/StringOperation/3;*/
/*%let var_list=geography Store_Format;*/
/*%let operations=left right blanks blanks replace compress;*/
/*%let values=1_1 1_17 leading trailing token!!replace remove;*/
/*%let prefix=so1;*/
/*%let postfix=;*/
/*%let datatype=;*/
/*-----------------------------------------------------------------------------------------*/

options mprint mlogic symbolgen spool;

proc printto log="&output_path./string_operations.log" new;
/*proc printto;*/
run;
quit;

%put
muRx log of Data Handling > String Operations.
Run by &SYSUSERID. with SASversion&SYSVLONG4..
On &SYSSCP.     &SYSSCPL..
At &SYSTIME.|&SYSDATE9.|&SYSDAY.;

libname in "&input_path";
libname out "&output_path";



%macro string_operations;
/*-----------------------------------------------------------------------------------------
Scope for improvement
1. If the parameters are given in the format used by the code, then the "Parameter Play" block of code can be removed
2. No need to run the remove blanks option on variables which were originally numeric
-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
Paremeter Play
-----------------------------------------------------------------------------------------*/
%let one=;
%let two=;
%let delimiter=;

data _null_;
call symput("operations",tranwrd("&operations.","compress","tranwrd"));
run;


%do tempi=1 %to %sysfunc(countw(&operations.));
	%let current_operations = %scan(&operations.,&tempi.);
	%let current_values = %scan("&values.", &tempi., " ");
	/*%let current_values = %sysfunc(tranwrd(&current_values.,_,%str(,)));*/
	%put &current_values.;

	%if &current_operations. = blanks %then
		%do;
			%let one=&one.&delimiter.&current_values.;
		%end;
	%else
		%do;
			%let one=&one.&delimiter.&current_operations.;
		%end;

	%if &current_operations. = left %then %let two=&two.&delimiter.(,&current_values.);
	%else %if &current_operations. = right %then %let two=&two.&delimiter.(((()),&current_values.));
	%else %if &current_operations. = replace %then
		%do;
			%let current_values = %sysfunc(tranwrd("&current_values.",%str(!!),%str(",")));

			%let two=&two.&delimiter.(,&current_values.);
		%end;
	%else %if &current_operations. = tranwrd %then
		%do;
			%let current_values = "&current_values.","";

			%let two=&two.&delimiter.(,&current_values.);
		%end;
	%else %let two=&two.&delimiter.();

	%let delimiter=!!;
%end;

%let one=%sysfunc(tranwrd(&one.,left,%str(substr())));
%let one=%sysfunc(tranwrd(&one.,right,%str(reverse(substr(left(reverse()))))));
%let one=%sysfunc(tranwrd(&one.,leading,%str(left())));
%let one=%sysfunc(tranwrd(&one.,trailing,%str(trim())));
%let one=%sysfunc(tranwrd(&one.,tranwrd,%str(tranwrd())));
%let one=%sysfunc(tranwrd(&one.,all,%str(compress())));
%let one=%sysfunc(tranwrd(&one.,replace,%str(tranwrd())));

%if "&prefix." ^= "" %then %let prefix=&prefix._;
%if "&postfix." ^= "" %then %let postfix=_&postfix.;

%let datatype=%sysfunc(tranwrd(&datatype.,numeric,1));
%let datatype=%sysfunc(tranwrd(&datatype.,string,2));
/*-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
Sort the input variables list
Get the data type of all the variables selected
Revert back to the same order as in the parameter
-----------------------------------------------------------------------------------------*/
/*Read var_list into a dataset*/
data var_list_dataset;
	length variable $32.;
	%do tempi = 1 %to %sysfunc(countw(&var_list.," "));
		variable="%scan(&var_list.,&tempi.," ")";
		key=&tempi.;
		output;
	%end;
	stop;
	run;

/*Run proc contents on the variables in var_list*/
proc contents data=in.dataworking(keep=&var_list.) out=out_contents noprint;
run;
quit;

/*Sort out_contents by variable for merging*/
proc sort data=out_contents out=out_contents;
	by name;
run;
quit;

/*Sort var_list_dataset by variable for merging*/
proc sort data=var_list_dataset out=var_list_dataset;
	by variable;
run;
quit;

/*Merge data type with the variable names*/
data var_list_dataset;
	merge var_list_dataset out_contents(keep=name type rename=(name=variable));
	by variable;
run;

/*Get the dataset back to the original order*/
proc sort data=var_list_dataset out=var_list_dataset;
	by key;
run;
quit;


/*Create a macro variable for the variable type*/
proc sql;
	select type into: var_list_data_type separated by "!!" from var_list_dataset;
quit;
/*-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
Create new variable one by one
-----------------------------------------------------------------------------------------*/
data tobeadded;
run;

%let error_var_list=;
%let delimiter2=;
%let error=0;
%let success=0;

%do i=1 %to %sysfunc(countw(&var_list.));
	%let current_var_list = %scan(&var_list.,&i.);
	%let current_var_list_data_type = %scan(&var_list_data_type.,&i.,!!);
	%let current_newvar = &prefix.%substr(&current_var_list.,1,27)&postfix.;
	%if "&datatype." = "" %then 
		%do;
			%let current_datatype = &current_var_list_data_type.;
		%end;
	%else
		%do;
			%let current_datatype = &datatype.;
		%end;

	%let current_error=1;
	data temp;
		set in.dataworking(keep=&current_var_list. rename=&current_var_list.=temp) end=end;
		length tempvar $50.;
		%if &current_var_list_data_type. = 1 %then
			%do;
				format &current_var_list. best32.;
				tempvar = compress(temp);
			%end;
		%else
			%do;
				tempvar = temp;
			%end;
		%do tempi = 1 %to %sysfunc(countw(&operations.));
			%put &one.;
			%let current_one = %scan(&one.,&tempi.,!!);
			%put &one.;
			%let current_one=%sysfunc(compress(&current_one.,')'));
			%put &one.;
			%let current_two = %scan(&two.,&tempi.,!!);
			%let current_two = %sysfunc(compress(&current_two.,'('));
			%put &current_two;
			tempvar = &current_one.tempvar&current_two.;
		%end;
		%if &current_datatype. = 1 %then
			%do;
				&current_newvar. = input(tempvar,8.);
			%end;
		%else
			%do;
				&current_newvar. = tempvar;
			%end;
		if cmiss(tempvar,&current_newvar.)=1 then stop;
		if end then call symput("current_error",0);
	run;

	%if &current_error. = 0 %then
		%do;
			data tobeadded;
				merge tobeadded temp(keep=&current_newvar.);
			run;

			%let success=1;
		%end;
	%else
		%do;
			%let error_var_list=&error_var_list.&delimiter2.&current_var_list.;
			%let delimiter2=,;
			%let error=1;
		%end;
%end;
/*-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
If there is any error, write error.txt
-----------------------------------------------------------------------------------------*/
%if &error. = 1 %then
	%do;
		data _null_;
			v1 = "&error_var_list.";
			file "&output_path./error.txt";
			put v1;
		run;
	%end;
/*-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
If there is any success, add those variables to dataworking, write one CSV and write completed.txt
-----------------------------------------------------------------------------------------*/
%if &success. = 1 %then
	%do;
		data in.dataworking;
			merge in.dataworking tobeadded;
		run;
		
		%let dsid = %sysfunc(open(tobeadded));
		%let nobs=%sysfunc(attrn(&dsid,nobs));	
		%let rc = %sysfunc(close(&dsid));
		%put &nobs.;

		%if &nobs.>6000 %then %do;
		proc surveyselect data=tobeadded out=tobeadded method=SRS
			  sampsize=6000 SEED=1234567;
			  run;
		%end;

		proc export data=tobeadded dbms=csv outfile="&output_path./String_operations.csv";
		run;
		quit;

		%include "&genericCode_path./datasetprop_update.sas";

		data _null_;
			v1= "STRING_OPERATIONS_COMPLETED";
			file "&output_path/STRING_OPERATIONS_COMPLETED.txt";
			put v1;
		run;
	%end;
/*-----------------------------------------------------------------------------------------*/
%mend string_operations;
%string_operations;