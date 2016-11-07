/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &outputPath/BYGROUPCREATE_COMPLETED.txt;
%let textToReport=;

%macro bygroupcreate;
	/* bygroupdata creation */
	%if &grpNo = 0 %then %do;
	    data group.bygroupdata;
	          set in.dataworking;
	          run;
	%end;
	%else %do;
	    data group.bygroupdata;
	          set in.dataworking (where = (GRP&grpNo._flag = "&grpFlag."));
	          run;
	%end;
	%let textToReport=&textToReport. By group data created;
%mend;

%bygroupcreate;

data _null_;
      v1= "&textToReport.";
      file "&outputPath/BYGROUPCREATE_COMPLETED.txt";      
	  put v1;
      run;