/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path./dataset_refresh_completed.txt;
/*--------------------------------Parameters Required---------------------------------------*/
/*%let input_path='';                                  (input path where sas dataset is present)*/
/*%let dataset_name='';                                (name of the dataset)*/
/*%let output_path='';                                 (the output path of the csv)*/
/*------------------------------------------------------------------------------------------*/
proc printto log="&output_path/dataset_refresh_code_Log.log";
run;
quit;
	
libname in "&input_path.";
%put in.&dataset_name.;
%put &output_path/&dataset_name..csv;
PROC EXPORT DATA=in.&dataset_name.
	OUTFILE="&output_path/&dataset_name..csv"
	dbms=CSV replace;
	run;

data _null_;
	v1= "dataset refresh completed";
	file "&output_path./dataset_refresh_completed.txt";
	put v1;
	run;




proc datasets lib=work kill nolist;
quit;

