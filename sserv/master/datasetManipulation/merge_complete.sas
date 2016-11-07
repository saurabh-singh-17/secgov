/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path./MERGE_COMPLETED.txt;
/*-- Description ---------------------------------------------------------------------------------------------------------------------------*/
/*-- Process Name 	: Merge									   																				*/
/*-- Description  	: Merges datasets and writes the resulting dataset																		*/
/*-- Return type  	: None             					  																					*/
/*-- Author 		: Vasanth M M 4261																										*/
/*-- Last Edit		: 																														*/
/*-- Last Edited on	: 																														*/
/*-- Last Edited By	: 						  																								*/
/*Known Issues		: If variables with the same name exist in multiple datasets we get only the values from the base dataset				*/
/*------------------------------------------------------------------------------------------------------------------------------------------*/

/*-- Parameters Required -------------------------------------------------------------------------------------------------------------------*/
/*%let input_path=C:/MRx/sas/corr-25-Jan-2013-14-20-16/2||C:/MRx/sas/corr-25-Jan-2013-14-20-16/3||C:/MRx/sas/corr-25-Jan-2013-14-20-16/1;	*/
/*%let output_path=C:/MRx/sas/corr-25-Jan-2013-14-20-16/DatasetManipulation/Merge/1;														*/
/*%let key_variables=Date;																													*/
/*%let type_join=a1 and a2 and a3;																											*/
/*%let new_dataset=nyu;																														*/
/*%let final_variables=Date channel_3 channel_4																								*/
/*------------------------------------------------------------------------------------------------------------------------------------------*/

/*-- Code Fragments ------------------------------------------------------------------------------------------------------------------------*/
/*Frag 1 : Macro : Options and clear the log																								*/
/*Frag 2 : Macro : Library definitions																										*/
/*Frag 3 : Macro : Log and print																											*/
/*Frag 4 : Macro : Sorting the input datasets by key variables and taking the name of the input datasets,									*/
/*			concatenating them together, so that they can be used in merge data step														*/
/*Frag 4.2 : Macro : Replace a1 by a2																										*/
/*Frag 5 : Macro : Merge datasets using SAS																									*/
/*Frag 6 : Macro : Many-many outer join using SQL																							*/
/*Frag 7 : Macro : Many-many inner join using SQL																							*/
/*Frag 8 : Macro : Get the common values from the input datasets																			*/
/*Frag 9 : Macro : Check if the merge is many-many or not																					*/
/*Frag 10 : Macro : Write the merged dataset in the output path and the CSV and completed.txt												*/
/*Frag 11 : Macro : Rearrange the input datasets for SQL																					*/
/*Frag 12 : Calling all the macro(s)																										*/
/*Frag 13: endsas																															*/
/*------------------------------------------------------------------------------------------------------------------------------------------*/


/*Frag 1 : Macro : Options and clear the log*/
%macro options;

options mprint mlogic symbolgen;
dm log 'clear';

%mend;


/*Frag 2 : Macro : Library definitions*/
%macro lib_in_out_1_to_n;

%do i=1 %to %sysfunc(countw(&input_path.,"||"));
	libname in&i. "%scan(&input_path.,&i.,"||")";
%end;
libname out "&output_path.";

%mend;

%macro lib_in_out_n_to_1;

%do i=%sysfunc(countw(&input_path.,"||")) %to 1 %by -1;
	libname in&i. "%scan(&input_path.,&i.,"||")";
%end;
libname out "&output_path.";

%mend;


/*Frag 3 : Macro : Log and print*/
%macro print_log;

proc printto log="&output_path/merge_complete_Log.log" new;
/*proc printto;*/
run;
quit;

%mend;


/*Frag 4 : Macro : Sorting the input datasets by key variables and taking the name of the input datasets,
concatenating them together, so that they can be used in merge data step*/
%macro create_the_name_and_sort_for_sas;

/*Initialising a global macro variable <these_datasets>*/
%global these_datasets;

/*Creating the name and sorting*/
%do i=1 %to %sysfunc(countw(&input_path.,"||"));
	/*Concatenating the names of the input datasets together to use in SAS merge data step*/
	%let this_dataset = in&i..dataworking (in = a&i.);
	%let these_datasets = &these_datasets. &this_dataset.;
	%put &these_datasets.;
	/*Sorting the dataset by the key_variables selected*/
	proc sort data=in&i..dataworking;
		by &key_variables.;
		run;
%end;

%mend;


/*Frag 4a : Macro : Replace a1 by a2*/
%macro a1_by_a2;

/*Replace a1 by temp*/
data _null_;
	call symput("type_join",tranwrd("&type_join.","a1","temp"));
	run;

/*Replace a2 by a1*/
data _null_;
	call symput("type_join",tranwrd("&type_join.","a2","a1"));
	run;

/*Replace temp by a2*/
data _null_;
	call symput("type_join",tranwrd("&type_join.","temp","a2"));
	run;

%put &type_join.;

%mend;


/*Frag 5 : Macro : Merge datasets using SAS*/
%macro merge_sas;

data &new_dataset. (keep = &final_variables. &key_variables.);
    merge &these_datasets.;
    by &key_variables.;
    if &type_join.;
    run;

%mend;


/*Frag 6 : Macro : Many-many outer join using SQL*/
%macro merge_sql_outer_join;

/*Determine if the merge is full outer join (or) left outer join (or) right outer join*/
%if %index(&type_join.,a1 or a2) > 0 %then %do;
	%let type=full;
%end;
%else %if %index(&type_join.,a2) > 0 %then %do;
	%let type=right;
%end;
%else %if %index(&type_join.,a1) > 0 %then %do;
	%let type=left;
%end;

/*Create the necessary statements for merging and merge the datasets two at a time*/

/*Initialising a variable <firstDatasetName> to be used in the do loop below*/
%let firstDatasetName=in1.dataworking;

%do i=1 %to (%sysfunc(countw(&input_path.,"||"))-1);
	/*Creating the dataset names*/
	%let createDatasetName=temp&i.;
	%if (&i.+1) = %sysfunc(countw(&input_path.,"||")) %then %do;
		%let createDatasetName=&new_dataset.;
	%end;
	%let secondDatasetName=in%eval(&i.+1).dataworking;
	/*Creating selectStatement & onStatement*/
	%let comma=,;
	%let and=and;
	%let selectStatement=;
	%let onStatement=;
	%do k=1 %to %sysfunc(countw(&key_variables.," "));
		%if (&k.+1) > %sysfunc(countw(&key_variables.," ")) %then %do;
			%let comma=;
			%let and=;
		%end;
		%let tempVar = %scan(&key_variables.,&k.," ");
		%let selectStatement = &selectStatement. coalesce(a1.&tempVar.,a2.&tempVar.) as &tempVar.&comma.;
		%let onStatement = &onStatement. (a1.&tempVar. = a2.&tempVar.) &and.;
	%end;
	%put &selectStatement.;
	%put &onStatement.;
	/*Merging the datasets now*/
	proc sql;
		create table &createDatasetName. as
		select &selectStatement., *
		from &firstDatasetName. a1
		&type. join &secondDatasetName. a2
		on &onStatement.;
		quit;
	/*The variable below will be used in the next iteration of the loop*/
	%let firstDatasetName=&createDatasetName.;
%end;

%mend;


/*Frag 7 : Macro : Many-many inner join using SQL*/
%macro merge_sql_inner_join;

/*Initialising two variables <fromDatasetName> and <whereStatement> to be used in the do loops below*/
%let fromDatasetName=;
%let whereStatement=;

/*Creating fromDatasetName*/
%let comma=,;
%do i=1 %to %sysfunc(countw(&input_path.,"||"));
	%if (&i.+1) > %sysfunc(countw(&input_path.,"||")) %then %do;
		%let comma=;
	%end;
	%let fromDatasetName = &fromDatasetName. in&i..dataworking a&i. &comma.;
%end;

/*Creating whereStatement*/
%let and=and;
%do k=1 %to %sysfunc(countw(&key_variables.," "));
	%if (&k.+1) > %sysfunc(countw(&key_variables.," ")) %then %do;
		%let and=;
	%end;

	%let equalTo==;
	%do i=1 %to %sysfunc(countw(&input_path.,"||"));
		%if (&i.+1) > %sysfunc(countw(&input_path.,"||")) %then %do;
			%let equalTo=;
		%end;
		%let whereStatement = &whereStatement. a&i..%scan(&key_variables.,&k.," ") &equalTo.;
	%end;

	%let whereStatement = &whereStatement. &and.;
%end;

/*Merging the datasets now*/
proc sql;
	create table &new_dataset. as
	select *
	from &fromDatasetName.
	where (&whereStatement.);
	quit;

%mend;


/*Frag 8 : Macro : Get the common values from the input datasets*/

/*Frag 9 : Macro : Check if the merge is many-many or not*/

/*Frag 10 : Macro : Write the merged dataset in the output path and the CSV and completed.txt*/
%macro write_dataset;

/* Checking number of observations in dataset	*/
%let dset=&new_dataset.;
%let dsid = %sysfunc(open(&dset));
%let nobs =%sysfunc(attrn(&dsid,NOBS));
%let global_nobs = &nobs.;
%let rc = %sysfunc(close(&dsid));

%if &NOBS. =0 %then %do;
	data _null_;
		v1= " Merge not possible. Merge operation will result in a dataset with 0 observations.";
		file "&output_path./NO_OF_ROWS_IS_ZERO.txt";
		put v1;
		run;
%end;
%else %do;
	data out.&new_dataset. (keep = &final_variables.);
		set &new_dataset.;
		run;

	data _null_;
		v1= "MERGE_COMPLETED";
		file "&output_path./MERGE_COMPLETED.txt";
		put v1;
		run;
%end;

%mend;


/*Frag 11 : Macro : Rearrange the input datasets for SQL*/

/*Frag 12 : Calling all the macro(s)*/
%macro callit;

filename myfile "&output_path./NO_OF_ROWS_IS_ZERO.txt";
data _null_;	
	rc = fdelete('myfile') ;	
run;

%options;
%print_log;
%if %index(&type_join., not) > 0 %then %do;
	%lib_in_out_n_to_1;
	%a1_by_a2;
	%create_the_name_and_sort_for_sas;
	%merge_sas;
%end;
%else %do;
	%lib_in_out_1_to_n;
	%if %index(&type_join., and) > 0 %then %do;
		%merge_sql_inner_join;
	%end;
	%else %do;
		%merge_sql_outer_join;
	%end;
%end;

%if %sysfunc(exist(&new_dataset.)) %then %do;
	%write_dataset;
%end;
%mend;

%callit;
