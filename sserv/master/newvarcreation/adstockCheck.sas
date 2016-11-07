*processbody;
options mfile mprint mlogic symbolgen;
dm log 'clear';

proc printto log="&output_path./adstockCheck_Log.log";
run;
quit;

libname in "&input_path.";
libname out "&output_path.";
%macro delete_files_check;
	FILENAME MyFile "&output_path./AcrossGroupby_Check_COMPLETED.txt";
	DATA _NULL_ ;
		rc = FDELETE('MyFile') ;
		RUN ;

	FILENAME MyFile "&output_path./NOT_UniqueValue.txt";
	DATA _NULL_ ;
		rc = FDELETE('MyFile') ;
		RUN ;

	FILENAME MyFile "&output_path./AcrossDataset_Check_COMPLETED.txt";
	DATA _NULL_ ;
		rc = FDELETE('MyFile') ;
		RUN ;
	
		

%mend;
%delete_files_check;
%macro check_unique_date;
%if "&grp_no." ^= "0" %then %do;

%let var=grp&grp_no._flag;
%put &var.;



				proc sql;
				create table useless as
					select distinct(&var.), count(distinct(&date_variable.))as unique_date,count(&var.) as count from in.dataworking group by &var.;
					run;
					quit;

					data useless;
					set useless;
					if unique_date = count then delete ;
					run;

				%let dset=useless;
				%let dsid = %sysfunc(open(&dset));
				%let nobs =%sysfunc(attrn(&dsid,NOBS));
				%let rc = %sysfunc(close(&dsid));
			%put &nobs;

		%macro check_ag;
			%If "&nobs."= "0" %then %do;
				data _null_;
					v1= "Dates are unique";
		      		file "&output_path./AcrossGroupby_Check_COMPLETED.txt";
		      		put v1;
					run;
				
			%end;
			%else %do;;
				data _null_;
			      		v1= "The dates are not unique in some of the levels of the selected panel. Do you wish to continue?";
			      		file "&output_path./NOT_UniqueValue.txt";
			      		put v1;
						run;

			%end;

			%mend;
			%check_ag;
%end;
%else %do;
			proc sql;
				select count(distinct(&date_variable.))into : unique_date from in.dataworking;
				run;
				quit;
				%put &unique_date.;

				
			proc sql;
				select count(&date_variable.)into : nobss from in.dataworking;
				run;
				quit;
				%put &nobss.;


			%macro check_ad;
				%if "&unique_date." = "&nobss" %then %do;
					data _null_;
							v1= "Dates are unique";
				      		file "&output_path./AcrossDataset_Check_COMPLETED.txt";
				      		put v1;
							run;
				%end;
				%else %do;
					data _null_;
				      		v1= "The dates are not unique across the dataset. Do you wish to continue? Note:Use Across Group By if unique dates are present across different levels of a panel";
				      		file "&output_path./NOT_UniqueValue.txt";
				      		put v1;
							run;
				%end;
				%mend;
				%check_ad;
%end;
%mend;
%check_unique_date;



