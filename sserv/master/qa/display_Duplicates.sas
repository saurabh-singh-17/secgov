/*%let inputPath=;*/
/*%let outputPath=;*/
/*%let startIndex=;*/
/*%let rows=;*/
libname in "&inputPath";
libname out "&outputPath";

proc import datafile="&inputPath./duplicates.csv" out=duplicates_data dbms=CSV replace;
run;

quit;

data duplicates_data_show;
	set duplicates_data;

	if _n_ >= &startIndex. and _n_ <= &startIndex.+&rows.-1 then
		output;
run;

proc export data=duplicates_data_show outfile="&outputPath./display_Duplicates.csv" dbms=CSV replace;
run;

quit;


data _null_;
	v1= "Completed";
	file "&outputPath./DISPLAY_COMPLETED.TXT";
	put v1;
run;
;