/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path./CHART_COMPLETED.txt;
/*VERSION 1.3*/

options mprint mlogic symbolgen mfile ;


proc printto log="&output_path/BUBBLE_CHART_Log.log";
run;
quit;
	
/*proc printto print="&output_path/BUBBLE_CHART_Output.out";*/
	
libname in "&input_path.";
libname out "&output_path";
%let dataset_name=in.dataworking;
%macro bubble_chart;
%if "&flag_filter." = "true" %then %do;
	%let dataset_name=out.temporary;
		%let whr=;
	 	/*call SAS code for dynamic filtering*/
		%include %unquote(%str(%'&filterCode_path./dynamicFiltering.sas%')); 
%end;

%if "&grp_vars." ^= "" %then %do;

	proc contents data = &dataset_name (keep = &grp_vars.) out = contents(keep = name type);
		run;

	proc sql noprint;
		select count(*) into :num_varcnt from contents where type = 1;
		quit;

	%put &num_varcnt.;

	%if %eval(&num_varcnt.) ^= 0 %then %do;
		data _null_;
			set contents;
			suffix = put(_n_,8.);
			call symput (cats("num_var",suffix),compress(name));
			where type = 1;
			run;

		data out.temp;
			set &dataset_name(keep = &grp_vars &x_axis_var &y_axis_var &size_by_var);
			%do j = 1 %to &num_varcnt.;
				&&num_var&j..1 = put(&&num_var&j.,best.);
				drop  &&num_var&j.;
				rename &&num_var&j..1 = &&num_var&j.;
			%end;
			run;

		data out.temp (drop = &grp_vars.);
			set out.temp;
			array aa(*) &grp_vars ;
			grp_variable = catx("_" , of aa[*]);
			run;
	%end;

	%if %eval(&num_varcnt.) = 0 %then %do;
		data out.temp (drop = &grp_vars.);
			set &dataset_name(keep = &grp_vars &x_axis_var &y_axis_var &size_by_var);
			array aa(*) &grp_vars ;
			grp_variable = catx("_" , of aa[*]);
			run;
	%end;
%end;
%else %do;
	data out.temp;
		set &dataset_name(keep = &x_axis_var &y_axis_var &size_by_var);
		run;
%end;

/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/

%if "&y_axis_metric." = "" and "&size_by_metric" = "" %then %do;
	data out.bubble_out;
		set out.temp (rename = (&x_axis_var = x_axis_var &y_axis_var = y_axis_var &size_by_var = size_by_var));
		%if "&grp_vars." = "" %then %do;
			keep &x_axis_var &y_axis_var &size_by_var;
		%end;
		run;
%end;
/*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^*/

%if "&y_axis_metric." ^= "" and "&size_by_metric" ^= "" %then %do;
	%if "&grp_vars." ^= "" %then %do;
		proc sql;
		create table out.bubble_out as
		select grp_variable , &x_axis_var. as x_axis_var,	
					&y_axis_metric.(&y_axis_var.) as metric_Y ,
					&size_by_metric.(&&size_by_var.) as metric_S
		from out.temp
		group by grp_variable , &x_axis_var.
		;
		quit;
	%end;
	%else %if "&grp_vars." = "" %then %do;
		proc sql;
		create table out.bubble_out as
		select &x_axis_var. as x_axis_var,	
					&y_axis_metric.(&y_axis_var.) as metric_Y ,
					&size_by_metric.(&&size_by_var.) as metric_S
		from out.temp
		group by &x_axis_var.
		;
		quit;
	%end;
%end;
/*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^*/

%if "&y_axis_metric." = "" and "&size_by_metric" ^= "" %then %do;
	%if "&grp_vars." ^= "" %then %do;
		proc sql;
		create table out.bubble_out as
		select grp_variable , &x_axis_var. as x_axis_var ,	&y_axis_var. as y_axis_var,
					&size_by_metric.(&&size_by_var.) as metric_S
		from out.temp
		group by grp_variable , &x_axis_var.
		;
		quit;
	%end;
	%else %if "&grp_vars." = "" %then %do;
		proc sql;
		create table out.bubble_out as
		select &x_axis_var. as x_axis_var, &y_axis_var. as y_axis_var,	
					&size_by_metric.(&&size_by_var.) as metric_S
		from out.temp
		group by &x_axis_var.
		;
		quit;
	%end;
%end;

/*/*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^*/*/
/*                                                    CREATING XMLs                                                                  */;

/*main output*/
data out.bubble_out;
	set out.bubble_out;
	rename x_axis_var = xaxis_flag;
	rename metric_y  = value1;
	rename grp_variable = grp_flag;	
	run;

data out.bubble_out; 
   set out.bubble_out;
   array nums _numeric_;
   do over nums;
   if nums=. then nums=0;
   end;
   run;


/*libname out1 xml "&output_path/column_chart1.xml";*/
/*data out1.column_chart;*/
/*	set out.bubble_out;*/
/*	run;*/

   data out.bubble_out;
   set out.bubble_out;
      %if "&grp_vars" ^= "" %then %do;
            if grp_flag = "" then grp_flag="-";
      %end;
	  if metric_S ="" then metric_S="-";
      if xaxis_flag = "" then xaxis_flag="-";
      if value1 = "" then value1="-";
	  run;

options missing ="-";
PROC EXPORT DATA =  out.bubble_out
	OUTFILE="&output_path/column_chart.csv" 
	DBMS=CSV REPLACE; 
	RUN;


/*xvar CSV*/
proc sql;
	create table x_vars as
	select distinct xaxis_flag
	from out.bubble_out;
	quit;

proc sort data = x_vars;
	by xaxis_flag;
	run;

data x_vars;
	set x_vars;
	if xaxis_flag ="" then xaxis_flag="-";
	run;

proc export data = x_vars
	outfile = "&output_path/xaxis_variables.csv"
	dbms = CSV replace;
	run;

/*grp-values CSV*/
%if "&grp_vars." ^= "" %then %do;
	proc sql;
		create table dist_values as
		select distinct grp_flag
		from out.bubble_out;
		quit;

	libname out2 xml "&output_path/grp_values_list.xml";
	data out2.grp_values_list;
		set dist_values;
		run;

		data dist_values;
		set dist_values;
		if grp_flag = "" then grp_flag = "-";
		run;

	proc export data = dist_values
		outfile = "&output_path/grp_values_list.csv"
		dbms = CSV replace;
		run;
%end;

%mend bubble_chart;

%bubble_chart;

	data _NULL_;
		v1= "BUBBLE_CHART_COMPLETED";
		file "&output_path./CHART_COMPLETED.txt";
		PUT v1;
	run;




