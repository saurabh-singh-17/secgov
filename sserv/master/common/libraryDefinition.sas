/*Successfully converted to SAS Server Format*/
*processbody;
options mprint mlogic symbolgen mfile;

proc printto log="&outputPath./&operation..log";
run;
quit;
      
/*proc printto print="&outputPath./&operation..out";*/
      

libname in "&inputPath.";
libname group "&groupPath.";
libname out "&outputPath.";
libname bias "&biasedpath.";