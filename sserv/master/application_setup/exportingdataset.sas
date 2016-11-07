/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path./EXPORT_COMPLETED.txt;
data out.&dataset_name.;
set in.&app_datasetname.;
run;



	data _NULL_;
		v1= "EDA - DATE_CHECK_COMPLETED";
		file "&output_path./EXPORT_COMPLETED.txt";
		PUT v1;
	run;
	
	


proc datasets lib=work kill nolist;
quit;

