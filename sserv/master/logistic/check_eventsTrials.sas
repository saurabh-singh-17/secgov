/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path./CHECK_EVENTS_TRIALS_COMPLETED.txt;
/*VERSION # 1.0.1*/
options mprint mlogic symbolgen mfile;

proc printto log="&output_path./Check_EventsTrials_Log.log";
run;
quit;
	
/*proc printto print="&output_path./Check_EventsTrials_Output.out";*/
	


libname dsn "&dataset_path";


%MACRO chk_eventsTrials;
/*count the number of invalid observations*/
	proc logistic data = dsn.&dataset_name.;
		model &events_var./&trials_var.=;
	run;
	%put &syserr;
	/*put the result of validation check into TXT file*/
	%if &syserr > 6 %then %do;
		data _null_;
			v1= "INVALID";
			file "&output_path./check_eventsTrials.txt";
			put v1;
			run;
	%end;
	%else %do;
		data _null_;
			v1= "VALID";
			file "&output_path./check_eventsTrials.txt";
			put v1;
			run;
	%end;

%MEND chk_eventsTrials;
%chk_eventsTrials;


/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "EVENTS_TRIALS_CHECK_COMPLETED";
	file "&output_path./CHECK_EVENTS_TRIALS_COMPLETED.txt";
	put v1;
	run;

/*ENDSAS;*/




