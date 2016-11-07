/*Successfully converted to SAS Server Format*/
*processbody;
/*For this code to run, it needs &current_variable. in.dataworking and &output_path*/
FILENAME MyFile "&output_path./zero.txt";

DATA _NULL_ ;
	rc = FDELETE('MyFile') ;
	RUN ;
	
FILENAME MyFile "&output_path./negative.txt";

DATA _NULL_ ;
	rc = FDELETE('MyFile') ;
	RUN ;
	
FILENAME MyFile "&output_path./missing.txt";

DATA _NULL_ ;
	rc = FDELETE('MyFile') ;
	RUN ;

%macro current;
	%global indicator;
	%let indicator = 0;
	%let dsid = %sysfunc(open(in.dataworking));
	%let varnum = %sysfunc(varnum(&dsid,&current_variable));
	%put &varnum;
	%let vartyp = %sysfunc(vartype(&dsid,&varnum)); /* variable type */
	%let rc = %sysfunc(close(&dsid));
	%put &vartyp;
	%let substr_current_variable = %substr(&current_variable.,1,22);

	data results(keep=&current_variable.:);
		set in.dataworking;
		%if "&vartyp."="N" %then %do;
			if &current_variable = 0 then do;
				&substr_current_variable._zero=1;
			end;
			if &current_variable < 0 and &current_variable ^=. then do;
				&substr_current_variable._negative=1;
			end;
			if &current_variable =. then do;
				&substr_current_variable._missing=1;
			end;
		%end;
		%else %do ;
			if &current_variable. =" " then do;
				&substr_current_variable._cmissing=1;
			end;
		%end;
		run;

	%if "&vartyp."="N" %then %do;
		proc sql;
			select distinct &substr_current_variable._zero into: zero separated by " " from results;
			select distinct &substr_current_variable._missing into: missing separated by " " from results;
			select distinct &substr_current_variable._negative into: negative separated by " " from results;
			quit;

		data _null_;
			%if &zero.^=. %then %do;
				%let indicator = 1;
				v1= "variable contains zero";
				file "&output_path./zero.txt";
				put v1;
			%end;
			%if &negative.^=. %then %do;
				%let indicator = 1;
				v1= "variable contains negative";
				file "&output_path./negative.txt";
				put v1;
			%end;
			%if &missing. ^=. %then %do;
				%let indicator = 1;
				v1= "variable contains missing";
				file "&output_path./missing.txt";
				put v1;
			%end;
			run;
	%end;
	%else %do;
		proc sql;
			select distinct &substr_current_variable._cmissing into: cmissing separated by " " from results;
			quit;

		data _null_;
	   		%if &cmissing. ^=' ' %then %do;
				%let indicator = 1;
				v1= "variable contains missing";
				file "&output_path./missing.txt";
				put v1;
			%end;
			run;
	%end;
%mend current;
%current;