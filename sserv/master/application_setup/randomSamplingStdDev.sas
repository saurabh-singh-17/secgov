options mlogic mprint symbolgen;

/*------------------------------------------------------------------------------------------------------------------------------------------*/
/*Parameters Required*/
/*------------------------------------------------------------------------------------------------------------------------------------------*/
/*%let inputpath=/home/mrx1/vasanth;*/
/*%let outputpath=/home/mrx1/vasanth;*/
/*%let samplingvar=ACV;*/
/*%let stratavar=;*/
/*------------------------------------------------------------------------------------------------------------------------------------------*/

libname in "&inputpath.";
libname out "&outputpath.";

%macro stddev;
proc means data=in.dataworking;
	var &samplingvar.;
	output var=var std=std mean=mean out=out_means;
run;
quit;

data stddev(rename=(std=stddev));
	set out_means(keep=std);
run;

%if "&stratavar." ^= "" %then
	%do;
		data _null_;
			set out_means;
			call symput("std",std);
			call symput("totalvariance",var);
		run;
		
		data temp;
			set in.dataworking(keep=&samplingvar. &stratavar.);
		run;

		proc sort data=temp out=temp;
			by &stratavar.;
		run;
		quit;

		proc means data=temp;
			var &samplingvar.;
			by &stratavar.;
			output var=var std=std mean=mean out=out_means_group;
		run;
		quit;

		proc means data=out_means_group;
			var mean;
			output std=std var=var mean=mean out=var_acrss_grp;
		run;
		quit;

		data _null_;
			set var_acrss_grp;
			call symput("varianceacrssgrp",var);
		run;

		%let reducedstd=%sysevalf((1-(&varianceacrssgrp./&totalvariance.))*&std.);
		data stddev;
			stddev=abs(&reducedstd.);
		run;
	%end;

%let dsid=%sysfunc(open(in.dataworking));
%let nobs=%sysfunc(attrn(&dsid.,nobs));
%let rc=%sysfunc(close(&dsid.));

data stddev;
	set stddev;
	records=&nobs.;
run;

proc export data=stddev outfile="&outputpath./stddev.csv" dbms=csv replace;
run;
quit;
%mend;
%stddev;

data _null_;
	v1= "Calculated standard deviation successfully.";
	file "&outputpath./stddev_completed.txt";
	put v1;
	run;