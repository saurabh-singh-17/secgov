/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/LAG_LEAD_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;

proc printto log="&output_path/LagLead_Log.log";
run;
quit;
/*proc printto print="&output_path/lagLead_Output.out";*/

libname in "&input_path.";
libname out "&output_path.";

%MACRO lag_lead;

/*varname modification, if required*/
%let i=1;
%do %until (not %length(%scan(&var_list,&i)));
data _null_;
	set in.dataworking;
	%let var_short=%substr(%scan(&var_list,&i),1,27);
	%put now you see...... var_short &var_short;
	%if "&i." = "1" %then %do;
		%if %length(%scan(&var_list,&i)) < 27 %then %do;
			call symput("new_list", "&prefix.%scan(&var_list,&i)");
		%end;
		%if %length(%scan(&var_list,&i)) >= 27 %then %do;
			call symput("new_list", "&prefix.&var_short");
		%end;
	%end;
	%else %do;
		%if %length(%scan(&var_list,&i)) < 27 %then %do;
			call symput("new_list", catx(" ", "&new_list.", "&prefix.%scan(&var_list,&i)"));
		%end;
		%if %length(%scan(&var_list,&i)) >= 27 %then %do;
			call symput("new_list", catx(" ", "&new_list.", "&prefix.&var_short"));
		%end;
	%end;
	run;
	%let i=%eval(&i+1);	
%end;

%if "&type." = "lag" %then %do;
	%let i = 1;
	%do %until (not %length(%scan(&var_list, &i)));
		%if "&i." = "1" %then %do;
			data out.output;
				retain %scan(&var_list, &i) %scan(&new_list, &i);
				set in.dataworking;
				%scan(&new_list, &i) = lag&lag.(%scan(&var_list, &i));
				run;
		%end;
		%else %do;
			data out.output;
				retain %scan(&var_list, &i) %scan(&new_list, &i);
				set out.output;
				%scan(&new_list, &i) = lag&lag.(%scan(&var_list, &i));
				run;
		%end;	
		%let i = %eval(&i.+1);
	%end;
%end;

%if "&type." = "lead" %then %do;
	%let i = 1;
	%do %until (not %length(%scan(&var_list, &i)));
		%if "&i." = "1" %then %do;
			data out.output;
				retain %scan(&var_list, &i) %scan(&new_list, &i);
				merge in.dataworking in.dataworking(keep=%scan(&var_list, &i) rename=(%scan(&var_list, &i)=%scan(&new_list, &i)) firstobs=%eval(&lead.+1));
				run;
		%end;
		%else %do;
			data out.output;
				retain %scan(&var_list, &i) %scan(&new_list, &i);
				merge out.output in.dataworking(keep=%scan(&var_list, &i) rename=(%scan(&var_list, &i)=%scan(&new_list, &i)) firstobs=%eval(&lead.+1));
				run;
		%end;
		%let i = %eval(&i.+1);
	%end;
%end;

/*subset to create view-pane csv*/
data sub_out;
	set out.output (keep = &var_list &new_list);
	run;

/*create dataset containing all new varnames*/
%let k = 1;
%do %until (not %length(%scan(&new_list, &k)));
	data newvar_temp;
		length new_varname $32;
		new_varname = "%scan(&new_list, &k)";
		run;

	%if "&k." = "1" %then %do;
		data newvar;
			set newvar_temp;
			run;
	%end;
	%else %do;
		data newvar;
			set newvar newvar_temp;
			run;
	%end;
	%let k = %eval(&k.+1);
%end;

%MEND lag_lead;
%lag_lead;

/*output*/
data in.dataworking;
	set out.output;
	run;


/*CSV output for view-pane*/
proc export data = sub_out
	outfile = "&output_path./lag_lead_subsetViewpane.csv"
	dbms = CSV replace;
	run;


/*create XML for new varnames*/
libname newvar xml "&output_path./lag_lead_new_varname.xml";
data newvar.new_varname;
	set newvar;
	run;


proc datasets library = out;
	delete output;
	run;

%include %unquote(%str(%'&genericCode_path./datasetprop_update.sas%'));
/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "LAG_LEAD_COMPLETED";
	file "&output_path/LAG_LEAD_COMPLETED.txt";
	put v1;
	run;


/*ENDSAS;*/




