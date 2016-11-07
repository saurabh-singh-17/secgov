/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path./CHART_COMPLETED.txt;
/*VERISON 1.3*/

options mprint mlogic symbolgen mfile ;

proc printto log="&output_path./pieChartCode_Log.log";
run;
quit;
/*proc printto print="&output_path./pieChartCode_Output.out";*/
libname in "&input_path";
libname out "&output_path";

%macro pie;

/*DYNAMIC FILTER*/
	%if "&flag_filter." = "true" %then %do;
		%let whr=;
		%let super_cn = and;

		data filter;
	    	infile "&filterCSV_path." delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
				retain name ID type classification values;
				length values $800.;
				informat name $32.; informat ID best32.; informat type $12.; informat classification $8.; informat values $800.; informat condition $7.; 
        		format name $32.; format ID best12.; format type $12.; format classification $8.; format values $800.; format condition $7.;
      			input name $ ID type $ classification $ values $ condition $;
      			run;


	/*create condition for each filter*/
		data filter;
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


	proc contents data = in.&dataset_name(keep = &grp_vars &colored_vars) out = contents(keep = name type);
		run;

	data _null_;
	set contents;
		call symput ("grp_varlist" , catx("," , scan("&grp_vars",1) , scan("&grp_vars",2),scan("&grp_vars",3)) );
		call symput ("colored_varlist" , catx("," , scan("&colored_vars",1) , scan("&colored_vars",2),scan("&colored_vars",3)) );
		run;
	%put &grp_varlist &colored_varlist;						

	%if "&grp_vars" = "" %then %do;
		proc sql;
			create table grp_varlist as
			select &colored_varlist,
						&metric(&analysis_var.) as value 
			from in.&dataset_name
			group by &colored_varlist
			%if "&flag_filter." = "true" %then %do;
				having &whr_filter.;
			%end;
			;
			quit;
	%end;
	%else %do;
		proc sql;
			create table grp_varlist as
			select &grp_varlist,&colored_varlist, &metric(&analysis_var.) as value 
			from in.&dataset_name
			group by &grp_varlist,&colored_varlist
			%if "&flag_filter." = "true" %then %do;
				having &whr_filter.;
			%end;
			;
			quit;
	%end;

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
		%put &num_var1 &num_var2;

		data grp_varlist;
		set grp_varlist;
			%do j = 1 %to &num_varcnt.;
				&&num_var&j..1 = put(&&num_var&j.,best.);
				drop  &&num_var&j.;
				rename &&num_var&j..1 = &&num_var&j.;
			%end;
		run;
	%end;

	data pie_chart1;
	set grp_varlist;
		%if "&grp_vars" ^= "" %then %do;
			array aa(*) &grp_vars ;
			grp_flag = catx("_" , of aa[*]);
		%end;
		array bb(*) &colored_vars;										
		colored_flag = catx("_" , of bb[*]);
	run;
	
	proc sort data=pie_chart1 nodupkey out=pie_chart_temp;
	by &colored_vars &grp_vars;
	run;
	
	proc sort data=pie_chart_temp out=pie_chart;
	by %if "&grp_vars" ^= "" %then %do;  &grp_vars; %end;
		%else %do; &colored_vars; %end;
	run;


	
	libname pie xml "&output_path/pie_chart.xml";
	data pie.pie_chart;
		retain grp_flag colored_flag value;
		set pie_chart 
		%if "&grp_vars" ^= "" %then %do; (keep = grp_flag colored_flag value); %end;
		%else %do; (keep = colored_flag value); %end;
		run;


	data pie_chart;
      set pie.pie_chart;
      %if "&grp_vars" ^= "" %then %do;
            if grp_flag = "" then grp_flag="-";
      %end;
      if colored_flag = "" then colored_flag="-";
      if value = "" then value="-";
      run;

    options missing="-";
	proc export data = pie_chart
		outfile="&output_path/column_chart.csv" 
		dbms=csv replace; 
		run;	

	%if "&grp_vars" ^= "" %then %do;
		libname pie1 xml "&output_path/grp_values_list.xml";
		proc sort data = pie_chart(keep = grp_flag) out = dist_grp_flag nodupkey;
			by grp_flag;
			run;

		data pie1.grp_values_list;
			set dist_grp_flag;
			run; 

		Option missing="-";
		proc export data =pie1.grp_values_list
			outfile="&output_path/grp_values_list.csv" 
			dbms=csv replace; 
			run;
	%end;
						
%mend pie;
%pie;


data _NULL_;
	v1= "PIE_CHART_COMPLETED";
	file "&output_path./CHART_COMPLETED.txt";
	PUT v1;
	run;


