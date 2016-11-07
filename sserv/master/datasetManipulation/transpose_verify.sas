/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/TRANSPOSE_VERIFY_COMPLETED.txt;
option mprint mlogic symbolgen mfile ;
dm log 'clear';

proc printto log="&output_path/transpose_verify_Log.log";
run;
quit;
/*proc printto print="&output_path./transpose_verify_Output.out";*/

libname in "&input_path.";
libname out "&output_path.";

%macro transpose_verify;


%let error=false;
%if "&unique_level_vars." ^= "" %then %do;
%let unique_level_vars = %sysfunc(compbl(&unique_level_vars.));
%end;

data _null_;
	call symput("byvars",tranwrd("&unique_level_vars."," ",","));
	run;


		proc sql;
			create table counting as select (count(&unique_var.)-count(distinct &unique_var.)) as diff
			from in.&dataset_name.
			%if "&unique_level_flag."= "true" %then %do;group by &byvars.;%end;
			quit;

		proc sql;
			select sum(diff) into:idflag
			from counting;
		
		%if &idflag.^=0 %then %do;
			%let error=true;
		%end;


		/*get vartype*/
		%let dsid = %sysfunc(open(in.&dataset_name.));
			%let varnum = %sysfunc(varnum(&dsid,%scan(&unique_var., 1)));
			%let vartyp = %sysfunc(vartype(&dsid,&varnum)); /* variable type */
			%let rc = %sysfunc(close(&dsid));
				

		proc sql;
			select count(*) as id_missing into:idmiss
			from in.&dataset_name. 
			%if &vartyp. = C %then %do;where &unique_var.="";%end;
			%if &vartyp. = N %then %do;where &unique_var.=.;%end;
			quit;


		/* summary table */
		proc sql;
			create table summary
			(
			 detail varchar(50)
			);
			quit;
	
		proc sql;
			insert into summary
			values("&error.");
			quit;

		proc sql;
			insert into summary
			values("&idmiss.");
			quit;
		%global prefix2;
		%if %sysfunc(symexist('prefix')) %then %do;
		%let prefix2 =&prefix.;
		%end;
		%else %do;
		%let prefix2=;
		%end;
	   /*creating sketch*/

		%if "&error."="false" %then %do;

			%macro createsketch;
			
				proc sql;
					create table idvartable as select distinct &unique_var.
					from in.&dataset_name.;
					quit; 

				proc transpose data=idvartable
				    out=idvartable_transposed %if  "&prefix2." ^= "" %then %do; prefix=&prefix2. %end;;
					id &unique_var.;
					run;


				proc sql;
					create table transpose_vars
					(
					 new_name varchar(50)
					);
				quit;

				%let i = 1;
					%do %until (not %length(%scan(&var_list, &i)));

					proc sql;
						insert into transpose_vars
						values("%scan(&var_list, &i)");
						quit;
					
					%let i = %eval(&i.+1);
					%end;


				%if "&unique_level_flag."= "true" %then %do;
				    proc sql;
						create table byvartable as select distinct &byvars. 
						from in.&dataset_name. group by &byvars. ;
						quit;

					proc sql;
						create table T as
						select byvartable.*, transpose_vars.* from byvartable,transpose_vars;
						quit;

					data sketch;
						merge T idvartable_transposed;
						run;
				%end;
				%else %do;
					data sketch;
					merge transpose_vars idvartable_transposed;
					run;
				%end;

				
				data sketch;
					set sketch (drop = _name_);
					run;
			
			%mend createsketch;
			%createsketch;

			

			/* exporting sketch */
				proc export data = sketch
				    outfile = "&output_path./sketch.csv"
				    dbms = csv replace;
				    run;
		%end;



%mend transpose_verify;
%transpose_verify;



proc export data = summary
    outfile = "&output_path./transpose_verification.csv"
    dbms = csv replace;
    run;

data _null_;
	v1= "VERIFY_COMPLETED";
	file "&output_path/TRANSPOSE_VERIFY_COMPLETED.txt";
	put v1;
	run;


