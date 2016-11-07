/*Successfully converted to SAS Server Format*/
 *processbody;
 options mprint mlogic symbolgen mfile;

 

 proc printto log="&group_path./Bygroupdata_Log.log";

 run;
 quit;
       

 /*proc printto print="&group_path./Bygroupdata_output.out";*/

       

 

 libname in "&input_path.";

 libname group "&group_path.";

 

 

 %macro bygroup;

 

             %if %sysfunc(exist(group.bygroupdata)) %then %do;

                   %put exists;

             %end;

             %else %do;

                   %if "&grp_no" = "0" %then %do;

                         data group.bygroupdata;

                               set in.dataworking;

                               run;

                   %end;

                   %else %do;

                         data group.bygroupdata;

                               set in.dataworking (where = (GRP&grp_no._flag = "&grp_flag."));

                               run;

                   %end;

             %end;

 

 /*bygroupdata updation*/

       %if "&flag_bygrp_update." = "true" %then %do;

             proc sort data = in.dataworking out = in.dataworking;

                   by primary_key_1644;

                   run;

 

             proc sort data = &dataset_name. out = &dataset_name.;

                   by primary_key_1644;

                   run;

 

             data &dataset_name.;

                   merge &dataset_name.(in=a) in.dataworking(in=b);

                   by primary_key_1644;

                   if a;

                   run;

       %end; 

 %mend;

 %bygroup;

 
 
 data _null_;


       v1= "ByGroupDataCompleted";


       file "&outputPath/bygroupdata_COMPLETED.txt";


       put v1;


       run;  
proc datasets lib=work kill nolist; quit; 
