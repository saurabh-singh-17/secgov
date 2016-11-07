/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &outputPath/vif_COMPLETED.txt;
%let textToReport=;
%let output_path = &outputPath.;
%macro vif3;
	ods output ParameterEstimates = vif_params(keep= Variable VarianceInflation rename=(VarianceInflation=VIF));
	proc reg data = &datasetName.;
		model &actual. = &vifVariables./vif;
		/* checking if validation is being done*/
		%if "&validationVar." ^= "" %then %do;
		/* checking the type if build or validation*/
			%if "&validationType." = "build" %then %do;
			    where &validationVar. = 1;
				%put &validationType. &validationVar.;
			%end;
			%else %if "&validationType." = "validation" %then %do;
			    where &validationVar. = 0;
			%end;
		%end;
	run;
	quit;
	%exportCsv(libname=work,dataset=vif_params,filename=model);
	%let textToReport=&textToReport VIF computed;

	data _null_;
      v1= "&textToReport";
      file "&outputPath/vif_COMPLETED.txt";
      put v1;
      run;
%mend; 
%macro no_logistic_vif;
%let check_operation = %symexist(operation);
%put &check_operation.;
%if(&check_operation. and &operation ^= logistic) %then %do;
%vif3;
%end;
%mend no_logistic_vif;
%no_logistic_vif;
