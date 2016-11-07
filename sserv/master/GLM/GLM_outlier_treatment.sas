/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/MODELING_OUTLIER_TREATMENT_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;


proc printto log="&output_path./ModelingOutlierTreatment_Log.log";
run;
quit;
/*proc printto print="&output_path./ModelingOutlierTreatment.out";*/


libname main "&input_path.";
libname in "&inter_output_path.";
libname out "&output_path.";

FILENAME MyFile "&output_path./MODELING_OUTLIER_TREATMENT_COMPLETED.txt" ;

  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;

  %macro macro_outliertreatment;
/*flag the specified variable depending on cut-off value*/
data outdata;
	retain &flag_name.;
	set in.outdata;

	if &flag_var. < %sysevalf(&cutoff_val.) then &flag_name. = 0;
		else if &flag_var. >=  %sysevalf(&cutoff_val.) then &flag_name. = 1;

	run;


	
	%let dsid = %sysfunc(open(outdata));
	%let nobs =%sysfunc(attrn(&dsid,NOBS));
	%let rc = %sysfunc(close(&dsid));
	%if &NOBS. < 7 %then %do;
		data _null_;
      		v1= "There are less than 7 observations in the subsetted dataset hence cannot perform modeling";
      		file "&output_path./INSUFFICIENT_OBSERVATIONS_CONSTRAINT.txt";
      		put v1;
			run;
		endsas;
	%end;

/*sort for merging*/
proc sort data = work.outdata out = work.outdata out=options;
	by primary_key_1644;;
	run;


/*merge-back the subsetted dataset with the main dataset*/
data main.bygroupdata;
	merge work.outdata(in=a keep = &flag_name. primary_key_1644) main.bygroupdata(in=b);
	by primary_key_1644;
	if a or b;
	run;

/*de-sort the main dataset*/
proc sort data = main.bygroupdata out=options;
	by primary_key_1644;
	run;

%mend;
%macro_outliertreatment;


/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "MODELING_OUTLIER_TREATMENT_COMPLETED";
	file "&output_path/MODELING_OUTLIER_TREATMENT_COMPLETED.txt";
	put v1;
	run;


ENDSAS;




