/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/EVENT_INDICATOR_VARIABLE_COMPLETED.txt;
option mprint mlogic symbolgen mfile ;


proc printto log="&output_path./EventIndicatorVariable_Log.log";
run;
quit;
/*proc printto print="&output_path./EventIndicatorVariable_Output.out";*/

libname in "&input_path";
libname out "&output_path";

libname input xml "&input_xml.";
data input_dates;
	set input.xml_dates;
	run;

proc contents data = input_dates out = contents_dates(keep=name);
	run;

proc sql;
	select name into :date_vars separated by " " from contents_dates;
	quit;

data input_dates;
	set input_dates;
	format &date_vars. 8.;
	run;


%MACRO eventVarCreation;

%let i =1;
%do %until (not %length(%scan(&date_vars, &i)));
	
	proc sql;
		select %scan(&date_vars, &i) into :slots_date&i. separated by " " from input_dates
		where %scan(&date_vars, &i) ^= .;
		quit;

	%put &&slots_date&i.;

	%let i =%eval(&i.+1);
%end;


data out.temp (drop=base_date);
	set in.dataworking(keep=&date_var. primary_key_1644);

	base_date = &date_var.;
	format base_date 8.;

	%let i = 1;
	%do %until (not %length(%scan(&date_vars, &i)));
		%let j = 1;
		%do %until (not %length(%scan(&&slots_date&i., &j, " ")));
			%if "&j." = "1" %then %do;
				if %scan(&&slots_date&i., &j, " ") <= &date_var. <= %scan(&&slots_date&i., %eval(&j.+1), " ") then &prefix.event&i._&date_var. = 1;
					else &prefix.event&i._&date_var. = 0;
			%end;
			%else %do;
				if &prefix.event&i._&date_var. = 0 then do;
					if %scan(&&slots_date&i., &j, " ") <= &date_var. <= %scan(&&slots_date&i., %eval(&j.+1), " ") then &prefix.event&i._&date_var. = 1;
						else &prefix.event&i._&date_var. = 0;
				end;
			%end;
			%let j = %eval(&j.+2);
		%end;
		%let i = %eval(&i.+1);
	%end;
	run;
				
%MEND eventVarCreation;
%eventVarCreation;

proc sort data = out.temp;
 	by primary_key_1644;
	run;

proc sort data = in.dataworking;
 	by primary_key_1644;
	run;


data in.dataworking;
	merge out.temp(in=a) in.dataworking(in=b);
	by primary_key_1644;
	if a or b;
	run;

/*restriction for the no of rows in the output csv*/
	%macro rows_restriction4;
	%let dsid = %sysfunc(open(out.temp));
		%let nobs=%sysfunc(attrn(&dsid,nobs));	
		%let rc = %sysfunc(close(&dsid));
	%put &nobs.;

	%if &nobs.>6000 %then %do;
	proc surveyselect data=out.temp out=out.temp method=SRS
		  sampsize=6000 SEED=1234567;
		  run;
	%end;
%mend rows_restriction4;
%rows_restriction4;

data out.temp (drop = primary_key_1644);
	set out.temp;
	run;

proc export data = out.temp
	outfile = "&output_path/eventIndicatorVariable_subsetViewpane.csv"
	dbms = CSV replace;
	run;


proc contents data = out.temp(drop=&date_var.) out = contents_temp(keep=name rename=(name=new_varname));
	run;

libname newvar xml "&output_path./eventIndicatorVariable_new_varname.xml";
data newvar.new_varname;
	set contents_temp;
	run;


/*/*delete the unrequired datasets*/*/
/*proc datasets library = out;*/
/*	delete temp;*/
/*	run;*/;
%include %unquote(%str(%'&genericCode_path./datasetprop_update.sas%'));

data _null_;
	v1= "EVENT_INDICATOR_VARIABLE_COMPLETED";
	file "&output_path/EVENT_INDICATOR_VARIABLE_COMPLETED.txt";
	put v1;
	run;


/*ENDSAS;*/




	


