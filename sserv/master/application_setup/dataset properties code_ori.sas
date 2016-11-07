/*Successfully converted to SAS Server Format*/ *processbody; %let completedTXTPath =  &output_path./datset_prop_completed_completed.txt;
 /* VERSION 2.1 */
 options mprint mlogic symbolgen mfile;
 FILENAME MyFile "&output_path/dataset_properties_completed.txt" ;  DATA _NULL_ ;    rc = FDELETE('MyFile') ;  RUN ;
 proc printto log="&output_path/dataset_prop_output.log";
 run; quit; 	
 
 libname out "&output_path.";
 libname in "&input_path.";
 
 data &dataset_name.;
 	set in.&dataset_name.;
 	run;
 
 ods output members = properties(where=(lowcase(name)=lowcase("&dataset_name.")) keep=name obs vars FileSize);
 proc datasets details library = work;
 	run; 
 	quit ;
 
 /*libname prop xml "&output_path./dataset_properties.xml";*/
 data properties;
 set properties(rename =(name=file_name obs=no_of_obs vars=no_of_vars fileSize = file_size));
 format file_size 12.4;
 file_size = file_size;
 run;
 
 /*CSV export*/
  proc export data = properties
 	outfile="&output_path/dataset_properties.csv"
 	dbms=CSV replace;
 	run;
 
 /* flex uses this file to test if the code has finished running */
 data _null_;
 v1= "eda - datset_prop_completed_completed";
 file "&output_path./dataset_properties_completed.txt";
 put v1;
 run;  


proc datasets lib=work kill nolist;
quit;

