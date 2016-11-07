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
%let i=1;
%do %until (not %length(%scan(&var_name.,&i.," ")));

proc sort data = in.&dataset_name.(keep=%scan(&var_name.,&i.," ")) out = uniq&i. NODUPKEY;
	by %scan(&var_name.,&i.," ");
	where %scan(&var_name.,&i.," ") is not missing;
	run;

 /*merge the unique outputs for all the required variables*/

	%if "&i." = "1" %then %do;
		data out.output;
			set uniq&i.;
			run;
	%end;
	%else %do;
		data out.output;
		 	merge out.output uniq&i.;
			run;
	%end;
 proc datasets;
 delete uniq&i.;
run;
%let i = %eval(&i+1);
%end;


proc export data=out.output
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

