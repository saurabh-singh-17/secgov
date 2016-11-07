*processbody;
%let completedTXTPath =  &output_path/VARMISS_GRP_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;

FILENAME MyFile "&output_path/VARMISS_GRP_COMPLETED.txt" ;

  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;

proc printto log="&output_path/varmiss_grp_Log.log";
run;
quit;
/*proc printto print="&output_path/varmiss_grp_Output.out";*/

libname out "&output_path";
%macro missvar_grp;
%if "&spec_char_button" = "true" %then %do;
proc sort data = in.&dataset_name.(keep=&var_name.) out = miss(rename = (&var_name = actual_name)) NODUPKEY;
	by &var_name.;
	where &var_name. is not missing;
	run;

data miss;
set miss;
retain unique_key;
unique_key = _n_;
run;

%end;
%mend missvar_grp;
%missvar_grp;
proc export data=miss
	outfile="&output_path/variable_missing_grp.csv"
	dbms =csv
	replace;
run;
data _NULL_;
		v1= "EDA - VARMISS_GRP_COMPLETED";
		file "&output_path/VARMISS_GRP_COMPLETED.txt";
		PUT v1;
run;
/*proc printto ; run ; quit;*/
/**/


proc datasets lib=work kill nolist;
quit;

