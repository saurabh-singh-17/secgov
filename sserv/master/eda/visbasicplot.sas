options mprint mlogic symbolgen spool;

/*-----------------------------------------------------------------------------------------
Parameters Required
-----------------------------------------------------------------------------------------*/

/*%let input_csv_path=/data22/IDev/Mrx/projects/vasanth_vb2-7-Aug-2013-15-34-10/1/0/1_1_1/EDA/visualization_2b/4;*/
/*%let output_path=/data22/IDev/Mrx/projects/vasanth_vb2-7-Aug-2013-15-34-10/1/0/1_1_1/EDA/visualization_2b/4;*/
/*%let x_axis=channel_1 channel_2 channel_1$channel_2;*/
/*%let y_axis=AVG(HHs_Index_Income_75K_9999K);*/
/*%let chart_type=column;*/
/*%let split_axis_by=north!!south;*/
/*%let split_axis_by_var=geography;*/
/*%let mode=normal;*/
/*-----------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------
Macro to make the plots for Visualizations Basic - Normal Mode
-----------------------------------------------------------------------------------------*/
proc printto log="&output_path./Visbasicplot_log.log";
run;
quit;

%macro plotvisbasicnormal;
	%let current_y_axis = &y_axis.;

	/* Loop to generate as many plots as the &x_axis. */
	%do i = 1 %to %sysfunc(countw(&x_axis.," "));

		/*	Get the current &x_axis. and &y_axiss.*/
		%let current_x_axis = %scan(&x_axis.,&i.," ");

		/*	Read the &current_x_axis. csv*/
		data WORK.TEMP;
			%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
			infile "&input_csv_path./&current_x_axis..csv" delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
			informat variable best32. ;
			informat metric $40. ;
			informat metric_unique $10. ;
			informat value best32. ;
			informat lineby1 $100. ;
			format variable best12. ;
			format metric $40. ;
			format metric_unique $10. ;
			format value best12. ;
			format lineby1 $100. ;
			input variable metric $ metric_unique $ value lineby1 $;
			if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
		run;

		%if &i. = 1 %then %do;

				data _null_;
					call symput("current_y_axis",tranwrd("&current_y_axis.","!!",'","'));
				run;

				%let current_y_axis = "&current_y_axis.";
			/*%end;*/

		    %if %length(&split_axis_by.) ^= 0 %then %do;

				data _null_;
					call symput("forlegend",tranwrd("&split_axis_by.","!!",'" "'));
				run;

				%let forlegend = "&forlegend.";
			%end;
		%end;
			%if %length(&split_axis_by.) ^= 0 %then %do;
				%if &i. = 1 %then
					%do;
						/*	Get the type of variable lineby1*/
						%let dsid=%sysfunc(open(temp));
						%let varnum_lineby1=%sysfunc(varnum(&dsid.,lineby1));
						%let type_lineby1=%sysfunc(vartype(&dsid.,&varnum_lineby1.));
						%let rc=%sysfunc(close(&dsid.));

						/*	If lineby1 is character enclose the values in &split_axis_by. by double quotes*/
						/*	If lineby1 is character keep the values in &split_axis_by. separated by , to use with <in>*/
						%if &type_lineby1. = C %then
							%do;

								data _null_;
									call symput("split_axis_by",tranwrd("&split_axis_by.","!!",'","'));
								run;

								/*%let split_axis_by = "&split_axis_by.";*/
							%end;

						/*	If lineby1 is numeric keep the values in &split_axis_by. separated by , to use with <in>*/
						%if &type_lineby1. = N %then
							%do;

								data _null_;
									call symput("split_axis_by",tranwrd("&split_axis_by.","!!",','));
								run;

							%end;
					%end;

				data temp2(keep=variable value lineby1 rename=(variable=x value=y lineby1=by));
					set temp;
					where metric in (&current_y_axis.) and lineby1 in ("&split_axis_by.");
				run;

			%end;
		%else
			%do;

				data temp2(keep= variable value metric rename=(variable=x value=y metric=by));
					set temp;
					where metric in (&current_y_axis.);
				run;

			%end;

		/*	Turn on ods graphics and ods listing to export the image*/
		ods graphics on / height=20in width=20in antialias;
		ods listing;

		/*	The filename of the going-to-be-exported image*/
		filename image "&output_path./&current_x_axis..png";

		/*	The SAS graphics options*/
		goptions reset=all device=pngt gsfname=image gsfmode=replace;

		/*	Make the plot depending on &chart_type.*/
		%if &chart_type. = column %then
			%do;
				axis1 label=(&current_y_axis.);
				axis2 label=("&current_x_axis.");
				axis3 label=("&split_axis_by_var.");

				proc gchart data=temp2;
					vbar by / type=mean sumvar=y group=x subgroup=by space=0 levels=all raxis=axis1 maxis=axis2 gaxis=axis3;
				run;

			%end;
		%else
			%do;
				axis1 label=(&current_y_axis.);
				axis2 label=("&current_x_axis.");
				legend1 label=("&split_axis_by_var.") value=(&forlegend.);

				%if &chart_type. = line %then
					%do;
						symbol1 interpol=join w=2;
					%end;

				proc gplot data=temp2;
					plot y*x=by / vaxis=axis1 haxis=axis2 legend=legend1;
				run;

			%end;

		/*	Turn off the ods graphics and ods listing*/
		ods listing close;
		ods graphics off;
	%end;
%mend plotvisbasicnormal;

/*-----------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------
Macro to make the plots for Visualizations Basic - Comparison Mode
-----------------------------------------------------------------------------------------*/
%macro plotvisbasiccomparison;
	/*	Get the current &x_axis. and &y_axiss.*/
	%let current_x_axis = &x_axis.;
	%let current_y_axis = &y_axis.;

	/*	Read the &current_x_axis. csv*/
	proc import datafile="&input_csv_path./column_chart.csv" out=temp dbms=csv replace;
	run;

	quit;

	data _null_;
		call symput("current_y_axis",tranwrd("&current_y_axis.","!!",'","'));
	run;

	%let current_y_axis = "&current_y_axis.";

	%if %length(&split_axis_by.) ^= 0 %then
		%do;
			/*	Get the type of variable lineby1*/
			%let dsid=%sysfunc(open(temp));
			%let varnum_lineby1=%sysfunc(varnum(&dsid.,lineby1));
			%let type_lineby1=%sysfunc(vartype(&dsid.,&varnum_lineby1.));
			%let rc=%sysfunc(close(&dsid.));

			/*	If lineby1 is character enclose the values in &split_axis_by. by double quotes*/
			/*	If lineby1 is character keep the values in &split_axis_by. separated by , to use with <in>*/
			%if &type_lineby1. = C %then
				%do;

					data _null_;
						call symput("split_axis_by",tranwrd("&split_axis_by.","!!",'","'));
					run;

					%let split_axis_by = "&split_axis_by.";
				%end;

			/*	If lineby1 is numeric keep the values in &split_axis_by. separated by , to use with <in>*/
			%if &type_lineby1. = N %then
				%do;

					data _null_;
						call symput("split_axis_by",tranwrd("&split_axis_by.","!!",','));
					run;

				%end;

			data temp2(keep=variable value lineby1 rename=(variable=x value=y lineby1=by));
				set temp;
				where metric_unique in (&current_y_axis.) and lineby1 in (&split_axis_by.);
			run;

		%end;
	%else
		%do;

			data temp2(keep= variable value metric_unique rename=(variable=x value=y metric_unique=by));
				set temp;
				where metric_unique in (&current_y_axis.);
			run;

		%end;

	/*	Turn on ods graphics and ods listing to export the image*/
	ods graphics on /height=20in width=20in antialias;
	ods listing;

	/*	The filename of the going-to-be-exported image*/
	filename image "&output_path./column_chart.png";

	/*	The SAS graphics options*/
	goptions reset=all device=pngt gsfname=image gsfmode=replace;

	/*	Make the plot depending on &chart_type.*/
	%if &chart_type. = column %then
		%do;
			axis1 label=("&current_y_axis.");
			axis2 label=("Comparison between variables");
			axis3 label=("Metric");

			proc gchart data=temp2;
				vbar by / type=mean sumvar=y group=x subgroup=by space=0 levels=all raxis=axis1 maxis=axis2 gaxis=axis3;
			run;

		%end;
	%else
		%do;
			%if &chart_type. = line %then
				%do;
					symbol1 interpol=join w=2;
				%end;

			proc gplot data=temp2;
				plot y*x=by;
			run;

		%end;

	/*	Turn off the ods graphics and ods listing*/
	ods listing close;
	ods graphics off;
%mend plotvisbasiccomparison;

/*-----------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------
Calling the macro
-----------------------------------------------------------------------------------------*/
%macro calling_macros;
%if &mode. = normal %then
	%do;
		%plotvisbasicnormal;
	%end;

%if &mode. = comparison %then
	%do;
		%plotvisbasiccomparison;
	%end;
%mend;
%calling_macros;
/*-----------------------------------------------------------------------------------------*/