/*Successfully converted to SAS Server Format*/
*processbody;
options mprint mlogic symbolgen mfile;

/*------------------------------------------------------------------------------
Notes :
There is no completed txt for this code
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
Parameters Required
------------------------------------------------------------------------------*/

/*%let input_path=D:/temp;*/
/*%let output_path=D:/temp;*/
/*%let dependent_variable=geography;*/
/*%let event=north;*/
/*%let validationvar=XXX_1;*/
/*----------------------------------------------------------------------------*/
proc printto log="&output_path./Event_Percentage_Log.log";
run;
quit;

libname in "&input_path.";

%macro event_percentage;
	%let dsid = %sysfunc(open(in.dataworking));
	%let varnum_dependent = %sysfunc(varnum(&dsid., &dependent_variable.));
	%let vartype_dependent = %sysfunc(vartype(&dsid., &varnum_dependent.));
	%let rc = %sysfunc(close(&dsid.));

	%if "&vartype_dependent." = "C" %then %do;
	  %let event = "&event.";
	%end;

	proc freq data = in.dataworking %if "&validationvar." ^= "" %then %do; (where = (&validationvar. = 1)) %end;;
		table &dependent_variable. / out=out_proc_freq;
	run;
	quit;

	data _null_;
		set out_proc_freq;
		if &dependent_variable. = &event. then
			do;
				call symput("n_event", count);
				call symput("n_pc_event", percent);
			end;
		else
			do;
				call symput("n_nonevent", count);
				call symput("n_pc_nonevent", percent);
			end;
	run;

	data _null_;
		v1 = round(&n_pc_event., 0.01);
		file "&output_path./Event_Percentage.txt";
		put v1;
	run;

%mend event_percentage;

%event_percentage;