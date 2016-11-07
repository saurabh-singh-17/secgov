/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &outputPath/EXPORT_RESIDUALS_COMPLETED.txt;
%let textToReport=;
%let output_path = &outputPath.;

%macro exportResiduals;
	proc export data=out.genmodoutput
    outfile="&outputPath./residuals.csv"
    dbms=csv replace;
    run;
	%let textToReport=&textToReport. Export Residuals Complete;
%mend;

%exportResiduals;

data _null_;
      v1= "&textToReport.";
      file "&outputPath/EXPORT_RESIDUALS_COMPLETED.txt";
      put v1;
      run;
 
