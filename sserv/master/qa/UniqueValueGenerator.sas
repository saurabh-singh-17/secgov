/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/UNIQUE_VALUES_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;

proc printto log="&output_path/UniqueValues_Log.log";
run;
quit;

proc printto print="&output_path/UniqueValues_Output.out";

dm log 'clear';
/*proc printto;*/
/*run;*/

libname in "&input_path.";
libname out "&output_path.";
proc import datafile = "&input_path./&filename." out=in.dataworking  DBMS=CSV replace ;
run;
quit;
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
	

		
	data _null_;
		call symput("var_list_new",cat("'",tranwrd("&var_list."," ","','"),"'"));
	run;

	%put &var_list_new.;

	proc contents data=out.temporary out=temp1;
	run;


/*	proc sql;*/
/*	create table tab as;*/
/*		select format,formatl into:format_chk separated by ",", :format_len separated by ","  from temp1 where name in (&var_list_new.);*/
/*	quit;*/
/**/
/*	%put &format_chk.;*/
/*	%put &format_len.;*/

	
	%do  i=1 %to %sysfunc(countw("&var_list."," "));
	%let current_var=%scan("&var_list.",&i.," ");
	proc sql;
	select format into:format_var from temp1 where name = "&current_var.";
	quit;
	proc sql;
	select formatl into:format_var_len from temp1 where name = "&current_var.";
	quit;
	%put &format_var.;
	%put &format_var_len.;
	data _null_;
	call symput("format_var",strip("&format_var."));
	run;
	%if "&format_var." ^= ""  %then %do;
		%if &format_var_len. ^= 0 %then %do;
		data _null_;
			call symput("format_final",cat(strip("&format_var."),strip("&format_var_len."),"."));
		run;
		%end;
		%else %do;
		data _null_;
			call symput("format_final",cat(strip("&format_var."),"."));
		run;
		%end;

		%put &format_final.;
		%put &current_var.;
			data temp;
			set out.temporary;
			new_var&i.=put(%scan("&var_list.",&i.," "),&format_final.);
		run;

		proc sort data=temp(keep=new_var&i.) out=uniq&i.(rename=(new_var&i.=%scan("&var_list.",&i.," "))) nodupkey;
			by new_var&i.;
		run;
		%end;
		%else %do;
			proc sort data=out.temporary(keep=&current_var.) out=uniq&i. nodupkey;
				by &current_var.;
				run;
		%end;
					
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

	%end;

%MEND uniqueValues1;
%uniqueValues1;
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
	

		
	data _null_;
		call symput("var_list_new",cat("'",tranwrd("&var_list."," ","','"),"'"));
	run;

	%put &var_list_new.;

	proc contents data=out.temporary out=temp1;
	run;


/*	proc sql;*/
/*	create table tab as;*/
/*		select format,formatl into:format_chk separated by ",", :format_len separated by ","  from temp1 where name in (&var_list_new.);*/
/*	quit;*/
/**/
/*	%put &format_chk.;*/
/*	%put &format_len.;*/

	
	%do  i=1 %to %sysfunc(countw("&var_list."," "));
	%let current_var=%scan("&var_list.",&i.," ");
	proc sql;
	select format into:format_var from temp1 where name = "&current_var.";
	quit;
	proc sql;
	select formatl into:format_var_len from temp1 where name = "&current_var.";
	quit;
	%put &format_var.;
	%put &format_var_len.;
	data _null_;
	call symput("format_var",strip("&format_var."));
	run;
	%if "&format_var." ^= ""  %then %do;
		%if &format_var_len. ^= 0 %then %do;
		data _null_;
			call symput("format_final",cat(strip("&format_var."),strip("&format_var_len."),"."));
		run;
		%end;
		%else %do;
		data _null_;
			call symput("format_final",cat(strip("&format_var."),"."));
		run;
		%end;

		%put &format_final.;
		%put &current_var.;
			data temp;
			set out.temporary;
			new_var&i.=put(%scan("&var_list.",&i.," "),&format_final.);
		run;

		proc sort data=temp(keep=new_var&i.) out=uniq&i.(rename=(new_var&i.=%scan("&var_list.",&i.," "))) nodupkey;
			by new_var&i.;
		run;
		%end;
		%else %do;
			proc sort data=out.temporary(keep=&current_var.) out=uniq&i. nodupkey;
				by &current_var.;
				run;
		%end;
					
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

	%end;

%MEND uniqueValues1;
%uniqueValues1;
