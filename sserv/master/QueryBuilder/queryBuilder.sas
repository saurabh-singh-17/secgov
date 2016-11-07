*processbody;
option mprint mlogic symbolgen mfile;
dm log 'clear';

proc printto log="&output_path/view_DATASETS_Log.log";
run;
quit;
/*proc printto print="&output_path./view_DATASETS_Output.out";*/

libname in "&input_path.";
libname out "&output_path.";

%macro query_view;
/* Checking number of observations in dataset	*/
	%let dset=in.&dataset_name.;
		%let dsid = %sysfunc(open(&dset));
		%let nobs =%sysfunc(attrn(&dsid,NOBS));
		%let rc = %sysfunc(close(&dsid));
		%put nobs;
		data num;
			_FREQ_ = &NOBS.;
			run;
			
	/*CSV export*/		
		 proc export data = num
			outfile="&output_path./Nobs.csv"
			dbms=CSV replace;
			run;

%if "&view_type."="sequential" %then %do;

	%if "&flag." = "true" %then %do;
		data subset;
			set in.&dataset_name.;
			if _n_ >= 600 then delete;
			run;
	%end;

	%else %do;
		data subset;
			set in.&dataset_name.;
			if &start_row.<= _n_ <= &end_row. then delete;
			run;
	%end;

%end;


%if "&view_type."="random" %then %do;

	proc surveyselect data=in.&dataset_name. out=subset method=SRS
	  	sampsize=%if &nobs. > 500 %then %do; 500 %end; 
				 %else %do; &nobs. %end; 	
		SEED=1234567;
	  	run;

/*	data subset;*/
/*		set in.&dataset_name;*/
/*		primary_key_1644=_n_;*/

%end;


%if "&view_type."="unique" %then %do;
	%if &NOBS. =0
		%then %do;

		data _null_;
      		v1= "There are zero observations in the dataset";
      		file "&output_path./Zero_Observations.txt";
      		put v1;
			run;
	%end;

	%else %do;

	proc contents data= in.&dataset_name out=dataset;
		run;

	proc sql;
		select NAME into : var_list separated by ' ' from dataset;
		run;
		quit;
	%put &var_list.;

		%let i = 1;
		%do %until (not %length(%scan(&var_list., &i)));
		    /*obtain unique values for each variable*/
		   	proc sort data=in.&dataset_name.(keep=%scan(&var_list., &i)) out=uniq&i. nodupkey;
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

		%if "&flag."= "true" %then %do;
		data subset;
			set out.output;
			if _n_ >= 600 then delete;
			run;
		%end;

		%else %do;
			data subset;
				set out.output;
				if &start_row. <= _n_ <= &end_row. then delete;
				run;
		%end;

	%end;

%end;
/*CSV export*/
		 proc export data = work.subset
			outfile="&output_path./subset_data.csv"
			dbms=CSV replace;
			run;
%mend;
%query_view;




data _null_;
	v1= "view_DATASETS_COMPLETED";
	file "&output_path/view_DATASETS_COMPLETED.txt";
	put v1;
	run;

	
