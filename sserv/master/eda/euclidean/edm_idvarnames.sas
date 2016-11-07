/*%let inputpath=/home/mrx1/vasanth;*/
/*%let outputpath=/home/mrx1/vasanth/wc;*/
/*%let grpno=0;*/
/*%let grpflag=1_1_1;*/
/*%let testindicatorvar=geography;*/
/*%let testvalue=north;*/
/*%let controlvalue=south;*/
/*%let nostd=nostd;*/
/*%let vars=ACV black_hispanic sales;*/
/*%let categoricalvars=Store_format;*/
/*%let idvar=Date;*/
/*%let testcontrolindicatorvar=dfsfsfae;*/
/*%let matchpreferencevar=sales;*/
/*%let matchpreferenceorder=descending;*/
/*%let matchtype1=Many to One;*/
/*%let matchtype2=simpleeuclidean;*/
/*%let distance_cutoff=150;*/
/*%let mapcontroltotestvar=wwwwwww;*/
/*%let distancevarflag=true;*/
/*%let createdatasetflag=true;*/
/*%let newdatasetname=dfsaddfsaddf;*/

options mlogic mprint symbolgen spool;

proc printto log = "&outputpath./edm_idvarnames.log" new;
run;
quit;

%macro idvarnames;
libname in "&inputpath.";

%if &grpno. = 0 %then
	%do;
		%let dataset=in.dataworking;
	%end;
%else
	%do;
		data temp;
			set in.dataworking;
			if grp&grpno._flag="&grpflag.";
		run;
		
		%let dataset=temp;
	%end;

ods output nlevels = nlevels;

proc freq data=&dataset. nlevels;
   tables _all_ / noprint;
run;

%let dsid=%sysfunc(open(nlevels));
%let nvars=%sysfunc(attrn(&dsid.,nvars));
%let rc=%sysfunc(close(&dsid.));

%let dsid=%sysfunc(open(&dataset.));
%let nobs=%sysfunc(attrn(&dsid.,nobs));
%let rc=%sysfunc(close(&dsid.));

data nlevels(keep= tablevar);
	set nlevels;
	%if &nvars. = 4 %then
		%do;
			if nnonmisslevels=&nobs. and tablevar ^= "primary_key_1644";
		%end;
	%else
		%do;
			if nlevels=&nobs. and tablevar ^= "primary_key_1644";
		%end;
run;

%let dsid=%sysfunc(open(nlevels));
%let nobs=%sysfunc(attrn(&dsid.,nobs));
%let rc=%sysfunc(close(&dsid.));

%if &nobs. ^= 0 %then
	%do;
		proc export data=nlevels outfile="&outputpath./idvarnames.csv" dbms=csv replace;
		run;
		quit;
		
		data _null_;
			v1= "idvarnames completed";
			file "&outputpath./idvarnames_completed.txt";
			put v1;
		run;
	%end;

%mend idvarnames;
%idvarnames;

proc datasets lib=work kill nolist;
run;
quit;