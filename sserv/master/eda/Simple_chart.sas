*processbody;
options mlogic symbolgen mprint mfile;
FILENAME MyFile "&output_path./Simple_COMPLETED.txt";
%let append_yvar_counter=0;

DATA _NULL_;
	rc = FDELETE('MyFile');
RUN;

/**/
/*proc printto log="&output_path./Simple_chart_Log.log" ;*/
/*run;*/
/*quit;	*/


proc printto;
run;
quit;

dm 'log' clear;

/*defining the libraries*/
libname in "&input_path.";
libname out "&output_path.";
%let dataset_name=in.dataworking;

%macro txt_obs(data_name);
	/*-----------------------------------------------------------------------------------------
		Writing a text file to indicate if there are more than 10000 observations in the CSV
	-----------------------------------------------------------------------------------------*/
	%let dsid=%sysfunc(open(&data_name.));
	%let nobs=%sysfunc(attrn(&dsid.,nobs));
	%let rc=%sysfunc(close(&dsid.));

	%if &nobs. > 5500 %then
		%do;

			data _null_;
				v1= "morethan6000";
				file "&output_path./morethan6000.txt";
				put v1;
			run;

		%end;
%mend txt_obs;

%macro main_viz;
	%if "&flag_normal"="true" %then
		%do;
			%if "&selected_varlist." ^= "" %then
				%do;
					%let selected_varlist1=%sysfunc(tranwrd(&selected_varlist,%quote( ),%quote(,)));
					%put &selected_varlist1;

					%do i = 1 %to %sysfunc(countw(&var_list.," "));
						%do j =1 %to %sysfunc(countw(&metrics.));
							%if "&grp_no." ^= "0" %then
								%do;
									%let name_dataset=out_&i._&j._&m.;
								%end;
							%else
								%do;
									%let name_dataset=out_&i._&j.;
								%end;

							%if "%scan(&metrics,&j.)" = "None" %then
								%do;
									%let new_metrics=%scan(&selected_varlist,&j);
								%end;

							%if "%scan(&metrics,&j.)" = "AVG" or "%scan(&metrics,&j.)" = "COUNT" or "%scan(&metrics,&j.)" = "RANGE" or "%scan(&metrics,&j.)" = "MAX" 
								or "%scan(&metrics,&j.)" = "MIN" or "%scan(&metrics,&j.)" = "STD" or "%scan(&metrics,&j.)" = "VAR"  or "%scan(&metrics,&j.)" = "SUM" %then
								%do;
									%let new_metrics= %scan(&metrics,&j)(%scan(&selected_varlist,&j));
								%end;

							%if "%scan(&metrics,&j)"="UNICOU" %then
								%do;
									%let new_metrics= count(distinct(%scan(&selected_varlist,&j)));
								%end;

							%if "%scan(&metrics,&j)"="CUMCOU" %then
								%do;
									%let new_metrics= sum((select count(%scan(&selected_varlist,&j))
										from temp t2
										where t2.%scan(&var_list,&i,' ')<= t.%scan(&var_list,&i,' ')));
								%end;

							%if "%scan(&metrics,&j)"="CUMCOUPER" %then
								%do;

									proc sql;
										select count(%scan(&selected_varlist,&j)) into:countnum  from temp;
									quit;

									%let new_metrics= (select count(%scan(&selected_varlist,&j))/&countnum.*100
										from temp t2
										where t2.%scan(&var_list,&i,' ')<= t.%scan(&var_list,&i,' '));
								%end;

							%if "%scan(&metrics,&j)"="CUMPER" %then
								%do;
									%let new_metrics= (select sum(%scan(&selected_varlist,&j))/(select sum(%scan(&selected_varlist,&j)) from temp)*100
										from temp t2
										where t2.%scan(&var_list,&i,' ')<= t.%scan(&var_list,&i,' '));
								%end;

							%if "%scan(&metrics,&j)"="PERTOT" %then
								%do;

									proc sql;
										select sum(%scan(&selected_varlist,&j)) into:sumnum separated by "," from temp

											%if  "&level." ^= "0"%then where;

											%if "&level." ^= "0" %then
												&done;;
									quit;

									%let new_metrics= (sum(%scan(&selected_varlist,&j))/&sumnum.)*100;
								%end;

							%if "%scan(&metrics,&j)"="COUPER" %then
								%do;

									proc sql;
										select count(%scan(&selected_varlist,&j)) into:countnum separated by "," from temp

											%if  "&level." ^= "0" %then where;

											%if  "&level." ^= "0" %then
												&done;;
									quit;

									%let new_metrics=(count(%scan(&selected_varlist,&j))/&countnum.)*100;
								%end;

							data temp(drop=%scan(&var_list,&i," ") rename=(a&i.=%scan(&var_list,&i," ")));
								set temp;
								a&i.=compress(%scan(&var_list,&i," "));
							run;

							proc sql;
								create table &name_dataset. as
									select &new_metrics. as yvalue, %scan(&var_list,&i," ") as xvalue format=$50. , "%scan(&selected_varlist,&j)" as yvars LENGTH=32,
										"%scan(&var_list,&i," ")" as xvars LENGTH=32,
										"%scan(&metrics,&j)" as metric_unique LENGTH=32  from temp t

									%if  "&level." ^= "0" %then where;

									%if  "&level." ^= "0" %then
										&done.;
									group by  %scan(&var_list,&i," ")

									%if "&level." ^="0" %then ,grp&split_level1._flag;
									;
							quit;

							/*							===========================*/
							/*							implementation for date as X variable*/
							%let type_current = %scan("&type_var_list.",&i.," ");

							%if("&type_current." = "date") %then
								%do;

									data &name_dataset.(drop=xvalue3);
										format xvalue3 30.;
										set &name_dataset.;
										xvalue3 = xvalue;
										xvalue=put(xvalue3,MMDDYY10.);
									run;

								%end;
								%else %do;

                                        data &name_dataset.(drop=xvalue rename=(xvalue3=xvalue));
										length xvalue3 $28.;
										set &name_dataset.;
										xvalue3 = xvalue;
										run;
							    %end;
									
							


							/*							============================*/
							data output&i&j;
								set &name_dataset.;

								%if "&level." ^= "0" %then
									%do;
										length sliceBy $ 50. sliceBy_grp_no $ 10.;
										sliceBy="&split_sublevel.";
										sliceBy_grp_no="&split_level.";
									%end;
								%else
									%do;
										length sliceBy $ 50. sliceBy_grp_no $ 10.;
										sliceBy="1_1_1";
										sliceBy_grp_no="0";
									%end;

								length chartBy $ 50. chartBy_grp_no $ 10. combined_flag $2.;
								chartBy_grp_no="&split_grp_no.";
								chartBy="&split_grp_flag.";
								combined_flag="0";
							run;

							/*append to the output file*/
							%if "&grp_no."="0" and "&level." ^= "0" %then
								%do;
									%let name_dataset1=output&i&i._&l.;
								%end;

							%if "&grp_no."^="0" and "&level."= "0" %then
								%do;
									%let name_dataset1=output&i&i._&m.;
								%end;

							%if "&grp_no."^="0" and  "&level." ^= "0" %then
								%do;
									%let name_dataset1=output&i&i._&l._&m.;
								%end;

							%if "&grp_no."="0" and "&level." = "0" %then
								%do;
									%let name_dataset1=output&i.&i.;
								%end;

							proc append base = &name_dataset1. data=output&i&j force;
							run;

							quit;

							proc sort data=&name_dataset1.  nodupkey;
								by yvars xvalue yvalue %if "&level." ^= "0" %then

									%do;
										sliceBy sliceBy_grp_no
									%end;

								%if "&grp_no." ^= "0" %then
									%do;
										chartBy chartBy_grp_no
									%end;;
							run;

						

						/* to replace missing values with zero*/
						data output&i;
							set &name_dataset1.;

							%if "&level." ^= "0" %then
								%do;
									length sliceby $ 50.;
								%end;

							array nums _numeric_;

							do over nums;
								if nums=. then
									nums=0;
							end;
						run;

						data output&i(drop=xvalue rename=(xvalue1=xvalue));
							set output&i;
							xvalue1=put(xvalue,$50.);
						run;

						%txt_obs(output&i.);

						proc append base=&last_dataset. data=output&i. force;
						run;

						proc sort data=&last_dataset. nodupkey;
							by xvars yvars xvalue yvalue %if "&level." ^= "" %then

								%do;
									sliceBy sliceBy_grp_no
								%end;

							%if "&grp_no." ^= "0" %then
								%do;
									chartBy chartBy_grp_no
								%end;;
						run;
						%end;

					%end;

					proc append base=final_dataset_old data=&last_dataset. force;
					run;

					proc sort data=final_dataset_old nodupkey;
						by xvars yvars xvalue yvalue sliceBy sliceBy_grp_no metric_unique
						%if "&grp_no." ^= "0" %then

							%do;
								chartBy chartBy_grp_no
							%end;;
					run;

				%end;

			%if "&combined_var." ^= "" and "&counter." = "0" %then
				%do;

					data _null_;
						call symput("combined_var",tranwrd("&combined_var.","|"," "));
					run;

					data _null_;
						call symput("combined_metric",tranwrd("&combined_metric.","|"," "));
					run;

					%let selected_varlist1=&combined_var.;
					%put &selected_varlist1;

					%do i = 1 %to %sysfunc(countw(&var_list.," "));
						%do j = 1 %to %sysfunc(countw(&combined_metric.));
							%if "&grp_no." ^= "0" %then
								%do;
									%let name_dataset=cout_&i._&j._&m.;
								%end;
							%else
								%do;
									%let name_dataset=cout_&i._&j.;
								%end;

							/*==================================================*/
							%if "%scan(&combined_metric.,&j.)" = "None" %then
								%do;
									%let new_combined_metrics=%scan(&selected_varlist,&j);
								%end;

							/*=====================================================*/
							%if "%scan(&combined_metric,&j.)" = "AVG" or "%scan(&combined_metric,&j.)" = "COUNT" or "%scan(&combined_metric,&j.)" = "RANGE" or "%scan(&combined_metric,&j.)" = "MAX" 
								or "%scan(&combined_metric,&j.)" = "MIN" or "%scan(&combined_metric,&j.)" = "STD" or "%scan(&combined_metric,&j.)" = "VAR"  or "%scan(&combined_metric,&j.)" = "SUM" %then
								%do;
									%let new_combined_metrics= %scan(&combined_metric,&j)(%scan(&selected_varlist1,&j));
								%end;

							%if "%scan(&combined_metric,&j)"="UNICOU" %then
								%do;
									%let new_combined_metrics= count(distict(%scan(&selected_varlist1,&j)));
								%end;

							%if "%scan(&combined_metric,&j)"="CUMCOU" %then
								%do;
									%let new_combined_metrics= sum((select count(%scan(&selected_varlist1,&j))
										from temp t2
										where t2.%scan(&var_list,&i,' ')<= t.%scan(&var_list,&i,' ')));
								%end;

							%if "%scan(&combined_metric,&j)"="CUMCOUPER" %then
								%do;

									proc sql;
										select count(%scan(&selected_varlist1,&j)) into:countnum separated by "," from temp;
									quit;

									%let new_combined_metrics= (select count(%scan(&selected_varlist1,&j))/&countnum.*100
										from temp t2
										where t2.%scan(&var_list,&i,' ')<= t.%scan(&var_list,&i,' '));
								%end;

							%if "%scan(&combined_metric,&j)"="CUMPER" %then
								%do;
									%let new_combined_metrics= (select sum(%scan(&selected_varlist1,&j))/(select sum(%scan(&selected_varlist1,&j)) from temp)*100
										from temp t2
										where t2.%scan(&var_list,&i,' ')<= t.%scan(&var_list,&i,' '));
								%end;

							%if "%scan(&combined_metric,&j)"="PERTOT" %then
								%do;

									proc sql;
										select sum(%scan(&selected_varlist1,&j)) into:sumnum separated by "," from temp;
									quit;

									%let new_combined_metrics= (sum(%scan(&selected_varlist1,&j))/&sumnum.)*100;
								%end;

							%if "%scan(&combined_metric,&j)"="COUPER" %then
								%do;

									proc sql;
										select count(%scan(&selected_varlist1,&j)) into:countnum separated by "," from temp;
									quit;

									%let new_combined_metrics=(count(%scan(&selected_varlist1,&j))/&countnum.)*100;
								%end;

							data temp(drop=%scan(&var_list,&i," ") rename=(a&i.=%scan(&var_list,&i," ")));
								set temp;
								a&i.=compress(%scan(&var_list,&i," "));
							run;

							proc sql;
								create table &name_dataset. as
									select &new_combined_metrics. as yvalue, %scan(&var_list,&i," ") as xvalue format=$50. , "%scan(&selected_varlist1,&j)" as yvars LENGTH=32,
										"%scan(&var_list,&i," ")" as xvars LENGTH=32,
										"%scan(&combined_metric,&j)" as metric_unique LENGTH=32  from temp t 
									group by  %scan(&var_list,&i," ");
							quit;

							/*							===========================*/
							/*							implementation for date as X variable*/
							%let type_current = %scan("&type_var_list.",&i.," ");

							%if("&type_current." = "date") %then
								%do;

									data &name_dataset.(drop=xvalue3);
										format xvalue3 30.;
										set &name_dataset.;
										xvalue3 = xvalue;
										xvalue=put(xvalue3,MMDDYY10.);
									run;

								%end;
								%else %do;

                                        data &name_dataset.(drop=xvalue rename=(xvalue3=xvalue));
										length xvalue3 $28.;
										set &name_dataset.;
										xvalue3 = xvalue;
										run;
							    %end;

							/*							============================*/
							data coutput&i&j;
								set &name_dataset.;
								length sliceBy $ 50. sliceBy_grp_no $ 10.;
								sliceBy=yvars;
								sliceBy_grp_no=metric_unique;
								length chartBy $ 50. chartBy_grp_no $ 10. combined_flag $2.;
								chartBy_grp_no="&split_grp_no.";
								chartBy="&split_grp_flag.";
								combined_flag = "1";
							run;

							/*	append to the output file*/
							%if "&grp_no."^="0" %then
								%do;
									%let name_dataset1=coutput&i&i._&m.;
								%end;

							%if "&grp_no."="0" %then
								%do;
									%let name_dataset1=coutput&i.&i.;
								%end;

							proc append base = &name_dataset1. data=coutput&i&j force;
							run;

							quit;

							proc sort data=&name_dataset1. nodupkey;
								by yvars xvalue yvalue sliceBy sliceBy_grp_no %if "&grp_no." ^= "0" %then

									%do;
										chartBy chartBy_grp_no
									%end;;
							run;

						%end;

						/* to replace missing values with zero*/
						data coutput&i;
							set &name_dataset1.;
							length sliceby $ 50.;
							array nums _numeric_;

							do over nums;
								if nums=. then
									nums=0;
							end;
						run;

						data coutput&i(drop=xvalue rename=(xvalue1=xvalue));
							set coutput&i;
							xvalue1=put(xvalue,$50.);
						run;

						%txt_obs(output&i.);

						proc append base=c&last_dataset. data=coutput&i. force;
						run;

						proc sort data=c&last_dataset. nodupkey;
							by yvars xvalue yvalue sliceBy sliceBy_grp_no %if "&grp_no." ^= "0" %then

								%do;
									chartBy chartBy_grp_no
								%end;;
						run;

					%end;

					proc append base=final_dataset_new data=c&last_dataset. force;
					run;

					proc sort data=final_dataset_new nodupkey;
						by yvars xvalue yvalue sliceBy sliceBy_grp_no %if "&grp_no." ^= "0" %then

							%do;
								chartBy chartBy_grp_no
							%end;;
					run;

				%end;

			%if "&combined_var." ^= "" %then
				%do;

					proc append base=final_dataset data=final_dataset_new force;
					run;

				%end;

			%if "&selected_varlist." ^= "" %then
				%do;

					proc append base=final_dataset data=final_dataset_old force;
					run;

				%end;
		%end;

	%if "&flag_normal." ^= "true" %then
		%do;
			%do i = 1 %to %sysfunc(countw(&var_list.," "));
				%if "&standard." ^= "0" %then
					%do;

						proc means data=temp mean std;
							var %scan(&var_list,&i.," ");
							output out=temp&i.;
						run;

						data _null_;
							set temp&i.;

							if _STAT_= "MIN" then
								call symput("min&i.",%scan(&var_list,&i.," "));

							if _STAT_= "MAX" then
								call symput("max&i.",%scan(&var_list,&i.," "));
						run;

						data temp(drop=%scan(&var_list,&i," ") rename=(a&i.=%scan(&var_list,&i," ")));
							set temp;
							a&i.=(%scan(&var_list,&i," ")-&&min&i..)/(&&max&i..-&&min&i..);
						run;

					%end;

				/*loop through the list of metrics*/
				%do j = 1 %to %sysfunc(countw(&metrics.));
					%if "&grp_no." ^= "0" %then
						%do;
							%let name_dataset=out_&i._&j._&m.;
						%end;
					%else
						%do;
							%let name_dataset=out_&i._&j.;
						%end;

					%if "%scan(&metrics,&j.)" = "AVG" or "%scan(&metrics,&j.)" = "COUNT" or "%scan(&metrics,&j.)" = "RANGE" or "%scan(&metrics,&j.)" = "MAX" 
						or "%scan(&metrics,&j.)" = "MIN" or "%scan(&metrics,&j.)" = "STD" or "%scan(&metrics,&j.)" = "VAR"  or "%scan(&metrics,&j.)" = "SUM" %then
						%do;
							%let new_metrics= %scan(&metrics,&j)(%scan(&var_list,&i));
						%end;

					%if "%scan(&metrics,&j)"="UNICOU" %then
						%do;
							%let new_metrics= count(distinct(%scan(&var_list,&i)));
						%end;

					%if "%scan(&metrics,&j)"="CUMCOU" %then
						%do;
							%let new_metrics= sum((select count(%scan(&var_list.,&i))
								from temp t2
								where t2.grp&split_level1._flag<= t.grp&split_level1._flag));
						%end;

					%if "%scan(&metrics,&j)"="CUMCOUPER" %then
						%do;

							proc sql;
								select count(%scan(&var_list.,&i)) into:countnum separated by "," from temp;
							quit;

							%let new_metrics= (select count(%scan(&var_list.,&i))/&countnum.*100
								from temp t2
								where t2.grp&split_level1._flag<= t.grp&split_level1._flag);
						%end;

					%if "%scan(&metrics,&j)"="CUMPER" %then
						%do;
							%let new_metrics= (select sum(%scan(&var_list.,&i))/(select sum(%scan(&var_list.,&i)) from temp)*100
								from temp t2
								where t2.grp&split_level1._flag<= t.grp&split_level1._flag);
						%end;

					%if "%scan(&metrics,&j)"="PERTOT" %then
						%do;

							proc sql;
								select sum(%scan(&var_list,&i)) into:sumnum separated by "," from temp

									%if  "&level." ^= "0" %then where;

									%if  "&level." ^= "0" %then
										&done;;
							quit;

							%let new_metrics= (sum(%scan(&var_list,&i))/&sumnum.)*100;
						%end;

					%if "%scan(&metrics,&j)"="COUPER" %then
						%do;

							proc sql;
								select count(%scan(&var_list,&i)) into:countnum separated by "," from temp

									%if  "&level." ^= "0" %then where;

									%if  "&level." ^= "0" %then
										&done;;
							quit;

							%let new_metrics=(count(%scan(&var_list.,&i))/&countnum.)*100;
						%end;

					proc sql;
						create table &name_dataset. as
							select &new_metrics. as yvalue, "%scan(&var_list,&i," ")" as yvars LENGTH=32,
								"%scan(&metrics,&j)" as metric_unique LENGTH=32 from temp t

							%if  "&level." ^= "0" %then where;

							%if  "&level." ^= "0" %then
								&done;

							%if  "&level." ^= "0" %then
								%do;
									group by  grp&split_level1._flag
								%end;
							;
					quit;

					/*append to the output file*/
					%if "&grp_no."="0" and "&level." ^= "0" %then
						%do;
							%let name_dataset1=output&i._&l.;
						%end;

					%if "&grp_no."^="0" and "&level."= "0" %then
						%do;
							%let name_dataset1=output&i._&m.;
						%end;

					%if "&grp_no."^="0" and  "&level." ^= "0" %then
						%do;
							%let name_dataset1=output&i._&l._&m.;
						%end;

					%if "&grp_no."="0" and "&level." = "0" %then
						%do;
							%let name_dataset1=output&i.;
						%end;

					proc append base = &name_dataset1. data=&name_dataset. force;
					run;

					quit;

				%end;

				%if "&grp_no."="0" and "&level." ^= "0" %then
					%do;
						%let name_dataset2=output&l&i&i;
					%end;

				%if "&grp_no."^="0" and "&level."= "0" %then
					%do;
						%let name_dataset2=output&i&i&m.;
					%end;

				%if "&grp_no."^="0" and  "&level." ^= "0" %then
					%do;
						%let name_dataset2=output&l&i&i&m.;
					%end;

				%if "&grp_no."="0" and "&level." = "0" %then
					%do;
						%let name_dataset2=output&i&i;
					%end;

				data &name_dataset2.;
					set &name_dataset1.;

					%if "&level." ^= "0" %then
						%do;
							length sliceBy $ 50. sliceBy_grp_no $ 10.;
							sliceBy="&split_sublevel.";
							sliceBy_grp_no="&split_level.";
						%end;
					%else
						%do;
							length sliceBy $ 50. sliceBy_grp_no $ 10.;
							sliceBy="1_1_1";
							sliceBy_grp_no="0";
						%end;

					length chartBy $ 10. chartBy_grp_no $ 10. combined_flag $2.;
					chartBy_grp_no="&split_grp_no.";
					chartBy="&split_grp_flag.";
					combined_flag = "0";
				run;

				/*=====================*/
				%let append_yvar_counter=%eval(&append_yvar_counter.+1);
				%put &append_yvar_counter.;

				data output;
					%if &append_yvar_counter. = 1 %then
						%do;
							set &name_dataset2.;
						%end;
					%else
						%do;
							set output &name_dataset2.;
						%end;
				run;

				/*				======================*/
			%end;

			/*==================*/
			proc sort data=output nodupkey;
				by yvars  yvalue metric_unique sliceBy sliceBy_grp_no 
				%if "&grp_no." ^= "0" %then

					%do;
						chartBy chartBy_grp_no
					%end;;
			run;

			/*			===================*/
			/* to replace missing values with zero*/
			data &last_dataset.;
				set output;
				array nums _numeric_;

				do over nums;
					if nums=. then
						nums=0;
				end;
			run;

			data final_dataset;
				set &last_dataset.;
			run;

			%txt_obs(output);
		%end;
%mend main_viz;

%macro viz(last_dataset);
	/*loop for the number of levels selected in slice by*/
	%if "&level." ^= "" and "&level." ^= "0" %then
		%do;
			%do l=1 %to %eval(%sysfunc(countw(&level.,"#")));
				%let split_level=%scan(&level.,&l,"#");
				%let split_sublevel=%scan(&sublevel.,&l,"#");

				/*creating the where condition*/
				%let where=;

				%do i=1 %to %eval(%sysfunc(countw(&split_level," "))-1);

					data _null_;
						call symput("temp","%scan(&split_sublevel.,&i.,"|")");
					run;

					%put &temp;
					%let temp=%str(%'&temp.%');

					data _null_;
						call symput("where",cat("&where ","grp%scan(&split_level,&i," ")_flag=&temp."," and"));
					run;

					%put &where;
					%let where=&where;
				%end;

				data _null_;
					call symput("temp","%scan(&split_sublevel.,&i.,"|")");
				run;

				%put &temp;
				%let temp=%str(%'&temp.%');

				data _null_;
					call symput("where",cat("&where ",'grp%scan(&split_level,&i," ")_flag=&temp'));
				run;

				%put &where;
				%let done= %sysfunc(tranwrd(&where,"=",%quote(=)));
				%put &done;
				%let split_level1=%sysfunc(tranwrd(&split_level,%quote( ),%quote(,)));
				%put &split_level1;

				%main_viz;
				%let counter=1;
			%end;
		%end;
	%else
		%do;
			/*		================*/
			%let split_level=%scan(&level.,1,"#");
			%let split_level1=%sysfunc(tranwrd(&split_level,%quote( ),%quote(,)));
			%put &split_level1;

			/*				====================*/
			%main_viz;
			%let counter=1;
		%end;
%mend viz;

%macro final_call;
	%if "&level." ^= "" %then
		%do;

			data _null_;
				call symput("level","%sysfunc(compbl(&level.))");
			run;

		%end;

	/*subset dataset on the bases of separate chart*/
	%if "&grp_no." ^="0" %then
		%do;
			%do m=1 %to %eval(%sysfunc(countw(&grp_no.,#)));

				/*		%let split_grp_var=%scan(&grp_var.,&m.,"#");*/
				/*		%let split_grp_sublevel=%scan(&grp_sublevel.,&m.,"#");*/
				%let split_grp_no=%scan(&grp_no.,&m,"#");
				%let split_grp_flag=%scan(&grp_flag.,&m,"#");

				data temp;
					set &dataset_name.;
					grp0_flag="1_1_1";

					%if "&split_grp_no." ^= "0" %then
						%do;
							where grp&split_grp_no._flag = "&split_grp_flag.";
						%end;
				run;

				%let counter=0;

				%viz(last_dataset=final&m.);

				%if %sysfunc(exist(final_dataset_old)) %then
					%do;

						data final_dataset_old;
							set final_dataset_old;

							if xvalue="." then
								delete;

							if xvalue="-" then
								delete;

							if yvalue="." then
								delete;

							if yvalue="-" then
								delete;
						run;

						proc export data = final_dataset_old
							outfile = "&output_path./Simple_chart.csv"
							dbms = CSV replace;
						run;

					%end;
				%else %if %sysfunc(exist(final_dataset_new))  %then
					%do;

						data final_dataset_new;
							set final_dataset_new;

							if xvalue="." then
								delete;

							if xvalue="-" then
								delete;

							if yvalue="." then
								delete;

							if yvalue="-" then
								delete;
						run;

						proc export data = final_dataset_new
							outfile = "&output_path./Simple_chart.csv"
							dbms = CSV replace;
						run;

					%end;
			%end;

			%if %sysfunc(exist(final_dataset_old)) and %sysfunc(exist(final_dataset_new)) %then
				%do;

					proc append base=final_dataset_old data=final_dataset_new;
					run;

					data final_dataset_old;
						set final_dataset_old;

						if xvalue="." then
							delete;

						if xvalue="-" then
							delete;

						if yvalue="." then
							delete;

						if yvalue="-" then
							delete;
					run;

					proc export data = final_dataset_old
						outfile = "&output_path./Simple_chart.csv"
						dbms = CSV replace;
					run;

				%end;

			%if "&combined_var." = "" and "&selected_varlist." = "" %then
				%do;

					data final_dataset;
						set final_dataset;

						if xvalue="." then
							delete;

						if xvalue="-" then
							delete;

						if yvalue="." then
							delete;

						if yvalue="-" then
							delete;
					run;

					proc export data = final_dataset
						outfile = "&output_path./Simple_chart.csv"
						dbms = CSV replace;
					run;

				%end;
		%end;
	%else
		%do;

			data temp;
				set &dataset_name.;

				%if ("&grp_no." = "0" | "&level." = "0" ) %then
					%do;
						grp0_flag = "1_1_1";
					%end;
			run;

			%let split_grp_no=&grp_no.;
			%let split_grp_flag=&grp_flag.;
			%let counter=0;

			%viz(final);

			%if %sysfunc(exist(final_dataset_old)) %then
				%do;

					data final_dataset_old;
						set final_dataset_old;

						if xvalue="." then
							delete;

						if xvalue="-" then
							delete;

						if yvalue="." then
							delete;

						if yvalue="-" then
							delete;
					run;

					proc export data = final_dataset_old
						outfile = "&output_path./Simple_chart.csv"
						dbms = CSV replace;
					run;

				%end;
			%else %if %sysfunc(exist(final_dataset_new)) %then
				%do;

					data final_dataset_new;
						set final_dataset_new;

						if xvalue="." then
							delete;

						if xvalue="-" then
							delete;

						if yvalue="." then
							delete;

						if yvalue="-" then
							delete;
					run;

					proc export data = final_dataset_new
						outfile = "&output_path./Simple_chart.csv"
						dbms = CSV replace;
					run;

				%end;

			%if %sysfunc(exist(final_dataset_old)) and %sysfunc(exist(final_dataset_new)) %then
				%do;

					proc append base=final_dataset_old data=final_dataset_new;
					run;

					data final_dataset_old;
						set final_dataset_old;

						if xvalue="." then
							delete;

						if xvalue="-" then
							delete;

						if yvalue="." then
							delete;

						if yvalue="-" then
							delete;
					run;

					proc export data = final_dataset_old
						outfile = "&output_path./Simple_chart.csv"
						dbms = CSV replace;
					run;

				%end;

			%if "&combined_var." = "" and "&selected_varlist." = "" %then
				%do;

					data final_dataset;
						set final_dataset;

						if xvalue="." then
							delete;

						if xvalue="-" then
							delete;

						if yvalue="." then
							delete;

						if yvalue="-" then
							delete;
					run;

					proc export data = final_dataset
						outfile = "&output_path./Simple_chart.csv"
						dbms = CSV replace;
					run;

				%end;
		%end;
%mend final_call;

%final_call;

/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "EDA - VISUALIZATION_COMPLETED";
	file "&output_path./Simple_COMPLETED.txt";
	put v1;
run;

/*proc datasets kill lib=work;*/
/*run;*/
/*quit;*/
