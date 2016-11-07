/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/TIMESERIES_ADVANCED_NEW_VARIABLE_SAVED_COMPLETED.txt;
options mprint mlogic symbolgen mfile;

proc printto;
run;

dm log 'clear';

libname in "&input_path.";
libname out "&output_path.";

%macro save_variable;

%let var_list = %substr(&var_list.,1,24);
proc sort data = in.dataworking out = in.dataworking;
by primary_key_1644;
run;

proc sort data = out.savetsv out = out.savetsv;
by primary_key_1644;
run;

data in.dataworking(rename = (SC = &prefix._&var_list._SC newVar = &prefix._&var_list.));
merge in.dataworking out.savetsv;
by primary_key_1644;
run;	

data save_var(keep = &var_list. );
set in.dataworking;
run;

/*	enhancement	*/
%if %sysfunc(exist(out.savevar)) %then %do;
data save_var;	
set in.dataworking(keep = &var_list. &prefix._&var_list._SC);
run;			 
%end;

proc export data =  save_var	outfile = "&output_path./saveVar.csv"	dbms = CSV replace;
run;
%mend save_variable;
%save_variable;

/* Flex uses this file to test if the code has finished running */
data _null_;
v1= "MODELING - TIMESERIES_ADVANCED_NEW_VARIABLE_SAVED_COMPLETED";
file "&output_path/TIMESERIES_ADVANCED_NEW_VARIABLE_SAVED_COMPLETED.txt";
PUT v1;
run;
