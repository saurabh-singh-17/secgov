/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &outputPath/MISSING_COMPLETED.txt;
%let textToReport=;

%macro missing;
      %let flagMissingPerc = false; /*false initiate*/

      %if &flagMissingPerc.=true %then %do;
            proc means data=group.bygroupdata nmiss;
                  output out=means;
                  var &dependentVariable. &independentVariables.;
                  run;

            proc transpose data=means out=means_trans(rename=(_NAME_=variable col1=nmiss) drop=col2 col3 col4 col5);
                  run;

            /*obtaining the total frequency */
            proc sql ;
                  select nmiss into:freq from means_trans where variable='_FREQ_';
                  quit;
                  %put &freq.;

            /*calculating the missing count and missing percentage*/
            data missing;
                  set means_trans;
                  nmiss=&freq.-nmiss;
                  miss_per=nmiss/&freq.;
                  if variable="_TYPE_" or variable="_FREQ_" then delete;
                  run;

            /* exporting the missing data*/
            proc export data = missing
                  outfile = "&output_path./appData_missing.csv"
                  dbms = CSV replace;
                  run;
      %end;
	  %let textToReport=&textToReport. Missing complete;
%mend;
%missing;

data _null_;
      v1= "&textToReport.";
      file "&outputPath/MISSING_COMPLETED.txt";
      put v1;
      run;
 
