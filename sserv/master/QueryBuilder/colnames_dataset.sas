/*Parameters Required*/
/*%let input_path=E:\datasets C:\data E:\datasets;*/
/*%let output_path=E:\corr;*/
/*%let dataset_name = dataworking_linear_1 dataworking_new data12345; */

*processbody;
options mprint mlogic symbolgen mfile;
dm log 'clear';
proc printto log="&output_path./colnames_dataset_Log.log";
run;
quit;

libname out "&output_path.";
%macro child_dataset;
proc datasets lib = out;
delete child_dataset;
run;

%do i = 1 %to %eval(%sysfunc(countw(&dataset_name.))-1);
  %let data= %scan(&dataset_name.,%eval(&i.+1));
   %let lib= %scan(&input_path.,%eval(&i.+1)," ");

	libname in&i. "&lib.";

	 proc contents data = in&i..&data. out=tempwork_data&i.(keep= MEMNAME NAME rename=(MEMNAME=dataset_name NAME=colnames));
	 run;

	proc append base=out.child_dataset data=tempwork_data&i.;
	run;
	%end;
%mend;
%child_dataset;

%macro dataset_colnames;
proc datasets lib = out;
delete all_colnames key_variables;
run;

%do i = 1 %to %sysfunc(countw(&dataset_name.));
  %let data= %scan(&dataset_name.,&i.);
   %let lib= %scan(&input_path.,&i.," ");

	libname in&i. "&lib.";

	 proc contents data = in&i..&data. out=temp_data&i.(keep= MEMNAME NAME rename=(MEMNAME=dataset_name NAME=colnames));
	 run;

	proc append base=out.all_colnames data=temp_data&i.;
	run;

	 proc contents data = in&i..&data. out=temp&i.(keep=NAME rename=(NAME=colnames));
	 run;

/*	data not_used(keep=colnames);*/
/*	set out.all_colnames ;*/
/*	run;*/
/**/
/*	proc sort data =not_used out=aa nodupkey dupout=out.key_variables;*/
/*	by colnames;*/
/*	run;*/

%end;

data out.key_variables;
merge
%do k = 1 %to %sysfunc(countw(&dataset_name.));
	temp&k.(in=a&k.)
%end;;
by colnames;
if
%do m = 1 %to %eval(%sysfunc(countw(&dataset_name.))-1);
	a&m. and
%end;
a&m.;
run;
%mend;
 %dataset_colnames;
 proc export data = out.child_dataset
		outfile = "&output_path./child_dataset.csv"
		dbms = csv replace;
		run;
 proc export data = out.all_colnames
		outfile = "&output_path./all_colnames.csv"
		dbms = csv replace;
		run;

	proc export data = out.key_variables
		outfile = "&output_path./key_variables.csv"
		dbms = csv replace;
		run;

/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "SUBSETING_COMPLETED";
	file "&output_path/COLNAMES_DATASET_COMPLETED.txt";
	put v1;
run;
	
