/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &&&datasetpath&i./EXPORT_COMPLETED.txt;

%macro export;

%do i=1 %to &count.;
	libname datapath "&&datasetPath&i.";
	
	data out.&&datasetname&i.;
		set datapath.&app_datasetname.;
		run;

	data _NULL_;
		v1= "EDA - DATE_CHECK_COMPLETED";
		file "&&&datasetpath&i./EXPORT_COMPLETED.txt";
		PUT v1;
	run;
%end;

%mend export;
%export;


	
	


proc datasets lib=work kill nolist;
quit;

