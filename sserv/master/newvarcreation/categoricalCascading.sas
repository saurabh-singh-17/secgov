/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/CATEGORICAL_CASCADING_COMPLETED.txt;
options mprint mlogic  symbolgen mfile;

proc printto log="&output_path./Categorical_Cascading_Log.log";
run;
quit;
/*proc printto print="&output_path./Categorical_Cascading_Output.out";*/

libname in "&input_path.";
libname out "&output_path.";


libname grps xml "&input_xml_path.";
data grps_cascading;
	set grps.grps_cascading;
	run;

proc contents data = grps_cascading out = contents_grps (keep=name);
	run;

proc sql;
	select name into :grp_names separated by " " from contents_grps;
	quit;
FILENAME MyFile "&output_path./CATEGORICAL_CASCADING_COMPLETED.txt" ;

  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;
%MACRO categoricalCascading;

%let i = 1;
%do %until (not %length(%scan(&grp_names, &i)));
	proc sql;
		select %scan(&grp_names, &i) into :grp&i. separated by " " from grps_cascading;
		quit;

	%let dlm=%scan(&delimiter.,&i.,|);
	%put aparna &dlm.;
	data _null_;
		call symput("cat_grp&i.", tranwrd("&&grp&i..", " ", ',&dlm.,'));
		run;

	data in.dataworking;
		set in.dataworking;
		%scan(&newvar_list, &i) = cats(&&cat_grp&i.);
		run;
	%let i = %eval(&i.+1);
%end;

%MEND categoricalCascading;
%categoricalCascading;

/*proc sort data = in.dataworking out = in.dataworking;*/
/*	by &newvar_list.;*/
/*	run;*/

data temp;
	set in.dataworking (keep = &newvar_list.);
	run;

%macro rows_restriction2;
	%let dsid = %sysfunc(open(temp));
		%let nobs=%sysfunc(attrn(&dsid,nobs));	
		%let rc = %sysfunc(close(&dsid));
	%put &nobs.;

	%if &nobs.>6000 %then %do;
	proc surveyselect data=temp out=temp method=SRS
		  sampsize=6000 SEED=1234567;
		  run;
	%end;
%mend rows_restriction2;
%rows_restriction2;

proc export data = temp
	outfile = "&output_path./categoricalCascading_viewPane.csv"
	dbms = csv replace;
	run;

%include %unquote(%str(%'&genericCode_path./datasetprop_update.sas%'));
/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "CATEGORICAL_CASCADING_COMPLETED";
	file "&output_path/CATEGORICAL_CASCADING_COMPLETED.txt";
	put v1;
	run;






