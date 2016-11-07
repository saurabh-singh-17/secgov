/*Successfully converted to SAS Server Format*/
*processbody;
options mprint mlogic symbolgen mfile;

/*------------------------------------------------------------------------------
Notes :
Biased dataset is always created from in.dataworking
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
Parameters Required
------------------------------------------------------------------------------*/
/*%let codePath=/data22/IDev/Mrx//SasCodes//G8.4.5;*/
/*%let input_path=/data22/IDev/Mrx//projects/gooooooooooooood-12-Nov-2013-10-35-46/1;*/
/*%let output_path=/data22/IDev/Mrx//projects/gooooooooooooood-12-Nov-2013-10-35-46/1/0/1_1_1/logistic/1;*/
/*%let dependent_variable=channel_3;*/
/*%let event=1;*/
/*%let oversample_percent=25;*/
/*%let seed=324875;*/
/*%let validation_var=;*/
/*%let biased_datasetname=AcrossDataset_channel_3_25;*/
/*----------------------------------------------------------------------------*/

%let completedTXTPath =  &output_path./biasedSampleCreation_COMPLETED.txt;

proc printto log="&output_path/biasedSampleCreation.log";
run;
quit;

libname in "&input_path.";
libname out "&output_path.";

%MACRO biasedSample;
	%let dsid = %sysfunc(open(in.dataworking));
	%let varnum_dependent = %sysfunc(varnum(&dsid., &dependent_variable.));
	%let vartype_dependent = %sysfunc(vartype(&dsid., &varnum_dependent.));
	%let rc = %sysfunc(close(&dsid.));

	%if "&vartype_dependent." = "C" %then %do;
	  %let event = "&event.";
	%end;

	proc freq data = in.dataworking %if "&validation_var." ^= "" %then %do; (where = (&validation_var. = 1)) %end;;
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

	%let n_nonevent_required = %sysevalf(((100 - &oversample_percent.) / &oversample_percent.) * &n_event., floor);

	proc surveyselect data = in.dataworking 
							 %if "&validation_var." ^= "" %then %do; (where = (&validation_var. = 1 and &dependent_variable. ^= &event.))%end; 
							 %else %do; (where = (&dependent_variable. ^= &event.)) %end;
					  out = nonevent_random method = SRS sampsize = &n_nonevent_required. seed = &seed.;
	run;
	quit;

	data out.&biased_datasetname.;
		set in.dataworking 
    		%if "&validation_var." ^= "" %then %do; (where = (&validation_var. = 1 and &dependent_variable. = &event.))%end; 
		    %else %do; (where = (&dependent_variable. = &event.)) %end;
			nonevent_random;
	run;
%mend biasedSample;
%biasedSample;

/* Flex uses this file to test if the code has finished running */
data _null_;
	v1= "Logistic Regression - biasedSampleCreation_COMPLETED";
	file "&output_path./biasedSampleCreation_COMPLETED.txt";
	put v1;
run;