/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path./TIMESERIES_VIEWER_COMPLETED.txt;
/*--------------------------------------------------------------------------------------------------------*/
/*--                                                                                                  	--*/   
/*-- Functionality Name :  time series viewer        	--*/
/*-- Description  		:  generates time series csv for the plot selected
/*-- Return type  		:  Creates CSV's at a location according to given inputs                        --*/
/*-- Author       		:  Saurabh vikash singh                         --*/                 
/*--------------------------------------------------------------------------------------------------------*/



options mprint mlogic symbolgen mfile;
dm log 'clear';
/*proc printto log="&output_path./timeseries_viewer.log";*/
/*run;*/
/*quit;*/
	
/*proc printto print="&output_path./timeseries_viewer.out";*/
	
data _null_;
call symput("combined_varlist",tranwrd("&combined_varlist.","|"," "));

data _null_;
call symput("timeseries_metrics",tranwrd("&timeseries_metrics.","|"," "));
run;
data _null_;
%let timeseries_metrics1 = &timeseries_metrics.;
%put &timeseries_metrics1.;
run;
data _null_;
call symput("timeseries_metrics",tranwrd("&timeseries_metrics.","average","avg"));
run;
data _null_;
call symput("timeseries_metrics",tranwrd("&timeseries_metrics.","total","sum"));
run;
data _null_;
call symput("timeseries_metrics",tranwrd("&timeseries_metrics.","beginning","first"));
run;
data _null_;
call symput("timeseries_metrics",tranwrd("&timeseries_metrics.","end","last"));
run;
data _null_;
call symput("selected_date_level",tranwrd("&selected_date_level.","week","weekday"));
run;
%put &combined_varlist.;
%put &timeseries_metrics.;

/*defining the libraries*/
libname in "&input_path.";
libname out "&output_path.";

%macro timeseries;
%if "&split_axis." ^="" %then %do;
%let split_axis = %sysfunc(compress(&split_axis.));
%let split_axis_sub = %sysfunc(compress(&split_axis_sub.));
%end;

data temp;
	set in.dataworking;
	%if "&grp_no." ^= "0" %then %do;
		where grp&grp_no._flag = "&grp_flag.";
	%end;
run;

%if "&split_axis_sub." = "" %then %do;
	data temp;
		set temp;
		grp0_flag="1_1_1";
	run;
	%let split_axis=0;
	%let unique_split_axis=1;
	%let split_axis_sub=1_1_1;
	%let split_axis_sub_name=;
%end;
%do i=1 %to %sysfunc(countw("&date_var."," ")); 
	%if "%scan(&selected_date_level.,&i.," ")" ^= "day" %then %do;
	data temp;
		set temp;
		rollupcol1&i.=%scan(&selected_date_level.,&i.," ")(%scan(&date_var.,&i.," "));
	run;

	data temp;
			set temp;
			yearcol=year(%scan(&date_var.,&i.," "));
	run;
		
		data temp(drop=rollupcol1&i.);
			set temp;
			format rollupcol&i. $ 10.;
			format yearcol $ 5.;
			%if "%scan(&selected_date_level.,&i.," ")" ^= "year" %then %do;
			rollupcol&i.=cat(rollupcol1&i.,"-",yearcol);
			%end;
			%else %do;
			rollupcol&i.=rollupcol1&i.;
			%end;
			run;
	%end;
	%else %do;
		proc sql;
			create table temp1 as select %scan(&date_var.,&i.," ") as rollupcol&i. from temp;
		quit;
		data temp;
			merge temp temp1;
		run;
	%end;
	%do j=1 %to %sysfunc(countw("&combined_varlist."," "));
		%let testvar=%scan(&combined_varlist.,&j.," ");
		%let testmetric=%scan(&timeseries_metrics.,&j.," ");
		%do k=1 %to %sysfunc(countw("&split_axis_sub.","#"));
			data temp1;
				set temp;
				where grp%scan("&split_axis.",&k.,"#")_flag ="%scan(&split_axis_sub.,&k.,"#")";
			run;
			%if "&testmetric" = "avg" or "&testmetric" = "sum" %then %do;
				proc sql;
				create table result as select &testmetric.(&testvar.) as value,rollupcol&i. from temp1 group by rollupcol&i.;
				quit;
			%end;
			%if "&testmetric" = "first" or "&testmetric" = "last" %then %do;
				proc sort data=temp1 out=temp1;
				by rollupcol&i.;
				run;
				data result(keep=&testvar. rollupcol&i.);
					set temp1;
					by rollupcol&i.;
					if &testmetric..rollupcol&i.;
				run;
			%end;

			%if "&testmetric" = "middle" %then %do;
				proc sort data=temp1 out=temp1;
					by rollupcol&i.;
					run;

				proc sql;
					create table dummy as select count(*) as count1, round(count(*)/2) as count2 from temp1 group by rollupcol&i.;
					quit;

				data dummy;
					set dummy;
					if First.count1 then newvar = 0;
					newvar + count1;
					run;

				data dummy(drop=newvar);
					set dummy;
					lagvar=lag(newvar);
					run;

				data dummy(keep=rowvar);
					set dummy;
					if _n_ = 1 then do;
					rowvar=count2;
					end;
					else do; 
					rowvar=count2+lagvar;
					end;
					run;

				data dummy;
					set dummy;
					rowvar1=cat("_n_ = ",rowvar);
				run;
				proc sql;
				select rowvar1 into:rowvar separated by " or " from dummy; 
				quit;
				proc sort data=temp1 out=temp1;
				by rollupcol&i.;
				run;
				data result(keep=&testvar. rollupcol&i.);
					set temp1;
					if &rowvar;
				run;
 			%end;

			data result(rename=(&testvar.=value rollupcol&i.=%scan(&date_var.,&i.," ")));
				set result;
				variables="%scan("&timeseries_metrics1.",&j.," ")(&testvar.)";
				metrics="%scan("&timeseries_metrics1.",&j.," ")";
				group="%scan("&split_axis_sub_name.",&k.,"#")";
			run;

			%if "%scan(&selected_date_level.,&i.," ")" ^= "year" %then %do;
			data result;
				set result;
				col1=scan(%scan(&date_var.,&i.," "),1,"-")*1;
				col2=scan(%scan(&date_var.,&i.," "),2,"-")*1;
				run;

			proc sort data=result out=result;
				by col2 col1;
				run;

			data result(drop=col1 col2);
				set result;
				run;	
			%end;
			
			data result;
					set result;
					if First.value then runningtotal = 0;
					runningtotal + value;
			run;
			data result;
				set result;
				lagvar=lag(value);
			run;
			%if "&perc_change." ="relative" %then %do;
				data result;
					set result;
					if _n_ = 1 then do;
						percchange=0;
					end;
					else do;
						percchange=value-lagvar;
					end;
				 run;
			%end;
			%if "&perc_change." ="base" %then %do;
				proc sql;
				select avg(&date_var.) into:basevalue from temp where &date_var. = "&perc_date.";
				quit;
				data result;
					set result;
					percchange=value-&basevalue.;
				run;	
			%end;	
			data result(drop=lagvar);
				format variables $50.;
/*				format group $200.;*/
				format metrics $20.;
				set result;
				if _n_ > 1 then do;
				twoperiodmoving=(lagvar+value)/2;
				end;
			run;
/*adding the trendline here*/
			data result;
				set result;
				tcol=_n_;
				run;	
				%let dsid=%sysfunc(open(result));
            	%let num=%sysfunc(attrn(&dsid,nobs));
            	%let rc=%sysfunc(close(&dsid));

				proc sql;
				select avg(tcol) into:tl from result where tcol < round(%eval(&num./2));
				quit;
				%put &tl;

				proc sql;
				select avg(tcol) into:tu from result where tcol >= round(%eval(&num./2));
				quit;
				%put &tu;
				proc sql;
				select avg(value) into:yl from result where tcol < round(%eval(&num./2));
				quit;
				%put &yl;
				proc sql;
				select avg(value) into:yu from result where tcol >= round(%eval(&num./2));
				quit;
				%put &yu;
				data _null_;
				call symput("slope",%sysevalf((&yu.-&yl.)/(&tu.-&tl.)));
				run;
				%put &slope.;
				data _null_;
				call symput("intercept",%sysevalf(&yl.- (&slope.*&tl.)));
				run;
				%put &intercept.;

				data result(drop=tcol);
					set result;
					trendline=&slope.*tcol +(&intercept.);
					run;
				
		/*adding of trendline ends here*/

			%if "&k." = "1" %then %do;
			data resultvar;
				set result;
			run;
			%end;
			%else %do;
			data resultvar;
				set resultvar result;
			run;
			%end;
		%end;
		%if "&j." = "1" %then %do;
		data resultdate;
			set resultvar;
		run;
		%end;
		%else %do;
		data resultdate;
			set resultdate resultvar;
		run;
		%end;
	%end;
	proc sort data=resultdate NODUPRECS;
		by %scan(&date_var.,&i.," ");
	run;
	%if "%scan(&selected_date_level.,&i.," ")" ^= "year" %then %do;
	data resultdate;
		set resultdate;
		col1=scan(%scan(&date_var.,&i.," "),1,"-")*1;
		col2=scan(%scan(&date_var.,&i.," "),2,"-")*1;
		run;

	proc sort data=resultdate out=resultdate;
		by col2 col1;
		run;

	data resultdate(drop=col1 col2);
		set resultdate;
		run;	
	%end;
	proc export data =  resultdate
		outfile = "&output_path./timeseries_viewer_%scan(&date_var.,&i.," ").csv"
		dbms = CSV replace;
	run;	
%end;
%mend;
%timeseries;
data _null_;
	v1= "TIMESERIES- TIMESERIES_VIEWER_COMPLETED";
	file "&output_path./TIMESERIES_VIEWER_COMPLETED.txt";
	put v1;
run;


