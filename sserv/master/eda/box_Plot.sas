/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path./CHART_COMPLETED.txt;
options mprint mlogic  symbolgen mfile;

proc printto log="&output_path/boxPlot_log.log";
run;
quit;
/*proc printto print="&output_path./boxPlot_Output.out";*/

libname in "&input_path.";
libname out "&output_path.";

%MACRO boxplot;
	%if "&grp_vars." ^= "" %then %do;
		data _null_;
			call symput("grps", tranwrd("&grp_vars", " ", ","));
			call symput("cat_grp", tranwrd("&grp_vars", " ", ",'_',"));
			run;

		data temp (drop=&grp_vars);
			set in.dataworking (keep = &var_list &grp_vars);
			distinct_grps = cats(&cat_grp.);
			run;

		/*get distinct combinations of grp vars into a XML*/
		libname groups xml "&output_path./distinct_groups.xml";
		proc sql;
			create table groups.distinct_grps as
			select distinct distinct_grps from temp;
			quit;
	%end;

	%if "&grp_vars." = "" %then %do;
		data temp;
			set in.dataworking(keep=&var_list.);
			run;
	%end;

/*get a xml for varlist*/
libname varlist xml "&output_path./variables_list.xml";
proc contents data = temp(keep=&var_list) out = varlist.variables(keep=name) varnum;
	run;


/*boxplot*/
%let i = 1;
%do %until (not %length(%scan(&var_list, &i)));
	proc univariate data = temp; 
		%if "&grp_vars." ^= "" %then %do; class distinct_grps; %end;
		var %scan(&var_list, &i);
		output out = boxplot_&i. pctlpts = 0 25 50 75 100 pctlpre=p_ mean = box_mean ;
		quit;

	data boxplot_&i.;
		retain attributes;
		set boxplot_&i.;
		length attributes $32.;
		attributes = "%scan(&var_list, &i)";
		run;

	%if "&i." = "1" %then %do;
		data boxplot;
			set boxplot_&i.;
			run;
	%end;
	%else %do;
		data boxplot;
			set boxplot boxplot_&i.;
			run;
	%end;
	%let i = %eval(&i.+1);
%end;
%MEND boxplot;
%boxplot;

libname outbox xml "&output_path./box_plot.xml";
data outbox.boxplot;
	set boxplot;
	run;

	
/* Flex uses this file to test if the code has finished running */
data _NULL_;
	v1= "EDA- boxPlot_COMPLETED";
	file "&output_path./CHART_COMPLETED.txt";
	PUT v1;
	run;

endsas;


