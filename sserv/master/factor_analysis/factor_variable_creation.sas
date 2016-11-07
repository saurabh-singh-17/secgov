/*author: saurabh vikash singh*/
/*name : factor_variable creation*/


/*parameters*/
/*inputPath*/
/*iterationPath*/
/*originalName*/
/*newName*/

options mprint symbolgen mlogic mfile;
dm 'log' clear;


proc printto log="&iterationPath./factor_variable creation.log" new;
run;
quit;

%macro factor_var;
/*factor variable creation starts here*/

libname in "&inputPath.";
libname iter "&iterationPath.";

proc sort data=iter.outputdata out=iter.outputdata;
by primary_key_1644;
run;

data iterdata;	
	set iter.outputdata(keep=&originalName primary_key_1644);
	run;

proc sort data=in.dataworking out=in.dataworking;
by primary_key_1644;
run;

data in.dataworking;
	merge in.dataworking(in=a) iterdata(in=b);
	by primary_key_1644;
	if a;
	run;

data in.dataworking;
	set in.dataworking;
	%do i=1 %to %sysfunc(countw("&originalName."," "));
		%let tempOrig=%scan("&originalName.",&i.," ");
		%let tempNew=%scan("&newName.",&i.," ");
		rename &tempOrig.=&tempNew.;
	%end;
	run;

%mend;
%factor_var;

data _null_;
	v1="Factor variable creation completed.";
	file "&iterationPath./FACTOR_VARIABLE_COMPLETED.txt";
	%put &v1.;
	run;