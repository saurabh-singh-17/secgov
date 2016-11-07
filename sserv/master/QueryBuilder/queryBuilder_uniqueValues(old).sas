*processbody;
%let completedTXTPath =  &output_path/uniqueValues.txt;
options mprint mlogic symbolgen mfile ;

FILENAME MyFile "&output_path/uniqueValues.txt" ;

  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;

proc printto log="&output_path/uniqueValues.log";
run;
quit;
/*proc printto print="&output_path/varmiss_grp_Output.out";*/
libname in "&input_path.";
libname out "&output_path";
%macro missvar_grp;

proc sort data = in.&dataset_name.(keep=&var_name.) out = miss NODUPKEY;
	by &var_name.;
	where &var_name. is not missing;
	run;

proc export data=miss
	outfile="&output_path/uniqueValues.csv"
	dbms =csv
	replace;
run;


%mend missvar_grp;
%missvar_grp;

data _NULL_;
		v1= "EDA - VARMISS_GRP_COMPLETED";
		file "&output_path/uniqueValues.txt";
		PUT v1;
run;

proc datasets lib=work kill nolist;
quit;

