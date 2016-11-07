/*Successfully converted to SAS Server Format*/
*processbody;
%macro preGenmod;

/* If dependent is in events/trials form, create new variable 
	and set "actual" as that	*/

%if &formEventsTrials.=true %then %do;
		data &datasetName.;
			set &datasetName.;
			actual=&dependentVariable.;
		run;
		%let actual=actual;
	%end;
%put &actual;
%mend;
%preGenmod;
