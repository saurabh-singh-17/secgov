/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path./Variable_Renaming_completed.txt;
options mprint mlogic symbolgen mfile ;

FILENAME MyFile "&output_path./Variable_Renaming_completed.txt" ;

  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;

proc printto log="&output_path/Renaming_log.log";
run;
quit;
/*proc printto print="&output_path/Renaming_output.out";*/

libname out "&output_path";
libname newvar xml "&output_path/newvarlist.xml";

data newvar;
set newvar.newvarlist;
run;

data newvar1;
set newvar;
cond = catx(" = " , variable , new_name);
run;

proc sql noprint;
select cond into: rename_cond separated by " " from newvar1;quit;

data out.dataworking;
set out.dataworking(rename = (&rename_cond));
run;

/* flex uses this file to test if the code has finished running */
data _null_;
v1= "EDA - Variable Renaming Completed";
file "&output_path./Variable_Renaming_completed.txt";
put v1;
run;










proc datasets lib=work kill nolist;
quit;

