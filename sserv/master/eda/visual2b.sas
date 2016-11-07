/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path./VISUALIZATION_2B_COMPLETED.txt;

/* VERSION : 2.1.1 */
options mprint mlogic symbolgen mfile ;

FILENAME MyFile "&output_path./GENERATE_FILTER_FAILED.txt" ;

  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;
dm log 'clear';
proc printto log="&output_path./Visualization_2b_log.log";
run;
quit;
	
/*proc printto print="&output_path./Visualization_2b_output.out";*/
	

/*defining the libraries*/
libname in "&input_path.";
libname out "&output_path.";
data _null_;
call symput("level","%sysfunc(compbl(&level))");
run;

%macro vis_2b;

	/*DYNAMIC FILTER*/
	%if "&flag_filter." = "true" %then %do;
		%let dataset_name=out.temporary;
		%let whr=;
	 	/*call SAS code for dynamic filtering*/
		%include %unquote(%str(%'&filterCode_path./dynamicFiltering.sas%')); 
	%end;
	%else %do;
		%let dataset_name=in.dataworking;
	%end;

	data temp;
	set &dataset_name.;
	%if "&grp_no." ^= "0" %then %do;
		where grp&grp_no._flag = "&grp_flag.";
	%end;
	run;

	/* Checking number of observations in dataset	*/
	%let dset=temp;
		%let dsid = %sysfunc(open(&dset));
		%let nobs =%sysfunc(attrn(&dsid,NOBS));
		%let rc = %sysfunc(close(&dsid));
	%if &NOBS. =0
		%then %do;

		data _null_;
      		v1= "There are zero observations in the filtered dataset";
      		file "&output_path./GENERATE_FILTER_FAILED.txt";
      		put v1;
			run;

	%end;
	%else %do;
	
/*loop for the number of levels selected in split axid by*/ 
%do l=1 %to %eval(%sysfunc(countw(&level,"#")));

%let split_varlist=%scan(&level,&l,"#");
%let split_varlist2=%scan(&sublevel,&l,"#");


/*creating the having condition*/
%let having=;
%do i=1 %to %eval(%sysfunc(countw(&split_varlist," "))-1);

	/*finding the variable type*/
	%let dsid = %sysfunc(open(temp));
	%let varnum = %sysfunc(varnum(&dsid,%scan(&split_varlist,&i," ")));
	%put &varnum;
	%let vartyp = %sysfunc(vartype(&dsid,&varnum)); /* variable type */
	%let rc = %sysfunc(close(&dsid));
	%put &vartyp;

		data _null_;
			call symput("temp","%scan(&split_varlist2,&i,"|")");
			run;
	%put &temp;
	/*generating quotes only for character type variable*/
	%if "&vartyp" ="C" %then %do; 
		%let temp=%str(%'&temp%');
	%end;
		data _null_;
			call symput("having",cat("&having ",'%scan(&split_varlist,&i," ")=&temp'," and"));
			run;
		%put &having;
	%let having=&having;

%end;

/*finding the variable type*/
	%let dsid = %sysfunc(open(temp));
	%let varnum = %sysfunc(varnum(&dsid,%scan(&split_varlist,&i," ")));
	%put &varnum;
	%let vartyp = %sysfunc(vartype(&dsid,&varnum)); /* variable type */
	%let rc = %sysfunc(close(&dsid));
	%put &vartyp;

data _null_;
	call symput("temp","%scan(&split_varlist2,&i,"|")");
	run;

%put &temp;
/*generating quotes only for character type variable*/
%if "&vartyp" ="C" %then %do; 
	%let temp=%str(%'&temp%');
%end;

data _null_;
	call symput("having",cat("&having ",'%scan(&split_varlist,&i," ")=&temp'));
	run;
%put &having;
%let done= %sysfunc(tranwrd(&having,"=",%quote(=)));
%put &done;

%if "&flag_multiplemetric"="true" %then %do;
	%let done=;
%end;
%put &done;
/*converting space to comma separated*/
%let split_varlist1=%sysfunc(tranwrd(&split_varlist,%quote( ),%quote(,)));
%put &split_varlist1;

%let selected_varlist1=%sysfunc(tranwrd(&selected_varlist,%quote( ),%quote(,)));
%put &selected_varlist1;


	%if "&flag_normal"="true" %then %do;
		%do i = 1 %to %sysfunc(countw(&var_list.," "));
			%if %sysfunc(index("%scan(&var_list,&i,' ')",$))>0 %then %do;
				%let combined_vars=%scan(&var_list,&i," ");
				%let combined_vars=%sysfunc(tranwrd(&combined_vars,%quote($),%quote( )));
				%let combined_vars1=%sysfunc(tranwrd(&combined_vars,%quote( ),%quote(,)));
			%end;

			%do j = 1 %to %sysfunc(countw(&metrics.));

				proc sql;
					create table out_&i._&j. as
					select %if %sysfunc(index("%scan(&var_list,&i,' ')",$))>0 %then &combined_vars1, ; %else %scan(&var_list,&i," ") as variable,; "%scan(&metrics,&j)(%scan(&selected_varlist,&j))" as metric LENGTH=32,
					"%scan(&metrics,&j)" as metric_unique LENGTH=32,%scan(&metrics,&j)(%scan(&selected_varlist,&j)) as value  from temp
						
					%if "&split_varlist" ^= "" %then %do;
						group by  %if %sysfunc(index("%scan(&var_list,&i,' ')",$))>0 %then &combined_vars1; %else %scan(&var_list,&i," "); %if "&flag_multiplemetric"^="true" %then ,&split_varlist1 ;
					%end; 
					%if "&flag_multiplemetric"^="true" or "&grp_no." ^= "0" %then having;
					%if "&flag_multiplemetric"^="true" %then &done; 
					%if "&flag_multiplemetric"^="true" and "&grp_no." ^= "0" %then and;
					%if "&grp_no." ^= "0" %then %do;
						grp&grp_no._flag = "&grp_flag."
					%end;
					;
				quit;

					data output&i&j;
						set out_&i._&j.;
						%if "&flag_multiplemetric"^="true" %then %do;
						length lineby1 $ 50.;
						lineby1="&split_varlist2";						
						%end;
						run;

				/*append to the output file*/
				proc append base = output&i&i._&l data=output&i&j force;
					run;
					quit;
			%end;
			%if %sysfunc(index("%scan(&var_list,&i,' ')",$))>0 %then %do;
				data output&i._&l(drop=&combined_vars);
					set output&i&i._&l;
					variable=catx("|",&combined_vars1);
					run;
				proc append base = output&i data=output&i._&l force;
					run;
					quit;

			%end;
			%else %do;
				proc append base = output&i data=output&i.&i._&l force;
					run;
					quit;

			%end;
			proc sort data=output&i nodupkey;
				by metric variable  value %if "&flag_multiplemetric" ^="true" %then %do; lineby1 %end; ;
				run;
          
            /* to replace missing values with zero*/
			data output&i; 
                set output&i;
				length lineby1 $ 50.;
                array nums _numeric_;
                do over nums;
                if nums=. then nums=0;
                end;
                run;


			/* to output the excel sheet at the output path */
			proc export data = output&i
				outfile = "&output_path./%scan(&var_list,&i,' ').csv"
				dbms = CSV replace;
				run;
			
			/*-----------------------------------------------------------------------------------------
		Writing a text file to indicate if there are more than 10000 observations in the CSV
		-----------------------------------------------------------------------------------------*/
		%let dsid=%sysfunc(open(output&i));
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
		/*-----------------------------------------------------------------------------------------*/

/*				proc append base = output data=output&i._&l force;*/
/*					run;*/
/*					quit;*/
		%end;

	%end;
	%else %do;
		%do i = 1 %to %sysfunc(countw(&var_list.," "));
			/*loop through the list of metrics*/
			%do j = 1 %to %sysfunc(countw(&metrics.));
				
				proc sql;
					create table out_&i._&j. as
					select "%scan(&var_list,&i," ")" as variable LENGTH=32, "%scan(&metrics,&j)(%scan(&var_list,&i," "))" as metric LENGTH=32,
					"%scan(&metrics,&j)" as metric_unique LENGTH=32,%scan(&metrics,&j)(%scan(&var_list,&i," ")) as value  from temp
						
					%if "&split_varlist" ^= "" and "&flag_multiplemetric"^="true" %then %do;
						group by  &split_varlist1
					%end; 
					%if "&flag_multiplemetric"^="true" or "&grp_no." ^= "0" %then having;
					%if "&flag_multiplemetric"^="true" %then &done; 
					%if "&flag_multiplemetric"^="true" and "&grp_no." ^= "0" %then and;
					%if "&grp_no." ^= "0" %then %do;
						grp&grp_no._flag = "&grp_flag."
					%end;
					;
				quit;
				/*append to the output file*/
				proc append base = output&i._&l data=out_&i._&j. force;
					run;
					quit;
				
			%end;
				data output&l&i&i;
					set output&i._&l;
					%if "&flag_multiplemetric"^="true" %then %do;
						length lineby1 $ 32.;
						lineby1="&split_varlist2";						
					%end;
					run;
				proc append base = output data=output&l&i&i force;
					run;
					quit;
		%end;
		proc sort data=output nodupkey;
			by variable metric value %if "&flag_multiplemetric" ^="true" %then %do; lineby1 %end; ;
			run;

		 /* to replace missing values with zero*/
	    data output; 
            set output;
            array nums _numeric_;
            do over nums;
            if nums=. then nums=0;
            end;
            run;

		/* to output the excel sheet at the output path */
		proc export data = output
			outfile = "&output_path./column_chart.csv"
			dbms = CSV replace;
			run;

		/*-----------------------------------------------------------------------------------------
		Writing a text file to indicate if there are more than 10000 observations in the CSV
		-----------------------------------------------------------------------------------------*/
		%let dsid=%sysfunc(open(output));
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
		/*-----------------------------------------------------------------------------------------*/
			
	%end;
%end;

/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "EDA - VISUALIZATION_2B_COMPLETED";
	file "&output_path./VISUALIZATION_2B_COMPLETED.txt";
	put v1;
	run;

	%end;
/*		data uniquevalues(keep=lineby1);*/
/*			set output;*/
/*			run;*/
/*		proc sort data=uniquevalues out=unique nodupkey;*/
/*			by lineby1;*/
/*			run;*/
%mend vis_2b;
%vis_2b;