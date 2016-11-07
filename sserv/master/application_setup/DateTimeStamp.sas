options nodate mprint mlogic symbolgen;

/*%let output_path = /data22/IDev/Mrx/projects/PGD_anvita_Logistic-13-Feb-2014-10-29-32/1/0;*/

FILENAME MyFile "&output_path./DATETIMESTAMP.txt";

DATA _NULL_;
	rc = FDELETE('MyFile');
RUN;

%let timenow=%sysfunc(datetime(), datetime20.);

data _null_;
file "&output_path./DATETIMESTAMP.TXT";
put "&timenow.";
run;