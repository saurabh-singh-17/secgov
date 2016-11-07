/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path./CHART_COMPLETED.txt;
/* VERSION : 1.4.1 */

options mprint mlogic symbolgen mfile ;
FILENAME MyFile "&output_path./GENERATE_FILTER_FAILED.txt" ;

  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;

proc printto log="&output_path/AllChartCodeNew_Log.log";
run;
quit;
	
/*proc printto print="&output_path/AllChartCodeNew_Output.out";*/
	
libname in "&input_path.";
%let dataset_name=in.dataworking;
data in.bygroupdata;
	set &dataset_name.;
	run;
libname out "&output_path.";


%macro pie_chart();

/*DYNAMIC FILTER*/
	%if "&flag_filter." = "true"  %then %do;
		%let whr=;
		%let dataset_name=out.temporary;

		/*call SAS code for dynamic filtering*/
		%include %unquote(%str(%'&filterCode_path./dynamicFiltering.sas%')); 
	%end;

/*#########################################################################################################################################################*/



/* get the relevent contents */
	proc contents data = &dataset_name(keep = &grp_vars &stacked_vars &xaxis_vars) out = contents(keep = name type);
		run;

/* create macro variables */
	data _null_;
		set contents;
		call symput ("grp_varlist" , catx("," , scan("&grp_vars",1) , scan("&grp_vars",2),scan("&grp_vars",3)) );
		call symput ("xaxis_varlist" , catx("," , scan("&xaxis_vars",1) , scan("&xaxis_vars",2),scan("&xaxis_vars",3)) );
		call symput ("stacked_varlist",catx(",",scan("&stacked_vars",1),scan("&stacked_vars",2),scan("&stacked_vars",3)));
		run;
	%put &grp_varlist ;	
	

/* loop to create dataset for each y_vars, one at a time */
	
	/* if metric is not blank */
	%if "&metric" ^= "" %then %do;	
		%if "&grp_vars" = "" and "&stacked_vars" = "" %then %do;
			proc sql;
				create table grp_varlist as
				select &xaxis_varlist	
				%do i = 1 %to &num_yvars.;
					%if "%scan(&metric,&i)" ^= "percentage" %then %do;
						,%scan(&metric,&i)(%scan(&yaxis_vars,&i)) as value&i.
					%end;
					%else %if "%scan(&metric,&i)" = "percentage" %then %do;
						,(sum(CASE WHEN %scan(&yaxis_vars,&i) = %scan(&perc_level,&i,"!!") then 1 else 0 end))/count(*) as value&i. FORMAT=12.3
					%end;
				%end; 
				from &dataset_name
				group by &xaxis_varlist
				;
				quit;
		%end;
	
		%if "&grp_vars" = "" and "&stacked_vars" ^= "" %then %do;
			proc sql;
				create table grp_varlist as
				select &stacked_varlist,&xaxis_varlist
				%do i = 1 %to &num_yvars.;
					%if "%scan(&metric,&i)" ^= "percentage" %then %do;
						,%scan(&metric,&i)(%scan(&yaxis_vars,&i)) as value&i.
					%end;
					%else %if "%scan(&metric,&i)" = "percentage" %then %do;
						,(sum(CASE WHEN %scan(&yaxis_vars,&i) = %scan(&perc_level,&i,"!!") then 1 else 0 end))/count(*) as value&i. FORMAT=12.3
					%end;
				%end; 
				from &dataset_name
				group by &xaxis_varlist,&stacked_varlist
				;
				quit;
		%end;
		%if "&grp_vars" ^= "" and "&stacked_vars" = "" %then %do;
        	proc sql;
				create table grp_varlist as
				select &grp_varlist,&xaxis_varlist
				%do i = 1 %to &num_yvars.;
					%if "%scan(&metric,&i)" ^= "percentage" %then %do;
						,%scan(&metric,&i)(%scan(&yaxis_vars,&i)) as value&i.
					%end;
					%else %if "%scan(&metric,&i)" = "percentage" %then %do;
						,(sum(CASE WHEN %scan(&yaxis_vars,&i) = %scan(&perc_level,&i,"!!") then 1 else 0 end))/count(*) as value&i. FORMAT=12.3
					%end;
				%end;
				from &dataset_name
				group by &grp_varlist,&xaxis_varlist
				;
				quit;
		%end;
		%if "&grp_vars" ^= "" and "&stacked_vars" ^= "" %then %do;
        	proc sql;
				create table grp_varlist as
				select &grp_varlist,&stacked_varlist,&xaxis_varlist
				%do i = 1 %to &num_yvars.;
					%if "%scan(&metric,&i)" ^= "percentage" %then %do;
						,%scan(&metric,&i)(%scan(&yaxis_vars,&i)) as value&i.
					%end;
					%else %if "%scan(&metric,&i)" = "percentage" %then %do;
						,(sum(CASE WHEN %scan(&yaxis_vars,&i) = %scan(&perc_level,&i,"!!") then 1 else 0 end))/count(*) as value&i. FORMAT=12.3
					%end;
				%end;
				from &dataset_name
				group by &grp_varlist,&xaxis_varlist,&stacked_varlist
				;
				quit;
		%end;
	%end;

	/*if metric is blank*/
	%else %do;
		/*if metric is blank and colourby_vars do not exist*/
		%if "&colourby_vars"  = "" %then %do;
			%if "&grp_vars" = "" and "&stacked_vars" = "" %then %do;
				proc sql;
					create table grp_varlist as
					select &xaxis_varlist	
					%do i = 1 %to &num_yvars.;
						,%scan(&yaxis_vars,&i.) as value&i.
					%end; 
					from &dataset_name
					group by &xaxis_varlist
					;
					quit;
			%end;
		
			%if "&grp_vars" = "" and "&stacked_vars" ^= "" %then %do;
				proc sql;
					create table grp_varlist as
					select &stacked_varlist,&xaxis_varlist
					%do i = 1 %to &num_yvars.;
						,%scan(&yaxis_vars,&i.) as value&i.
					%end;  
					from &dataset_name
					group by &xaxis_varlist,&stacked_varlist
					;
					quit;
			%end;
			%if "&grp_vars" ^= "" and "&stacked_vars" = "" %then %do;
	        	proc sql;
					create table grp_varlist as
					select &grp_varlist,&xaxis_varlist
					%do i = 1 %to &num_yvars.;
						,%scan(&yaxis_vars,&i.) as value&i.
					%end; 
					from &dataset_name
					group by &grp_varlist,&xaxis_varlist
					;
					quit;
			%end;
			%if "&grp_vars" ^= "" and "&stacked_vars" ^= "" %then %do;
	        	proc sql;
					create table grp_varlist as
					select &grp_varlist,&stacked_varlist,&xaxis_varlist
					%do i = 1 %to &num_yvars.;
						,%scan(&yaxis_vars,&i.) as value&i.
					%end; 
					from &dataset_name
					group by &grp_varlist,&xaxis_varlist,&stacked_varlist
					;
					quit;
			%end;
		%end;
		/*if metric is blank and colourby_vars exist*/
		%else %do;
			%if "&grp_vars" = "" %then %do;
				proc sql;
					create table grp_varlist as 
					select &xaxis_varlist,&colourby_vars
					%do i = 1 %to &num_yvars.;
						,%scan(&yaxis_vars,&i.) as value&i.
					%end; 
					from &dataset_name 
					group by &xaxis_varlist
					;
					quit;
			%end;
			%else %do;
				proc sql;
					create table grp_varlist as 
					select &xaxis_varlist,&grp_varlist,&colourby_vars
					%do i = 1 %to &num_yvars.;
						,%scan(&yaxis_vars,&i.) as value&i.
					%end; 
					from &dataset_name 
					;
					quit;
			%end;
		%end;
   	%end;



/* count the number of x_vars */
	%let count_x = 1;
	%do %until (not %length(%scan(&xaxis_vars,&count_x)));
		%let counter = %eval(&count_x.);

		%let count_x = %eval(&count_x.+1);
	%end;

	%put &counter;

	%if &counter. = 1 %then %do;
		%let dsid = %sysfunc(open(grp_varlist));
			%let varnum = %sysfunc(varnum(&dsid,&xaxis_vars.));
			%let vartyp = %sysfunc(vartype(&dsid,&varnum)); /* variable type */
			%let rc = %sysfunc(close(&dsid));
		%put &vartyp;
	%end;

	%if &counter. = 1 %then %do;
		%if &vartyp. = N %then %do;
			%let sort_order = N;
		%end;
		%if &vartyp. = C %then %do;
			%let sort_order = C;
		%end;
	%end;
	%else %do;
		%let sort_order = C;
	%end;

	%if &sort_order. = N %then %do;
		proc sort data = grp_varlist(keep=&xaxis_vars.) out = x_vars(rename=(&xaxis_vars.=xaxis_flag)) nodupkey;
			by &xaxis_vars.;
			run;
	%end;


/*get the number of numeric variables*/
	proc sql noprint;
		select count(*) into :num_varcnt from contents where type = 1 %if &sort_order. = N %then %do; and strip(lowcase(name)) ^= lowcase("&xaxis_vars.") %end;;
		quit;
	%put &num_varcnt.;

	%if %eval(&num_varcnt.) ^= 0 %then %do;
		data _null_;
			set contents;
			suffix = put(_n_,8.);
			call symput (cats("num_var",suffix),compress(name));
			where type = 1 %if &sort_order. = N %then %do; and strip(lowcase(name)) ^= lowcase("&xaxis_vars.") %end;;
			run;
		%put &num_var1 &num_var2;

		data grp_varlist;
			set grp_varlist;
			%do j = 1 %to &num_varcnt.;
				&&num_var&j..1 = put(&&num_var&j.,best.);
				drop &&num_var&j.;
				rename &&num_var&j..1 = &&num_var&j.;
			%end;
			run;
	%end;

	data column_chart %if &sort_order. ^= N %then %do;(drop = &xaxis_vars.) %end;;
		set grp_varlist;
		%if "&grp_vars" ^= "" %then %do;
			array aa(*) &grp_vars;
			grp_flag = catx("_" , of aa[*]);
			drop &grp_vars.;
		%end;
		%if "&stacked_vars" ^= "" %then %do;
			array bb(*) &stacked_vars;										
			stacked_flag = catx("_" , of bb[*]);
		%end;
		%if &sort_order. = C %then %do;
			array cc(*) &xaxis_vars;
			xaxis_flag = catx("_", of cc[*]);
		%end;
		%if &sort_order. = N %then %do;
			rename &xaxis_vars. = xaxis_flag;
		%end;
		run;

	%if "&colourby_vars" ^= "" %then %do;
		data column_chart;
			set column_chart(rename = (&colourby_vars. = colourby_flag));
			run;
	%end;


	%if "&stacked_vars" ^= "" %then %do;
		%if "&grp_vars" ^= "" %then %do;
			proc sort data = column_chart out = column_chart;
				by grp_flag xaxis_flag;
				run;
				quit;

/*			data columnchart;*/
/*				set column_chart;*/
/*				run;*/
/**/
/*			libname column xml "&output_path/column_chart1.xml";*/
/*			data column.column_chart;*/
/*				retain grp_flag xaxis_flag;*/
/*				set column_chart;*/
/*				run; */
		%end;

		%else %do;
			proc sort data = column_chart out = column_chart;
				by xaxis_flag;
				run;
				quit;

/*			data columnchart;*/
/*				set column_chart;*/
/*				run;*/
/**/
/*			libname column xml "&output_path/column_chart1.xml";*/
/*				data column.column_chart;*/
/*					retain xaxis_flag;*/
/*					set column_chart;*/
/*					run; */
		%end;
	%end;

/*	%else %do;*/
/*		libname column xml "&output_path/column_chart1.xml";*/
/*		data column.column_chart;*/
/*			set column_chart;*/
/*			run;*/
/*	%end;*/



	%if "&grp_vars" ^= "" %then %do;
		proc sort data = column_chart(keep = grp_flag) out = dist_grp_flag nodupkey;
			by grp_flag;
			run;
		
		libname pie1 xml "&output_path/grp_values_list.xml";
		data pie1.grp_values_list;
			set dist_grp_flag;
			run; 

		data dist_grp_flag;
			 set dist_grp_flag;
			 if grp_flag = "" then grp_flag="-";
			 run;

		proc export data = dist_grp_flag
			outfile = "&output_path/grp_values_list.csv"
			dbms = CSV replace;
			run;
	%end;

	%if "&stacked_vars" ^= "" %then %do;
		libname pie1 xml "&output_path/stackedvalues_list.xml";
		proc sort data = column_chart(keep = stacked_flag) out = dist_stacked_flag nodupkey;
			by stacked_flag;
			run;

/*		proc transpose data = dist_stacked_flag out = dist_stacked_flag1;*/
/*			id stacked_flag ;*/
/*			run;*/
/**/
/*		proc contents data = dist_stacked_flag1 out = stackedlist1(keep = NAME where = (NAME ^= "_NAME_"));*/
/*			run;*/
/*			quit;*/
/**/
/*		data pie1.stacked_values_list;*/
/*			set stackedlist1;*/
/*			run;*/

		data pie1.stacked_values_list;
			set dist_stacked_flag(rename=(stacked_flag=NAME));
			run;


		data stacked_values_list;
			 set pie1.stacked_values_list;
			 if NAME = "" then NAME="-";
			 run;

		proc export data = stacked_values_list
			outfile = "&output_path/stackedvalues_list.csv"
			dbms = CSV replace;
			run;
	%end;

	%if "&colourby_vars" ^= "" %then %do;
		libname pie1 xml "&output_path/colourvalues_list.xml";
		proc sort data = column_chart(keep = colourby_flag) out = dist_colour_flag nodupkey;
			by colourby_flag;
			run;

		data pie1.coloured_values_list;
			set dist_colour_flag;
			run; 
		proc export data = pie1.coloured_values_list
			outfile = "&output_path/colourvalues_list.csv"
			dbms = CSV replace;
			run;
	%end;
	
	data column_chart;
      set column_chart;
      %if "&grp_vars" ^= "" %then %do;
            if grp_flag = "" then grp_flag="-";
      %end;
	  %if "&stacked_vars" ^= "" %then %do;
			if stacked_flag = "" then stacked_flag="-";
			if &stacked_vars. ="" then &stacked_vars.="-";
	  %end;
      if xaxis_flag = "" then xaxis_flag="-";
      if value1 = "" then value1="-";
	  run;

    options missing="-";
	proc export data = column_chart
		outfile="&output_path/column_chart.csv" 
		dbms=csv replace; 
		run;	

	%if &sort_order. = C %then %do;
		proc sort data = column_chart(keep=xaxis_flag) out = x_vars nodupkey;
				by xaxis_flag;
				run;
	%end;
	%if "&binned_xvar." = "true" %then %do;
		data x_vars;
			set x_vars;
			if index(xaxis_flag, ">") > 0 then dummy_var = input(scan(xaxis_flag,-1, ">"),best12.) + 1; 
				else if index(xaxis_flag, "<") > 0 then dummy_var = input(scan(xaxis_flag,-1, "<"),best12.) - 1; 
				else dummy_var = input(scan(xaxis_flag,2, "-"),best12.); 
			run;

		proc sort data = x_vars out = x_vars(drop=dummy_var);
			by dummy_var;
			run;

		data x_vars;
			set x_vars;
			if xaxis_flag ="" then xaxis_flag="-";
			run;
	%end;
	
%mend pie_chart;
%pie_chart;

	
	proc export data = x_vars
		outfile = "&output_path/xaxis_variables.csv"
		dbms = CSV replace;
		run;


	data _NULL_;
		v1= "CHART_COMPLETED";
		file "&output_path./CHART_COMPLETED.txt";
		PUT v1;
	run;

/*ENDSAS;*/



