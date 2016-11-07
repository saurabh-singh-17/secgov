options mprint mlogic symbolgen;

proc printto;
run;
quit;

/*variables used to later resolve to respective macros for metric calculation*/
%let sum=sql;
%let avg=sql;
%let min=sql;
%let max=sql;
%let count=sql;
%let std=sql;
%let unicou=unique_count;
%let none=no_metric;
%let y2d=y2d;
%let q2d=q2d;
%let m2d=m2d;
%let w2d=w2d;
%let pertot=perc_sum;
%let cum_perc=perc_sum;
%let couper=counts;
%let cumcou=counts;
%let cumcouper=counts;
%let cumcou_column=cum_freq;
%let cumcouper_column=cum_pct;
%let couper_column=percent;
%let pop=period_growth;
%let popp=period_growth_perc;
%let trendline=trend_line;
%let combined_flag=&flag_multiplemetric.;
%let append_yvar_counter=0;
%let slice_checking_param=0;

%macro libname_definer;
	libname in "&input_path.";
	libname out "&output_path.";
%mend libname_definer;

%macro dataset_intake;
	/*loop to set level and sublevel for combined metric calculation*/
	%if &slicebymode.=panel and %sysfunc(find(&level.,0))=0 %then
		%do;
			%if &level.= %then
				%do;
					%let level=0;
					%let sublevel=1_1_1;
					%global slice_checking_param;
					%let slice_checking_param=1;
				%end;
			%else
				%do;
					%let level=%sysfunc(catx(#,&level.,0));
					%let sublevel=%sysfunc(catx(#,&sublevel.,1_1_1));
					%let slice_checking_param=1;
				%end;
		%end;

	data ma_dataset;
		set in.dataworking;

		/*	columns set for rollup and metric(y2d,q2d,m2d,w2d)calculation*/
		grp0_flag="1_1_1";
		grpyear_flag=year(&date_var.);
		grpmonth_flag=month(&date_var.);
		grpqtr_flag=qtr(&date_var.);
		grpweek_flag=week(&date_var.)+1;

		/*		weeks can vary from 1-53,1-15 or 1-16.so do months from 1-12 and 1-4*/
		wk_in_mnth=intck('week',intnx('month',&date_var.,0),&date_var.)+1;
		wk_in_qtr=intck('week',intnx('quarter',&date_var.,0),&date_var.)+1;
		mnth_in_qtr=intck('month',intnx('quarter',&date_var.,0),&date_var.)+1;
	run;

%mend dataset_intake;

%macro format_changer(by_no,by_flag);
	%let x_no                 = &&&by_no..;
	%let x_flag               = &&&by_flag..;
	%let y_no                 = .;

	%do i=1 %to %sysfunc(countw(&x_no.,"#"));
		%let x_no_current          =    %scan("&x_no.",&i.,"#");
		%let x_no_previous         =    %scan("&x_no.",%eval(&i.-1),"#");
		%let x_flag_current        =    %scan("&x_flag.",&i.,"#");
		%put &x_flag_current.;

		%if &i.=1 %then
			%do;
				%let y_no               =    &x_no_current.;
				%let y_flag             =    &x_flag_current.;
			%end;
		%else
			%do;
				%let delimiter       =    #;

				%if &x_no_current.   =    &x_no_previous. %then
					%do;
						%let delimiter =    %str( );
					%end;

				%let y_no       =    %sysfunc(catx(&delimiter.,&y_no.,&x_no_current.));
				%let y_flag          =    %sysfunc(catx(&delimiter.,&y_flag.,&x_flag_current.));
			%end;
	%end;

	%let &by_no.              =    &y_no.;
	%let &by_flag.            =    &y_flag.;
	%put grp_no;
	%put grp_flag;
%mend format_changer;

%macro combinedmetric_appender;
	%let temp_var    = %sysfunc(tranwrd(&Combined_var.,|, ));
	%let temp_agg    = %sysfunc(tranwrd(&Combined_metric.,|, ));
	%put &temp_var.;

	%if &initial_len. =0 %then
		%do;
			%let selected_varlist =&temp_var.;
			%let metrics=&temp_agg.;
		%end;
	%else
		%do;
			%let selected_varlist  = %sysfunc(catx(%str( ),&selected_varlist.,&temp_var.));
			%let metrics  = %sysfunc(catx(%str( ),&metrics.,&temp_agg.));
		%end;

	%put &metrics.;
	%put &selected_varlist.;
%mend combinedmetric_appender;

%macro timeperiod_appender_year;
	/*to subset for mode "timeperiod", tp_flag changed to unique year values from the dataset*/
	proc sql;
		select unique(grpyear_flag)into: &tp_flag. separated by " " from ma_dataset;
	quit;

	%let &tp_no.=year;
%mend;

%macro timeperiod_appender_qtr;
	/*tp_flag set to possible quarter values*/
	%let &tp_no.=qtr;
	%let &tp_flag.=1 2 3 4;
%mend;

%macro timeperiod_appender_month;
	/*tp_flag set to possible month values*/
	%let &tp_no.=month;
	%let &tp_flag.=1 2 3 4 5 6 7 8 9 10 11 12;
%mend;

%macro timeperiod_appender_week;
	/*tp_flag set to possible week values*/
	%let &tp_no.=week;
	%let &tp_flag.=1 2 3 4 5 6 7 8 9 10 
		11 12 13 14 15 16 17 18 19 20 
		21 22 23 24 25 26 27 28 29 30
		31 32 33 34 35 36 37 38 39 40
		41 42 43 44 45 46 47 48 49 50
		51 52 53;
%mend;

%macro timeperiod_appender(tp_no,tp_flag,tp_level);
	/*macro used to set values to the variable "tp_flag" which can be used for subsetting if the chartby/sliceby mode is timeperiod*/
	%timeperiod_appender_&&&tp_level..;
%mend timeperiod_appender;

%macro param_player;
	%if &chartbymode.=panel %then
		%do;
			%format_changer(grp_no,grp_flag);
		%end;
	%else
		%do;
			%timeperiod_appender(grp_no,grp_flag,chartbylevel)
		%end;

	%if &slicebymode.=panel %then
		%do;
			%format_changer(level,sublevel);
		%end;
	%else
		%do;
			%timeperiod_appender(level,sublevel,slicebylevel)
		%end;

	%if &flag_multiplemetric.= true %then
		%do;
			%combinedmetric_appender;
		%end;
%mend param_player;

%macro chartby_want_creator;
	%global col_no want;
	%let CBN_temp      = %scan("&grp_flag.",&i.,"#");
	%let col_no_temp   = %scan("&grp_no.",&i.,"#");
	%let col_no         = %scan("&col_no_temp.",1," ");
	%let want          = %sysfunc(tranwrd(%str("&CBN_temp."),%str( ),%str(",")));
%mend;

%macro sliceby_want_creator;
	%global col_no_SBN want_sbn;
	%let SBN_temp= %scan("&sublevel.",&k.,"#");
	%let col_no_temp_SBN = %scan("&level.",&k.,"#");
	%let col_no_SBN = %scan("&col_no_temp_SBN.",1," ");
	%let want_SBN = %sysfunc(tranwrd(%str("&SBN_temp."),%str( ),%str(",")));
	%put &want_SBN.;
	%put &col_no_SBN.;
%mend;

%macro chartbymode_Panel_;
	chartBy =grp&col_no._flag;
	chartBy_grp_no= "&col_no.";
	chartBy_time_level = catx("_",chartBy_grp_no,chartBy);

	if grp&col_no._flag in (&want.) then
		output;
%mend;

%macro slicebymode_Panel_;
	sliceBy = grp&col_no_SBN._flag;
	sliceBy_grp_no= "&col_no_SBN.";
	sliceBy_time_level  = catx("_",sliceBy_grp_no,sliceBy);

	if grp&col_no_SBN._flag in(&want_SBN.) then
		output;
%mend;

%macro chartbymode_TimePeriod_week;
	chartBy_time_level = catx("_",grpyear_flag,grpqtr_flag,grpmonth_flag,grpweek_flag);

	if grp&col_no._flag in (&want.) then
		output;
%mend;

%macro slicebymode_TimePeriod_week;
	sliceBy_time_level = catx("_",grpyear_flag,grpqtr_flag,grpmonth_flag,grpweek_flag);

	if grp&col_no_sbn._flag in (&want_sbn.) then
		output;
%mend;

%macro chartbymode_TimePeriod_month;
	chartBy_time_level = catx("_",grpyear_flag,grpqtr_flag,grpmonth_flag);

	if grp&col_no._flag in (&want.) then
		output;
%mend;

%macro slicebymode_TimePeriod_month;
	sliceBy_time_level = catx("_",grpyear_flag,grpqtr_flag,grpmonth_flag);

	if grp&col_no_sbn._flag in (&want_sbn.) then
		output;
%mend;

%macro chartbymode_TimePeriod_qtr;
	chartBy_time_level = catx("_",grpyear_flag,grpqtr_flag);

	if grp&col_no._flag in (&want.) then
		output;
%mend;

%macro slicebymode_TimePeriod_qtr;
	sliceBy_time_level = catx("_",grpyear_flag,grpqtr_flag);

	if grp&col_no_sbn._flag in (&want_sbn.) then
		output;
%mend;

%macro chartbymode_TimePeriod_year;
	chartBy_time_level = grpyear_flag;

	if grp&col_no._flag in (&want.) then
		output;
%mend;

%macro slicebymode_TimePeriod_year;
	sliceBy_time_level = grpyear_flag;

	if grp&col_no_sbn._flag in (&want_sbn.) then
		output;
%mend;

%macro chartbysubsetting;
	%put &col_no.;

	data first_subset;
		set ma_dataset(where=(&date_var. ne .));
		format chartby_time_level $25.;
		informat chartby_time_level $25.;
		format sliceby_time_level $25.;
		informat sliceby_time_level $25.;

		%chartbymode_&chartByMode._&chartBylevel;
	run;

%mend;

%macro slicebysubsetting;

	data final_subset;
		set first_subset;

		%slicebymode_&sliceByMode._&sliceBylevel;
	run;

%mend;

%macro weekly;
	%global  uniq_r2 uniq_r3 uniq_r4;
	%let uniq_r1=week;
	%let uniq_r2=unique_r2;
	%let uniq_r3=unique_r3;
	%let uniq_r4=unique_r4;
	r1=grpweek_flag;
	r2=1;
	r3=1;
	r4=1;
%mend;

%macro monthly;
	%global  uniq_r2 uniq_r3 uniq_r4;
	%let uniq_r2=unique_r2;
	%let uniq_r3=unique_r3;
	%let uniq_r4=unique_r4;
	r1=grpmonth_flag;
	r2=1;
	r3=1;
	r4=1;
%mend;

%macro qtrly;
	%global  uniq_r2 uniq_r3 uniq_r4;
	%let uniq_r2=unique_r2;
	%let uniq_r3=unique_r3;
	%let uniq_r4=unique_r4;
	r1=grpqtr_flag;
	r2=1;
	r3=1;
	r4=1;
%mend;

%macro yearly;
	%global  uniq_r2 uniq_r3 uniq_r4;
	%let uniq_r2=unique_r2;
	%let uniq_r3=unique_r3;
	%let uniq_r4=unique_r4;
	r1=grpyear_flag;
	r2=1;
	r3=1;
	r4=1;
%mend;

%macro wam;
	%global  uniq_r2 uniq_r3 uniq_r4;
	%let uniq_r2=month;
	%let uniq_r3=year;
	%let uniq_r4=unique_r4;
	r1=wk_in_mnth;
	r2=grpmonth_flag;
	r3=grpyear_flag;
	r4=1;
%mend;

%macro waq;
	%global  uniq_r2 uniq_r3 uniq_r4;
	%let uniq_r2=qtr;
	%let uniq_r3=year;
	%let uniq_r4=unique_r4;
	r1=wk_in_qtr;
	r2=grpqtr_flag;
	r3=grpyear_flag;
	r4=1;
%mend;

%macro way;
	%global  uniq_r2 uniq_r3 uniq_r4;
	%let uniq_r2=unique_r2;
	%let uniq_r3=year;
	%let uniq_r4=unique_r4;
	r1=grpweek_flag;
	r2=1;
	r3=grpyear_flag;
	r4=1;
%mend;

%macro maq;
	%global  uniq_r2 uniq_r3 uniq_r4;
	%let uniq_r2=qtr;
	%let uniq_r3=year;
	%let uniq_r4=unique_r4;
	r1=mnth_in_qtr;
	r2=grpqtr_flag;
	r3=grpyear_flag;
	r4=1;
%mend;

%macro may;
	%global  uniq_r2 uniq_r3 uniq_r4;
	%let uniq_r2=unique_r2;
	%let uniq_r3=year;
	%let uniq_r4=unique_r4;
	r1=grpmonth_flag;
	r2=1;
	r3=grpyear_flag;
	r4=1;
%mend;

%macro qay;
	%global  uniq_r2 uniq_r3 uniq_r4;
	%let uniq_r2=unique_r2;
	%let uniq_r3=year;
	%let uniq_r4=unique_r4;
	r1=grpqtr_flag;
	r2=1;
	r3=grpyear_flag;
	r4=1;
%mend;

%macro none;
	%global  uniq_r2 uniq_r3 uniq_r4;
	%let uniq_r2=month;
	%let uniq_r3=qtr;
	%let uniq_r4=year;
	r1=&date_var.;
	r2=grpmonth_flag;
	r3=grpqtr_flag;
	r4=grpyear_flag;
%mend;

%macro rollup_loop;

	data final_data;
		set final_data;

		%if &rolluplevel.=none %then
			%do;
				format r1 mmddyy10.;
				informat r1 mmddyy10.;
			%end;

		/*		The following macro will set 3 variables namely yeardrop,rollcol2 and rollcol1 
			for respective rollup levels*/

		/*		where rollcol1 is the most granular level.*/
		/*		when no rollup is chosen it resolves to none*/
		%&rolluplevel.;
	run;

%mend;

%macro sql;
	/*macro to implement count,sum,avg,min,max,standard deviation*/
	ods output SQL_results = to_append_output;
	ods trace on;

	proc sql;
		select chartBy_time_level,sliceBy_time_level,r1,r2,r3,r4,
			combined_flag,yvars,&metric_agg_current.(&metric_var_current)as yvalue,
			metric_unique from final_data 
		group by chartBy_time_level,sliceBy_time_level,r1,r2,r3,r4,combined_flag,yvars,metric_unique;
	run;

	quit;

%mend;

%macro period_growth;

	proc sql;
		create table to_append_output as select chartBy_time_level,sliceBy_time_level,r1,r2,r3,r4,
			combined_flag,yvars,sum(&metric_var_current)as yvalue,
			metric_unique from final_data 
		group by chartBy_time_level,sliceBy_time_level,r1,r2,r3,r4,combined_flag,yvars,metric_unique;
	run;

	quit;

	%if "&Chartbymode."="panel" and "&Slicebymode."="panel" %then
		%do;

			proc sql;
				create table to_append_output as select a.*,b.yvalue as yvar_previous
					from to_append_output as a left join to_append_output as b 
						on a.chartby_time_level=b.chartby_time_level
						and a.sliceby_time_level=b.sliceby_time_level

					%if  &rolluplevel^=none %then
						%do;
							and  a.r1=b.r1
							and a.r3-1=b.r3
						%end;
					%else
						%do;
							and day(a.r1)=day(b.r1)
							and a.r3=b.r3
							and a.r4-1=b.r4
						%end;

					and  a.r2=b.r2;
			run;

			quit;

		%end;

	%if "&Chartbymode."^="panel" and "&Slicebymode."="panel" %then
		%do;

			proc sql;
				create table to_append_output as select a.*,b.yvalue as yvar_previous
					from to_append_output as a left join to_append_output as b 
						on substr(strip(a.chartby_time_level),5)=substr(strip(b.chartby_time_level),5)
						and a.sliceby_time_level=b.sliceby_time_level

					%if  &rolluplevel^=none %then
						%do;
							and  a.r1=b.r1
							and a.r3-1=b.r3
						%end;
					%else
						%do;
							and day(a.r1)=day(b.r1)
							and a.r3=b.r3
							and a.r4-1=b.r4
						%end;

					and  a.r2=b.r2;
			run;

			quit;

		%end;

	%if "&Chartbymode."="panel" and "&Slicebymode."^="panel" %then
		%do;

			proc sql;
				create table to_append_output as select a.*,b.yvalue as yvar_previous
					from to_append_output as a left join to_append_output as b 
						on a.chartby_time_level=b.chartby_time_level
						and substr(strip(a.sliceby_time_level),5)=substr(strip(b.sliceby_time_level),5)

					%if  &rolluplevel^=none %then
						%do;
							and  a.r1=b.r1
							and a.r3-1=b.r3
						%end;
					%else
						%do;
							and day(a.r1)=day(b.r1)
							and a.r3=b.r3
							and a.r4-1=b.r4
						%end;

					and  a.r2=b.r2;
			run;

			quit;

		%end;

	%if "&Chartbymode."^="panel" and "&Slicebymode."^="panel" %then
		%do;

			proc sql;
				create table to_append_output as select a.*,b.yvalue as yvar_previous
					from to_append_output as a left join to_append_output as b 
						on substr(strip(a.chartby_time_level),5)=substr(strip(b.chartby_time_level),5)
						and substr(strip(a.sliceby_time_level),5)=substr(strip(b.sliceby_time_level),5)

					%if  &rolluplevel^=none %then
						%do;
							and  a.r1=b.r1
							and a.r3-1=b.r3
						%end;
					%else
						%do;
							and day(a.r1)=day(b.r1)
							and a.r3=b.r3
							and a.r4-1=b.r4
						%end;

					and  a.r2=b.r2;
			run;

			quit;

		%end;

	data to_append_output(drop=yvalue yvar_previous rename=(yvalues=yvalue));
		set to_append_output;

		if yvar_previous="." then
			yvar_previous=0;
		yvalues=yvalue-yvar_previous;
	run;

%mend;

%macro period_growth_perc;

	proc sql;
		create table to_append_output as select chartBy_time_level,sliceBy_time_level,r1,r2,r3,r4,
			combined_flag,yvars,sum(&metric_var_current.)as yvalue,
			metric_unique from final_data 
		group by chartBy_time_level,sliceBy_time_level,r1,r2,r3,r4,combined_flag,yvars,metric_unique;
	run;

	%if "&Chartbymode."="panel" and "&Slicebymode."="panel" %then
		%do;

			proc sql;
				create table to_append_output as select a.*,b.yvalue as yvar_previous
					from to_append_output as a left join to_append_output as b 
						on a.chartby_time_level=b.chartby_time_level
						and a.sliceby_time_level=b.sliceby_time_level

					%if  &rolluplevel^=none %then
						%do;
							and  a.r1=b.r1
							and a.r3-1=b.r3
						%end;
					%else
						%do;
							and day(a.r1)=day(b.r1)
							and a.r3=b.r3
							and a.r4-1=b.r4
						%end;

					and  a.r2=b.r2;
			run;

			quit;

		%end;

	%if "&Chartbymode."^="panel" and "&Slicebymode."="panel" %then
		%do;

			proc sql;
				create table to_append_output as select a.*,b.yvalue as yvar_previous
					from to_append_output as a left join to_append_output as b 
						on substr(strip(a.chartby_time_level),5)=substr(strip(b.chartby_time_level),5)
						and a.sliceby_time_level=b.sliceby_time_level

					%if  &rolluplevel^=none %then
						%do;
							and  a.r1=b.r1
							and a.r3-1=b.r3
						%end;
					%else
						%do;
							and day(a.r1)=day(b.r1)
							and a.r3=b.r3
							and a.r4-1=b.r4
						%end;

					and  a.r2=b.r2;
			run;

			quit;

		%end;

	%if "&Chartbymode."="panel" and "&Slicebymode."^="panel" %then
		%do;

			proc sql;
				create table to_append_output as select a.*,b.yvalue as yvar_previous
					from to_append_output as a left join to_append_output as b 
						on a.chartby_time_level=b.chartby_time_level
						and substr(strip(a.sliceby_time_level),5)=substr(strip(b.sliceby_time_level),5)

					%if  &rolluplevel^=none %then
						%do;
							and  a.r1=b.r1
							and a.r3-1=b.r3
						%end;
					%else
						%do;
							and day(a.r1)=day(b.r1)
							and a.r3=b.r3
							and a.r4-1=b.r4
						%end;

					and  a.r2=b.r2;
			run;

			quit;

		%end;

	%if "&Chartbymode."^="panel" and "&Slicebymode."^="panel" %then
		%do;

			proc sql;
				create table to_append_output as select a.*,b.yvalue as yvar_previous
					from to_append_output as a left join to_append_output as b 
						on substr(strip(a.chartby_time_level),5)=substr(strip(b.chartby_time_level),5)
						and substr(strip(a.sliceby_time_level),5)=substr(strip(b.sliceby_time_level),5)

					%if  &rolluplevel^=none %then
						%do;
							and  a.r1=b.r1
							and a.r3-1=b.r3
						%end;
					%else
						%do;
							and day(a.r1)=day(b.r1)
							and a.r3=b.r3
							and a.r4-1=b.r4
						%end;

					and  a.r2=b.r2;
			run;

			quit;

		%end;

	data to_append_output(drop=yvalue yvar_previous rename=(yvalues=yvalue));
		set to_append_output;

		if yvar_previous="." then
			yvar_previous=0;

		if yvar_previous^=0 then
			yvalues=((yvalue-yvar_previous)*100/yvar_previous);
		else yvalues=.;
	run;

%mend;

%macro perc_sum;

	proc sql;
		create table to_append_output as select chartby_time_level,sliceby_time_level,r1,r2,r3,r4,combined_flag,yvars,
			metric_unique,sum(&metric_var_current) as yvalues from
			final_data 
		group by chartBy_time_level,sliceBy_time_level,r1,r2,r3,r4,combined_flag,yvars,metric_unique;
	quit;

	run;
	%&metric_agg_current._calculation;
%mend;

%macro cum_perc_calculation;

	data to_append_output;
		set  to_append_output;
		concat=catx("_",chartBy_time_level,sliceBy_time_level,r4,r3,r2);
	run;

	proc sort data=to_append_output;
		by concat  r1;
	run;

	quit;

	/*	by flag set to take the cumulative sum and thereby calculating yvalue*/
	data to_append_output(drop= concat count );
		set to_append_output;
		by concat;

		if first.concat then
			yvalue=yvalues;
		else yvalue+yvalues;
	run;

	quit;

	proc sql;
		create table perc_tot_merge as select chartby_time_level,sliceby_time_level,r2,r3,r4,combined_flag,yvars,
			metric_unique,sum(yvalues) as tot_val from to_append_output 
		group by chartBy_time_level,sliceBy_time_level,r2,r3,r4,combined_flag,yvars,metric_unique;
	quit;

	run;

	proc sql;
		create table to_append_output as select a.*,b.tot_val from 
			to_append_output as a left join perc_tot_merge as b
			on a.chartby_time_level=b.chartby_time_level
			and a.sliceby_time_level=b.sliceby_time_level
			and a.r2=b.r2 
			and a.r3=b.r3
			and a.r4=b.r4;
	quit;

	run;

	data to_append_output(drop=yvalues tot_val);
		set to_append_output;
		yvalue=(yvalue*100)/tot_val;
	run;

%mend;

%macro pertot_calculation;

	proc sql;
		create table perc_tot_merge as select chartby_time_level,sliceby_time_level,r2,r3,r4,combined_flag,yvars,
			metric_unique,sum(yvalues) as tot_val from to_append_output 
		group by chartBy_time_level,sliceBy_time_level,r2,r3,r4,combined_flag,yvars,metric_unique;
	quit;

	run;

	proc sql;
		create table to_append_output as select a.*,b.tot_val from 
			to_append_output as a left join perc_tot_merge as b
			on a.chartby_time_level=b.chartby_time_level
			and a.sliceby_time_level=b.sliceby_time_level
			and a.r2=b.r2 
			and a.r3=b.r3
			and a.r4=b.r4;
	quit;

	run;

	data to_append_output(drop=yvalues tot_val);
		set to_append_output;
		yvalue=(yvalues*100)/tot_val;
	run;

%mend;

%macro unique_count;
	/*macro to implement unique count*/
	ods output SQL_results = to_append_output;
	ods trace on;

	proc sql;
		select chartBy_time_level,sliceBy_time_level,r1,r2,r3,r4,
			combined_flag,yvars,count(unique yvalue)as yvalue,
			metric_unique from final_data 
		group by chartBy_time_level,sliceBy_time_level,r1,r2,r3,r4,combined_flag,yvars,metric_unique;
	run;

	quit;

%mend;

%macro y2d;
	/*for y2d implementation*/
	/*proc sql used to calculate sum of the variable at the rollup level*/
	proc sql;
		create table to_append_output as select chartBy_time_level,sliceBy_time_level,r1,r2,r3,r4,
			grpyear_flag,combined_flag,yvars,sum(yvalue)as count,
			metric_unique from final_data 
		group by chartBy_time_level,sliceBy_time_level,r1,r2,r3,r4,grpyear_flag,combined_flag,yvars,metric_unique;
	run;

	quit;

	/*concatinating the rollup variables by excluding the granular level for taking cumulative sum */
	data to_append_output;
		set  to_append_output;
		concat=catx("_",chartBy_time_level,sliceBy_time_level,grpyear_flag,put(r4,z5.),put(r3,z5.));
	run;

	proc sort data=to_append_output;
		by concat r2 r1;
	run;

	quit;

	/*by flag set to take the cumulative sum and thereby calculating yvalue*/
	data to_append_output(drop= concat count grpyear_flag);
		set to_append_output;
		by concat;

		if first.concat then
			yvalue=count;
		else yvalue+count;
	run;

	quit;

%mend;

%macro q2d;
	/*proc sql used to calculate sum of the variable at the rollup level*/
	proc sql;
		create table to_append_output as select chartBy_time_level,sliceBy_time_level,r1,r2,r3,r4,grpyear_flag,grpqtr_flag,
			combined_flag,yvars,sum(yvalue)as count,
			metric_unique from final_data 
		group by chartBy_time_level,sliceBy_time_level,r1,r2,r3,r4,grpyear_flag,grpqtr_flag,combined_flag,yvars,metric_unique;
	run;

	quit;

	/*concatinating the rollup variables by excluding the granular level for taking cumulative sum */
	data to_append_output;
		set  to_append_output;
		concat=catx("_",chartBy_time_level,sliceBy_time_level,grpyear_flag,grpqtr_flag,put(r4,z5.),put(r3,z5.));
	run;

	proc sort data=to_append_output;
		by concat r2 r1;
	run;

	quit;

	/*by flag set to take the cumulative sum and thereby calculating yvalue*/
	data to_append_output(drop= grpyear_flag grpqtr_flag concat count);
		set to_append_output;
		by concat;

		if first.concat then
			yvalue=count;
		else yvalue+count;
	run;

	quit;

%mend;

%macro m2d;
	/*proc sql used to calculate sum of the variable at the rollup level*/
	proc sql;
		create table to_append_output as select chartBy_time_level,sliceBy_time_level,r1,r2,r3,r4,grpyear_flag,grpqtr_flag,grpmonth_flag,
			combined_flag,yvars,sum(yvalue)as count,
			metric_unique from final_data 
		group by chartBy_time_level,sliceBy_time_level,r1,r2,r3,r4,grpyear_flag,grpqtr_flag,grpmonth_flag,combined_flag,yvars,metric_unique;
	run;

	quit;

	/*concatinating the rollup variables by excluding the granular level for taking cumulative sum */
	data to_append_output;
		set  to_append_output;
		concat=catx("_",chartBy_time_level,sliceBy_time_level,grpyear_flag,grpqtr_flag,grpmonth_flag,put(r4,z5.),put(r3,z5.));
	run;

	proc sort data=to_append_output;
		by concat r2 r1;
	run;

	quit;

	/*by flag set to take the cumulative sum and thereby calculating yvalue*/
	data to_append_output(drop= grpyear_flag grpqtr_flag grpmonth_flag concat count);
		set to_append_output;
		by concat;

		if first.concat then
			yvalue=count;
		else yvalue+count;
	run;

	quit;

%mend;

%macro w2d;
	/*proc sql used to calculate sum of the variable at the rollup level*/
	proc sql;
		create table to_append_output as select chartBy_time_level,sliceBy_time_level,r1,r2,r3,r4,grpyear_flag,grpqtr_flag,grpmonth_flag,grpweek_flag,
			combined_flag,yvars,sum(yvalue)as count,
			metric_unique from final_data 
		group by chartBy_time_level,sliceBy_time_level,r1,r2,r3,r4,grpyear_flag,grpqtr_flag,grpmonth_flag,grpweek_flag,combined_flag,yvars,metric_unique;
	run;

	quit;

	/*concatinating the rollup variables by excluding the granular level for taking cumulative sum */
	data to_append_output;
		set  to_append_output;
		concat=catx("_",chartBy_time_level,sliceBy_time_level,grpyear_flag,grpqtr_flag,grpmonth_flag,grpweek_flag,put(r4,z5.),put(r3,z5.));
	run;

	proc sort data=to_append_output;
		by concat r2 r1;
	run;

	quit;

	/*by flag set to take the cumulative sum and thereby calculating yvalue*/
	data to_append_output(drop= grpyear_flag grpqtr_flag grpmonth_flag grpweek_flag concat count);
		set to_append_output;
		by concat;

		if first.concat then
			yvalue=count;
		else yvalue+count;
	run;

	quit;

%mend;

%macro no_metric;

	data to_append_output(keep=chartby_time_level sliceby_time_level r1 r2 r3 r4 combined_flag
		yvars metric_unique yvalue );
		set final_data;
	run;

%mend;

%macro counts;
	/*this macro is commonly used to calculate count percentage,cumulative count and cum count percentage*/
	proc sort data=final_data;
		by chartby_time_level sliceby_time_level r4 r3 r2 r1;
	run;

	proc freq data=final_data;
		by %if &rolluplevel.=none %then

			%do;
				chartby_time_level sliceby_time_level;
			%end;
%else
	%do;
		chartby_time_level sliceby_time_level r4 r3 r2;
	%end;

table r1/out=count_table outcum;
	run;

	%count_merge;
%mend;

%macro count_merge;
	/*as per the specified metric, results from the proc freq are manipulated to get the desired results*/
	proc sql;
		create table to_append_output as
			select a.chartby_time_level ,a.sliceby_time_level ,a.r1,a.r2,a.r3,a.r4,a.combined_flag,a.yvars,a.metric_unique,b.&&&metric_agg_current._column. as yvalue
				from final_data as a join count_table as b
					on

			%if  &rolluplevel.=none %then
				%do;
					a.chartby_time_level=b.chartby_time_level
					and a.sliceby_time_level=b.sliceby_time_level
					and a.r1=b.r1;
				%end;
			%else
				%do;
					a.chartby_time_level=b.chartby_time_level
					and a.sliceby_time_level=b.sliceby_time_level
					and a.r1=b.r1
					and a.r2=b.r2
					and a.r3=b.r3
					and a.r4=b.r4;
				%end;
	quit;

	proc sort data=to_append_output out=to_append_output nodupkey;
		by chartby_time_level sliceby_time_level r4 r3 r2 r1;
	quit;

%mend;

%macro moving_centered_odd;
	%let displacement=%eval((&movavg_order.-1)/2);

	data to_append_output;
		set to_append_output;

		%if &rolluplevel.=none %then
			%do;
				concat=catx("_",chartby_time_level,sliceby_time_level,combined_flag,yvars,metric_unique);
			%end;
		%else
			%do;
				concat=catx("_",chartby_time_level,sliceby_time_level,combined_flag,yvars,metric_unique,r4,r3,r2);
			%end;
	run;

	proc sort data=to_append_output;
		by concat r1;
	run;

	proc expand data=to_append_output out=to_append_output;
		by 
		%if &rolluplevel.=none %then

			%do;
				chartby_time_level sliceby_time_level combined_flag yvars metric_unique;
			%end;
		%else
			%do;
				chartby_time_level sliceby_time_level combined_flag yvars metric_unique  r4 r3 r2;
			%end;

		id r1;
		convert yvalue = movingaverage/ transformout=(cmovave &movavg_order);
	run;

	data to_append_output;
		set to_append_output;
		by concat;

		if first.concat then
			row_num=1;
		else row_num+1;

		if row_num<= &displacement. then
			movingaverage=.;
	run;

	proc expand data=to_append_output out=to_append_output;
		convert row_num = row_nums/ transformout=(lead &displacement.);
	run;

	data to_append_output(drop=row_num row_nums concat);
		set to_append_output;

		if row_nums<row_num then
			movingaverage=.;
	run;

%mend;

%macro moving_centered;
	%let half_order=%eval(&movavg_order/2);

	proc sort data=to_append_output;
		by chartby_time_level sliceby_time_level combined_flag yvars metric_unique  r4 r3 r2 r1;
	run;

	proc expand data=to_append_output out=to_append_outputs;
		by 
		%if &rolluplevel.=none %then

			%do;
				chartby_time_level sliceby_time_level combined_flag yvars metric_unique;
			%end;
%else
	%do;
		chartby_time_level sliceby_time_level combined_flag yvars metric_unique  r4 r3 r2;
	%end;

id r1;

%do i=1 %to %eval(&movavg_order.-1);
	convert yvalue = mv&i./ transformout=(lag &i);
	convert r1=r1&i./ transformout=(lag &i);
%end;
	run;

	data to_append_outputs;
		set to_append_outputs;
		mv=sum(mv,yvalue);
		xvalue_ma=sum(xvalue_ma,r1);

		%do i=1 %to %eval(&movavg_order.-1);
			mv=sum(mv,mv&i.);
			xvalue_ma=sum(xvalue_ma,r1&i.);
			%let mac=&i.;
		%end;

		mv=mv/&movavg_order.;
		xvalue_ma=xvalue_ma/&movavg_order.;

		if r1&mac.=. then
			delete;
	run;

	proc expand data=to_append_outputs out=to_append_outputs;
		by 
		%if &rolluplevel.=none %then

			%do;
				chartby_time_level sliceby_time_level combined_flag yvars metric_unique;
			%end;
%else
	%do;
		chartby_time_level sliceby_time_level combined_flag yvars metric_unique  r4 r3 r2;
	%end;

id r1;

%do i=1 %to %eval(&half_order.-1);
	convert mv = mv&i. / transformout=(lag &i);
	convert xvalue_ma =xvalue_ma&i./ transformout=(lag &i);
%end;
	run;

	data to_append_outputs;
		set to_append_outputs;

		%do i=1 %to %eval(&half_order.-1);
			mv=sum(mv,mv&i.);
			xvalue_ma=sum(xvalue_ma,xvalue_ma&i.);
			%let mac=&i.;
		%end;

		mv=mv/&half_order.;
		xvalue_ma=xvalue_ma/&half_order.;

		if xvalue_ma=. then
			delete;
	run;

	proc sql;
		create table to_append_output as select a.*,b.mv as movingaverage
			from to_append_output as a left join to_append_outputs as b 
				on a.chartby_time_level= b.chartby_time_level
				and a.sliceby_time_level= b.sliceby_time_level
				and a.combined_flag=b.combined_flag
				and a.yvars=b.yvars
				and a.metric_unique=b.metric_unique
				and a.r1=b.xvalue_ma
				and a.r2=b.r2
				and a.r3=b.r3
				and a.r4=b.r4;
	quit;

	run;

%mend;

%macro moving_forward;

	proc expand data=to_append_output out=to_append_output(drop=movave concat row_num);
		by %if &rolluplevel.=none %then

			%do;
				chartby_time_level sliceby_time_level combined_flag yvars metric_unique;
			%end;
%else
	%do;
		chartby_time_level sliceby_time_level combined_flag yvars metric_unique  r4 r3 r2;
	%end;

id r1;
convert movave=movingaverage/transformout=(  lead &displacement.  );
	run;

%mend;

%macro moving_backward;

	proc expand data=to_append_output out=to_append_output(drop=movave concat row_num);
		by 
		%if &rolluplevel.=none %then

			%do;
				chartby_time_level sliceby_time_level combined_flag yvars metric_unique;
			%end;
%else
	%do;
		chartby_time_level sliceby_time_level combined_flag yvars metric_unique  r4 r3 r2;
	%end;

id r1;
convert movave=movingaverage/transformout=(  lag &displacement.  );
	run;

%mend;

%macro moving_average;
	%if &movavg_type.^=centered %then
		%do;
			%let displacement=%eval(&movavg_order-1);

			data to_append_output;
				set to_append_output;

				%if &rolluplevel.=none %then
					%do;
						concat=catx("_",chartby_time_level,sliceby_time_level,combined_flag,yvars,metric_unique);
					%end;
				%else
					%do;
						concat=catx("_",chartby_time_level,sliceby_time_level,combined_flag,yvars,metric_unique,r4,r3,r2);
					%end;
			run;

			proc sort data=to_append_output;
				by  concat r1;
			run;

			quit;

			data to_append_output;
				set to_append_output;
				by concat;

				if first.concat then
					row_num=0;
				row_num+1;
			run;

			proc sort data=to_append_output;
				by chartby_time_level sliceby_time_level combined_flag yvars metric_unique  r4 r3 r2;
			run;

			quit;

			proc expand data=to_append_output out=to_append_output;
				by 
				%if &rolluplevel.=none %then

					%do;
						chartby_time_level sliceby_time_level combined_flag yvars metric_unique;
					%end;
				%else
					%do;
						chartby_time_level sliceby_time_level combined_flag yvars metric_unique  r4 r3 r2;
					%end;

				id r1;
				convert yvalue = movave/ transformout=(  movave &movavg_order.  );
			quit;

			data to_append_output;
				set to_append_output;

				if row_num<&movavg_order. then
					movave=.;
			run;

			%moving_&movavg_type.;
		%end;
	%else
		%do;
			%if %sysfunc(mod(&movavg_order.,2))=0 %then
				%do;
					%moving_centered;
				%end;
			%else
				%do;
					%moving_centered_odd;
				%end;
		%end;
%mend;

%macro trend_line;

	proc sort data=to_append_output;
		by chartby_time_level sliceby_time_level combined_flag yvars metric_unique r4 r3 r2 r1;
	run;

	quit;

	data to_append_output;
		set to_append_output;

		%if &rolluplevel.=none %then
			%do;
				concat=catx("_",chartby_time_level,sliceby_time_level,combined_flag,yvars,metric_unique);
			%end;
		%else
			%do;
				concat=catx("_",chartby_time_level,sliceby_time_level,combined_flag,yvars,metric_unique,r4,r3,r2);
			%end;
	run;

	proc sort data=to_append_output;
		by concat r4 r3 r2 r1;
	run;

	data to_append_output;
		set to_append_output;
		by concat;

		if first.concat then
			seq_id=0;
		seq_id+1;
	run;

	proc sql;
		create table to_append_output as select *, max(seq_id) as seqid from to_append_output
			group by concat;
	run;

	quit;

	data to_append_output(drop= seq_id );
		set to_append_output;
		t_centered=seq_id-((seqid/2)+0.5);
		t_cent_sqr=t_centered*t_centered;
		t_cent_y=t_centered*yvalue;
	run;

	proc sql;
		create table to_append_output as select *,avg(yvalue) as avg_yvalue,sum(t_cent_y) as t_cents_y,sum(t_cent_sqr) as t_cents_sqr
			from to_append_output
				group by concat;
	quit;

	run;

	data to_append_output(drop=seqid t_cent_sqr t_cent_y avg_yvalue t_cents_y t_cents_sqr t_centered concat );
		set to_append_output;
		trendline=((t_centered*t_cents_y/t_cents_sqr)+avg_yvalue);
	run;

%mend;

%macro yvar_loop;
	%do yvar_count=1 %to %sysfunc(countw(&selected_varlist.));
		%let metric_var_current = %scan("&selected_varlist.",&yvar_count.," ");
		%let metric_agg_current = %scan("&metrics.",&yvar_count.," ");

		data final_data;
			format metric_unique $32.;
				informat metric_unique $32.;
				format yvars $32.;
				informat yvars $32.;
				set final_data;
				yvars= "&metric_var_current.";
				yvalue=&metric_var_current.;
				metric_unique  = "&metric_agg_current.";
				combined_flag   = 0;

				%if &yvar_count. > &initial_len. %then
					%do;
						combined_flag ="1";

						%if &slicebymode^=panel %then
							%do;
								sliceby_time_level="0_1_1_1";
							%end;
						%else
							%do;
								if sliceby_time_level="0_1_1_1" then
									output;
							%end;
					%end;
		run;
		%&&&metric_agg_current..;
		%if "&flag_trendline."="true" %then
			%do;
				%trend_line;
			%end;

		%if "&flag_movingaverage."="true" %then
			%do;
				%moving_average;
			%end;

		%let append_yvar_counter=%eval(&append_yvar_counter.+1);

		data to_append_output(rename=(r1=xvalue r2=&uniq_r2 r3=&uniq_r3 r4=&uniq_r4));
			set to_append_output;
		run;

		data MID_OUTPUT;
			format xvars $32.;
			informat xvars $32.;

			%if &append_yvar_counter. = 1 %then
				%do;
					set to_append_output;
				%end;
			%else
				%do;
					set MID_OUTPUT to_append_output;
				%end;

			/*			%if &sliceby_chk.=0 %then*/
			%if &slice_checking_param.=1 %then
				%do;
					if sliceby_time_level='0_1_1_1' and combined_flag=0 then
						delete;
				%end;

			xvars="&date_var";
		run;

	%end;
%mend;

%macro sliceby_loop;
	%do k=1 %to %sysfunc(countw(&level.,"#"));
		%sliceby_want_creator;
		%slicebysubsetting;

		data final_data;
			%if &k.=1 & &i.=1 %then
				%do;
					set final_subset;
				%end;
			%else
				%do;
					set final_data final_subset;
				%end;
		run;

	%end;
%mend;

%macro chartby_loop;
	%do i=1 %to %sysfunc(countw(&grp_no.,"#"));
		%chartby_want_creator;
		%chartbysubsetting;
		%sliceby_loop;
	%end;
%mend;

%macro main;
	%libname_definer;
	%dataset_intake;
	%let sliceby_chk=%sysfunc(index(&level.,0));

	/*	variable initial_len used to set combine_flag*/
	%if &selected_varlist. = %then
		%do;
			%let initial_len = 0;
		%end;
	%else
		%do;
			%let initial_len =%sysfunc(countw(&selected_varlist.));
		%end;

	%param_player;
	%chartby_loop;

	proc sort data=final_data;
		by grpyear_flag grpqtr_flag grpmonth_flag grpweek_flag;
	run;

	quit;

	%Rollup_loop;
	%yvar_loop;
%mend main;

%main;

proc sort data=mid_output out=unique_chart_slice 
	(keep=chartby_time_level sliceby_time_level combined_flag 
	rename=(chartby_time_level=chartby sliceby_time_level=sliceby))nodupkey;
	by chartby_time_level sliceby_time_level;
run;

data unique_levels;
	set mid_output(keep= &uniq_r2 &uniq_r3 &uniq_r4);
run;

proc sort data=unique_levels  out=unique_levels nodupkey;
	by  &uniq_r2. &uniq_r3. &uniq_r4.;
run;

data mid_output(rename= (chartby_time_level=grp_no_flag   sliceby_time_level=slice_no_flag));
	set mid_output;

	if yvalue=. then
		delete;
run;

PROC EXPORT DATA = unique_levels
	OUTFILE="&output_path./unique_levels.csv" 
	DBMS=CSV REPLACE;
run;

quit;

PROC EXPORT DATA = mid_output
	OUTFILE="&output_path./timeseries_chart.csv" 
	DBMS=CSV REPLACE;
run;

quit;

PROC EXPORT DATA = unique_chart_slice 
	OUTFILE="&output_path./unique_chart_slice.csv" 
	DBMS=CSV REPLACE;
run;

data _null_;
	v1= "time series completed";
	file "&output_path./timeseries_COMPLETED.txt";
	put v1;
run;