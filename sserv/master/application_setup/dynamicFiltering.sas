/*Successfully converted to SAS Server Format*/
*processbody;

	%let super_cn = and;

	data filter;
    	infile "&filterCSV_path." delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
			retain name ID type classification values;
			length values $5000.;
			informat name $32.; informat ID best32.; informat type $12.; informat classification $8.; 
				informat values $5000.; informat condition $7.; informat scope $9.; informat select $5.;
    		format name $32.; format ID best12.; format type $12.; format classification $8.; format values $5000.; 
				format condition $7.; format scope $9.; format select $5.;
  			input name $ ID type $ classification $ values $ condition $ scope $ select $;
  			run;
	%let path = %substr(&filterCSV_path.,1,%length(&filterCSV_path.)-%length(%scan(&filterCSV_path.,-1,"/"))-1);
	data filter_data (rename= values = completed_values);
		infile "&path./filterData.csv" delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
			retain variable ID values;
			length values $5000.;
			informat variable $32.; informat ID best32.; informat values $5000.; 
    		format variable $32.; format ID best12.; format values $5000.; 
  			input variable $ ID values $;
  			run;

	data filter;
		length whr_var $5000.;
		set filter;
		where strip(lowcase(select)) = "true";
		if strip(lowcase(type)) = "categorical" and strip(lowcase(classification))="numeric" and strip(lowcase(condition))="in" and strip(values) = "" then do;
			values = 525263475374584641241;
		end;
/*		if strip(lowcase(type)) = "categorical" and (strip(lowcase(classification))="numeric" or strip(lowcase(classification))="string") and strip(lowcase(condition))="not in" then do;*/
/*			if values=completed_values then do;*/
/*			whr_var = cat("(", strip(name), " ", in, " (", "", ")", ")");*/
/*			end;*/
/*		end;*/
		if strip(lowcase(type)) = "categorical" and (strip(lowcase(classification))="numeric" or strip(lowcase(classification))="string") and strip(values) = "" and strip(lowcase(condition))="in" then do;
			whr_var = cat("(", strip(name), " ", strip(condition), " (", strip(values), ")", ")");
		end;
		if strip(lowcase(type)) = "categorical" and strip(lowcase(classification))="numeric" then do;
			whr_var = cat("(", strip(name), " ", strip(condition), " (", tranwrd(strip(values),"!!", ", "), ")", ")");
		end;
		if strip(lowcase(type)) = "categorical" and strip(lowcase(classification))="string" then do;
			whr_var = cat("(", strip(name), " ", strip(condition), " ('", tranwrd(strip(values), "!!", "','"), "')", ")");
		end;
		if strip(lowcase(type)) = "continuous" and strip(lowcase(classification))="numeric" and strip(lowcase(condition)="in") then do;
			whr_var = cat("(", strip(name), " >= ", scan(strip(values), 1, "!!"), " and ", strip(name), " <= ", scan(strip(values), 2, "!!"), ")");
		end;
		if strip(lowcase(type)) = "continuous" and strip(lowcase(classification))="numeric" and strip(lowcase(condition)="not in") then do;
			whr_var = cat("(", strip(name), " < ", scan(strip(values), 1, "!!"), " or ", strip(name), " > ", scan(strip(values), 2, "!!"), ")");
		end;
		if strip(lowcase(type)) = "continuous" and strip(lowcase(classification))="date" and strip(lowcase(condition)="in") then do;
			whr_var = cat("(", strip(name), " >= ", "'", scan(strip(values), 1, "!!"), "'d and ", strip(name), " <= ", "'", scan(strip(values), 2, "!!"), "'d)");
		end;
		if strip(lowcase(type)) = "continuous" and strip(lowcase(classification))="date" and strip(lowcase(condition)="not in") then do;
			whr_var = cat("(", strip(name), " < ", "'", scan(strip(values), 1, "!!"), "'d or ", strip(name), " > ", "'", scan(strip(values), 2, "!!"), "'d)");
		end;
	run;

	%let global_vars=;
	%let local_vars=;
	proc sql;
		select (name) into :global_vars separated by " " from filter where scope="dataset";
		select (name) into :local_vars separated by " " from filter where scope="variable";
		quit;

	%put &global_vars.;
	%put &local_vars.;
	data _null_;
		call symput("glob_vars", cats("'", tranwrd("&global_vars.", " ", "', '"),"'"));
		run;
	%put &glob_vars;
	
/*COLLATE ALL CONDITIONS TO CREATE WHERE STATEMENT*/
	%let whr_filter =; 
	proc sql;
		select (whr_var) into :whr_filter separated by " &super_cn. " from filter where name in (&glob_vars.);
		quit;
	%put &whr_filter;


%put &local_vars.;
%macro localVars;
	%let dataset_name=out.temporary;

	proc sql;
	%if "&local_vars." ^= "" %then %do;
		%do i=1 %to %sysfunc(countw(&local_vars.));
			%let this_var = %scan(&local_vars,&i);
			%global whr_&this_Var.;
			select (whr_var) into :whr_&this_Var. from filter where strip(name) ="&this_Var.";
		%end;
		quit;

		%do i=1 %to %sysfunc(countw(&local_vars.));
			%let this_var = %scan(&local_vars,&i);
			%put &&whr_&this_Var.;
		%end;
	%end;

	data _null_;
		call symput ("filter", cat("'", tranwrd(lowcase("&filter_vars."), " ", "', '"), "'"));
		run;

/* applying variable specific filters */
	%if "&local_vars." ^= "" %then %do;
	   		/*join local whr conditions to whr_filter*/
			%do i=1 %to %sysfunc(countw(&local_vars.));
				%let this_var = %scan(&local_vars,&i);
				%let this_vaar = %sysfunc(lowcase(%unquote(%str(%'&this_var.%'))));
				%put &this_vaar;

				%put &&whr_&this_Var.;

				%if %index("&filter.", &this_vaar) > 0 %then %do;
					%if "&whr_filter." = "" %then %do;
						%let whr_filter = &&whr_&this_Var.;
					%end;
					%if "&whr_filter." ^= "" %then %do;
						%let whr_filter = &whr_filter. and &&whr_&this_Var.;
					%end;
				%end;
			%end;
		%end;

		/*join whr_filter to whr*/
		%if "&whr_filter." ^= "" %then %do;
			data _null_;
				%if "&whr." = "" %then %do;
					call symput("whr", "&whr_filter.");
				%end;
				%if "&whr." ^= "" %then %do;
					call symput("whr", cat("&whr.", " and ", "&whr_filter."));
				%end;
				run;
			%put &whr;
		%end;
	/*Creating the filtered dataset which will be used for regression*/
		data out.temporary;
			set %if "&group_path."^="" %then group.bygroupdata; %else in.dataworking; 
			; 
			%if "&whr." ^="" %then %do;
				where &whr.;
			%end;
			run;

		data out.totalfilter;
			filter="&whr.";
			run;

%mend localVars;
%localVars;