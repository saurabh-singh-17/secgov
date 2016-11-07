/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/CROSSTABS_MULTIPLE_COMPLETED.txt;
options mprint mlogic  symbolgen mfile;

FILENAME MyFile "&output_path/CROSSTABS_MULTIPLE_COMPLETED.txt" ;

  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;
proc printto log="&output_path/Crosstabs_Multiple_Log.log";
run;
quit;
/*proc printto print="&output_path/Crosstabs_Multiple_output.out";*/

libname in "&input_path.";
libname out "&output_path.";


%MACRO crosstabs_multiple;

/*DYNAMIC FILTER*/
	%if "&flag_filter." = "true" %then %do;
		%let super_cn = and;

		data filter;
	    	infile "&filterCSV_path." delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
				retain name ID type classification values;
				length values $1200.;
				informat name $32.; informat ID best32.; informat type $12.; informat classification $8.; informat values $1200.; informat condition $7.; 
        		format name $32.; format ID best12.; format type $12.; format classification $8.; format values $1200.; format condition $7.;
      			input name $ ID type $ classification $ values $ condition $;
      			run;


	/*create condition for each filter*/
		data filter;
			length whr_var $1200.;
			set filter;
			if strip(lowcase(type)) = "categorical" and strip(lowcase(classification))="numeric" then do;
				whr_var = cat("(", strip(name), " ", strip(condition), " (", tranwrd(strip(values),"!!", ", "), ")", ")");
			end;
			if strip(lowcase(type)) = "categorical" and strip(lowcase(classification))="string" then do;
				whr_var = cat("(", strip(name), " ", strip(condition), " ('", tranwrd(strip(values), "!!", "','"), "')", ")");
			end;
			if strip(lowcase(type)) = "continuous" and strip(lowcase(classification))="numeric" and strip(lowcase(condition)="in") then do;
				whr_var = cat("(", strip(name), " > ", scan(strip(values), 1, "!!"), " and ", strip(name), " < ", scan(strip(values), 2, "!!"), ")");
			end;
			if strip(lowcase(type)) = "continuous" and strip(lowcase(classification))="numeric" and strip(lowcase(condition)="not in") then do;
				whr_var = cat("(", strip(name), " < ", scan(strip(values), 1, "!!"), " and ", strip(name), " > ", scan(strip(values), 2, "!!"), ")");
			end;
			if strip(lowcase(type)) = "continuous" and strip(lowcase(classification))="date" and strip(lowcase(condition)="in") then do;
				whr_var = cat("(", strip(name), " > ", "'", scan(strip(values), 1, "!!"), "'d and ", strip(name), " < ", "'", scan(strip(values), 2, "!!"), "'d)");
			end;
			if strip(lowcase(type)) = "continuous" and strip(lowcase(classification))="date" and strip(lowcase(condition)="not in") then do;
				whr_var = cat("(", strip(name), " < ", "'", scan(strip(values), 1, "!!"), "'d and ", strip(name), " > ", "'", scan(strip(values), 2, "!!"), "'d)");
			end;
			run;

		/*collate all the conditions to form where statement*/
		%let whr_filter =;
		proc sql;
			select (whr_var) into :whr_filter separated by " &super_cn. " from filter;
			select (name) into :filter_vars separated by " " from filter;
			quit;
		%put &whr_filter;
		%put &filter_vars;
		
	%end;

/*#########################################################################################################################################################*/

	
	data temp;
		set in.dataworking (keep=&var_name. &pivot_vars. &var_list. %if "&grp_vars." ^= "" %then %do; &grp_vars. %end;
			%if "&weight_var." ^= "" %then %do; &weight_var.%end;
			%if "&flag_filter." = "true" %then %do; &filter_vars. where=(&whr_filter.) %end;);
		run;

	%if "&grp_vars." ^= "" %then %do;
		data _null_;
			call symput("grps", tranwrd("&grp_vars", " ", ", "));
			run;
	
		%let axes = grp_vars;

		data _null_;
			call symput("cat_axis", tranwrd("&&&axes.", " ", ",'_',"));
			run;
		%put &cat_axis;

		data temp;
			set temp;
			&axes. = cats(&cat_axis);
			run;
	%end;


	%let n = 1;
	%do %until (not %length(%scan(&pivot_vars., &n)));
		data _null_;
			call symput("x_var", "%scan(&pivot_vars., &n)");
			run;

		%let m = 1;
		%do %until (not %length(%scan(&var_list., &m)));
			data _null_;
				call symput("y_var", "%scan(&var_list., &m)");
				run;

			/* x-variable type */
			%let dsid = %sysfunc(open(temp));
				%let varnum = %sysfunc(varnum(&dsid,&y_var.));
				%let vartyp_y = %sysfunc(vartype(&dsid,&varnum));
				%let rc = %sysfunc(close(&dsid));

			%if &vartyp_y = C %Then %do;
				data temp;
					set temp;
					&y_var. = tranwrd(strip(&y_var.), " ", "_");
					&y_var. = tranwrd(strip(&y_var.), "/", "_");
					run;
			%end;


		/* METRIC */
			%if "&type." = "metric" %then %do;
				proc sql;
					create table form_table as
					select distinct  &x_var., &y_var., %if "&grp_vars" ^= "" %then %do; grp_vars, %end;
					round(&metric.(&var_name),.01) as var from temp
					group by %if "&grp_vars." ^= "" %then %do; &grps., %end; &x_var., &y_var.;
					quit;

				%let dsid = %sysfunc(open(form_table));
					%let varnum_met = %sysfunc(varnum(&dsid,&x_var.));
					%let vartyp_met = %sysfunc(vartype(&dsid,&varnum_met));
					%let rc = %sysfunc(close(&dsid));


				data form_table;
					retain %if "&grp_vars." ^= "" %then %do; grp_vars %end; &x_var.;
					set form_table %if &vartyp_met = N %then %do;(rename=(&x_var.=x_var))%end;;
					%if &vartyp_met = N %then %do;
						&x_var. = put(x_var, best8.);  
						drop x_var;
					%end; 
					run;

				%if "&grp_vars." = "" %then %do;
					data form_table;
						set form_table;
						grp_vars = "none";
						run;
				%end;

				proc sort data = form_table;
					by grp_vars &x_var.;
					run;

				proc transpose data = form_table out = trans(drop=_name_);
					var var;
					by grp_vars &x_var.;
					id &y_var.;
					run;


			/*row-wise sum*/
				proc contents data = trans(drop=&x_var. grp_vars ) out = contents_trans(keep=name) varnum;
					run;

				proc sql;
					select name into :row_elements separated by "," from contents_trans;
					quit;

				proc sql;
					create table summ_rows as
					select *, sum(&row_elements) as sum_row from trans;
					quit;

			/*column-wise sum*/
				proc contents data = summ_rows(drop=&x_var. grp_vars) out = contents_summ_rows(keep=name) varnum;
					run;

				proc sql;
					select name into :column_elements separated by " " from contents_summ_rows;
					quit;

				
				%let i = 1;
				%do %until (not %length(%scan(&column_elements, &i)));
					proc summary data=summ_rows;
						var %scan(&column_elements, &i);
						output out=summ_%scan(&column_elements, &i) sum=sum_%scan(&column_elements, &i);
						by grp_vars;
						run;

					proc sql;
						select sum_%scan(&column_elements, &i) into :sum_column from summ_%scan(&column_elements, &i);
						quit;


					%if "&i." = "1" %then %do;
						data summ_columns;
							merge summ_rows(in=a) summ_%scan(&column_elements, &i)(in=b drop=_type_ _freq_);
							by grp_vars;
							if a or b;
							run;
	/*					data summ_columns;*/
	/*						set summ_rows;*/
	/*						sum_%scan(&column_elements, &i) = &sum_column.;*/
	/*						%if "&grp_vars." ^= "" %then %do;*/
	/*							by grp_vars;*/
	/*						%end;*/
	/*						run;*/
					%end;
					%else %do;
						data summ_columns;
							merge summ_columns(in=a) summ_%scan(&column_elements, &i)(in=b drop=_type_ _freq_);
							by grp_vars;
							if a or b;
							run;
	/*					data summ_columns;*/
	/*						set summ_columns;*/
	/*						sum_%scan(&column_elements, &i) = &sum_column.;*/
	/*						%if "&grp_vars." ^= "" %then %do;*/
	/*							by grp_vars;*/
	/*						%end;*/
	/*						run;*/

					%end;

					%let i = %eval(&i.+1);
				%end;

				data _null_;
					call symput("new_columns", cats("sum_", tranwrd("&column_elements.", " ", " ,sum_")));
					run;
				%put &new_columns;

				proc sql;
					create table summ_inter as
					select distinct (grp_vars), "total" as &x_var., &new_columns. from summ_columns
					where sum_sum_row ^= .;
					quit;


				%let i = 1;
				%do %until (not %length(%scan(&column_elements, &i)));
					data summ_inter;
						set summ_inter;
						%scan(&column_elements, &i) = sum_%scan(&column_elements, &i);
						run;

					%let i = %eval(&i.+1);
				%end;


				data  summ_total;
					set summ_columns summ_inter;
					run;

				proc sort data = summ_total;
					by grp_vars;
					run;

				
				%if "&grp_vars." = "" %then %do;
					data summ_total;
						set summ_total(drop=grp_vars);
						run;
				%end;


				/*final processing*/
				%let i = 1;
				%do %until (not %length(%scan(&column_elements, &i)));
					data _null_;
						call symput("column", "%scan(&column_elements, &i)");
						run;

					data summ_total;
						set summ_total;
						perc_abs_&column. = round((&column./sum_sum_row)*100,.01);
						if &x_var. ^= "total" then do;
							%if "&column." ^= "sum_row" %then %do;
								perc_col_&column. = round((&column./sum_&column.)*100,.01);
								perc_row_&column. = round((&column./sum_row)*100, .01);
							%end;
						end;
						run;
					%let i = %eval(&i.+1);
				%end;

				/*intermediate output*/
				libname outct xml "&output_path./&x_var./inter_&y_var..xml";
				data outct.column_chart;
					set summ_total;
					run;


				%let i = 1;
				%do %until (not %length(%scan(&column_elements, &i)));
					data _null_;
						call symput("column", "%scan(&column_elements, &i)");
						run;

					data summ_total(drop=perc_abs_&column. &column. sum_&column. %if "&column." ^= "sum_row" %then %do;perc_col_&column. perc_row_&column. %end; 
									rename=(out_&column.=&column.));
						set summ_total;
						if &x_var. ^= "total" then do;
							%if "&column." ^= "sum_row" %then %do;
								out_&column. = cats("value=", &column., "!! row%=", perc_row_&column., "!! col%=", perc_col_&column., "!! abs%=", perc_abs_&column.);
							%end;
							%if "&column." = "sum_row" %then %do;
								out_&column. = cats("value=", &column., "!! abs%=", round((&column./sum_sum_row)*100,.01));
							%end;
						end;
						else do;
							%if "&column." ^= "sum_row" %then %do;
								out_&column. = cats("value=", &column., "!! abs%=", perc_abs_&column.);
							%end;
							%if "&column." = "sum_row" %then %do;
								out_&column. = &column.;
							%end;
						end;
						run;
					%let i = %eval(&i.+1);
				%end;
			%end;
						
			/* CHI-SQ */
			%if "&flag_chisq_relation." = "true" %then %do;
				%if "&grp_vars." ^= "" %then %do;
					proc sort data = in.dataworking;
						by &grp_vars.;
						run;
				%end;

				ods output ChiSq = chiSq(drop=table where=(statistic="Chi-Square"));
				proc freq data = in.dataworking %if "&flag_filter." = "true" %then %do; (where=(&whr_filter.)) %end;;
					tables &x_var. * &y_var./ chisq;
					%if "&grp_vars." ^= "" %then %do;
						by &grp_vars.;
					%end;
					%if "&weight_var." ^= "" %then %do;
						weight &weight_var.;
					%end;
					run;

				data chiSq(drop=&grp_vars.);
					retain pivot_var interaction %if "&grp_vars." ^= "" %then %do;&axes. %end; statistic DF value prob result;
					length result $15.;
					length pivot_var $32.;
					length interaction $32.;
					set chiSq;
					pivot_var = "&x_var.";
					interaction = "&y_var.";
					%if "&grp_vars." ^= "" %then %do;
						&axes. = cats(&cat_axis);
					%end;
					if prob <= &pvalue_cutoff. then result = "significant";
						else result = "insignificant";
					run;

				proc append base=out_chiSq data=chiSq force;
					run;
			%end;
			
/*-----------------------------------------------------------------------------------------------------------------------*/
		/* COUNT */
			%if "&type." = "count" %then %do;
				%if "&grp_vars." ^= "" %then %do;
					proc sort data = temp;
						by &grp_vars.;
						run;
				%end;

				ods output  CrossTabFreqs = crosstab;
				proc freq data = temp;
					tables &x_var. * &y_var.;
					%if "&grp_vars." ^= "" %then %do;
						by grp_vars;
					%end;
					%if "&weight_var." ^= "" %then %do;
						weight &weight_var.;
					%end;
					output out = counter;
					run;


				data crosstab;
					set crosstab;
					frequency = round(frequency,.01);
					percent = round(percent,.01);
					rowpercent = round(rowpercent,.01);
					colpercent = round(colpercent,.01);
					run;


				/* x-variable type */
				%let dsid = %sysfunc(open(crosstab));
					%let varnum = %sysfunc(varnum(&dsid,&x_var.));
					%let vartyp = %sysfunc(vartype(&dsid,&varnum));
					%let rc = %sysfunc(close(&dsid));


				data crosstab_modi;
					set crosstab;
					%if &vartyp. = N %then %do;
						rename &x_var.=x_var;
					%end;
					%if &vartyp_y. = N %then %do;
						rename &y_var.=y_var;
					%end;
					run;

				data crosstab_modi;
					set crosstab_modi;
					%if &vartyp. = N %then %do;
						format &x_var. $32.;
						&x_var. = put(x_var,best12.);
					%end;
					%if &vartyp_y. = N %then %do;
						format &y_var. $32.;
						&y_var. = put(y_var,best12.);
					%end;
					run;


		/*intermediate output*/
				libname outct xml "&output_path./&x_var./inter_&y_var..xml";
				data inter_column_chart(rename=(&x_var.=x_var &y_var.=y_var));
					set crosstab_modi(drop=table %if &vartyp. = N %then %do; x_var %end; %if &vartyp_y. = N %then %do; y_var %end;_table_ _type_ missing);
					run;

				data outct.column_chart;
					length y_var $32.;
					length x_var $32.;
					set inter_column_chart;
					%if &vartyp_y. = N %then %do;
						if strip(y_var) = "." then y_var = "sum_row";
					%end;
					%if &vartyp_y. = C %then %do;
						if strip(y_var) = "" then y_var = "sum_row";
					%end;
					%if &vartyp. = N %then %do;
						if strip(x_var) = "." then x_var = "total";
					%end;
					%if &vartyp. = C %then %do;
						if strip(x_var) = "" then x_var = "total";
					%end;
					y_var = strip(y_var);
					x_var = strip(x_var);
					run;


				data crosstab_mod(keep=%if "&grp_vars." ^= "" %then %do;grp_vars %end; &x_var. &y_var. out);
					length &y_var. $32.;
					length &x_var. $32.;
					set crosstab_modi;
					%if &vartyp_y. = N %then %do;
						if &y_var. = . then &y_var. = "sum_row";
					%end;
					%if &vartyp_y. = C %then %do;
						if &y_var. = "" then &y_var. = "sum_row";
					%end;
					%if &vartyp. = N %then %do;
						if &x_var. = . then &x_var. = "total";
					%end;
					%if &vartyp. = C %then %do;
						if &x_var. = "" then &x_var. = "total";
					%end;

					
					if &x_var. ^= "total" then do;
						if &y_var. ^= "sum_row" then do;
							out = cats("value=", frequency, "!! row%=", rowPercent, "!! col%=", colPercent, "!! abs%=", percent);
						end;
						if &y_var. = "sum_row" then do;
							out = cats("value=", frequency, "!! abs%=", percent);
						end;
					end;
					else do;
						if &y_var. ^= "sum_row" then do;
							out = cats("value=", frequency, "!! abs%=", percent);
						end;
						if &y_var. = "sum_row" then do;
							out = frequency;
						end;
					end;
					run;


				proc transpose data = crosstab_mod out = summ_total(drop=_name_);
					var out;
					id &y_var.;
					by %if "&grp_vars." ^= "" %then %do;grp_vars %end; &x_var.;
					run;

				proc contents data = summ_total(drop=%if "&grp_vars." ^= "" %then %do;grp_vars %end; &x_var. sum_row) out = contents_trans(keep=name);
					run;

				proc sql;
					select name into :column_elements separated by "!!" from contents_trans;
					quit;
				%put &column_elements;

				%let j = 1;
				%do %until (not %length(%scan(&column_elements, &j, "!!")));
					data _null_;
						call symput("column", "%scan(&column_elements, &j, "!!")");
						run;

					data summ_total;
						set summ_total;
						if &x_var. ^= "total" then do;
							%if "&column." ^= "sum_row" %then %do;
								if &column. = "" then do;
									&column. = "value=0!! row%=0!! col%=0!! abs%=0";
								end;
							%end;
							%if "&column." = "sum_row" %then %do;
								if &column. = "" then do;
									&column. = "value=0!! abs%=0";
								end;
							%end;
						end;
						else do;
							%if "&column." ^= "sum_row" %then %do;
								if &column. = "" then do;
									&column. = "value=0!! abs%=0";
								end;
							%end;
							%if "&column." = "sum_row" %then %do;
								if &column. = "" then do;
									&column. = "0";
								end;
							%end;
						end;
						run; 

					%let j = %eval(&j.+1);
				%end;

			%end;

/*-----------------------------------------------------------------------------------------------------------------------*/

			libname outct xml "&output_path./&x_var./&y_var..xml";
			data outct.column_chart;
				set summ_total;
				run;


			proc export data = summ_total
				outfile = "&output_path./&x_var./&y_var..csv"
				dbms = csv replace;
				run;

			libname stacked xml "&output_path./stackedvalues_list_&y_var..xml";
			data stacked.stacked_values_list;
				set contents_trans;
				run;

			%let m = %eval(&m.+1);
		%end;

		%let n = %eval(&n.+1);
	%end;	

	%if "&grp_vars." ^= "" %then %do;
		libname grpvars xml "&output_path./grp_values_list.xml";
		proc sql;
			create table grpvars.grp_values_list as
			select distinct grp_vars from temp;
			quit;
	%end;

	%if "&flag_chisq_relation." = "true" %then %do;
		proc export data = out_chiSq
			outfile = "&output_path./chi_sq.csv"
			dbms = csv replace;
			run;
	%end;

%MEND crosstabs_multiple;
%crosstabs_multiple;


/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "CROSSTABS_MULTIPLE_COMPLETED";
	file "&output_path/CROSSTABS_MULTIPLE_COMPLETED.txt";
	put v1;
run;

ENDSAS;


