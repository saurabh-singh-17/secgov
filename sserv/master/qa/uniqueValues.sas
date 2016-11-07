/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/UNIQUE_VALUES_COMPLETED.txt;
options mprint mlogic symbolgen mfile;
dm log 'clear';

proc printto log="&output_path/UniqueValues_Log.log";
run;

quit;

/*proc printto;*/
/*run;*/
/*proc printto print="&output_path/UniqueValues_Output.out";*/
libname in "&input_path.";
libname out "&output_path.";

/*subset the input dataset*/
data out.temporary;
	set in.dataworking (keep = &var_list.);
run;

FILENAME MyFile "&output_path./GENERATE_FILTER_FAILED.txt";

DATA _NULL_;
	rc = FDELETE('MyFile');
RUN;

%MACRO uniqueValues1;
	/*DYNAMIC FILTER*/
	%if "&flag_filter." = "true" %then
		%do;
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

	%if &NOBS. =0 %then
		%do;

			data _null_;
				v1= "There are zero observations in the filtered dataset";
				file "&output_path./GENERATE_FILTER_FAILED.txt";
				put v1;
			run;

			/*delete unrequired datasets*/
			proc datasets library = out;
				delete temporary;
			run;

		%end;
	%else
		%do;

			data _null_;
				call symput("var_list_new",cat("'",tranwrd("&var_list."," ","','"),"'"));
			run;

			%put &var_list_new.;

			proc contents data=out.temporary out=temp1;
			run;

			%do  i=1 %to %sysfunc(countw("&var_list."," "));
				%let current_var=%scan("&var_list.",&i.," ");

				/*				data _null_;*/
				/*					call symput("format_final",cat(strip("&format_var."),strip("&format_var_len."),"."));*/
				/*				run;*/
				data temp;
					set out.temporary(keep=&current_var.);
					rename &current_var=new_var&i.;

					/*					new_var&i.=vvalue(%scan("&var_list.",&i.," "));*/
				run;

				proc sort data=temp out=uniq&i.(rename=(new_var&i.=%scan("&var_list.",&i.," "))) nodupkey;
					by new_var&i.;
				run;

				/*merge the unique outputs for all the required variables*/
				%if "&i." = "1" %then
					%do;

						data out.output;
							set uniq&i.;
						run;

					%end;
				%else
					%do;

						data out.output;
							merge out.output uniq&i.;
						run;

					%end;

				proc datasets;
					delete uniq&i.;
				run;

			%end;
		%end;

	/*CSV export*/
	proc export data = out.output
		outfile="&output_path./uniqueValues.csv"
		dbms=CSV replace;
	run;

	/*		delete unrequired datasets*/
	/* flex uses this file to test if the code has finished running */
	data _null_;
		v1= "UNIQUE_VALUES_COMPLETED";
		file "&output_path./UNIQUE_VALUES_COMPLETED.txt";
		put v1;
	run;

%MEND uniqueValues1;

%uniqueValues1;
;
;