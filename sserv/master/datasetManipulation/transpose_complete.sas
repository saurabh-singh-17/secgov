/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/TRANSPOSE_COMPLETED.txt;
option mprint mlogic symbolgen mfile ;
/**/
proc printto log="&output_path/transpose_complete_Log.log";
run;
quit;

/*log="&output_path/transpose_complete_Log.log"*/
/*proc printto print="&output_path./transpose_complete_Output.out";*/

libname in "&input_path.";
libname out "&output_path.";
dm log 'clear';

FILENAME MyFile "&output_path.\ERROR.txt" ;

  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;
%macro transpose_complete;

		%if "&unique_level_flag."= "true" %then %do;
				proc sort data=in.&dataset_name.
						  out=in.&dataset_name.;
						  by &unique_level_vars.;
						  run;
						  
		%end;

%let dsid = %sysfunc(open(in.&dataset_name.));
%let nobs = %sysfunc(attrn(&dsid,nobs));
%let rc = %sysfunc(close(&dsid.));

%if &nobs.>32647 %then %do;

	data _null_;
	v1= "Identity Variable has rows more then 32647";
	file "&output_path/ERROR.txt";
	put v1;
	run;
	ENDSAS;
%end;
		proc transpose data=in.&dataset_name.
		               out=out.temp  name=&new_var_name. %if "&prefix." ^= "" %then %do; prefix=&prefix. %end;;
					   var &var_list.;
					   id &unique_var.;
					   %if "&unique_level_flag."= "true" %then %do;by &unique_level_vars.;%end;
					   run;

		%let dsid = %sysfunc(open(out.temp));
		%let varnum = %sysfunc(varnum(&dsid,_LABEL_));
		%let rc = %sysfunc(close(&dsid));
			
 		 DATA  out.&new_dataset.(%if &varnum. ^= 0 %then %do; drop=_LABEL_ %end;);
  						 SET out.temp;
  						 LABEL &new_var_name.="Transposed Variable";
	  	 RUN;
   
 
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



	/* properties table */
		proc sql;
			create table properties
			(
			 missing integer,
			 repeating integer
			);
			quit;
		proc sql;
			insert into properties
			values(&idmiss.,0);
			quit;



%mend transpose_complete;
%transpose_complete;


proc export data = properties
    outfile = "&output_path./transpose_properties.csv"
    dbms = csv replace;
    run;

data _null_;
	v1= "TRANSPOSE_COMPLETED";
	file "&output_path/TRANSPOSE_COMPLETED.txt";
	put v1;
	run;


