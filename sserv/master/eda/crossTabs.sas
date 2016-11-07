options mprint mlogic symbolgen mfile;

%let completedTXTPath = &output_path/CROSSTABS.txt;

FILENAME MyFile "&output_path./GENERATE_FILTER_FAILED.txt" ;
DATA _NULL_ ;
	rc = FDELETE('MyFile');
	RUN ;
proc printto log="&output_path/crosstabs.log";
	run;quit;

/*proc printto;*/
/*run;*/

dm log 'clear';

libname in "&input_path.";
libname out "&output_path.";

/* separating "," by "_"for the chisq output */

data _null_;
		call symput("xchi", tranwrd("&selected_vars.",",","_"));
		call symput("ychi", tranwrd("&pivot_vars.",",","_"));

/* separating "," by ",'_'," for concatenating the , separated variables */

data _null_;
		call symput("x", tranwrd("&selected_vars.",",",",'_',"));
		call symput("y", tranwrd("&pivot_vars.",",",",'_',"));
		run;

/* separating !! and , by space so as to keep only the required variables */

data _null_;
		call symput("xkeep", tranwrd(tranwrd("&selected_vars.",","," "),"!!"," "));
		call symput("ykeep", tranwrd(tranwrd("&pivot_vars.",","," "),"!!"," "));
		run;

%macro filter;
%global dataset_name;
		%if "&flag_filter." = "true" %then %do;
		%let dataset_name=  out.temporary;
		%let whr=;
	 	/*call SAS code for dynamic filtering*/
		%include %unquote(%str(%'&filterCode_path./dynamicFiltering.sas%')); 
	%end;
		%else %do;
		%let dataset_name=in.dataworking;
		%end;
%mend;
%filter;

%macro unique_crosstabs;
%do q=1 %to %sysfunc(countw("&pivot_vars.","!!"));
%let new_pivot_var=%scan(&pivot_vars.,&q.,"!!");
%put &new_pivot_var.;
%if %sysfunc(length(&new_pivot_var.)) > 25 %then %do;
%let new_pivot_vars=%substr(&new_pivot_var.,1,25);
%end;
%else %do;
%let new_pivot_vars=&new_pivot_var.;
%end;


	proc sql;
			create table unique_&new_pivot_vars. as
			select distinct %scan(&pivot_vars.,&q.) into: count from &dataset_name.;
		quit;
		
proc export data = unique_&new_pivot_vars.
				outfile = "&output_path./unique_&new_pivot_vars..csv"
				dbms = CSV replace;
			run;
%end;
%do p=1 %to %sysfunc(countw("&selected_vars.","!!"));

%let new_selected_var=%scan(&selected_vars.,&p.,"!!");
%put &new_selected_var.;
%if %sysfunc(length(&new_selected_var.)) > 25 %then %do;
%let new_selected_vars=%substr(&new_selected_var.,1,25);
%end;
%else %do;
%let new_selected_vars=&new_selected_var.;
%end;
	proc sql;
			create table unique_&new_selected_vars. as
			select distinct %scan(&selected_vars.,&p.) into : count from &dataset_name.;
		quit;

proc export data = unique_&new_selected_vars.
				outfile = "&output_path./unique_&new_selected_vars..csv"
				dbms = CSV replace;
			run;
%end;
%if "&flag_cmh." ^= "false" %then %do; 
	proc sql;
			create table uniqueValues as
			select distinct &control_Variable. into : count from &dataset_name.;
		quit;

proc export data = uniqueValues
				outfile = "&output_path./uniqueValues.csv"
				dbms = CSV replace;
			run;
%end;

%mend;
%unique_crosstabs;


%macro cmh;
	%let y_var=;
	%let x_var=;
	%let relriskcol=;
	%let uniqueval=;
	%let sep=;

	%do i=1 %to %sysfunc(countw("&pivot_vars.","!!"));

		proc sql;
			select count(distinct %scan(&pivot_vars.,&i.)) into: count from one;
		quit;

		%if &count. = 2 %then
			%do;
				%let yCMH = %scan(&pivot_vars.,&i.);
				%let y_var = &yCMH. &y_var.;
				%let relriskcol=&relriskcol. %scan(&relriskcolumn.,&i.,"!!");
				%if "&uniqueval." ^= "" %then %let sep=!!;
				%let uniqueval=&uniqueval.&sep.%scan(&unique_Values.,&i.,"!!");
			%end;
	%end;

	%do i=1 %to %sysfunc(countw("&selected_vars.","!!"));

		proc sql;
			select count(distinct %scan(&selected_vars.,&i.)) into: count from one;
		quit;

		%if &count. = 2 %then
			%do;
				%let xCMH = %scan(&selected_vars.,&i.);
				%let x_var = &xCMH. &x_var.;
			%end;
	%end;

	%if "&x_var." = "" or "&y_var." = "" %then
		%do;

			data _NULL_;
				v1 = "CMH test can be applied only on 2x2 contingency tables. The variables selected are not binary variables.";
/*				v1= "CMH Test not possible. Select atleast one binary variable in both selected and pivot variables tab.";*/
				file "&output_path./CMH_failed.txt";
				PUT v1;
			run;

		%end;

	%do i=1 %to %sysfunc(countw("&y_var."," "));
		%do j=1 %to %sysfunc(countw("&x_var."," "));

			data final;
				set one(keep= &control_Variable. %scan(&y_var.,&i.) %scan(&x_var.,&j.));
			run;
			
			proc sort data=final out=final;
				by &control_Variable. %scan(&y_var.,&i.) %scan(&x_var.,&j.);
			run;
			quit;

			data final;
				retain count 1;
				set final;
				by &control_Variable. %scan(&y_var.,&i.) %scan(&x_var.,&j.);
				if first.&control_Variable. or first.%scan(&y_var.,&i.) or first.%scan(&x_var.,&j.)
					then count = 1;
				count = count + 1;
				if last.&control_Variable. or last.%scan(&y_var.,&i.) or last.%scan(&x_var.,&j.);
			run;


			ods output CMH= CMHstatistics;
			ods output CommonRelRisks= CRRestimates;
			ods output BreslowDayTest= BreslowDayTest;
			ods output crosstabfreqs=togetcol1col2names;
			ods output chisq= chisq;
			 %if &type.=count %then %do;
			ods output CrossTabFreqs = cross;
			%end;
/*			ods output OneWayChiSq = chiSq1;*/
/*			ods output OneWayChiSqMc = chisq12;*/
			

			proc freq data=final;
				tables &control_Variable.*%scan(&x_var.,&j.)*%scan(&y_var.,&i.) / chisq cmh;
				weight count;
				title 'abcd';
			run;
			
			goptions device = gif gsfname=fileref gsfmode=replace;
			ods graphics on;
			ods listing gpath="&output_path./%scan(&y_var.,&i.)/%scan(&x_var.,&j.)";
/*----------------------------------------------------*/
ods output Freq.Table1.CrossTabFreqs=freqtable;

proc freq data=final;
tables %scan(&x_var.,&j.)*&control_Variable. ;
quit;

proc sql;
select &control_Variable. into: names_list separated by " " from freqtable 
where _type_ ="01" and frequency = 4;
quit;

%let names=%sysfunc(tranwrd(%str("&names_list."),%str( ),%str(",")));

data final_temp;
set final;
if &control_Variable. in (&names.);
run;

/*----------------------------------------------------*/
			proc freq data=final_temp;
				tables &control_Variable.*%scan(&x_var.,&j.)*%scan(&y_var.,&i.) / relrisk plots(only)=relriskplot(stats column=%scan(&relriskcol.,&i.)) cmh noprint;
				weight count;
				title 'abcd';
			run;

			ods graphics off;
			/*---------------------------------------------------------------------------------------
			Crosstabs level-wise
			---------------------------------------------------------------------------------------*/
			proc sql;
			create table new_unique as 
			select distinct(&control_Variable.) as  uni_cont from &dataset_name.;
			run;
			quit;
			

			data new_unique(keep=uni_cont1 key_use rename=(uni_cont1=uni_cont));
			set new_unique;
			uni_cont1= put(uni_cont,32.);
			if missing(uni_cont) then delete;
			run;
			

			data new_unique;
			set new_unique;
			key_use=_n_;
			run;

			proc sql;
			select distinct(uni_cont) into: uni_cont_var separated by '##' from new_unique;
			run;
			quit;


			%put &uni_cont_var.;

			data _null_;
			call symput("uni_cont_var1",translate("&uni_cont_var.","_____________________________","~@%^&*()+{}|:<>?`-=[]\,./; "));
			run;

			%put &uni_cont_var1.;

		

			%do m = 1 %to %sysfunc(countw(&uni_cont_var.,"##"));
			%let level_control_var=%scan(&uni_cont_var.,&m.,"##");
			%let level_control_var1=%scan(&uni_cont_var1.,&m.,"##");

			%let dsid = %sysfunc(open(&dataset_name.));
			%let varnum = %sysfunc(varnum(&dsid,&control_Variable.));
			%put &varnum;
			%let vartyp = %sysfunc(vartype(&dsid,&varnum)); /* variable type */
			%let rc = %sysfunc(close(&dsid));
			%put &vartyp;

			 %if &type.=count %then %do;


		data %scan(&x_var.,&j.)_&level_control_var1.(drop= _TYPE_ _TABLE_ Missing Table %scan(&x_var.,&j.) %scan(&y_var.,&i.));
			set cross;
			%If "&vartyp."= "N" %then %do;
			where &control_Variable.= &level_control_var.;
			%end;
			%else %do;
			where &control_Variable.= "&level_control_var.";
			%end;
			a&j.=compress(%scan(&x_var.,&j.));
			b&i.=compress(%scan(&y_var.,&i.));
			run;
	data %scan(&x_var.,&j.)_&level_control_var1.(rename=(b&i.=%scan(&y_var.,&i.) a&j.=%scan(&x_var.,&j.) Frequency=value Percent=absolute));
			set %scan(&x_var.,&j.)_&level_control_var1.;
			if a&j.="."  then a&j.="total";
			if a&j.=""  then a&j.="total";
			if a&j.="-"  then a&j.="total";
			if b&i.="."  then b&i.="total";
			if b&i.=""  then b&i.="total";
			if b&i.="-"  then b&i.="total";
			run;
%end;
%else %do;

		data %scan(&x_var.,&j.)_&level_control_var1.(drop=%scan(&x_var.,&j.) %scan(&y_var.,&i.)  
													rename=( __&i.=%scan(&y_var.,&i.) _&j.=%scan(&x_var.,&j.)));
			set one;
				_&j.=left(%scan(&x_var.,&j.));
				__&i.=left(%scan(&y_var.,&i.));
/*				_&i.&j.=left(&control_Variable.);*/
			run;


			data %scan(&x_var.,&j.)_&level_control_var1.;
			set %scan(&x_var.,&j.)_&level_control_var1.;
			%If "&vartyp."= "N" %then %do;
			where &control_Variable.= &level_control_var.;
			%end;
			%else %do;
			where &control_Variable.= "&level_control_var.";
			%end;
			run;

		proc sql;
				 create table %scan(&x_var.,&j.)_&level_control_var1. as
				 select %scan(&y_var.,&i.), %scan(&x_var.,&j.),&metric.(&var_name.) as &metric.
				 from  %scan(&x_var.,&j.)_&level_control_var1.
				 group by %scan(&y_var.,&i.), %scan(&x_var.,&j.);
				 quit;

	/* calculating rowsum colsum and absolute sum */

			proc sql;
				create table %scan(&x_var.,&j.)_&level_control_var1. as
					select *,sum(&metric.) as colsum
					from %scan(&x_var.,&j.)_&level_control_var1.
					group by  %scan(&x_var.,&j.);

				create table %scan(&x_var.,&j.)_&level_control_var1. as
					select *,sum(&metric.) as rowsum
					from %scan(&x_var.,&j.)_&level_control_var1.
					group by %scan(&y_var.,&i.);

				create table %scan(&x_var.,&j.)_&level_control_var1. as
					select *,sum(&metric.) as abssum
					from %scan(&x_var.,&j.)_&level_control_var1.;

				create table total1&j.&i._&level_control_var1. as
				select %scan(&y_var.,&i.),sum(&metric.) as &metric.,sum(abssum) as abssum from %scan(&x_var.,&j.)_&level_control_var1.
				group by %scan(&y_var.,&i.);

				create table total11&j.&i._&level_control_var1.  as
				select sum(&metric.) as &metric. from total1&j.&i._&level_control_var1.;

				create table total2&j.&i._&level_control_var1.  as
				select %scan(&x_var.,&j.), sum(&metric.) as &metric.,sum(abssum) as abssum from %scan(&x_var.,&j.)_&level_control_var1.
				group by %scan(&x_var.,&j.);
				quit;
					
proc append base=%scan(&x_var.,&j.)_&level_control_var1. data=total1&j.&i._&level_control_var1. force;
run;
proc append base=%scan(&x_var.,&j.)_&level_control_var1. data=total11&j.&i._&level_control_var1. force;
run;
proc append base=%scan(&x_var.,&j.)_&level_control_var1. data=total2&j.&i._&level_control_var1. force;
run;

data %scan(&x_var.,&j.)_&level_control_var1.(drop=colsum rowsum &metric. abssum);
		set %scan(&x_var.,&j.)_&level_control_var1.;
		value=&metric.;
		ColPercent=(&metric./colsum)*100;
		RowPercent=(&metric./rowsum)*100;
		absolute=(&metric./abssum)*100;
			if %scan(&x_var.,&j.)="."  then %scan(&x_var.,&j.)="total";
			if %scan(&x_var.,&j.)=""   then %scan(&x_var.,&j.)="total";
			if %scan(&x_var.,&j.)="-"  then %scan(&x_var.,&j.)="total";
			if %scan(&y_var.,&i.)="."  then %scan(&y_var.,&i.)="total";
			if %scan(&y_var.,&i.)=""   then %scan(&y_var.,&i.)="total";
			if %scan(&y_var.,&i.)="-"  then %scan(&y_var.,&i.)="total";
		run;

		proc sql;
			select count(distinct %scan(&y_var.,&i.)) into: pivot_count from one;
		quit;


data %scan(&x_var.,&j.)_&level_control_var1.;
set %scan(&x_var.,&j.)_&level_control_var1.;
%if &pivot_count. > 1 %then %do;
if  %scan(&x_var.,&j.)="total" then absolute=2*absolute;
if %scan(&y_var.,&i.)="total" then absolute=2*absolute;
%end;
run;

/*		%let xx_name=%scan("&x.",&j.,"!!");*/
/*		%let yy_name=%scan("&y.",&i.,"!!");*/
/**/
/*		data freqj&j.i&i.(rename=(b&i.=&yy_name. a&j.=&xx_name.));*/
/*			set freqj&j.i&i. ;*/
/*			run;*/



/*			data %scan(&x_var.,&j.)_&level_control_var1.(rename=(b&i.=%scan(&y_var.,&i.) a&j.=%scan(&x_var.,&j.) Frequency=value Percent=absolute));*/
/*			set %scan(&x_var.,&j.)_&level_control_var1.;*/
/*			if a&j.="."  then a&j.="total";*/
/*			if a&j.=""  then a&j.="total";*/
/*			if a&j.="-"  then a&j.="total";*/
/*			if b&i.="."  then b&i.="total";*/
/*			if b&i.=""  then b&i.="total";*/
/*			if b&i.="-"  then b&i.="total";*/
/*			run;*/
%end;
			options missing="-";
			proc export data = %scan(&x_var.,&j.)_&level_control_var1.
				outfile = "&output_path./%scan(&y_var.,&i.)/%scan(&x_var.,&j.)/%scan(&x_var.,&j.)_&level_control_var1..csv"
				dbms = CSV replace;
			run;
			
			%let excerpt = Table &m. of;

			%if "&flag_chisq_relation."= "true" %then %do;
			%if %sysfunc(exist(chisq)) ^= 0 %then
				%do;
			data temp;
			set chisq;
			run;

			data temp;
				set temp;
				if index(Table,"&excerpt.") > 0 then newcol = "&level_control_var.";
				run;

			data chi_sq_&level_control_var1.(drop=table);
				set temp;
				where newcol="&level_control_var.";
				run;

			data chi_sq_&level_control_var1.(drop=newcol rename=(prob=Prob statistic=Statistic value=Value));
			retain Selected_var Pivot_var Statistic DF Value Prob Result;
			length result $15.;
			set chi_sq_&level_control_var1.;
			where statistic="Chi-Square";
			if prob <= &pvalue_cutoff. then Result = "Significant";
			else Result = "Insignificant";
			run;

	%let new=chi_sq_&level_control_var1.;
	%let dsid = %sysfunc(open(&new.));
	%let nobs =%sysfunc(attrn(&dsid.,NOBS));
	%let rc = %sysfunc(close(&dsid));
	%put &NOBS.;

	%if &NOBS. = . or &NOBS.=0 %then
		%do;

			data _null_;
				v1= "There are no observations for some of the levels, so chi square statistics cannot be calculated ";
				file "&output_path./%scan(&y_var.,&i.)/%scan(&x_var.,&j.)/chi_sq_&level_control_var1..txt";
				put v1;
			run;

		%end;
	%else
		%do;
			options missing="-";
			proc export data = chi_sq_&level_control_var1
				outfile = "&output_path./%scan(&y_var.,&i.)/%scan(&x_var.,&j.)/chi_sq_&level_control_var1..csv"
				dbms = CSV replace;
			run;
			%end;
			%end;

			%end;
			%if %sysfunc(exist(chisq)) = 0 %then
				%do;
				%let errornote = chiSq is not possible;
			data _null_;
				v1= "&errornote.";
				file "&output_path./%scan(&y_var.,&i.)/%scan(&x_var.,&j.)/chi_sq_&level_control_var1..txt";
				put v1;
			run;
				%end;
			
%end;

			/*-----------------------------------------------------------------------------------------
			Error check
			-----------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------*/
            %let dsid         = %sysfunc(open(&dataset_name.));
			%let varnum       = %sysfunc(varnum(&dsid,%scan(&y_var.,&i.)));
			%put &varnum;
			%let vartyp_pivot = %sysfunc(vartype(&dsid,&varnum)); /* variable type */
			%let rc           = %sysfunc(close(&dsid));
			%put &vartyp_pivot;
/*==========================================================*/
/*			above code was written to replace the below piece of code*/

/*%let dsid = %sysfunc(open(togetcol1col2names));*/
/*			%let type_yvar=%sysfunc(attrn(&dsid.,type));*/
/*			%let rc=%sysfunc(close(&dsid.));*/
/*             %put &type_yvar.;*/
/*==========================================================*/
/*---------------------------------------------------------------------*/

			%let currentuniqueval = %scan(&uniqueval.,&i.,"!!");
			%if "&vartyp_pivot." = "C" %then %let currentuniqueval = "&currentuniqueval.";

			data togetcol1col2names_tempe;
				retain product 1;
				set togetcol1col2names(keep=_type_ %scan(&y_var.,&i.) %scan(&x_var.,&j.) &control_Variable. frequency) end=end;
				if %scan(&y_var.,&i.)=&currentuniqueval. then product = product * frequency;
				if end then call symput("product",product);
				if %scan(&y_var.,&i.)=&currentuniqueval. and _type_ = "111";
			run;			

			%let error_control_level=;
			%let error_xvar_level=;
			%let error_yvar_level=;
			%if &product. = 0 %then
				%do;
/*					proc sql;*/
/*						select &control_Variable. into: error_control_level separated by "!!" from togetcol1col2names_tempe where frequency = 0;*/
/*						select %scan(&x_var.,&j.) into: error_xvar_level separated by "!!" from togetcol1col2names_tempe where frequency = 0;*/
/*						select %scan(&y_var.,&i.) into: error_yvar_level separated by "!!" from togetcol1col2names_tempe where frequency = 0;*/
/*					run;*/
/*					quit;*/
/**/
/*					%let errortext=;*/
/*					%let and=;*/
/*					%do error_i = 1 %to %sysfunc(countw(&error_control_level.,"!!"));*/
/*						%let current_error_control_level=%scan(&error_control_level.,&error_i.,"!!");*/
/*						%let current_error_xvar_level=%scan(&error_xvar_level.,&error_i.,"!!");*/
/*						%let current_error_yvar_level=%scan(&error_yvar_level.,&error_i.,"!!");*/
/*						%if &error_i. > 1 %then %let and=and;*/
/*						%let errortext=&errortext. &and. &control_Variable. = &current_error_control_level, %scan(&x_var.,&j.) = &current_error_xvar_level., %scan(&y_var.,&i.) = &current_error_yvar_level.;*/
/*					%end;*/

/*					%let errortext = Odds ratio plot was not plotted because there are 0 observations for &errortext.;*/

					%let errortext = Odds ratio plot was not plotted because there are 0 observations for the selected variables.;

					data _null_;
						v1= "&errortext.";
						file "&output_path./%scan(&y_var.,&i.)/%scan(&x_var.,&j.)/oddsratioplot_error.txt";
						put v1;
					run;
				%end;

			%let error_control_level=;
			%let error_xvar_level=;
			%let error_yvar_level=;
			%if %sysfunc(exist(breslowdaytest)) = 0 %then
				%do;
/*					proc sql;*/
/*						select &control_Variable. into: error_control_level separated by "!!" from togetcol1col2names where frequency = 0 and _type_ = "111";*/
/*						select %scan(&x_var.,&j.) into: error_xvar_level separated by "!!" from togetcol1col2names where frequency = 0 and _type_ = "111";*/
/*						select %scan(&y_var.,&i.) into: error_yvar_level separated by "!!" from togetcol1col2names where frequency = 0 and _type_ = "111";*/
/*					run;*/
/*					quit;*/
/**/
/*					%let errortext=;*/
/*					%let and=;*/
/*					%do error_i = 1 %to %sysfunc(countw(&error_control_level.,"!!"));*/
/*						%let current_error_control_level=%scan(&error_control_level.,&error_i.,"!!");*/
/*						%let current_error_xvar_level=%scan(&error_xvar_level.,&error_i.,"!!");*/
/*						%let current_error_yvar_level=%scan(&error_yvar_level.,&error_i.,"!!");*/
/*						%if &error_i. > 1 %then %let and=and;*/
/*						%let errortext=&errortext. &and. &control_Variable. = &current_error_control_level, %scan(&x_var.,&j.) = &current_error_xvar_level., %scan(&y_var.,&i.) = &current_error_yvar_level.;*/
/*					%end;*/
/**/
/*					%let errortext = Breslow Day Test was not performed because there are 0 observations for &errortext.;*/

					%let errortext = Breslow Day Test was not performed because there are 0 observations for the selected variables.;

					data _null_;
						v1= "&errortext.";
						file "&output_path./%scan(&y_var.,&i.)/%scan(&x_var.,&j.)/breslowdaytest_error.txt";
						put v1;
					run;
				%end;
			/*-----------------------------------------------------------------------------------------*/


			data togetcol1col2names_temp;
				set togetcol1col2names(keep=%scan(&y_var.,&i.));
			run;

			proc sort data=togetcol1col2names_temp out=togetcol1col2names_temp nodupkey;
				by %scan(&y_var.,&i.);
			run;
			quit;

			data _null_;
				set togetcol1col2names_temp;
				call symput("col"||compress(_n_),"Risk for '"||compress(%scan(&y_var.,&i.))||"'");
			run;				

			/*CMH ESTIMATES OUTPUT*/
			data Crrestimates (drop= Table Control);
				rename LowerCL=Lower_Confidence_Limit_95percent;
				rename UpperCL=Upper_Confidence_Limit_95percent;
				set Crrestimates;

				if compress(studytype) = "(Col1Risk)" then
					studytype="&col2.";

				if compress(studytype) = "(Col2Risk)" then
					studytype="&col3.";
					
				method = tranwrd(method,"**","");
			run;

			/* export the dataset*/
			proc export data = Crrestimates
				outfile = "&output_path./%scan(&y_var.,&i.)/%scan(&x_var.,&j.)/CMHestimates.csv"
				dbms = CSV replace;
			run;

			/*CMH STATISTICS OUTPUT*/
			data Cmhstatistics (drop= Table);
			    length Result $20;
				format Result $20.;
				set Cmhstatistics;

				if prob=<.0001 then
					Result="Significant";
				else if prob <= &cmhpValue_cutoff. then
					Result="Significant";
				else if prob > &cmhpValue_cutoff. then
					Result="Insignificant";
/*				if prob > &cmhpValue_cutoff. then*/
/*					Result="Insignificant";*/
/*				else Result="Significant";*/
			run;

			/* export the dataset*/
			proc export data = Cmhstatistics
				outfile = "&output_path./%scan(&y_var.,&i.)/%scan(&x_var.,&j.)/CMHstatistics.csv"
				dbms = CSV replace;
			run;

			/*CMH Breslowdaytest OUTPUT*/
			%if %sysfunc(exist(BreslowDayTest)) %then
				%do;

					data BreslowDayTest (keep = Statistics Estimates);
						rename Label1=Statistics;
						rename cValue1=Estimates;
						set BreslowDayTest;
					run;

					/* export the dataset*/

					proc export data = BreslowDayTest
						outfile = "&output_path./%scan(&y_var.,&i.)/%scan(&x_var.,&j.)/CMHbreslowdaytest.csv"
						dbms = CSV replace;
					run;

				%end;
		%end;
	%end;
%mend;


%macro metric;

/* count till number of y values separated by !! */

	%do i=1 %to %sysfunc(countw("&y.","!!"));

	/* count till number of x values separated by !! */

		%do j=1 %to %sysfunc(countw("&x.","!!"));
			/*Chi Square*/
			ods trace on;
/*			ods output  CrossTabFreqs=freqj&j.i&i.;*/
			/* checking it chisq is required  */
			%if "&flag_chisq_relation." = "true" %then %do;
			ods output ChiSq = chiSq&j&i(where=(statistic="Chi-Square"));
			%end;
			/* checking if weight_var is empty or not */
			proc freq data=one_reqd;	
				%if "&weight_var." ^= "" %then %do;weight &weight_var.;%end;
				tables b&i*a&j %if "&flag_chisq_relation." = "true" %then %do;/chisq %end;;
				run;
			ods trace off;

			proc sql;
				 create table freq&j&i as
				 select b&i,a&j,&metric.(&var_name.) as &metric.
				 from one_reqd
				 group by b&i,a&j;
				 quit;

	/* calculating rowsum colsum and absolute sum */

			proc sql;
				create table freq&j&i as
					select *,sum(&metric.) as colsum
					from freq&j&i
					group by a&j;

				create table freq&j&i as
					select *,sum(&metric.) as rowsum
					from freq&j&i
					group by b&i;

				create table freq&j&i as
					select *,sum(&metric.) as abssum
					from freq&j&i;

				create table total1&j.&i. as
				select b&i.,sum(&metric.) as &metric.,sum(abssum) as abssum from freq&j&i
				group by b&i.;

				create table total11&j.&i.  as
				select sum(&metric.) as &metric. from total1&j.&i.;

				create table total2&j.&i.  as
				select a&j, sum(&metric.) as &metric.,sum(abssum) as abssum from freq&j&i
				group by a&j;
				quit;
					
proc append base=freq&j&i data=total1&j.&i. force;
run;
proc append base=freq&j&i data=total11&j.&i. force;
run;
proc append base=freq&j&i data=total2&j.&i. force;
run;

data freqj&j.i&i.(drop=colsum rowsum &metric. abssum);
		set freq&j&i;
		value=&metric.;
		ColPercent=(&metric./colsum)*100;
		RowPercent=(&metric./rowsum)*100;
		absolute=(&metric./abssum)*100;
			if a&j.="."  then a&j.="total";
			if a&j.=""  then a&j.="total";
			if a&j.="-"  then a&j.="total";
			if b&i.="."  then b&i.="total";
			if b&i.=""  then b&i.="total";
			if b&i.="-"  then b&i.="total";
		run;
		proc sql;
			select count(distinct b&i.) into: pivot_count from one_reqd;
		quit;

data freqj&j.i&i.;
set freqj&j.i&i.;
%if &pivot_count. > 1 %then %do; 
if a&j.="total" then absolute=2*absolute;
if b&i.="total" then absolute=2*absolute;
%end;
run;

		%let xx_name=%scan("&x.",&j.,"!!");
		%let yy_name=%scan("&y.",&i.,"!!");

		data freqj&j.i&i.(rename=(b&i.=&yy_name. a&j.=&xx_name.));
			set freqj&j.i&i. ;
			run;



		%end;
	%end;
%mend metric;

%macro count;

%do i=1 %to %sysfunc(countw("&y.","!!"));
	%do j=1 %to %sysfunc(countw("&x.","!!"));
		ods trace on;
		ods output  CrossTabFreqs=freqj&j.i&i.;

	/* checking it chisq is required  */

		%if "&flag_chisq_relation." = "true" %then %do;
		      ods output ChiSq = chiSq&j&i(where=(statistic="Chi-Square"));
		%end;

	/* checking if weight_var is empty or not */

			proc freq data=one_reqd;	
			%if "&weight_var." ^= "" %then %do;weight &weight_var/zeros;%end;
				tables b&i*a&j %if "&flag_chisq_relation." = "true" %then %do;/chisq %end;;
			run;
		ods trace off;

		data freqj&j.i&i.;
			set freqj&j.i&i.;
			if a&j=" " or b&i=" " then delete;
			run;

/*	 calculating rowsum colsum and absolute sum */

		proc sql;
				create table freqa&i.j&j.i&i. as
					select a&j.,sum(frequency)as Frequency,sum(percent) as Percent
					from freqj&j.i&i.
					group by a&j.;
			quit;

			data freqa&i.j&j.i&i.;
			set freqa&i.j&j.i&i.;
			b&i.="total";
			run;
			

		proc sql;
				create table freqab&i.j&j.i&i. as
					select b&i.,sum(frequency) as Frequency,sum(percent) as Percent
					from freqj&j.i&i.
					group by b&i;
			quit;

			data freqab&i.j&j.i&i.;
			set freqab&i.j&j.i&i.;
			a&j.="total";
			run;

		proc sql;
				create table freqac&i.j&j.i&i. as
					select sum(frequency) as frequency
					from freqj&j.i&i.;

		data freqac&i.j&j.i&i.;
			set freqac&i.j&j.i&i.;
			a&j.="total";
			b&i.="total";
			run;

			quit;

			%let xx_name=%scan("&x.",&j.,"!!");
			%let yy_name=%scan("&y.",&i.,"!!");
 
			data freqj&j.i&i.(drop= _TABLE_ _TYPE_ TABLE Missing rename=(b&i.=&yy_name. a&j.=&xx_name. frequency=value percent=absolute));
			set freqj&j.i&i. freqa&i.j&j.i&i. freqab&i.j&j.i&i. freqac&i.j&j.i&i.;
			run;



	/* combining row sum col sum and abs sum */
/*	*/
/*		data freqj&j.i&i.(drop=Frequency RowPercent ColPercent Percent);*/
/*			length combined $100.;*/
/*			set freqj&j.i&i.;*/
/*			combined=cat('value=',Frequency,'!!row%=',RowPercent,'!!col%=',ColPercent,'!!abs%=',Percent);*/
/*			retain a&j b&i combined;*/
/*			run;*/
	%end;
%end;
%mend count;
	
%macro main;
	
	%if "&grp_no." = "0" %then %do;
		data one;
			set &dataset_name.(keep=&xkeep. &ykeep. &var_name. %if "&weight_var." ^=""  %then %do; &weight_var. %end; %if "&flag_cmh." = "true" %then %do;
		&control_Variable. %end; );
			run;
	%end;
	%else %do;
		data one(drop=grp&grp_no._flag);
			set &dataset_name.(keep=&xkeep. &ykeep. &var_name. grp&grp_no._flag %if "&weight_var." ^=""  %then %do; &weight_var. %end; %if "&flag_cmh." = "true" %then %do;
		&control_Variable.	%end;);
			where grp&grp_no._flag = "&grp_flag.";
			run;
	%end;


	/* concatentating variables separated ny "," */

	data one_concat;
			set one;
			%do i=1 %to %sysfunc(countw("&x.","!!"));
				a&i=trim(left(cat(%sysfunc(scan("&x.",&i,"!!")))));
			%end;
			%do i=1 %to %sysfunc(countw("&y.","!!"));
				b&i=trim(left(cat(%sysfunc(scan("&y.",&i,"!!")))));
			%end;
			run;

/*	 keeping the required variables */

	data one_reqd(keep=a: b: &var_name. &weight_var.);
		set one_concat;
		run;

	/* checking the type-count/metric */
	%if "&flag_cmh." = "true" %then %do;
		%cmh;
	%end;
	 %if &type.=count %then %do;
	  	%count;
	 %end;
	 %else %if &type.=metric %then %do;
	  	%metric;
	 %end;

	%do i=1 %to %sysfunc(countw("&y.","!!"));
		%do j=1 %to %sysfunc(countw("&x.","!!"));


				%let xname=%scan("&selected_vars.",&j,"!!");
				%let yname=%scan("&pivot_vars.",&i,"!!");
    			options missing="-";
				proc export data=freqj&j.i&i. 
					outfile="&output_path./&yname./&xname./&xname..csv" 
					dbms=csv replace;
					run;	


	/* calculating the chisq value if type is metric and chisq flag is true */

				%if "&type." = "metric" %then %do;
					%if "&flag_chisq_relation." = "true" %then %do;
					proc means data=one_reqd SUM var range max stddev mean;
					class b&i a&j;
					var &var_name.;
					ods output summary=chi_data;
				      run; 
				      ods output ChiSq = chiSq&j&i(where=(statistic="Chi-Square"));
				      proc freq data = chi_data;
				            tables b&i *a&j/ chisq;
							%if &metric.=AVG %then %do;
								weight &var_name._Mean;
				            %end;
							%if &metric.=VAR %then %do;
								weight &var_name._Var;
				            %end;
							%if &metric.=SUM %then %do;
								weight &var_name._Sum;
				            %end;
							%if &metric.=STD %then %do;
								weight &var_name._Stddev;
				            %end;
							%if &metric.=MAX %then %do;
								weight &var_name._Max;
				           %end;
							%if &metric.=RANGE %then %do;
								weight &var_name._Range;
							%end;
							%if &metric.= COUNT %then %do;
								weight NObs;
							%end;
				            run;
					%end;
				%end;

	/* checking for the significance of the probablity value */

				%if "&flag_chisq_relation." = "true" and %sysfunc(exist(chiSq&j&i)) %then %do;
					 data chiSq&j&i(drop=table rename=(prob=Prob statistic=Statistic value=Value));
			            retain Selected_var Pivot_var Statistic DF Value Prob Result;
			            length result $15.;
			            length pivot_var $32.;
			            length Selected_var $32.;
			            set chiSq&j&i;
			            Selected_var = "%scan("&xchi.",&j,"!!")";
			            Pivot_var = "%scan("&ychi.",&i,"!!")";
			            if prob <= &pvalue_cutoff. then Result = "Significant";
			                  else Result = "Insignificant";
			            run;

	/* exporting the chisq values */

	%if "&flag_chisq_relation." = "true"  %then %do;
		options missing="-";
			proc export data=chiSq&j&i
			outfile="&output_path./&yname./&xname./chi_sq.csv" 
			dbms=csv replace;
			run;	
	%end;
	
	/* appending all the chisq values into a single dataset */
				  /*proc append base=out_chiSq data=chiSq&j&i force;*/
		            /*run;*/
				%end;
	   
	%end;
	%end;

	
	/* keeping all the distinct values of all the x variables */
	
	%do k=1 %to %sysfunc(countw("&x.","!!"));
		proc sql;
			create table dist_x&k as 
				select distinct a&k as xvar
				from one_reqd;
			quit;

		%let name=%scan("&selected_vars.",&k,"!!");

	/* checking if the distinct value starts with a number . if so concatenating an "_" to it */

		data dist_x&k;
			set dist_x&k;
			if verify(xvar,'0123456789')=2 then xvar=cat("_",xvar) ;
			run;

	/* exporting the unique values of selected_var to xml */

		libname out xml "&output_path./stackedvalues_list_&name..xml";
			data out.distinct_xvars&k;
			set dist_x&k;

			run;
	%end;
%mend main;
%main;

data _null_;
      v1= "EDA - CROSSTABS";
      file "&output_path/CROSSTABS.txt";
      put v1;
run;