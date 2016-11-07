*processbody;
%let completedTXTPath =  &output_path/ROLLUP_COMPLETED.txt;
/* VERSION : 1.0.0 */
options mprint mlogic symbolgen mfile;
dm log 'clear';
proc printto log="&output_path./Rollup_log.log";
run;
quit;
/*proc printto print="&output_path./Rollup_output.out";*/
/*quit;*/


	data _null_;
		call symput("newvarlist",translate("&newvarlist.",'_____________________________',"~@%^&*()_+{}|:<>?`-=[]/,.\; '"));
		%put &newvarlist.;
		run;
	data _null_;
		call symput("alldata",tranwrd("&all",",",""));
		run;
	data _null_;
		call symput("agg_var_catdata",tranwrd("&agg_var_cat","#"," "));
		run;
	data _null_;
		call symput("non_vars_new",tranwrd("&non_vars_new",","," "));
	run;

%macro stringsub;
	%put newvarlist;
	%do k=1 %to %sysfunc(countw("&newvarlist.","$"));
		%if &k.=1 %then %do;
			%let temp=%scan("&newvarlist.",&k.,"$");
			%let temp=%substr(&temp,1,32);
			%let newvarlist1=&temp;
		 %end;
		%else %do;
			%let temp=%scan("&newvarlist.",&k.,"$");
			%let temp=%substr(&temp,1,32);
			%let newvarlist1=&newvarlist1$&temp;
	 	%end;
	%end;
		%let newvarlist=&newvarlist1;
		%put &newvarlist.;
%mend;
%stringsub;

/*	data _null_;*/
/*		call symput("non_vars",compbl("&non_vars"));*/
/*		run;*/


/*defining the libraries*/
libname in "&input_path.";
libname out "&output_path.";
%macro rollup;
	%if "&non_vars." ^="" %then %do;
		data _null_;
			call symput("non_vars",compbl("&non_vars"));
			run;
	%end;
	%if "&non_vars." ^="" %then %do;
		data _null_;
			call symput("non_vars1",tranwrd("&non_vars"," ",","));
			run;
		%put &non_vars1;
	%end;

/*date variables*/
/*creating temp dataset containing all variables required*/
%let date_list=;

/*proc sql;*/
/*	create table temp as*/
/*		select &all.*/
/*			%if "&non_vars." ^= "" %then ,&non_vars1. ;*/
/*			%if "&group_var_date." ^= "" %then %do;*/
/*				*/
/*				%do i=1 %to %sysfunc(countw("&group_var_date."));*/
/*				*/
/*					%if "%scan(&date_Fun.,&i.," ")" = "week_month" %then %do;*/
/*					,intck('week',intnx('month',%scan(&group_var_date.,&i.," "),0),%scan(&group_var_date.,&i.," "))+1 as %scan(&date_Fun.,&i.," ")_%scan(&group_var_date.,&i.," ") */
/*					%end;*/
/*					%else %do;*/
/*					,%scan(&date_Fun.,&i.," ")(%scan(&group_var_date.,&i.," ")) as %scan(&date_Fun.,&i.," ")_%scan(&group_var_date.,&i.," ") */
/*					%end;*/
/*					*/
/*					%let date_list=&date_list. %scan(&date_Fun.,&i.," ")_%scan(&group_var_date.,&i.," ");*/
/*				%end;*/
/*				%scan(&date_Fun.,&i.," ")(%scan(&group_var_date.,&i.," ")) as %scan(&date_Fun.,&i.," ")_%scan(&group_var_date.,&i.," ")*/
/*				%let date_list=&date_list. %scan(&date_Fun.,&i.," ")_%scan(&group_var_date.,&i.," ");*/
/*			%end;*/
/*			from in.&dataset_name.;*/
/*			quit;*/
/*	%put &group_var_cat.;*/
/*	%put &date_list.;*/

		data temp;
		set in.&dataset_name.;
/*			%if "&non_vars." ^= "" %then %do;*/
			%if "&group_var_date." ^= "" %then %do;
				
			%do i=1 %to %sysfunc(countw("&group_var_date."));
		%let new_name= %scan(&date_Fun.,&i.," ")_%scan(&group_var_date.,&i.," ");	
		%put &new_name.;	
		%if "%scan(&date_Fun.,&i.," ")" = "week_month" %then %do;
			week=intck('week',intnx('month',%scan(&group_var_date.,&i.," "),0),%scan(&group_var_date.,&i.," "))+1;
			mon=month(%scan(&group_var_date.,&i.," "));
			if mon < 10 then mon1=cat("0",mon);
			else mon1=mon;
			&new_name.=catx("-",mon1,week);
		%end;
		%if "%scan(&date_Fun.,&i.," ")" = "qtr_year" %then %do;
			&new_name.=put(%scan(&group_var_date.,&i.," "),YYQ10.);
		%end;
		%if "%scan(&date_Fun.,&i.," ")" = "month_year" %then %do;
			%scan(&date_Fun.,&i.," ")_%scan(&group_var_date.,&i.," ")=put(%scan(&group_var_date.,&i.," "),YYMMD.);
		%end;
		%if "%scan(&date_Fun.,&i.," ")" = "week_month_year" %then %do;
			
			week_mon=intck('week',intnx('month',%scan(&group_var_date.,&i.," "),0),%scan(&group_var_date.,&i.," "))+1;;
			mon_year=%scan(&group_var_date.,&i.," ");
			&new_name.=catx("-",put(mon_year,YYMMD.),week_mon);
		%end;
		%if "%scan(&date_Fun.,&i.," ")" = "qtr" %then %do;
		 &new_name.=qtr(%scan(&group_var_date.,&i.," "));
		%end;
		%if "%scan(&date_Fun.,&i.," ")" =  "month" %then %do;
		 &new_name.=month(%scan(&group_var_date.,&i.," "));
		%end;
		%if "%scan(&date_Fun.,&i.," ")" = "year" %then %do;
		 &new_name.= year(%scan(&group_var_date.,&i.," "));
		%end;
		%if "%scan(&date_Fun.,&i.," ")" = "week" %then %do;
		week=week(%scan(&group_var_date.,&i.," "));
		if week<10 then week1=cat("0",week);
		else week1=week;
		year=year(%scan(&group_var_date.,&i.," "));
		 &new_name.= catx("_",year,week1);
		%end;
	
		%let date_list=&date_list. &new_name.;
		%end;
/*				%scan(&date_Fun.,&i.," ")(%scan(&group_var_date.,&i.," ")) as %scan(&date_Fun.,&i.," ")_%scan(&group_var_date.,&i.," ")*/
/*				%let date_list=&date_list. %scan(&date_Fun.,&i.," ")_%scan(&group_var_date.,&i.," ");*/
			%end;
/*			%end;*/
	
	run;
	%let group_var_cat=&group_var_cat. &date_list.;
	data _null_;
			call symput("group_var_cat",compbl("&group_var_cat."));
			run;
	data _null_;
		call symput("cont_grp_var",tranwrd("&group_var_cat"," ",","));
		run;
/*sorting temp dataset*/
proc sort data=temp;
	by &group_var_cat.;
	run;
/***********************************************CONTINUOUS VARIABLES METRIC CALC************************************************/
/*getting metrics for all the variables sent in agg_var_cont*/
	%if "&agg_var_Cont." ^= "" %then %do;
		proc sql;
			create table cont_out as
			select &cont_grp_var.,
				%do i=1 %to %sysfunc(countw("&agg_var_Cont."," "))-1; 
						%if ("%scan(&metrics,&i.)" = "UNICOUNT" or "%scan(&metrics,&i.)" = "PERCENT") %then COUNT; 
						%else %scan(&metrics.,&i.," ");
					(%if ("%scan(&metrics,&i.)" = "UNICOUNT") %then distinct ;%scan(&agg_var_Cont.,&i.," ")) as %scan(&newvarlist,&i.,"$") ,
				%end;

					%if ("%scan(&metrics,&i.)" = "UNICOUNT" or "%scan(&metrics,&i.)" = "PERCENT")  %then COUNT; 
					%else %scan(&metrics.,&i.," ");
				(%if ("%scan(&metrics,&i.)" = "UNICOUNT") %then distinct ;%scan(&agg_var_Cont.,&i.," ")) as %scan(&newvarlist,&i.,"$") 
				from temp
				group by &cont_grp_var.;
				quit;
/*calculating percentages for required metrics*/
		%do i=1 %to %sysfunc(countw("&agg_var_Cont."," ")); 
			%if "%scan(&metrics,&i.)" = "PERCENT"  %then %do;
				data temp4;
					merge cont_out temp(keep= &group_var_cat. &agg_var_cont. );
					by &group_var_cat.;
					run;
				proc sql;
					create table percentcols as
					select *,%scan(&newvarlist.,&i.,"$")/count(%scan(&agg_var_cont.,&i.," "))*100 as percent&i from temp4
					group by &cont_grp_var.;
					quit;
				data cont_out;
					set percentcols(drop=%scan(&newvarlist.,&i.,"$"));
					rename percent&i=%scan(&newvarlist.,&i.,"$");
					run;
			%end;
		%end;
	 %end;
/***********************************************CATEGORICAL LEVELS METRIC CALC************************************************/
/*Metric calculation for levels of categorical variables*/
	%if "&agg_var_cat." ^= "" %then %do;
		data _null_;
			call symput("agg_var_cat_level",tranwrd("&agg_var_cat_level.","# ","#"));
			run;
		data _null_;
			call symput("keep_levels",translate("&agg_var_cat_level.",'______________________________',"~@$%^&*()_+{}|:<>?`-=[]\,./; '"));
			run;
		data _null_;
			call symput("keep_levels",tranwrd("&keep_levels.","#"," "));
			call symput("grp_var_catsql",tranwrd("&group_var_cat"," ",","));
			run;

		%do j=1 %to %sysfunc(countw("&agg_var_cat.","#"));

		%let met_cont=%eval(%sysfunc(countw("&agg_var_Cont."," "))+ &j.);
			ods output OneWayFreqs=OneWayFreqs&j.;
			proc freq data= temp;
				tables %scan(&agg_var_cat.,&j.,"#");
				by &group_var_cat.;
				run;

			proc transpose data=OneWayFreqs&j. out=OneWayFreqs&j. (drop=_Name_);
				id %scan(&agg_var_cat.,&j.,"#");
				var Frequency;
				by &group_var_cat.;
				run;
/*renaming the levels of cat vars to the newvarlist*/
			data OneWayFreqs&j.(keep=&group_var_cat. %scan(&newvarlist.,%eval(%sysfunc(countw("&agg_var_Cont."," "))+ &j.),"$"));
				set OneWayFreqs&j.;
				rename %scan(&keep_levels.,&j.," ")=%scan(&newvarlist.,&met_cont,"$");
				run;
/*calculating unicount of levels whereever required*/
			data OneWayFreqs&j.;
				set OneWayFreqs&j.;
				%if "%scan(&metrics.,&met_cont," ")" = "UNICOUNT" %then %do;
					if %scan(&newvarlist.,&met_cont,"$") >0 then %scan(&newvarlist.,&met_cont,"$")=1;
				%end;
				run;

			data OneWayFreqs&j.;
				merge OneWayFreqs&j. temp
					(keep=&group_var_cat. &agg_var_catdata.);
				by &group_var_cat.;
				run;

			%if &j=1 %then %do;
				data cat_out;
					set OneWayFreqs1;
					by &group_var_cat.;
					run;
			%end;
			%else %do;
				data cat_out;
					merge cat_out OneWayFreqs&j.;
					by &group_var_cat.;
					run;
			%end;
		%end;

/*calculate percent for categorical*/
		%if &agg_var_Cont.^= %then %let f = %eval(%sysfunc(countw("&agg_var_Cont."," "))+1);
			%else %let f = 1; 
			;
		%let k=1;	
		%let catvarlist=;
		%do f= &f. %to %sysfunc(countw("&metrics"," "));
			%if "%scan(&metrics,&f.," ")" = "PERCENT" %then %do;
			proc sql;
				create table percentcols as
				select *,%scan(&newvarlist.,&f.,"$")/count(%scan(&agg_var_cat.,&k.,"#"))*100 as percent&f from cat_out
				group by &grp_var_catsql.;
				quit;
			data cat_out;
				set percentcols(drop=%scan(&newvarlist.,&f.,"$"));
				rename percent&f =%scan(&newvarlist.,&f.,"$");
				run;
			%let k=%eval(&k+1);	
			%end;
			data _null_;
				call symput("catvarlist","&catvarlist %scan(&newvarlist.,&f.,'$')");
				run;
		%end;

/*		data _null_;*/
/*			call symput("newvarlist",tranwrd("&newvarlist","$"," "));*/
/*			run;*/

		data cat_out;
			set cat_out(keep=&catvarlist. &group_var_cat. );
			run;

/*Removing duplicates */
	proc sql;
		create table cat_out as
		select unique * from cat_out;
		quit;
	%end;

/*creating temp3 for nonvars to include in the output*/

	data temp3;
		set temp(keep=&group_var_cat. &non_vars.);
		run;
%if "&non_vars." ^= "" %then %do;
	 data temp3;
		set temp3;
		%do b=1 %to %sysfunc(countw("&non_vars."," "));
		%scan("&non_vars_new.",&b.," ")= %scan("&non_vars.",&b.," ");
		%end;
		run;
%end;

	

	data _null_;
		call symput("newvarlist",tranwrd("&newvarlist","$"," "));
		run;
/*merge continuous categorical and nonvars datasets*/
	data &new_Dataset_name.(keep=&group_var_cat. &newvarlist. &non_vars_new.);
		merge %if "&agg_var_Cont." ^="" %then %do;
				    cont_out 
			  %end;
			  %if "&agg_var_cat." ^="" %then %do;
			    	cat_out 
			  %end;
  			  %if "&non_vars." ^="" %then %do;
		    		temp3
			  %end;
			  ;
		by &group_var_cat.;
		run;
/*getting unique values from output dataset*/
	%if "&non_vars." = "" %then %do;
	proc sql;
		create table &new_Dataset_name. as
		select unique * from &new_Dataset_name.;
		quit;
	%end;
/*creating dataset in output path*/
	data out.&new_Dataset_name.;
		set &new_Dataset_name.;
		run;				
%mend rollup;
%rollup;
/*export rollup in csv format*/
proc export data=out.&new_Dataset_name.
		outfile= "&output_path./&new_Dataset_name..csv"
		dbms=csv replace;
		run;

	ods output members = properties(where=(lowcase(name)=lowcase("&new_Dataset_name.")) keep=name obs vars FileSize);
	proc datasets details library = out;
		run; 
		quit ;

	/*libname prop xml "&output_path./dataset_properties.xml";*/
	data properties;
		set properties(rename =(name=file_name obs=no_of_obs vars=no_of_vars fileSize = file_size));
		format file_size 12.4;
		file_size = file_size/(1024*1024);
		run;

	/*CSV export*/
	 proc export data = properties
		outfile="&output_path/dataset_properties.csv"
		dbms=CSV replace;
		run;

		proc datasets lib=work kill nolist;
		run;
		quit;


/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "ROLLUP_COMPLETED";
	file "&output_path/ROLLUP_COMPLETED.txt";
	put v1;
	run;
