/*------------------------------------------------------------------------------------------------------------------------------------------*/
/*Sample Parameters Required*/
/*------------------------------------------------------------------------------------------------------------------------------------------*/
/*%let codePath=/product-development/murx///SasCodes//8.7.2;*/
/*%let output_path=/product-development/murx///projects/Nida_Sampling_New-10-Sep-2014-12-25-13/1/randomSampling;*/
/*%let input_path=/product-development/murx///projects/Nida_Sampling_New-10-Sep-2014-12-25-13/1;*/
/*%let significance =0.05;*/
/*%let meandiff=122;*/
/*%let stddev=407.22511108;*/
/*%let power=0.8;*/
/*%let sampling_type=Two Sample Test;*/
/*%let sampling_variable=black_hispanic;*/
/*------------------------------------------------------------------------------------------------------------------------------------------*/
/*Macro to calculate the samplesize and export it as CSV*/
/*------------------------------------------------------------------------------------------------------------------------------------------*/
options mlogic mprint symbolgen;

%macro samplesize;
	/*parameter play*/
	%let c_file_csv_sample	    = samplesize;
	%let c_dataset_final	    = samplesize;
	%let c_txt_completed	    = samplesize_completed;
	%let c_txt_error            = error;
	%let c_file_log			    = &output_path./samplesize.log;
	%let c_file_delete	    	= &output_path./&c_txt_completed..txt#
		&output_path./&c_txt_error..txt#
		&output_path./samplesize.log#
		&output_path./&c_file_csv_sample..csv;

	/*Delete Files*/
	%do tempi = 1 %to %sysfunc(countw(%str(&c_file_delete.), %str(#)));
		%let c_file_delete_now = %sysfunc(compress(%scan(%str(&c_file_delete.), &tempi., %str(#))));
		filename myfile "&c_file_delete_now.";

		data _null_;
			rc = fdelete('myfile');
		run;

	%end;

	dm log 'clear' output;

	/*	Log file*/
		proc printto log="&c_file_log." new;
		run;
	
		quit;
/*	proc printto;*/
/*	run;*/
/**/
/*	quit;*/

	/*Libraries*/
	libname in "&input_path.";
	libname out "&output_path.";

	%if "&sampling_type." = "One Sample Test" %then
		%do;

			proc means data=in.dataworking;
				var &sampling_variable.;
				output mean=mean out=out_means;
			run;

			quit;

			data _null_;
				set out_means;
				call symput("mean",mean);
			run;

			%put &mean.;
		%end;

	ods output Output=&c_dataset_final.;

	proc power;
		%if "&sampling_type." = "One Sample Test" %then
			%do;
				onesamplemeans 
					mean=&mean.
					ntotal = .
			%end;
		%else
			%do;
				twosamplemeans
					meandiff = &meandiff.
					npergroup=.
			%end;

		power = &power.
			stddev = &stddev.
			alpha=&significance.;
	run;

	quit;

	/*	data _null_;*/
	/*		set &c_dataset_final.;*/
	/**/
	/*		if Error ^= "" then*/
	/*			call symput("error_file",Error);*/
	/*	run;*/
	data &c_dataset_final.;
		set &c_dataset_final.

			%if "&sampling_type." = "Two Sample Test" %then
				%do;
					(rename=(NPerGroup=NTotal))
				%end;
			;
			if Error ^= "" then
				call symput("error_file",Error);
			keep NTotal;
	run;

	%if %symexist(error_file) %then
		%do;

			data _null_;
				v1= "Sample Size can't be calculated for the given parameters. Please change the values and try again.";
				file "&output_path./&c_txt_error..txt";
				put v1;
			run;

			%symdel error_file;
			%goto the_end;
		%end;

	proc export data=&c_dataset_final. outfile="&output_path./&c_file_csv_sample..csv" dbms=csv replace;
	run;

	data _null_;
		v1= "completed sample size";
		file "&output_path./samplesize_completed.txt";
		put v1;
	run;

	quit;

	%the_end:
%mend;

/*Calling the above defined macro*/
%samplesize;
;