/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/MODELING_OUTLIER_TREATMENT_PREVIEW_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;

proc printto log="&output_path./ModelingOutlierTreatment_Log.log";
run;
quit;
/*proc printto print="&output_path./ModelingOutlierTreatment.out";*/

libname main "&input_path.";
libname in "&inter_output_path.";
libname out "&output_path.";

FILENAME MyFile "&output_path./MODELING_OUTLIER_TREATMENT_PREVIEW_COMPLETED.txt" ;

  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;
/*put-in primary key*/
data main.dataworking;
	set main.dataworking;
	primary_key_1644 = _n_;
	run;


/*subset only the outlier values*/
data preview_outdata;
	set in.outdata (where = (&flag_var. >=  %sysevalf(&cutoff_val.)));
	run;


/*sort for merging*/
proc sort data = preview_outdata out = preview_outdata;
	by &dependent_var. &independent_var.;
	run;

proc sort data = main.dataworking out = main.dataworking;
	by &dependent_var. &independent_var.;
	run;


/*merge-back the subsetted dataset with the main dataset*/
data preview_output;
	merge preview_outdata(in=a keep = &dependent_var. &independent_var.) main.dataworking(in=b);
	by &dependent_var. &independent_var.;
	if a;
	run;

/*de-sort the main dataset*/
proc sort data = preview_output out = preview_output(drop = primary_key_1644 grp:);
	by primary_key_1644;
	run;


/*CSV export*/
proc export data = preview_output
	outfile="&output_path/modeling_outlierTreatment_preview.csv" 
	dbms=CSV replace; 
	run;


/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "MODELING_OUTLIER_TREATMENT_PREVIEW_COMPLETED";
	file "&output_path/MODELING_OUTLIER_TREATMENT_PREVIEW_COMPLETED.txt";
	put v1;
	run;


ENDSAS;


