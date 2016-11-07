/*changing double qoutes back to single in condition param*/
%let condition=%sysfunc(tranwrd(%str(&condition.),%str(%"),%str(%')));
/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/CONDITIONAL_NEWVAR_COMPLETED.txt;
options mprint mlogic symbolgen mfile;
dm log 'clear';
proc printto log="&output_path./conditional_newVar_Log.log";
run;
quit;
	
/*proc printto print="&output_path./conditional_newVar_Output.out";*/

libname in "&input_path.";
libname out "&output_path.";

%macro conditional_var;
proc sql;
create table &dataset_name. as
	select *,
		case 
			%do i=1 %to %sysfunc(countw(&condition.,"!!"));
				%let cond=%scan(&condition.,&i.,"!!");
				when &cond. then 
					%if "&var_type." ="string" %then "%scan(&value,&i.,"!!")";
					%else %if "&var_type." ="numeric" %then %scan(&value,&i.,"!!");
			%end;  
		end  as &var_name.
	from &dataset_name
	quit;

%mend conditional_var;
%conditional_var;

data newvar;
	set &dataset_name.(keep=&var_name.);
	run;
%macro rows_restriction4cnv;
	%let dsid = %sysfunc(open(newvar));
		%let nobs=%sysfunc(attrn(&dsid,nobs));	
		%let rc = %sysfunc(close(&dsid));
	%put &nobs.;

	%if &nobs.>6000 %then %do;
	proc surveyselect data=newvar out=newvar method=SRS
		  sampsize=6000 SEED=1234567;
		  run;
	%end;
%mend rows_restriction4cnv;
%rows_restriction4cnv;

proc export data = newvar
		outfile = "&output_path./newvar.csv"
		dbms = csv replace;
		run;
%include %unquote(%str(%'&genericCode_path./datasetprop_update.sas%'));
/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "CONDITIONAL_NEWVAR_CREATION_COMPLETED";
	file "&output_path/CONDITIONAL_NEWVAR_COMPLETED.txt";
	put v1;
run;


