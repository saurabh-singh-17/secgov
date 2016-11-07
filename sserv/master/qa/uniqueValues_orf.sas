/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/UNIQUE_VALUES_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;

proc printto log="&output_path/UniqueValues_Log.log";
run;
quit;
/*proc printto print="&output_path/UniqueValues_Output.out";*/

dm log 'clear';
libname in "&input_path.";
libname out "&output_path.";

/*subset the input dataset*/
data out.temporary;
	set in.dataworking (keep = &var_list.);
	run;
	FILENAME MyFile "&output_path./GENERATE_FILTER_FAILED.txt" ;

  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;

%MACRO uniqueValues1;
/*DYNAMIC FILTER*/
	%if "&flag_filter." = "true" %then %do;
		%let dataset_name=out.temporary;
		%let whr=;
	 	/*call SAS code for dynamic filtering*/
		%include %unquote(%str(%'&filterCode_path./dynamicFiltering.sas%')); 
		%end;

/* Checking number of observations in dataset	*/
	%let dset=out.temporary;
		%let dsid = %sysfunc(open(&dset));
		%let nobs =%sysfunc(attrn(&dsid,NOBS));
		%let rc = %sysfunc(close(&dsid));
	%if &NOBS. =0
		%then %do;

		data _null_;
      		v1= "There are zero observations in the filtered dataset";
      		file "&output_path./GENERATE_FILTER_FAILED.txt";
      		put v1;
			run;

			/*delete unrequired datasets*/
		proc datasets library = out;
			delete temporary ;
			run;
	%end;
	%else %do;
	

		%let i = 1;
		%do %until (not %length(%scan(&var_list, &i)));
		    /*obtain unique values for each variable*/
		   	proc sort data=out.temporary(keep=%scan(&var_list, &i)) out=uniq&i. nodupkey;
				by %scan(&var_list, &i);
				run;
		    /*merge the unique outputs for all the required variables*/
		    %if "&i." = "1" %then %do;
		        data out.output;
		            set uniq&i.;
		            run;
		    %end;
		    %else %do;
		        data out.output;
		            merge out.output uniq&i.;
		            run;
		    %end;

			proc datasets;
				delete uniq&i.;
				run;
		    %let i = %eval(&i+1);
		%end;

		/*CSV export*/
		 proc export data = out.output
			outfile="&output_path/uniqueValues.csv"
			dbms=CSV replace;
			run;

		/*delete unrequired datasets*/
		proc datasets library = out;
			delete output ;
			run;
			quit;

			/* flex uses this file to test if the code has finished running */
			data _null_;
			v1= "UNIQUE_VALUES_COMPLETED";
			file "&output_path/UNIQUE_VALUES_COMPLETED.txt";
			put v1;
			run;

	%end;

%MEND uniqueValues1;
%uniqueValues1;


	



