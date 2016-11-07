*processbody;
options mlogic symbolgen mprint mfile;
FILENAME MyFile "&output_path./Pie_COMPLETED.txt";

DATA _NULL_;
	rc = FDELETE('MyFile');
RUN;
proc printto  log ="&output_path./pie_chart_Log.log";
run;
quit;

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
%macro find_var_type;
%global temp;
		/*finding the variable type*/
			%let dsid = %sysfunc(open(temp));
			%let varnum = %sysfunc(varnum(&dsid,%scan(&split_level,&i," ")));
			%put &varnum;
			%let vartyp = %sysfunc(vartype(&dsid,&varnum)); /* variable type */
			%let rc = %sysfunc(close(&dsid));
			%put &vartyp;

			data _null_;
					call symput("temp","%scan(&split_sublevel.,&i.,"|")");
					run;
			%put &temp;
		
			/*generating quotes only for character type variable*/
			%if "&vartyp" ="C" %then %do; 
				%let temp=%str(%'&temp.%');
			%end;
			%put &temp;
%mend find_var_type;
%macro pi;
%if "&flag_normal" ="true" %then %do;
%do j = 1 %to %sysfunc(countw(&metrics.));
					%if "&grp_no." ^= "0" %then %do;
					%let name_dataset=out&j._&m.;
					%end;
					%else %do;
					%let name_dataset=out&j.;
					%end;

					%if "%scan(&metrics,&j.)" = "AVG" or "%scan(&metrics,&j.)" = "COUNT" or "%scan(&metrics,&j.)" = "RANGE" or "%scan(&metrics,&j.)" = "MAX" 
					or "%scan(&metrics,&j.)" = "MIN" or "%scan(&metrics,&j.)" = "STD" or "%scan(&metrics,&j.)" = "VAR"  or "%scan(&metrics,&j.)" = "SUM" %then %do;
					%let new_metrics= %scan(&metrics,&j)(%scan(&selected_varlist,&j));
					%end;

					%if "%scan(&metrics,&j)"="UNICOU" %then %do;
					%let new_metrics= unique(count(%scan(&selected_varlist,&j)));
					%end;
					

					%if "%scan(&metrics,&j)"="CUMCOU" %then %do;
					%let new_metrics= sum((select count(%scan(&selected_varlist,&j))
		        						from temp t2
		       							 where t2.grp&split_level1._flag<= t.grp&split_level1._flag)) ;
					%end;
					%if "%scan(&metrics,&j)"="CUMCOUPER" %then %do;
					proc sql;
					select count(%scan(&selected_varlist,&j)) into:countnum  from temp;
					quit;
					%let new_metrics= (select count(%scan(&selected_varlist,&j))/&countnum.*100
		        						from temp t2
		       							 where t2.grp&split_level1._flag<= t.grp&split_level1._flag)  ;
					%end;
					
					%if "%scan(&metrics,&j)"="CUMPER" %then %do;
					%let new_metrics= (select count(%scan(&selected_varlist,&j))/(select sum(%scan(&selected_varlist,&j)) from temp)*100
		        						from temp t2
		       							 where t2.grp&split_level1._flag<= t.grp&split_level1._flag) ;
					%end;
					
					%if "%scan(&metrics,&j)"="PERTOT" %then %do;
					proc sql;
					select sum(%scan(&selected_varlist,&j)) into:sumnum separated by "," from temp;
					quit;
					%let new_metrics= (sum(%scan(&selected_varlist,&j))/&sumnum.)*100;
					%end;
			
					%if "%scan(&metrics,&j)"="COUPER" %then %do;
					proc sql;
					select count(%scan(&selected_varlist.,&j)) into:countnum separated by "," from temp;
					quit;
					%let new_metrics=(count(%scan(&selected_varlist,&j))/&countnum.)*100;
					%end;




						proc sql;
							create table &name_dataset. as
							select &new_metrics. as yvalue, "%scan(&selected_varlist,&j)" as yvars LENGTH=32 , "%scan(&metrics,&j)" as metric_unique LENGTH=32 from temp t 
							%if "&level." ^= "0" %then where;
							%if "&level." ^= "0" %then &done.; 					
							%if "&level." ^= "0" %then %do;
								group by grp&split_level1._flag
							%end; 
							;
						quit;
					%if "&grp_no." ^= "0" %then %do;
					%let name_dataset_new=output&j&m;
					%end;
					%else %do;
					%let name_dataset_new=output&j.;
					%end;

							data &name_dataset_new.;
								set &name_dataset.;
								%if "&level." ^= "0" %then %do;
								length sliceBy $ 10. sliceBy_grp_no $ 10.;
								sliceBy_grp_no="&split_level.";	
								sliceBy="&split_sublevel.";
								%end;	
								%else %do;
								length sliceBy $ 10. sliceBy_grp_no $ 10.;
								sliceBy_grp_no="0";	
								sliceBy="1_1_1";	
								%end;

								length chartBy $ 10. chartBy_grp_no $ 10.;
								chartBy_grp_no="&split_grp_no.";
								chartBy="&split_grp_flag.";
								run;

				
						proc append base = &last_dataset. data=&name_dataset_new. force;
							run;
							quit;
%end;
					
/*				%end;*/
				proc append base=final_dataset data=&last_dataset. force;
					run;
				proc sort data=final_dataset nodupkey;
						by yvars yvalue sliceBy sliceBy_grp_no 
						%if "&grp_no." ^= "0" %then %do; chartBy chartBy_grp_no %end;;
						run;
		%end;
	%if "&flag_normal" ^="true" %then %do;
					%if "&grp_no." ^= "0" %then %do;
					%let name_dataset=out&m.;
					%end;
					%else %do;
					%let name_dataset=out;
					%end;
					proc sql;
							create table &name_dataset. as
							select count(grp&split_level1._flag) as yvalue LENGTH=32 from temp t 
							%if "&level." ^= "" %then where;
							%if "&level." ^= "" %then &done.; 					
							%if "&level." ^= "" %then %do;
								group by grp&split_level1._flag
							%end; 
							;
						quit;
					%if "&grp_no." ^= "0" %then %do;
					%let name_dataset_new=output&m;
					%end;
					%else %do;
					%let name_dataset_new=output;
					%end;

							data &name_dataset_new.;
								set &name_dataset.;
								%if "&level." ^= "0" %then %do;
								length sliceBy $ 10. sliceBy_grp_no $ 10.;
								sliceBy_grp_no="&split_level.";	
								sliceBy="&split_sublevel.";
								%end;	
								%else %do;
								length sliceBy $ 10. sliceBy_grp_no $ 10.;
								sliceBy_grp_no="0";	
								sliceBy="1_1_1";	
								%end;

								length chartBy $ 10. chartBy_grp_no $ 10. metric_unique $10. yvars $10.;
								chartBy_grp_no="&split_grp_no.";
								chartBy="&split_grp_flag.";
								yvars="";
								metric_unique="";
								run;

				
						proc append base = &last_dataset. data=&name_dataset_new. force;
							run;
							quit;
					
				proc append base=final_dataset data=&last_dataset. force;
					run;
				proc sort data=final_dataset nodupkey;
						by yvalue sliceBy sliceBy_grp_no 
						%if "&grp_no." ^= "0" %then %do; chartBy chartBy_grp_no %end;;
						run;
		%end;

%mend pi;

%macro viz(last_dataset);
%if "&level." ^= "0" %then %do;
		/*loop for the number of levels selected in slice by*/ 
			%do l=1 %to %eval(%sysfunc(countw("&level.","#")));

				%let split_level=%scan("&level.",&l,"#");
				%let split_sublevel=%scan(&sublevel,&l,"#");

				/*creating the having condition*/
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
						call symput("where",cat("&where ",'grp%scan(&split_level,&i," ")_flag=&temp.'));
						run;
					%put &where;
					%let done= %sysfunc(tranwrd(&where,"=",%quote(=)));
					%put &done;

		%let split_level1=%sysfunc(tranwrd(&split_level,%quote( ),%quote(,)));
		%put &split_level1;

		%let selected_varlist1=%sysfunc(tranwrd(&selected_varlist,%quote( ),%quote(,)));
		%put &selected_varlist1;
		%pi;
	%end;
	
%end;
%else %do;
		%pi;
%end;
	%mend viz;
%macro final_call;
%if "&level." ^= "" %then %do;
		data _null_;
		call symput("level","%sysfunc(compbl("&level."))");
		run;
%end;
		/*subset dataset on the bases of separate chart*/
%if "&grp_no." ^= 0 %then %do;
	%do m=1 %to %eval(%sysfunc(countw(&grp_no.,#)));
			%let split_grp_no=%scan(&grp_no.,&m,"#");
			%let split_grp_flag=%scan(&grp_flag.,&m,"#");
	data temp;
		set &dataset_name.;
		%if "&split_grp_no." ^= "0" %then %do;
			where grp&split_grp_no._flag = "&split_grp_flag.";
		%end;
		run;

		%viz(final&m.);
			proc export data = final_dataset
			outfile = "&output_path./Pie_chart.csv"
			dbms = CSV replace;
			run;
	%end;

%end;
%mend final_call;
%final_call;

/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "EDA - VISUALIZATION_COMPLETED";
	file "&output_path./Pie_COMPLETED.txt";
	put v1;
	run;
	
	proc datasets lib=work kill;
	run;
