
*processbody;
/*| ==================================================================================== |*/
/*| Code Details                                                                         |*/
/*| ==================================================================================== |*/
/*| # PROGRAM NAME	: rollup.sas                                              			 |*/
/*| # DESCRIPTION	: Performs the rollup operation for catrgorical and continuous 		 |*/
/*| 			  	 variables 							    	                         |*/
/*| # CALLED BY		: Data Preparation - Dataset Manipulation - Rollup in muRx           |*/
/*| # CALLS TO		: NA                                  								 |*/
/*| # PROGRAMMER	: Aparna Joseph and Saurabh Vikash Singh                             |*/
/*| # DATE WRITTEN	: 2012                                       				 		 |*/

/*| # INPUT FILES	: dataworking.sas7bdat          								 	 |*/
/*| # OUTPUT FILES	: Creates rolled up SAS dataset with name given by the user			 |*/	
/*| ==================================================================================== |*/
/*| Modifications                                                                     	 |*/
/*| ==================================================================================== |*/
/*| # ITERATION NO	: 0                                               					 |*/
/*| # DATE 			: 21st March 2015			                                         |*/
/*| # CHANGE		: Reviewed for EQR                               				 	 |*/
/*| # PROGRAMMER	: Saurabh Vikash Singh                              			     |*/
/*| # DESCRIPTION   : Not any changes made as changes were made recently to improve performance|*/
/*| ==================================================================================== |*/


/*| ==================================================================================== |*/
/*| Sample parameters                                                                    |*/
/*| ==================================================================================== |*/
/*| %let codePath=/product-development/murx//SasCodes//8.7.3;*/
/*| %let input_path=/product-development/murx//projects/freshproj-3-Mar-2015-15-40-43/2;*/
/*| %let output_path=/product-development/murx//projects/freshproj-3-Mar-2015-15-40-43/DatasetManipulation/Rollup/1;*/
/*| %let group_var_cat=geography;*/
/*| %let group_var_date=;*/
/*| %let agg_var_Cont=channel_1 black_hispanic ACV Store_Format;*/
/*| %let agg_var_cat=Store_Format#Store_Format#Store_Format#Store_Format#*/
/*| Store_Format#Store_Format;*/
/*| %let metrics=MIN AVG MAX COUNT */
/*| COUNT COUNT COUNT COUNT */
/*| COUNT;*/
/*| %let class_var=Store_Format;*/
/*| %let newvarlist=channel_1_$black_hispanic_$ACV_$Store_Format_$*/
/*| Store_Format_Food_Drug_Combo_$Store_Format_Super_Combo_$Store_Format_Supercenter_$Store_Format_Supermarket_$*/
/*| Store_Format_Superstore_;*/
/*| %let date_Fun=;*/
/*| %let agg_var_cat_level=!#Food/Drug Combo#Super Combo#Supercenter#*/
/*| Supermarket#Superstore;*/
/*| %let all=geography,Store_Format,Store_Format,Store_Format,*/
/*| Store_Format,Store_Format,Store_Format,channel_1,*/
/*| black_hispanic,ACV;*/
/*| %let new_Dataset_name=nedtaa;*/
/*| %let non_vars=;*/
/*| %let non_vars_new=;*/
/*| %let ds_prop_code_path=/product-development/murx//SasCodes//8.7.3//application_setup//dataset properties code.sas;*/



%let completedTXTPath =  &output_path/ROLLUP_COMPLETED.txt;
options mprint mlogic symbolgen mfile;
dm log 'clear';
proc printto log="&output_path./Rollup_log.log" new;
run;
quit;

%macro temp;

	%global agg_var_cat agg_var_cat_level metrics newvarlist non_vars_new;

	%let avc_temp                       = ;
	%let avcl_temp                      = ;
	%let n_temp                         = ;
	%let sep_avc                        = ;
	%let sep_newvarlist                 = ;

	%do i = 1 %to %sysfunc(countw(&agg_var_cat., #));
		%let agg_var_cat_i              = %scan(&agg_var_cat., &i., #);
		%let agg_var_cat_level_i        = %scan(%bquote(&agg_var_cat_level.), &i., #);

		%if "&agg_var_cat_level_i." = "!" %then
			%let agg_var_cat_level_i    = ;
		%else
			%do;
				%let avc_temp           = &avc_temp.&sep_avc.&agg_var_cat_i.;
				%let avcl_temp          = &avcl_temp.&sep_avc.&agg_var_cat_level_i.;
				%let sep_avc            = #;
			%end;

		%let newvarlist_i               = &agg_var_cat_i._&agg_var_cat_level_i.;
		%let n_temp                     = &n_temp.&sep_newvarlist.&newvarlist_i.;
		%let sep_newvarlist             = $;
	%end;

	%let agg_var_cat                    = &avc_temp.;
	%let agg_var_cat_level              = &avcl_temp.;
	%if "&newvarlist." = "" %then
		%let newvarlist                 = &n_temp.;

	%if "&non_vars_new." = "" and "&non_vars." ^= "" %then
		%do;
			%let n_temp                 = ;
			%let sep_non_vars_new       = ;

			%do i = 1 %to %sysfunc(countw(&non_vars., %str( )));
				%let non_vars_i         = %scan(&non_vars., &i., %str( ));
				%let non_vars_new_i     = &non_vars_i._;

				%let n_temp             = &n_temp.&sep_non_vars_new.&non_vars_new_i.;
				%let sep_non_vars_new   = ,;
			%end;

			%let non_vars_new = &n_temp.;
		%end;
%mend temp;
%temp;

%macro stringsub;

	%if "&group_var_cat." ^= "" %then
		%let group_var_cat=%sysfunc(compbl(&group_var_cat.));
	%if "&group_var_date." ^= "" %then
		%let group_var_date=%sysfunc(compbl(&group_var_date.));
	%if "&agg_var_Cont." ^= "" %then
		%let agg_var_Cont=%sysfunc(compbl(&agg_var_Cont.));
	%if "&agg_var_cat." ^= "" %then
		%let agg_var_cat=%sysfunc(compbl(&agg_var_cat.));

	data _null_;
		call symput("newvarlist",translate("&newvarlist.",'_____________________________',"~@%^&*()_+{}|:<>?`-=[]/,./; '"));
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

	data temp;
		set in.dataworking;
			%if "&group_var_date." ^= "" %then %do;
				
			%do i=1 %to %sysfunc(countw("&group_var_date."));
		%let new_name= %scan(&date_Fun.,&i.," ")_%scan(&group_var_date.,&i.," ");	
		%put &new_name.;	
		%if "%scan(&date_Fun.,&i.," ")" = "week_month" %then %do;
			&new_name.=intck('week',intnx('month',%scan(&group_var_date.,&i.," "),0),%scan(&group_var_date.,&i.," "))+1;
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
		 &new_name.= catx("_",year(%scan(&group_var_date.,&i.," ")),week(%scan(&group_var_date.,&i.," ")));
		%end;
		%let date_list=&date_list. &new_name.;
		%end;
			%end;
	
	run;
	%let group_var_cat=&group_var_cat. &date_list.;

	data _null_;
		call symput("cont_grp_var",tranwrd("&group_var_cat"," ",","));
		run;
/*sorting temp dataset*/
proc sort data=temp;
	by &group_var_cat.;
	run;
	

/***********************************************CONTINUOUS VARIABLES METRIC CALC************************************************/
/*getting metrics for all the variables sent in agg_var_cont*/
	%let metrices_cont=;
	%let metrices_cont_unique=;
	%let initials_newvarlist=&newvarlist.;
	%if "&agg_var_Cont" ^= "" %then %do;
		%do aa=1 %to %sysfunc(countw("&agg_var_Cont."," "));
			%let metrices_cont=&metrices_cont. %scan("&metrics.",&aa.," ");
				%let part2=%scan("&metrices_cont.",&aa.," ");
				%if %index("&metrices_cont_unique.","&part2.") = 0 %then %do;
					%let metrices_cont_unique=&metrices_cont_unique. %scan("&metrics.",&aa.," ");
				%end;
		%end;
		%put &metrices_cont.;
		%put &metrices_cont_unique.;
		proc sort data=temp out=temp;
		by &group_var_cat.;
		run;
		%let agg_var_Cont_for_means=&agg_var_Cont.;
		%do ff=1 %to %sysfunc(countw("&class_var."," "));
			%let tempclass=%scan("&class_var.",&ff.," ");
			data _null_;
			call symput("agg_var_Cont_for_means",tranwrd("&agg_var_Cont_for_means.","&tempclass.",""));
			run;
		%end;
		%put  abcd &agg_var_Cont_for_means.; 
		proc means data=temp;
			var &agg_var_Cont_for_means.;
			by &group_var_cat.;
			output out=temp_cont_out;
			run;

		%do cc=1 %to %sysfunc(countw("&metrices_cont_unique."," "));
			%let current_metric=%scan("&metrices_cont_unique.",&cc.," ");
			%let current_agg_var_cont=;
			%let current_agg_var_cont_new_name=;
			%do dd=1 %to %sysfunc(countw("&agg_var_Cont."," "));
				%if %scan("&metrices_cont.",&dd.," ") = &current_metric. %then %do;
					%let current_agg_var_cont=&current_agg_var_cont. %scan("&agg_var_Cont.",&dd.," ");
					%let current_agg_var_cont_new_name=&current_agg_var_cont_new_name. %scan("&newvarlist.",&dd.,"$");
				%end;
			%end;	
			%put abcdz &current_agg_var_cont.;
			%put &current_agg_var_cont_new_name.;
			%if "&current_metric." ne "UNICOUNT" %then %do;
					data _null_;
					call symput("current_metric",tranwrd("&current_metric.","AVG","MEAN"));
					run;
					data _null_;
					call symput("current_metric",tranwrd("&current_metric.","COUNT","N"));
					run;	
				data data123(keep=&group_var_cat. &current_agg_var_cont.);
						set temp_cont_out;
						format _numeric_ 12.;
						%if "&current_metric." ne "SUM" %then %do;
							if _STAT_ = "&current_metric.";
						%end;
						%else %do;
							if _STAT_ = "MEAN";
							%do kk =1 %to %sysfunc(countw("&current_agg_var_cont."," "));	
 								%scan("&current_agg_var_cont.",&kk.," ")=_FREQ_ * %scan("&current_agg_var_cont.",&kk.," ");								
							%end;
						%end;
						run;

					 data data123;
					 	set data123;
						%do anv=1 %to %sysfunc(countw(&current_agg_var_cont_new_name.," "));
						rename %scan(&current_agg_var_cont.,&anv.," ") = %scan(&current_agg_var_cont_new_name.,&anv.," ");
						%end;
						run;
					%if "&cc." = "1" %then %do;
						data cont_out1;
							set data123;
							run;
					%end;
					%else %do;
					data cont_out1;
						merge cont_out1 data123;
						by &group_var_cat.;
						run;
					%end;
			%end;
		%end;
	
/*	updating the agg_var_Cont parameter*/
	%let initials=&agg_var_Cont.;
	%let initials_metrics=&metrics.;
/*	%let initials_newvarlist=&newvarlist.;*/

	%do vv=1 %to %sysfunc(countw("&initials."," "));
		%let cur_agg_var_Cont=%scan("&initials.",&vv.," ");
		%let cur_metrics=%scan("&initials_metrics.",&vv.," ");
		%let cur_newvarlist=%scan("&initials_newvarlist.",&vv.,"$");
		%if "&cur_metrics." ne "UNICOUNT" %then %do;
			%if %index("&class_var.",&cur_agg_var_Cont.) = 0 %then %do;
			%let ind=%index(&agg_var_Cont.,&cur_agg_var_Cont.);
			%let fin=%sysfunc(findc(&agg_var_Cont.," ",i,%eval(&ind.)));
			%let ind_me=%index(&metrics.,&cur_metrics.);
			%let fin_me=%sysfunc(findc(&metrics.," ",i,%eval(&ind_me.)));
			%let ind_ne=%index(&newvarlist.,&cur_newvarlist.);
			%let fin_ne=%sysfunc(findc(&newvarlist.,"$",i,%eval(&ind_ne.)));

			%if "&ind." ne "0" and "&fin." ne "0" %then %do;
				%let part1= %substr(&agg_var_Cont.,&ind.,%eval(&fin.-&ind.+1));
				%let part2= %substr(&agg_var_Cont.,&fin.-&ind.+1);
				%let part1_me= %substr(&metrics.,&ind_me.,%eval(&fin_me.-&ind_me.+1));
				%let part2_me= %substr(&metrics.,&fin_me.-&ind_me.+1);
				%let part1_ne= %substr(&newvarlist.,&ind_ne.,%eval(&fin_ne.-&ind_ne.+1));
				%let part2_ne= %substr(&newvarlist.,&fin_ne.-&ind_ne.+1);
				
				data _null_;
					call symput("part1",tranwrd("&part1.","&cur_agg_var_Cont.",""));
				run;
				data _null_;
				call symput("agg_var_Cont","%sysfunc(trim(&part1 &part2))");
				run;

				data _null_;
					call symput("part1_me",tranwrd("&part1_me.","&cur_metrics.",""));
				run;
				data _null_;
				call symput("metrics","%sysfunc(trim(&part1_me &part2_me))");
				run;

				data _null_;
					call symput("part1_ne",tranwrd("&part1_ne.","&cur_newvarlist.$",""));
				run;
				data _null_;
				call symput("newvarlist","%sysfunc(trim(&part1_ne.%substr(&part2_ne.,2)))");
				run;
			%end;
			%end;
		%end;
	%end;
	%put bcdefg &agg_var_Cont.;
	%put &newvarlist.;
	%put &metrics.;
%end;
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
				(%if("%scan(&metrics,&i.)" = "UNICOUNT") %then distinct;%scan(&agg_var_Cont.,&i.," ")) as %scan(&newvarlist,&i.,"$") 
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
	%if %sysfunc(exist(cont_out1)) ne 0 and %sysfunc(exist(cont_out)) ne 0 %then %do;
		data cont_out;
			merge cont_out1(in=a) cont_out(in=b);
			by &group_var_cat.;
			if a;
			run;
	%end;
	%if %sysfunc(exist(cont_out1)) ne 0 and %sysfunc(exist(cont_out)) = 0 %then %do;
		data cont_out;
			set cont_out1;
			run;	
	%end;
/***********************************************CATEGORICAL LEVELS METRIC CALC************************************************/
/*Metric calculation for levels of categorical variables*/
	%if "&agg_var_cat." ^= "" %then %do;
		data _null_;
			call symput("agg_var_cat_level",tranwrd("&agg_var_cat_level.","# ","#"));
			run;
		data _null_;
			call symput("keep_levels",translate("&agg_var_cat_level.",'______________________________',"~@$%^&*()_+{}|:<>?`-=[]/,./; '"));
			run;
		data _null_;
			call symput("keep_levels",tranwrd("&keep_levels.","#"," "));
			call symput("grp_var_catsql",tranwrd("&group_var_cat"," ",","));
			run;

		%let retain_var=;		
		%do j=1 %to %sysfunc(countw("&agg_var_cat.","#"));
		%let met_cont=%eval(%sysfunc(countw("&agg_var_Cont."," "))+ &j.);

/*			new chunk*/
			
			%let change_var=%scan(&agg_var_cat.,&j.,"#");
			proc contents data=temp out=conta(keep=name type);
			run;
			proc sql;
			select type into: change_type separated by " " from conta where name = "&change_var.";
			quit;
			%if "&change_var." ne "&retain_var." %then %do;
			%if "&change_type." = "1" %then %do;
			data temp(drop=&change_var. rename=(newvar12=&change_var.));
				set temp;
				format newvar12 $20.;
				newvar12=&change_var.;
				newvar12=cat("_",strip(newvar12));
				run;
			%end;
			%let retain_var=&change_var.;
			%end;
/*	  		new chunk ends here*/
			ods output OneWayFreqs=OneWayFreqs&j.;
			proc freq data= temp;
				tables %scan(&agg_var_cat.,&j.,"#");
				by &group_var_cat.;
				run;
			
			proc sort data=OneWayFreqs&j.;
				by &group_var_cat.;
			run;
			quit;
			
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
		call symput("newvarlist",tranwrd("&newvarlist.","$"," "));
		run;

	data _null_;
		call symput("initials_newvarlist",tranwrd("&initials_newvarlist.","$"," "));
		run;

/*merge continuous categorical and nonvars datasets*/
	data &new_Dataset_name.(keep=&group_var_cat. &initials_newvarlist. &non_vars_new.);
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
	
	%if %sysfunc(exist(&new_Dataset_name.)) %then %do;

		/* flex uses this file to test if the code has finished running */
		data _null_;
			v1= "ROLLUP_COMPLETED";
			file "&output_path/ROLLUP_COMPLETED.txt";
			put v1;
			run;


		%let input_path = &output_path.;
		%let dataset_name = &new_Dataset_name.;
		%include "&ds_prop_code_path";
	%end;
%mend rollup;
%rollup;
/*export rollup in csv format*/
/*proc export data=out.&new_Dataset_name.*/
/*		outfile= "&output_path./rollup.csv"*/
/*		dbms=csv replace;*/
/*		run;*/



