/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/UNIQUE_VALUES_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;

proc printto log="&output_path/UniqueValues_Log.log";
run;
quit;
/*proc printto print="&output_path/UniqueValues_Output.out";*/


libname in "&input_path.";
libname out "&output_path.";

/*subset the input dataset*/
data out.temp;
	set in.dataworking (keep = &var_list.);
	run;
FILENAME MyFile "&output_path/UNIQUE_VALUES_COMPLETED.txt" ;

  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;

%MACRO uniquevalues1log;

%let i = 1;
%do %until (not %length(%scan(&var_list, &i)));

    /*obtain unique values for each variable*/
    proc sql;
        create table uniq&i. as
        select distinct %scan(&var_list, &i) from out.temp;
        quit;

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

    %let i = %eval(&i+1);
%end;

%MEND uniquevalues1log;
%uniquevalues1log;

/*CSV export*/
 proc export data = out.output
	outfile="&output_path/uniqueValues.csv"
	dbms=CSV replace;
	run;

/*delete unrequired datasets*/
proc datasets library = out;
	delete output temp;
	run;

	
/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "UNIQUE_VALUES_COMPLETED";
	file "&output_path/UNIQUE_VALUES_COMPLETED.txt";
	put v1;
run;


ENDSAS;




