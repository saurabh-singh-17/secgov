/*Successfully converted to SAS Server Format*/
*processbody;

/*--------------------------------------------------------------------------------------------------------*/
/*--                                                                                                  	--*/   
/*-- Functionality Name :  Time-Series Split                                                        	--*/
/*-- Description  		:  Contains procedures to rollup the data and aggregate for plotting based		--*/
/*--						the selected plot metric													--*/
/*-- Return type  		:  Creates CSV's at a location according to given inputs                        --*/
/*-- Author       		:  Mohit Agrawal                                                                --*/                 
/*--------------------------------------------------------------------------------------------------------*/


/*PARAMETERS EXPECTED*/


/*%let input_path=D:/SASDatasets/split/in;*/
/*%let output_path=D:/SASDatasets/split/out; */
/*%let selected_vars = ACV;*/
/*%let grp_vars = geography store_format ;*/
/*%let date_vars = Date;*/
/*%let date_level = day;*/
/**/
/*%let flag_rollup = true;*/
/*%let rollup_level = year;*/
/*%let rollup_metric = total;*/
/**/
/*%let plot_metric = ;*/
/*%let plot_select = year;*/
/*%let plot_across = year;*/
/*%let plot_over = year;*/


dm log 'clear';
options mprint mlogic symbolgen mfile ;

proc printto log="&output_path/timeseries_split_Log.log";
run;
quit;
/**/
/**/
/*proc printto print="&output_path/timeseries_split_Output.out";*/
/**/


libname in "&input_path.";
libname out "&output_path.";

%macro timeseries_split;

	%let setstatement=;
/*Parameter modification */
	%if (&plot_select. = qtr) %then %let plot_select = quarter;
	%if (&plot_across. = qtr) %then %let plot_across = quarter;
	%if (&rollup_level. = qtr) %then %let rollup_level = quarter;

	%if (&plot_metric. = none) %then %let plot_metric = ;
	%if (&plot_metric. = total) %then %let plot_metric = sum;
	%if (&plot_metric. = average) %then %let plot_metric = avg;

	%if (&rollup_metric. = average) %then %let rollup_metric = avg;
	%if (&rollup_metric. = total) %then %let rollup_metric = sum;
	%if (&rollup_metric. = begin) %then %let rollup_metric = min;
	%if (&rollup_metric. = end) %then %let rollup_metric = max;

	%if (&plot_select. = ) %then %let plot_select = month;
	%let plot_over= year;

/**/

	/*3 Output columns*/
	%let col1 = &plot_select.;
	%let col2 = &plot_across.;
	%let col3 = &plot_over.;
/**/


	%if (&flag_rollup. = false) %then %let rollup_level = &plot_across.;

/*Sorting the data*/
	proc sort data=in.dataworking out = temp;
	by &grp_vars. &date_vars. ;
	run;
/**/

	data _null_;
			call symput("selected_vars1",substr("&selected_vars.",1,5));
		run;

		data temp;
			set temp;
			&selected_vars1.=&selected_vars.;
		run;

	%let selected_vars=&selected_vars1.;


	data _null_;
		%if (&grp_vars. ne )  %then %do;
			call symputx("panel_flag",tranwrd("&grp_vars."," "," || '[]' || ")); /*[] is used as a separator and later replaced to _ since its unlikely to occur in the values*/
			call symput("group_cols" ,cats(",", tranwrd("&grp_vars."," ",",")));
		%end;
		%else %do;
			%let panel_flag =0;
			%let group_cols=;
		%end;

	run;

	
/**Creating Level columns - they are used to roll up the data to a particular level**/

		%let levels = year quarter month week day;
		%let l =1;
		%let date_cols =;
		%let level_cols =;

		%do %until (%scan(&levels.,%eval(&l.-1)," ") = &rollup_level.);

				data _null_;
				call symput("this_level","%scan(&levels.,&l," ")");
				
				%if &l. >1  %then %do;
				%let x = %eval(&l. -1);
				call symput("last_level","%scan(&levels.,&x.," ")");
					
				%end;

				run;

				
				%let date_cols = &this_level., &date_cols. ;
				%let level_cols = l&this_level., &level_cols. ;
				/*Both date_cols and level_cols run from the highest level (year) till the rolledup level*/
				
				data temp (drop = quarter);
				set temp;
	
						%if (&this_level. = quarter) %then %do; 
						&this_level. = qtr(&date_vars.);
						qtr = quarter; /*qtr column is used to avoid recursion while concatenating 'Q'*/
						%end;
						%else %do;
						&this_level. = &this_level.(&date_vars.);
						%end;
	 
						%if &this_level. = week %then %do; &this_level. = &this_level. + 1; %end;

						%if &this_level. = year %then %do;
						l&this_level. = compress(&this_level.);
						%end;
						%else %do;
						%put &last_level.;
						l&this_level. = compress(l&last_level.) || "_" ||compress(&this_level.);
						%end;

					/* 3 special cases where the lower level values need to be adjusted acc to the higher level for the plot*/
				
						/*Case 1: Quarter across month - month to be limited to values 1,2 & 3*/
						%if (&plot_select. = quarter and &plot_across. = month) %then %do;
						qmonth = month -3*(qtr-1);	
						%end;
						
						/*Case 2: Month across week - week to be limited to values 1-5*/
						%if (&plot_select. = month and &plot_across. = week) %then %do;
						mweek = (intck('week',intnx('month',&date_vars.,0),&date_vars.)+1);
						%end;
						
						/*Case 3: Week across day - day to be limited to values 1-7*/
						%if (&plot_select. = week and &plot_across. = day) %then %do;
						wday = weekday(&date_vars.);
						%end;
					/**/
						
				run;
		
		%let l = %eval(&l. +1);

		%end;
		

/**Level Columns created**/
		
		
		data temp;
		set temp;
			format quarter $2.;
			/*Creating column quarter with values Q1 to Q4)*/
			%if (&plot_select. = quarter or &plot_across. = quarter) %then %do;
			quarter = cat("Q", qtr);
			%end;
			/**/
			
			/*For Case 1*/
			%if (&plot_select. = quarter and &plot_across. = month) %then %do;	
			month = qmonth;
			%end;

			/*For Case 2*/
			%if (&plot_select. = month and &plot_across. = week) %then %do;
			week = mweek;
			%end;

			/*For Case 3*/
			%if (&plot_select. = week and &plot_across. = day) %then %do;
			day = wday;
			%end;
		
		run;


/**Creating datasets for passing information to Flex*/
		proc datasets library=work;
			delete uniquenames;
			delete uniqueyears;
		run;

		data uniquenames;
			format names $50.;
			length names $50.;
		run;

		data uniqueyears;
			format year $4.;
			length year $4.;
		run;
/**/


/**Rolling up each continuous variable into separate datasets**/
		
		/*Looping for each continuous variable*/
		%let c = 1;
		%do %until (not %length(%scan("&selected_vars.",&c.)));
		%let this_var = %scan(&selected_vars,&c);
		%put &this_var.;

					/*If the user asks for rolling up then aggregate the data using rollup metric*/
					%if "&flag_rollup." = "true" %then %do;
							data temp;
							set temp;
							panel_flag1= compress(&panel_flag.);
							run;
							

							%if &rollup_metric. = sum or &rollup_metric. = avg %then %do;
							proc sql;
								create table rolledup_&this_var. as 
								select distinct panel_flag1 as panel_flag, &date_cols.  &level_cols. &rollup_metric.(&this_var.) as &this_var. &group_cols.
								from temp
								group by l&rollup_level. &group_cols.;
							quit;
							%end;

							%else %if &rollup_metric. = min or &rollup_metric. = max %then %do;
							proc sql;
								create table rolledup_&this_var. as
								select distinct  &panel_flag. as panel_flag, &date_cols. &level_cols. &this_var.  &group_cols.
								from temp
								group by  l&rollup_level. &group_cols.
								having &date_level. = &rollup_metric.(&date_level.);
							quit;
							%end;

							%else %if &rollup_metric. = middle %then %do;
							proc sql;
								create table rolledup_&this_var. as 
								select distinct &panel_flag. as panel_flag, &date_cols. &level_cols. &this_var. &group_cols.
								from temp
								group by l&rollup_level. &group_cols.
								having &date_level. = min(&date_level.) + floor(count(&date_level.)/2);
							quit;
							%end;

					%end;

					/*Otherwise just add the panel flag column. The values in the column are the distinct groups to be made*/
					%else %do;
							%let rollup_level = &date_level;
							proc sql;
								create table rolledup_&this_var. as
								select distinct &panel_flag. as panel_flag, &date_cols. &level_cols. &this_var. &group_cols. 
								from temp;
							quit;
					%end;


				
	/*Rolling up done*/
		

					proc sql;			
						select distinct panel_flag into :groups separated by ','
						from rolledup_&this_var.;
					quit;
					
					/*Looping for each group*/
				
					
					%do g = 1 %to %sysfunc(countw("&groups.",','));
						
						%let setstatement=;
						%let this_grp = %scan("&groups.",&g,",");
						
					
							/*Formatting panels according to CSV naming convention*/
							data _null_;
								call symput("this_grp",translate("&this_grp.",' ',"~@ %^&*()_+{}|:<>`-=?/,./;"));
								run;
								
							data _null_;
								call symput("this_grp",translate("&this_grp.",'_',"[]"));
								run;
								
							data _null_;
								call symput("this_grp",compress("&this_grp."));
								run;
							/**/
							
						
							
							
							data data_&c._&g. ( keep =  &rollup_level. &plot_select. &plot_across. &plot_over. &this_var. &grp_vars. panel_flag);
							set rolledup_&this_var. ; 
								
								%let col_a = %sysfunc(lowcase(&col1.));
								%let col_b = %sysfunc(lowcase(&col2.));
								%let col_c = %sysfunc(lowcase(&col3.));
								
							run;

							%let this_panel = %scan("&groups.",&g.,",");

							proc contents data=data_&c._&g. out=contentabc;
							run;

							proc sql;
							select type into :type1 separated by ' ' from contentabc where name="panel_flag";
							quit; 

							%if &type1.=1 %then %do; 
							proc sql;
							create table  data_&c._&g. as 
							select distinct * from data_&c._&g.
							where panel_flag = &this_panel.;
							quit;
							%end;

							%if &type1.=2 %then %do; 
							proc sql;
							create table  data_&c._&g. as 
							select distinct * from data_&c._&g.
							where panel_flag = "&this_panel.";
							quit;
							%end;
							

							


							/*If no metric is selected then separate csv is made for each year*/

							%if %length(&plot_metric) = 0 %then %do; 
							proc sql;
								select distinct &plot_over. into :years separated by ','
								from data_&c._&g.;
							quit;
							
								/*looping for each year*/
								%do y = 1 %to %sysfunc(countw("&years.",','));
								%let this_year = %scan("&years.",&y.,",");
									
									proc sql;
										create table &this_var._&g._&this_year. as 
										select  &this_var. as varname, &col_a. , &col_b. , &col_c.
										from data_&c._&g.
										where year = &this_year.
										group by &plot_select., &plot_across.,year ;
									quit;

									proc sql;
									create table &this_var._&g._&this_year. as 
									select distinct * from &this_var._&g._&this_year.;
									quit;

									data UN_&this_var._&g.;				
									names = "&this_var._&this_grp.";
									output;
									run;

									proc append base=uniquenames data=UN_&this_var._&g. force;
									run;
									quit;
								
									data UY_&this_year.;
									year = "&this_year.";
									output;
									run;

									proc append base=uniqueyears data=UY_&this_year. force;
									run;
									quit;

									proc contents data=&this_var._&g._&this_year. out=content;
									run;

									proc sql;
									select name into :names separated by ' ' from content  where name^="varname";
									quit;
									%put &names.; 

									data &this_var._&g._&this_year.;
										set &this_var._&g._&this_year.;
										%do i=1 %to %sysfunc(countw("&names.",' '));
												%scan(&names.,&i.," ")_a =compress(put(%scan(&names.,&i.," "),$8.));
												varname = varname;
												if length(%scan(&names.,&i.," ")_a)<2 then do;
												%scan(&names.,&i.," ")_a=cat("0",%scan(&names.,&i.," ")_a);
												end;
												drop %scan(&names.,&i.," ");
												rename %scan(&names.,&i.," ")_a=%scan(&names.,&i.," ");
										%end;

									run;
									%if "&plot_metric." = "" and "&plot_select."="year" and "&plot_over."="year" %then %do;
										%let setstatement=&setstatement. &this_var._&g._&this_year.;
								 	%end;
									data &this_var._&g._&this_year.(rename=(quarter=qtr));
										set &this_var._&g._&this_year.;
									run;
									proc export data = &this_var._&g._&this_year.
									outfile = "&output_path./&this_var._&this_grp._&this_year..csv"
									dbms = csv replace;
									run;
									
								%end;
								%if "&plot_metric." = "" and "&plot_select."="year" and "&plot_over."="year" %then %do;
									data &this_var._&g.(rename=(quarter=qtr));
						 			set &setstatement.;
									run;
									proc export data = &this_var._&g.
	 								outfile = "&output_path./&this_var._&this_grp..csv"
									dbms = csv replace;
	 								run;
								%end;

							
							%end;
							/**/
					
							%else %do; /*Plot metric given - Result aggregated for all years*/	

								proc sql;
									create table &this_var._&g. as 
									select  &plot_metric.(&this_var.) as varname,&col_a. , &col_b.
									from data_&c._&g.
									group by &plot_select., &plot_across.  ;
								quit;
								
								data &this_var._&g.;
								set &this_var._&g. (keep = varname &col_a.  &col_b. );
								run;

								proc sql;
								create table &this_var._&g. as 
								select distinct * from &this_var._&g.;
								quit;

									/*Unique Names*/
									data UN_&this_var._&g.;
									names = "&this_var._&this_grp.";
									output;
									if names = '' then delete;
									run;

									proc append base=uniquenames data=UN_&this_var._&g. force;
									run;
									quit;
	
									/**/
									proc contents data=&this_var._&g. out=content;
									run;

									proc sql;
									select name into :names separated by ' ' from content where name^="varname";
									quit; 

									data &this_var._&g.;
										set &this_var._&g.;
										%do i=1 %to %sysfunc(countw("&names.",' '));
												%scan(&names.,&i.," ")_a =compress(put(%scan(&names.,&i.," "),$8.));
												varname = varname;
												if length(%scan(&names.,&i.," ")_a)<2 then do;
												%scan(&names.,&i.," ")_a=cat("0",%scan(&names.,&i.," ")_a);
												end;
												drop %scan(&names.,&i.," ");
												rename %scan(&names.,&i.," ")_a=%scan(&names.,&i.," ");
 										%end;

									run;
								%if "&plot_metric." = "" and "&plot_select."="year" and "&plot_over."="year" %then %do;
										%let setstatement=&setstatement. &this_var._&g.;
								%end;


								data &this_var._&g.(rename=(quarter=qtr));
									set &this_var._&g.;
								run;


								proc export data = &this_var._&g.
								outfile = "&output_path./&this_var._&this_grp..csv"
								dbms = csv replace;
								run;

							%end;
					
					%end;
 		
		%let c = %eval(&c.+1);
		%end;
%if "&plot_metric." = "" and "&plot_select."="year" and "&plot_over."="year" %then %do;
	data &this_var._0(rename=(quarter=qtr));
		set &setstatement.;
	 run;

	 proc export data = &this_var._0
	 outfile = "&output_path./&this_var._0.csv"
	 dbms = csv replace;
	 run;
%end;

		
		proc sql;
		create table uniqueyears as 
		select distinct * from uniqueyears
		where year is not null;
		quit;
		
		proc sql;
		create table uniquenames as 
		select distinct * from uniquenames
		where names is not null;
		quit;

		proc export data = uniquenames
		outfile = "&output_path./uniquenames.csv"
		dbms = csv replace;
		run;
%if "&plot_across." = "quarter" %then %do;
	proc sql;
	create table uniqueyears as select distinct(year) from temp;
	quit;
%end;
%if "&plot_select." ^= ""  and "&plot_metric" = "" %then %do;		
		proc export data = uniqueyears
		outfile = "&output_path./uniqueyears.csv"
		dbms = csv replace;
		run;
%end;



%mend timeseries_split;

%timeseries_split;	


/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "TIMESERIES_SPLIT_COMPLETED";
	file "&output_path/TIMESERIES_SPLIT_COMPLETED.txt";
	put v1;
	run;



