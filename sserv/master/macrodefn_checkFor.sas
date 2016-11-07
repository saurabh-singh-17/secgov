/*Successfully converted to SAS Server Format*/
*processbody;
/*------------------------------------------------------------------------------------------------------------------------------*/
/*Parameters Required*/
/*------------------------------------------------------------------------------------------------------------------------------*/
/*libname in "D:/";*/
/*%let dataset=in.dataworking_new;*/
/*%let variables=Chiller_flag ACV;*/
/*%let checkFor=missing 4680000;*/
/*%let fileName = D:/error.txt;*/
/*------------------------------------------------------------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------------------------------------------------------*/
/*Macro to check if specified values exist in specified variables in the specified dataset*/
/*------------------------------------------------------------------------------------------------------------------------------*/
%macro checkFor(dataset,variables,checkFor,outputFileName);
	%let errorText=;

	%do i = 1 %to %sysfunc(countw(&checkFor.," "));
		%let current_checkFor = %scan(&checkFor.,&i.," ");

		data temp;
			set &dataset. (keep = &variables.);
			%do tempi = 1 %to %sysfunc(countw(&variables.," "));
				%let current_variable = %scan(&variables.,&tempi.," ");
				%if "&current_checkFor." = "negative" %then %do;
					if &current_variable. < 0 and &current_variable. ^= . then indicator&tempi. = 1;
				%end;
				%else %if "&current_checkFor." = "missing" %then %do;
					if &current_variable. = . then indicator&tempi. = 1;
				%end;
				%else %do;
					if &current_variable. = &current_checkFor. then indicator&tempi. = 1;
				%end;
			%end;
			run;

		proc sql;
			%do tempi = 1 %to %sysfunc(countw(&variables.," "));
				%let current_variable = %scan(&variables.,&tempi.," ");
				select sum(indicator&tempi.) into: sum from temp;
				%if &sum. > 0 %then %do;
					%let found_status = 1;
					%let errorText=&errorText. The variable &current_variable. has %trim(&sum.) number of values as &current_checkFor..;
				%end;
			%end;
			quit;
	%end;

	%if &found_status. = 1 %then %do;
		data _null_;
			text = "&errorText.";
			file "&outputFileName.";
			put text;
			run;
	%end;

	%put &errorText.;
%mend;
/*------------------------------------------------------------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------------------------------------------------------*/
/*Calling the macro*/
/*------------------------------------------------------------------------------------------------------------------------------*/
/*%checkFor(dataset=&dataset.,variables=&variables.,checkFor=&checkFor.,outputFileName=&fileName.);*/
/*------------------------------------------------------------------------------------------------------------------------------*/
